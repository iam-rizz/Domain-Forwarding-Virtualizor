#!/bin/bash

CONFIG_FILE="/etc/vm/data.conf"

# Variabel untuk opsi
SHOW_HELP=false
NO_COLOR=false
VPSID=""
VDFID=""
FORCE=false
INTERACTIVE=false

# Fungsi bantuan
show_help() {
    cat << EOF
Penggunaan: $0 [OPSI]

Script untuk menghapus Domain/Port Forwarding dari API VPS

OPSI:
    -h, --help              Tampilkan bantuan ini
    -n, --no-color          Nonaktifkan warna pada output
    -v, --vpsid VPSID       Pilih VPSID secara manual
    -f, --vdfid VDFID       ID forwarding yang akan dihapus
    --force                 Hapus tanpa konfirmasi
    -i, --interactive       Mode interactive (step-by-step)
    
CONTOH:
    $0 --interactive                        # Mode step-by-step dengan konfirmasi
    $0 --vpsid 103 --vdfid 596              # Hapus forwarding tertentu (dengan konfirmasi)
    $0 --vpsid 103 --vdfid 596 --force     # Hapus tanpa konfirmasi
    $0 -v 103 -f 596,597,598                # Hapus beberapa forwarding sekaligus

EOF
}

# Parse argumen command line
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -n|--no-color)
            NO_COLOR=true
            shift
            ;;
        -v|--vpsid)
            VPSID="$2"
            shift 2
            ;;
        -f|--vdfid)
            VDFID="$2"
            shift 2
            ;;
        --force)
            FORCE=true
            shift
            ;;
        -i|--interactive)
            INTERACTIVE=true
            shift
            ;;
        *)
            echo "❌ Opsi tidak dikenal: $1"
            echo "Gunakan -h atau --help untuk bantuan"
            exit 1
            ;;
    esac
done

# Cek apakah file konfigurasi ada
if [[ -f "$CONFIG_FILE" ]]; then
    source "$CONFIG_FILE"
else
    echo "❌ File konfigurasi tidak ditemukan: $CONFIG_FILE"
    exit 1
fi

# Validasi masing-masing variabel
[[ -z "$API_URL" ]] && { echo "❌ API_URL tidak boleh kosong di $CONFIG_FILE"; exit 1; }
[[ -z "$API_KEY" ]] && { echo "❌ API_KEY tidak boleh kosong di $CONFIG_FILE"; exit 1; }
[[ -z "$API_PASS" ]] && { echo "❌ API_PASS tidak boleh kosong di $CONFIG_FILE"; exit 1; }

# Fungsi untuk mendapatkan daftar VM
get_vm_list() {
    local response=$(curl -sk --max-time 30 "${API_URL}?act=listvs&api=json&apikey=${API_KEY}&apipass=${API_PASS}")
    echo "$response"
}

# Fungsi untuk mendapatkan daftar forwarding dari VM
get_forwarding_list() {
    local vpsid="$1"
    local response=$(curl -sk --max-time 30 "${API_URL}?act=managevdf&svs=${vpsid}&api=json&apikey=${API_KEY}&apipass=${API_PASS}")
    echo "$response"
}

