#!/bin/bash

CONFIG_FILE="/etc/vm/data.conf"

# Variabel untuk opsi
SHOW_HELP=false
NO_COLOR=false
VPSID=""
VDFID=""
PROTOCOL=""
SRC_HOSTNAME=""
SRC_PORT=""
DEST_PORT=""
INTERACTIVE=false

# Fungsi bantuan
show_help() {
    cat << EOF
Penggunaan: $0 [OPSI]

Script untuk mengedit Domain/Port Forwarding di API VPS

OPSI:
    -h, --help              Tampilkan bantuan ini
    -n, --no-color          Nonaktifkan warna pada output
    -v, --vpsid VPSID       Pilih VPSID secara manual
    -f, --vdfid VDFID       ID forwarding yang akan diedit
    -p, --protocol PROTOCOL Protocol (HTTP/HTTPS/TCP)
    -d, --domain DOMAIN     Source hostname/domain baru
    -s, --src-port PORT     Source port baru
    -t, --dest-port PORT    Destination port baru
    -i, --interactive       Mode interactive (step-by-step)
    
CONTOH:
    $0 --interactive                                    # Mode step-by-step
    $0 --vpsid 103 --vdfid 596 --protocol HTTPS        # Edit protocol ke HTTPS (auto port 443)
    $0 -v 103 -f 596 -p HTTP -d secure.app.com         # Edit protocol & domain HTTP (auto port 80)
    $0 -v 103 -f 596 -s 30222 -t 22                    # Edit ports untuk TCP

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
        -p|--protocol)
            PROTOCOL="$2"
            shift 2
            ;;
        -d|--domain)
            SRC_HOSTNAME="$2"
            shift 2
            ;;
        -s|--src-port)
            SRC_PORT="$2"
            shift 2
            ;;
        -t|--dest-port)
            DEST_PORT="$2"
            shift 2
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

# Fungsi untuk menampilkan daftar VM
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
            
            printf "\e[1;93m%s)\e[0m \e[1;36mVPSID:\e[0m \e[1;32m%-6s\e[0m | \e[1;36mHostname:\e[0m \e[1;94m%-15s\e[0m | \e[1;36mStatus:\e[0m %s ${status_color}%s\e[0m\n" "$vpsid" "$vpsid" "$hostname" "$status_icon" "$status_raw"
        fi
    done
    
    echo ""
}

# Fungsi untuk mendapatkan IP internal VM
get_vm_internal_ip() {
    local vpsid="$1" 
    local vm_response="$2"
    local internal_ip=$(echo "$vm_response" | jq -r ".vs.\"$vpsid\".ips | to_entries[] | select(.value | test(\"^[0-9.]+$\")) | .value")
    echo "$internal_ip"
}

# Fungsi untuk mendapatkan konfigurasi server
get_server_config() {
    local vpsid="$1"
    local response=$(curl -sk --max-time 30 "${API_URL}?act=managevdf&svs=${vpsid}&novnc=6710&do=add&api=json&apikey=${API_KEY}&apipass=${API_PASS}")
    echo "$response"
}

# Fungsi untuk parsing informasi HAProxy
get_haproxy_info() {
    local server_response="$1"
    local allowed_ports=$(echo "$server_response" | jq -r '.server_haconfigs[]?.haproxy_allowedports // empty')
    local reserved_ports=$(echo "$server_response" | jq -r '.server_haconfigs[]?.haproxy_reservedports // empty') 
    local reserved_http_ports=$(echo "$server_response" | jq -r '.server_haconfigs[]?.haproxy_reservedports_http // empty')
    local src_ips=$(echo "$server_response" | jq -r '.server_haconfigs[]?.haproxy_src_ips // empty')
    
    echo "$allowed_ports|$reserved_ports|$reserved_http_ports|$src_ips"
}

