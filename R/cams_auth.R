#' Set username used for authentication by CAMS radiation service
#'
#' @param username Email registered at soda-pro.com. Required
#' @examples \dontrun{
#' # cams_set_user("your@email.com") # An email registered at soda-pro.com
#' }
#'
#' @export
cams_set_user <- function(username) {
  if (!is.character(username) |
      identical(username, "") |
      !grepl("@", username)) {
    stop("Please, provide a valid email registered at CAMS radiation service",
         call. = FALSE)
  }
  Sys.setenv('CAMS_USERNAME'= username)
}

#' internal check if username is given
#'
#' @noRd
cams_get_user <- function() {
  username <- Sys.getenv('CAMS_USERNAME')
  if (identical(username, "")) {
    stop('Provide your email, registered at CAMS radiation service, with cams_set_user("your@email.com")',
         call. = FALSE)
  }
  return(username)
}
