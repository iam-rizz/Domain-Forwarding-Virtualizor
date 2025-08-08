#!/bin/bash

CONFIG_FILE="/etc/vm/data.conf"

SHOW_HELP=false
NO_COLOR=false
VPSID=""
PROTOCOL=""
SRC_HOSTNAME=""
SRC_PORT=""
DEST_PORT=""
INTERACTIVE=false

show_help() {
    cat << EOF
Penggunaan: $0 [OPSI]

Script untuk menambahkan Domain/Port Forwarding ke API VPS

OPSI:
    -h, --help              Tampilkan bantuan ini
    -n, --no-color          Nonaktifkan warna pada output
    -v, --vpsid VPSID       Pilih VPSID secara manual
    -p, --protocol PROTOCOL Protocol (HTTP/HTTPS/TCP) - default: TCP
    -d, --domain DOMAIN     Source hostname/domain
    -s, --src-port PORT     Source port (external)
    -t, --dest-port PORT    Destination port (internal VM)
    -i, --interactive       Mode interactive (step-by-step)
    
CONTOH:
    $0 --interactive                                    # Mode step-by-step
    $0 --vpsid 103 --protocol HTTP --domain app.com --src-port 80 --dest-port 8080
    $0 -v 103 -p TCP -d 45.158.126.130 -s 2222 -t 22  # SSH forwarding
    $0 -v 105 -p HTTPS -d secure.app.com -s 443 -t 443 # HTTPS forwarding

EOF
}

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

# Fungsi untuk mendapatkan IP internal VM
get_vm_internal_ip() {
    local vpsid="$1"
    local vm_response="$2"
    local internal_ip=$(echo "$vm_response" | jq -r ".vs.\"$vpsid\".ips | to_entries[] | select(.value | test(\"^[0-9.]+$\")) | .value")
    echo "$internal_ip"
}

# Fungsi untuk mendapatkan server config dengan HAProxy info
get_server_config() {
    local vpsid="$1"
    local response=$(curl -sk --max-time 30 "${API_URL}?act=managevdf&svs=${vpsid}&novnc=6710&do=add&api=json&apikey=${API_KEY}&apipass=${API_PASS}")
    echo "$response"
}

# Fungsi untuk mengambil informasi HAProxy dari server config
get_haproxy_info() {
    local server_response="$1"
    local allowed_ports=$(echo "$server_response" | jq -r '.server_haconfigs[]?.haproxy_allowedports // empty')
    local reserved_ports=$(echo "$server_response" | jq -r '.server_haconfigs[]?.haproxy_reservedports // empty') 
    local reserved_http_ports=$(echo "$server_response" | jq -r '.server_haconfigs[]?.haproxy_reservedports_http // empty')
    local src_ips=$(echo "$server_response" | jq -r '.server_haconfigs[]?.haproxy_src_ips // empty')
    
    echo "$allowed_ports|$reserved_ports|$reserved_http_ports|$src_ips"
}

# Fungsi untuk validasi port dengan HAProxy config
validate_port() {
    local port="$1"
    local haproxy_info="$2"
    
    IFS='|' read -r allowed_ports reserved_ports reserved_http_ports src_ips <<< "$haproxy_info"
    
    # Cek jika port number valid
    if ! [[ "$port" =~ ^[0-9]+$ ]] || [ "$port" -lt 1 ] || [ "$port" -gt 65535 ]; then
        echo "Port harus berupa angka antara 1-65535"
        return 1
    fi
    
    # Cek jika port sudah digunakan/reserved
    if [[ -n "$reserved_ports" && "$reserved_ports" == *"$port"* ]]; then
        echo "Port $port sudah digunakan/reserved"
        return 1
    fi
    
    # Cek jika port diizinkan (jika ada pembatasan)
    if [[ -n "$allowed_ports" && "$allowed_ports" != *"$port"* ]]; then
        echo "Port $port tidak diizinkan. Port yang diizinkan: $allowed_ports"
        return 1
    fi
    
    return 0
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
    
    if [[ "$NO_COLOR" != "true" ]]; then
        echo ""
    fi
}

