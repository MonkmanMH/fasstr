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

#' @title Write plots from a list into a directory or PDF document
#'
#' @description Write a list of plots (ggplots; as used by fasstr ) into a directory or PDF document. 
#'    When writing into a named directory each plot will be named by the plot name listed in the list; uses ggplot2::ggsave function.
#'    When writing into a PDF document (\code{combined_pdf == TRUE}) the plot names will not appear; uses grDevices:pdf function.
#'
#' @param plots List of plots to write to disk.
#' @param foldername Name of folder to create on disk (if it does not exist) to write each plot from list. 
#'    If using \code{combined_pdf} argument, then it will be the name of the PDF document.
#' @param plot_filetype Image type to write. One of "png", "eps", "ps", "tex", "pdf", "jpeg", "tiff", "bmp", or "svg".
#'    Image type will be overwritten if using \code{combined_pdf} is used.
#' @param width Numeric plot width in \code{units}. If not supplied, uses the size of current graphics device.
#' @param height Numeric plot height in \code{units}. If not supplied, uses the size of current graphics device.
#' @param units Character string plot height and width units, one of "in", "cm", or "mm". Default \code{"in"}.
#' @param dpi Numeric resolution of plots. Default \code{300}.
#' @param combined_pdf Logical value indicating whether to combine list of plots into one pdf document. Default \code{FALSE}.
#'
#' @examples
#' \dontrun{
#' 
#' write_plots()
#' 
#' }
#' @export

write_plots <- function(plots = NULL,
                        foldername = "",
                        plot_filetype = NULL, 
                        width = NA,
                        height = NA,
                        units = "in",
                        dpi = 300,
                        combined_pdf = FALSE){
  
  # ARGUMENT CHECKS
  # ---------------
  
  # Check list of plots
  if (is.null(plots)) stop("Must provide a list of plots.", call. = FALSE)
  if (!is.list(plots)) stop("Object provided is a not a list.", call. = FALSE)
  if (!all(sapply(plots, inherits, what = "gg"))) stop("Not all objects in list are plots.", call. = FALSE)
  
  # Check device type
  if (!combined_pdf) {
    if (is.null(plot_filetype)) stop("Must provide an image plot_filetype to save.", call. = FALSE)
    if (!plot_filetype %in% c("png", "eps", "ps", "tex", "pdf", "jpeg", "tiff", "bmp", "svg")) 
      stop("Use of the file types required.", call. = FALSE)
  }
  
  # Check dimensions
  if ((!is.na(height) & !is.numeric(height)))
    stop("height argument must be numeric.", call. = FALSE)
  if (length(height) !=1) stop("Only one height value can be provided.", call. = FALSE)
  
  if ((!is.na(width) & !is.numeric(width)))
    stop("width argument must be numeric.", call. = FALSE)
  if (length(width) !=1) stop("Only one width value can be provided.", call. = FALSE)
  
  if (length(units) != 1)  stop("only one unit type can be provided.", call. = FALSE)
  if (!units %in% c("in", "cm", "mm"))  stop("Only units of 'in', 'cm', or 'mm' can be provided.", call. = FALSE)
  
  
  # SAVE PLOTS
  # ----------
  
  # Create a single PDF document
  if(combined_pdf) { 
    
    # Remove slash if foldername ends with it
    if (substr(foldername, nchar(foldername), nchar(foldername)) == "/") {
      foldername <- substr(foldername, 1, nchar(foldername)-1)
    }
    
    # Check dimensions for PDF device
    if(is.na(width)) {
      width <- grDevices::dev.size(units = units)[1]
    }
    
    if(is.na(height)) {
      height <- grDevices::dev.size(units = units)[2]
    }
    
    # Plot plots to PDF device
    grDevices::pdf(file = paste0(foldername, ".pdf"), 
                   width = width, 
                   height = height,
                   title = "R Graphics Output - fasstr")
    for (i in names(plots)) {
      suppressWarnings(graphics::plot(plots[[i]]))
    }
    invisible(grDevices::dev.off())
    
    message(paste0("Successfully created PDF file ", foldername, ".pdf with all plots."))
    
    
  } else {
    
    # Create a folder of plots
    
    # Check if folder exists, create if not
    dir.create(foldername, showWarnings = FALSE)
    
    # Add the slash to foldername if it doesn't exist
    if (!substr(foldername, nchar(foldername), nchar(foldername)) == "/") {
      foldername <- paste0(foldername, "/")
    }
    
    # Filter through each plot
    for (i in names(plots)) {
      suppressWarnings(ggplot2::ggsave(filename = paste0(foldername, i, ".", plot_filetype), 
                                       plot = plots[[i]],
                                       width = width,
                                       height = height,
                                       units = units,
                                       dpi = dpi))
    }
    
    message(paste0("Successfully created folder ", foldername, " with all plots."))
    
    
  }
  
  
  
}

