# VSH - A Simple Unix Shell

VSH (V Shell) is a lightweight, custom Unix shell implementation written in C. It provides basic shell functionality with a clean, colorized interface and supports both built-in commands and external program execution.

## Features

- **Interactive Command Line**: Colorized prompt showing username, hostname, and current directory
- **Built-in Commands**: `cd`, `help`, and `exit` commands
- **External Program Execution**: Run any system command or program
- **Signal Handling**: Proper handling of SIGINT (Ctrl+C) to interrupt running processes
- **Home Directory Support**: Navigate using `~` shorthand for home directory
- **Memory Management**: Proper allocation and cleanup of dynamic memory

## Project Structure

```
vsh/
├── include/      
│   ├── builtins.h
│   ├── colors.h  
│   ├── executor.h
│   ├── parser.h  
│   ├── shell.h   
│   ├── signals.h 
│   └── utils.h   
├── src/          
│   ├── builtins.c
│   ├── executor.c
│   ├── main.c    
│   ├── parser.c  
│   ├── shell.c   
│   ├── signals.c 
│   └── utils.c   
├── obj/    
├── Makefile
├── install.sh        # Automated installation script
└── vsh     
```

## Installation

### Method 1: Automated Installation (Recommended)

Use the provided installation script that automatically detects your system and installs dependencies:

```bash
git clone https://github.com/Vatsalj17/vsh.git
cd vsh
chmod +x install.sh
./install.sh
```

The installation script supports multiple operating systems and distributions:
- **macOS**: Uses Homebrew for dependencies
- **Ubuntu/Debian**: Uses apt package manager
- **Arch Linux/Manjaro**: Uses pacman package manager
- **Fedora**: Uses dnf package manager
- **RHEL/CentOS**: Uses yum/dnf with EPEL repository
- **openSUSE**: Uses zypper package manager
- **Alpine Linux**: Uses apk package manager
- **Void Linux**: Uses xbps package manager
- **Gentoo**: Uses emerge package manager

#### Installation Script Options

```bash
./install.sh                # Full installation (dependencies + build + install)
./install.sh --deps-only    # Install dependencies only
./install.sh --build-only   # Build only (skip dependencies and installation)
./install.sh --help         # Show help information
```

### Method 2: Manual Installation

If you prefer manual installation or the automated script doesn't work for your system:

#### Prerequisites

- GCC compiler
- GNU Readline library
- POSIX-compliant Unix system (Linux, macOS, etc.)

#### Installing Dependencies Manually

**Ubuntu/Debian:**
```bash
sudo apt-get install gcc libreadline-dev
```

**CentOS/RHEL/Fedora:**
```bash
sudo yum install gcc readline-devel
# or for newer versions:
sudo dnf install gcc readline-devel
```

**macOS:**
```bash
# Install Xcode command line tools
xcode-select --install
# Readline is usually available by default
```

#### Building Manually

```bash
git clone https://github.com/Vatsalj17/vsh.git
cd vsh
make
```

This will create the `vsh` executable in the project directory.

## Usage

Run the shell:

```bash
./vsh        # If built locally
# or
vsh          # If installed system-wide
```

You'll see a colorized prompt in the format:
```
username@hostname:[current_directory]$ 
```

### Built-in Commands

- **`cd [directory]`**: Change directory
- **`help`**: Display available commands
- **`exit`**: Exit the shell
- **`history`**: Display history of commands

### External Commands

Any system command or program can be executed:
```bash
ls -la
grep "pattern" file.txt
gcc -o program program.c
python script.py
```

### Signal Handling

- **Ctrl+C (SIGINT)**: Interrupts the currently running command without exiting the shell
- **Ctrl+D (EOF)**: Exits the shell gracefully

## Code Organization

### Core Components

1. **Parser** (`parser.c`): Tokenizes user input into command arguments
2. **Executor** (`executor.c`): Handles command execution (built-ins vs external programs)
3. **Shell Interface** (`shell.c`): Manages the interactive prompt and user input
4. **Built-ins** (`builtins.c`): Implements built-in shell commands
5. **Utilities** (`utils.c`): Helper functions for user info and path management
6. **Signal Handling** (`signals.c`): Manages signal handling for process control

### Key Features Implementation

- **Process Management**: Uses `fork()` and `execvp()` for external command execution
- **Path Resolution**: Supports both absolute paths and home directory shortcuts
- **Memory Safety**: Proper allocation, deallocation, and error handling
- **Color Support**: ANSI color codes for enhanced visual experience

## Cleaning Up

Remove compiled files:

```bash
make clean
```

Uninstall VSH (if installed system-wide):

```bash
sudo rm /usr/local/bin/vsh
```

## Known Limitations

- No support for pipes (`|`) or redirections (`>`, `<`)
- No background process support (`&`)
- Limited tab completion (relies on readline's default behavior)
- No command history persistence between sessions

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

