/*
 * Copyright (c) 2015 Enrico M. Crisostomo
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation; either version 3, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program.  If not, see <http://www.gnu.org/licenses/>.
 */
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