# Fungsi untuk menampilkan konfirmasi
show_confirmation() {
    local vpsid="$1"
    local protocol="$2"
    local src_hostname="$3"
    local src_port="$4"
    local dest_ip="$5"
    local dest_port="$6"
    
    if [[ "$NO_COLOR" == "true" ]]; then
        echo "=== KONFIRMASI FORWARDING ==="
        echo "VPSID: $vpsid"
        echo "Protocol: $protocol"
        echo "Source: $src_hostname:$src_port"
        echo "Destination: $dest_ip:$dest_port"
        echo ""
        echo -n "Tambahkan forwarding ini? (y/N): "
    else
        echo ""
        echo -e "\e[1;33m📋 KONFIRMASI FORWARDING\e[0m"
        printf "\e[2;37m%s\e[0m\n" "--------------------------------"
        echo -e "\e[1;36mVPSID:\e[0m \e[1;32m$vpsid\e[0m"
        echo -e "\e[1;36mProtocol:\e[0m \e[1;35m$protocol\e[0m"
        echo -e "\e[1;36mSource:\e[0m \e[1;94m$src_hostname\e[0m:\e[1;91m$src_port\e[0m"
        echo -e "\e[1;36mDestination:\e[0m \e[1;96m$dest_ip\e[0m:\e[1;93m$dest_port\e[0m"
        echo ""
        echo -e "\e[1;97m❓ Tambahkan forwarding ini? \e[0m\e[1;32m(y)\e[0m\e[1;37m/\e[0m\e[1;31m(N)\e[0m: "
    fi
}

