#!/bin/bash
# =====================================================================
# VSH HARD SETUP - EXTREMELY DANGEROUS SYSTEM MODIFICATION SCRIPT
# =====================================================================
# WARNING: This script will PERMANENTLY REMOVE all other shells and
#          make VSH the ONLY shell on your system. This action is
#          IRREVERSIBLE and can render your system UNUSABLE.
#
# THIS SCRIPT WILL:
# - Remove ALL other shells (bash, zsh, fish, dash, etc.)
# - Modify system files (/etc/shells, /etc/passwd)
# - Change default shell for ALL users to VSH
# - Remove shell packages completely
# - Update system configurations
#
# USE AT YOUR OWN RISK - NO WARRANTY PROVIDED
# =====================================================================

set -e  # Exit on any error

SHELL_NAME="vsh"
VSH_PATH="/usr/local/bin/vsh"
BACKUP_DIR="/tmp/vsh_hard_setup_backup_$(date +%s)"

# ANSI Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# === Function: Print colored output ===
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_danger() {
    echo -e "${RED}[DANGER]${NC} $1"
}

# === Function: Detect system ===
detect_system() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "$ID"
    elif [ -f /etc/alpine-release ]; then
        echo "alpine"
    else
        echo "linux"
    fi
}

# === Function: Check if VSH exists ===
check_vsh() {
    if [ ! -f "$VSH_PATH" ]; then
        print_error "VSH not found at $VSH_PATH"
        print_error "Please run install.sh first to install VSH"
        exit 1
    fi
    
    if [ ! -x "$VSH_PATH" ]; then
        print_error "VSH is not executable at $VSH_PATH"
        exit 1
    fi
    
    print_success "VSH found and executable at $VSH_PATH"
}

# === Function: Create backup directory ===
create_backup() {
    print_status "Creating backup directory: $BACKUP_DIR"
    mkdir -p "$BACKUP_DIR"
    
    # Backup critical files
    cp /etc/shells "$BACKUP_DIR/shells.bak" 2>/dev/null || true
    cp /etc/passwd "$BACKUP_DIR/passwd.bak" 2>/dev/null || true
    cp /etc/shadow "$BACKUP_DIR/shadow.bak" 2>/dev/null || true
    
    print_success "System files backed up to $BACKUP_DIR"
}

# === Function: Get list of installed shells ===
get_installed_shells() {
    local shells=()
    
    # Common shell binaries to look for
    local common_shells=(
        "/bin/bash" "/usr/bin/bash"
        "/bin/zsh" "/usr/bin/zsh" "/usr/local/bin/zsh"
        "/bin/fish" "/usr/bin/fish" "/usr/local/bin/fish"
        "/bin/dash" "/usr/bin/dash"
        "/bin/sh" "/usr/bin/sh"
        "/bin/csh" "/usr/bin/csh"
        "/bin/tcsh" "/usr/bin/tcsh"
        "/bin/ksh" "/usr/bin/ksh"
        "/usr/local/bin/bash"
        "/usr/local/bin/zsh"
    )
    
    for shell in "${common_shells[@]}"; do
        if [ -f "$shell" ] && [ "$shell" != "$VSH_PATH" ]; then
            shells+=("$shell")
        fi
    done
    
    # Also check /etc/shells for any other shells
    if [ -f /etc/shells ]; then
        while IFS= read -r line; do
            line=$(echo "$line" | sed 's/#.*//' | xargs)  # Remove comments and trim
            if [ -n "$line" ] && [ -f "$line" ] && [ "$line" != "$VSH_PATH" ]; then
                if [[ ! " ${shells[@]} " =~ " ${line} " ]]; then
                    shells+=("$line")
                fi
            fi
        done < /etc/shells
    fi
    
    printf '%s\n' "${shells[@]}"
}

