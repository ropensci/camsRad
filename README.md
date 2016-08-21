
<!-- README.md is generated from README.Rmd. Please edit that file -->
camsRad
=======

[![Travis-CI Build Status](https://travis-ci.org/lukas-rokka/camsRad.svg?branch=master)](https://travis-ci.org/lukas-rokka/camsRad)

`camsRad` is a R client for [CAMS radiation service](http://www.soda-pro.com/web-services/radiation/cams-radiation-service). CAMS radiation service provides time series of global, direct, and diffuse irradiations on horizontal surface, and direct irradiation on normal plane for the actual weather conditions as well as for clear-sky conditions. The geographical coverage is the field-of-view of the Meteosat satellite, roughly speaking Europe, Africa, Atlantic Ocean, Middle East (-66° to 66° in both latitudes and longitudes). The time coverage of data is from 2004-02-01 up to 2 days ago. Data are available with a time step ranging from 15 min to 1 month.

Quick start
-----------

### Install

Dev version from GitHub.

``` r
devtools::install_github("lukas-rokka/camsRad")
```

``` r
library("camsRad")
```

### Authentication

To access the CAMS radiation service you need to register at <http://www.soda-pro.com/web-services/radiation/cams-radiation-service>. The email you use at the registration step will be used for authentication.

### Example 1

Get CAMS solar data straight into a R data frame.

``` r
username <- "your@email.com" # An email registrated at soda-pro.com

df <- cams_get_radition(username, lat=60, lon=15, 
                        date_begin="2016-01-01", date_end="2016-01-15")
print(df)
```

### Example 2

Retrieve CAMS solar data in ncdf format. You need to have `ncdf4` installed

``` r
library(ncdf4)

filename <- paste0(tempfile(), ".nc")

r <- cams_api(username, 60, 15, "2016-06-01", "2016-06-10", 
              format = "application/x-netcdf", filename = filename)

# Access the on disk stored ncdf4 file 
nc <- nc_open(r$respone$content)

# list names of available variables
names(nc$var)

# create data.frame with datetime and global horizontal irradiation and plot it
df <- data.frame(datetime = as.POSIXct(nc$dim$time$vals, "UTC", origin="1970-01-01"),
                 GHI = ncvar_get(nc, "GHI"))

plot(df, type="l")
```
