#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/wait.h>
#include <unistd.h>
#include <fcntl.h>
#include "../include/executor.h"
#include "../include/builtins.h"

void execute_command(char **command) {
	int status;
	pid_t child_pid;
    char *output_file = NULL, *append_file = NULL, *input_file = NULL;
    for (int i = 0; command[i] != NULL; i++) {
        if (strcmp(command[i], ">") == 0) {
            output_file = command[++i];
            command[i - 1] = NULL;
            break;
        } else if (strcmp(command[i], ">>") == 0) {
            append_file = command[++i];
            command[i - 1] = NULL;
            break;
        } else if (strcmp(command[i], "<") == 0) {
            input_file = command[++i];
            command[i - 1] = NULL;
            break;
        }
    }
	for (int i = 0; i < vsh_num_builtins(); i++) {
		if (strcmp(command[0], builtin_str[i]) == 0) {
			builtin_func[i](command);
			return;
		}
	}
	child_pid = fork();
	if (child_pid == 0) {
        if (output_file != NULL) {
            int file = open(output_file, O_WRONLY | O_CREAT | O_TRUNC, 0666); // Last arg is for permission
            if (file == -1) return;
            dup2(file, STDOUT_FILENO);
            close(file);
        } else if (append_file != NULL) {
            int file = open(append_file, O_WRONLY | O_APPEND, 0666);
            if (file == -1) {
                printf("%s: file doesn't exist\n", append_file);
                return;
            }
            dup2(file, STDOUT_FILENO);
            close(file);
        } else if (input_file != NULL) {
            int file = open(input_file, O_RDONLY);
            if (file == -1) {
                printf("%s: file doesn't exist\n", append_file);
                return;
            }
            dup2(file, STDIN_FILENO);
            close(file);
        }
		signal(SIGINT, SIG_DFL); // Do default behaviour of signal
		if (execvp(command[0], command) < 0) perror("execvp");
		printf("Invalid Command\n");
		exit(EXIT_FAILURE);
	} else {
		waitpid(child_pid, &status, WUNTRACED);
	}
}

