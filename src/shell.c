#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <stdbool.h>
#include <readline/readline.h>
#include <readline/history.h>
#include "../include/shell.h"
#include "../include/utils.h"
#include "../include/parser.h"
#include "../include/colors.h"

char **read_line() {
	char **command;
	char *input;
	char *username = vsh_get_username();
	char *home = vsh_get_homedir();
	char hostname[256];
	gethostname(hostname, sizeof(hostname));
	char *path = vsh_get_path(home);
	if (path == NULL) {
		perror("path");
        free(path);
		return NULL;
	}
	size_t shell_size = strlen(username) + strlen(hostname) + strlen(path) + 100;
	char *shell = (char *)malloc(shell_size);
	snprintf(shell, shell_size, BHGRN"%s"BHRED"@%s"reset":["CYN"%s"reset"]⊱ ", username, hostname, path);
	input = readline(shell);
	if (input == NULL) {
		printf("Exiting shell...\n");
		free(path);
		free(shell);
		free(input);
		exit(0);
	} else if (input && *input) {
        add_history(input);
        append_history(1, vsh_history_path());
    }
	command = tokenize_input(input);
	free(input);
	if (command[0] == NULL) {
		free(path);
		free(shell);
		free(command);
		return NULL;
	}
	free(path);
	free(shell);
	return command;
}

