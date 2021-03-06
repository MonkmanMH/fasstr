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

#' @title Calculate the long-term and long-term monthly summary statistics
#'
#' @description Calculates the long-term and long-term monthly mean, median, maximum, minimum, and percentiles of daily flow values 
#'    from a streamflow dataset. Calculates the statistics from all daily values from all years, unless specified.
#'
#' @inheritParams calc_daily_stats
#' @param percentiles Numeric vector of percentiles to calculate. Set to NA if none required. Default \code{c(10,90)}.
#' @param include_longterm Logical value indicating whether to include longterm calculation of all data. Default \code{TRUE}.
#' @param custom_months Numeric vector of months to combine to summarize (ex. \code{6:8} for Jun-Aug). Adds results to the end of table.
#'    If wanting months that overlap calendar years (ex. Oct-Mar), choose water_year and a water_year_month that begins before the first 
#'    month listed. Leave blank for no custom month summary.
#' @param custom_months_label Character string to label custom months. For example, if choosing months 7:9  you may choose 
#'    "Summer" or "Jul-Sep". Default \code{"Custom-Months"}.
#' 
#' @return A tibble data frame with the following columns:
#'   \item{Month}{month of the year, included 'Long-term' for all months, and 'Custom-Months' if selected}
#'   \item{Mean}{mean of all daily data for a given month and long-term over all years}
#'   \item{Median}{median of all daily data for a given month and long-term over all years}
#'   \item{Maximum}{maximum of all daily data for a given month and long-term over all years}
#'   \item{Minimum}{minimum of all daily data for a given month and long-term over all years}
#'   \item{P'n'}{each  n-th percentile selected for a given month and long-term over all years}
#'   Default percentile columns:
#'   \item{P10}{annual 10th percentile selected for a given month and long-term over all years}
#'   \item{P90}{annual 90th percentile selected for a given month and long-term over all years}
#'   Transposing data creates a column of "Statistics" and subsequent columns for each year selected.
#'   
#' @examples
#' \dontrun{
#' 
#' calc_longterm_stats(station_number = "08NM116", 
#'                     water_year = TRUE, 
#'                     water_year_start = 8, 
#'                     percentiles = c(1:10))
#'
#' calc_longterm_stats(station_number = c("08NM116","08NM242"), 
#'                     custom_months = c(5:9))
#'
#' }
#' @export


