#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/wait.h>
#include <unistd.h>
#include "../include/executor.h"
#include "../include/builtins.h"

void execute_command(char **command) {
	int status;
	pid_t child_pid;
	for (int i = 0; i < vsh_num_builtins(); i++) {
		if (strcmp(command[0], builtin_str[i]) == 0) {
			builtin_func[i](command);
			return;
		}
	}
	child_pid = fork();
	if (child_pid == 0) {
		signal(SIGINT, SIG_DFL);
		if (execvp(command[0], command) < 0) perror("execvp");
		printf("Invalid Command\n");
		exit(EXIT_FAILURE);
	} else {
		waitpid(child_pid, &status, WUNTRACED);
	}
}

