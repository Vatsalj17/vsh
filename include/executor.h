#ifndef EXECUTOR_H
#define EXECUTOR_H

void handle_redirections(char *input_file, char *output_file, char *append_file);
void execute_command(char **command);

#endif
