#include <errno.h>
#include <pwd.h>
#include <readline/readline.h>
#include <setjmp.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/wait.h>
#include <unistd.h>
#include "colors.h"

#define VSH_TOK_BUFSIZE 64
#define VSH_TOK_DELIM " \t\r\n\a"
#define VSH_PATH_BUFSIZE 128

static sigjmp_buf env;
static volatile sig_atomic_t jump_active = 0;

char *get_username() {
	struct passwd *pwd;
	pwd = getpwuid(geteuid());
	return pwd->pw_name;
}

char *get_homedir() {
	struct passwd *pwd;
	pwd = getpwuid(geteuid());
	return pwd->pw_dir;
}

int vsh_cd(char **args) {
	if (args[1] == NULL || strcmp(args[1], "~") == 0) {
		chdir(get_homedir());  // fallback to home directory
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

void sig_handler(int signo) {
	if (!jump_active) return;
	siglongjmp(env, 42);
}

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

char *vsh_get_path(char *home) {
	size_t buf_size = VSH_PATH_BUFSIZE;
	char *path = NULL;
	int retry_count = 0;
	while (retry_count < 5) {
		path = (char *)malloc(buf_size * sizeof(char));
		if (!path) {
			perror("malloc error");
			return NULL;
		}
		if (getcwd(path, buf_size) != NULL) {
			if (strcmp(path, home) == 0) {
				snprintf(path, buf_size, "~");
			} else if (strstr(path, home) != NULL && buf_size > strlen(home)) {
				snprintf(path, buf_size, "~%s", path + strlen(home));
			}
			return path;
		}
		if (errno == ERANGE) {
			// Buffer too small, double size and retry
			free(path);
			path = NULL;
			buf_size += VSH_PATH_BUFSIZE;
			retry_count++;
		} else {
			perror("getcwd error");
			free(path);
			return NULL;
		}
	}
	// Exceeded max retries
	free(path);
	return NULL;
}

char **read_line() {
	char **command;
	char *input;
	char *username = get_username();
	char *home = get_homedir();
	char hostname[256];
	gethostname(hostname, sizeof(hostname));
	char *path = vsh_get_path(home);
	if (path == NULL) {
		perror("path");
		return NULL;
	}
	size_t shell_size = strlen(username) + strlen(hostname) + strlen(path) + 100;
	char *shell = (char *)malloc(shell_size);
	snprintf(shell, shell_size, BHGRN"%s"BHRED"@%s"reset":[""%s"reset"]$ ", username, hostname, path);
	input = readline(shell);
	if (input == NULL) {
		printf("Exiting shell...\n");
		free(path);
		free(shell);
		free(input);
		exit(0);
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

void execute_command(char **command) {
	int status;
	pid_t child_pid;
	for (int i = 0; i < vsh_num_builtins(); i++) {
		if (strcmp(command[0], builtin_str[i]) == 0) {
			builtin_func[i](command);
			return;
		}
	}
	child_pid = fork();
	if (child_pid == 0) {
		signal(SIGINT, SIG_DFL);
		if (execvp(command[0], command) < 0) perror("execvp");
		printf("Invalid Command\n");
		exit(EXIT_FAILURE);
	} else {
		waitpid(child_pid, &status, WUNTRACED);
	}
}

int main() {
	char **command;
	if (sigsetjmp(env, 1) == 42) {
		printf("\n");
	}
	struct sigaction s;
	s.sa_handler = sig_handler;
	sigemptyset(&s.sa_mask);
	s.sa_flags = SA_RESTART;
	sigaction(SIGINT, &s, NULL);
	jump_active = 1;
	while (1) {
		command = read_line();
		if (command == NULL) {
			continue;
		}
		execute_command(command);

		for (int i = 0; command[i] != NULL; i++) {
			free(command[i]);
		}
		free(command);
	}
	return 0;
}
