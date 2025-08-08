<h2 align="center"> ━━━━━━  ❖  ━━━━━━ </h2>

<!-- BADGES -->
<div align="center">

[![stars](https://img.shields.io/github/stars/iam-rizz/Domain-Forwarding-Virtualizor?color=C9CBFF&labelColor=1A1B26&style=for-the-badge)](https://github.com/iam-rizz/Domain-Forwarding-Virtualizor/stargazers)
[![size](https://img.shields.io/github/repo-size/iam-rizz/Domain-Forwarding-Virtualizor?color=9ece6a&labelColor=1A1B26&style=for-the-badge)](https://github.com/iam-rizz/Domain-Forwarding-Virtualizor)
[![Visitors](https://api.visitorbadge.io/api/visitors?path=https%3A%2F%2Fgithub.com%2Fiam-rizz%2FDomain-Forwarding-Virtualizor&label=View&labelColor=%231a1b26&countColor=%23e0af68)](https://visitorbadge.io/status?path=https%3A%2F%2Fgithub.com%2Fiam-rizz%2FDomain-Forwarding-Virtualizor)
[![license](https://img.shields.io/github/license/iam-rizz/Domain-Forwarding-Virtualizor?color=FCA2AA&labelColor=1A1B26&style=for-the-badge)](https://github.com/iam-rizz/Domain-Forwarding-Virtualizor/blob/main/LICENSE.md)

</div>
<h2 align="center"> ━━━━━━  ❖  ━━━━━━ </h2>

# Manajemen Domain/Port Forwarding untuk Virtualizor

🚀 **Rangkaian tool lengkap untuk mengelola domain dan port forwarding di lingkungan VPS Virtualizor**

[![Shell Script](https://img.shields.io/badge/Shell-Script-4EAA25?style=flat&logo=gnu-bash&logoColor=white)](https://www.gnu.org/software/bash/)
[![Virtualizor](https://img.shields.io/badge/Virtualizor-API-blue)](https://www.virtualizor.com/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

## 🌐 Language / Bahasa
- **[English](README_EN.md)** - Read in English
- **Bahasa Indonesia** - Anda sedang membaca versi bahasa Indonesia

## 📋 Gambaran Umum

Repository ini menyediakan seperangkat lengkap script bash untuk mengelola aturan domain dan port forwarding di lingkungan VPS Virtualizor. Tool ini menawarkan antarmuka interaktif dan command-line dengan fitur otomasi yang cerdas.

### ✨ Fitur Utama

- 🖥️ **Manajemen VM** - Daftar dan kelola virtual machine
- 📋 **Port Forwarding** - Lihat aturan forwarding yang ada
- ➕ **Tambah Forwarding** - Buat aturan forwarding baru dengan default cerdas
- ✏️ **Edit Forwarding** - Ubah konfigurasi forwarding yang ada
- �️ **Delete Forwarding** - Hapus aturan forwarding dengan konfirmasi aman
- �🔧 **Auto-Port Setting** - Konfigurasi port otomatis untuk HTTP/HTTPS
- 🎯 **Smart Protocol Handling** - Prompt dan validasi yang sadar konteks
- 🌈 **Color-coded Output** - Keterbacaan yang ditingkatkan dengan dukungan warna
- 🔍 **Integrasi HAProxy** - Validasi port real-time dan petunjuk

## 🚧 Status Proyek & Roadmap

### ✅ Fitur yang Sudah Selesai

#### Fungsionalitas Inti
- [ ] **Manajemen VM** - Daftar dan kelola virtual machine dengan filter status
- [ ] **Daftar Port Forwarding** - Lihat aturan forwarding yang ada dengan informasi detail  
- [ ] **Tambah Forwarding** - Buat aturan forwarding baru dengan validasi komprehensif
- [ ] **Edit Forwarding** - Ubah konfigurasi forwarding yang ada dengan perbandingan sebelum/sesudah
- [ ] **Delete Forwarding** - Hapus aturan forwarding yang ada dengan aman


#### Fitur Lanjutan  
- [ ] **Auto-Port Setting** - Port otomatis 80/443 untuk protokol HTTP/HTTPS
- [ ] **Smart Protocol Handling** - Prompt yang sadar konteks berdasarkan jenis protokol
- [ ] **Integrasi HAProxy** - Validasi port real-time dan petunjuk konfigurasi
- [ ] **Auto-Detection** - Deteksi IP otomatis untuk protokol TCP menggunakan config HAProxy
- [ ] **Enhanced Error Handling** - Pesan error yang user-friendly dengan petunjuk yang dapat ditindaklanjuti
- [ ] **Color-coded Output** - Output terminal yang indah dengan syntax highlighting
- [ ] **Mode Interaktif & CLI** - Antarmuka terpandu dan scriptable
- [ ] **Manajemen Konfigurasi** - Manajemen kredensial API terpusat

### 🔄 Sedang Dikerjakan

_Tidak ada fitur yang sedang dikerjakan saat ini_

### 📋 Fitur yang Direncanakan

#### Jangka Pendek (Rilis Berikutnya)
- [ ] **Batch Operations** - Proses beberapa aturan sekaligus via CLI
- [ ] **Configuration Validation** - Pre-flight checks sebelum API calls

#### Jangka Menengah 
- [ ] **Backup/Restore** - Simpan dan pulihkan konfigurasi forwarding
- [ ] **Templates** - Template forwarding yang sudah didefinisikan untuk layanan umum
- [ ] **Bulk Import/Export** - Kemampuan batch processing CSV/JSON

#### Visi Jangka Panjang
- [ ] **Monitoring** - Health checks untuk aturan forwarding
- [ ] **Web Interface** - Panel manajemen berbasis browser
- [ ] **Auto-Discovery** - Deteksi layanan dan saran aturan forwarding
- [ ] **Load Balancing** - Dukungan beberapa destinasi untuk high availability

### 🎯 Fokus Pengembangan

**Sprint Saat Ini**: Batch operations dan configuration validation  
**Sprint Berikutnya**: Template system dan backup/restore functionality  
**Masa Depan**: Monitoring lanjutan dan web interface

## 📦 Instalasi

1. **Clone repository:**
   ```bash
   git clone https://github.com/iam-rizz/Domain-Forwarding-Virtualizor.git
   cd Domain-Forwarding-Virtualizor
   ```

2. **Buat script dapat dieksekusi:**
   ```bash
   chmod +x *.sh
   ```

3. **Buat file konfigurasi:**
   ```bash
   sudo mkdir -p /etc/vm
   sudo nano /etc/vm/data.conf
   ```

4. **Tambahkan kredensial API Virtualizor Anda:**
   ```bash
   API_URL="https://domain.com:4083/index.php"
   API_KEY="your_api_key_here"
   API_PASS="your_api_password_here"
   ```

## 🛠️ Script yang Tersedia

### Script Inti

| Script | Deskripsi | Penggunaan |
|--------|-------------|--------|
| `listvm.sh` | Daftar virtual machine | Lihat status dan detail VM |
| `listforward.sh` | Tampilkan aturan port forwarding | Tampilkan forwarding yang ada |
| `addforward.sh` | Tambah aturan forwarding baru | Buat forwarding HTTP/HTTPS/TCP |
| `editforward.sh` | Edit forwarding yang ada | Ubah konfigurasi forwarding |
| `deleteforward.sh` | Hapus aturan forwarding | Hapus forwarding dengan konfirmasi |
| `vm.sh` | Script helper utama | Akses terpadu ke semua tools |

### Script Helper

Script `vm.sh` menyediakan shortcut yang nyaman untuk semua script lainnya:

```bash
./vm.sh list          # Daftar VM
./vm.sh forward       # Tampilkan aturan forwarding
./vm.sh add           # Tambah forwarding (interaktif)
./vm.sh edit          # Edit forwarding (interaktif)
./vm.sh delete        # Hapus forwarding (interaktif)
```

## 🚀 Mulai Cepat

### 1. Daftar Virtual Machine
```bash
# Tampilkan semua VM
./listvm.sh

# Tampilkan hanya VM yang berjalan
./listvm.sh --status up

# Output tanpa warna
./listvm.sh --no-color
```

### 2. Lihat Port Forwarding
```bash
# Pilihan VM interaktif
./listforward.sh

# VPSID langsung
./listforward.sh --vpsid 103

# Auto-select jika hanya ada satu VM
./listforward.sh --auto
```

### 3. Tambah Port Forwarding

#### HTTP/HTTPS (Auto-Port)
```bash
# HTTP - otomatis menggunakan port 80
./addforward.sh --vpsid 103 --protocol HTTP --domain app.example.com

# HTTPS - otomatis menggunakan port 443
./addforward.sh --vpsid 103 --protocol HTTPS --domain secure.example.com

# Mode interaktif
./addforward.sh --interactive
```

#### TCP (Port Manual)
```bash
# SSH forwarding
./addforward.sh --vpsid 103 --protocol TCP --domain 45.158.126.130 --src-port 2222 --dest-port 22

# Layanan custom
./addforward.sh -v 103 -p TCP -d 192.168.1.100 -s 8080 -t 80
```

### 4. Edit Port Forwarding

```bash
# Edit protokol ke HTTPS (auto-port 443)
./editforward.sh --vpsid 103 --vdfid 596 --protocol HTTPS --domain secure.app.com

# Edit port TCP
./editforward.sh --vpsid 103 --vdfid 596 --src-port 30222 --dest-port 22

# Mode interaktif
./editforward.sh --interactive
```

### 5. Hapus Port Forwarding

```bash
# Hapus forwarding tertentu
./deleteforward.sh --vpsid 103 --vdfid 596

# Mode interaktif dengan konfirmasi
./deleteforward.sh --interactive

# Hapus dengan konfirmasi otomatis
./deleteforward.sh --vpsid 103 --vdfid 596 --force
```

## 📖 Penggunaan Detail

### Perilaku Spesifik Protokol

#### Protokol HTTP
- **Auto-Port**: Source 80, Destination 80
- **Input yang Diperlukan**: Domain saja
- **Contoh**: `app.example.com:80 → VM:80`

#### Protokol HTTPS  
- **Auto-Port**: Source 443, Destination 443
- **Input yang Diperlukan**: Domain saja
- **Contoh**: `secure.example.com:443 → VM:443`

#### Protokol TCP
- **Port Manual**: User menentukan kedua port
- **Input yang Diperlukan**: IP/Domain, source port, destination port
- **Contoh**: `192.168.1.100:2222 → VM:22`

### Fitur Mode Interaktif

1. **Smart VM Selection** - Pemilihan otomatis untuk lingkungan VM tunggal
2. **Protocol-Aware Prompts** - Request input yang sensitif konteks
3. **Port Validation** - Validasi real-time dengan integrasi HAProxy
4. **Auto-Detection** - Deteksi IP otomatis untuk protokol TCP
5. **Confirmation Preview** - Perbandingan sebelum/sesudah untuk edit

### Opsi Command Line

#### Opsi Global
- `-h, --help` - Tampilkan informasi bantuan
- `-n, --no-color` - Nonaktifkan output warna
- `-i, --interactive` - Paksa mode interaktif

#### Opsi Spesifik Add/Edit/Delete
- `-v, --vpsid VPSID` - Target VM ID
- `-p, --protocol PROTOCOL` - HTTP/HTTPS/TCP
- `-d, --domain DOMAIN` - Source hostname/domain
- `-s, --src-port PORT` - Source port (TCP saja)
- `-t, --dest-port PORT` - Destination port (TCP saja)
- `-f, --vdfid VDFID` - Forwarding ID (edit/delete)
- `--force` - Hapus tanpa konfirmasi (delete saja)

## 🎯 Kasus Penggunaan

### Aplikasi Web
```bash
# Situs WordPress
./vm.sh add --vpsid 103 --protocol HTTP --domain wordpress.example.com

# Situs dengan SSL
./vm.sh add --vpsid 103 --protocol HTTPS --domain secure.example.com
```

### Layanan Pengembangan
```bash
# Server pengembangan Node.js
./addforward.sh -v 103 -p TCP -d dev.example.com -s 3000 -t 3000

# Akses database
./addforward.sh -v 103 -p TCP -d db.example.com -s 5432 -t 5432
```

### Administrasi Sistem
```bash
# SSH di port custom
./addforward.sh -v 103 -p TCP -d 45.158.126.130 -s 2222 -t 22

# Panel admin web
./addforward.sh -v 103 -p TCP -d admin.example.com -s 8080 -t 80
```

## 🔧 Fitur Lanjutan

### Integrasi HAProxy
- **Port Validation** - Cek terhadap port yang diizinkan/direservasi
- **Smart Hints** - Memberikan saran port yang membantu
- **Real-time Config** - Mengambil konfigurasi HAProxy saat ini

### Error Handling
- **User-friendly Messages** - Deskripsi error yang jelas
- **Actionable Hints** - Panduan spesifik untuk resolusi
- **Validation Feedback** - Validasi input real-time

### Dukungan Otomasi
- **Scriptable** - Semua fungsi bekerja dalam mode non-interaktif
- **JSON Output** - Opsi output yang dapat dibaca mesin
- **Exit Codes** - Penanganan kode error yang tepat

## 🔄 Contoh Workflow

### Workflow Setup Lengkap
```bash
# 1. Cek VM yang tersedia
./vm.sh list

# 2. Lihat forwarding yang ada
./vm.sh forward --vpsid 103

# 3. Tambah forwarding HTTP baru
./vm.sh add --vpsid 103 --protocol HTTP --domain new-site.com

# 4. Edit forwarding yang ada  
./vm.sh edit --vpsid 103 --vdfid 596 --protocol HTTPS

# 5. Hapus forwarding yang tidak diperlukan
./vm.sh delete --vpsid 103 --vdfid 596
```

### Operasi Bulk
```bash
# Tambah beberapa situs HTTP
for domain in site1.com site2.com site3.com; do
    ./addforward.sh --vpsid 103 --protocol HTTP --domain $domain
done
```

## 🐛 Troubleshooting

### Masalah Umum

**1. Koneksi API Gagal**
```bash
# Cek konfigurasi
cat /etc/vm/data.conf

# Test konektivitas API
curl -sk "$API_URL?act=listvs&api=json&apikey=$API_KEY&apipass=$API_PASS"
```

**2. Port Sudah Digunakan**
```bash
# Cek forwarding yang ada
./listforward.sh --vpsid 103

# Lihat konfigurasi HAProxy
./addforward.sh --interactive  # Menampilkan petunjuk port
```

**3. VPSID Tidak Valid**
```bash
# Daftar VM yang tersedia
./listvm.sh
```

### Mode Debug
```bash
# Aktifkan output verbose
set -x
./addforward.sh --interactive
set +x
```

## 🤝 Kontribusi

Kontribusi sangat diterima! Silakan kirim Pull Request.

### Setup Pengembangan
1. Fork repository
2. Buat feature branch
3. Lakukan perubahan Anda
4. Test secara menyeluruh
5. Kirim pull request

### Panduan
- Ikuti gaya kode yang ada
- Tambahkan komentar untuk logika yang kompleks
- Test pada beberapa konfigurasi VM
- Update dokumentasi sesuai kebutuhan

## 📄 Lisensi

Proyek ini dilisensikan di bawah MIT License - lihat file [LICENSE](LICENSE) untuk detail.

## 🙏 Penghargaan

- [Virtualizor](https://www.virtualizor.com/) untuk platform manajemen VPS yang luar biasa
- [jq](https://stedolan.github.io/jq/) untuk kemampuan pemrosesan JSON
- Komunitas open-source untuk inspirasi dan tools

## 📞 Dukungan

- **Issues**: [GitHub Issues](https://github.com/iam-rizz/Domain-Forwarding-Virtualizor/issues)
- **Dokumentasi**: README ini dan bantuan inline (`--help`)
- **Komunitas**: Jangan ragu untuk berkontribusi perbaikan dan saran

---

**Dibuat dengan ❤️ untuk komunitas Virtualizor**
