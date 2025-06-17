#ifndef PARSER_H
#define PARSER_H

#define VSH_TOK_BUFSIZE 64
#define VSH_TOK_DELIM " \t\r\n\a"

char **tokenize_input(char *input);

#endif
