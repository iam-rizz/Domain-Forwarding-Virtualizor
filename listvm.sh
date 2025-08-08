#!/bin/bash

CONFIG_FILE="/etc/vm/data.conf"

SHOW_HELP=false
NO_COLOR=false
JSON_OUTPUT=false
FILTER_STATUS=""

show_help() {
    cat << EOF
Penggunaan: $0 [OPSI]

Script untuk menampilkan daftar Virtual Machine dari API VPS

OPSI:
    -h, --help          Tampilkan bantuan ini
    -n, --no-color      Nonaktifkan warna pada output
    -j, --json          Output dalam format JSON
    -s, --status STATUS Filter berdasarkan status (up/down)
    
CONTOH:
    $0                  # Tampilkan semua VM
    $0 --no-color       # Tampilkan tanpa warna
    $0 --status up      # Tampilkan hanya VM yang aktif
    $0 --json           # Output format JSON

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
        -j|--json)
            JSON_OUTPUT=true
            shift
            ;;
        -s|--status)
            FILTER_STATUS="$2"
            shift 2
            ;;
        *)
            echo "❌ Opsi tidak dikenal: $1"
            echo "Gunakan -h atau --help untuk bantuan"
            exit 1
            ;;
    esac
done

if [[ -f "$CONFIG_FILE" ]]; then
    source "$CONFIG_FILE"
else
    echo "❌ File konfigurasi tidak ditemukan: $CONFIG_FILE"
    exit 1
fi

[[ -z "$API_URL" ]] && { echo "❌ API_URL tidak boleh kosong di $CONFIG_FILE"; exit 1; }
[[ -z "$API_KEY" ]] && { echo "❌ API_KEY tidak boleh kosong di $CONFIG_FILE"; exit 1; }
[[ -z "$API_PASS" ]] && { echo "❌ API_PASS tidak boleh kosong di $CONFIG_FILE"; exit 1; }

shorten_ipv6() {
    local ip="$1"
    ip="${ip%%/*}"
    
    if command -v python3 &> /dev/null; then
        python3 -c "
import ipaddress
try:
    print(str(ipaddress.IPv6Address('$ip').compressed))
except:
    print('$ip')
" 2>/dev/null || echo "$ip"
    else
        echo "$ip" | sed -E '
            s/0000/0/g
            s/:0+([0-9a-fA-F])/:|\1/g
            s/\|//g
            s/(^|:)0+:/\1:/g
            s/::+/::/g
        '
    fi
}

response=$(curl -sk --max-time 30 --retry 3 "${API_URL}?act=listvs&api=json&apikey=${API_KEY}&apipass=${API_PASS}")
curl_exit_code=$?

if [[ $curl_exit_code -ne 0 ]]; then
    echo "❌ Gagal menghubungi API. Kode error: $curl_exit_code"
    case $curl_exit_code in
        6) echo "   Tidak dapat menguraikan hostname" ;;
        7) echo "   Tidak dapat terhubung ke server" ;;
        28) echo "   Timeout - koneksi terlalu lambat" ;;
        *) echo "   Error curl tidak dikenal" ;;
    esac
    exit 1
fi

if [[ -z "$response" ]]; then
    echo "❌ Tidak ada respons dari API."
    exit 1
fi

if ! echo "$response" | jq . > /dev/null 2>&1; then
    echo "❌ Respons API bukan JSON valid."
    echo "Respons: $response"
    exit 1
fi

vs_data=$(echo "$response" | jq -r '.vs // empty')
if [[ -z "$vs_data" || "$vs_data" == "null" ]]; then
    echo "❌ Tidak ada data VM ditemukan di respons API."
    echo "Respons API: $response"
    exit 1
fi

if [[ "$JSON_OUTPUT" == "true" ]]; then
    echo "$response" | jq '.vs'
    exit 0
fi

printf "%-6s | %-15s | %-13s | %-30s | %-7s\n" "VPSID" "Hostname" "IPv4" "IPv6" "Status"
printf "%s\n" "------------------------------------------------------------------------------------------"

echo "$response" | jq -r '
  .vs | 
  to_entries[] | 
  .value as $vm |
  ($vm.ips | to_entries | map(select(.value | test("^[0-9.]+$"))) | .[0].value // "-") as $ipv4 |
  ($vm.ips | to_entries | map(select(.value | test(":"))) | .[0].value // "-") as $ipv6 |
  [
    ($vm.vpsid // "N/A"),
    ($vm.hostname // "N/A"), 
    $ipv4,
    $ipv6,
    ($vm.status // 0)
  ] | 
  @tsv
' | while IFS=$'\t' read -r vpsid hostname ipv4 ipv6_raw status_raw; do
    if [[ "$ipv6_raw" == "-" ]]; then
        ipv6="-"
    else
        ipv6=$(shorten_ipv6 "$ipv6_raw")
    fi

    if [[ "$status_raw" == "1" ]]; then
        if [[ "$NO_COLOR" == "true" ]]; then
            status="Up"
        else
            status="\e[32mUp\e[0m"
        fi
        status_filter="up"
    else
        if [[ "$NO_COLOR" == "true" ]]; then
            status="Down"
        else
            status="\e[31mDown\e[0m"
        fi
        status_filter="down"
    fi

    if [[ -n "$FILTER_STATUS" && "$FILTER_STATUS" != "$status_filter" ]]; then
        continue
    fi

    printf "%-6s | %-15s | %-13s | %-30s | %-7b\n" "$vpsid" "$hostname" "$ipv4" "$ipv6" "$status"
done