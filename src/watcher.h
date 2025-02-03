#ifndef WATCHER_H
#define WATCHER_H

#include <stdarg.h>
#include <stdio.h>
#include <unistd.h>
#include <pthread.h>
#include <libfswatch/c/libfswatch.h>

#ifndef R_NO_REMAP
#define R_NO_REMAP
#endif
#ifndef STRICT_R_HEADERS
#define STRICT_R_HEADERS
#endif
#include <R.h>
#include <Rinternals.h>
#include <R_ext/Visibility.h>

#define WATCHER_BUFSIZE 4096

typedef struct watcher_cb_s {
  SEXP callback;
  char **paths;
  unsigned int event_num;
} watcher_cb;

extern void (*eln2)(void (*)(void *), void *, double, int);

SEXP watcher_create(SEXP, SEXP, SEXP);
SEXP watcher_start_monitor(SEXP);
SEXP watcher_stop_monitor(SEXP);

#endif /* WATCHER_H */
