#!/bin/bash
set -e  # Exit on error

SHELL_NAME="vsh"
INSTALL_DIR="/usr/local/bin"

# === Function: Detect OS and Distro ===
detect_system() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "$ID"
    elif [ -f /etc/alpine-release ]; then
        echo "alpine"
    elif [ -f /etc/redhat-release ]; then
        echo "rhel"
    else
        echo "unknown"
    fi
}

# === Function: Check if command exists ===
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# === Function: Check if package is installed ===
check_package_installed() {
    local package="$1"
    local system="$2"
    
    case "$system" in
        macos)
            brew list "$package" >/dev/null 2>&1
            ;;
        arch)
            pacman -Qi "$package" >/dev/null 2>&1
            ;;
        ubuntu|debian)
            dpkg -l "$package" >/dev/null 2>&1
            ;;
        fedora|rhel|centos)
            rpm -q "$package" >/dev/null 2>&1
            ;;
        opensuse*)
            rpm -q "$package" >/dev/null 2>&1
            ;;
        alpine)
            apk info -e "$package" >/dev/null 2>&1
            ;;
        void)
            xbps-query "$package" >/dev/null 2>&1
            ;;
        gentoo)
            equery list "$package" >/dev/null 2>&1
            ;;
        *)
            return 1
            ;;
    esac
}

# === Function: Install single package if not present ===
install_package_if_needed() {
    local package="$1"
    local system="$2"
    local display_name="${3:-$package}"
    
    if check_package_installed "$package" "$system"; then
        echo "✅ $display_name is already installed"
        return 0
    fi
    
    echo "📦 Installing $display_name..."
    case "$system" in
        macos)
            brew install "$package"
            ;;
        arch)
            sudo pacman -S --needed "$package"
            ;;
        ubuntu|debian)
            sudo apt install -y "$package"
            ;;
        fedora)
            sudo dnf install -y "$package"
            ;;
        rhel|centos)
            if command_exists dnf; then
                sudo dnf install -y "$package"
            else
                sudo yum install -y "$package"
            fi
            ;;
        opensuse-leap|opensuse-tumbleweed)
            sudo zypper install -y "$package"
            ;;
        alpine)
            sudo apk add "$package"
            ;;
        void)
            sudo xbps-install -y "$package"
            ;;
        gentoo)
            sudo emerge "$package"
            ;;
        *)
            echo "⚠️ Cannot install $display_name automatically on $system"
            return 1
            ;;
    esac
}

# === Function: Check and install essential tools ===
check_essential_tools() {
    local system="$1"
    
    echo "🔍 Checking essential development tools..."
    
    # Check for make
    if ! command_exists make; then
        case "$system" in
            macos)
                install_package_if_needed "make" "$system"
                ;;
            ubuntu|debian)
                install_package_if_needed "build-essential" "$system" "build tools (including make)"
                ;;
            *)
                install_package_if_needed "make" "$system"
                ;;
        esac
    else
        echo "✅ make is already available"
    fi
    
    # Check for gcc/clang
    if ! command_exists gcc && ! command_exists clang; then
        case "$system" in
            macos)
                echo "📦 Installing Xcode Command Line Tools (includes clang)..."
                xcode-select --install 2>/dev/null || echo "⚠️ Xcode tools may already be installed"
                ;;
            *)
                install_package_if_needed "gcc" "$system"
                ;;
        esac
    else
        echo "✅ C compiler is already available"
    fi
}

# === Function: Install Packages ===
install_packages() {
    local system="$1"
    echo "🔍 Checking and installing dependencies for $system..."
    
    # First ensure we have essential build tools
    check_essential_tools "$system"
    
    case "$system" in
        macos)
            # macOS uses Homebrew
            if ! command_exists brew; then
                echo "❌ Homebrew not found. Please install Homebrew first:"
                echo "   /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
                exit 1
            fi
            install_package_if_needed "readline" "$system"
            ;;
        arch|manjaro)
            # Update package database
            if ! check_package_installed "base-devel" "$system"; then
                echo "📦 Installing base-devel group..."
                sudo pacman -Syu --needed base-devel
            else
                echo "✅ base-devel is already installed"
            fi
            install_package_if_needed "readline" "$system"
            ;;
        ubuntu|debian|pop|mint|elementary)
            sudo apt update
            if ! check_package_installed "build-essential" "$system"; then
                install_package_if_needed "build-essential" "$system"
            fi
            install_package_if_needed "libreadline-dev" "$system" "readline development headers"
            ;;
        fedora)
            install_package_if_needed "gcc" "$system"
            install_package_if_needed "make" "$system"
            install_package_if_needed "readline-devel" "$system" "readline development headers"
            ;;
        rhel|centos)
            # Enable EPEL for additional packages
            if ! rpm -q epel-release >/dev/null 2>&1; then
                echo "📦 Installing EPEL repository..."
                if command_exists dnf; then
                    sudo dnf install -y epel-release
                else
                    sudo yum install -y epel-release
                fi
            fi
            install_package_if_needed "gcc" "$system"
            install_package_if_needed "make" "$system"
            install_package_if_needed "readline-devel" "$system" "readline development headers"
            ;;
        opensuse-leap|opensuse-tumbleweed)
            install_package_if_needed "gcc" "$system"
            install_package_if_needed "make" "$system"
            install_package_if_needed "readline-devel" "$system" "readline development headers"
            ;;
        alpine)
            sudo apk update
            install_package_if_needed "build-base" "$system" "build tools"
            install_package_if_needed "readline-dev" "$system" "readline development headers"
            ;;
        void)
            sudo xbps-install -Sy
            install_package_if_needed "base-devel" "$system" "base development tools"
            install_package_if_needed "readline-devel" "$system" "readline development headers"
            ;;
        gentoo)
            install_package_if_needed "sys-devel/gcc" "$system" "GCC compiler"
            install_package_if_needed "sys-libs/readline" "$system" "readline library"
            ;;
        nixos)
            echo "⚠️ NixOS detected. Please use nix-shell or add dependencies to your configuration:"
            echo "   nix-shell -p gcc gnumake readline"
            echo "   Or add to your system configuration: gcc gnumake readline"
            exit 1
            ;;
        *)
            echo "⚠️ Unknown system: $system"
            echo "Please manually install the following dependencies:"
            echo "  - C compiler (gcc or clang)"
            echo "  - make"
            echo "  - readline development headers"
            echo ""
            echo "Common package names:"
            echo "  - build-essential or base-devel (for compiler and make)"
            echo "  - libreadline-dev or readline-devel (for readline)"
            ;;
    esac
}

