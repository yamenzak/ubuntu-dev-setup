#!/bin/bash

# Ubuntu Development Environment Auto-Setup Script
# For Frappe and Python development with Docker containerization

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

# Logging functions
log_info() { echo
echo "Manual VS Code Installation:"
echo "  ${BLUE}sudo snap install code --classic${NC}     # Recommended method"
echo "  ${BLUE}# OR download from: https://code.visualstudio.com${NC}"
echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_header() { echo -e "\n${PURPLE}=== $1 ===${NC}"; }

# Configuration
DEV_DIR="$HOME/Development"
GIT_NAME="Yamen Zakhour"
GIT_EMAIL="zakhouryamen@gmail.com"
GITHUB_USERNAME="yamenzak"

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   log_error "This script should not be run as root. Please run as a regular user."
   exit 1
fi

log_header "Ubuntu Development Environment Auto-Setup"
echo "This script will set up your development environment with:"
echo "- Essential development tools"
echo "- Docker & Docker Compose"
echo "- Node.js 20"
echo "- Python development tools"
echo "- Claude Code CLI"
echo "- Claude Code CLI"
echo "- Git configuration"
echo "- Container management scripts"
echo "- Directory structure"
echo

read -p "Continue with the installation? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    log_info "Installation cancelled."
    exit 0
fi

# Update system
log_header "Updating System"
sudo apt update && sudo apt upgrade -y
log_success "System updated"

# Install essential development tools
log_header "Installing Essential Development Tools"
sudo apt install -y \
    git \
    curl \
    wget \
    build-essential \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release \
    tree \
    htop \
    neofetch \
    unzip \
    zip \
    jq \
    ripgrep \
    net-tools
log_success "Essential tools installed"

# Install Node.js 20
log_header "Installing Node.js 20"
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs
log_success "Node.js $(node --version) installed"

# Install Python development tools
log_header "Installing Python Development Tools"
sudo apt install -y \
    python3 \
    python3-pip \
    python3-venv \
    python3-dev \
    python3-setuptools \
    python3-wheel
log_success "Python development tools installed"

# Install Docker
log_header "Installing Docker"
# Remove old versions if any
sudo apt remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true

# Add Docker's official GPG key
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Set up the repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker Engine
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Add user to docker group
sudo usermod -aG docker $USER

# Start and enable Docker
sudo systemctl enable docker
sudo systemctl start docker
log_success "Docker installed and configured"

# Install Claude Code CLI
log_header "Installing Claude Code CLI"
# Install via native binary (recommended method)
curl -fsSL https://claude.ai/install.sh | bash
log_success "Claude Code CLI installed"

# Setup development directory structure
log_header "Creating Development Directory Structure"
mkdir -p "$DEV_DIR"/{frappe,python,scripts}
log_success "Directory structure created at $DEV_DIR"

# Configure Git
log_header "Configuring Git"
git config --global user.name "$GIT_NAME"
git config --global user.email "$GIT_EMAIL"
git config --global init.defaultBranch main
git config --global pull.rebase false

# Generate SSH key for GitHub
if [[ ! -f "$HOME/.ssh/id_ed25519" ]]; then
    log_info "Generating SSH key for GitHub..."
    ssh-keygen -t ed25519 -C "$GIT_EMAIL" -f "$HOME/.ssh/id_ed25519" -N ""
    eval "$(ssh-agent -s)"
    ssh-add "$HOME/.ssh/id_ed25519"
    log_success "SSH key generated"
    log_warning "Add this SSH key to your GitHub account:"
    cat "$HOME/.ssh/id_ed25519.pub"
    echo
else
    log_info "SSH key already exists"
fi

# Create container manager script
log_header "Creating Container Manager Script"
cat > "$DEV_DIR/scripts/container-manager.sh" << 'SCRIPT_END'
#!/bin/bash

# Docker Container Manager for Development Projects
# Supports: Frappe and Python projects

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECTS_DIR="$HOME/Development"
CONTAINERS_CONFIG="$HOME/.dev-containers.json"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

init_config() {
    if [[ ! -f "$CONTAINERS_CONFIG" ]]; then
        echo '{}' > "$CONTAINERS_CONFIG"
    fi
}

get_next_port() {
    local base_port=$1
    local port=$base_port
    
    while netstat -tuln 2>/dev/null | grep -q ":$port " || ss -tuln 2>/dev/null | grep -q ":$port "; do
        ((port++))
    done
    echo $port
}

create_frappe_project() {
    local project_name=$1
    local project_dir="$PROJECTS_DIR/frappe/$project_name"
    
    if [[ -d "$project_dir" ]]; then
        log_error "Project $project_name already exists at $project_dir"
        exit 1
    fi
    
    log_info "Creating Frappe project: $project_name"
    
    # Clone your FrappeDev template
    git clone https://github.com/yamenzk/FrappeDev.git "$project_dir"
    cd "$project_dir"
    
    # Remove git history to start fresh
    rm -rf .git
    git init
    git add .
    git commit -m "Initial commit"
    
    # Make scripts executable
    chmod +x fh install.sh
    
    # Run the installation
    echo -e "$project_name\n1\n8000\ny" | ./install.sh
    
    local main_port=$(get_next_port 8000)
    
    # Store project info
    local temp_file=$(mktemp)
    jq --arg name "$project_name" --arg type "frappe" --arg dir "$project_dir" --arg port "$main_port" \
       '.[$name] = {type: $type, directory: $dir, port: ($port | tonumber), status: "created"}' \
       "$CONTAINERS_CONFIG" > "$temp_file" && mv "$temp_file" "$CONTAINERS_CONFIG"
    
    log_success "Created Frappe project $project_name at $project_dir"
    log_info "Use 'devman start $project_name' to start development"
}

create_python_project() {
    local project_name=$1
    local project_dir="$PROJECTS_DIR/python/$project_name"
    
    if [[ -d "$project_dir" ]]; then
        log_error "Project $project_name already exists at $project_dir"
        exit 1
    fi
    
    log_info "Creating Python project: $project_name"
    mkdir -p "$project_dir"
    cd "$project_dir"
    
    # Create Python Docker setup with PostgreSQL
    cat > docker-compose.yml << 'EOF'
version: '3.8'
services:
  python-app:
    build: .
    container_name: ${PROJECT_NAME}_python
    ports:
      - "${PYTHON_PORT}:8000"
    volumes:
      - .:/app
    environment:
      - PYTHONPATH=/app
      - PYTHONUNBUFFERED=1
      - DATABASE_URL=postgresql://postgres:postgres@postgres:5432/${PROJECT_NAME}
    depends_on:
      postgres:
        condition: service_healthy
    networks:
      - python-network

  postgres:
    image: postgres:14-alpine
    container_name: ${PROJECT_NAME}_postgres
    environment:
      - POSTGRES_DB=${PROJECT_NAME}
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=postgres
    volumes:
      - postgres-data:/var/lib/postgresql/data
    ports:
      - "${POSTGRES_PORT}:5432"
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 10s
      timeout: 5s
      retries: 5
    networks:
      - python-network

volumes:
  postgres-data:

networks:
  python-network:
    driver: bridge
EOF

    cat > Dockerfile << 'EOF'
FROM python:3.11-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements and install Python dependencies
COPY requirements.txt .
RUN pip install -r requirements.txt

# Copy application code
COPY . .

EXPOSE 8000

CMD ["python", "main.py"]
EOF

    cat > requirements.txt << 'EOF'
fastapi==0.104.1
uvicorn==0.24.0
python-dotenv==1.0.0
psycopg2-binary==2.9.9
sqlalchemy==2.0.23
alembic==1.12.1
pydantic==2.5.0
EOF

    cat > main.py << EOF
from fastapi import FastAPI
import uvicorn
import os

app = FastAPI(title="$project_name", version="1.0.0")

@app.get("/")
def read_root():
    return {"message": "Hello from $project_name!", "status": "running"}

@app.get("/health")
def health_check():
    return {"status": "healthy"}

if __name__ == "__main__":
    port = int(os.getenv("PORT", 8000))
    uvicorn.run(app, host="0.0.0.0", port=port)
EOF

    # Create .env file
    local python_port=$(get_next_port 8000)
    local postgres_port=$(get_next_port 5432)
    
    cat > .env << EOF
PROJECT_NAME=$project_name
PYTHON_PORT=$python_port
POSTGRES_PORT=$postgres_port
EOF

    # Initialize git
    git init
    echo "__pycache__/" > .gitignore
    echo "*.pyc" >> .gitignore
    echo ".env" >> .gitignore
    echo "postgres-data/" >> .gitignore
    
    git add .
    git commit -m "Initial Python project setup"
    
    # Store project info
    local temp_file=$(mktemp)
    jq --arg name "$project_name" --arg type "python" --arg dir "$project_dir" --arg port "$python_port" \
       '.[$name] = {type: $type, directory: $dir, port: ($port | tonumber), status: "created"}' \
       "$CONTAINERS_CONFIG" > "$temp_file" && mv "$temp_file" "$CONTAINERS_CONFIG"
    
    log_success "Created Python project $project_name"
    log_info "Main app port: $python_port"
    log_info "PostgreSQL port: $postgres_port"
    log_info "Use 'devman start $project_name' to start development"
}

start_project() {
    local project_name=$1
    local project_info=$(jq -r --arg name "$project_name" '.[$name] // empty' "$CONTAINERS_CONFIG")
    
    if [[ -z "$project_info" ]]; then
        log_error "Project $project_name not found"
        exit 1
    fi
    
    local project_dir=$(echo "$project_info" | jq -r '.directory')
    local project_type=$(echo "$project_info" | jq -r '.type')
    
    cd "$project_dir"
    
    if [[ "$project_type" == "frappe" ]]; then
        ./fh up
        log_info "Starting Frappe development server..."
        ./fh start &
    else
        docker compose up -d --build
    fi
    
    # Update status
    local temp_file=$(mktemp)
    jq --arg name "$project_name" '.[$name].status = "running"' \
       "$CONTAINERS_CONFIG" > "$temp_file" && mv "$temp_file" "$CONTAINERS_CONFIG"
    
    local port=$(echo "$project_info" | jq -r '.port')
    log_success "Project $project_name started"
    log_info "Access at: http://localhost:$port"
    
    if [[ "$project_type" == "frappe" ]]; then
        log_info "Default login: Administrator / admin"
    fi
}

stop_project() {
    local project_name=$1
    local project_info=$(jq -r --arg name "$project_name" '.[$name] // empty' "$CONTAINERS_CONFIG")
    
    if [[ -z "$project_info" ]]; then
        log_error "Project $project_name not found"
        exit 1
    fi
    
    local project_dir=$(echo "$project_info" | jq -r '.directory')
    local project_type=$(echo "$project_info" | jq -r '.type')
    
    cd "$project_dir"
    
    if [[ "$project_type" == "frappe" ]]; then
        ./fh down
    else
        docker compose down
    fi
    
    # Update status
    local temp_file=$(mktemp)
    jq --arg name "$project_name" '.[$name].status = "stopped"' \
       "$CONTAINERS_CONFIG" > "$temp_file" && mv "$temp_file" "$CONTAINERS_CONFIG"
    
    log_success "Project $project_name stopped"
}

shell_project() {
    local project_name=$1
    local project_info=$(jq -r --arg name "$project_name" '.[$name] // empty' "$CONTAINERS_CONFIG")
    
    if [[ -z "$project_info" ]]; then
        log_error "Project $project_name not found"
        exit 1
    fi
    
    local project_type=$(echo "$project_info" | jq -r '.type')
    local project_dir=$(echo "$project_info" | jq -r '.directory')
    
    if [[ "$project_type" == "frappe" ]]; then
        cd "$project_dir"
        ./fh shell
    else
        local container_name="${project_name}_python"
        log_info "Opening shell in $container_name"
        docker exec -it "$container_name" /bin/bash || docker exec -it "$container_name" /bin/sh
    fi
}

list_projects() {
    log_info "Development Projects:"
    echo
    
    if [[ ! -s "$CONTAINERS_CONFIG" || $(cat "$CONTAINERS_CONFIG") == "{}" ]]; then
        log_warning "No projects found"
        return
    fi
    
    printf "%-20s %-10s %-10s %-6s %s\n" "NAME" "TYPE" "STATUS" "PORT" "DIRECTORY"
    printf "%-20s %-10s %-10s %-6s %s\n" "----" "----" "------" "----" "---------"
    
    jq -r 'to_entries[] | "\(.key) \(.value.type) \(.value.status) \(.value.port) \(.value.directory)"' \
       "$CONTAINERS_CONFIG" | \
    while read -r name type status port directory; do
        printf "%-20s %-10s %-10s %-6s %s\n" "$name" "$type" "$status" "$port" "$directory"
    done
}

remove_project() {
    local project_name=$1
    
    if [[ -z "$project_name" ]]; then
        log_error "Usage: $0 remove <project-name>"
        exit 1
    fi
    
    local project_info=$(jq -r --arg name "$project_name" '.[$name] // empty' "$CONTAINERS_CONFIG")
    
    if [[ -z "$project_info" ]]; then
        log_error "Project $project_name not found"
        exit 1
    fi
    
    local project_dir=$(echo "$project_info" | jq -r '.directory')
    local project_type=$(echo "$project_info" | jq -r '.type')
    
    # Stop containers if running
    if [[ -d "$project_dir" ]]; then
        cd "$project_dir"
        if [[ "$project_type" == "frappe" ]]; then
            ./fh clean || true
        else
            docker compose down -v 2>/dev/null || true
        fi
    fi
    
    # Ask for confirmation
    read -p "Remove project $project_name and all its data? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Operation cancelled"
        exit 0
    fi
    
    # Remove directory
    rm -rf "$project_dir"
    
    # Remove from config
    local temp_file=$(mktemp)
    jq --arg name "$project_name" 'del(.[$name])' \
       "$CONTAINERS_CONFIG" > "$temp_file" && mv "$temp_file" "$CONTAINERS_CONFIG"
    
    log_success "Project $project_name removed"
}

main() {
    init_config
    
    case "${1:-}" in
        "create")
            case "$3" in
                "frappe") create_frappe_project "$2" ;;
                "python") create_python_project "$2" ;;
                *) 
                    log_error "Supported types: frappe, python"
                    log_info "Usage: $0 create <project-name> <type>"
                    exit 1 
                    ;;
            esac
            ;;
        "start") start_project "$2" ;;
        "stop") stop_project "$2" ;;
        "restart") 
            stop_project "$2"
            start_project "$2"
            ;;
        "shell") shell_project "$2" ;;
        "list"|"ls") list_projects ;;
        "remove"|"rm") remove_project "$2" ;;
        "help"|"--help"|"-h"|"")
            cat << 'EOF'
