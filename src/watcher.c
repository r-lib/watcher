#include "watcher.h"

// utilities -------------------------------------------------------------------

static void Wprintf(const char *fmt, ...) {

  char buf[WATCHER_BUFSIZE];
  va_list arg_ptr;
  va_start(arg_ptr, fmt);
  int bytes = vsnprintf(buf, WATCHER_BUFSIZE, fmt, arg_ptr);
  va_end(arg_ptr);

  if (write(STDOUT_FILENO, buf, (size_t) bytes)) {};

}

static inline void watcher_error(FSW_HANDLE handle, const char *msg) {

  if (handle) fsw_destroy_session(handle);
  Rf_error("%s", msg);

}

// callbacks -------------------------------------------------------------------

static void exec_later(void *data) {
  SEXP call, fn = (SEXP) data;
  PROTECT(call = Rf_lcons(fn, R_NilValue));
  Rf_eval(call, R_GlobalEnv);
  UNPROTECT(1);
}

// non-allocating version of fsw_get_event_flag_name() handling main event flags
static void get_event_flag_name(char *buf, const int flag) {
  const char *name;
  switch(flag) {
  case 1 << 1: name = "Created"; break;
  case 1 << 2: name = "Updated"; break;
  case 1 << 3: name = "Removed"; break;
  case 1 << 4: name = "Renamed"; break;
  default: name = "Unknown"; break;
  }
  memcpy(buf, name, strlen(name));
}

static void process_events(fsw_cevent const *const events, const unsigned int event_num, void *data) {
  if (data != R_NilValue) {
    eln2(exec_later, data, 0, 0);
  } else {
    char strbuf[8]; // large enough for subset of events handled by get_event_flag_name()
    memset(strbuf, 0, sizeof(strbuf));
    for (unsigned int i = 0; i < event_num; i++) {
      for (unsigned int j = 0; j < events[i].flags_num; j++) {
        get_event_flag_name(strbuf, events[i].flags[j]);
        Wprintf("%s: %s\n", strbuf, events[i].path);
      }
    }
  }
}

static void* watcher_thread(void *args) {

  FSW_HANDLE handle = (FSW_HANDLE) args;
  fsw_start_monitor(handle);
  return NULL;

}

// watcher ---------------------------------------------------------------------

static void session_finalizer(SEXP xptr) {

  if (R_ExternalPtrAddr(xptr) == NULL) return;
  FSW_HANDLE handle = (FSW_HANDLE) R_ExternalPtrAddr(xptr);
  fsw_stop_monitor(handle);
  fsw_destroy_session(handle);

}

SEXP watcher_create(SEXP path, SEXP callback) {

  const char *watch_path = CHAR(STRING_ELT(path, 0));

  FSW_HANDLE handle = fsw_init_session(system_default_monitor_type);
  if (handle == NULL)
    watcher_error(handle, "Failed to initialize watch");

  if (fsw_add_path(handle, watch_path) != FSW_OK)
    watcher_error(handle, "Failed to add path to watch");

  if (fsw_set_callback(handle, process_events, callback) != FSW_OK)
    watcher_error(handle, "Failed to set watch callback");

  /* recursive is always set for consistency of behaviour, as Windows and MacOS
   * default monitors are always recursive, hence this applies only on Linux
   */
  fsw_set_recursive(handle, true);
  fsw_set_allow_overflow(handle, true);

  /* filter only for main event types: Created, Updated, Removed, Renamed
   * This is to prevent events being triggered too often as some platforms e.g.
   * Ubuntu generate events even when files are being read etc.
   */
  fsw_event_type_filter filter;
  for (int flag = Created; flag <= Renamed; flag = flag << 1) {
    filter.flag = flag;
    fsw_add_event_type_filter(handle, filter);
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
  pthread_attr_t attr;
  pthread_attr_init(&attr);
  pthread_attr_setdetachstate(&attr, PTHREAD_CREATE_DETACHED);
  const int ret = pthread_create(&thr, &attr, &watcher_thread, handle);
  pthread_attr_destroy(&attr);

  return Rf_ScalarLogical(ret == 0);

}

SEXP watcher_stop_monitor(SEXP session) {

  FSW_HANDLE handle = (FSW_HANDLE) R_ExternalPtrAddr(session);

  return Rf_ScalarLogical(fsw_stop_monitor(handle) == FSW_OK);

}
