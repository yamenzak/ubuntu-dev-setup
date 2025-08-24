# Ubuntu Development Environment Auto-Setup

A complete automated setup script for Ubuntu development environment focused on Frappe and Python development with Docker containerization.

## 🚀 Quick Start

```bash
curl -fsSL https://raw.githubusercontent.com/yamenzak/ubuntu-dev-setup/main/ubuntu-dev-setup.sh -o ubuntu-dev-setup.sh
chmod +x ubuntu-dev-setup.sh
./ubuntu-dev-setup.sh
```

## 📦 What Gets Installed

- **Essential Tools**: Git, curl, build tools, jq, ripgrep, net-tools
- **Node.js 20**: Latest LTS version via NodeSource
- **Python 3**: Complete development stack (pip, venv, dev tools)
- **Docker**: Latest Docker Engine with Docker Compose
- **Claude Code CLI**: AI-powered development assistant
- **Development Tools**: Container management scripts and organized directory structure

## 📁 Directory Structure

After installation, your development environment will be organized as:

```
~/Development/
├── frappe/          # Frappe/ERPNext projects
├── python/          # Python/FastAPI projects  
└── scripts/         # Utility scripts
```

## 🐳 Container Manager (`devman`)

A powerful CLI tool for managing your containerized development projects.

### Create Projects

```bash
# Create new Frappe project (uses FrappeDev template)
devman create my-erp frappe

# Create new Python project (FastAPI + PostgreSQL)
devman create my-api python
```

### Manage Projects

```bash
devman start my-erp          # Start project containers
devman stop my-erp           # Stop project containers  
devman restart my-erp        # Restart project
devman shell my-erp          # Open shell in container
devman list                  # List all projects
devman remove my-erp         # Remove project (with confirmation)
```

### Project Access

- **Frappe projects**: `http://localhost:8000` (Default: Administrator/admin)
- **Python projects**: `http://localhost:8001` (FastAPI with auto docs)

## ⚙️ Configuration

The script automatically configures:

- **Git**: Pre-configured with Yamen Zakhour / zakhouryamen@gmail.com
- **SSH Key**: Generated for GitHub (ed25519)
- **Docker**: User added to docker group (requires logout/login)
- **Paths**: Claude Code and development tools added to PATH

## 🔐 Post-Installation Steps

1. **Logout and login** to apply Docker group membership
2. **Add SSH key to GitHub**:
   ```bash
   cat ~/.ssh/id_ed25519.pub
   # Copy output and add to https://github.com/settings/keys
   ```
3. **Authenticate Claude Code**:
   ```bash
   claude auth
   ```
4. **Test your setup**:
   ```bash
   docker run hello-world
   devman list
   claude --help
   ```

## 🎯 Project Templates

### Frappe Projects
- Uses the [FrappeDev](https://github.com/yamenzk/FrappeDev) template
- Full Frappe/ERPNext environment with MariaDB and Redis
- Interactive installer with version selection
- Development server with hot reload

### Python Projects  
- FastAPI application template
- PostgreSQL database with health checks
- Docker development environment
- Auto-generated API documentation
- Production-ready structure

## 🔧 Optional Enhancements

The script offers optional installation of:
- **Zsh + Oh My Zsh** with useful plugins
- Auto-suggestions and syntax highlighting
- Enhanced terminal experience

## 🐛 Troubleshooting

### Docker Permission Issues
If you get permission errors with Docker:
```bash
# Logout and login, or run:
newgrp docker
```

### Port Conflicts
The container manager automatically finds available ports, but you can check with:
```bash
devman list  # Shows all project ports
```