# Fungsi untuk validasi port
validate_port() {
    local port="$1"
    local haproxy_info="$2"
    local protocol="$3"
    
    IFS='|' read -r allowed_ports reserved_ports reserved_http_ports src_ips <<< "$haproxy_info"
    
    # Cek jika port number valid
    if ! [[ "$port" =~ ^[0-9]+$ ]] || [ "$port" -lt 1 ] || [ "$port" -gt 65535 ]; then
        echo "Port harus berupa angka antara 1-65535"
        return 1
    fi
    
    # Cek jika port sudah digunakan/reserved
    if [[ -n "$reserved_ports" && "$reserved_ports" == *"$port"* ]]; then
        # Cek apakah port 80/443 untuk HTTP/HTTPS
        if [[ "$port" == "80" && "$protocol" == "HTTP" ]] || [[ "$port" == "443" && "$protocol" == "HTTPS" ]]; then
            return 0  # Allow port 80 for HTTP and 443 for HTTPS
        fi
        echo "Port $port sudah digunakan/reserved. Untuk HTTP gunakan port 80, untuk HTTPS gunakan port 443"
        return 1
    fi
    
    # Cek jika port diizinkan (jika ada pembatasan)
    if [[ -n "$allowed_ports" && "$allowed_ports" != *"$port"* ]]; then
        echo "Port $port tidak diizinkan. Port yang diizinkan: $allowed_ports"
        return 1
    fi
    
    return 0
}

# Fungsi untuk mendapatkan daftar forwarding dari VM
get_forwarding_list() {
    local vpsid="$1"
    local response=$(curl -sk --max-time 30 "${API_URL}?act=managevdf&svs=${vpsid}&api=json&apikey=${API_KEY}&apipass=${API_PASS}")
    echo "$response"
}

