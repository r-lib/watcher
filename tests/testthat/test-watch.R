dir <- file.path(tempdir(), "watcher-test")
dir2 <- file.path(tempdir(), "watcher-test2")
subdir <- file.path(dir, "文件subdir")
dir.create(dir)
dir.create(dir2)
dir.create(subdir)

test_that("watcher() logs", {
  w <- watcher(dir, callback = NULL)
  expect_s3_class(w, "Watcher")
  expect_false(w$is_running())
  expect_false(w$stop())
  expect_true(w$start())
  expect_true(w$is_running())
  expect_type(w$get_path(), "character")
  Sys.sleep(1)
  file.create(file.path(dir, "testfile"))
  file.remove(file.path(dir, "testfile"))
  Sys.sleep(1)
  expect_false(w$start())
  expect_true(w$stop())
  expect_false(w$stop())
  expect_false(w$is_running())
  rm(w)
})

test_that("watcher() callbacks", {
  skip_if(R.version$arch == "aarch64" && !Sys.getenv("NOT_CRAN") == "true")
  x <- 0L
  w <- watcher(
    c(dir, dir2),
    callback = ~ {
      is.character(.x) || stop()
      x <<- x + 1L
    },
    latency = 0.2
  )
  expect_output(print(w))
  expect_s3_class(w, "Watcher")
  expect_false(w$is_running())
  expect_true(w$start())
  expect_true(w$is_running())
  expect_type(w$get_path(), "character")
  expect_length(w$get_path(), 2L)
  Sys.sleep(1)
  file.create(file.path(subdir, "testfile"))
  later::run_now(1)
  expect_gte(x, 1L)
  x <- 0L
  file.remove(file.path(subdir, "testfile"))
  later::run_now(1)
  expect_gte(x, 1L)
  x <- 0L
  file.create(file.path(dir, "oldfile"))
  later::run_now(1)
  expect_gte(x, 1L)
  x <- 0L
  file.rename(file.path(dir, "oldfile"), file.path(dir, "みらいヘ"))
  later::run_now(1)
  expect_gte(x, 1L)
  x <- 0L
  file.create(file.path(dir2, "français"))
  later::run_now(1)
  expect_gte(x, 1L)
  x <- 0L
  file.remove(file.path(dir, "みらいヘ"))
  later::run_now(1)
  expect_gte(x, 1L)
  x <- 0L
  file.remove(file.path(dir2, "français"))
  later::run_now(1)
  expect_gte(x, 1L)
  x <- 0L
  expect_true(w$stop())
  expect_false(w$is_running())
  rm(w)
})

test_that("watcher() reports full path for one-sided move into watched dir", {
  skip_if(R.version$arch == "aarch64" && !Sys.getenv("NOT_CRAN") == "true")
  # Regression test for libfswatch issue #387: pre-1.22.0 the Linux inotify
  # monitor dropped the child filename from one-sided move events, reporting
  # only the watched directory path.
  staging <- file.path(tempdir(), "watcher-staging")
  dir.create(staging)
  src <- file.path(staging, "moved-in")
  dest <- file.path(dir, "moved-in")
  paths <- character()
  w <- watcher(
    dir,
    callback = ~ {
      paths <<- c(paths, .x)
    },
    latency = 0.2
  )
  expect_true(w$start())
  Sys.sleep(1)
  file.create(src)
  file.rename(src, dest)
  for (i in 1:20) {
    later::run_now(0.5)
    if (any(normalizePath(paths, mustWork = FALSE) == normalizePath(dest))) {
      break
    }
  }
  expect_true(any(
    normalizePath(paths, mustWork = FALSE) == normalizePath(dest)
  ))
  expect_true(w$stop())
  rm(w)
  unlink(staging, recursive = TRUE, force = TRUE)
})

unlink(dir, recursive = TRUE, force = TRUE)
unlink(dir2, recursive = TRUE, force = TRUE)

test_that("watcher() error handling", {
  expect_snapshot(watcher(latency = -1), error = TRUE)
})

Sys.sleep(1) # time for watch threads to terminate and release resources
