# scheduled-jobs

It's a workflow that pulls the Carbon Intensity data from the National Grid's Carbon Intensity API and pushes it to the SQL Server Database hosted on Azure. 
It is scheduled daily using GiHub Actions that run a Docker container with pre-built R and SQL Server Drivers and the R script performing data processing. 
