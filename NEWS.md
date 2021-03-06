fasstr 0.2.7
=========================

Updated: 27 September 2018

#### New:

  * compute_frequency_analysis() function to calculate a frequency analysis with custom data (update other frequency analysis functions to use this function internally)
  * Vignettes completed:
      * Users Guide
      * Full Analysis Guide
      * Trends Analysis Guide
      * Frequency Analysis Guide
      * Under the Hood

#### Updates:

  * frequency analysis updates:
      * option to plot the computed curve or not
      * changed the names of the outputted objects
      * changed the measure names (rolling-day names of the annual_freq analysis (ex from Q007-day-avg to 7-Day))
      * All parameter documentation info in the compute_frequency_analysis function
      * updated full_analysis to include new changes
  * Completed Users Guide vignette
  * Completed Full Analysis vignette
  * Completed Frequency Analysis Vignette
  * Updated filetype argument in the write_ functions
  * Updated some plot object names
  
#### Bug Fixes

  * Added trendline to trends plots in compute_full_analysis
  
  
fasstr 0.2.6
=========================

Updated: 28 June 2018

#### New:

  * plot_annual_means() function to plot annual mean and long-term means
    
#### Updates:

  * Axes breaks and ticks on most plots
  * Renamed compute_frequency_stat() to compute_frequency_quantile()
  * calc_ and plot_annual_stats, compute_frequency description updates
  * Renamed Timeseries folder to Screening in compute_full_analysis() function
  * README Updates
  * Vignettes (renamed full_analysis)
  

fasstr 0.2.5.1
=========================

Updated: 19 June 2018

* Fixed write_objects_list to save in folder it creates
* Fixed calc_daily_stats to remove partial data years

fasstr 0.2.5
=========================

Updated: 18 June 2018

#### New:

  * New write_objects_list() function to write all plots and tables from a list of objects (help with frquency analysis writing)
  * Added vignettes:
    * 'fasstr' Users Guide (to be completed)
    * Trending Analysis Guide (to be completed)
    * Volume Frequency Analysis Guide (to be completed)
    * Under the Hood (to be completed)
    
#### Major Function Updates:

  * Renamed write_full_analysis to compute_full_analysis which creates a list object with all results with option to write everything. Fixed various bugs and issues.
  * Joined compute_annual_trends and plot_annual_trends.  It now consists of a list with a tibble of annual data, a tibble of trending results, and all trending plots
  * Added 'months' argument to calc_long_term() and all screening and missing data functions; also an include_longterm argument for longterm to choose whether to include or not
  
#### Other Updates:

  * Fixed bug where 'groups' column was not kept in resulting tibble, and add_basin_area(), add_rolling_means()
  * Removed Nan and Inf values from calc_monthly_stats when no data existed for a month
  * Plots of longterm_stats, daily_stats, and flow_duration plot nothing (instead of error) if all data is NA
  * Updated documentation for some functions
  * Removed colour brewer Set1 on some annual plots due to a lack of colours in set


fasstr 0.2.4
=========================

Updated: 8 May 2018

  * Fixed bug where groups function did not work if not "STATION_NUMBER"
  * Added warning if not all dates are dates in column
  * Added references in annual_flow_timing() and trending functions
  * Added 'See Also' documentation for many related functions
  * Removed error from daily and monthly cumulative stats/plots with no basin area (now produces NA)
  * Updated write_full_analysis so no section 7 is completed with insufficient data
  

fasstr 0.2.3
=========================

Updated: 17 April 2018

  * Updated write_full_analysis() documentation

fasstr 0.2.2
=========================

Updated: 17 April 2018

  * Added write_full_analysis() function to write almost almost all plots and tables in a folder
  * Added some interal checks functions
  

fasstr 0.2.1
=========================

Updated: 13 April 2018

  * Reformatted examples script in testing folder as a temporary help document until a vignette is built
  * Moved the previous examples script to a new testing script in the same folder



fasstr 0.2.0
=========================

Updated: 9 April 2018

### NEW FEATURES
  * Summarize and plot by multiple groups (ex. stations) 
  * Selecting columns of dates, values, and groupings (ex. station numbers) when using 'data' argument
  * Exported data frames are tibbles
  * Exported plots ('gg' class) are within lists (multiple plots are produced with many plot_ functions)
  * Updated plot formatting
  * More functions utilizing rolling average days
  * More filtering arguments for some functions (months, complete_years)
  * 'na' argument is now 'ignore_missing' with default of FALSE for all functions
  * Additional write_, calc_, add_, compute_, and plot_ functions
  * Renaming of some functions
  * Exports pipe operator, %>%, to facilitate tidy analyses
  
### REMOVED FEATURES
  * Choice for writing within functions - moved to their own write_ data and plot functions

### INTERNAL IMPROVEMENTS
  * Reformatted internal structure, including adding internal functions for efficiency and argument checks
  * Used @Inheritparams to simplify documentation
 


fasstr 0.1.0
=========================

Updated: 9 Dec 2017

* Initial package beta version
* Use HYDAT argument to extract HYDAT data using 'tidyhydat' package
* Included add_, calc_, compute_, and plot_functions
* Included README with basic examples