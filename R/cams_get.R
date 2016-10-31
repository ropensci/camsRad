#' Retrieve CAMS solar radiation data
#'
#' @param lat The latitude
#' @param lng The longitude
#' @param date_begin Start date as 'yyyy-mm-dd' string
#' @param date_end End date as 'yyyy-mm-dd' string
#' @param alt The altitude in meters, use -999 to let CAMS decide
#' @param time_step 'PT01M' for minutes, 'PT15M' for 15 minutes, 'PT01H' for
#'   hourly, 'P01D' for daily, 'P01M' for monthly
#' @param time_ref 'UT' for universal time, 'TST' for true solar time
#' @param verbose TRUE for verbose output
#' @param service 'get_mcclear' for CAMS McClear data, get_cams_radiation for CAMS
#'   radiation data
#' @param format 'application/csv', 'application/json',
#'   'application/x-netcdf' or 'text/csv'
#'
#' @return A data frame with requested solar data
#'
#' @examples \dontrun{
#' df <- cams_get_radiation(
#'   lat=60, lng=15, date_begin="2016-01-01", date_end="2016-01-15")
#' print(head(df))
#' }
#'
#' @export
#'
cams_get_radiation <- function(
  lat, lng, date_begin, date_end,
  time_step="PT01H", alt=-999, verbose=FALSE) {

  r <- cams_api(lat, lng, date_begin, date_end,
                alt, time_step=time_step,
                verbose=verbose,
                service="get_cams_radiation",
                format="application/csv",
                filename = tempfile())
  if(r$ok==FALSE) stop(r$response, call. = FALSE)
  return(cams_parse(r$respone$content))
}

#' Retrieve McClear clear sky solar radiation data
#' @inheritParams cams_get_radiation
#'
#' @return A data frame with requested solar data
#'
#' @examples \dontrun{
#' df <- cams_get_mcclear(
#'   lat=60, lng=15, date_begin="2016-01-01", date_end="2016-01-15")
#' print(head(df))
#' }
#'
#' @export
#'
cams_get_mcclear <- function(
  lat, lng, date_begin, date_end,
  time_step="PT01H", alt=-999, verbose=FALSE) {

  r <- cams_api(lat, lng, date_begin, date_end,
                alt, time_step=time_step,
                verbose=verbose,
                service="get_mcclear",
                format="application/csv",
                filename = tempfile())
  if(r$ok==FALSE) stop(r$response, call. = FALSE)
  return(cams_parse(r$respone$content))
}


#' internal parser of csv data.
#' TODO: could break if the csv formating is changed,
#' use json or ncdf instead (more reliable but slower)?
#' @noRd
#'
cams_parse <- function(content) {
  # Last row with '#' holds column names, the data part starts after that
  j <- 0
  for(row_str in readLines(content, n=50)) {
    if(substr(row_str,1,1) != "#") break
    j <- j + 1
  }

  # output info part of the csv file
  message(writeLines(readLines(content, n=j)))

  # get column names, change first column name to 'timestamp'
  col_names <- unlist((readLines(content, n=j))[j] %>% strsplit(";"))
  col_names <- c("timestamp", col_names[2:(length(col_names))])

  # get data, parse first column as datetime, set column names
  df <- read.delim(content, header=FALSE, sep=";", skip=j) %>%
    mutate(V1=as.POSIXct(substr(V1,23,38), "UTC", "%Y-%m-%dT%H:%M")) %>%
    stats::setNames(col_names)

  return(df)
}
