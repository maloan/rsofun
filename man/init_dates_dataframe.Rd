% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/run_pmodel_f_bysite.R
\name{init_dates_dataframe}
\alias{init_dates_dataframe}
\title{Initialises a tibble with dates}
\usage{
init_dates_dataframe(
  yrstart,
  yrend,
  startmoy = 1,
  startdoy = 1,
  freq = "days",
  endmoy = 12,
  enddom = 31,
  noleap = FALSE
)
}
\arguments{
\item{yrstart}{An integer defining the start year
of dates covered by the dataframe.}

\item{yrend}{An integer defining the end year of dates
covered by the dataframe.}

\item{startmoy}{An integer defining the start month-of-year of dates
covered by the dataframe. Defaults to 1.}

\item{startdoy}{An integer defining the start day-of-year of
dates covered by the dataframe. Defaults to 1.}

\item{freq}{A character string specifying the time steps of dates
(in rows). Defaults to \code{"days"}. Any of \code{"days", "months", "years"}. If
\code{freq = "months"} the 15\eqn{^{th}} day of the months is used as date,
and if \code{freq = "years"} the 1\eqn{^{st}} of January of each year is returned.}

\item{endmoy}{An integer defining the end month-of-year of dates covered
by the dataframe. Defaults to 12.}

\item{enddom}{An integer defining the end day-of-year of dates
covered by the dataframe. Defaults to 31.}

\item{noleap}{Whether leap years are ignored, that is, whether the 29\eqn{^{th}} 
of February is removed. Defaults to \code{FALSE}.}
}
\value{
A tibble with dates.
}
\description{
Creates a tibble with rows for each date from \code{'yrstart'} to \code{'yrend'}
in \code{'yyyy-mm-dd'} format. Intervals of dates are specified by argument 
\code{'freq'}. 
 ddf <- init_dates_dataframe(2000, 2003, startmoy=1, startdoy=1,
                             freq="days", endmoy=12, enddom=31, noleap=FALSE)
}
