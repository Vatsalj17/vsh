#include <fcntl.h>
#include <signal.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/wait.h>
#include <unistd.h>
#include "../include/builtins.h"
#include "../include/parser.h"
#include "../include/executor.h"

void handle_redirections(char *input_file, char *output_file, char *append_file) {
	if (output_file != NULL) {
		int file = open(output_file, O_WRONLY | O_CREAT | O_TRUNC, 0644);	// Last arg is for permission
		if (file == -1) return;
		dup2(file, STDOUT_FILENO);
		close(file);
	} else if (append_file != NULL) {
		int file = open(append_file, O_WRONLY | O_APPEND);
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
}

bool found_pipe(char **command) {
	for (int i = 0; command[i] != NULL; i++) {
		if (!strcmp(command[i], "|")) return true;
	}
	return false;
}

void exec_pipe(char ***new_cmds, int i, int n) {
	int fd[2];
	if (pipe(fd) == -1) {
		perror("pipe");
		exit(EXIT_FAILURE);
	}
	int pid = fork();
	if (pid < 0) {
		perror("fork");
		exit(EXIT_FAILURE);
	}
	if (pid == 0) {
		dup2(fd[1], STDOUT_FILENO);	 // redirect stdout to pipe
		close(fd[0]);
		close(fd[1]);
		execvp(new_cmds[i][0], new_cmds[i]);
		printf("Invalid Command\n");
		exit(EXIT_FAILURE);
	} else {
		dup2(fd[0], STDIN_FILENO);	// redirect stdin to pipe
		close(fd[0]);
		close(fd[1]);
		waitpid(pid, NULL, 0);	// wait for the child to prevent zombies
		if (i == n - 2) {
			execvp(new_cmds[i + 1][0], new_cmds[i + 1]);
			printf("Invalid Command\n");
			exit(EXIT_FAILURE);
		} else
			exec_pipe(new_cmds, i + 1, n);
	}
}

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
			int stdin_copy = dup(STDIN_FILENO);
			int stdout_copy = dup(STDOUT_FILENO);
			handle_redirections(input_file, output_file, append_file);
			builtin_func[i](command);
			dup2(stdin_copy, STDIN_FILENO);	 // restore
			dup2(stdout_copy, STDOUT_FILENO);
			close(stdin_copy);
			close(stdout_copy);
			return;
		}
	}
	child_pid = fork();
	if (child_pid == 0) {
		handle_redirections(input_file, output_file, append_file);
		signal(SIGINT, SIG_DFL);  // Do default behaviour of signal
		if (found_pipe(command)) {
            if (invalid_pipe_usage(command)) {
                fprintf(stderr, "vsh: Invalid pipe usage\n");
                exit(EXIT_FAILURE);
            }
			exec_pipe(parse_pipes(command), 0, pipe_counter(command) + 1);
		} else {
			if (execvp(command[0], command) < 0) perror("execvp");
			fprintf(stderr, "vsh: Invalid Command\n");
			exit(EXIT_FAILURE);
		}
	} else {
		waitpid(child_pid, &status, WUNTRACED);
	}
}
