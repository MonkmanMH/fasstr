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

#' @title Write all data frames and plots from a list of objects into a directory
#'
#' @description Write a list of tables (data.frames) and plots (ggplots; as used by fasstr ) into a directory. Objects that are not
#'    class "data.frame" or "gg" will not be saved. Each table and plot will be named by the object name in the list.
#'
#' @param list List of data frames and plots to write to disk.
#' @param foldername Name of folder to create on disk (if it does not exist) to write each plot from list. 
#'    If using \code{combined_pdf} argument, then it will be the name of the PDF document.
#' @param table_filetype Table file type to write. One of "csv", "xls", or "xslx".
#' @param plot_filetype Image type to write. One of "png", "eps", "ps", "tex", "pdf", "jpeg", "tiff", "bmp", or "svg".
#'    Image type will be overwritten if using \code{combined_pdf} is used.
#' @param width Numeric plot width in \code{units}. If not supplied, uses the size of current graphics device.
#' @param height Numeric plot height in \code{units}. If not supplied, uses the size of current graphics device.
#' @param units Character string plot height and width units, one of "in", "cm", or "mm". Default \code{"in"}.
#' @param dpi Numeric resolution of plots. Default \code{300}.
#'
#' @examples
#' \dontrun{
#' 
#' write_objects_list()
#' 
#' }
#' @export

write_objects_list <- function(list = NULL,
                               foldername = "",
                               table_filetype = NULL, 
                               plot_filetype = NULL, 
                               width = NA,
                               height = NA,
                               units = "in",
                               dpi = 300){
  
  # ARGUMENT CHECKS
  # ---------------
  
  # Check list of plots
  if (is.null(list)) stop("Must provide a list.", call. = FALSE)
  if (!is.list(list)) stop("Object provided is a not a list.", call. = FALSE)
  
  for (i in names(list)) {
    if (inherits( list[[i]], what = "data.frame")) {
      
      if (is.null(table_filetype))  stop("Must provide an table type to save using the table_filetype argument. One of 'csv', 'xls', or 'xlsx'.", call. = FALSE)
      
    } else if (inherits(list[[i]], what = "gg")) {
      
      if (is.null(plot_filetype)) stop("Must provide an image type to save using the plot_filetype argument. Once of 'png', 'eps', 'ps', 'tex', 'pdf', 'jpeg', 'tiff', 'bmp', or 'svg'.", call. = FALSE)
      if (!plot_filetype %in% c("png", "eps", "ps", "tex", "pdf", "jpeg", "tiff", "bmp", "svg")) 
        stop("Use of the file types required.", call. = FALSE)
      
      
      # Check dimensions
      if ((!is.na(height) & !is.numeric(height)))
        stop("height argument must be numeric.", call. = FALSE)
      if (length(height) !=1) stop("Only one height value can be provided.", call. = FALSE)
      
      if ((!is.na(width) & !is.numeric(width)))
        stop("width argument must be numeric.", call. = FALSE)
      if (length(width) !=1) stop("Only one width value can be provided.", call. = FALSE)
      
      if (length(units) != 1)  stop("only one unit type can be provided.", call. = FALSE)
      if (!units %in% c("in", "cm", "mm"))  stop("Only units of 'in', 'cm', or 'mm' can be provided.", call. = FALSE)
      
    } 
  }
  
  
  
  
  # SAVE PLOTS
  # ----------
  
  # Create a folder of plots
  
  # Check if folder exists, create if not
  dir.create(foldername, showWarnings = FALSE)
  
  # Add the slash to foldername if it doesn't exist
  if (!substr(foldername, nchar(foldername), nchar(foldername)) == "/") {
    foldername <- paste0(foldername, "/")
  }
  
  for (i in names(list)) {
    if (inherits( list[[i]], what = "gg")) {
      ggplot2::ggsave(filename = paste0(foldername, i, ".", plot_filetype), 
                      plot = list[[i]],
                      width = width,
                      height = height,
                      units = units,
                      dpi = dpi)
    } else if (inherits(list[[i]], what = "data.frame")) {
      write_results(data = list[[i]], 
                    file = paste0(foldername, i, ".", table_filetype))
    } else {
      warning(paste0("Object in list, ", as.character(substitute(list)), "$", i, ", is not a ggplot or data frame object and was not saved."), call. = FALSE)
    }
  }
  
  message(paste0("Successfully created folder ", foldername, " with all plots and tables."))
  
  
  
  
  
  
}

