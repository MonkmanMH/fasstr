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

#' @title Calculate cumulative daily flow statistics
#'
#' @description Calculate cumulative daily flow statistics for each day of the year of daily flow values from a streamflow dataset. 
#'    Calculates the statistics from all daily discharge values from all years, unless specified. Defaults to volumetric cumulative 
#'    flows, can use \code{use_yield} and \code{basin_area} to convert to runoff yield.
#'
#' @param data Daily data to be analyzed. Options:
#' 
#'    A data frame of daily data that contains columns of dates, values, and (optional) groups (ex. station 
#'    names/numbers).
#'    
#'    A character string vector of seven digit Water Survey of Canada station numbers (e.g. \code{"08NM116"}) of which to 
#'    extract daily streamflow data from a HYDAT database. Requires \code{tidyhydat} package and a HYDAT database.   
#' @param dates Column in the \code{data} data frame that contains dates formatted YYYY-MM-DD. Only required if
#'    using the data frame option of \code{data} and dates column is not named 'Date'. Default \code{Date}. 
#' @param values Column in the \code{data} data frame that contains numeric flow values, in units of cubic metres per second.
#'    Only required if using the data frame option of \code{data} and values column is not named 'Value'. Default \code{Value}. 
#' @param groups Column in the \code{data} data frame that contains unique identifiers for different data sets. 
#'    Only required if using the data frame option of \code{data} and groups column is not named 'STATION_NUMBER'.
#'    Function will automatically group by a column named 'STATION_NUMBER' if present. Remove the 'STATION_NUMBER' column or identify 
#'    another non-existing column name to remove this grouping. Identify another column if desired. Default \code{STATION_NUMBER}. 
#' @param use_yield Logical value indicating whether to use yield runoff, in mm, instead of volumetric. Default \code{FALSE}.
#' @param percentiles Numeric vector of percentiles to calculate. Set to NA if none required. Default \code{c(5,25,75,95)}.
#' @param basin_area Upstream drainage basin area to apply to daily observations. Options:
#'    
#'    Leave blank if \code{groups} is STATION_NUMBER with HYDAT station numbers to extract basin areas from HYDAT.
#'    
#'    Single numeric value to apply to all observations.
#'    
#'    List each basin area for each grouping factor (can override HYDAT value) as such \code{c("08NM116" = 795, "08NM242" = 10)}.
#'    Factors not listed will result in NA basin areas.
#' @param water_year Logical value indicating whether to use water years to group data instead of calendar years. Water years 
#'    are designated by the year in which they end. Default \code{FALSE}.
#' @param water_year_start Numeric value indicating the month of the start of the water year. Used if \code{water_year = TRUE}. 
#'    Default \code{10}.
#' @param start_year Numeric value of the first year to consider for analysis. Leave blank to use the first year of the source data.
#' @param end_year Numeric value of the last year to consider for analysis. Leave blank to use the last year of the source data.
#' @param exclude_years Numeric vector of years to exclude from analysis. Leave blank to include all years.             
#' @param complete_years Logical values indicating whether to include only years with complete data in analysis. Default \code{FALSE}.          
#' @param transpose Logical value indicating if the results rows and columns are to be switched. Default \code{FALSE}.
#' @param ignore_missing Logical value indicating whether dates with missing values should be included in the calculation. If
#'    \code{TRUE} then a statistic will be calculated regardless of missing dates. If \code{FALSE} then only statistics from time periods 
#'    with no missing dates will be returned. Default \code{TRUE}.
#'    
#' @return A data frame with the following columns, default units in cubic metres, millimetres if use_yield and basin_area provided:
#'   \item{Date}{date (MMM-DD) of daily cumulative statistics}
#'   \item{DayofYear}{day of year of daily cumulative statistics}
#'   \item{Mean}{daily mean of all cumulative flows for a given day of the year}
#'   \item{Median}{daily mean of all cumulative flows for a given day of the year}
#'   \item{Maximum}{daily mean of all cumulative flows for a given day of the year}
#'   \item{Minimum}{daily mean of all cumulative flows for a given day of the year}
#'   \item{P'n'}{each daily n-th percentile selected of all cumulative flows for a given day of the year}
#'   Default percentile columns:
#'   \item{P5}{daily 5th percentile of all cumulative flows for a given day of the year}
#'   \item{P25}{daily 25th percentile of all cumulative flows for a given day of the year}
#'   \item{P75}{daily 75th percentile of all cumulative flows for a given day of the year}
#'   \item{P95}{daily 95th percentile of all cumulative flows for a given day of the year}
#'   Transposing data creates a column of "Statistics" and subsequent columns for each year selected.
#'
#' @examples
#' \dontrun{
#' 
#'calc_monthly_cumulative_stats(data = flow_data, station_name = "MissionCreek", write_table = TRUE)
#' 
#'calc_monthly_cumulative_stats(data = "08NM116", water_year = TRUE, water_year_start = 8, percentiles = c(1:10))
#'
#' }
#' @export



