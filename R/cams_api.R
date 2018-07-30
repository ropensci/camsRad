#' API client for
#' \href{http://www.soda-pro.com/web-services/radiation/cams-radiation-service}{CAMS
#' radiation service}
#'
#' @inheritParams cams_get_radiation
#' @param time_ref Time reference:'UT' for universal time, 'TST' for true solar
#'   time. Default 'UT'
#' @param service 'get_mcclear' for CAMS McClear data, 'get_cams_radiation' for
#'   CAMS radiation data. Default 'get_cams_radiation'
#' @param format 'application/csv', 'application/json', 'application/x-netcdf'
#'   or 'text/csv'. Default 'application/csv'
#' @param filename path to file on disk to write to. If empty, data is kept in
#'   memory. Default empty
#'
#' @return list(ok=TRUE/FALSE, response=response). If ok=TRUE, response is the
#'   response from httr::GET. If ok=FALSE, response holds exception text
#'
#' @examples \dontrun{
#' library(ncdf4)
#'
#' filename <- paste0(tempfile(), ".nc")
#'
#' # API call to CAMS
#' r <- cams_api(
#'   60, 15,                       # latitude=60, longitude=15
#'   "2016-06-01", "2016-06-10",   # for 2016-06-01 to 2016-06-10
#'   time_step="PT01H",            # hourly data
#'   service="get_cams_radiation", # CAMS radiation
#'   format="application/x-netcdf",# netCDF format
#'   filename=filename)            # file to save to
#'
#' # Access the on disk stored ncdf4 file
#' nc <- nc_open(filename)
#' # list names of available variables
#' names(nc$var)
#'
#' # create data.frame with timestamp and global horizontal irradiation
#' df <- data.frame(datetime=as.POSIXct(nc$dim$time$vals, "UTC",
#'                                      origin="1970-01-01"),
#'                  GHI = ncvar_get(nc, "GHI"))
#'
#' plot(df, type="l")
#'
#' nc_close(nc)
#' }
#'
#' @export

cams_api <- function(
  lat, lng, date_begin, date_end,
  alt=-999, time_step="PT01H", time_ref="UT", verbose=FALSE,
  service="get_cams_radiation", format='application/csv', filename="") {

  # Stop if username is not provided
  username <- cams_get_user()

  body <- paste0(
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>',
    '<wps:Execute service="WPS" version="1.0.0" ',
      'xmlns:ows="http://www.opengis.net/ows/1.1" ',
      'xmlns:xlink="http://www.w3.org/1999/xlink" ',
      'xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" ',
      'xsi:schemaLocation="http://www.opengis.net/wps/1.0.0 ../schemas/wps/1.0.0/wpsExecute_request.xsd" ',
      'xmlns:wps="http://www.opengis.net/wps/1.0.0">',
    '<ows:Identifier>', service, '</ows:Identifier>',
    '<wps:DataInputs>',
    '<wps:Input><ows:Identifier>latitude</ows:Identifier>',
    '<wps:Data><wps:LiteralData>',lat,'</wps:LiteralData></wps:Data></wps:Input>',
    '<wps:Input><ows:Identifier>longitude</ows:Identifier>',
    '<wps:Data><wps:LiteralData>',lng,'</wps:LiteralData></wps:Data></wps:Input>',
    '<wps:Input><ows:Identifier>altitude</ows:Identifier>',
    '<wps:Data><wps:LiteralData>',alt,'</wps:LiteralData></wps:Data></wps:Input>',
    '<wps:Input><ows:Identifier>date_begin</ows:Identifier>',
    '<wps:Data><wps:LiteralData>',date_begin,'</wps:LiteralData></wps:Data></wps:Input>',
    '<wps:Input><ows:Identifier>date_end</ows:Identifier>',
    '<wps:Data><wps:LiteralData>',date_end,'</wps:LiteralData></wps:Data></wps:Input>',
    '<wps:Input><ows:Identifier>time_ref</ows:Identifier>',
    '<wps:Data><wps:LiteralData>',time_ref,'</wps:LiteralData></wps:Data></wps:Input>',
    '<wps:Input><ows:Identifier>summarization</ows:Identifier>',
    '<wps:Data><wps:LiteralData>',time_step,'</wps:LiteralData></wps:Data></wps:Input>',
    '<wps:Input><ows:Identifier>verbose</ows:Identifier>',
    '<wps:Data><wps:LiteralData>',"false",'</wps:LiteralData></wps:Data></wps:Input>',
    '<wps:Input><ows:Identifier>username</ows:Identifier>',
    '<wps:Data><wps:LiteralData>',username,'</wps:LiteralData></wps:Data></wps:Input>',
    '</wps:DataInputs>',
    '<wps:ResponseForm>',
    '<wps:ResponseDocument storeExecuteResponse="false">',
    '<wps:Output mimeType="',format,'" asReference="true">',
    '<ows:Identifier>irradiation</ows:Identifier></wps:Output></wps:ResponseDocument>',
    '</wps:ResponseForm>',
    '</wps:Execute>')

  if(verbose) httr::set_config(httr::verbose())

  r <- httr::POST(
    "http://www.soda-is.com/service/wps",
    body=body,
    httr::content_type("text/xml; charset=utf.8"),
    encode= "multipart",
    httr::accept_xml())

  httr::reset_config()

  # stop if request not successful
  httr::stop_for_status(r, "request data from soda-pro.com")

  if (httr::http_type(r) != "application/xml") {
    stop("soda-pro.com did not return xml", call. = FALSE)
  }

  # parse content into xml
  parsed <- xml2::read_xml(
    httr::content(r, as="text", encoding="UTF-8"))

  if(verbose) print(parsed)

  # test if //wps:ProcessSucceeded //wps:Reference exists, else return ExceptionText if exist
  if(length(xml2::xml_find_all(parsed, "//wps:ProcessSucceeded"))==0 |
     length(xml2::xml_find_all(parsed, "//wps:Reference"))==0) {
    if(length(xml2::xml_find_all(parsed, "//ows:ExceptionText"))>0) {
      return(list(
        ok=FALSE,
        response=xml2::xml_text(xml2::xml_find_all(parsed, "//ows:ExceptionText"))))
    } else {
      return(list(ok=FALSE, response=r))
    }
  }

  # get url to the processed file on soda-pro server
  url <- xml2::xml_attr(xml2::xml_find_all(parsed, "//wps:Reference"), "href")

  # if filename=="" the data is saved in memory, oterwise data is writen to disk
  if(filename=="") {
    r <- httr::GET(url)
  } else {
    r <- httr::GET(url, httr::write_disk(filename, overwrite = TRUE))
  }

  return(list(ok=(r$status_code==200), response=r))
}

