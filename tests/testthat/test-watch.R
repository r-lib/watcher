dir <- file.path(tempdir(), "watcher-test")
subdir <- file.path(dir, "文件subdir")
dir.create(dir)
dir.create(subdir)

test_that("watcher() logs", {
  w <- watcher(dir, callback = NULL)
  expect_s3_class(w, "Watcher")
  expect_false(w$running)
  expect_false(w$stop())
  expect_true(w$start())
  expect_true(w$running)
  expect_type(w$path, "character")
  Sys.sleep(1)
  file.create(file.path(dir, "testfile"))
  file.remove(file.path(dir, "testfile"))
  Sys.sleep(1)
  expect_false(w$start())
  expect_true(w$stop())
  expect_false(w$stop())
  expect_false(w$running)
  rm(w)
})

test_that("watcher() callbacks", {
  x <- 0L
  w <- watcher(dir, callback = ~{is.character(.x) || stop(); x <<- x + 1L}, latency = 0.2)
  expect_output(print(w))
  expect_s3_class(w, "Watcher")
  expect_false(w$running)
  expect_true(w$start())
  expect_true(w$running)
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
  file.remove(file.path(dir, "みらいヘ"))
  later::run_now(1)
  expect_gte(x, 1L)
  expect_true(w$stop())
  expect_false(w$running)
  rm(w)
})

unlink(dir, recursive = TRUE, force = TRUE)

test_that("watcher() error handling", {
  expect_error(watcher(latency = -1), "Watcher latency cannot be negative.")
})

Sys.sleep(1) # time for watch threads to terminate and release resources
