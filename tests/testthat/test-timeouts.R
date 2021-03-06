
context("timeouts")

## This is easy, we just set a short timeout and make
## sure that the supplied script takes longer.

test_that("script timeout", {
  s <- session$new(port = phantom$port)
  on.exit(s$delete(), add = TRUE)
  s$go(server$url("/check.html"))

  ## This effectively waits for 100ms
  script <-
    "f = arguments[0];
     setTimeout(function() { f(42); }, 100);"

  ## It runs fine if the timeout is large enough
  s$set_timeout(script = 200)
  expect_equal(
    s$execute_script_async(script),
    42
  )

  ## But fails if the timeout is small
  s$set_timeout(script = 50)
  expect_error(
    s$execute_script_async(script),
    "Timed out waiting for asyncrhonous script result"
  )
})

## A web page that loads slowly

test_that("page load timeout", {

  skip_on_cran()
  skip_if_offline()

  s <- session$new(port = phantom$port)
  on.exit(s$delete(), add = TRUE)

  ## Cannot connect if page load is low
  s$set_timeout(page_load = 100)
  expect_error(
    s$go("http://httpbin.org/delay/1"),
    "URL .http://httpbin.org/delay/1. didn't load. Error: .timeout."
  )
})

## A web page that puts a div in after a 100 ms delay.
## With the 0ms implicit wait, we miss it first. With
## 200 ms wait, we find it already.

test_that("implicit timeout", {
  s <- session$new(port = phantom$port)
  on.exit(s$delete(), add = TRUE)

  skip("FIXME: does not work, maybe phantom waits for the page to load")

  ## Element not there yet, error
  s$set_timeout(implicit = 0);
  s$go(server$url("/slow.html"))
  expect_error(
    s$find_element(css = "div.slow"),
    "Unable to find element with css selector"
  )

  ## There after some wait
  s$set_timeout(implicit = 200);
  expect_error(s$find_element(css = "div.slow"), NA)
})
