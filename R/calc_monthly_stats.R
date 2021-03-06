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

#' @title Calculate monthly summary statistics
#'
#' @description Calculates monthly mean, median, maximum, minimum, and percentiles for each month of all years of daily flow values 
#'    from a streamflow dataset. Calculates the statistics from all daily discharge values from all years, unless specified.
#'
#' @inheritParams calc_annual_stats
#' @param transpose Logical value indicating if each month statistic should be individual rows. Default \code{FALSE}.
#' @param spread Logical value indicating if each month statistic should be the column name. Default \code{FALSE}.
#' 
#' @return A tibble data frame with the following columns:
#'   \item{Year}{calendar or water year selected}
#'   \item{Month}{month of the year}
#'   \item{Mean}{mean of all daily flows for a given month and year}
#'   \item{Median}{median of all daily flows for a given month and year}
#'   \item{Maximum}{maximum of all daily flows for a given month and year}
#'   \item{Minimum}{minimum of all daily flows for a given month and year}
#'   \item{P'n'}{each n-th percentile selected for a given month and year}
#'   Default percentile columns:
#'   \item{P10}{10th percentile of all daily flows for a given month and year}
#'   \item{P90}{90th percentile of all daily flows for a given month and year}
#'   Transposing data creates a column of 'Statistics' for each month, labeled as 'Month-Statistic' (ex "Jan-Mean"),
#'   and subsequent columns for each year selected.
#'   Spreading data creates columns of Year and subsequent columns of Month-Statistics  (ex 'Jan-Mean').
#'   
#' @examples
#' \dontrun{
#' 
#' calc_monthly_stats(station_number = "08NM116", 
#'                    water_year = TRUE,
#'                    water_year_start = 8, 
#'                    percentiles = c(1:10))
#'
#' calc_monthly_stats(station_number = "08NM116", 
#'                    months = 7:9)
#'
#' }
#' @export


