#!/bin/bash

CONFIG_FILE="/etc/vm/data.conf"

show_help() {
    cat << EOF
VM Management Tools - Script Helper

SCRIPT YANG TERSEDIA:
    ./listvm.sh         # Menampilkan daftar Virtual Machine
    ./listforward.sh    # Menampilkan daftar Domain/Port Forwarding
    ./addforward.sh     # Menambahkan Domain/Port Forwarding
    ./editforward.sh    # Mengedit Domain/Port Forwarding
    ./deleteforward.sh  # Menghapus Domain/Port Forwarding

OPSI GLOBAL:
    -h, --help          Tampilkan bantuan ini
    -n, --no-color      Nonaktifkan warna pada output  
    -j, --json          Output dalam format JSON

CONTOH PENGGUNAAN:

1. MELIHAT DAFTAR VM:
   ./listvm.sh                    # Tampilkan semua VM
   ./listvm.sh --status up        # Tampilkan hanya VM yang aktif
   ./listvm.sh --no-color         # Tampilkan tanpa warna

2. MELIHAT PORT FORWARDING:
   ./listforward.sh               # Pilih VM dari daftar
   ./listforward.sh --vpsid 103   # Langsung ke VPSID 103
   ./listforward.sh --auto        # Auto-select jika 1 VM

3. MENAMBAH PORT FORWARDING:
   ./addforward.sh --interactive  # Mode step-by-step
   ./addforward.sh --vpsid 103 --protocol HTTP --domain app.com           # HTTP (auto port 80)
   ./addforward.sh --vpsid 103 --protocol HTTPS --domain secure.app.com   # HTTPS (auto port 443)
   ./addforward.sh -v 103 -p TCP -d 45.158.126.130 -s 2222 -t 22          # TCP (manual ports)

4. MENGEDIT PORT FORWARDING:
   ./editforward.sh --interactive  # Mode step-by-step
   ./editforward.sh --vpsid 103 --vdfid 596 --protocol HTTPS              # Edit ke HTTPS (auto port 443)
   ./editforward.sh -v 103 -f 596 -p HTTP -d secure.app.com               # Edit ke HTTP (auto port 80)
   ./editforward.sh -v 103 -f 596 -s 30222 -t 22                          # Edit TCP ports

5. MENGHAPUS PORT FORWARDING:
   ./deleteforward.sh --interactive  # Mode step-by-step dengan konfirmasi
   ./deleteforward.sh --vpsid 103 --vdfid 596                             # Hapus forwarding tertentu (dengan konfirmasi)
   ./deleteforward.sh --vpsid 103 --vdfid 596 --force                     # Hapus tanpa konfirmasi
   ./deleteforward.sh -v 103 -f 596,597,598                               # Hapus beberapa forwarding sekaligus

6. WORKFLOW CEPAT:
   ./vm.sh list           # Cek daftar VPS  
   ./vm.sh add           # Tambah forwarding (shortcut)
   ./vm.sh edit          # Edit forwarding (shortcut)
   ./vm.sh delete        # Hapus forwarding (shortcut)

   # Lihat VM yang aktif, lalu cek forwarding, edit atau hapus
   ./listvm.sh --status up
   ./listforward.sh --vpsid [VPSID_DARI_OUTPUT_ATAS]
   ./addforward.sh --vpsid [VPSID] --interactive
   ./deleteforward.sh --vpsid [VPSID] --interactive

KONFIGURASI:
   File config: $CONFIG_FILE
   
   Contoh isi file config:
   API_URL="https://domain.com:4083/index.php"
   API_KEY="your_api_key_here"
   API_PASS="your_api_password_here"

EOF
}

case "${1:-}" in
    -h|--help|help|"")
        show_help
        ;;
    vm|list|listvm)
        shift
        exec ./listvm.sh "$@"
        ;;
    forward|forwarding|listforward)
        shift  
        exec ./listforward.sh "$@"
        ;;
    add|addforward|add-forward)
        shift
        exec ./addforward.sh "$@"
        ;;
    edit|editforward|edit-forward)
        shift
        exec ./editforward.sh "$@"
        ;;
    delete|deleteforward|delete-forward|del|remove)
        shift
        exec ./deleteforward.sh "$@"
        ;;
    *)
        echo "❌ Perintah tidak dikenal: $1"
        echo ""
        show_help
        exit 1
        ;;
esac
