# Copyright 2017 Province of British Columbia
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
# http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and limitations under the License.

#' @title Calculate annual summary statistics
#'
#' @description Calculates annual mean, median, maximum, minimum, and percentiles of daily flow values from a streamflow 
#'    dataset. Calculates the statistics from all daily discharge values from all years, unless specified.
#'
#' @param data A data frame of daily data that contains columns of dates, flow values, and (optional) groups (e.g. station numbers).
#'    Leave blank if using \code{station_number} argument.
#' @param dates Column in \code{data} that contains dates formatted YYYY-MM-DD. Only required if dates column name is not '
#'    Date' (default). Leave blank if using \code{station_number} argument.
#' @param values Column in \code{data} that contains numeric flow values, in units of cubic metres per second.
#'    Only required if values column name is not 'Value' (default). Leave blank if using \code{station_number} argument.
#' @param groups Column in \code{data} that contains unique identifiers for different data sets, if applicable. Only required if
#'    groups column name is not 'STATION_NUMBER'. Function will automatically group by a column named 'STATION_NUMBER' if present.
#'    Remove the 'STATION_NUMBER' column beforehand to remove this grouping. Leave blank if using \code{station_number} argument.
#' @param station_number A character string vector of seven digit Water Survey of Canada station numbers (e.g. \code{"08NM116"}) of
#'    which to extract daily streamflow data from a HYDAT database. Requires \code{tidyhydat} package and a HYDAT database.
#'    Leave blank if using \code{data} argument.
#' @param roll_days Numeric value of the number of days to apply a rolling mean. Default \code{1}.
#' @param roll_align Character string identifying the direction of the rolling mean from the specified date, either by the first 
#'    ('left'), last ('right), or middle ('center') day of the rolling n-day group of observations. Default \code{'right'}.
#' @param percentiles Numeric vector of percentiles to calculate. Set to NA if none required. Default \code{c(10,90)}.
#' @param water_year Logical value indicating whether to use water years to group data instead of calendar years. Water years 
#'    are designated by the calendar year in which they end. Default \code{FALSE}.
#' @param water_year_start Numeric value indicating the month of the start of the water year. Used if \code{water_year = TRUE}. 
#'    Default \code{10}.
#' @param start_year Numeric value of the first year to consider for analysis. Leave blank to use the first year of the source data.
#' @param end_year Numeric value of the last year to consider for analysis. Leave blank to use the last year of the source data.
#' @param exclude_years Numeric vector of years to exclude from analysis. Leave blank to include all years.             
#' @param months Numeric vector of months to include in analysis (e.g.. \code{6:8} for Jun-Aug). Leave blank to summarize 
#'    all months (default \code{1:12}).
#' @param transpose Logical value indicating if the results rows and columns are to be switched. Default \code{FALSE}.
#' @param ignore_missing Logical value indicating whether dates with missing values should be included in the calculation. If
#'    \code{TRUE} then a statistic will be calculated regardless of missing dates. If \code{FALSE} then only statistics from time periods 
#'    with no missing dates will be returned. Default \code{FALSE}.
#' 
#' @return A tibble data frame with the following columns:
#'   \item{Year}{calendar or water year selected}
#'   \item{Mean}{annual mean of all daily flows for a given year}
#'   \item{Median}{annual median of all daily flows for a given year}
#'   \item{Maximum}{annual maximum of all daily flows for a given year}
#'   \item{Minimum}{annual minimum of all daily flows for a given year}
#'   \item{P'n'}{each annual n-th percentile selected of all daily flows}
#'   Default percentile columns:
#'   \item{P10}{annual 10th percentile of all daily flows for a given year}
#'   \item{P90}{annual 90th percentile of all daily flows for a given year}
#'   Transposing data creates a column of "Statistics" and subsequent columns for each year selected.
#'   
#' @examples
#' \dontrun{
#' 
#' calc_annual_stats(data = flow_data)
#' 
#' calc_annual_stats(station_number = "08NM116",
#'                   water_year = TRUE, 
#'                   water_year_start = 8, 
#'                   percentiles = c(1:10))
#'
#' calc_annual_stats(station_number = "08NM116", 
#'                   months = 7:9)
#'
#' }
#' @export


