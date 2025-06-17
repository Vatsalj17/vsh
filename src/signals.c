#include <setjmp.h>
#include <signal.h>
#include "../include/signals.h"

sigjmp_buf env;
volatile sig_atomic_t jump_active = 0;

void sig_handler(int signo) {
	if (!jump_active) return;
	siglongjmp(env, 42);
}
