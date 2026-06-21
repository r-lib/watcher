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
/**
 * @file
 * @brief Header of the `libfswatch` library containing logging functions..
 *
 * @copyright Copyright (c) 2014-2015 Enrico M. Crisostomo
 * @license GNU General Public License v. 3.0
 * @author Enrico M. Crisostomo
 * @version 1.8.0
 */

#ifndef LIBFSW_LOG_H
#  define LIBFSW_LOG_H

#include <stdio.h>

/**
 * Prints the specified message to standard output.
 */
void fsw_log(const char * msg);

/**
 * Prints the specified message to the specified file.
 */
void fsw_flog(FILE * f, const char * msg);

/**
 * Formats the specified message and prints it to standard output.  The message
 * string format conforms with printf.
 */
void fsw_logf(const char * format, ...);

/**
 * Formats the specified message and prints it to the specified file.  The
 * message string format conforms with printf.
 */
void fsw_flogf(FILE * f, const char * format, ...);

/**
 * Prints the specified message using perror.
 */
void fsw_log_perror(const char * msg);

/**
 * Prints the specified message using perror.  The message string format
 * conforms with printf.
 */
void fsw_logf_perror(const char * format, ...);

/**
 * @brief Log the specified message to the standard output prepended by the
 * source line number.
 */
#  define FSW_LOG(msg) ((void)0)

/**
 * @brief Log the specified message to the standard error prepended by the
 * source line number.
 */
#  define FSW_ELOG(msg) ((void)0)

/**
 * @brief Log the specified `printf()`-like message to the standard output
 * prepended by the source line number.
 */
#  define FSW_LOGF(msg, ...) ((void)0)

/**
 * @brief Log the specified `printf()`-like message to the standard error
 * prepended by the source line number.
 */
#  define FSW_ELOGF(msg, ...) ((void)0)

/**
 * @brief Log the specified `printf()`-like message to the specified file
 * descriptor prepended by the source line number.
 */
#  define FSW_FLOGF(f, msg, ...) ((void)0)

#endif  /* LIBFSW_LOG_H */
