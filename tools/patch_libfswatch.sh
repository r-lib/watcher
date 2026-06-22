#!/bin/bash

# Apply watcher's local patches to the vendored libfswatch sources.
#
# Usage: ./tools/patch_libfswatch.sh [LIBFSWATCH_SRC_DIR]
#
#   LIBFSWATCH_SRC_DIR defaults to the package's vendored tree
#   (src/fswatch/libfswatch/src/libfswatch). update_libfswatch.sh passes the
#   staging tree instead.
#
# Every patch is IDEMPOTENT: running this on already-patched sources is a no-op.
# The patches are:
#   1. string_utils.cpp  - guard against a null format string (GCC
#      -Wformat-truncation in stricter CRAN/rhub builds).
#   2. Monitor self-guards - wrap fsevents/inotify/fanotify monitor bodies in
#      their platform #ifdef so they compile to empty objects on the wrong OS
#      (kqueue/fen/windows monitors already self-guard upstream).
#   3. Logging neutering - libfswatch's diagnostics must not write to
#      stdout/stderr from compiled code (R CMD check 'compiled code' policy).
#      watcher never enables libfswatch verbose logging, so this is a no-op in
#      normal use. Neutering removes the printf/stdout/stderr/cerr symbols that
#      would otherwise be flagged when libfswatch is compiled into watcher.so.

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
LIBFSW_SRC="${1:-$SCRIPT_DIR/../src/fswatch/libfswatch/src/libfswatch}"

if [ ! -d "$LIBFSW_SRC" ]; then
  echo "Error: libfswatch source dir not found: $LIBFSW_SRC" >&2
  exit 1
fi

# Wrap a monitor source body in #ifdef <macro> ... #endif so it compiles to an
# empty object on platforms that lack the feature. Idempotent and portable.
add_guard() {
  file=$1; macro=$2
  if grep -q "WATCHER guard $macro" "$file" 2>/dev/null; then
    echo -e "${GREEN}  ✓ self-guard $macro already present${NC}"; return 0
  fi
  awk -v m="$macro" '
    { print }
    $0 == "#include <libfswatch/libfswatch_config.h>" && !done {
      print ""
      print "#ifdef " m
      done = 1
    }
    END { print ""; print "#endif  /* WATCHER guard " m " */" }
  ' "$file" > "$file.tmp" && mv "$file.tmp" "$file"
  echo -e "${GREEN}  ✓ self-guard $macro applied${NC}"
}

# --- Patch 1: string_utils.cpp null-format guard -----------------------------
STRING_UTILS="$LIBFSW_SRC/c++/string/string_utils.cpp"
if [ -f "$STRING_UTILS" ]; then
  if grep -q "if (!format) return" "$STRING_UTILS"; then
    echo -e "${GREEN}  ✓ string_utils null-format guard already present${NC}"
  else
    sed -i.bak 's|^      size_t current_buffer_size = 0;$|      if (!format) return string();\
      size_t current_buffer_size = 0;|' "$STRING_UTILS"
    rm -f "$STRING_UTILS.bak"
    echo -e "${GREEN}  ✓ string_utils null-format guard applied${NC}"
  fi
else
  echo -e "${YELLOW}  ⚠ string_utils.cpp not found, skipping${NC}"
fi

# --- Patch 2: self-guard the three non-self-guarding monitors ----------------
add_guard "$LIBFSW_SRC/c++/fsevents_monitor.cpp" HAVE_FSEVENTS_FSEVENTSTREAMSETDISPATCHQUEUE
add_guard "$LIBFSW_SRC/c++/inotify_monitor.cpp"  HAVE_INOTIFY_MONITOR
add_guard "$LIBFSW_SRC/c++/fanotify_monitor.cpp" HAVE_FANOTIFY

