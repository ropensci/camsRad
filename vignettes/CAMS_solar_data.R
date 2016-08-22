## ----echo=FALSE----------------------------------------------------------
knitr::opts_chunk$set(
  comment = "#>", 
  collapse = TRUE,
  warning = FALSE
)
if(Sys.getenv("CAMS_USERNAME")=="") {
  knitr::opts_chunk$set(eval = FALSE) # doesn't build vignette if CAMS_USERNAME is not set
}