calc_monthly_cumulative_stats <- function(data = NULL,
                                          dates = Date,
                                          values = Value,
                                          groups = STATION_NUMBER,
                                          percentiles = c(5,25,75,95),
                                          use_yield = FALSE, 
                                          basin_area = NA,
                                          water_year = FALSE,
                                          water_year_start = 10,
                                          start_year = 0,
                                          end_year = 9999,
                                          exclude_years = NULL, 
                                          complete_years = FALSE,
                                          transpose = FALSE,
                                          ignore_missing = TRUE){
  
  
  ## CHECKS ON FLOW DATA
  ## -------------------
  
  # Check if data is provided
  if(is.null(data))   stop("No data provided, must provide a data frame or HYDAT station number(s).")
  if(is.vector(data)) {
    if(!all(data %in% dplyr::pull(tidyhydat::allstations[1]))) 
      stop("One or more stations numbers listed in data argument do not exist in HYDAT. Re-check numbers or provide a data frame of data.")
    flow_data <- suppressMessages(tidyhydat::hy_daily_flows(station_number = data))
  } else {
    flow_data <- data
  }
  if(!is.data.frame(flow_data)) stop("Incorrect selection for data argument, must provide a data frame or HYDAT station number(s).")
  flow_data <- as.data.frame(flow_data) # Getting random 'Unknown or uninitialised column:' warnings if using tibble
  
  # Save the original columns (to check for groups column later) and ungroup
  orig_cols <- names(flow_data)
  flow_data <- dplyr::ungroup(flow_data)
  
  # If no groups (default STATION_NUMBER) in data, make it so (required)
  if(!as.character(substitute(groups)) %in% colnames(flow_data)) {
    flow_data[, as.character(substitute(groups))] <- "XXXXXXX"
  }
  
  # Get the just groups (default STATION_NUMBER), Date, and Value columns
  # This method allows the user to select the Station, Date or Value columns if the column names are different
  if(!as.character(substitute(values)) %in% names(flow_data) & !as.character(substitute(dates)) %in% names(flow_data)) 
    stop("Dates and values not found in data frame. Rename dates and values columns to 'Date' and 'Value' or identify the columns using
         'dates' and 'values' arguments.")
  if(!as.character(substitute(dates)) %in% names(flow_data))  
    stop("Dates not found in data frame. Rename dates column to 'Date' or identify the column using 'dates' argument.")
  if(!as.character(substitute(values)) %in% names(flow_data)) 
    stop("Values not found in data frame. Rename values column to 'Value' or identify the column using 'values' argument.")
  
  # Gather required columns (will temporarily rename groups column as STATION_NUMBER if isn't already)
  flow_data <- flow_data[,c(as.character(substitute(groups)),
                            as.character(substitute(dates)),
                            as.character(substitute(values)))]
  colnames(flow_data) <- c("STATION_NUMBER","Date","Value")
  
  # Check columns are in proper formats
  if(!inherits(flow_data$Date[1], "Date"))  stop("'Date' column in provided data frame does not contain dates.")
  if(!is.numeric(flow_data$Value))          stop("'Value' column in provided data frame does not contain numeric values.")
  
  
  ## CHECKS ON OTHER ARGUMENTS
  ## -------------------------
  
  if(!is.logical(water_year))         stop("water_year argument must be logical (TRUE/FALSE).")
  if(!is.numeric(water_year_start))   stop("water_year_start argument must be a number between 1 and 12 (Jan-Dec).")
  if(length(water_year_start)>1)      stop("water_year_start argument must be a number between 1 and 12 (Jan-Dec).")
  if(!water_year_start %in% c(1:12))  stop("water_year_start argument must be an integer between 1 and 12 (Jan-Dec).")
  
  if(length(start_year)>1)        stop("Only one start_year value can be listed")
  if(!start_year %in% c(0:9999))  stop("start_year must be an integer.")
  if(length(end_year)>1)          stop("Only one end_year value can be listed")
  if(!end_year %in% c(0:9999))    stop("end_year must be an integer.")
  if(start_year > end_year)       stop("start_year must be less than or equal to end_year.")
  
  if(!is.null(exclude_years) & !is.numeric(exclude_years)) stop("List of exclude_years must be numeric - ex. 1999 or c(1999,2000).")
  if(!all(exclude_years %in% c(0:9999)))                   stop("Years listed in exclude_years must be integers.")
  
  if(!is.logical(complete_years))         stop("complete_years argument must be logical (TRUE/FALSE).")
  
  if(!all(is.na(percentiles))){
    if(!is.numeric(percentiles))               stop("percentiles argument must be numeric.")
    if(!all(percentiles>0 & percentiles<100))  stop("percentiles must be > 0 and < 100.")
  }
  
  if(!is.logical(transpose))       stop("transpose argument must be logical (TRUE/FALSE).")
  
  if(!is.logical(ignore_missing))  stop("ignore_missing argument must be logical (TRUE/FALSE).")
  
  if(!is.logical(use_yield))  stop("use_yield argument must be logical (TRUE/FALSE).")
  
  ## SET UP BASIN AREA
  ## -----------------
  
  suppressWarnings(flow_data <- add_basin_area(flow_data, basin_area = basin_area))
  flow_data$Basin_Area_sqkm_temp <- flow_data$Basin_Area_sqkm
  
  
  
  ## PREPARE FLOW DATA
  ## -----------------
  
  # Fill in the missing dates and the add the date variables again
  flow_data <- fill_missing_dates(data = flow_data, water_year = water_year, water_year_start = water_year_start)
  flow_data <- add_date_variables(data = flow_data, water_year = water_year, water_year_start = water_year_start)
  
  # Set selected year-type and day of year, and date columns for analysis
  if (water_year) {
    flow_data$AnalysisYear <- flow_data$WaterYear
  }  else {
    flow_data$AnalysisYear <- flow_data$Year
  }
  
  # Add cumulative flows
  if (use_yield){
    flow_data <- add_cumulative_yield(data = flow_data, water_year = water_year, water_year_start = water_year_start, basin_area = basin_area)
    names(flow_data)[names(flow_data) == "Cumul_Yield_mm"] <- paste("Cumul_Total")
  } else {
    flow_data <- add_daily_volume(data = flow_data, water_year = water_year, water_year_start = water_year_start)
    names(flow_data)[names(flow_data) == "Cumul_Volume_m3"] <- paste("Cumul_Total")
  }
  
  # Filter for the selected and excluded years and leap year values (last day)
  flow_data <- dplyr::filter(flow_data, AnalysisYear >= start_year & AnalysisYear <= end_year)
  flow_data <- dplyr::filter(flow_data, !(AnalysisYear %in% exclude_years))
  
  # Remove incomplete years if selected
  if(complete_years){
    comp_years <- dplyr::summarise(dplyr::group_by(flow_data, STATION_NUMBER, AnalysisYear),
                                   complete_yr = ifelse(sum(!is.na(Value)) == length(AnalysisYear), TRUE, FALSE))
    flow_data <- merge(flow_data, comp_years, by = c("STATION_NUMBER", "AnalysisYear"))
    flow_data <- dplyr::filter(flow_data, complete_yr == "TRUE")
    flow_data <- dplyr::select(flow_data, -complete_yr)
  }
  
  
  ## CALCULATE STATISTICS
  ## --------------------
  
  # Calculate monthly totals for all years
  monthly_data <- dplyr::summarize(dplyr::group_by(flow_data, STATION_NUMBER, AnalysisYear, MonthName),
                                   Monthly_Total = max(Cumul_Total, na.rm = FALSE))
  monthly_data
  # Calculate the monthly and longterm stats
  monthly_cumul <- dplyr::summarize(dplyr::group_by(monthly_data, STATION_NUMBER, MonthName),
                                    Mean = mean(Monthly_Total, na.rm = ignore_missing),
                                    Median = median(Monthly_Total, na.rm = ignore_missing),
                                    Maximum = max(Monthly_Total, na.rm = ignore_missing),
                                    Minimum = min(Monthly_Total, na.rm = ignore_missing))
  
  # Compute daily percentiles (if 10 or more years of data)
  if (!all(is.na(percentiles))){
    for (ptile in percentiles) {
      monthly_ptile <- dplyr::summarise(dplyr::group_by(monthly_data, STATION_NUMBER, MonthName),
                                        Percentile = ifelse(!is.na(mean(Monthly_Total, na.rm = FALSE)) | ignore_missing, 
                                                            quantile(Monthly_Total, ptile / 100, na.rm = TRUE), NA))
      
      names(monthly_ptile)[names(monthly_ptile) == "Percentile"] <- paste0("P", ptile)
      
      # Merge with monthly_cumul
      monthly_cumul <- merge(monthly_cumul, monthly_ptile, by = c("STATION_NUMBER", "MonthName"))
    }
  }
  
  # Rename Month column and reorder to proper levels (set in add_date_vars)
  monthly_cumul <- dplyr::rename(monthly_cumul, Month = MonthName)
  monthly_cumul <- with(monthly_cumul, monthly_cumul[order(STATION_NUMBER, Month),])
  row.names(monthly_cumul) <- c(1:nrow(monthly_cumul))
  
  
  # If transpose if selected, switch columns and rows
  if (transpose) {
    # Get list of columns to order the Statistic column after transposing
    stat_levels <- names(monthly_cumul[-(1:2)])
    
    # Transpose the columns for rows
    monthly_cumul <- tidyr::gather(monthly_cumul, Statistic, Value, -STATION_NUMBER, -Month)
    monthly_cumul <- tidyr::spread(monthly_cumul, Month, Value)
    
    # Order the columns
    monthly_cumul$Statistic <- as.factor(monthly_cumul$Statistic)
    levels(monthly_cumul$Statistic) <- stat_levels
    monthly_cumul <- with(monthly_cumul, monthly_cumul[order(STATION_NUMBER, Statistic),])
  }
  
  # Recheck if station_number was in original flow_data and rename or remove as necessary
  if(as.character(substitute(groups)) %in% orig_cols) {
    names(monthly_cumul)[names(monthly_cumul) == "STATION_NUMBER"] <- as.character(substitute(groups))
  } else {
    monthly_cumul <- dplyr::select(monthly_cumul, -STATION_NUMBER)
  }
  
  
  dplyr::as_tibble(monthly_cumul)
  
  # monthly_cumul$Month <- match(monthly_cumul$Month, month.abb)
  # 
  # # Create the daily stats plots
  # ggplot2::ggplot(monthly_cumul, ggplot2::aes(x = Month)) +
  #   ggplot2::geom_ribbon(ggplot2::aes(ymin = Minimum, ymax = P5, fill = "Min-5th Percentile")) +
  #   ggplot2::geom_ribbon(ggplot2::aes(ymin = P5, ymax = P25, fill = "5th-25th Percentile")) +
  #   ggplot2::geom_ribbon(ggplot2::aes(ymin = P25, ymax = P75, fill = "25th-75th Percentile")) +
  #   ggplot2::geom_ribbon(ggplot2::aes(ymin = P75, ymax = P95, fill = "75th-95th Percentile")) +
  #   ggplot2::geom_ribbon(ggplot2::aes(ymin = P95, ymax = Maximum, fill = "95th Percentile-Max")) +
  #   ggplot2::geom_line(ggplot2::aes(y = Median, colour = "Median"), size = .5) +
  #   ggplot2::geom_line(ggplot2::aes(y = Mean, colour = "Mean"), size = .5) +
  #   ggplot2::scale_fill_manual(values = c("Min-5th Percentile" = "orange" , "5th-25th Percentile" = "yellow",
  #                                         "25th-75th Percentile" = "skyblue1", "75th-95th Percentile" = "dodgerblue2",
  #                                         "95th Percentile-Max" = "royalblue4")) +
  #   ggplot2::scale_color_manual(values = c("Median" = "purple3", "Mean" = "springgreen4")) +
  #   {if (!log_discharge) ggplot2::scale_y_continuous(expand = c(0, 0))} +
  #   {if (log_discharge) ggplot2::scale_y_log10(expand = c(0, 0))} +
  #   {if (log_discharge) ggplot2::annotation_logticks(base= 10, "left", colour = "grey25", size = 0.3,
  #                                                    short = ggplot2::unit(.07, "cm"), mid = ggplot2::unit(.15, "cm"),
  #                                                    long = ggplot2::unit(.2, "cm"))} +
  #   ggplot2::xlab("Month")+
  #   ggplot2::scale_x_continuous(breaks = 1:12, labels = month.abb[1:12], expand = c(0,0)) +
  #   {if (!use_yield) ggplot2::ylab("Cumulative Discharge (cubic metres)")} +
  #   {if (use_yield) ggplot2::ylab("Cumulative Runoff Yield (mm)")} +
  #   ggplot2::theme_bw() +
  #   ggplot2::labs(color = 'Monthly Statistics', fill = "Monthly Ranges") +  
  #   ggplot2::theme(axis.text=ggplot2::element_text(size = 10, colour = "grey25"),
  #                  axis.title=ggplot2::element_text(size = 12, colour = "grey25"),
  #                  axis.title.y=ggplot2::element_text(margin = ggplot2::margin(0,0,0,0)),
  #                  axis.ticks = ggplot2::element_line(size = .1, colour = "grey25"),
  #                  axis.ticks.length=ggplot2::unit(0.05, "cm"),
  #                  panel.border = ggplot2::element_rect(colour = "black", fill = NA, size = 1),
  #                  panel.grid.minor = ggplot2::element_blank(),
  #                  panel.grid.major = ggplot2::element_line(size = .1),
  #                  panel.background = ggplot2::element_rect(fill = "grey94"),
  #                  legend.text = ggplot2::element_text(size = 9, colour = "grey25"),
  #                  legend.box = "vertical",
  #                  legend.justification = "top",
  #                  legend.key.size = ggplot2::unit(0.4, "cm"),
  #                  legend.spacing = ggplot2::unit(0, "cm")) +
  #   ggplot2::guides(colour = ggplot2::guide_legend(order = 1), fill = ggplot2::guide_legend(order = 2))
  # 
  # 
  # 
}