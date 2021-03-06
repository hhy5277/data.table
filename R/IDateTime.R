
###################################################################
# IDate -- a simple wrapper class around Date using integer storage
###################################################################

as.IDate <- function(x, ...) UseMethod("as.IDate")

as.IDate.default <- function(x, ..., tz = attr(x, "tzone")) {
  if (is.null(tz)) tz = "UTC"
  as.IDate(as.Date(x, tz = tz, ...))
}

as.IDate.numeric <- function(x, origin = "1970-01-01", ...) {
  if (origin=="1970-01-01") {
    # standard epoch
    setattr(as.integer(x), "class", c("IDate", "Date"))
  } else {
    # only call expensive as.IDate.character if we have to
    as.IDate(origin, ...) + as.integer(x)
  }
}

as.IDate.Date <- function(x, ...) {
  setattr(as.integer(x), "class", c("IDate", "Date"))
}

as.IDate.POSIXct <- function(x, tz = attr(x, "tzone"), ...) {
  if (is.null(tz)) tz = "UTC"
  if (tz %chin% c("UTC", "GMT")) {
    setattr(as.integer(x) %/% 86400L, "class",  c("IDate", "Date"))
  } else
    as.IDate(as.Date(x, tz = tz, ...))
}

as.IDate.IDate <- function(x, ...) x

as.Date.IDate <- function(x, ...) {
  setattr(as.numeric(x), "class", "Date")
}

mean.IDate <-
cut.IDate <-
seq.IDate <-
c.IDate <-
rep.IDate <-
split.IDate <-
unique.IDate <-
  function(x, ...) {
    as.IDate(NextMethod())
  }

# fix for #1315
as.list.IDate <- function(x, ...) NextMethod()

# rounding -- good for graphing / subsetting
## round.IDate <- function (x, digits, units=digits, ...) {
##     if (missing(digits)) digits <- units # workaround to provide a units argument to match the round generic and round.POSIXt
##     units <- match.arg(digits, c("weeks", "months", "quarters", "years"))
round.IDate <- function (x, digits=c("weeks", "months", "quarters", "years"), ...) {
  units <- match.arg(digits)
  as.IDate(switch(units,
          weeks  = round(x, "year") + 7L * (yday(x) %/% 7L),
          months = ISOdate(year(x), month(x), 1L),
          quarters = ISOdate(year(x), 3L * (quarter(x)-1L) + 1L, 1L),
          years = ISOdate(year(x), 1L, 1L)))
}

#Adapted from `+.Date`
`+.IDate` <- function (e1, e2) {
  if (nargs() == 1L)
    return(e1)
  if (inherits(e1, "difftime") || inherits(e2, "difftime"))
    stop("difftime objects may not be added to IDate. Use plain integer instead of difftime.")
  if (isReallyReal(e1) || isReallyReal(e2)) {
    return(`+.Date`(e1, e2))
    # IDate doesn't support fractional days; revert to base Date
  }
  if (inherits(e1, "Date") && inherits(e2, "Date"))
    stop("binary + is not defined for \"IDate\" objects")
  setattr(as.integer(unclass(e1) + unclass(e2)), "class", c("IDate", "Date"))
}

`-.IDate` <- function (e1, e2) {
  if (!inherits(e1, "IDate"))
    stop("can only subtract from \"IDate\" objects")
  if (storage.mode(e1) != "integer")
    stop("Internal error: storage mode of IDate is somehow no longer integer") # nocov
  if (nargs() == 1L)
    stop("unary - is not defined for \"IDate\" objects")
  if (inherits(e2, "difftime"))
    stop("difftime objects may not be subtracted from IDate. Use plain integer instead of difftime.")

  if ( isReallyReal(e2) ) {
    # IDate deliberately doesn't support fractional days so revert to base Date
    return(base::`-.Date`(as.Date(e1), e2))
    # can't call base::.Date directly (last line of base::`-.Date`) as tried in PR#3168 because
    # i) ?.Date states "Internal objects in the base package most of which are only user-visible because of the special nature of the base namespace."
    # ii) .Date was newly exposed in R some time after 3.4.4
  }
  ans = as.integer(unclass(e1) - unclass(e2))
  if (!inherits(e2, "Date")) setattr(ans, "class", c("IDate", "Date"))
  return(ans)
}



