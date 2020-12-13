## connect to ADO DB
# remotes::install_github("KKulma/intensegRid")
library(DBI)
library(keyring)
library(intensegRid)
library(dplyr)
library(lubridate)
library(logger)

### secure db credentials
## checkout https://db.rstudio.com/best-practices/managing-credentials/ for details
# keyring::key_set(service = "national-grid-data",
#                  username = "national-grid-shiny")

log_info("calling credentials")
myusername <- keyring::key_list("national-grid-data")[1, 2]

log_info("connecting ot db")
con <- DBI::dbConnect(
  odbc::odbc(),
  Driver    = "SQL Server",
  Server    = "national-grid-server.database.windows.net",
  Database  = "naitonal-grid-data",
  UID       = myusername,
  PWD       = keyring::key_get("national-grid-data", myusername),
  Port      = 1433
)

## national CI
log_info("checking if the data alredy exists in the db")
start <- today() - days(1)
end <- start

res <-
  dbGetQuery(con,
             "select MAX([to]) as max_to FROM national_ci_data")

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
