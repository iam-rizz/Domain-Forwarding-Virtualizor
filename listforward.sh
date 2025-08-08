#!/bin/bash

CONFIG_FILE="/etc/vm/data.conf"

# Variabel untuk opsi
SHOW_HELP=false
NO_COLOR=false
JSON_OUTPUT=false
VPSID=""
AUTO_SELECT=false

# Fungsi bantuan
show_help() {
    cat << EOF
Penggunaan: $0 [OPSI]

Script untuk menampilkan daftar Domain/Port Forwarding dari API VPS

OPSI:
    -h, --help          Tampilkan bantuan ini
    -n, --no-color      Nonaktifkan warna pada output
    -j, --json          Output dalam format JSON
    -v, --vpsid VPSID   Pilih VPSID secara manual
    -a, --auto          Auto-select jika hanya ada 1 VM
    
CONTOH:
    $0                  # Tampilkan pilihan VM dan forwarding
    $0 --vpsid 103      # Langsung tampilkan forwarding untuk VPSID 103
    $0 --auto           # Auto-select jika hanya 1 VM
    $0 --json           # Output format JSON

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
        -j|--json)
            JSON_OUTPUT=true
            shift
            ;;
        -v|--vpsid)
            VPSID="$2"
            shift 2
            ;;
        -a|--auto)
            AUTO_SELECT=true
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

