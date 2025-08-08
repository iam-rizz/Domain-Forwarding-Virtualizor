<h2 align="center"> ━━━━━━  ❖  ━━━━━━ </h2>

<!-- BADGES -->
<div align="center">

[![stars](https://img.shields.io/github/stars/iam-rizz/Domain-Forwarding-Virtualizor?color=C9CBFF&labelColor=1A1B26&style=for-the-badge)](https://github.com/iam-rizz/Domain-Forwarding-Virtualizor/stargazers)
[![size](https://img.shields.io/github/repo-size/iam-rizz/Domain-Forwarding-Virtualizor?color=9ece6a&labelColor=1A1B26&style=for-the-badge)](https://github.com/iam-rizz/Domain-Forwarding-Virtualizor)
[![Visitors](https://api.visitorbadge.io/api/visitors?path=https%3A%2F%2Fgithub.com%2Fiam-rizz%2FDomain-Forwarding-Virtualizor&label=View&labelColor=%231a1b26&countColor=%23e0af68)](https://visitorbadge.io/status?path=https%3A%2F%2Fgithub.com%2Fiam-rizz%2FDomain-Forwarding-Virtualizor)
[![license](https://img.shields.io/github/license/iam-rizz/Domain-Forwarding-Virtualizor?color=FCA2AA&labelColor=1A1B26&style=for-the-badge)](https://github.com/iam-rizz/Domain-Forwarding-Virtualizor/blob/main/LICENSE)

</div>
<h2 align="center"> ━━━━━━  ❖  ━━━━━━ </h2>

# Domain/Port Forwarding Management for Virtualizor

🚀 **Comprehensive tool suite for managing domain and port forwarding in Virtualizor VPS environments**

[![Shell Script](https://img.shields.io/badge/Shell-Script-4EAA25?style=flat&logo=gnu-bash&logoColor=white)](https://www.gnu.org/software/bash/)
[![Virtualizor](https://img.shields.io/badge/Virtualizor-API-blue)](https://www.virtualizor.com/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

## 🌐 Language / Bahasa
- **English** - You are reading the English version
- **[Bahasa Indonesia](README.md)** - Baca dalam bahasa Indonesia

## � Table of Contents

- [📋 Overview](#-overview)
- [💡 VPS & Hosting Recommendation](#-vps--hosting-recommendation)
- [✨ Key Features](#-key-features)
- [🚧 Project Status & Roadmap](#-project-status--roadmap)
- [📦 Installation](#-installation)
- [🛠️ Available Scripts](#️-available-scripts)
- [🚀 Quick Start](#-quick-start)
- [📖 Detailed Usage](#-detailed-usage)
- [🎯 Use Cases](#-use-cases)
- [🔧 Advanced Features](#-advanced-features)
- [🔄 Workflow Examples](#-workflow-examples)
- [🐛 Troubleshooting](#-troubleshooting)
- [🤝 Contributing](#-contributing)
- [📄 License](#-license)
- [🙏 Acknowledgments](#-acknowledgments)
- [📞 Support](#-support)

## �📋 Overview

This repository provides a complete set of bash scripts for managing domain and port forwarding rules in Virtualizor VPS environments. The tools offer both interactive and command-line interfaces with smart automation features.

---

### 💡 VPS & Hosting Recommendation

<div align="center">

Need VPS for testing this script? **[HostData.id](https://hostdata.id)** provides various trusted hosting options at affordable prices.

[![HostData.id](https://img.shields.io/badge/HostData.id-Trusted%20VPS-FF6B35?style=flat&logo=server&logoColor=white)](https://hostdata.id) 
[![NAT VPS](https://img.shields.io/badge/NAT%20VPS-Starting%2015K/month-00C851?style=flat)](https://hostdata.id/nat-vps)
[![VPS Indonesia](https://img.shields.io/badge/VPS%20Indonesia-Starting%20200K/month-007ACC?style=flat&logo=server)](https://hostdata.id/vps-indonesia)
[![Dedicated Server](https://img.shields.io/badge/Dedicated%20Server-Enterprise%20Ready-8B5CF6?style=flat&logo=server)](https://hostdata.id/dedicated-server)

</div>

#### 🚀 Available Hosting Packages

| Hosting Type | Starting Price | Specifications | Perfect For |
|--------------|----------------|----------------|-------------|
| **NAT VPS** | **15K/month** | SSD NVMe, Shared IP | Testing, Development, Personal Projects |
| **VPS Indonesia** | **200K/month** | Dedicated IP, Full Root, SSD | Production Websites, App Deployment |
| **Dedicated Server** | **Custom** | Full Hardware Control | Enterprise, Server Indonesia |


### ✨ Key Features

- 🖥️ **VM Management** - List and manage virtual machines
- 📋 **Port Forwarding** - View existing forwarding rules
- ➕ **Add Forwarding** - Create new forwarding rules with smart defaults
- ✏️ **Edit Forwarding** - Modify existing forwarding configurations
- �️ **Delete Forwarding** - Remove forwarding rules with safe confirmation
- �🔧 **Auto-Port Setting** - Automatic port configuration for HTTP/HTTPS
- 🎯 **Smart Protocol Handling** - Context-aware prompts and validation
- 🌈 **Color-coded Output** - Enhanced readability with color support
- 🔍 **HAProxy Integration** - Real-time port validation and hints

## 🚧 Project Status & Roadmap

### ✅ Completed Features

#### Core Functionality
- [ ] **VM Management** - List and manage virtual machines with status filtering
- [ ] **Port Forwarding Listing** - View existing forwarding rules with detailed information  
- [ ] **Add Forwarding** - Create new forwarding rules with comprehensive validation
- [ ] **Edit Forwarding** - Modify existing forwarding configurations with before/after comparison
- [ ] **Delete Forwarding** - Remove existing forwarding rules safely


#### Advanced Features  
- [ ] **Auto-Port Setting** - Automatic port 80/443 for HTTP/HTTPS protocols
- [ ] **Smart Protocol Handling** - Context-aware prompts based on protocol type
- [ ] **HAProxy Integration** - Real-time port validation and configuration hints
- [ ] **Auto-Detection** - Automatic IP detection for TCP protocols using HAProxy config
- [ ] **Enhanced Error Handling** - User-friendly error messages with actionable hints
- [ ] **Color-coded Output** - Beautiful terminal output with syntax highlighting
- [ ] **Interactive & CLI Modes** - Both guided and scriptable interfaces
- [ ] **Configuration Management** - Centralized API credential management


### �📋 Planned Features

#### Short Term (Next Release)
- [ ] **Batch Operations** - Process multiple rules at once via CLI
- [ ] **Configuration Validation** - Pre-flight checks before API calls

#### Medium Term 
- [ ] **Backup/Restore** - Save and restore forwarding configurations
- [ ] **Templates** - Predefined forwarding templates for common services
- [ ] **Bulk Import/Export** - CSV/JSON batch processing capabilities

#### Long Term Vision
- [ ] **Monitoring** - Health checks for forwarding rules
- [ ] **Web Interface** - Browser-based management panel
- [ ] **Auto-Discovery** - Detect services and suggest forwarding rules
- [ ] **Load Balancing** - Multiple destination support for high availability

### 🎯 Development Focus

**Current Sprint**: Batch operations and configuration validation  
**Next Sprint**: Template system and backup/restore functionality  
**Future**: Advanced monitoring and web interface

## 📦 Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/iam-rizz/Domain-Forwarding-Virtualizor.git
   cd Domain-Forwarding-Virtualizor
   ```

2. **Make scripts executable:**
   ```bash
   chmod +x *.sh
   ```

3. **Create configuration file:**
   ```bash
   sudo mkdir -p /etc/vm
   sudo nano /etc/vm/data.conf
   ```

4. **Add your Virtualizor API credentials:**
   ```bash
   API_URL="https://domain.com:4083/index.php"
   API_KEY="your_api_key_here"
   API_PASS="your_api_password_here"
   ```

## 🛠️ Available Scripts

### Core Scripts

| Script | Description | Usage |
|--------|-------------|--------|
| `listvm.sh` | List virtual machines | View VM status and details |
| `listforward.sh` | Show port forwarding rules | Display existing forwarding |
| `addforward.sh` | Add new forwarding rules | Create HTTP/HTTPS/TCP forwarding |
| `editforward.sh` | Edit existing forwarding | Modify forwarding configuration |
| `deleteforward.sh` | Delete forwarding rules | Remove forwarding with confirmation |
| `vm.sh` | Main helper script | Unified access to all tools |

### Helper Script

The `vm.sh` script provides convenient shortcuts to all other scripts:

```bash
./vm.sh list          # List VMs
./vm.sh forward       # Show forwarding rules
./vm.sh add           # Add forwarding (interactive)
./vm.sh edit          # Edit forwarding (interactive)
./vm.sh delete        # Delete forwarding (interactive)
```

## 🚀 Quick Start

### 1. List Virtual Machines
```bash
# Show all VMs
./listvm.sh

# Show only running VMs
./listvm.sh --status up

# No color output
./listvm.sh --no-color
```

### 2. View Port Forwarding
```bash
# Interactive VM selection
./listforward.sh

# Direct VPSID
./listforward.sh --vpsid 103

# Auto-select if only one VM
./listforward.sh --auto
```

### 3. Add Port Forwarding

#### HTTP/HTTPS (Auto-Port)
```bash
# HTTP - automatically uses port 80
./addforward.sh --vpsid 103 --protocol HTTP --domain app.example.com

# HTTPS - automatically uses port 443
./addforward.sh --vpsid 103 --protocol HTTPS --domain secure.example.com

# Interactive mode
./addforward.sh --interactive
```

#### TCP (Manual Ports)
```bash
# SSH forwarding
./addforward.sh --vpsid 103 --protocol TCP --domain 45.158.126.130 --src-port 2222 --dest-port 22

# Custom service
./addforward.sh -v 103 -p TCP -d 192.168.1.100 -s 8080 -t 80
```

### 4. Edit Port Forwarding

```bash
# Edit protocol to HTTPS (auto-port 443)
./editforward.sh --vpsid 103 --vdfid 596 --protocol HTTPS --domain secure.app.com

# Edit TCP ports
./editforward.sh --vpsid 103 --vdfid 596 --src-port 30222 --dest-port 22

# Interactive mode
./editforward.sh --interactive
```

### 5. Delete Port Forwarding

```bash
# Delete specific forwarding
./deleteforward.sh --vpsid 103 --vdfid 596

# Interactive mode with confirmation
./deleteforward.sh --interactive

# Delete with automatic confirmation
./deleteforward.sh --vpsid 103 --vdfid 596 --force
```

## 📖 Detailed Usage

### Protocol-Specific Behavior

#### HTTP Protocol
- **Auto-Port**: Source 80, Destination 80
- **Input Required**: Domain only
- **Example**: `app.example.com:80 → VM:80`

#### HTTPS Protocol  
- **Auto-Port**: Source 443, Destination 443
- **Input Required**: Domain only
- **Example**: `secure.example.com:443 → VM:443`

#### TCP Protocol
- **Manual Port**: User defines both ports
- **Input Required**: IP/Domain, source port, destination port
- **Example**: `192.168.1.100:2222 → VM:22`

### Interactive Mode Features

1. **Smart VM Selection** - Automatic selection for single VM environments
2. **Protocol-Aware Prompts** - Context-sensitive input requests
3. **Port Validation** - Real-time validation with HAProxy integration
4. **Auto-Detection** - Automatic IP detection for TCP protocols
5. **Confirmation Preview** - Before/after comparison for edits

### Command Line Options

#### Global Options
- `-h, --help` - Show help information
- `-n, --no-color` - Disable color output
- `-i, --interactive` - Force interactive mode

#### Add/Edit/Delete Specific Options
- `-v, --vpsid VPSID` - Target VM ID
- `-p, --protocol PROTOCOL` - HTTP/HTTPS/TCP
- `-d, --domain DOMAIN` - Source hostname/domain
- `-s, --src-port PORT` - Source port (TCP only)
- `-t, --dest-port PORT` - Destination port (TCP only)
- `-f, --vdfid VDFID` - Forwarding ID (edit/delete)
- `--force` - Delete without confirmation (delete only)

## 🎯 Use Cases

### Web Applications
```bash
# WordPress site
./vm.sh add --vpsid 103 --protocol HTTP --domain wordpress.example.com

# SSL-enabled site
./vm.sh add --vpsid 103 --protocol HTTPS --domain secure.example.com
```

### Development Services
```bash
# Node.js development server
./addforward.sh -v 103 -p TCP -d dev.example.com -s 3000 -t 3000

# Database access
./addforward.sh -v 103 -p TCP -d db.example.com -s 5432 -t 5432
```

### System Administration
```bash
# SSH on custom port
./addforward.sh -v 103 -p TCP -d 45.158.126.130 -s 2222 -t 22

# Web admin panel
./addforward.sh -v 103 -p TCP -d admin.example.com -s 8080 -t 80
```

## 🔧 Advanced Features

### HAProxy Integration
- **Port Validation** - Checks against allowed/reserved ports
- **Smart Hints** - Provides helpful port suggestions
- **Real-time Config** - Fetches current HAProxy configuration

### Error Handling
- **User-friendly Messages** - Clear error descriptions
- **Actionable Hints** - Specific guidance for resolution
- **Validation Feedback** - Real-time input validation

### Automation Support
- **Scriptable** - All functions work in non-interactive mode
- **JSON Output** - Machine-readable output option
- **Exit Codes** - Proper error code handling

## 🔄 Workflow Examples

### Complete Setup Workflow
```bash
# 1. Check available VMs
./vm.sh list

# 2. View existing forwarding
./vm.sh forward --vpsid 103

# 3. Add new HTTP forwarding
./vm.sh add --vpsid 103 --protocol HTTP --domain new-site.com

# 4. Edit existing forwarding  
./vm.sh edit --vpsid 103 --vdfid 596 --protocol HTTPS

# 5. Delete unnecessary forwarding
./vm.sh delete --vpsid 103 --vdfid 596
```

### Bulk Operations
```bash
# Add multiple HTTP sites
for domain in site1.com site2.com site3.com; do
    ./addforward.sh --vpsid 103 --protocol HTTP --domain $domain
done
```

## 🐛 Troubleshooting

### Common Issues

**1. API Connection Failed**
```bash
# Check configuration
cat /etc/vm/data.conf

# Test API connectivity
curl -sk "$API_URL?act=listvs&api=json&apikey=$API_KEY&apipass=$API_PASS"
```

**2. Port Already in Use**
```bash
# Check existing forwarding
./listforward.sh --vpsid 103

# View HAProxy configuration
./addforward.sh --interactive  # Shows port hints
```

**3. Invalid VPSID**
```bash
# List available VMs
./listvm.sh
```

### Debug Mode
```bash
# Enable verbose output
set -x
./addforward.sh --interactive
set +x
```

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

### Development Setup
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

### Guidelines
- Follow existing code style
- Add comments for complex logic
- Test on multiple VM configurations
- Update documentation as needed

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [Virtualizor](https://www.virtualizor.com/) for the excellent VPS management platform
- [jq](https://stedolan.github.io/jq/) for JSON processing capabilities
- The open-source community for inspiration and tools

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/iam-rizz/Domain-Forwarding-Virtualizor/issues)
- **Documentation**: This README and inline help (`--help`)
- **Community**: Feel free to contribute improvements and suggestions

### 💬 Contact Developer

<div align="center">

**Need help or have questions about this script?**

[![Telegram](https://img.shields.io/badge/Telegram-@rizzid03-2CA5E0?style=for-the-badge&logo=telegram&logoColor=white)](https://t.me/rizzid03)
[![WhatsApp](https://img.shields.io/badge/WhatsApp-Chat%20Developer-25D366?style=for-the-badge&logo=whatsapp&logoColor=white)](https://wa.me/6285700994200)

*💡 Ready to help with implementation, troubleshooting, and custom development*

</div>

---

**Made with ❤️ for the Virtualizor community**
