#include "watcher.h"

static void Wprintf(const int err, const char *fmt, ...) {

  char buf[WATCHER_BUFSIZE];
  va_list arg_ptr;

  va_start(arg_ptr, fmt);
  int bytes = vsnprintf(buf, WATCHER_BUFSIZE, fmt, arg_ptr);
  va_end(arg_ptr);

  if (write(err ? STDERR_FILENO : STDOUT_FILENO, buf, (size_t) bytes)) {};

}

void session_finalizer(SEXP xptr) {
  if (R_ExternalPtrAddr(xptr) == NULL) return;
  FSW_HANDLE handle = (FSW_HANDLE) R_ExternalPtrAddr(xptr);
  fsw_stop_monitor(handle);
  fsw_destroy_session(handle);
}

void (*eln2)(void (*)(void *), void *, double, int) = NULL;

void load_later_safe(void *data) {
  (void) data;
  SEXP fn, call;
  fn = Rf_install("loadNamespace");
  PROTECT(call = Rf_lang2(fn, Rf_mkString("later")));
  Rf_eval(call, R_GlobalEnv);
  UNPROTECT(1);
}

void exec_later(void *data) {
  SEXP call, fn = (SEXP) data;
  PROTECT(call = Rf_lcons(fn, R_NilValue));
  Rf_eval(call, R_GlobalEnv);
  UNPROTECT(1);
}

void process_events(fsw_cevent const *const events, const unsigned int event_num, void *data) {
  if (data != R_NilValue && eln2 != NULL) {
    eln2(exec_later, data, 0, 0);
  } else {
    for (unsigned int i = 0; i < event_num; i++)
      for (unsigned int j = 0; j < events[i].flags_num; j++)
        Wprintf(0, "Event: %s\n Flag: %s\n", events[i].path, fsw_get_event_flag_name(events[i].flags[j]));
  }
}

void* watcher_thread(void *args) {

  pthread_detach(pthread_self());
  FSW_HANDLE handle = (FSW_HANDLE) args;
  fsw_start_monitor(handle);
  return (void *) NULL;

}

SEXP watcher_create(SEXP path, SEXP recursive, SEXP callback) {

  const char *watch_path = CHAR(STRING_ELT(path, 0));
  const int recurse = LOGICAL(recursive)[0];
  if (callback != R_NilValue) {
    SEXPTYPE typ = TYPEOF(callback);
    if (typ != CLOSXP && typ != BUILTINSXP && typ != SPECIALSXP)
      Rf_error("'callback' must be a function");
  }

  FSW_HANDLE handle = fsw_init_session(system_default_monitor_type);
  if (handle == NULL) {
    Rf_error("Failed to initialize watch");
  }
  if (fsw_add_path(handle, watch_path) != FSW_OK) {
    fsw_destroy_session(handle);
    Rf_error("Failed to add path to watch");
  }
  if (recurse && (fsw_set_recursive(handle, 1) != FSW_OK)) {
    fsw_destroy_session(handle);
    Rf_error("Failed to set recursive watch");
  }
  if (fsw_set_callback(handle, process_events, callback) != FSW_OK) {
    fsw_destroy_session(handle);
    Rf_error("Failed to set watch callback");
  }

  fsw_event_type_filter filter;
  for (int flag = Created; flag <= Renamed; flag = flag << 1) {
    filter.flag = flag;
    if (fsw_add_event_type_filter(handle, filter) != FSW_OK) {
      fsw_destroy_session(handle);
      Rf_error("Failed to apply watch filters");
    }
  }

  SEXP out;
  PROTECT(out = R_MakeExternalPtr(handle, R_NilValue, callback));
  R_RegisterCFinalizerEx(out, session_finalizer, TRUE);

  UNPROTECT(1);
  return out;

}

SEXP watcher_start_monitor(SEXP session) {

  FSW_HANDLE handle = (FSW_HANDLE) R_ExternalPtrAddr(session);
  pthread_t thr;

  if (eln2 == NULL && R_ToplevelExec(load_later_safe, NULL)) {
    eln2 = (void (*)(void (*)(void *), void *, double, int)) R_GetCCallable("later", "execLaterNative2");
  }

  return Rf_ScalarLogical(pthread_create(&thr, NULL, &watcher_thread, handle) == 0);

}

SEXP watcher_stop_monitor(SEXP session) {

  FSW_HANDLE handle = (FSW_HANDLE) R_ExternalPtrAddr(session);

  return Rf_ScalarLogical(fsw_stop_monitor(handle) == FSW_OK);

}