calc_monthly_stats <- function(data = NULL,
                               dates = Date,
                               values = Value,
                               groups = STATION_NUMBER,
                               station_number = NULL,
                               percentiles = c(10,90),
                               roll_days = 1,
                               roll_align = "right",
                               water_year = FALSE,
                               water_year_start = 10,
                               start_year = 0,
                               end_year = 9999,
                               exclude_years = NULL,
                               months = 1:12,
                               transpose = FALSE,
                               spread = FALSE,
                               ignore_missing = FALSE){
  
  
  ## ARGUMENT CHECKS
  ## ---------------
  
  rolling_days_checks(roll_days, roll_align, multiple = FALSE)
  water_year_checks(water_year, water_year_start)
  years_checks(start_year, end_year, exclude_years)
  months_checks(months)
  ignore_missing_checks(ignore_missing)
  transpose_checks(transpose)
  spread_checks(spread)
  if(transpose & spread) stop("Both spread and transpose arguments cannot be TRUE.", call. = FALSE)
  

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
  monthly_stats <- dplyr::summarize(dplyr::group_by(flow_data, STATION_NUMBER, AnalysisYear, MonthName),
                                Mean = mean(RollingValue, na.rm = ignore_missing),  
                                Median = stats::median(RollingValue, na.rm = ignore_missing), 
                                Maximum = suppressWarnings(max(RollingValue, na.rm = ignore_missing)),    
                                Minimum = suppressWarnings(min(RollingValue, na.rm = ignore_missing)))
  monthly_stats <- dplyr::ungroup(monthly_stats)
  
  # Calculate annual percentiles
  if(!all(is.na(percentiles))) {
    for (ptile in percentiles) {
      monthly_stats_ptile <- dplyr::summarise(dplyr::group_by(flow_data, STATION_NUMBER, AnalysisYear, MonthName),
                                          Percentile = stats::quantile(RollingValue, ptile / 100, na.rm = TRUE))
      monthly_stats_ptile <- dplyr::ungroup(monthly_stats_ptile)
      
      names(monthly_stats_ptile)[names(monthly_stats_ptile) == "Percentile"] <- paste0("P", ptile)
      
      # Merge with monthly_stats
      monthly_stats <- merge(monthly_stats, monthly_stats_ptile, by = c("STATION_NUMBER", "AnalysisYear", "MonthName"))
      
      # Remove percentile if mean is NA (workaround for na.rm=FALSE in quantile)
      monthly_stats[, ncol(monthly_stats)] <- ifelse(is.na(monthly_stats$Mean), NA, monthly_stats[, ncol(monthly_stats)])
    }
  }
  
  #Remove Nans and Infs
  monthly_stats$Mean[is.nan(monthly_stats$Mean)] <- NA
  monthly_stats$Maximum[is.infinite(monthly_stats$Maximum)] <- NA
  monthly_stats$Minimum[is.infinite(monthly_stats$Minimum)] <- NA
  
  # Rename year column
  monthly_stats <-   dplyr::rename(monthly_stats, Year = AnalysisYear, Month = MonthName)
  
  
  # Set the levels of the months for proper ordering
  if (water_year) {
    if (water_year_start == 1) {
      monthly_stats$Month <- factor(monthly_stats$Month, 
                                levels = c("Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"))
    } else if (water_year_start == 2) {
      monthly_stats$Month <- factor(monthly_stats$Month, 
                                levels = c("Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec", "Jan"))
    } else if (water_year_start == 3) {
      monthly_stats$Month <- factor(monthly_stats$Month, 
                                levels = c("Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec", "Jan", "Feb"))
    } else if (water_year_start == 4) {
      monthly_stats$Month <- factor(monthly_stats$Month, 
                                levels = c("Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec", "Jan", "Feb", "Mar"))
    } else if (water_year_start == 5) {
      monthly_stats$Month <- factor(monthly_stats$Month, 
                                levels = c("May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec", "Jan", "Feb", "Mar", "Apr"))
    } else if (water_year_start == 6) {
      monthly_stats$Month <- factor(monthly_stats$Month, 
                                levels = c("Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec", "Jan", "Feb", "Mar", "Apr", "May"))
    } else if (water_year_start == 7) {
      monthly_stats$Month <- factor(monthly_stats$Month, 
                                levels = c("Jul", "Aug", "Sep", "Oct", "Nov", "Dec", "Jan", "Feb", "Mar", "Apr", "May", "Jun"))
    } else if (water_year_start == 8) {
      monthly_stats$Month <- factor(monthly_stats$Month, 
                                levels = c("Aug", "Sep", "Oct", "Nov", "Dec", "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul"))
    } else if (water_year_start == 9) {
      monthly_stats$Month <- factor(monthly_stats$Month, 
                                levels = c("Sep", "Oct", "Nov", "Dec", "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug"))
    } else if (water_year_start == 10) {
      monthly_stats$Month <- factor(monthly_stats$Month, 
                                levels = c("Oct", "Nov", "Dec", "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep"))
    } else if (water_year_start == 11) {
      monthly_stats$Month <- factor(monthly_stats$Month, 
                                levels = c("Nov", "Dec", "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct"))
    } else if (water_year_start == 12) {
      monthly_stats$Month <- factor(monthly_stats$Month, 
                                levels = c("Dec", "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov"))
    }
  } else {           
    monthly_stats$Month <- factor(monthly_stats$Month,
                              levels = c("Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"))
  }
  
  # Reorder months and row.names
  monthly_stats <- with(monthly_stats, monthly_stats[order(Year, Month),])
  
  
  # Make excluded years data NA
  if(as.character(substitute(groups)) %in% orig_cols) {
    monthly_stats[monthly_stats$Year %in% exclude_years,-(1:3)] <- NA
  } else {
    monthly_stats[monthly_stats$Year %in% exclude_years,-(1:2)] <- NA
  }
  
  
  # Transform data to chosen format
  # Spread data if selected
  if (spread | transpose) {
    monthly_stats_spread <- dplyr::summarise(dplyr::group_by(monthly_stats, STATION_NUMBER, Year))
    monthly_stats_spread <- dplyr::ungroup(monthly_stats_spread)
    for (mnth in unique(monthly_stats$Month)) {
      monthly_stats_month <- dplyr::filter(monthly_stats, Month == mnth)
      monthly_stats_month <- tidyr::gather(monthly_stats_month, Statistic, Value, 4:ncol(monthly_stats_month))
      monthly_stats_month <- dplyr::mutate(monthly_stats_month, StatMonth = paste0(Month, "_", Statistic))
      monthly_stats_month <- dplyr::select(monthly_stats_month, -Statistic, -Month)
      stat_order <- unique(monthly_stats_month$StatMonth)
      monthly_stats_month <- tidyr::spread(monthly_stats_month, StatMonth, Value)
      monthly_stats_month <-  monthly_stats_month[, c("STATION_NUMBER", "Year", stat_order)]
      monthly_stats_spread <- merge(monthly_stats_spread, monthly_stats_month, by = c("STATION_NUMBER", "Year"), all = TRUE)
    }
    monthly_stats <- monthly_stats_spread
    
    if(transpose){
      monthly_stats <- tidyr::gather(monthly_stats, Statistic, Value, -(1:2))
    }
  }
  
  monthly_stats <- with(monthly_stats, monthly_stats[order(STATION_NUMBER, Year),])
  
  # Give warning if any NA values
  missing_values_warning(monthly_stats[, 4:ncol(monthly_stats)])
  

  # Recheck if station_number/grouping was in original flow_data and rename or remove as necessary
  if(as.character(substitute(groups)) %in% orig_cols) {
    names(monthly_stats)[names(monthly_stats) == "STATION_NUMBER"] <- as.character(substitute(groups))
  } else {
    monthly_stats <- dplyr::select(monthly_stats, -STATION_NUMBER)
  }
  
  
  
  dplyr::as_tibble(monthly_stats)
  
}

