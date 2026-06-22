/* Hand-maintained replacement for the cmake/autotools-generated config header.
 * Feature selection is keyed on compiler-predefined platform macros.
 * Regenerated/owned by the watcher package — not by upstream tooling. */
#ifndef LIBFSWATCH_CONFIG_H
#define LIBFSWATCH_CONFIG_H

/* C++17 guarantees these; used by libfswatch_map.hpp / libfswatch_set.hpp */
#define HAVE_UNORDERED_MAP 1
#define HAVE_UNORDERED_SET 1

#if defined(__APPLE__)
/* FSEvents + kqueue. The HAVE_MACOS_GE_* gates are *derived from the deployment
 * target* (a compile-time "probe" of MAC_OS_X_VERSION_MIN_REQUIRED) rather than
 * hard-set true: this stays correct for any floor R might use, costs nothing,
 * and needs no configure machinery. Compare against the named MAC_OS_X_VERSION_*
 * constants — their numeric encoding changed (1090 vs 101000) at 10.10. */
#  include <AvailabilityMacros.h>
#  define HAVE_FSEVENTS_FSEVENTSTREAMSETDISPATCHQUEUE 1
#  define HAVE_SYS_EVENT_H 1
#  define HAVE_STRUCT_STAT_ST_MTIMESPEC 1
#  if MAC_OS_X_VERSION_MIN_REQUIRED >= MAC_OS_X_VERSION_10_5
#    define HAVE_MACOS_GE_10_5 1
#  endif
#  if MAC_OS_X_VERSION_MIN_REQUIRED >= MAC_OS_X_VERSION_10_6
#    define HAVE_MACOS_GE_10_6 1
#  endif
#  if MAC_OS_X_VERSION_MIN_REQUIRED >= MAC_OS_X_VERSION_10_7
#    define HAVE_MACOS_GE_10_7 1
#  endif
#  if MAC_OS_X_VERSION_MIN_REQUIRED >= MAC_OS_X_VERSION_10_9
#    define HAVE_MACOS_GE_10_9 1
#  endif
#  if MAC_OS_X_VERSION_MIN_REQUIRED >= MAC_OS_X_VERSION_10_10
#    define HAVE_MACOS_GE_10_10 1
#  endif
#  if MAC_OS_X_VERSION_MIN_REQUIRED >= MAC_OS_X_VERSION_10_13
#    define HAVE_MACOS_GE_10_13 1
#  endif

#elif defined(_WIN32)
#  define HAVE_WINDOWS 1
#  define HAVE_STRUCT_STAT_ST_MTIME 1

#elif defined(__linux__)
#  define HAVE_SYS_INOTIFY_H 1
#  define HAVE_SYS_EPOLL_H 1
#  define HAVE_SYS_EVENTFD_H 1
#  define HAVE_INOTIFY_MONITOR 1
#  define HAVE_STRUCT_STAT_ST_MTIME 1
/* fanotify intentionally OFF: requires CAP_SYS_ADMIN/root and a large symbol surface. */

#elif defined(__FreeBSD__) || defined(__OpenBSD__) || defined(__NetBSD__) || defined(__DragonFly__)
#  define HAVE_SYS_EVENT_H 1
#  define HAVE_STRUCT_STAT_ST_MTIMESPEC 1

#elif defined(__sun)
#  define HAVE_PORT_H 1
#  define HAVE_STRUCT_STAT_ST_MTIME 1

#else
/* Generic POSIX fallback: stat()-based poll monitor only. */
#  define HAVE_STRUCT_STAT_ST_MTIME 1
#endif

#endif /* LIBFSWATCH_CONFIG_H */
