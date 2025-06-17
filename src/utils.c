#include <errno.h>
#include <pwd.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include "../include/utils.h"

char *vsh_get_username() {
	struct passwd *pwd;
	pwd = getpwuid(geteuid());
	return pwd->pw_name;
}

char *vsh_get_homedir() {
	struct passwd *pwd;
	pwd = getpwuid(geteuid());
	return pwd->pw_dir;
}

char *vsh_history_path() {
    char *home = vsh_get_homedir();
    size_t hist_size = strlen(home) + 14;
    char *hist_path = (char *)malloc(hist_size);
    snprintf(hist_path, hist_size, "%s/.vsh_history", home);
    return hist_path;
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

