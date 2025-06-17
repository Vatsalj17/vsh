#include <stdio.h>
#include <stdlib.h>
#include <pwd.h>
#include <readline/readline.h>
#include <readline/history.h>
#include <setjmp.h>
#include <signal.h>
#include <sys/wait.h>
#include <unistd.h>
#include "../include/executor.h"
#include "../include/shell.h"
#include "../include/signals.h"
#include "../include/utils.h"

int main() {
	char **command;
	if (sigsetjmp(env, 1) == 42) {
		printf("\n");
	}
	struct sigaction s;
	s.sa_handler = sig_handler;
	sigemptyset(&s.sa_mask);
	s.sa_flags = SA_RESTART;
	sigaction(SIGINT, &s, NULL);
	jump_active = 1;
    read_history(vsh_history_path());
	while (1) {
		command = read_line();
		if (command == NULL) {
			continue;
		}
		execute_command(command);

		for (int i = 0; command[i] != NULL; i++) {
			free(command[i]);
		}
		free(command);
	}
	return 0;
}
