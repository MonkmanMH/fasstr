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

#' @title Plot cumulative daily flow statistics
#' 
#' @description Plot the daily cumulative mean, median, maximum, minimum, and 5, 25, 75, 95th percentiles for each day of the year 
#'    from a streamflow dataset. Plots the statistics from all daily cumulative values from all years, unless specified. 
#'    Data calculated using calc_daily_cumulative_stats() function. Can plot individual years for comparision using the 
#'    include_year argument. Defaults to volumetric cumulative flows, can use \code{use_yield} and \code{basin_area} to convert to 
#'    runoff yield.
#'
#' @inheritParams calc_daily_cumulative_stats
#' @inheritParams plot_daily_stats
#'    
#' @return A list of ggplot2 objects with the following for each station provided:
#'   \item{Daily_Cumulative_Stats}{a plot that contains daily cumulative flow statistics}
#'   Default plots on each object:   
#'   \item{Mean}{daily cumulative mean}
#'   \item{Median}{daily cumulative median}
#'   \item{Min-5 Percentile Range}{a ribbon showing the range of data between the daily cumulative minimum and 5th percentile}
#'   \item{5-25 Percentiles Range}{a ribbon showing the range of data between the daily cumulative 5th and 25th percentiles}
#'   \item{25-75 Percentiles Range}{a ribbon showing the range of data between the daily cumulative 25th and 75th percentiles}
#'   \item{75-95 Percentiles Range}{a ribbon showing the range of data between the daily cumulative 75th and 95th percentiles}
#'   \item{95 Percentile-Max Range}{a ribbon showing the range of data between the daily cumulative 95th percentile and the maximum}
#'   \item{'Year' Flows}{(optional) the daily cumulative flows for the designated year}
#'   
#' @seealso \code{\link{calc_daily_cumulative_stats}}
#'   
#' @examples
#' \dontrun{
#' 
#' plot_daily_cumulative_stats(station_number = "08NM116", 
#'                             water_year = TRUE,
#'                            water_year_start = 8)
#'
#' }
#' @export



