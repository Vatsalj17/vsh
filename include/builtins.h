#ifndef BUILTINS_H
#define BUILTINS_H

extern char *builtin_str[];
extern int (*builtin_func[])(char **);

int vsh_cd(char **args);
int vsh_help(char **args);
int vsh_exit(char **args);
int vsh_num_builtins();

#endif
