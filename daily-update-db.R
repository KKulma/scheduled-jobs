## connect to ADO DB
# library(DBI)
# library(intensegRid)
 library(dplyr)
# library(lubridate)
# library(logger)

logger::log_info("connecting to db")
con <- DBI::dbConnect(
  odbc::odbc(),
  Driver    = "ODBC Driver 17 for SQL Server",
  Server    = "national-grid-server.database.windows.net",
  Database  = "naitonal-grid-data",
  UID       = "national-grid-shiny",
  PWD       = Sys.getenv("MYPASS"),
  Port      = 1433
)

# db data check
logger::log_info("checking if the data alredy exists in the db")


transform_ci <- function(raw) {
  raw %>%
    dplyr::mutate(from_dt = lubridate::as_date(from),
                  is_renewable = dplyr::if_else(fuel %in% c("nuclear", "hydro", "solar", "wind"), 1, 0)) %>%
    dplyr::filter(is_renewable == 1) %>%
    dplyr::group_by(from, from_dt, regionid, dnoregion, shortname) %>%
    dplyr::summarise(total_perc = sum(perc)) %>% # calculate renewable perc by 1/2 hour interval
    dplyr::group_by(from_dt, regionid, dnoregion, shortname) %>%
    dplyr::summarise(renewable_perc = mean(total_perc)) %>%
    dplyr::ungroup()
}

#national CI
start <- lubridate::today() - lubridate::days(1)
end <- start


logger::log_info("pull data from the API")

intense_data <-
  intensegRid::get_national_ci(start = start, end = end)

logger::log_info("write new data to the db")
if (!is.null(intense_data)) {
  # export 1/2-hourly data
  DBI::dbWriteTable(con, "national_ci_data", intense_data, append = TRUE)
  # export daily summary
  new_entries = transform_ci(intense_data)
  DBI::dbWriteTable(con, "daily_ci_data", new_entries, append = TRUE)
}


logger::log_info("disconnect from the db")
DBI::dbDisconnect(con)
