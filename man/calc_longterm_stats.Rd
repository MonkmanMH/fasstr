% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/calc_longterm_stats.R
\name{calc_longterm_stats}
\alias{calc_longterm_stats}
\title{Calculate the long-term and long-term monthly summary statistics}
\usage{
calc_longterm_stats(data = NULL, dates = Date, values = Value,
  groups = STATION_NUMBER, station_number = NULL, percentiles = c(10,
  90), roll_days = 1, roll_align = "right", water_year = FALSE,
  water_year_start = 10, start_year = 0, end_year = 9999,
  exclude_years = NULL, months = 1:12, complete_years = FALSE,
  include_longterm = TRUE, custom_months = NULL,
  custom_months_label = "Custom-Months", transpose = FALSE,
  ignore_missing = FALSE)
}
\arguments{
\item{data}{A data frame of daily data that contains columns of dates, flow values, and (optional) groups (e.g. station numbers).
Leave blank if using \code{station_number} argument.}

\item{dates}{Column in \code{data} that contains dates formatted YYYY-MM-DD. Only required if dates column name is not '
Date' (default). Leave blank if using \code{station_number} argument.}

\item{values}{Column in \code{data} that contains numeric flow values, in units of cubic metres per second.
Only required if values column name is not 'Value' (default). Leave blank if using \code{station_number} argument.}

\item{groups}{Column in \code{data} that contains unique identifiers for different data sets, if applicable. Only required if
groups column name is not 'STATION_NUMBER'. Function will automatically group by a column named 'STATION_NUMBER' if present.
Remove the 'STATION_NUMBER' column beforehand to remove this grouping. Leave blank if using \code{station_number} argument.}

\item{station_number}{A character string vector of seven digit Water Survey of Canada station numbers (e.g. \code{"08NM116"}) of
which to extract daily streamflow data from a HYDAT database. Requires \code{tidyhydat} package and a HYDAT database.
Leave blank if using \code{data} argument.}

\item{percentiles}{Numeric vector of percentiles to calculate. Set to NA if none required. Default \code{c(10,90)}.}

\item{roll_days}{Numeric value of the number of days to apply a rolling mean. Default \code{1}.}

\item{roll_align}{Character string identifying the direction of the rolling mean from the specified date, either by the first 
('left'), last ('right), or middle ('center') day of the rolling n-day group of observations. Default \code{'right'}.}

\item{water_year}{Logical value indicating whether to use water years to group data instead of calendar years. Water years 
are designated by the calendar year in which they end. Default \code{FALSE}.}

\item{water_year_start}{Numeric value indicating the month of the start of the water year. Used if \code{water_year = TRUE}. 
Default \code{10}.}

\item{start_year}{Numeric value of the first year to consider for analysis. Leave blank to use the first year of the source data.}

\item{end_year}{Numeric value of the last year to consider for analysis. Leave blank to use the last year of the source data.}

\item{exclude_years}{Numeric vector of years to exclude from analysis. Leave blank to include all years.}

\item{months}{Numeric vector of months to include in analysis (e.g.. \code{6:8} for Jun-Aug). Leave blank to summarize 
all months (default \code{1:12}).}

\item{complete_years}{Logical values indicating whether to include only years with complete data in analysis. Default \code{FALSE}.}

\item{include_longterm}{Logical value indicating whether to include longterm calculation of all data. Default \code{TRUE}.}

\item{custom_months}{Numeric vector of months to combine to summarize (ex. \code{6:8} for Jun-Aug). Adds results to the end of table.
If wanting months that overlap calendar years (ex. Oct-Mar), choose water_year and a water_year_month that begins before the first 
month listed. Leave blank for no custom month summary.}

\item{custom_months_label}{Character string to label custom months. For example, if choosing months 7:9  you may choose 
"Summer" or "Jul-Sep". Default \code{"Custom-Months"}.}

\item{transpose}{Logical value indicating if the results rows and columns are to be switched. Default \code{FALSE}.}

\item{ignore_missing}{Logical value indicating whether dates with missing values should be included in the calculation. If
\code{TRUE} then a statistic will be calculated regardless of missing dates. If \code{FALSE} then only statistics from time periods 
with no missing dates will be returned. Default \code{FALSE}.}
}
\value{
A tibble data frame with the following columns:
  \item{Month}{month of the year, included 'Long-term' for all months, and 'Custom-Months' if selected}
  \item{Mean}{mean of all daily data for a given month and long-term over all years}
  \item{Median}{median of all daily data for a given month and long-term over all years}
  \item{Maximum}{maximum of all daily data for a given month and long-term over all years}
  \item{Minimum}{minimum of all daily data for a given month and long-term over all years}
  \item{P'n'}{each  n-th percentile selected for a given month and long-term over all years}
  Default percentile columns:
  \item{P10}{annual 10th percentile selected for a given month and long-term over all years}
  \item{P90}{annual 90th percentile selected for a given month and long-term over all years}
  Transposing data creates a column of "Statistics" and subsequent columns for each year selected.
}
\description{
Calculates the long-term and long-term monthly mean, median, maximum, minimum, and percentiles of daily flow values 
   from a streamflow dataset. Calculates the statistics from all daily values from all years, unless specified.
}
\examples{
\dontrun{

calc_longterm_stats(station_number = "08NM116", 
                    water_year = TRUE, 
                    water_year_start = 8, 
                    percentiles = c(1:10))

calc_longterm_stats(station_number = c("08NM116","08NM242"), 
                    custom_months = c(5:9))

}
}
