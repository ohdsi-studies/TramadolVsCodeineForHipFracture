
#https://sourcecode.jnj.com/projects/ITX-ASJ/repos/epi_680/browse/DoacsWarfarinSub/inst/shiny/EvidenceExplorer/report/CreateReportPlotsAndTables.R
reportFolder <- "./report"
source("global.R")
source("report/ReportPlotsAndTables.R")

counts <- getPatientCounts(attrition)
