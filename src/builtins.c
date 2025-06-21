#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <readline/history.h>
#include "../include/utils.h"
#include "../include/builtins.h"

int vsh_cd(char **args) {
	if (args[1] == NULL || strcmp(args[1], "~") == 0) {
		chdir(vsh_get_homedir());
	} else if (args[1][0] == '~') {
        size_t pathsize = strlen(args[1]) + strlen(vsh_get_homedir());
        char *path = (char *)malloc(pathsize);
        snprintf(path, pathsize, "%s%s", vsh_get_homedir(), args[1] + 1);
        if (chdir(path) < 0) {
            perror("cd ~");
            return -1;
        }
    } else if (chdir(args[1]) < 0) {
		perror("cd");
		return -1;
	}
	return 0;
}

int vsh_help(char **args) {
	printf("Available commands:\n- cd\n- help\n- exit\n- history\n");
	return 0;
}

int vsh_exit(char **args) { exit(0); }

int vsh_history(char **args) {
    HIST_ENTRY **the_list = history_list();
    if (the_list == NULL) {
        printf("No history.\n");
        return 0;
    }
    for (int i = 0; the_list[i] != NULL; i++) {
        printf("%d. %s\n", i + 1, the_list[i]->line);
    }
    return 0;
}

char *builtin_str[] = {"cd", "help", "exit", "history"};
int (*builtin_func[])(char **) = {vsh_cd, vsh_help, vsh_exit, vsh_history};

int vsh_num_builtins() { return sizeof(builtin_str) / sizeof(char *); }
