#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include "../include/utils.h"
#include "../include/builtins.h"


int vsh_cd(char **args) {
	if (args[1] == NULL || strcmp(args[1], "~") == 0) {
		chdir(vsh_get_homedir());
	} else if (chdir(args[1]) < 0) {
		perror("cd");
		return -1;
	}
	return 0;
}

int vsh_help(char **args) {
	printf("Available commands:\n- cd\n- help\n- exit\n");
	return 0;
}

int vsh_exit(char **args) { exit(0); }
char *builtin_str[] = {"cd", "help", "exit"};
int (*builtin_func[])(char **) = {vsh_cd, vsh_help, vsh_exit};

int vsh_num_builtins() { return sizeof(builtin_str) / sizeof(char *); }