###################################################################
# ITime -- Integer time-of-day class
#          Stored as seconds in the day
###################################################################

as.ITime <- function(x, ...) UseMethod("as.ITime")

as.ITime.default <- function(x, ...) {
  as.ITime(as.POSIXlt(x, ...), ...)
}

as.ITime.POSIXct <- function(x, tz = attr(x, "tzone"), ...) {
  if (is.null(tz)) tz = "UTC"
  if (tz %chin% c("UTC", "GMT")) as.ITime(unclass(x), ...)
  else as.ITime(as.POSIXlt(x, tz = tz, ...), ...)
}

as.ITime.numeric <- function(x, ms = 'truncate', ...) {
  secs = switch(ms,
                'truncate' = as.integer(x),
                'nearest' = as.integer(round(x)),
                'ceil' = as.integer(ceiling(x)),
                stop("Valid options for ms are 'truncate', ",
                     "'nearest', and 'ceil'.")) %% 86400L
  setattr(secs, "class", "ITime")
}

as.ITime.character <- function(x, format, ...) {
  x <- unclass(x)
  if (!missing(format)) return(as.ITime(strptime(x, format = format, ...), ...))
  # else allow for mixed formats, such as test 1189 where seconds are caught despite varying format
  y <- strptime(x, format = "%H:%M:%OS", ...)
  w <- which(is.na(y))
  formats = c("%H:%M",
        "%Y-%m-%d %H:%M:%OS",
        "%Y/%m/%d %H:%M:%OS",
        "%Y-%m-%d %H:%M",
        "%Y/%m/%d %H:%M",
        "%Y-%m-%d",
        "%Y/%m/%d")
  for (f in formats) {
    if (!length(w)) break
    new <- strptime(x[w], format = f, ...)
    nna <- !is.na(new)
    if (any(nna)) {
      y[ w[nna] ] <- new[nna]
      w <- w[!nna]
    }
  }
  return(as.ITime(y, ...))
}

as.ITime.POSIXlt <- function(x, ms = 'truncate', ...) {
  secs = switch(ms,
                'truncate' = as.integer(x$sec),
                'nearest' = as.integer(round(x$sec)),
                'ceil' = as.integer(ceiling(x$sec)),
                stop("Valid options for ms are 'truncate', ",
                     "'nearest', and 'ceil'."))
  setattr(with(x, secs + min * 60L + hour * 3600L), "class", "ITime")
}

as.ITime.times <- function(x, ms = 'truncate', ...) {
  secs <- 86400 * (unclass(x) %% 1)
  secs = switch(ms,
                'truncate' = as.integer(secs),
                'nearest' = as.integer(round(secs)),
                'ceil' = as.integer(ceiling(secs)),
                stop("Valid options for ms are 'truncate', ",
                     "'nearest', and 'ceil'."))
  setattr(secs, "class", "ITime")
}

as.character.ITime <- format.ITime <- function(x, ...) {
  # adapted from chron's format.times
  # Fix for #811. Thanks to @StefanFritsch for the code snippet
  neg <- x < 0L
  x  <- abs(unclass(x))
  hh <- x %/% 3600L
  mm <- (x - hh * 3600L) %/% 60L
  # #2171 -- trunc gives numeric but %02d requires integer;
  #   as.integer is also faster (but doesn't handle integer overflow)
  #   http://stackoverflow.com/questions/43894077
  ss <- as.integer(x - hh * 3600L - 60L * mm)
  res = sprintf('%02d:%02d:%02d', hh, mm, ss)
  # Fix for #1354, so that "NA" input is handled correctly.
  if (is.na(any(neg))) res[is.na(x)] = NA
  neg = which(neg)
  if (length(neg)) res[neg] = paste0("-", res[neg])
  res
}

as.data.frame.ITime <- function(x, ...) {
  # This method is just for ggplot2, #1713
  # Avoids the error "cannot coerce class '"ITime"' into a data.frame", but for some reason
  # ggplot2 doesn't seem to call the print method to get axis labels, so still prints integers.
  # Tried converting to POSIXct but that gives the error below.
  # If user converts to POSIXct themselves, then it works for some reason.
  ans = list(x)
  # ans = list(as.POSIXct(x,tzone=""))  # ggplot2 gives "Error: Discrete value supplied to continuous scale"
  setattr(ans, "class", "data.frame")
  setattr(ans, "row.names", .set_row_names(length(x)))
  setattr(ans, "names", "V1")
  ans
}