calc_annual_stats <- function(data = NULL,
                              dates = Date,
                              values = Value,
                              groups = STATION_NUMBER,
                              station_number = NULL,
                              roll_days = 1,
                              roll_align = "right",
                              percentiles = c(10,90),
                              water_year = FALSE,
                              water_year_start = 10,
                              start_year = 0,
                              end_year = 9999,
                              exclude_years = NULL, 
                              months = 1:12,
                              transpose = FALSE,
                              ignore_missing = FALSE){
  
  
  ## ARGUMENT CHECKS
  ## ---------------
  
  rolling_days_checks(roll_days, roll_align)
  percentiles_checks(percentiles)
  water_year_checks(water_year, water_year_start)
  years_checks(start_year, end_year, exclude_years)
  months_checks(months)
  transpose_checks(transpose)
  ignore_missing_checks(ignore_missing)
  
  
  ## FLOW DATA CHECKS AND FORMATTING
  ## -------------------------------
  
  # Check if data is provided and import it
  flow_data <- flowdata_import(data = data, 
                               station_number = station_number)
  
  # Save the original columns (to check for STATION_NUMBER col at end) and ungroup if necessary
  orig_cols <- names(flow_data)
  flow_data <- dplyr::ungroup(flow_data)
  
  # Check and rename columns
  flow_data <- format_all_cols(data = flow_data,
                               dates = as.character(substitute(dates)),
                               values = as.character(substitute(values)),
                               groups = as.character(substitute(groups)),
                               rm_other_cols = TRUE)
  
  
  ## PREPARE FLOW DATA
  ## -----------------

  # Fill missing dates, add date variables, and add AnalysisYear
  flow_data <- analysis_prep(data = flow_data, 
                             water_year = water_year, 
                             water_year_start = water_year_start,
                             year = TRUE)
  
  # Add rolling means to end of dataframe
  flow_data <- add_rolling_means(data = flow_data, roll_days = roll_days, roll_align = roll_align)
  colnames(flow_data)[ncol(flow_data)] <- "RollingValue"
  
  # Filter for the selected year (remove excluded years after)
  flow_data <- dplyr::filter(flow_data, AnalysisYear >= start_year & AnalysisYear <= end_year)
  flow_data <- dplyr::filter(flow_data, Month %in% months)
  
  
  ## CALCULATE STATISTICS
  ## --------------------
  
  # Calculate basic stats
  annual_stats <-   dplyr::summarize(dplyr::group_by(flow_data, STATION_NUMBER, AnalysisYear),
                                     Mean = mean(RollingValue, na.rm = ignore_missing),
                                     Median = stats::median(RollingValue, na.rm = ignore_missing),
                                     Maximum = max (RollingValue, na.rm = ignore_missing),
                                     Minimum = min (RollingValue, na.rm = ignore_missing))
  annual_stats <- dplyr::ungroup(annual_stats)
  
  #Remove Nans and Infs
  annual_stats$Mean[is.nan(annual_stats$Mean)] <- NA
  annual_stats$Maximum[is.infinite(annual_stats$Maximum)] <- NA
  annual_stats$Minimum[is.infinite(annual_stats$Minimum)] <- NA
  
  # Calculate annual percentiles
  if(!all(is.na(percentiles))) {
    for (ptile in percentiles) {
      # Calculate percentiles
      annual_stats_ptile <- dplyr::summarise(dplyr::group_by(flow_data, STATION_NUMBER, AnalysisYear),
                                             Percentile = stats::quantile(RollingValue, ptile / 100, na.rm = TRUE))
      annual_stats_ptile <- dplyr::ungroup(annual_stats_ptile)
      names(annual_stats_ptile)[names(annual_stats_ptile) == "Percentile"] <- paste0("P", ptile)
      
      # Merge with stats
      annual_stats <- merge(annual_stats, annual_stats_ptile, by = c("STATION_NUMBER", "AnalysisYear"))
      
      # Remove percentile if mean is NA (workaround for na.rm=FALSE in quantile)
      annual_stats[, ncol(annual_stats)] <- ifelse(is.na(annual_stats$Mean), NA, annual_stats[, ncol(annual_stats)])
    }
  }
  
  
  ## Final formatting
  ## ----------------

  # Rename year column
  annual_stats <- dplyr::rename(annual_stats, Year = AnalysisYear)
  
  # Remove selected excluded years
  annual_stats[annual_stats$Year %in% exclude_years, -(1:2)] <- NA
  
  
  # If transpose if selected
  if (transpose) {
    # Get list of columns to order the Statistic column after transposing
    stat_levels <- names(annual_stats[-(1:2)])
    
    # Transpose the columns for rows
    annual_stats <- tidyr::gather(annual_stats, Statistic, Value, -STATION_NUMBER, -Year)
    annual_stats <- tidyr::spread(annual_stats, Year, Value)
    
    # Order the columns
    annual_stats$Statistic <- factor(annual_stats$Statistic, levels = stat_levels)
    annual_stats <- dplyr::arrange(annual_stats, STATION_NUMBER, Statistic)
  }
  
  # Give warning if any NA values
  missing_values_warning(annual_stats[, 3:ncol(annual_stats)])
  
  
  # Recheck if station_number/grouping was in original data and rename or remove as necessary
  if(as.character(substitute(groups)) %in% orig_cols) {
    names(annual_stats)[names(annual_stats) == "STATION_NUMBER"] <- as.character(substitute(groups))
  } else {
    annual_stats <- dplyr::select(annual_stats, -STATION_NUMBER)
  }
  
  
  dplyr::as_tibble(annual_stats)
}