Docker Container Manager for Development Projects

Usage: devman [command] [options]

Commands:
    create <name> <type>     Create new project (types: frappe, python)
    start <name>             Start project containers
    stop <name>              Stop project containers
    restart <name>           Restart project containers
    shell <name>             Open shell in project container
    list|ls                  List all projects
    remove|rm <name>         Remove project and all data
    help                     Show this help message

Examples:
    devman create my-erp frappe
    devman create my-api python
    devman start my-erp
    devman shell my-api
    devman list
    devman stop my-erp
    devman remove my-api

Project Types:
    frappe    - Full Frappe/ERPNext setup with MariaDB, Redis
    python    - Python FastAPI setup with PostgreSQL

EOF
            ;;
        *)
            log_error "Unknown command: $1"
            log_info "Use 'devman help' for usage information"
            exit 1
            ;;
    esac
}

main "$@"
SCRIPT_END

chmod +x "$DEV_DIR/scripts/container-manager.sh"

# Create symlink for easy access
sudo ln -sf "$DEV_DIR/scripts/container-manager.sh" /usr/local/bin/devman

log_success "Container manager script created and linked as 'devman'"

# Install Zsh and Oh My Zsh (optional)
log_header "Installing Zsh and Oh My Zsh (Optional)"
read -p "Install Zsh and Oh My Zsh for better terminal experience? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    sudo apt install -y zsh
    
    # Install Oh My Zsh
    sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    
    # Install useful plugins
    git clone https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions
    git clone https://github.com/zsh-users/zsh-syntax-highlighting ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
    
    # Update .zshrc with plugins
    sed -i 's/plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting docker npm node python)/' ~/.zshrc
    
    # Add Claude Code and development paths
    echo "" >> ~/.zshrc
    echo "# Development paths" >> ~/.zshrc
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
    echo 'export PATH="$HOME/.claude/bin:$PATH"' >> ~/.zshrc
    echo "" >> ~/.zshrc
    
    log_success "Zsh and Oh My Zsh installed"
