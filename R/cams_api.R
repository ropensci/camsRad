#' API client for
#' \href{http://www.soda-pro.com/web-services/radiation/cams-radiation-service}{CAMS
#' radiation service}
#'
#' @inheritParams cams_get_radiation
#' @param filename path to file on disk to write to. If empty, data is kept in
#'   memory.
#'
#' @return list(ok=TRUE/FALSE, response=response). If ok=TRUE, response is the
#'   response from httr::GET. If ok=FALSE, response holds exception text
#'
#' @examples \dontrun{
#' library(ncdf4)
#'
#' filename <- paste0(tempfile(), ".nc")
#'
#' r <- cams_api(username, 60, 15, "2016-06-01", "2016-06-10",
#'               format = "application/x-netcdf", filename=filename)
#'
#' # Access the on disk stored ncdf4 file
#' nc <- nc_open(r$respone$content)
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
#' @import dplyr
#' @export

cams_api <- function(
  lat, lng, date_begin, date_end,
  alt=-999, time_step="PT01H", time_ref="UT", verbose=FALSE,
  service="get_cams_radiation", format='application/csv', filename="") {

  # Stops if now username is provided
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

  r <- tryCatch(
    httr::POST("http://www.soda-is.com/service/wps",
               body=body,
               httr::content_type("text/xml; charset=utf.8"),
               encode= "multipart",
               httr::accept_xml())
    , error = function(e) {e})

  if(is.null(r$status_code)) {
    # should not happen
    stop(r)
  } else if(r$status_code !=200) {
    stop(httr::content(r))
  }

  parsed <- httr::content(r)

  if(verbose) print(parsed)

  # test if //wps:ProcessSucceeded //wps:Reference exists, else return ExceptionText if exist
  if(length(xml2::xml_find_all(parsed, "//wps:ProcessSucceeded"))==0 |
     length(xml2::xml_find_all(parsed, "//wps:Reference"))==0) {
    httr::reset_config()
    if(length(xml2::xml_find_all(parsed, "//ows:ExceptionText"))>0) {
      return(list(ok=FALSE,
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
  httr::reset_config()
  return(list(ok=(r$status_code==200), respone=r))
}