# === Function: Build ===
build_shell() {
    if [ ! -f "Makefile" ] && [ ! -f "makefile" ]; then
        echo "❌ No Makefile found in current directory"
        exit 1
    fi
    
    echo "🛠️  Building $SHELL_NAME..."
    make clean 2>/dev/null || true  # Clean if possible, ignore errors
    make
    
    if [ ! -f "$SHELL_NAME" ]; then
        echo "❌ Build failed - $SHELL_NAME binary not created"
        exit 1
    fi
    
    echo "✅ Build successful!"
}

# === Function: Install Binary ===
install_binary() {
    if [ ! -f "$SHELL_NAME" ]; then
        echo "❌ Binary $SHELL_NAME not found. Build failed?"
        exit 1
    fi
    
    # Choose appropriate install directory
    if [[ "$OSTYPE" == "darwin"* ]]; then
        INSTALL_DIR="/usr/local/bin"
    else
        INSTALL_DIR="/usr/local/bin"
    fi
    
    echo "📦 Installing $SHELL_NAME to $INSTALL_DIR..."
    
    # Create install directory if it doesn't exist
    sudo mkdir -p "$INSTALL_DIR"
    sudo cp "$SHELL_NAME" "$INSTALL_DIR/"
    sudo chmod +x "$INSTALL_DIR/$SHELL_NAME"
    
    # Verify installation
    if command -v "$SHELL_NAME" >/dev/null 2>&1; then
        echo "✅ $SHELL_NAME installed successfully!"
        echo "   You can now run it using: $SHELL_NAME"
        echo "   Version: $($SHELL_NAME --version 2>/dev/null || echo 'Unknown')"
    else
        echo "⚠️ $SHELL_NAME installed but not found in PATH."
        echo "   Try adding $INSTALL_DIR to your PATH or restart your terminal."
        echo "   You can run it directly with: $INSTALL_DIR/$SHELL_NAME"
    fi
}

# === Function: Show system info ===
show_system_info() {
    echo "🖥️  System Information:"
    echo "   OS: $OSTYPE"
    echo "   Architecture: $(uname -m)"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "   macOS Version: $(sw_vers -productVersion)"
    else
        echo "   Kernel: $(uname -r)"
    fi
}

# === Main Execution ===
main() {
    echo "🐚 Vatsal's Shell ($SHELL_NAME) Installer"
    echo "=========================================="
    
    show_system_info
    
    local system=$(detect_system)
    echo "📦 Detected system: $system"
    echo ""
    
    # Check if we're in the right directory
    if [ ! -f "Makefile" ] && [ ! -f "makefile" ]; then
        echo "⚠️ Warning: No Makefile found in current directory"
        echo "   Make sure you're in the project root directory"
    fi
    
    install_packages "$system"
    echo ""
    build_shell
    echo ""
    install_binary
    echo ""
    echo "🎉 Installation complete!"
}

# === Help function ===
show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --help     Show this help message"
    echo "  --deps-only    Only install dependencies, don't build or install"
    echo "  --build-only   Only build, don't install dependencies or install binary"
    echo ""
    echo "This script will:"
    echo "  1. Detect your operating system and distribution"
    echo "  2. Install necessary build dependencies (gcc, make, readline)"
    echo "  3. Build the shell using make"
    echo "  4. Install the binary to $INSTALL_DIR"
}

# === Parse command line arguments ===
case "${1:-}" in
    -h|--help)
        show_help
        exit 0
        ;;
    --deps-only)
        echo "🐚 Installing dependencies only..."
        system=$(detect_system)
        install_packages "$system"
        echo "✅ Dependencies installed!"
        exit 0
        ;;
    --build-only)
        echo "🐚 Building only..."
        build_shell
        echo "✅ Build complete!"
        exit 0
        ;;
    "")
        main "$@"
        ;;
    *)
        echo "Unknown option: $1"
        show_help
        exit 1
        ;;
esac