# Fungsi untuk menampilkan pilihan VM
show_vm_selection() {
    local vm_response="$1"
    
    if [[ "$NO_COLOR" == "true" ]]; then
        echo "=== PILIH VIRTUAL MACHINE ==="
    else
        echo ""
        echo -e "\e[1;36m🖥️ PILIH VIRTUAL MACHINE:\e[0m"
        printf "\e[2;37m%s\e[0m\n" "----------------------------------------"
    fi
    
    echo "$vm_response" | jq -r '
      .vs | 
      to_entries[] | 
      .value as $vm |
      [
        ($vm.vpsid // "N/A"),
        ($vm.hostname // "N/A"),
        (if ($vm.status // 0) == 1 then "Up" else "Down" end),
        ($vm.ips | to_entries[] | select(.value | test("^[0-9.]+$")) | .value)
      ] | 
      @tsv
    ' | while IFS=$'\t' read -r vpsid hostname status_raw internal_ip; do
        # Truncate hostname jika terlalu panjang
        if [[ ${#hostname} -gt 15 ]]; then
            hostname="${hostname:0:12}..."
        fi
        
        if [[ "$NO_COLOR" == "true" ]]; then
            printf "%s) VPSID: %-6s | Hostname: %-15s | Status: %-4s | IP: %s\n" "$vpsid" "$vpsid" "$hostname" "$status_raw" "$internal_ip"
        else
            local status_icon=""
            local status_color=""
            if [[ "$status_raw" == "Up" ]]; then
                status_icon="🟢"
                status_color="\e[32m"
            else
                status_icon="🔴"
                status_color="\e[31m"
            fi
            
            printf "\e[1;93m%s\e[0m) VPSID: \e[1;36m%-6s\e[0m | Hostname: \e[35m%-15s\e[0m | Status: ${status_color}%s %s\e[0m | IP: \e[96m%s\e[0m\n" "$vpsid" "$vpsid" "$hostname" "$status_icon" "$status_raw" "$internal_ip"
        fi
    done
    
    echo ""
}

# Fungsi untuk menampilkan daftar forwarding dan memilih
show_forwarding_selection() {
    local forwarding_response="$1"
    local vpsid="$2"
    
    if [[ "$NO_COLOR" == "true" ]]; then
        echo "=== PILIH FORWARDING UNTUK DIHAPUS ==="
        echo "VPSID: $vpsid"
        echo ""
    else
        echo ""
        echo -e "\e[1;31m🗑️ PILIH FORWARDING UNTUK DIHAPUS:\e[0m"
        echo -e "\e[1;36mVPSID:\e[0m \e[1;32m$vpsid\e[0m"
        printf "\e[2;37m%s\e[0m\n" "------------------------------------------------"
    fi
    
    # Parse dan tampilkan forwarding
    echo "$forwarding_response" | jq -r '
      .haproxydata // {} | 
      to_entries[] | 
      .value as $fwd |
      [
        ($fwd.id // "N/A"),
        ($fwd.protocol // "N/A"),
        ($fwd.src_hostname // "N/A"),
        ($fwd.src_port // "N/A"),
        ($fwd.dest_ip // "N/A"),
        ($fwd.dest_port // "N/A")
      ] | 
      @tsv
    ' | while IFS=$'\t' read -r id protocol src_hostname src_port dest_ip dest_port; do
        # Truncate hostname jika terlalu panjang
        if [[ ${#src_hostname} -gt 15 ]]; then
            src_hostname="${src_hostname:0:12}..."
        fi
        
        if [[ "$NO_COLOR" == "true" ]]; then
            printf "ID: %-4s | %s | %-15s | %s -> %s:%s\n" "$id" "$protocol" "$src_hostname" "$src_port" "$dest_ip" "$dest_port"
        else
            local protocol_color=""
            case "$protocol" in
                "HTTP") protocol_color="\e[32m" ;;
                "HTTPS") protocol_color="\e[31m" ;;
                "TCP") protocol_color="\e[34m" ;;
                *) protocol_color="\e[37m" ;;
            esac
            
            printf "\e[1;93mID: %-4s\e[0m | ${protocol_color}%-5s\e[0m | \e[94m%-15s\e[0m | \e[91m%s\e[0m -> \e[96m%s\e[0m:\e[93m%s\e[0m\n" "$id" "$protocol" "$src_hostname" "$src_port" "$dest_ip" "$dest_port"
        fi
    done
    
    if [[ "$NO_COLOR" != "true" ]]; then
        echo ""
    fi
}

# Fungsi untuk mendapatkan data forwarding berdasarkan ID(s)
get_forwarding_data() {
    local forwarding_response="$1"
    local vdfids="$2"
    
    # Split IDs berdasarkan koma
    IFS=',' read -ra ID_ARRAY <<< "$vdfids"
    
    for id in "${ID_ARRAY[@]}"; do
        # Trim whitespace
        id=$(echo "$id" | xargs)
        
        local forwarding_data=$(echo "$forwarding_response" | jq -r --arg id "$id" '
          .haproxydata // {} | 
          to_entries[] | 
          select(.value.id == $id) | 
          .value |
          [
            (.id // ""),
            (.protocol // ""),
            (.src_hostname // ""),
            (.src_port // ""),
            (.dest_ip // ""),
            (.dest_port // "")
          ] | 
          @tsv
        ')
        
        if [[ -n "$forwarding_data" ]]; then
            echo "$forwarding_data"
        fi
    done
}

# Fungsi untuk menampilkan konfirmasi penghapusan
show_delete_confirmation() {
    local forwarding_data="$1"
    local vpsid="$2"
    
    if [[ "$NO_COLOR" == "true" ]]; then
        echo "=== KONFIRMASI PENGHAPUSAN ==="
        echo "VPSID: $vpsid"
        echo ""
        echo "Forwarding yang akan dihapus:"
        echo ""
    else
        echo ""
        echo -e "\e[1;31m⚠️ KONFIRMASI PENGHAPUSAN\e[0m"
        echo -e "\e[1;36mVPSID:\e[0m \e[1;32m$vpsid\e[0m"
        printf "\e[2;37m%s\e[0m\n" "------------------------------------------------"
        echo -e "\e[1;31m🗑️ Forwarding yang akan dihapus:\e[0m"
        echo ""
    fi
    
    # Parse dan tampilkan setiap forwarding
    echo "$forwarding_data" | while IFS=$'\t' read -r id protocol src_hostname src_port dest_ip dest_port; do
        if [[ "$NO_COLOR" == "true" ]]; then
            printf "ID: %-4s | %s | %s:%s -> %s:%s\n" "$id" "$protocol" "$src_hostname" "$src_port" "$dest_ip" "$dest_port"
        else
            local protocol_color=""
            case "$protocol" in
                "HTTP") protocol_color="\e[32m" ;;
                "HTTPS") protocol_color="\e[31m" ;;
                "TCP") protocol_color="\e[34m" ;;
                *) protocol_color="\e[37m" ;;
            esac
            
            printf "\e[1;91m🗑️ ID: %-4s\e[0m | ${protocol_color}%-5s\e[0m | \e[94m%s\e[0m:\e[91m%s\e[0m -> \e[96m%s\e[0m:\e[93m%s\e[0m\n" "$id" "$protocol" "$src_hostname" "$src_port" "$dest_ip" "$dest_port"
        fi
    done
    
    echo ""
    if [[ "$NO_COLOR" == "true" ]]; then
        echo "⚠️ PERINGATAN: Tindakan ini tidak dapat dibatalkan!"
        echo ""
        echo -n "Lanjutkan penghapusan? (y/N): "
    else
        echo -e "\e[1;31m⚠️ PERINGATAN: Tindakan ini tidak dapat dibatalkan!\e[0m"
        echo ""
        echo -e "\e[1;97m❓ Lanjutkan penghapusan? \e[0m\e[1;32m(y)\e[0m\e[1;37m/\e[0m\e[1;31m(N)\e[0m: "
    fi
}

# Fungsi untuk menghapus forwarding
delete_forwarding() {
    local vpsid="$1"
    local vdfids="$2"
    
    if [[ "$NO_COLOR" == "true" ]]; then
        echo "🗑️ Menghapus forwarding..."
    else
        echo -e "\e[1;31m🗑️ Menghapus forwarding...\e[0m"
    fi
    
    local response=$(curl -sk --max-time 30 -X POST \
        -d "vdf_action=delvdf&ids=${vdfids}" \
        "${API_URL}?act=managevdf&svs=${vpsid}&api=json&apikey=${API_KEY}&apipass=${API_PASS}")
    
    # Cek apakah ada error
    if [[ -z "$response" ]]; then
        echo "❌ Tidak ada respons dari API."
        return 1
    fi
    
    if ! echo "$response" | jq . > /dev/null 2>&1; then
        echo "❌ Respons API bukan JSON valid."
        echo "Respons: $response"
        return 1
    fi
    
    # Parsing untuk sukses message
    local done_msg=$(echo "$response" | jq -r '.done.msg // empty')
    local error_obj=$(echo "$response" | jq -r '.error // empty')
    
    if [[ -n "$done_msg" && "$done_msg" != "null" ]]; then
        if [[ "$NO_COLOR" == "true" ]]; then
            echo "✅ Forwarding berhasil dihapus!"
            echo "📝 Pesan: $done_msg"
        else
            echo -e "\e[1;32m✅ Forwarding berhasil dihapus!\e[0m"
            echo -e "\e[1;37m📝 Pesan:\e[0m \e[2;37m$done_msg\e[0m"
        fi
        return 0
    elif [[ -n "$error_obj" && "$error_obj" != "null" && "$error_obj" != "{}" ]]; then
        # Parse error messages
        local general_error=$(echo "$response" | jq -r '.error // empty')
        
        if [[ "$NO_COLOR" == "true" ]]; then
            echo "❌ Error saat menghapus forwarding:"
            echo "   ❌ Error: $general_error"
        else
            echo -e "\e[1;31m❌ Error saat menghapus forwarding:\e[0m"
            echo -e "\e[1;91m   ❌ Error:\e[0m \e[37m$general_error\e[0m"
        fi
        
        return 1
    else
        if [[ "$NO_COLOR" == "true" ]]; then
            echo "❌ Error: Response tidak dikenal"
            echo "📄 Raw response: $response"
        else
            echo -e "\e[1;31m❌ Error: Response tidak dikenal\e[0m"
            echo -e "\e[2;90m📄 Raw response: $response\e[0m"
        fi
        return 1
    fi
}

# Main logic
if [[ "$NO_COLOR" == "true" ]]; then
    echo "🔍 Mengambil daftar VM..."
else
    echo -e "\e[1;36m🔍 Mengambil daftar VM...\e[0m"
fi

vm_response=$(get_vm_list)

# Validasi respons VM
if [[ -z "$vm_response" ]]; then
    echo "❌ Tidak ada respons dari API VM."
    exit 1
fi

if ! echo "$vm_response" | jq . > /dev/null 2>&1; then
    echo "❌ Respons API VM bukan JSON valid."
    exit 1
fi

# Cek jumlah VM
vm_count=$(echo "$vm_response" | jq '.vs | length')

if [[ "$vm_count" == "0" ]]; then
    echo "❌ Tidak ada VM ditemukan."
    exit 1
fi

# Interactive mode atau parameter mode
if [[ "$INTERACTIVE" == "true" || (-z "$VPSID" && -z "$VDFID") ]]; then
    # Mode Interactive
    
    # Pilih VM
    if [[ -z "$VPSID" ]]; then
        if [[ "$vm_count" == "1" ]]; then
            VPSID=$(echo "$vm_response" | jq -r '.vs | to_entries[0].value.vpsid')
            if [[ "$NO_COLOR" == "true" ]]; then
                echo "ℹ️ Menggunakan VPSID: $VPSID (hanya 1 VM tersedia)"
            else
                echo -e "\e[32mℹ️ Menggunakan VPSID: $VPSID (hanya 1 VM tersedia)\e[0m"
            fi
        else
            show_vm_selection "$vm_response"
            if [[ "$NO_COLOR" == "true" ]]; then
                echo -n "💡 Masukkan VPSID yang dipilih: "
            else
                echo -e "\e[1;97m💡 Masukkan VPSID yang dipilih: \e[1;93m"
            fi
            read -r VPSID
            if [[ "$NO_COLOR" != "true" ]]; then
                echo -ne "\e[0m"
            fi
        fi
    fi
    
    # Validasi VPSID
    if ! echo "$vm_response" | jq -e ".vs.\"$VPSID\"" > /dev/null 2>&1; then
        echo "❌ VPSID tidak valid: $VPSID"
        exit 1
    fi
    
    # Ambil daftar forwarding
    if [[ "$NO_COLOR" == "true" ]]; then
        echo "🔍 Mengambil daftar forwarding..."
    else
        echo -e "\e[2;36m🔍 Mengambil daftar forwarding...\e[0m"
    fi
    
    forwarding_response=$(get_forwarding_list "$VPSID")
    
    # Validasi forwarding response
    if [[ -z "$forwarding_response" ]]; then
        echo "❌ Tidak ada respons dari API forwarding."
        exit 1
    fi
    
    # Cek apakah ada forwarding
    forwarding_count=$(echo "$forwarding_response" | jq '.haproxydata // {} | length')
    if [[ "$forwarding_count" == "0" ]]; then
        echo "❌ Tidak ada forwarding ditemukan untuk VPSID: $VPSID"
        exit 1
    fi
    
    # Tampilkan daftar forwarding
    show_forwarding_selection "$forwarding_response" "$VPSID"
    
    # Pilih forwarding untuk dihapus
    if [[ -z "$VDFID" ]]; then
        if [[ "$NO_COLOR" == "true" ]]; then
            echo "💡 Masukkan ID forwarding yang akan dihapus (pisahkan dengan koma untuk beberapa ID): "
            echo -n "ID(s): "
        else
            echo -e "\e[1;97m💡 Masukkan ID forwarding yang akan dihapus\e[0m"
            echo -e "\e[2;37m   (pisahkan dengan koma untuk beberapa ID)\e[0m"
            echo -e "\e[1;91mID(s): \e[1;93m"
        fi
        read -r VDFID
        if [[ "$NO_COLOR" != "true" ]]; then
            echo -ne "\e[0m"
        fi
    fi
    
    # Validasi VDFID(s)
    forwarding_data=$(get_forwarding_data "$forwarding_response" "$VDFID")
    if [[ -z "$forwarding_data" ]]; then
        echo "❌ ID forwarding tidak valid: $VDFID"
        exit 1
    fi
    
    # Tampilkan konfirmasi hanya jika tidak dalam mode force
    if [[ "$FORCE" != "true" ]]; then
        show_delete_confirmation "$forwarding_data" "$VPSID"
        read -r confirmation
        
        if [[ ! "$confirmation" =~ ^[Yy]$ ]]; then
            if [[ "$NO_COLOR" == "true" ]]; then
                echo "❌ Penghapusan dibatalkan."
            else
                echo -e "\e[1;33m❌ Penghapusan dibatalkan.\e[0m"
            fi
            exit 0
        fi
    fi
    
else
    # Mode Parameter
    
    # Validasi parameter wajib
    if [[ -z "$VPSID" ]]; then
        echo "❌ VPSID harus diisi. Gunakan -v atau --vpsid"
        exit 1
    fi
    
    if [[ -z "$VDFID" ]]; then
        echo "❌ VDFID harus diisi. Gunakan -f atau --vdfid"
        exit 1
    fi
    
    # Validasi VPSID
    if ! echo "$vm_response" | jq -e ".vs.\"$VPSID\"" > /dev/null 2>&1; then
        echo "❌ VPSID tidak valid: $VPSID"
        exit 1
    fi
    
    # Ambil daftar forwarding untuk validasi
    if [[ "$NO_COLOR" == "true" ]]; then
        echo "🔍 Mengambil daftar forwarding..."
    else
        echo -e "\e[2;36m🔍 Mengambil daftar forwarding...\e[0m"
    fi
    
    forwarding_response=$(get_forwarding_list "$VPSID")
    
    # Validasi forwarding response
    if [[ -z "$forwarding_response" ]]; then
        echo "❌ Tidak ada respons dari API forwarding."
        exit 1
    fi
    
    # Validasi VDFID(s)
    forwarding_data=$(get_forwarding_data "$forwarding_response" "$VDFID")
    if [[ -z "$forwarding_data" ]]; then
        echo "❌ ID forwarding tidak valid: $VDFID"
        exit 1
    fi
    
    # Tampilkan konfirmasi hanya jika tidak dalam mode force
    if [[ "$FORCE" != "true" ]]; then
        show_delete_confirmation "$forwarding_data" "$VPSID"
        read -r confirmation
        
        if [[ ! "$confirmation" =~ ^[Yy]$ ]]; then
            if [[ "$NO_COLOR" == "true" ]]; then
                echo "❌ Penghapusan dibatalkan."
            else
                echo -e "\e[1;33m❌ Penghapusan dibatalkan.\e[0m"
            fi
            exit 0
        fi
    fi
fi

# Eksekusi penghapusan
delete_forwarding "$VPSID" "$VDFID"

if [[ $? -eq 0 ]]; then
    if [[ "$NO_COLOR" == "true" ]]; then
        echo ""
        echo "🎉 Penghapusan forwarding selesai!"
    else
        echo ""
        echo -e "\e[1;32m🎉 Penghapusan forwarding selesai!\e[0m"
    fi
    exit 0
else
    exit 1
fi
