#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include "../include/parser.h"
#include "../include/utils.h"

char **tokenize_input(char *input) {
	int bufsize = VSH_TOK_BUFSIZE;
	char **tokens = malloc(bufsize * sizeof(char *));
	if (!tokens) {
		perror("malloc error");
		return NULL;
	}
	int index = 0, pos = 0;
    while (input[pos] != '\0') {
        while (input[pos] == ' ') pos++; // ignore unnecessary blank spaces
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
        // handling home path
        if (token[0] == '~') {
            size_t newtoken_s = strlen(token) + strlen(vsh_get_homedir());
            char *newtoken = (char *)malloc(newtoken_s);
            if (token[1] == '\0') {
                strcpy(newtoken, vsh_get_homedir());
            } else {
                snprintf(newtoken, newtoken_s, "%s%s", vsh_get_homedir(), token + 1);
            }
            token = newtoken;
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

bool invalid_pipe_usage(char **cmd) {
    if (cmd[0] == NULL || strcmp(cmd[0], "|") == 0) return true;
    for (int i = 0; cmd[i] != NULL; i++) {
        if (strcmp(cmd[i], "|") == 0 && (cmd[i + 1] == NULL || strcmp(cmd[i + 1], "|") == 0)) {
            return true;
        }
    }
    return false;
}

int pipe_counter(char **cmd) {
	int c = 0;
	for (int i = 0; cmd[i] != NULL; i++) {
		if (strcmp(cmd[i], "|") == 0) c++;
	}
	return c;
}

char ***parse_pipes(char **cmd) {
	int count = pipe_counter(cmd);
	int n = count + 1;
	char ***new_cmds = malloc(n * sizeof(char **));
	for (int i = 0; i < n; i++) {
		new_cmds[i] = malloc(64 * sizeof(char *));
	}
	int index = 0, sub_i = 0;
	for (int i = 0; cmd[i] != NULL; i++) {
		if (strcmp(cmd[i], "|") == 0) {
			new_cmds[index][sub_i] = NULL;
			sub_i = 0;
			index++;
			continue;
		}
		new_cmds[index][sub_i++] = cmd[i];
	}
    new_cmds[index][sub_i] = NULL;
    return new_cmds;
}