# Fungsi untuk menambahkan forwarding
add_forwarding() {
    local vpsid="$1"
    local protocol="$2"
    local src_hostname="$3"
    local src_port="$4"
    local dest_ip="$5"
    local dest_port="$6"
    
    if [[ "$NO_COLOR" == "true" ]]; then
        echo "🔄 Menambahkan forwarding..."
    else
        echo -e "\e[1;36m🔄 Menambahkan forwarding...\e[0m"
    fi
    
    local response=$(curl -sk --max-time 30 -X POST \
        -d "vdf_action=addvdf&protocol=${protocol}&src_hostname=${src_hostname}&src_port=${src_port}&dest_ip=${dest_ip}&dest_port=${dest_port}" \
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
            echo "✅ Forwarding berhasil ditambahkan!"
            echo "📝 Pesan: $done_msg"
        else
            echo -e "\e[1;32m✅ Forwarding berhasil ditambahkan!\e[0m"
            echo -e "\e[1;37m📝 Pesan:\e[0m \e[2;37m$done_msg\e[0m"
        fi
        return 0
    elif [[ -n "$error_obj" && "$error_obj" != "null" && "$error_obj" != "{}" ]]; then
        # Parse error messages lebih baik
        local src_port_error=$(echo "$response" | jq -r '.error.src_port // empty')
        local src_hostname_error=$(echo "$response" | jq -r '.error.src_hostname // empty')
        local general_error=$(echo "$response" | jq -r '.error // empty')
        
        if [[ "$NO_COLOR" == "true" ]]; then
            echo "❌ Error saat menambahkan forwarding:"
        else
            echo -e "\e[1;31m❌ Error saat menambahkan forwarding:\e[0m"
        fi
        
        if [[ -n "$src_port_error" && "$src_port_error" != "null" ]]; then
            if [[ "$NO_COLOR" == "true" ]]; then
                echo "   🚫 Port Error: $src_port_error"
            else
                echo -e "\e[1;91m   🚫 Port Error:\e[0m \e[37m$src_port_error\e[0m"
            fi
            
            # Ambil info HAProxy untuk memberikan hint
            local server_config=$(get_server_config "$vpsid")
            local haproxy_info=$(get_haproxy_info "$server_config")
            IFS='|' read -r allowed_ports reserved_ports reserved_http_ports src_ips <<< "$haproxy_info"
            
            if [[ -n "$allowed_ports" && "$allowed_ports" != "null" ]]; then
                if [[ "$NO_COLOR" == "true" ]]; then
                    echo "   💡 Port yang diizinkan: $allowed_ports"
                else
                    echo -e "\e[2;36m   💡 Port yang diizinkan:\e[0m \e[93m$allowed_ports\e[0m"
                fi
            fi
            
            if [[ -n "$reserved_ports" && "$reserved_ports" != "null" ]]; then
                if [[ "$NO_COLOR" == "true" ]]; then
                    echo "   🚫 Port yang sudah digunakan: $reserved_ports"
                else
                    echo -e "\e[2;36m   🚫 Port yang sudah digunakan:\e[0m \e[91m$reserved_ports\e[0m"
                fi
            fi
        fi
        
        if [[ -n "$src_hostname_error" && "$src_hostname_error" != "null" ]]; then
            if [[ "$NO_COLOR" == "true" ]]; then
                echo "   🌐 Domain Error: $src_hostname_error"
            else
                echo -e "\e[1;91m   🌐 Domain Error:\e[0m \e[37m$src_hostname_error\e[0m"
            fi
        fi
        
        if [[ -n "$general_error" && "$general_error" != "null" && "$general_error" != "$src_port_error" && "$general_error" != "$src_hostname_error" ]]; then
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
if [[ "$INTERACTIVE" == "true" || (-z "$VPSID" && -z "$PROTOCOL" && -z "$SRC_HOSTNAME" && -z "$SRC_PORT" && -z "$DEST_PORT") ]]; then
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
                echo -n "Masukkan VPSID yang dipilih: "
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
    
    # Auto-detect destination IP
    dest_ip=$(get_vm_internal_ip "$VPSID" "$vm_response")
    if [[ -z "$dest_ip" ]]; then
        echo "❌ Tidak dapat menemukan IP internal untuk VPSID: $VPSID"
        exit 1
    fi

    # Ambil informasi HAProxy untuk validasi dan hints
    if [[ "$NO_COLOR" == "true" ]]; then
        echo "🔍 Mengambil konfigurasi server..."
    else
        echo -e "\e[2;36m🔍 Mengambil konfigurasi server...\e[0m"
    fi
    server_config=$(get_server_config "$VPSID")
    haproxy_info=$(get_haproxy_info "$server_config")
    IFS='|' read -r allowed_ports reserved_ports reserved_http_ports src_ips <<< "$haproxy_info"
    
    # Input Protocol
    if [[ -z "$PROTOCOL" ]]; then
        echo ""
        if [[ "$NO_COLOR" == "true" ]]; then
            echo "Protocol yang tersedia: HTTP, HTTPS, TCP"
            echo -n "Masukkan protocol [TCP]: "
        else
            echo -e "\e[1;36m🌐 Protocol yang tersedia:\e[0m \e[32mHTTP\e[0m, \e[31mHTTPS\e[0m, \e[34mTCP\e[0m"
            echo -e "\e[1;97m💡 Masukkan protocol \e[0m[\e[1;34mTCP\e[0m]: "
        fi
        read -r PROTOCOL
        PROTOCOL=${PROTOCOL:-TCP}
    fi
    
    # Validasi protocol
    PROTOCOL=$(echo "$PROTOCOL" | tr '[:lower:]' '[:upper:]')
    if [[ ! "$PROTOCOL" =~ ^(HTTP|HTTPS|TCP)$ ]]; then
        echo "❌ Protocol tidak valid. Gunakan: HTTP, HTTPS, atau TCP"
        exit 1
    fi
    
    # Input Source Hostname dengan smart prompts berdasarkan protocol
    if [[ -z "$SRC_HOSTNAME" ]]; then
        echo ""
        case "$PROTOCOL" in
            "HTTP"|"HTTPS")
                if [[ "$NO_COLOR" == "true" ]]; then
                    echo -n "Masukkan source domain: "
                else
                    echo -e "\e[1;97m🌐 Masukkan source domain: \e[1;94m"
                fi
                read -r SRC_HOSTNAME
                if [[ "$NO_COLOR" != "true" ]]; then
                    echo -ne "\e[0m"
                fi
                ;;
            "TCP")
                # Auto-detect untuk TCP dari haproxy_src_ips
                if [[ -n "$src_ips" && "$src_ips" != "null" ]]; then
                    SRC_HOSTNAME="$src_ips"
                    if [[ "$NO_COLOR" == "true" ]]; then
                        echo "🔍 Auto-detect source IP: $SRC_HOSTNAME"
                    else
                        echo -e "\e[2;32m🔍 Auto-detect source IP:\e[0m \e[1;96m$SRC_HOSTNAME\e[0m"
                    fi
                else
                    if [[ "$NO_COLOR" == "true" ]]; then
                        echo -n "Masukkan source hostname/IP: "
                    else
                        echo -e "\e[1;97m💡 Masukkan source hostname/IP: \e[1;94m"
                    fi
                    read -r SRC_HOSTNAME
                    if [[ "$NO_COLOR" != "true" ]]; then
                        echo -ne "\e[0m"
                    fi
                fi
                ;;
        esac
    fi
    
    # Auto-set ports untuk HTTP/HTTPS atau input manual untuk TCP
    case "$PROTOCOL" in
        "HTTP")
            SRC_PORT="80"
            DEST_PORT="80"
            if [[ "$NO_COLOR" == "true" ]]; then
                echo ""
                echo "🔧 Auto-set ports: Source 80, Destination 80 (HTTP)"
            else
                echo ""
                echo -e "\e[2;36m🔧 Auto-set ports:\e[0m \e[1;91mSource 80\e[0m, \e[1;93mDestination 80\e[0m \e[2;37m(HTTP)\e[0m"
            fi
            ;;
        "HTTPS")
            SRC_PORT="443"
            DEST_PORT="443"
            if [[ "$NO_COLOR" == "true" ]]; then
                echo ""
                echo "🔧 Auto-set ports: Source 443, Destination 443 (HTTPS)"
            else
                echo ""
                echo -e "\e[2;36m🔧 Auto-set ports:\e[0m \e[1;91mSource 443\e[0m, \e[1;93mDestination 443\e[0m \e[2;37m(HTTPS)\e[0m"
            fi
            ;;
        "TCP")
            # Input Source Port untuk TCP
            if [[ -z "$SRC_PORT" ]]; then
                echo ""
                # Tampilkan informasi port yang tersedia
                if [[ -n "$allowed_ports" && "$allowed_ports" != "null" ]]; then
                    if [[ "$NO_COLOR" == "true" ]]; then
                        echo "💡 Port yang diizinkan: $allowed_ports"
                    else
                        echo -e "\e[2;36m💡 Port yang diizinkan:\e[0m \e[93m$allowed_ports\e[0m"
                    fi
                fi
                
                if [[ -n "$reserved_ports" && "$reserved_ports" != "null" ]]; then
                    if [[ "$NO_COLOR" == "true" ]]; then
                        echo "🚫 Port yang sudah digunakan: $reserved_ports"
                    else
                        echo -e "\e[2;36m🚫 Port yang sudah digunakan:\e[0m \e[91m$reserved_ports\e[0m"
                    fi
                fi
                
                # Loop untuk input port dengan validasi
                while true; do
                    if [[ "$NO_COLOR" == "true" ]]; then
                        echo -n "Masukkan source port: "
                    else
                        echo -e "\e[1;97m💡 Masukkan source port: \e[1;91m"
                    fi
                    read -r SRC_PORT
                    if [[ "$NO_COLOR" != "true" ]]; then
                        echo -ne "\e[0m"
                    fi
                    
                    # Validasi port
                    if validation_result=$(validate_port "$SRC_PORT" "$haproxy_info"); then
                        break
                    else
                        if [[ "$NO_COLOR" == "true" ]]; then
                            echo "❌ $validation_result"
                        else
                            echo -e "\e[1;31m❌ $validation_result\e[0m"
                        fi
                        echo ""
                    fi
                done
            fi
            
            # Input Destination Port untuk TCP
            if [[ -z "$DEST_PORT" ]]; then
                echo ""
                if [[ "$NO_COLOR" == "true" ]]; then
                    echo -n "Masukkan destination port: "
                else
                    echo -e "\e[1;97m💡 Masukkan destination port: \e[1;93m"
                fi
                read -r DEST_PORT
                if [[ "$NO_COLOR" != "true" ]]; then
                    echo -ne "\e[0m"
                fi
            fi
            ;;
    esac
    