calc_longterm_stats <- function(data = NULL,
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
                                complete_years = FALSE,
                                include_longterm = TRUE,
                                custom_months = NULL,
                                custom_months_label = "Custom-Months",
                                transpose = FALSE,
                                ignore_missing = FALSE){
  
  
  ## ARGUMENT CHECKS
  ## ---------------
  
  rolling_days_checks(roll_days, roll_align)
  percentiles_checks(percentiles)
  water_year_checks(water_year, water_year_start)
  years_checks(start_year, end_year, exclude_years)
  months_checks(months = months)
  transpose_checks(transpose)
  ignore_missing_checks(ignore_missing)
  complete_yrs_checks(complete_years)
  custom_months_checks(custom_months, custom_months_label)
  include_longterm_checks(include_longterm)
  
  
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
 
  # Filter for the selected years
  flow_data <- dplyr::filter(flow_data, AnalysisYear >= start_year & AnalysisYear <= end_year)
  flow_data <- dplyr::filter(flow_data, !(AnalysisYear %in% exclude_years))
  flow_data <- dplyr::filter(flow_data, Month %in% months)
  
  
  # Remove incomplete years if selected
  flow_data <- filter_complete_yrs(complete_years = complete_years, 
                                   flow_data)
  

  
  ## CALCULATE STATISTICS
  ## --------------------
  
  # Calculate the monthly and longterm stats
  Q_months <- dplyr::summarize(dplyr::group_by(flow_data, STATION_NUMBER, MonthName),
                               Mean = mean(RollingValue, na.rm = ignore_missing),
                               Median = stats::median(RollingValue, na.rm = ignore_missing),
                               Maximum = max(RollingValue, na.rm = ignore_missing),
                               Minimum = min(RollingValue, na.rm = ignore_missing))
  Q_months <- dplyr::ungroup(Q_months)
  
  if (include_longterm) {
    longterm_stats   <- dplyr::summarize(dplyr::group_by(flow_data, STATION_NUMBER),
                                         Mean = mean(RollingValue, na.rm = ignore_missing),
                                         Median = stats::median(RollingValue, na.rm = ignore_missing),
                                         Maximum = max(RollingValue, na.rm = ignore_missing),
                                         Minimum = min(RollingValue, na.rm = ignore_missing))
    longterm_stats <- dplyr::ungroup(longterm_stats)
    longterm_stats <- dplyr::mutate(longterm_stats, MonthName = as.factor("Long-term"))
    
    longterm_stats <- rbind(Q_months, longterm_stats)  #dplyr::bindrows gives unnecessary warnings
  } else {
    longterm_stats <- Q_months
  }
  
  
  # Calculate the monthly and longterm percentiles
  if(!all(is.na(percentiles))) {
    for (ptile in percentiles) {
      
      Q_months_ptile <- dplyr::summarise(dplyr::group_by(flow_data, STATION_NUMBER, MonthName),
                                         Percentile = ifelse(!is.na(mean(RollingValue, na.rm = FALSE)) | ignore_missing, 
                                                             stats::quantile(RollingValue, ptile / 100, na.rm = TRUE), NA))
      names(Q_months_ptile)[names(Q_months_ptile) == "Percentile"] <- paste0("P", ptile)
      Q_months_ptile <- dplyr::ungroup(Q_months_ptile)
      
      
      if (include_longterm) {
        longterm_stats_ptile <- dplyr::summarise(dplyr::group_by(flow_data, STATION_NUMBER),
                                                 Percentile = ifelse(!is.na(mean(RollingValue, na.rm = FALSE)) | ignore_missing, 
                                                                     stats::quantile(RollingValue, ptile / 100, na.rm = TRUE), NA))
        longterm_stats_ptile <- dplyr::mutate(longterm_stats_ptile, MonthName = "Long-term")
        
        names(longterm_stats_ptile)[names(longterm_stats_ptile) == "Percentile"] <- paste0("P", ptile)
        longterm_stats_ptile <- dplyr::ungroup(longterm_stats_ptile)
        
        longterm_stats_ptile <- rbind(dplyr::ungroup(Q_months_ptile), dplyr::ungroup(longterm_stats_ptile))  #dplyr::bindrows gives unnecessary warnings
      } else {
        longterm_stats_ptile <- Q_months_ptile
      }
      # Merge with longterm_stats
      longterm_stats <- merge(longterm_stats,longterm_stats_ptile, by = c("STATION_NUMBER", "MonthName"))
    }
  }
  
  # Calculate custom_months is selected, append data to end
  if(is.numeric(custom_months) & all(custom_months %in% c(1:12))) {
    
    # Filter months for those selected and calculate stats
    flow_data_temp <- dplyr::filter(flow_data, Month %in% custom_months)
    Q_months_custom <-   dplyr::summarize(dplyr::group_by(flow_data_temp, STATION_NUMBER),
                                          Mean = mean(RollingValue, na.rm = ignore_missing),
                                          Median = stats::median(RollingValue, na.rm = ignore_missing),
                                          Maximum = max(RollingValue,na.rm = ignore_missing),
                                          Minimum = min(RollingValue,na.rm = ignore_missing))
    Q_months_custom <- dplyr::mutate(Q_months_custom, MonthName = paste0(custom_months_label))
    
    # Calculate percentiles
    if (!all(is.na(percentiles))){
      for (ptile in percentiles) {
        Q_ptile_custom <- dplyr::summarize(dplyr::group_by(flow_data_temp, STATION_NUMBER),
                                           Percentile = ifelse(!is.na(mean(RollingValue, na.rm = FALSE)) | ignore_missing, 
                                                               stats::quantile(RollingValue, ptile / 100, na.rm = TRUE), NA))
        Q_ptile_custom <- dplyr::mutate(Q_ptile_custom, MonthName = paste0(custom_months_label))
        names(Q_ptile_custom)[names(Q_ptile_custom) == "Percentile"] <- paste0("P", ptile)
        
        # Merge with custom stats
        Q_months_custom <- merge(dplyr::ungroup(Q_months_custom), dplyr::ungroup(Q_ptile_custom), by = c("STATION_NUMBER", "MonthName"))
      }
    }
    # Merge with longterm_stats
    longterm_stats <- rbind(longterm_stats, Q_months_custom)
  }
  
  # Rename Month column and reorder to proper levels (set in add_date_vars)
  longterm_stats <- dplyr::rename(longterm_stats, Month = MonthName)
  longterm_stats <- with(longterm_stats, longterm_stats[order(STATION_NUMBER, Month),])
  #  row.names(longterm_stats) <- c(1:nrow(longterm_stats))
  
  
  # If transpose if selected, switch columns and rows
  if (transpose) {
    # Get list of columns to order the Statistic column after transposing
    stat_levels <- names(longterm_stats[-(1:2)])
    
    # Transpose the columns for rows
    longterm_stats <- tidyr::gather(longterm_stats, Statistic, Value, -STATION_NUMBER, -Month)
    longterm_stats <- tidyr::spread(longterm_stats, Month, Value)
    
    # Order the columns
    longterm_stats$Statistic <- factor(longterm_stats$Statistic, levels = stat_levels)
    longterm_stats <- dplyr::arrange(longterm_stats, STATION_NUMBER, Statistic)
  }
  
  # Give warning if any NA values
  missing_values_warning(longterm_stats[, 3:ncol(longterm_stats)])
  
  # Recheck if station_number was in original flow_data and rename or remove as necessary
  if(as.character(substitute(groups)) %in% orig_cols) {
    names(longterm_stats)[names(longterm_stats) == "STATION_NUMBER"] <- as.character(substitute(groups))
  } else {
    longterm_stats <- dplyr::select(longterm_stats, -STATION_NUMBER)
  }
  
  
  
  dplyr::as_tibble(longterm_stats)
  
  
}
