#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "../include/parser.h"

char **tokenize_input(char *input) {
	int bufsize = VSH_TOK_BUFSIZE;
	char **tokens = malloc(bufsize * sizeof(char *));
	if (!tokens) {
		perror("malloc error");
		return NULL;
	}
	char *token;
	int index = 0;

	token = strtok(input, VSH_TOK_DELIM);
	while (token != NULL) {
		tokens[index] = strdup(token);
		if (tokens[index] == NULL) {
			for (int i = 0; i < index; i++) free(tokens[i]);
			free(tokens);
			return NULL;
		}
		index++;
		if (index >= bufsize) {
			bufsize += VSH_TOK_BUFSIZE;
			tokens = realloc(tokens, sizeof(char *) * bufsize);
			if (!tokens) {
				perror("realloc error");
				return NULL;
			}
		}
		token = strtok(NULL, VSH_TOK_DELIM);
	}
	tokens[index] = NULL;
	return tokens;
}

