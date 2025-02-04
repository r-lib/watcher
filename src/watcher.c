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

  watcher_cb *wcb = (watcher_cb *) data;
  SEXP call, paths;
  PROTECT(paths = Rf_allocVector(STRSXP, wcb->event_num));
  for (unsigned int i = 0; i < wcb->event_num; i++) {
    SET_STRING_ELT(paths, i, Rf_mkChar(wcb->paths[i]));
  }
  PROTECT(call = Rf_lang2(wcb->callback, paths));
  Rf_eval(call, R_GlobalEnv);
  UNPROTECT(2);
  for (unsigned int i = 0; i < wcb->event_num; i++) {
    R_Free(wcb->paths[i]);
  }
  R_Free(wcb->paths);
  R_Free(wcb);

}

static void process_events(fsw_cevent const *const events, const unsigned int event_num, void *data) {

  SEXP callback = (SEXP) data;

  if (callback != R_NilValue) {

    watcher_cb *wcb = R_Calloc(1, watcher_cb);
    wcb->callback = callback;
    wcb->event_num = event_num;
    wcb->paths = R_Calloc(event_num, char *);
    for (unsigned int i = 0; i < event_num; i++) {
      size_t slen = strlen(events[i].path);
      wcb->paths[i] = R_Calloc(slen + 1, char);
      memcpy(wcb->paths[i], events[i].path, slen);
    }
    eln2(exec_later, wcb, 0, 0);

  } else {

    for (unsigned int i = 0; i < event_num; i++) {
      Wprintf("%d: %s\n", i, events[i].path);
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

SEXP watcher_create(SEXP path, SEXP callback, SEXP latency) {

  const char *watch_path = Rf_translateChar(STRING_ELT(path, 0));
  const double lat = REAL(latency)[0];

  FSW_HANDLE handle = fsw_init_session(system_default_monitor_type);
  if (handle == NULL)
    watcher_error(handle, "Failed to allocate memory.");

  if (fsw_add_path(handle, watch_path) != FSW_OK)
    watcher_error(handle, "Watcher path invalid.");

  if (fsw_set_latency(handle, lat) != FSW_OK) {
    watcher_error(handle, "Watcher latency cannot be negative.");
  }

  fsw_set_callback(handle, process_events, callback);

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