else
    # Add paths to bashrc if not using zsh
    echo "" >> ~/.bashrc
    echo "# Development paths" >> ~/.bashrc
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
    echo 'export PATH="$HOME/.claude/bin:$PATH"' >> ~/.bashrc
    echo "" >> ~/.bashrc
fi

# Final instructions
log_header "Setup Complete!"
echo -e "${GREEN}Your Ubuntu development environment is now ready!${NC}"
echo
echo "Next steps:"
echo "1. ${YELLOW}Logout and login again${NC} to apply Docker group membership"
echo "2. ${YELLOW}Add your SSH key to GitHub:${NC}"
echo "   - Go to https://github.com/settings/keys"
echo "   - Add the key from: cat ~/.ssh/id_ed25519.pub"
echo "3. ${YELLOW}Configure Claude Code:${NC}"
echo "   - Run: claude auth"
echo "   - Follow the authentication process"
echo "4. ${YELLOW}Test your setup:${NC}"
echo "   - docker run hello-world"
echo "   - devman list"
echo "   - claude --help"
echo
echo "Container Manager Usage:"
echo "  ${BLUE}devman create my-erp frappe${NC}        # Create Frappe project"
echo "  ${BLUE}devman create my-api python${NC}        # Create Python project"
echo "  ${BLUE}devman start my-erp${NC}                # Start project"
echo "  ${BLUE}devman shell my-api${NC}                # Open shell in container"
echo "  ${BLUE}devman list${NC}                        # List all projects"
echo
echo "Development directories:"
echo "  ${BLUE}~/Development/frappe/${NC}    - Frappe projects"
echo "  ${BLUE}~/Development/python/${NC}    - Python projects"
echo "  ${BLUE}~/Development/scripts/${NC}   - Utility scripts"
echo
log_success "Happy coding! 🚀"