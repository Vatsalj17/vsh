# VSH - A Simple Unix Shell

VSH (V Shell) is a lightweight, custom Unix shell implementation written in C. It provides basic shell functionality with a clean, colorized interface and supports both built-in commands and external program execution.

## Features

- **Interactive Command Line**: Colorized prompt showing username, hostname, and current directory
- **Built-in Commands**: `cd`, `help`, `exit`, and `history` commands with full functionality
- **External Program Execution**: Run any system command or program with argument support
- **I/O Redirection**: Full support for input (`<`), output (`>`), and append (`>>`) redirection
- **Pipe Support**: Chain commands together using pipes (`|`) for powerful command composition
- **Environment Variables**: Access and use environment variables (e.g., `$HOME`, `$PATH`, `$USER`)
- **Command History**: Persistent command history stored in `~/.vsh_history` with readline integration
- **Signal Handling**: Proper handling of SIGINT (Ctrl+C) to interrupt running processes
- **Home Directory Support**: Navigate using `~` shorthand for home directory expansion
- **Memory Management**: Robust allocation and cleanup of dynamic memory with error handling

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
└── vsh     
```

## Installation

### Prerequisites

- GCC compiler
- GNU Readline library
- POSIX-compliant Unix system (Linux, macOS, etc.)

### Installing Dependencies

**Ubuntu/Debian:**
```bash
sudo apt-get install gcc libreadline-dev
```

**CentOS/RHEL:**
```bash
sudo yum install gcc readline-devel
```

**Fedora:**
```bash
sudo dnf install gcc readline-devel
```

**macOS:**
```bash
# Install Xcode command line tools
xcode-select --install
# Install Homebrew if not already installed
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
# Install readline
brew install readline
```

**Arch Linux:**
```bash
sudo pacman -S gcc readline
```

### Building and Installing

```bash
git clone https://github.com/Vatsalj17/vsh.git
cd vsh
make
sudo make install
```

This will:
1. Build the `vsh` executable
2. Install it to `/usr/local/bin/vsh` (accessible system-wide)

## Usage

Run the shell:

```bash
./vsh        # If built locally
# or
vsh          # If installed system-wide
```

You'll see a colorized prompt in the format:
```
username@hostname:[current_directory]⊱
```

### Built-in Commands

- **`cd [directory]`**: Change directory (supports `~` for home directory)
- **`help`**: Display available commands and shell features
- **`exit`**: Exit the shell gracefully
- **`history`**: Display command history (stored in `~/.vsh_history`)

### External Commands and Advanced Features

Any system command or program can be executed with full support for advanced shell features:

**Basic Commands:**
```bash
ls -la
grep "pattern" file.txt
gcc -o program program.c
python script.py
```

**I/O Redirection:**
```bash
ls > file_list.txt          # Redirect output to file
cat < input.txt             # Redirect input from file
echo "text" >> log.txt      # Append output to file
```

**Pipes:**
```bash
ls -la | grep ".txt"        # List files and filter for .txt files
cat file.txt | sort | uniq  # Sort and remove duplicates
ps aux | grep "vsh"         # Find vsh processes
```

**Environment Variables:**
```bash
echo $HOME                  # Display home directory
echo $PATH                  # Display PATH variable
ls $HOME/Documents          # Use variables in commands
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

To remove VSH from your system:

```bash
sudo make uninstall
```

To clean build artifacts:
```bash
make clean
```

## Known Limitations

- No background process support (`&`)
- No command substitution (`` `command` `` or `$(command)`)
- No shell scripting support (if/while/for loops)
- Limited tab completion (relies on readline's default behavior)

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request
