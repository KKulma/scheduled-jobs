FROM ubuntu:18.04

# Install tzdata and configure Timezone
# We do this in the first place to make sure tzdata will not stop R installation
RUN export DEBIAN_FRONTEND=noninteractive
RUN apt-get update -y && apt-get install -y tzdata
RUN ln -fs /usr/share/zoneinfo/America/New_York /etc/localtime
RUN dpkg-reconfigure --frontend noninteractive tzdata

# Install R
# Some of these packages such as apt-utils, apt-transport-https or gnupg2 are required so that the R repo can be added and R installed
# Note that the R repo is specific for the Linux distro (Ubuntu 18.04 aka bionic in this case)
# Other packages such as curl will be used later to install ODBC
RUN apt-get update -y && apt-get install -y build-essential curl libssl1.0.0 libssl-dev gnupg2 software-properties-common dirmngr apt-transport-https apt-utils lsb-release ca-certificates
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E298A3A825C0D65DFD57CBB651716619E084DAB9
RUN add-apt-repository 'deb https://cloud.r-project.org/bin/linux/ubuntu bionic-cran35/'
RUN apt-get update -y && apt-get install -y r-base

# See about installing ODBC drivers here: https://docs.microsoft.com/en-us/sql/connect/odbc/linux-mac/installing-the-microsoft-odbc-driver-for-sql-server?view=sql-server-2017
# Note that the driver version installed needs to match the version used in the code
# In this case for Ubuntu 18.04: ODBC SQL driver 17
RUN curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add -
RUN curl https://packages.microsoft.com/config/ubuntu/18.04/prod.list > /etc/apt/sources.list.d/mssql-release.list
RUN apt-get update -y
RUN ACCEPT_EULA=Y apt-get install -y msodbcsql17 unixodbc-dev mssql-tools

# copy R scripts and install dependencies 
RUN R -e "install.packages(c('DBI','odbc','intensegRid','dplyr','lubridate','logger'))"
#COPY r-setup.R .
COPY daily-update-db.R .

#RUN Rscript r-setup.R

# Copy and execute R script
CMD R -e "source('daily-update-db.R')"