# === Function: Remove shell packages ===
remove_shell_packages() {
    local system="$1"
    
    print_danger "Removing shell packages from system..."
    
    case "$system" in
    # Replace all sudo commands with dynamic sudo command
    local sudo_cmd
    if [ "$EUID" -eq 0 ]; then
        sudo_cmd=""
    else
        sudo_cmd="sudo"
    fi
        ubuntu|debian)
            # Remove shell packages with maximum force
            $sudo_cmd apt-get remove --purge -y bash zsh fish dash csh tcsh ksh 2>/dev/null || true
            $sudo_cmd apt-get autoremove -y 2>/dev/null || true
            $sudo_cmd apt-get autoclean -y 2>/dev/null || true
            ;;
        arch|manjaro)
            $sudo_cmd pacman -Rns --noconfirm bash zsh fish dash tcsh 2>/dev/null || true
            ;;
        fedora)
            $sudo_cmd dnf remove -y bash zsh fish dash tcsh ksh 2>/dev/null || true
            ;;
        rhel|centos)
            if command -v dnf >/dev/null 2>&1; then
                $sudo_cmd dnf remove -y bash zsh fish dash tcsh ksh 2>/dev/null || true
            else
                $sudo_cmd yum remove -y bash zsh fish dash tcsh ksh 2>/dev/null || true
            fi
            ;;
        opensuse*)
            $sudo_cmd zypper remove -y bash zsh fish dash tcsh 2>/dev/null || true
            ;;
        alpine)
            $sudo_cmd apk del bash zsh fish dash 2>/dev/null || true
            ;;
        void)
            $sudo_cmd xbps-remove -y bash zsh fish dash 2>/dev/null || true
            ;;
        macos)
            # macOS - FORCE REMOVAL OF EVERYTHING
            print_danger "macOS - ATTEMPTING MAXIMUM DESTRUCTION!"
            if command -v brew >/dev/null 2>&1; then
                brew uninstall --ignore-dependencies zsh fish bash 2>/dev/null || true
                brew uninstall --force zsh fish bash 2>/dev/null || true
            fi
            # Try to remove system shells (this will probably fail but we try anyway)
            $sudo_cmd rm -f /bin/bash /bin/zsh /bin/csh /bin/tcsh 2>/dev/null || true
            ;;
        *)
            print_warning "Unknown system - skipping package removal"
            ;;
    esac
    
    print_success "Shell packages removal attempted"
}

# === Function: Remove shell binaries ===
remove_shell_binaries() {
    local shells
    mapfile -t shells < <(get_installed_shells)
    
    print_danger "Removing shell binaries..."
    
    for shell in "${shells[@]}"; do
        if [ -f "$shell" ]; then
            print_status "Removing: $shell"
            sudo rm -f "$shell" 2>/dev/null || print_warning "Could not remove $shell"
        fi
    done
    
    # Remove common shell symlinks
    sudo rm -f /bin/sh /usr/bin/sh 2>/dev/null || true
    
    print_success "Shell binaries removed"
}

# === Function: Update /etc/shells ===
update_etc_shells() {
    print_status "Updating /etc/shells..."
    
    # Create new /etc/shells with only VSH
    echo "$VSH_PATH" | sudo tee /etc/shells > /dev/null
    
    print_success "/etc/shells updated - VSH is now the only valid shell"
}

# === Function: Change user shells ===
change_user_shells() {
    print_status "Changing all user shells to VSH..."
    
    # Get all users from /etc/passwd
    while IFS=: read -r username _ uid _ _ _ shell; do
        # Skip system users (UID < 1000) but include root
        if [ "$uid" -ge 1000 ] || [ "$username" = "root" ]; then
            if [ "$shell" != "$VSH_PATH" ] && [ -n "$shell" ]; then
                print_status "Changing shell for user: $username ($shell -> $VSH_PATH)"
                sudo usermod -s "$VSH_PATH" "$username"
            fi
        fi
    done < /etc/passwd
    
    print_success "User shells updated"
}

# === Function: Update system default shell ===
update_system_defaults() {
    print_status "Updating system default shell configurations..."
    
    # Update /bin/sh symlink to point to VSH
    sudo ln -sf "$VSH_PATH" /bin/sh 2>/dev/null || true
    sudo ln -sf "$VSH_PATH" /usr/bin/sh 2>/dev/null || true
    
    # Update environment variables in common locations
    local env_files=(
        "/etc/environment"
        "/etc/profile"
        "/etc/bash.bashrc"
        "/etc/zsh/zshenv"
    )
    
    for file in "${env_files[@]}"; do
        if [ -f "$file" ]; then
            sudo sed -i.bak "s|SHELL=.*|SHELL=$VSH_PATH|g" "$file" 2>/dev/null || true
        fi
    done
    
    print_success "System defaults updated"
}

# === Function: Clean up shell configs ===
cleanup_shell_configs() {
    print_status "Cleaning up shell configuration files..."
    
    # Remove global shell configs
    sudo rm -rf /etc/bash.bashrc /etc/bash_completion.d 2>/dev/null || true
    sudo rm -rf /etc/zsh /usr/share/zsh 2>/dev/null || true
    sudo rm -rf /etc/fish /usr/share/fish 2>/dev/null || true
    
    # Clean up user directories (be careful here)
    print_warning "Removing user shell configs - this will delete .bashrc, .zshrc, etc."
    find /home -name ".bashrc" -delete 2>/dev/null || true
    find /home -name ".zshrc" -delete 2>/dev/null || true
    find /home -name ".fishrc" -delete 2>/dev/null || true
    find /home -name ".bash_profile" -delete 2>/dev/null || true
    find /home -name ".bash_history" -delete 2>/dev/null || true
    find /home -name ".zsh_history" -delete 2>/dev/null || true
    
    # Clean root's shell configs too
    sudo rm -f /root/.bashrc /root/.zshrc /root/.bash_profile /root/.bash_history /root/.zsh_history 2>/dev/null || true
    
    print_success "Shell configurations cleaned up"
}

