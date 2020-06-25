setwd("S:/GIT/BitBucket/epi_756/programs/epi756CohortDiagnostics")
wd <- getwd()
exportFolder <- paste0(wd,"/export")

options(fftempdir = "s:/fftemp")

#Defining the set of cohorts to diagnose
cohortSetReference <- read.csv("cohortsToCreate.csv")

#Configuring the connections to the server
connectionDetails <- DatabaseConnector::createConnectionDetails(dbms = "pdw",
                                                                server = "SERVER",
                                                                user = NULL,
                                                                password = NULL,
                                                                port = 17001)

# For Oracle: define a schema that can be used to emulate temp tables:
oracleTempSchema <- NULL

# Database information
databaseFile <- "databases.csv"
databases <- read.csv(databaseFile,as.is=TRUE)[,]

################################################################################
# WORK
################################################################################
for(i in 1:nrow(databases)){
  print("#######################################################################")
  print(paste0("Run Cohort Diagnostics:  ",databases[i,]$databaseId))
  print("#######################################################################")
  
  # The name of the database schema and table where the study-specific cohorts will be instantiated:
  cohortDatabaseSchema <- databases$cohortDatabaseSchema[i]
  cohortTable <- databases$cohortTable[i]
  
  #Where is the CDM
  cdmDatabaseSchema <- databases$cdmDatabaseSchema[i]
  
  # Some meta-information that will be used by the export function:
  databaseId <- databases$databaseId[i]
  databaseName <- databases$databaseName[i]
  databaseDescription <- databases$databaseDescription[i]

  #Creating a new cohort table
  CohortDiagnostics::createCohortTable(connectionDetails = connectionDetails,
                                       cohortDatabaseSchema = cohortDatabaseSchema,
                                       cohortTable = cohortTable)
  
  #Instantiating the cohort
  baseUrl <- "https://URL/WebAPI"
  inclusionStatisticsFolder <- paste0(wd,"/incStats")
  
  CohortDiagnostics::instantiateCohortSet(connectionDetails = connectionDetails,
                                          cdmDatabaseSchema = cdmDatabaseSchema,
                                          oracleTempSchema = oracleTempSchema,
                                          cohortDatabaseSchema = cohortDatabaseSchema,
                                          cohortTable = cohortTable,
                                          baseUrl = baseUrl,
                                          cohortSetReference = cohortSetReference,
                                          generateInclusionStats = TRUE,
                                          inclusionStatisticsFolder = inclusionStatisticsFolder)
  
  #Generating the diagnostics
  CohortDiagnostics::runCohortDiagnostics(baseUrl = baseUrl,
                                          cohortSetReference = cohortSetReference,
                                          connectionDetails = connectionDetails,
                                          cdmDatabaseSchema = cdmDatabaseSchema,
                                          oracleTempSchema = oracleTempSchema,
                                          cohortDatabaseSchema = cohortDatabaseSchema,
                                          cohortTable = cohortTable,
                                          inclusionStatisticsFolder = inclusionStatisticsFolder,
                                          exportFolder = exportFolder,
                                          databaseId = databaseId,
                                          runInclusionStatistics = TRUE,
                                          runIncludedSourceConcepts = TRUE,
                                          runOrphanConcepts = TRUE,
                                          runTimeDistributions = TRUE,
                                          runBreakdownIndexEvents = TRUE,
                                          runIncidenceRate = TRUE,
                                          runCohortOverlap = TRUE,
                                          runCohortCharacterization = TRUE,
                                          minCellCount = 5)
  
}



#Viewing
CohortDiagnostics::preMergeDiagnosticsFiles(exportFolder)
CohortDiagnostics::launchDiagnosticsExplorer(exportFolder)

load(paste0(exportFolder,"/PreMerged.RData"))
counts <- cohortCount[,c(1,3,4)]
names <- unique(cohort[,c(1,2,3)])
countsNames <- merge(counts, names)
countsNames <- countsNames[,c(4,2,3)]
df <- tidyr::pivot_wider_spec(countsNames,values_from = c(countsNames$cohortSubjects,countsNames$databaseId))
