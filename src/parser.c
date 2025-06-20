#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include "../include/parser.h"

char **tokenize_input(char *input) {
	int bufsize = VSH_TOK_BUFSIZE;
	char **tokens = malloc(bufsize * sizeof(char *));
	if (!tokens) {
		perror("malloc error");
		return NULL;
	}
	int index = 0, pos = 0;
    while (input[pos] != '\0') {
        while (input[pos] == ' ') pos++;
        if (input[pos] == '\0') break;

        char *token = malloc(bufsize);
        if (!token) {
            perror("malloc token");
            for (int j = 0; j < index; j++) free(tokens[j]);
            free(tokens);
            return NULL;
        }
        int i = 0, count = 0;
        bool check = false;
        while (check || (input[pos] != ' ' && input[pos] != '\0')) {
            // handling quotes
            if (input[pos] == '"') {
                check = !check;
                count++;
                pos++;
                if (count % 2 == 0) continue;
            }
            token[i++] = input[pos++];
        }
        token[i] = '\0';
        // handling env variable
        if (token[0] == '$') {
            char *env_var = getenv(token + 1);
            if (env_var != NULL) {
                free(token);
                token = strdup(env_var);
            }
        }
        tokens[index++] = token;
		if (index >= bufsize) {
			bufsize += VSH_TOK_BUFSIZE;
			char **tmp = realloc(tokens, sizeof(char *) * bufsize);
			if (!tmp) {
				perror("realloc error");
                for (int j = 0; j < index; j++) free(tokens[j]);
                free(tokens);
				return NULL;
			}
            tokens = tmp;
		}
    }
	tokens[index] = NULL;
	return tokens;
}

