## connect to ADO DB
library(DBI)
library(intensegRid)
library(dplyr)
library(lubridate)
library(logger)

log_info("connecting ot db")
con <- DBI::dbConnect(
  odbc::odbc(),
  Driver    = "SQL Server",
  Server    = "national-grid-server.database.windows.net",
  Database  = "naitonal-grid-data",
  UID       = Sys.getenv("UID"),
  PWD       = Sys.getenv("PWD"),
  Port      = 1433
)

# db data check
log_info("checking if the data alredy exists in the db")

res <-
  dbGetQuery(con,
             "select MAX([to]) as max_to FROM national_ci_data")

## national CI
start <- today() - days(1)
end <- start


if (!all(as_date(res$max_to) == start)) {
  log_info("pull data from the API")
  
  intense_data <- get_national_ci(start = start, end = end)
  
  log_info("write new data to the db")
  if (!is.null(intense_data)) {
    dbWriteTable(con, "national_ci_data", intense_data, append = TRUE)
  }
}

log_info("disconnect from the db")
dbDisconnect(con)

# log_info("send log in the email")

# recent_data <- dbReadTable(con, "national_ci_data")
# unique_recent_data <- unique(recent_data)
# identical(recent_data, unique_recent_data)
# recent_data$from %>% as_date() %>% unique()
# dbWriteTable(con, "national_ci_data", unique_recent_data, overwrite = TRUE)
