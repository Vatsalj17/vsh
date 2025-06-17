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
└── vsh     
```

## Prerequisites

- GCC compiler
- GNU Readline library
- POSIX-compliant Unix system (Linux, macOS, etc.)

## Building

Clone the repository and build using make:

```bash
git clone https://github.com/Vatsalj17/vsh.git
cd vsh
make
```

This will create the `vsh` executable in the project directory.

## Usage

Run the shell:

```bash
./vsh
```

You'll see a colorized prompt in the format:
```
username@hostname:[current_directory]$ 
```

### Built-in Commands

- **`cd [directory]`**: Change directory
  
- **`help`**: Display available commands

- **`exit`**: Exit the shell

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

