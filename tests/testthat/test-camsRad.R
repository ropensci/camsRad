context("cams set/get user")

test_that("Setting/getting user authentication", {
  testthat::skip_on_travis() # Conflicts with Travis environment

  username_old=Sys.getenv("CAMS_USERNAME")
  if(username_old=="") {username <- "your@email.com"}

  expect_error(cams_set_user("not a valid email"))
  expect_silent(cams_set_user(username))
  expect_identical(camsRad:::cams_get_user(), username)

  Sys.setenv('CAMS_USERNAME'=username_old)
})


context("cams_api")

test_that("Calling CAMS radiation service API", {
  #skip_on_cran()

  username <- Sys.getenv("CAMS_USERNAME")
  if(username=="") skip("need CAMS_USERNAME to be set")

  r <- cams_api(60, 15, "2016-06-01", "2016-06-10",
                format = "application/csv")

  expect_is(r, "list")
  expect_equal(length(r),2)
  expect_equal(r$ok, TRUE)
  expect_equal(httr::has_content(r$response), TRUE)
  expect_equal(httr::http_type(r$response), "text/csv")
  expect_equal(r$response$status_code, 200)
  expect_gt(length(readLines((rawConnection(r$response$content)))), 250)
})

test_that("Calling cams_get_radiation()", {
  #skip_on_cran()

  username <- Sys.getenv("CAMS_USERNAME")
  if(username=="") skip(" CAMS_USERNAME need to be set")

  df <- cams_get_radiation(60, 15, "2016-06-01", "2016-06-10", time_step="PT01H")

  expect_is(df, "data.frame")
  expect_equal(nrow(df),240)
  expect_equal(ncol(df),11)
  expect_is(df[[1,1]], "POSIXct")
  for(i in 2:11) {expect_is(df[[1,i]], "numeric")}
  expect_true(all(names(df) %in% c("timestamp","TOA","Clear sky GHI",
                                   "Clear sky BHI","Clear sky DHI","Clear sky BNI",
                                   "GHI","BHI","DHI","BNI","Reliability")))
  expect_equal(as.integer(df[[2,1]]) - as.integer(df[[1,1]]), 3600)
})


test_that("Calling cams_get_mcclear()", {
  #skip_on_cran()

  username <- Sys.getenv("CAMS_USERNAME")
  if(username=="") skip("CAMS_USERNAME need to be set")

  df <- cams_get_mcclear(60, 15, "2016-06-01", "2016-06-10", time_step="PT01H")

  expect_is(df, "data.frame")
  expect_equal(nrow(df),240)
  expect_equal(ncol(df),6)
  expect_is(df[[1,1]], "POSIXct")
  for(i in 2:6) {expect_is(df[[1,i]], "numeric")}
  expect_true(all(names(df) %in% c("timestamp","TOA","Clear sky GHI",
                                   "Clear sky BHI","Clear sky DHI","Clear sky BNI")))
  expect_equal(as.integer(df[[2,1]]) - as.integer(df[[1,1]]), 3600)
})
