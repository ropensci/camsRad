context("cams_get_mcclear")

test_that("Calling CAMS radiation service works", {
  skip_on_cran()

  username=Sys.getenv("CAMS_USERNAME")
  if(username=="") skip(" CAMS_USERNAME need to be set")

  df <- cams_get_mcclear(username, 60, 15, "2016-06-01", "2016-06-10", time_step="PT01H")

  expect_is(df, "data.frame")
  expect_equal(nrow(df),240)
  expect_equal(ncol(df),6)
  expect_is(df[[1,1]], "POSIXct")
  for(i in 2:6) {expect_is(df[[1,i]], "numeric")}
  expect_true(all(names(df) %in% c("timestamp","TOA","Clear sky GHI",
                                   "Clear sky BHI","Clear sky DHI","Clear sky BNI")))
  expect_equal(as.integer(df[[2,1]]) - as.integer(df[[1,1]]), 3600)
})