# === Function: Create VSH symlinks ===
create_vsh_symlinks() {
    print_status "Creating VSH compatibility symlinks..."
    
    # Create symlinks for common shell names to point to VSH
    local shell_names=("bash" "zsh" "fish" "dash" "sh")
    
    for shell_name in "${shell_names[@]}"; do
        sudo ln -sf "$VSH_PATH" "/usr/local/bin/$shell_name" 2>/dev/null || true
        sudo ln -sf "$VSH_PATH" "/bin/$shell_name" 2>/dev/null || true
        sudo ln -sf "$VSH_PATH" "/usr/bin/$shell_name" 2>/dev/null || true
    done
    
    print_success "VSH symlinks created for compatibility"
}

# === Function: Verify setup ===
verify_setup() {
    print_status "Verifying VSH hard setup..."
    
    # Check /etc/shells
    if grep -q "$VSH_PATH" /etc/shells && [ "$(wc -l < /etc/shells)" -eq 1 ]; then
        print_success "/etc/shells contains only VSH"
    else
        print_error "/etc/shells verification failed"
    fi
    
    # Check if other shells still exist
    local remaining_shells
    mapfile -t remaining_shells < <(get_installed_shells)
    
    if [ ${#remaining_shells[@]} -eq 0 ]; then
        print_success "No other shells found on system"
    else
        print_warning "Some shells may still exist:"
        printf '  %s\n' "${remaining_shells[@]}"
    fi
    
    # Check current user's shell
    local current_shell
    current_shell=$(getent passwd "$USER" | cut -d: -f7)
    if [ "$current_shell" = "$VSH_PATH" ]; then
        print_success "Current user shell is VSH"
    else
        print_warning "Current user shell is: $current_shell"
    fi
    
    print_success "VSH hard setup verification complete"
}

# === Function: Show final warning and status ===
show_final_status() {
    echo ""
    echo "========================================================"
    print_danger "VSH HARD SETUP COMPLETED"
    echo "========================================================"
    print_success "VSH is now the ONLY shell on this system"
    print_warning "All other shells have been PERMANENTLY REMOVED"
    print_status "Backup files saved to: $BACKUP_DIR"
    echo ""
    print_danger "IMPORTANT NOTES:"
    echo "  • You MUST restart your terminal/session now"
    echo "  • All shell scripts expecting bash/zsh may fail"
    echo "  • Some system services may be affected"
    echo "  • This change is PERMANENT and IRREVERSIBLE"
    echo ""
    print_status "VSH Path: $VSH_PATH"
    print_status "To restore (if needed): Use backup files in $BACKUP_DIR"
    echo "========================================================"
}

# === Main execution ===
main() {
    echo "========================================================"
    echo -e "${RED}💀 VSH HARD SETUP - MAXIMUM DESTRUCTION MODE 💀${NC}"
    echo "========================================================"
    print_danger "STARTING IMMEDIATE SYSTEM DESTRUCTION!"
    print_danger "NO WARNINGS, NO MERCY, NO GOING BACK!"
    echo ""
    
    # Force sudo/root access regardless of current user
    if [ "$EUID" -eq 0 ]; then
        print_danger "RUNNING AS ROOT - MAXIMUM DESTRUCTION ENABLED!"
        SUDO_CMD=""
    else
        print_danger "ELEVATING TO ROOT PRIVILEGES FOR MAXIMUM CHAOS!"
        SUDO_CMD="sudo"
    fi
    
    local system
    system=$(detect_system)
    print_status "Detected system: $system"
    
    check_vsh
    create_backup
    
    print_danger "🔥 BEGINNING TOTAL SHELL ANNIHILATION 🔥"
    
    remove_shell_packages "$system"
    remove_shell_binaries
    update_etc_shells
    change_user_shells
    update_system_defaults
    cleanup_shell_configs
    create_vsh_symlinks
    
    verify_setup
    show_final_status
    
    print_danger "REBOOT RECOMMENDED - System shell configuration changed"
}

# === NO SAFETY GUARDS - PURE CHAOS ===
# Run with any arguments or no arguments - we don't care
# Run as root or user - we don't care
# MAXIMUM DESTRUCTION MODE ACTIVATED

main "$@"
