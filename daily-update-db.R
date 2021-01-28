## connect to ADO DB
# library(DBI)
# library(intensegRid)
# library(dplyr)
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

# res <-
#   DBI::dbGetQuery(con,
#              "select MAX([to]) as max_to FROM national_ci_data")
# 
# all_dates <-
#   DBI::dbGetQuery(con,
#              "select DISTINCT [to] as unique_to FROM national_ci_data")

#national CI
start <- lubridate::today() - lubridate::days(1)
end <- start

if (!all(lubridate::as_date(res$max_to) == start)) {
  logger::log_info("pull data from the API")
  
  intense_data <- intensegRid::get_national_ci(start = start, end = end)
  
  logger::log_info("write new data to the db")
  if (!is.null(intense_data)) {
    DBI::dbWriteTable(con, "national_ci_data", intense_data, append = TRUE)
  }
} else {
  logger::log_info("data already exists on DB")
}

logger::log_info("disconnect from the db")
DBI::dbDisconnect(con)
