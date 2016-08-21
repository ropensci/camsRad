context("cams_get_radiation")

test_that("Calling CAMS radiation service works", {
  skip_on_cran()

  username=Sys.getenv("CAMS_USERNAME")

  if(username=="") skip("need CAMS_USERNAME to be set")

  df <- cams_get_radition(username, 60, 15, "2016-06-01", "2016-06-10")

  expect_is(df, "data.frame")
  expect_equal(nrow(df),240)
  expect_equal(ncol(df),11)
  expect_is(df[[1,1]], "POSIXct")
  for(i in 2:11) {expect_is(df[[1,i]], "numeric")}
  expect_true(all(names(df) %in% c("Observation period","TOA","Clear sky GHI",
                                   "Clear sky BHI","Clear sky DHI","Clear sky BNI",
                                   "GHI","BHI","DHI","BNI","Reliability")))
})