# Fungsi untuk menampilkan daftar forwarding dan memilih
show_forwarding_selection() {
    local forwarding_response="$1"
    local vpsid="$2"
    
    if [[ "$NO_COLOR" == "true" ]]; then
        echo "=== PILIH FORWARDING UNTUK EDIT ==="
        echo "VPSID: $vpsid"
        echo ""
    else
        echo ""
        echo -e "\e[1;33m📝 PILIH FORWARDING UNTUK EDIT:\e[0m"
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

# Fungsi untuk mendapatkan data forwarding berdasarkan ID
get_current_forwarding_data() {
    local forwarding_response="$1"
    local vdfid="$2"
    
    echo "$forwarding_response" | jq -r --arg id "$vdfid" '
      .haproxydata // {} | 
      to_entries[] | 
      select(.value.id == $id) | 
      .value |
      [
        (.protocol // ""),
        (.src_hostname // ""),
        (.src_port // ""),
        (.dest_ip // ""),
        (.dest_port // "")
      ] | 
      @tsv
    '
}

# Fungsi untuk menampilkan perbandingan before vs after
show_edit_comparison() {
    local old_protocol="$1"
    local old_src_hostname="$2" 
    local old_src_port="$3"
    local old_dest_ip="$4"
    local old_dest_port="$5"
    local new_protocol="$6"
    local new_src_hostname="$7"
    local new_src_port="$8"
    local new_dest_ip="$9"
    local new_dest_port="${10}"
    
    if [[ "$NO_COLOR" == "true" ]]; then
        echo "=== KONFIRMASI PERUBAHAN ==="
        echo "Field         | Before          | After"
        echo "--------------|-----------------|------------------"
        echo "Protocol      | $old_protocol   | $new_protocol"
        echo "Source Host   | $old_src_hostname | $new_src_hostname"
        echo "Source Port   | $old_src_port   | $new_src_port"
        echo "Dest IP       | $old_dest_ip    | $new_dest_ip"
        echo "Dest Port     | $old_dest_port  | $new_dest_port"
        echo ""
        echo -n "Lanjutkan update? (y/N): "
    else
        echo ""
        echo -e "\e[1;33m📋 KONFIRMASI PERUBAHAN\e[0m"
        printf "\e[2;37m%s\e[0m\n" "--------------------------------------------------------"
        printf "\e[1;36m%-12s\e[0m | \e[1;91m%-15s\e[0m | \e[1;92m%-15s\e[0m\n" "Field" "Before" "After"
        printf "\e[2;37m%s\e[0m\n" "--------------------------------------------------------"
        printf "\e[1;37m%-12s\e[0m | \e[91m%-15s\e[0m | \e[92m%-15s\e[0m\n" "Protocol" "$old_protocol" "$new_protocol"
        printf "\e[1;37m%-12s\e[0m | \e[91m%-15s\e[0m | \e[92m%-15s\e[0m\n" "Source Host" "$old_src_hostname" "$new_src_hostname"
        printf "\e[1;37m%-12s\e[0m | \e[91m%-15s\e[0m | \e[92m%-15s\e[0m\n" "Source Port" "$old_src_port" "$new_src_port"
        printf "\e[1;37m%-12s\e[0m | \e[91m%-15s\e[0m | \e[92m%-15s\e[0m\n" "Dest IP" "$old_dest_ip" "$new_dest_ip"
        printf "\e[1;37m%-12s\e[0m | \e[91m%-15s\e[0m | \e[92m%-15s\e[0m\n" "Dest Port" "$old_dest_port" "$new_dest_port"
        echo ""
        echo -e "\e[1;97m❓ Lanjutkan update? \e[0m\e[1;32m(y)\e[0m\e[1;37m/\e[0m\e[1;31m(N)\e[0m: "
    fi
}

# Fungsi untuk update forwarding
update_forwarding() {
    local vpsid="$1"
    local vdfid="$2"
    local protocol="$3"
    local src_hostname="$4"
    local src_port="$5"
    local dest_ip="$6"
    local dest_port="$7"
    
    if [[ "$NO_COLOR" == "true" ]]; then
        echo "🔄 Mengupdate forwarding..."
    else
        echo -e "\e[1;36m🔄 Mengupdate forwarding...\e[0m"
    fi
    
    local response=$(curl -sk --max-time 30 -X POST \
        -d "vdf_action=editvdf&protocol=${protocol}&src_hostname=${src_hostname}&src_port=${src_port}&dest_ip=${dest_ip}&dest_port=${dest_port}&vdfid=${vdfid}" \
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
            echo "✅ Forwarding berhasil diupdate!"
            echo "📝 Pesan: $done_msg"
        else
            echo -e "\e[1;32m✅ Forwarding berhasil diupdate!\e[0m"
            echo -e "\e[1;37m📝 Pesan:\e[0m \e[2;37m$done_msg\e[0m"
        fi
        return 0
    elif [[ -n "$error_obj" && "$error_obj" != "null" && "$error_obj" != "{}" ]]; then
        # Parse error messages
        local src_port_error=$(echo "$response" | jq -r '.error.src_port // empty')
        local src_hostname_error=$(echo "$response" | jq -r '.error.src_hostname // empty')
        local general_error=$(echo "$response" | jq -r '.error // empty')
        
        if [[ "$NO_COLOR" == "true" ]]; then
            echo "❌ Error saat mengupdate forwarding:"
        else
            echo -e "\e[1;31m❌ Error saat mengupdate forwarding:\e[0m"
        fi
        
        if [[ -n "$src_port_error" && "$src_port_error" != "null" ]]; then
            if [[ "$NO_COLOR" == "true" ]]; then
                echo "   🚫 Port Error: $src_port_error"
            else
                echo -e "\e[1;91m   🚫 Port Error:\e[0m \e[37m$src_port_error\e[0m"
            fi
        fi
        
        if [[ -n "$src_hostname_error" && "$src_hostname_error" != "null" ]]; then
            if [[ "$NO_COLOR" == "true" ]]; then
                echo "   🌐 Domain Error: $src_hostname_error"
            else
                echo -e "\e[1;91m   🌐 Domain Error:\e[0m \e[37m$src_hostname_error\e[0m"
            fi
        fi
        
        if [[ -n "$general_error" && "$general_error" != "null" ]]; then
            if [[ "$NO_COLOR" == "true" ]]; then
                echo "   ❌ Error: $general_error"
            else
                echo -e "\e[1;91m   ❌ Error:\e[0m \e[37m$general_error\e[0m"
            fi
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
    
    # Pilih forwarding untuk edit
    if [[ -z "$VDFID" ]]; then
        if [[ "$NO_COLOR" == "true" ]]; then
            echo -n "💡 Masukkan ID forwarding yang akan diedit: "
        else
            echo -e "\e[1;97m💡 Masukkan ID forwarding yang akan diedit: \e[1;93m"
        fi
        read -r VDFID
        if [[ "$NO_COLOR" != "true" ]]; then
            echo -ne "\e[0m"
        fi
    fi
    
    # Validasi VDFID
    current_data=$(get_current_forwarding_data "$forwarding_response" "$VDFID")
    if [[ -z "$current_data" ]]; then
        echo "❌ ID forwarding tidak valid: $VDFID"
        exit 1
    fi
    
    # Parse data current
    IFS=$'\t' read -r current_protocol current_src_hostname current_src_port current_dest_ip current_dest_port <<< "$current_data"
    
    if [[ "$NO_COLOR" == "true" ]]; then
        echo ""
        echo "=== DATA FORWARDING SAAT INI ==="
        echo "Protocol: $current_protocol"
        echo "Source: $current_src_hostname:$current_src_port"
        echo "Destination: $current_dest_ip:$current_dest_port"
        echo ""
    else
        echo ""
        echo -e "\e[1;36m📄 DATA FORWARDING SAAT INI:\e[0m"
        printf "\e[2;37m%s\e[0m\n" "--------------------------------"
        echo -e "\e[1;37mProtocol:\e[0m \e[1;35m$current_protocol\e[0m"
        echo -e "\e[1;37mSource:\e[0m \e[1;94m$current_src_hostname\e[0m:\e[1;91m$current_src_port\e[0m"
        echo -e "\e[1;37mDestination:\e[0m \e[1;96m$current_dest_ip\e[0m:\e[1;93m$current_dest_port\e[0m"
        echo ""
    fi
    
    # Ambil server config untuk validasi
    if [[ "$NO_COLOR" == "true" ]]; then
        echo "🔍 Mengambil konfigurasi server..."
    else
        echo -e "\e[2;36m🔍 Mengambil konfigurasi server...\e[0m"
    fi
    
    server_config=$(get_server_config "$VPSID")
    haproxy_info=$(get_haproxy_info "$server_config")
    IFS='|' read -r allowed_ports reserved_ports reserved_http_ports src_ips <<< "$haproxy_info"
    
    # Set nilai default dari data current
    PROTOCOL="$current_protocol"
    SRC_HOSTNAME="$current_src_hostname"
    SRC_PORT="$current_src_port"
    DEST_PORT="$current_dest_port"
    
    # === EDIT FIELDS ===
    
    # 1. Edit Protocol
    echo ""
    if [[ "$NO_COLOR" == "true" ]]; then
        echo "Protocol saat ini: $current_protocol"
        echo "Protocol tersedia: HTTP, HTTPS, TCP"
        echo -n "Masukkan protocol baru (atau tekan Enter untuk tidak mengubah): "
    else
        echo -e "\e[2;37mProtocol saat ini:\e[0m \e[1;35m$current_protocol\e[0m"
        echo -e "\e[1;36m🌐 Protocol tersedia:\e[0m \e[32mHTTP\e[0m, \e[31mHTTPS\e[0m, \e[34mTCP\e[0m"
        echo -e "\e[1;97m💡 Masukkan protocol baru \e[2;37m(atau tekan Enter untuk tidak mengubah)\e[0m: \e[1;35m"
    fi
    read -r new_protocol
    if [[ "$NO_COLOR" != "true" ]]; then
        echo -ne "\e[0m"
    fi
    
    # Jika kosong, gunakan protocol yang lama
    if [[ -n "$new_protocol" ]]; then
        PROTOCOL=$(echo "$new_protocol" | tr '[:lower:]' '[:upper:]')
        if [[ ! "$PROTOCOL" =~ ^(HTTP|HTTPS|TCP)$ ]]; then
            echo "❌ Protocol tidak valid: $new_protocol"
            exit 1
        fi
    fi
    
    # 2. Edit Source Hostname (jika protocol HTTP/HTTPS)
    if [[ "$PROTOCOL" == "HTTP" || "$PROTOCOL" == "HTTPS" ]]; then
        echo ""
        if [[ "$NO_COLOR" == "true" ]]; then
            echo "Source hostname saat ini: $current_src_hostname"
            echo -n "Masukkan hostname/domain baru (atau tekan Enter untuk tidak mengubah): "
        else
            echo -e "\e[2;37mSource hostname saat ini:\e[0m \e[1;94m$current_src_hostname\e[0m"
            echo -e "\e[1;97m💡 Masukkan hostname/domain baru \e[2;37m(atau tekan Enter untuk tidak mengubah)\e[0m: \e[1;94m"
        fi
        read -r new_src_hostname
        if [[ "$NO_COLOR" != "true" ]]; then
            echo -ne "\e[0m"
        fi
        
        # Jika kosong, gunakan hostname yang lama
        if [[ -n "$new_src_hostname" ]]; then
            SRC_HOSTNAME="$new_src_hostname"
        fi
        
        # Auto-set port berdasarkan protocol
        if [[ "$PROTOCOL" == "HTTP" ]]; then
            SRC_PORT="80"
            DEST_PORT="80"
            if [[ "$NO_COLOR" == "true" ]]; then
                echo "🔧 Auto-set ports: Source 80, Destination 80 (HTTP)"
            else
                echo -e "\e[2;36m🔧 Auto-set ports:\e[0m \e[1;91mSource 80\e[0m, \e[1;93mDestination 80\e[0m \e[2;37m(HTTP)\e[0m"
            fi
        elif [[ "$PROTOCOL" == "HTTPS" ]]; then
            SRC_PORT="443" 
            DEST_PORT="443"
            if [[ "$NO_COLOR" == "true" ]]; then
                echo "🔧 Auto-set ports: Source 443, Destination 443 (HTTPS)"
            else
                echo -e "\e[2;36m🔧 Auto-set ports:\e[0m \e[1;91mSource 443\e[0m, \e[1;93mDestination 443\e[0m \e[2;37m(HTTPS)\e[0m"
            fi
        fi
        
    elif [[ "$PROTOCOL" == "TCP" ]]; then
        # Untuk TCP, gunakan source IP dari HAProxy config
        if [[ -n "$src_ips" && "$src_ips" != "null" ]]; then
            # Ambil IP pertama dari daftar src_ips
            SRC_HOSTNAME=$(echo "$src_ips" | cut -d',' -f1)
            if [[ "$NO_COLOR" == "true" ]]; then
                echo "🔍 Auto-detect source IP: $SRC_HOSTNAME"
            else
                echo -e "\e[2;36m🔍 Auto-detect source IP:\e[0m \e[1;94m$SRC_HOSTNAME\e[0m"
            fi
        else
            SRC_HOSTNAME="$current_src_hostname"
        fi
        
        # Untuk TCP, tetap edit port manual
        # 3. Edit Source Port (hanya untuk TCP)
        echo ""
        if [[ "$NO_COLOR" == "true" ]]; then
            echo "Source port saat ini: $current_src_port"
            if [[ -n "$allowed_ports" && "$allowed_ports" != "null" ]]; then
                echo "💡 Port yang diizinkan: $allowed_ports"
            fi
            if [[ -n "$reserved_ports" && "$reserved_ports" != "null" ]]; then
                echo "🚫 Port yang sudah digunakan: $reserved_ports"
            fi
        else
            echo -e "\e[2;37mSource port saat ini:\e[0m \e[1;91m$current_src_port\e[0m"
            if [[ -n "$allowed_ports" && "$allowed_ports" != "null" ]]; then
                echo -e "\e[2;36m💡 Port yang diizinkan:\e[0m \e[93m$allowed_ports\e[0m"
            fi
            if [[ -n "$reserved_ports" && "$reserved_ports" != "null" ]]; then
                echo -e "\e[2;31m🚫 Port yang sudah digunakan:\e[0m \e[91m$reserved_ports\e[0m"
            fi
        fi
        
        while true; do
            if [[ "$NO_COLOR" == "true" ]]; then
                echo -n "Masukkan source port baru (atau tekan Enter untuk tidak mengubah): "
            else
                echo -e "\e[1;97m💡 Masukkan source port baru \e[2;37m(atau tekan Enter untuk tidak mengubah)\e[0m: \e[1;91m"
            fi
            read -r new_src_port
            if [[ "$NO_COLOR" != "true" ]]; then
                echo -ne "\e[0m"
            fi
            
            # Jika kosong, gunakan port yang lama
            if [[ -z "$new_src_port" ]]; then
                SRC_PORT="$current_src_port"
                break
            fi
            
            if validation_result=$(validate_port "$new_src_port" "$haproxy_info" "$PROTOCOL"); then
                SRC_PORT="$new_src_port"
                break
            else
                if [[ "$NO_COLOR" == "true" ]]; then
                    echo "❌ $validation_result"
                else
                    echo -e "\e[1;31m❌ $validation_result\e[0m"
                fi
            fi
        done
        
        # 4. Edit Destination Port (hanya untuk TCP)
        echo ""
        if [[ "$NO_COLOR" == "true" ]]; then
            echo "Destination port saat ini: $current_dest_port"
            echo -n "Masukkan destination port baru (atau tekan Enter untuk tidak mengubah): "
        else
            echo -e "\e[2;37mDestination port saat ini:\e[0m \e[1;93m$current_dest_port\e[0m"
            echo -e "\e[1;97m💡 Masukkan destination port baru \e[2;37m(atau tekan Enter untuk tidak mengubah)\e[0m: \e[1;93m"
        fi
        read -r new_dest_port
        if [[ "$NO_COLOR" != "true" ]]; then
            echo -ne "\e[0m"
        fi
        
        # Jika kosong, gunakan port yang lama
        if [[ -z "$new_dest_port" ]]; then
            DEST_PORT="$current_dest_port"
        else
            # Validasi destination port
            if [[ ! "$new_dest_port" =~ ^[0-9]+$ ]] || [[ "$new_dest_port" -lt 1 ]] || [[ "$new_dest_port" -gt 65535 ]]; then
                echo "❌ Destination port harus berupa angka antara 1-65535"
                exit 1
            fi
            DEST_PORT="$new_dest_port"
        fi
    fi
    
    # Auto-detect destination IP
    dest_ip=$(get_vm_internal_ip "$VPSID" "$vm_response")
    if [[ -z "$dest_ip" ]]; then
        echo "❌ Tidak dapat menemukan IP internal untuk VPSID: $VPSID"
        exit 1
    fi
    
else
    # Mode Command Line Parameters
    
    # Validasi parameter required
    if [[ -z "$VPSID" || -z "$VDFID" ]]; then
        echo "❌ Parameter tidak lengkap. Required: --vpsid, --vdfid"
        echo "Gunakan --interactive untuk mode step-by-step atau --help untuk bantuan"
        exit 1
    fi
    
    # Ambil daftar forwarding untuk validasi
    forwarding_response=$(get_forwarding_list "$VPSID")
    current_data=$(get_current_forwarding_data "$forwarding_response" "$VDFID")
    
    if [[ -z "$current_data" ]]; then
        echo "❌ ID forwarding tidak valid: $VDFID"
        exit 1
    fi
    
    # Parse data current
    IFS=$'\t' read -r current_protocol current_src_hostname current_src_port current_dest_ip current_dest_port <<< "$current_data"
    
    # Set nilai default dari data current jika tidak disediakan
    PROTOCOL=${PROTOCOL:-$current_protocol}
    SRC_HOSTNAME=${SRC_HOSTNAME:-$current_src_hostname}
    SRC_PORT=${SRC_PORT:-$current_src_port}
    DEST_PORT=${DEST_PORT:-$current_dest_port}
    
    # Auto-detect destination IP
    dest_ip=$(get_vm_internal_ip "$VPSID" "$vm_response")
    if [[ -z "$dest_ip" ]]; then
        echo "❌ Tidak dapat menemukan IP internal untuk VPSID: $VPSID"
        exit 1
    fi
fi

# Validasi protocol
PROTOCOL=$(echo "$PROTOCOL" | tr '[:lower:]' '[:upper:]')
if [[ ! "$PROTOCOL" =~ ^(HTTP|HTTPS|TCP)$ ]]; then
    echo "❌ Protocol tidak valid: $PROTOCOL"
    exit 1
fi

# Validasi port (harus numerik)
if [[ ! "$SRC_PORT" =~ ^[0-9]+$ ]] || [[ ! "$DEST_PORT" =~ ^[0-9]+$ ]]; then
    echo "❌ Port harus berupa angka"
    exit 1
fi

# Tampilkan perbandingan
show_edit_comparison "$current_protocol" "$current_src_hostname" "$current_src_port" "$current_dest_ip" "$current_dest_port" "$PROTOCOL" "$SRC_HOSTNAME" "$SRC_PORT" "$dest_ip" "$DEST_PORT"

read -r confirm
if [[ "$confirm" =~ ^[Yy]$ ]]; then
    update_forwarding "$VPSID" "$VDFID" "$PROTOCOL" "$SRC_HOSTNAME" "$SRC_PORT" "$dest_ip" "$DEST_PORT"
else
    if [[ "$NO_COLOR" == "true" ]]; then
        echo "❌ Update dibatalkan."
    else
        echo -e "\e[1;31m❌ Update dibatalkan.\e[0m"
    fi
fi