else
    # Mode Command Line Parameters
    
    # Default protocol
    PROTOCOL=${PROTOCOL:-TCP}
    PROTOCOL=$(echo "$PROTOCOL" | tr '[:lower:]' '[:upper:]')
    
    # Auto-set ports untuk HTTP/HTTPS di CLI mode
    case "$PROTOCOL" in
        "HTTP")
            SRC_PORT=${SRC_PORT:-80}
            DEST_PORT=${DEST_PORT:-80}
            ;;
        "HTTPS")
            SRC_PORT=${SRC_PORT:-443}
            DEST_PORT=${DEST_PORT:-443}
            ;;
    esac
    
    # Validasi parameter required berdasarkan protocol
    if [[ "$PROTOCOL" == "HTTP" || "$PROTOCOL" == "HTTPS" ]]; then
        # Untuk HTTP/HTTPS, hanya perlu VPSID dan domain
        if [[ -z "$VPSID" || -z "$SRC_HOSTNAME" ]]; then
            echo "❌ Parameter tidak lengkap. Required untuk $PROTOCOL: --vpsid, --domain"
            echo "Gunakan --interactive untuk mode step-by-step atau --help untuk bantuan"
            exit 1
        fi
    else
        # Untuk TCP, perlu semua parameter
        if [[ -z "$VPSID" || -z "$SRC_HOSTNAME" || -z "$SRC_PORT" || -z "$DEST_PORT" ]]; then
            echo "❌ Parameter tidak lengkap. Required untuk TCP: --vpsid, --domain, --src-port, --dest-port"
            echo "Gunakan --interactive untuk mode step-by-step atau --help untuk bantuan"
            exit 1
        fi
    fi
    
    # Validasi VPSID
    if ! echo "$vm_response" | jq -e ".vs.\"$VPSID\"" > /dev/null 2>&1; then
        echo "❌ VPSID tidak valid: $VPSID"
        exit 1
    fi
    
    # Auto-detect destination IP
    dest_ip=$(get_vm_internal_ip "$VPSID" "$vm_response")
    if [[ -z "$dest_ip" ]]; then
        echo "❌ Tidak dapat menemukan IP internal untuk VPSID: $VPSID"
        exit 1
    fi