print.ITime <- function(x, ...) {
  print(format(x))
}

rep.ITime <- function (x, ...)
{
  y <- rep(unclass(x), ...)
  setattr(y, "class", "ITime")
}

"[.ITime" <- function(x, ..., drop = TRUE)
{
  cl <- oldClass(x)
  class(x) <- NULL
  val <- NextMethod("[")
  setattr(val, "class", cl)
}

unique.ITime <- function(x, ...) {
  ans = NextMethod()
  setattr(ans, "class", "ITime")
}

# create a data.table with IDate and ITime columns
#   should work for most date/time formats like POSIXct

IDateTime <- function(x, ...) UseMethod("IDateTime")
IDateTime.default <- function(x, ...) {
  data.table(idate = as.IDate(x), itime = as.ITime(x))
}

# POSIXt support

as.POSIXct.IDate <- function(x, tz = "UTC", time = 0, ...) {
  if (missing(time) && inherits(tz, "ITime")) {
    time <- tz # allows you to use time as the 2nd argument
    tz <- "UTC"
  }
  if (tz == "") tz <- "UTC"
  as.POSIXct(as.POSIXlt(x, ...), tz, ...) + time
}

as.POSIXct.ITime <- function(x, tz = "UTC", date = Sys.Date(), ...) {
  if (missing(date) && inherits(tz, c("Date", "IDate", "POSIXt", "dates"))) {
    date <- tz # allows you to use date as the 2nd argument
    tz <- "UTC"
  }
  as.POSIXct(as.POSIXlt(date), tz = tz) + x
}

as.POSIXlt.ITime <- function(x, ...) {
  as.POSIXlt(as.POSIXct(x, ...))
}

###################################################################
# Date - time extraction functions
#   Adapted from Hadley Wickham's routines cited below to ensure
#   integer results.
#     http://gist.github.com/10238
#   See also Hadley's more advanced and complex lubridate package:
#     http://github.com/hadley/lubridate
#   lubridate routines do not return integer values.
###################################################################

second  <- function(x) {
  if (inherits(x,'POSIXct') && identical(attr(x,'tzone'),'UTC')) {
    # if we know the object is in UTC, can calculate the hour much faster
    as.integer(x) %% 60L
  } else {
    as.integer(as.POSIXlt(x)$sec)
  }
}
minute  <- function(x) {
  if (inherits(x,'POSIXct') && identical(attr(x,'tzone'),'UTC')) {
    # ever-so-slightly faster than x %% 3600L %/% 60L
    as.integer(x) %/% 60L %% 60L
  } else {
    as.POSIXlt(x)$min
  }
}
hour <- function(x) {
  if (inherits(x,'POSIXct') && identical(attr(x,'tzone'),'UTC')) {
    # ever-so-slightly faster than x %% 86400L %/% 3600L
    as.integer(x) %/% 3600L %% 24L
  } else {
    as.POSIXlt(x)$hour
  }
}
yday    <- function(x) as.POSIXlt(x)$yday + 1L
wday    <- function(x) (unclass(as.IDate(x)) + 4L) %% 7L + 1L
mday    <- function(x) as.POSIXlt(x)$mday
week    <- function(x) yday(x) %/% 7L + 1L
isoweek <- function(x) {
  # ISO 8601-conformant week, as described at
  #   https://en.wikipedia.org/wiki/ISO_week_date
  # Approach:
  # * Find nearest Thursday to each element of x
  # * Find the number of weeks having passed between
  #   January 1st of the year of the nearest Thursdays and x

  x = as.IDate(x)   # number of days since 1 Jan 1970 (a Thurs)
  nearest_thurs = as.IDate(7L * (as.integer(x + 3L) %/% 7L))
  year_start <- as.IDate(format(nearest_thurs, '%Y-01-01'))
  1L + (nearest_thurs - year_start) %/% 7L
}

month   <- function(x) as.POSIXlt(x)$mon + 1L
quarter <- function(x) as.POSIXlt(x)$mon %/% 3L + 1L
year    <- function(x) as.POSIXlt(x)$year + 1900L

