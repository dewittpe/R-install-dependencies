################################################################################
# file: build-dep-list.R
#
# This script is used to get the source (.tar.gz) files for R packages and
# recursive dependencies so that the source files can be transfered to, and
# installed on, machines without internet access.
#
# The result of this script will place source files (.tar.gz) for the packages,
# and the package dependencies, and dependencies of dependencies, and so on, in
# the pkg-source-files directory.
#
# A makefile will be generated to install the packages.
#
# Moving the pkg-source-files directory, and the makefile via FTP
# to the target machine should be sufficient for installing on that machine,
# assuming that R and GNU make have been successfully installed on that machine.
#
# This script is expected to be evaluated from the command line via:
#
#   Rscript --vanilla build-dep-list.R [pkg1] [pkg2] [...] [pkgn]
#
# Where pkg1 is the name of the first known package to download, pkg2 the second
# known package to download, ..., and pkgn the nth package to download.  The
# script will download all the dependencies for pkg1, ..., pkgn, and the
# dependencies of the dependencies, and so on.
#
# Alternatively,
#
#  Rscript --vanilla build-dep-list.R needed-pkgs.txt
#
# where needed-pkgs.txt is a file listing the pkg1, pkg2, ..., pkgn.
#
# **EXAMPLE** you need the following three packages:
#
# 1. ggplot2
# 2. qwraps2
# 3. data.table
#
# One way to do this:
#
#     Rscript --vanilla build-dep-list.R ggplot2 qwraps2 data.table
#
# or
#
#    echo -e "ggplot2\nqwraps2\ndata.table" > needed-pkgs.txt
#    Rscript --vanilla build-dep-list.R needed-pkgs.txt
#
################################################################################

# For testing and development, use a subset of packages.  If this script is
# called as noted above then the command line args will be used.
if (interactive()) {
  OUR_PACKAGES <- c("graph", "gRbase", "gRain", "jsonlite", "plotly", "SHELF",
                    "rjson", "svglite", "magrittr")
} else {
  OUR_PACKAGES <- commandArgs(trailingOnly = TRUE)
  if (file.exists(OUR_PACKAGES[1])) {
    OUR_PACKAGES <- scan(OUR_PACKAGES[1], what = character())
    message(OUR_PACKAGES)
  }
}

# Repositories to look for packages
CRAN <- "https://cran.rstudio.com/"
BIOC <- "https://bioconductor.org/packages/release/bioc/"

# Define the base packages.  These are packages which come with R upon install
# of R.  These packages include: "base", "compiler", "datasets", "graphics",
# "grDevices", "grid", "methods", "parallel", "splines", "stats", "stats4",
# "tcltk", "tools", and "utils".
#
# NOTE: there are Priority = "recommended" packages as well.  If these packages
# are missing from the system install, this script might fail.  Downloading and
# installing the 'recommended' packages can be difficult between R versions.
base_pkgs <-
  unname(utils::installed.packages()[utils::installed.packages()[, "Priority"] %in% c("base", "recommended"), "Package"])

# get a list of the available packages from CRAN and BioConductor
available_pkgs <- available.packages(repos = c(CRAN, BIOC))

# use the tools::package_dependencies function to generate a list of the
# packages dependencies, and dependencies of dependencies, and so on, ...
pkgs_to_download <- OUR_PACKAGES
i <- 1L
while(i <= length(pkgs_to_download)) {
  deps <-
    unlist(tools::package_dependencies(packages = pkgs_to_download[i],
                                       which = c("Depends", "Imports", "LinkingTo"),
                                       db = available_pkgs,
                                       recursive = FALSE),
           use.names = FALSE)
  deps <- deps[!(deps %in% base_pkgs)]
  pkgs_to_download <- append(pkgs_to_download, deps, i)
  i <- i + 1L
}
pkgs_to_download <- unique(rev(pkgs_to_download))

# Download the needed packages into the pkg-source-files directory
unlink("pkg-source-files/*")
dir.create("pkg-source-files/", showWarnings = FALSE)

dwnld_pkgs <-
  download.packages(pkgs = pkgs_to_download,
                    destdir = "pkg-source-files",
                    repos = c(CRAN, BIOC),
                    type = "source")

# generate a makefile to install the packages.  The makefile will stop if there
# is an error in any of the installs.  Using a bash script will not stop if
# there is an error.

cat("all:\n",
    paste0("\tR CMD INSTALL ", dwnld_pkgs[, 2], "\n"),
    sep = "",
    file = "makefile")


################################################################################
#  end of file
################################################################################