fi

# Validasi input
if [[ -z "$VPSID" || -z "$PROTOCOL" || -z "$SRC_HOSTNAME" || -z "$SRC_PORT" || -z "$DEST_PORT" ]]; then
    echo "❌ Data tidak lengkap!"
    exit 1
fi

# Validasi protocol
if [[ ! "$PROTOCOL" =~ ^(HTTP|HTTPS|TCP)$ ]]; then
    echo "❌ Protocol tidak valid: $PROTOCOL"
    exit 1
fi

# Validasi port (harus numerik)
if [[ ! "$SRC_PORT" =~ ^[0-9]+$ ]] || [[ ! "$DEST_PORT" =~ ^[0-9]+$ ]]; then
    echo "❌ Port harus berupa angka"
    exit 1
fi

# Tampilkan konfirmasi
show_confirmation "$VPSID" "$PROTOCOL" "$SRC_HOSTNAME" "$SRC_PORT" "$dest_ip" "$DEST_PORT"

read -r confirm
if [[ "$confirm" =~ ^[Yy]$ ]]; then
    add_forwarding "$VPSID" "$PROTOCOL" "$SRC_HOSTNAME" "$SRC_PORT" "$dest_ip" "$DEST_PORT"
else
    if [[ "$NO_COLOR" == "true" ]]; then
        echo "❌ Dibatalkan."
    else
        echo -e "\e[1;31m❌ Dibatalkan.\e[0m"
    fi
fi
