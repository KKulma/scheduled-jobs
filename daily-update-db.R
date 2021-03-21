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

#national CI
start <- lubridate::today() - lubridate::days(1)
end <- start


logger::log_info("pull data from the API")

intense_data <-
  intensegRid::get_national_ci(start = start, end = end)

logger::log_info("write new data to the db")
if (!is.null(intense_data)) {
  # export 1/2-hourly data
  DBI::dbWriteTable(con, "raw_ci_by_country", intense_data, append = TRUE)
}


logger::log_info("disconnect from the db")
DBI::dbDisconnect(con)
