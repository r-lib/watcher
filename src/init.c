#include "watcher.h"

void (*eln2)(void (*)(void *), void *, double, int);

static const R_CallMethodDef callMethods[] = {
  {"watcher_create", (DL_FUNC) &watcher_create, 3},
  {"watcher_start_monitor", (DL_FUNC) &watcher_start_monitor, 1},
  {"watcher_stop_monitor", (DL_FUNC) &watcher_stop_monitor, 1},
  {NULL, NULL, 0}
};

void attribute_visible R_init_watcher(DllInfo* dll) {
  if (fsw_init_library() != FSW_OK) return;
  eln2 = (void (*)(void (*)(void *), void *, double, int)) R_GetCCallable("later", "execLaterNative2");
  R_registerRoutines(dll, NULL, callMethods, NULL, NULL);
  R_useDynamicSymbols(dll, FALSE);
  R_forceSymbols(dll, TRUE);
}
