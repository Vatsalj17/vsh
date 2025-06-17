#ifndef SIGNALS_H
#define SIGNALS_H

#include <setjmp.h>
#include <signal.h>

extern sigjmp_buf env;
extern volatile sig_atomic_t jump_active;

void sig_handler(int signo);

#endif
