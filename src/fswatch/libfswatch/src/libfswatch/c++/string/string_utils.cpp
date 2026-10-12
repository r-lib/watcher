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
/* watcher: bodies removed as dead code. Logging is neutered, and the only
 * other callers (regex-error paths in monitor.cpp) are unreachable in watcher.
 * Also sidesteps a GCC 16 -Warray-bounds false positive.
 * See tools/patch_libfswatch.sh. */
#include "string_utils.hpp"
