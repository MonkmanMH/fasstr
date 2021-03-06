% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/plot_annual_flow_timing.R
\name{plot_annual_flow_timing}
\alias{plot_annual_flow_timing}
\title{Plot annual flow timing}
\usage{
plot_annual_flow_timing(data = NULL, dates = Date, values = Value,
  groups = STATION_NUMBER, station_number = NULL,
  percent_total = c(25, 33.3, 50, 75), water_year = FALSE,
  water_year_start = 10, start_year = 0, end_year = 9999,
  exclude_years = NULL, include_title = FALSE)
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

\item{percent_total}{Numeric vector of percents of total annual flows to determine dates. Default \code{c(25,33.3,50,75)}.}

\item{water_year}{Logical value indicating whether to use water years to group data instead of calendar years. Water years 
are designated by the calendar year in which they end. Default \code{FALSE}.}

\item{water_year_start}{Numeric value indicating the month of the start of the water year. Used if \code{water_year = TRUE}. 
Default \code{10}.}

\item{start_year}{Numeric value of the first year to consider for analysis. Leave blank to use the first year of the source data.}

\item{end_year}{Numeric value of the last year to consider for analysis. Leave blank to use the last year of the source data.}

\item{exclude_years}{Numeric vector of years to exclude from analysis. Leave blank to include all years.}

\item{include_title}{Logical value to indicate adding the group/station number to the plot, if provided. Default \code{FALSE}.}
}
\value{
A list of ggplot2 objects with the following for each station provided:
  \item{Annual_Flow_Timing}{a plot that contains each n-percent of total volumetric discharge}
  Default plots on each object:   
  \item{DoY_25pct_TotalQ}{day of year of 25-percent of total volumetric discharge}
  \item{DoY_33.3pct_TotalQ}{day of year of 33.3-percent of total volumetric discharge}
  \item{DoY_50pct_TotalQ}{day of year of 50-percent of total volumetric discharge}
  \item{DoY_75pct_TotalQ}{day of year of 75-percent of total volumetric discharge}
}
\description{
Plots annual the timing (day of year) of occurrence of portions of total annual flow of daily flow 
   values from a streamflow dataset. Calculates the statistics from all daily discharge values from all years, unless specified.
   Data calculated using calc_annual_flow_timing() function.
}
\examples{
\dontrun{

plot_annual_flow_timing(station_number = "08NM116", 
                        water_year = TRUE, 
                        water_year_start = 8, 
                        percent_total = 50)

}
}
\references{
\itemize{
 \item{Barnett, T.P., Pierce, D.W., Hidalgo, H.G., Bonfils, C., Santer, B.D., Das, T., Bala, G., Wood, A.W.,
       Nozawa, T., Mirin, A.A., Cayan, D.R., Dettinger, M.D., 2008. Human-Induced Clanges in the Hydrology of 
       the Western United States. Science 319, 1080-1083.}
       }
}
\seealso{
\code{\link{calc_annual_flow_timing}}
}
