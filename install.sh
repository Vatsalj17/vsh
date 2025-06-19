#!/bin/bash
set -e

SHELL_NAME="vsh"
INSTALL_DIR="/usr/local/bin"

detect_system() {
	if [[ "$OSTYPE" == "darwin"* ]]; then
		echo "macos"
	elif [ -f /etc/os-release ]; then
		. /etc/os-release && echo "$ID"
	elif [ -f /etc/alpine-release ]; then
		echo "alpine"
	elif [ -f /etc/redhat-release ]; then
		echo "rhel"
	else
		echo "unknown"
	fi
}

command_exists() {
	command -v "$1" >/dev/null 2>&1
}

check_package_installed() {
	local package="$1" system="$2"
	case "$system" in
		macos) brew list "$package" >/dev/null 2>&1 ;;
		arch) pacman -Qi "$package" >/dev/null 2>&1 ;;
		ubuntu | debian) dpkg -l "$package" >/dev/null 2>&1 ;;
		fedora | rhel | centos | opensuse*) rpm -q "$package" >/dev/null 2>&1 ;;
		alpine) apk info -e "$package" >/dev/null 2>&1 ;;
		void) xbps-query "$package" >/dev/null 2>&1 ;;
		gentoo) equery list "$package" >/dev/null 2>&1 ;;
		*) return 1 ;;
	esac
}

install_package_if_needed() {
	local package="$1" system="$2" display="${3:-$package}"
	if check_package_installed "$package" "$system"; then
		echo "✅ $display is already installed"
		return
	fi

	echo "📦 Installing $display..."
	case "$system" in
		macos) brew install "$package" ;;
		arch) sudo pacman -S --needed "$package" ;;
		ubuntu | debian) sudo apt install -y "$package" ;;
		fedora) sudo dnf install -y "$package" ;;
		rhel | centos)
			if command_exists dnf; then sudo dnf install -y "$package"
			else sudo yum install -y "$package"; fi ;;
		opensuse-*) sudo zypper install -y "$package" ;;
		alpine) sudo apk add "$package" ;;
		void) sudo xbps-install -y "$package" ;;
		gentoo) sudo emerge "$package" ;;
		*) echo "⚠️ Cannot install $display automatically on $system" && return 1 ;;
	esac
}

check_essential_tools() {
	local system="$1"
	echo "🔍 Checking essential tools..."

	if ! command_exists make; then
		case "$system" in
			macos) install_package_if_needed "make" "$system" ;;
			ubuntu | debian) install_package_if_needed "build-essential" "$system" "build tools" ;;
			*) install_package_if_needed "make" "$system" ;;
		esac
	else echo "✅ make is available"
	fi

	if ! command_exists gcc && ! command_exists clang; then
		case "$system" in
			macos) xcode-select --install 2>/dev/null || echo "⚠️ Xcode tools may already be installed" ;;
			*) install_package_if_needed "gcc" "$system" ;;
		esac
	else echo "✅ C compiler is available"
	fi
}

install_packages() {
	local system="$1"
	echo "🔍 Checking and installing dependencies for $system..."
	check_essential_tools "$system"

	case "$system" in
		macos)
			command_exists brew || {
				echo "❌ Install Homebrew first:"
				echo "   /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
				exit 1
			}
			install_package_if_needed "readline" "$system"
			;;

		arch | manjaro)
			check_package_installed "base-devel" "$system" || sudo pacman -Syu --needed base-devel
			install_package_if_needed "readline" "$system"
			;;

		ubuntu | debian | pop | mint | elementary)
			sudo apt update
			install_package_if_needed "build-essential" "$system"
			install_package_if_needed "libreadline-dev" "$system" "readline headers"
			;;

		fedora)
			install_package_if_needed "gcc" "$system"
			install_package_if_needed "make" "$system"
			install_package_if_needed "readline-devel" "$system" "readline headers"
			;;

		rhel | centos)
			rpm -q epel-release >/dev/null 2>&1 || {
				echo "📦 Installing EPEL..."
				command_exists dnf && sudo dnf install -y epel-release || sudo yum install -y epel-release
			}
			install_package_if_needed "gcc" "$system"
			install_package_if_needed "make" "$system"
			install_package_if_needed "readline-devel" "$system" "readline headers"
			;;

		opensuse-*)
			install_package_if_needed "gcc" "$system"
			install_package_if_needed "make" "$system"
			install_package_if_needed "readline-devel" "$system" "readline headers"
			;;

		alpine)
			sudo apk update
			install_package_if_needed "build-base" "$system" "build tools"
			install_package_if_needed "readline-dev" "$system" "readline headers"
			;;

		void)
			sudo xbps-install -Sy
			install_package_if_needed "base-devel" "$system" "build tools"
			install_package_if_needed "readline-devel" "$system" "readline headers"
			;;

		gentoo)
			install_package_if_needed "sys-devel/gcc" "$system" "GCC"
			install_package_if_needed "sys-libs/readline" "$system" "readline"
			;;

		nixos)
			echo "⚠️ NixOS detected. Use nix-shell or system config:"
			echo "   nix-shell -p gcc gnumake readline"
			exit 1
			;;

		*)
			echo "⚠️ Unknown system: $system"
			echo "Please install:"
			echo "  - gcc or clang"
			echo "  - make"
			echo "  - readline headers"
			;;
	esac
}

build_shell() {
	if ! [ -f "Makefile" ] && ! [ -f "makefile" ]; then
		echo "❌ No Makefile found"
		exit 1
	fi

	echo "🛠️  Building $SHELL_NAME..."
	make clean 2>/dev/null || true
	make

	if ! [ -f "$SHELL_NAME" ]; then
		echo "❌ Build failed"
		exit 1
	fi
	echo "✅ Build successful!"
}

install_binary() {
	[ -f "$SHELL_NAME" ] || {
		echo "❌ Binary not found"
		exit 1
	}

	echo "📦 Installing $SHELL_NAME to $INSTALL_DIR..."
	sudo mkdir -p "$INSTALL_DIR"
	sudo cp "$SHELL_NAME" "$INSTALL_DIR/"
	sudo chmod +x "$INSTALL_DIR/$SHELL_NAME"

	if command -v "$SHELL_NAME" >/dev/null; then
		echo "✅ $SHELL_NAME installed!"
		echo "   Run it: $SHELL_NAME"
		echo "   Version: $($SHELL_NAME --version 2>/dev/null || echo 'Unknown')"
	else
		echo "⚠️ Not found in PATH. Use: $INSTALL_DIR/$SHELL_NAME"
	fi
}

main() {
	echo "🐚 Vatsal's Shell Installer"
	echo "==========================="
	system=$(detect_system)
	echo "📦 Detected: $system"
	echo ""
	install_packages "$system"
	echo ""
	build_shell
	echo ""
	install_binary
	echo ""
	echo "🎉 Done!"
}

main "$@"