plot_daily_cumulative_stats <- function(data = NULL,
                                        dates = Date,
                                        values = Value,
                                        groups = STATION_NUMBER,
                                        station_number = NULL,
                                        use_yield = FALSE, 
                                        basin_area = NA,
                                        water_year = FALSE,
                                        water_year_start = 10,
                                        start_year = 0,
                                        end_year = 9999,
                                        exclude_years = NULL, 
                                        log_discharge = FALSE,
                                        include_title = FALSE,
                                        include_year = NULL){
  
  ## ARGUMENT CHECKS
  ## ---------------
  
  log_discharge_checks(log_discharge) 
  include_year_checks(include_year)
  include_title_checks(include_title)  
  
  
  ## FLOW DATA CHECKS AND FORMATTING
  ## -------------------------------
  
  # Check if data is provided and import it
  flow_data <- flowdata_import(data = data, station_number = station_number)
  
  # Check and rename columns
  flow_data <- format_all_cols(data = flow_data,
                               dates = as.character(substitute(dates)),
                               values = as.character(substitute(values)),
                               groups = as.character(substitute(groups)),
                               rm_other_cols = TRUE)
  
  
  if (water_year) {
    # Create origin date to apply to flow_data and Q_daily later on
    if (water_year_start==1)         {origin_date <- as.Date("1899-12-31")
    } else if (water_year_start==2)  {origin_date <- as.Date("1899-01-31")
    } else if (water_year_start==3)  {origin_date <- as.Date("1899-02-28")
    } else if (water_year_start==4)  {origin_date <- as.Date("1899-03-31")
    } else if (water_year_start==5)  {origin_date <- as.Date("1899-04-30")
    } else if (water_year_start==6)  {origin_date <- as.Date("1899-05-31")
    } else if (water_year_start==7)  {origin_date <- as.Date("1899-06-30")
    } else if (water_year_start==8)  {origin_date <- as.Date("1899-07-31")
    } else if (water_year_start==9)  {origin_date <- as.Date("1899-08-31")
    } else if (water_year_start==10) {origin_date <- as.Date("1899-09-30")
    } else if (water_year_start==11) {origin_date <- as.Date("1899-10-31")
    } else if (water_year_start==12) {origin_date <- as.Date("1899-11-30")}
  }  else {
    origin_date <- as.Date("1899-12-31")
  }
  
  ## CALC STATS
  ## ----------
  
  daily_stats <- calc_daily_cumulative_stats(data = flow_data,
                                             percentiles = c(5,25,75,95),
                                             use_yield = use_yield, 
                                             basin_area = ifelse(use_yield, basin_area, 0),
                                             water_year = water_year,
                                             water_year_start = water_year_start,
                                             start_year = start_year,
                                             end_year = end_year,
                                             exclude_years = exclude_years)
  
 
  
  daily_stats <- dplyr::mutate(daily_stats, Date = as.Date(DayofYear, origin = origin_date))
  daily_stats <- dplyr::mutate(daily_stats, AnalysisDate = Date)
  
  
  ## ADD YEAR IF SELECTED
  ## --------------------
  
  if(!is.null(include_year)){
    
    year_data <- fill_missing_dates(data = flow_data, water_year = water_year, water_year_start = water_year_start)
    year_data <- add_date_variables(data = year_data, water_year = water_year, water_year_start = water_year_start)
    
    # Add cumulative flows
    if (use_yield){
      year_data <- add_cumulative_yield(data = year_data, water_year = water_year, water_year_start = water_year_start, basin_area = basin_area)
      year_data$Cumul_Flow <- year_data$Cumul_Yield_mm
    } else {
      year_data <- add_cumulative_volume(data = year_data, water_year = water_year, water_year_start = water_year_start)
      year_data$Cumul_Flow <- year_data$Cumul_Volume_m3
    }
    
    if (water_year) {
      year_data$AnalysisYear <- year_data$WaterYear
      year_data$AnalysisDoY <- year_data$WaterDayofYear
    }  else {
      year_data$AnalysisYear <- year_data$Year
      year_data$AnalysisDoY <- year_data$DayofYear
    }
    year_data <- dplyr::mutate(year_data, AnalysisDate = as.Date(AnalysisDoY, origin = origin_date))
    year_data <- dplyr::filter(year_data, AnalysisYear >= start_year & AnalysisYear <= end_year)
    year_data <- dplyr::filter(year_data, !(AnalysisYear %in% exclude_years))
    year_data <- dplyr::filter(year_data, AnalysisDoY < 366)
    
    year_data <- dplyr::filter(year_data, AnalysisYear == include_year)
    
    year_data <- dplyr::select(year_data, STATION_NUMBER, AnalysisDate, Cumul_Flow)
    
    # Add the daily data from include_year to the daily stats
    daily_stats <- dplyr::left_join(daily_stats, year_data, by = c("STATION_NUMBER", "AnalysisDate"))
    
    # Warning if all daily values are NA from the include_year
    for (stn in unique(daily_stats$STATION_NUMBER)) {
      year_test <- dplyr::filter(daily_stats, STATION_NUMBER == stn)
      
      if(all(is.na(daily_stats$Cumul_Flow)))
        warning("Daily data does not exist for the year listed in include_year and was not plotted.", call. = FALSE)
    }
    
  } 
    
  daily_stats[is.na(daily_stats)] <- 0

  ## PLOT STATS
  ## ----------

  # Create the daily stats plots
  daily_plots <- dplyr::group_by(daily_stats, STATION_NUMBER)
  daily_plots <- tidyr::nest(daily_plots)
  daily_plots <- dplyr::mutate(daily_plots,
                               plot = purrr::map2(data, STATION_NUMBER,
       ~suppressMessages(
         suppressWarnings(
           ggplot2::ggplot(., ggplot2::aes(x = AnalysisDate)) +
             ggplot2::geom_ribbon(ggplot2::aes(ymin = Minimum, ymax = P5, fill = "Min-5th Percentile")) +
             ggplot2::geom_ribbon(ggplot2::aes(ymin = P5, ymax = P25, fill = "5th-25th Percentile")) +
             ggplot2::geom_ribbon(ggplot2::aes(ymin = P25, ymax = P75, fill = "25th-75th Percentile")) +
             ggplot2::geom_ribbon(ggplot2::aes(ymin = P75, ymax = P95, fill = "75th-95th Percentile")) +
             ggplot2::geom_ribbon(ggplot2::aes(ymin = P95, ymax = Maximum, fill = "95th Percentile-Max")) +
             ggplot2::geom_line(ggplot2::aes(y = Median, colour = "Median"), size = .7) +
             ggplot2::geom_line(ggplot2::aes(y = Mean, colour = "Mean"), size = .7) +
             ggplot2::scale_fill_manual(values = c("Min-5th Percentile" = "orange" , "5th-25th Percentile" = "yellow",
                                                   "25th-75th Percentile" = "skyblue1", "75th-95th Percentile" = "dodgerblue2",
                                                   "95th Percentile-Max" = "royalblue4")) +
             ggplot2::scale_color_manual(values = c("Median" = "purple3", "Mean" = "springgreen4")) +
             {if (!log_discharge) ggplot2::scale_y_continuous(expand = c(0, 0), breaks = scales::pretty_breaks(n = 7))} +
             {if (log_discharge) ggplot2::scale_y_log10(expand = c(0, 0), breaks = scales::log_breaks(n = 8, base = 10) )} +
             {if (log_discharge) ggplot2::annotation_logticks(base= 10, "left", colour = "grey25", size = 0.3,
                                                              short = ggplot2::unit(.07, "cm"), mid = ggplot2::unit(.15, "cm"),
                                                              long = ggplot2::unit(.2, "cm"))} +
             ggplot2::scale_x_date(date_labels = "%b", date_breaks = "1 month",
                                   limits = as.Date(c(NA, as.character(max(daily_stats$AnalysisDate)))), expand=c(0, 0)) +
             ggplot2::xlab("Day of Year")+
             {if (!use_yield) ggplot2::ylab("Cumulative Discharge (cubic metres)")} +
             {if (use_yield) ggplot2::ylab("Cumulative Runoff Yield (mm)")} +
             ggplot2::theme_bw() +
             ggplot2::labs(color = 'Daily Statistics', fill = "Daily Ranges") +
             {if (include_title & .y != "XXXXXXX") ggplot2::labs(color = paste0(.y,'\n \nDaily Statistics'), fill = "Daily Ranges") } +
             ggplot2::theme(axis.text = ggplot2::element_text(size = 10, colour = "grey25"),
                            axis.title = ggplot2::element_text(size = 12, colour = "grey25"),
                            axis.title.y = ggplot2::element_text(margin = ggplot2::margin(0,0,0,0)),
                            axis.ticks = ggplot2::element_line(size = .1, colour = "grey25"),
                            axis.ticks.length = ggplot2::unit(0.05, "cm"),
                            panel.border = ggplot2::element_rect(colour = "black", fill = NA, size = 1),
                            panel.grid.minor = ggplot2::element_blank(),
                            panel.grid.major = ggplot2::element_line(size = .1),
                            panel.background = ggplot2::element_rect(fill = "grey94"),
                            legend.text = ggplot2::element_text(size = 9, colour = "grey25"),
                            legend.box = "vertical",
                            legend.justification = "top",
                            legend.key.size = ggplot2::unit(0.4, "cm"),
                            legend.spacing = ggplot2::unit(0, "cm")) +
             ggplot2::guides(colour = ggplot2::guide_legend(order = 1), fill = ggplot2::guide_legend(order = 2)) +
             {if (is.numeric(include_year)) ggplot2::geom_line(ggplot2::aes(y = Cumul_Flow, colour = "yr.colour"), size = 0.7) } +
             {if (is.numeric(include_year)) ggplot2::scale_color_manual(values = c("Mean" = "paleturquoise", "Median" = "dodgerblue4", "yr.colour" = "red"),
                                                                        labels = c("Mean", "Median", paste0(include_year, " Flows"))) }
         ))))



  # Create a list of named plots extracted from the tibble
  plots <- daily_plots$plot
  if (nrow(daily_plots) == 1) {
    names(plots) <- paste0(ifelse(use_yield, "Daily_Cumulative_Yield_Stats", "Daily_Cumulative_Volumetric_Stats"))
  } else {
    names(plots) <- paste0(daily_plots$STATION_NUMBER, ifelse(use_yield, "_Daily_Cumulative_Yield_Stats", "_Daily_Cumulative_Volumetric_Stats"))
  }

 plots

}

