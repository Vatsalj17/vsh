#ifndef UTILS_H
#define UTILS_H

#define VSH_PATH_BUFSIZE 128

char *vsh_get_username();
char *vsh_get_homedir();
char *vsh_get_path(char *home);

#endif