# --- Patch 3a: neuter the FSW_*LOG* macros (they expand `stderr` inline) ------
LOG_H="$LIBFSW_SRC/c/libfswatch_log.h"
if grep -q 'fsw_flogf(stderr' "$LOG_H" 2>/dev/null; then
  perl -pi -e 's/^(#  define FSW_[A-Z]+\([^)]*\))\s+.*$/$1 ((void)0)/' "$LOG_H"
  echo -e "${GREEN}  ✓ FSW_*LOG* macros neutered${NC}"
else
  echo -e "${GREEN}  ✓ FSW_*LOG* macros already neutered${NC}"
fi

# --- Patch 3b: empty the fsw_log* function bodies ----------------------------
LOG_CPP="$LIBFSW_SRC/c/libfswatch_log.cpp"
if grep -q 'watcher: logging neutered' "$LOG_CPP" 2>/dev/null; then
  echo -e "${GREEN}  ✓ libfswatch_log.cpp already neutered${NC}"
else
  # Preserve the upstream licence header (everything before the first #include).
  HEADER=$(awk '/^#include/{exit} {print}' "$LOG_CPP")
  {
    printf '%s\n' "$HEADER"
    cat <<'EOF'
/* watcher: logging neutered. libfswatch's diagnostics must not write to
 * stdout/stderr from compiled code; watcher never enables verbose logging,
 * so these are no-ops in normal use. See tools/patch_libfswatch.sh. */
#include "libfswatch_log.h"

void fsw_log(const char *) {}
void fsw_flog(FILE *, const char *) {}
void fsw_logf(const char *, ...) {}
void fsw_flogf(FILE *, const char *, ...) {}
void fsw_log_perror(const char *) {}
void fsw_logf_perror(const char *, ...) {}
EOF
  } > "$LOG_CPP.tmp" && mv "$LOG_CPP.tmp" "$LOG_CPP"
  echo -e "${GREEN}  ✓ libfswatch_log.cpp bodies emptied${NC}"
fi

# --- Patch 3c: drop the lone std::cerr in fsevents_monitor.cpp ---------------
FSEVENTS="$LIBFSW_SRC/c++/fsevents_monitor.cpp"
if grep -q 'std::cerr << "Warning: Failed to convert CFStringRef' "$FSEVENTS" 2>/dev/null; then
  perl -ni -e 'print unless /std::cerr << "Warning: Failed to convert CFStringRef/' "$FSEVENTS"
  echo -e "${GREEN}  ✓ fsevents_monitor.cpp std::cerr removed${NC}"
else
  echo -e "${GREEN}  ✓ fsevents_monitor.cpp std::cerr already removed${NC}"
fi

# --- Patch 3d: drop the Windows-only stderr/cerr diagnostics -----------------
# These compile only on Windows (so they escape the POSIX checks); same policy
# as 3a-3c. perror() is left as-is throughout -- R's compiled-code check does
# not flag it. Each write is the lone statement in a braced block, so removing
# the line leaves valid code (an empty else / a bare return false).
WIN_DCE="$LIBFSW_SRC/c++/windows/win_directory_change_event.cpp"
if grep -q 'cerr << _("File name unexpectedly empty' "$WIN_DCE" 2>/dev/null; then
  perl -ni -e 'print unless /cerr << _\("File name unexpectedly empty/' "$WIN_DCE"
  echo -e "${GREEN}  ✓ win_directory_change_event.cpp cerr removed${NC}"
else
  echo -e "${GREEN}  ✓ win_directory_change_event.cpp cerr already removed${NC}"
fi

WIN_MON="$LIBFSW_SRC/c++/windows_monitor.cpp"
if grep -q 'fprintf(stderr, _("Invalid handle when opening' "$WIN_MON" 2>/dev/null; then
  perl -ni -e 'print unless /fprintf\(stderr, _\("Invalid handle when opening/' "$WIN_MON"
  echo -e "${GREEN}  ✓ windows_monitor.cpp fprintf(stderr) removed${NC}"
else
  echo -e "${GREEN}  ✓ windows_monitor.cpp fprintf(stderr) already removed${NC}"
fi