# Fungsi untuk mendapatkan forwarding data
get_forwarding_data() {
    local vpsid="$1"
    local response=$(curl -sk --max-time 30 "${API_URL}?act=managevdf&svs=${vpsid}&novnc=6710&do=add&api=json&apikey=${API_KEY}&apipass=${API_PASS}")
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
        (if ($vm.status // 0) == 1 then "Up" else "Down" end)
      ] | 
      @tsv
    ' | while IFS=$'\t' read -r vpsid hostname status_raw; do
        # Truncate hostname jika terlalu panjang
        if [[ ${#hostname} -gt 15 ]]; then
            hostname="${hostname:0:12}..."
        fi
        
        if [[ "$NO_COLOR" == "true" ]]; then
            printf "%s) VPSID: %-6s | Hostname: %-15s | Status: %s\n" "$vpsid" "$vpsid" "$hostname" "$status_raw"
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
            
            printf "\e[1;93m%s\e[0m) VPSID: \e[1;36m%-6s\e[0m | Hostname: \e[35m%-15s\e[0m | Status: ${status_color}%s %s\e[0m\n" "$vpsid" "$vpsid" "$hostname" "$status_icon" "$status_raw"
        fi
    done
    
    if [[ "$NO_COLOR" != "true" ]]; then
        echo ""
    fi
}

# Fungsi untuk menampilkan forwarding data
show_forwarding_data() {
    local vpsid="$1"
    local forwarding_response="$2"
    
    # Jika output JSON diminta
    if [[ "$JSON_OUTPUT" == "true" ]]; then
        echo "$forwarding_response" | jq '.haproxydata'
        return
    fi
    
    # Cek apakah ada data forwarding
    local forwarding_count=$(echo "$forwarding_response" | jq '.haproxydata | length')
    
    if [[ "$forwarding_count" == "0" ]]; then
        if [[ "$NO_COLOR" == "true" ]]; then
            echo "ℹ️ Tidak ada domain/port forwarding untuk VPSID: $vpsid"
        else
            echo -e "\e[33mℹ️ Tidak ada domain/port forwarding untuk VPSID: $vpsid\e[0m"
        fi
        return
    fi
    
    # Header sederhana
    if [[ "$NO_COLOR" == "true" ]]; then
        echo "=== DOMAIN/PORT FORWARDING untuk VPSID: $vpsid ==="
        printf "%-4s | %-8s | %-18s | %-8s | %-15s | %-8s\n" "ID" "Protocol" "Source Host" "Src Port" "Dest IP" "Dst Port"
        printf "%s\n" "------------------------------------------------------------------------------"
    else
        echo ""
        echo -e "\e[1;36m🌐 DOMAIN/PORT FORWARDING untuk VPSID: \e[1;32m$vpsid\e[0m"
        printf "\e[1;37m%-4s | %-8s | %-18s | %-8s | %-15s | %-8s\e[0m\n" "ID" "Protocol" "Source Host" "Src Port" "Dest IP" "Dst Port"
        printf "\e[2;37m%s\e[0m\n" "------------------------------------------------------------------------------"
    fi
    
    # Tampilkan data forwarding dengan warna sederhana
    echo "$forwarding_response" | jq -r '
      .haproxydata | 
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
        if [[ ${#src_hostname} -gt 18 ]]; then
            src_hostname="${src_hostname:0:15}..."
        fi
        
        if [[ "$NO_COLOR" == "true" ]]; then
            printf "%-4s | %-8s | %-18s | %-8s | %-15s | %-8s\n" "$id" "$protocol" "$src_hostname" "$src_port" "$dest_ip" "$dest_port"
        else
            # Tentukan warna untuk protocol
            local protocol_color=""
            case "${protocol^^}" in
                "HTTP")  protocol_color="\e[1;32m" ;;  # Hijau
                "HTTPS") protocol_color="\e[1;31m" ;;  # Merah
                "TCP")   protocol_color="\e[1;34m" ;;  # Biru
                *)       protocol_color="\e[1;37m" ;;  # Putih
            esac
            
            # Tentukan warna untuk port berdasarkan range
            local src_port_color=""
            if [[ "$src_port" =~ ^[0-9]+$ ]]; then
                if (( src_port <= 1024 )); then
                    src_port_color="\e[91m"  # Merah terang untuk system ports
                elif (( src_port <= 49151 )); then
                    src_port_color="\e[93m"  # Kuning untuk user ports
                else
                    src_port_color="\e[92m"  # Hijau untuk dynamic ports
                fi
            else
                src_port_color="\e[37m"
            fi
            
            local dest_port_color=""
            if [[ "$dest_port" =~ ^[0-9]+$ ]]; then
                if (( dest_port <= 1024 )); then
                    dest_port_color="\e[91m"  # Merah terang untuk system ports
                elif (( dest_port <= 49151 )); then
                    dest_port_color="\e[93m"  # Kuning untuk user ports
                else
                    dest_port_color="\e[92m"  # Hijau untuk dynamic ports
                fi
            else
                dest_port_color="\e[37m"
            fi
            
            printf "\e[1;93m%-4s\e[0m | ${protocol_color}%-8s\e[0m | \e[94m%-18s\e[0m | ${src_port_color}%-8s\e[0m | \e[96m%-15s\e[0m | ${dest_port_color}%-8s\e[0m\n" "$id" "$protocol" "$src_hostname" "$src_port" "$dest_ip" "$dest_port"
        fi
    done
    
    # Footer sederhana
    if [[ "$NO_COLOR" != "true" ]]; then
        echo ""
        echo -e "\e[2;37m� Protocol: \e[32mHTTP\e[37m | \e[31mHTTPS\e[37m | \e[34mTCP\e[37m  •  Ports: \e[91mSystem\e[37m | \e[93mUser\e[37m | \e[92mDynamic\e[0m"
        echo ""
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

# Logika pemilihan VPSID
if [[ -n "$VPSID" ]]; then
    # VPSID sudah ditentukan via parameter
    selected_vpsid="$VPSID"
elif [[ "$vm_count" == "1" && "$AUTO_SELECT" == "true" ]]; then
    # Auto-select jika hanya 1 VM dan flag auto diaktifkan
    selected_vpsid=$(echo "$vm_response" | jq -r '.vs | to_entries[0].value.vpsid')
    if [[ "$NO_COLOR" == "true" ]]; then
        echo "ℹ️ Auto-selected VPSID: $selected_vpsid (hanya 1 VM tersedia)"
    else
        echo -e "\e[32mℹ️ Auto-selected VPSID: $selected_vpsid (hanya 1 VM tersedia)\e[0m"
    fi
elif [[ "$vm_count" == "1" ]]; then
    # Hanya 1 VM, langsung pilih
    selected_vpsid=$(echo "$vm_response" | jq -r '.vs | to_entries[0].value.vpsid')
    if [[ "$NO_COLOR" == "true" ]]; then
        echo "ℹ️ Menggunakan VPSID: $selected_vpsid (hanya 1 VM tersedia)"
    else
        echo -e "\e[32mℹ️ Menggunakan VPSID: $selected_vpsid (hanya 1 VM tersedia)\e[0m"
    fi
else
    # Tampilkan pilihan jika lebih dari 1 VM
    show_vm_selection "$vm_response"
    if [[ "$NO_COLOR" == "true" ]]; then
        echo -n "Masukkan VPSID yang dipilih: "
    else
        echo -e "\e[1;97m💡 Masukkan VPSID yang dipilih: \e[1;93m"
    fi
    read -r selected_vpsid
    if [[ "$NO_COLOR" != "true" ]]; then
        echo -ne "\e[0m"
    fi
    
    # Validasi pilihan
    if ! echo "$vm_response" | jq -e ".vs.\"$selected_vpsid\"" > /dev/null 2>&1; then
        echo "❌ VPSID tidak valid: $selected_vpsid"
        exit 1
    fi
fi

echo ""
if [[ "$NO_COLOR" == "true" ]]; then
    echo "🔍 Mengambil data forwarding untuk VPSID: $selected_vpsid..."
else
    echo -e "\e[1;36m🔍 Mengambil data forwarding untuk VPSID: \e[1;32m$selected_vpsid\e[1;36m...\e[0m"
fi

# Ambil data forwarding
forwarding_response=$(get_forwarding_data "$selected_vpsid")

# Validasi respons forwarding
if [[ -z "$forwarding_response" ]]; then
    echo "❌ Tidak ada respons dari API forwarding."
    exit 1
fi

if ! echo "$forwarding_response" | jq . > /dev/null 2>&1; then
    echo "❌ Respons API forwarding bukan JSON valid."
    exit 1
fi

# Tampilkan data forwarding
show_forwarding_data "$selected_vpsid" "$forwarding_response"
