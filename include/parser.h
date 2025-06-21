#ifndef PARSER_H
#define PARSER_H

#define VSH_TOK_BUFSIZE 64

char **tokenize_input(char *input);
bool invalid_pipe_usage(char **cmd);
int pipe_counter(char **cmd);
char ***parse_pipes(char **cmd);

#endif
