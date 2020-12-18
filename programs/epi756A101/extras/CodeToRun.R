################################################################################
# NOTES
################################################################################
#  In the settings you need to set stopOnError = false

################################################################################
# CONFIG
################################################################################
library(epi756A101)

# Optional: specify where the temporary files (used by the ff package) will be created:
options(fftempdir = "S:\\fftemp")
#options(fftempdir = "D:\\fftemp")

################################################################################
# VARIABLES
################################################################################
# Maximum number of cores to be used:
maxCores <- parallel::detectCores()

# The folder where the study intermediate and result files will be written:
studyFolder <- "S:/GIT/BitBucket/epi_756/programs/epi756A101/results"
#studyFolder <- "S:/BitBucket/epi_756/programs/epi756A101/results"

# Details for connecting to the server:
connectionDetails <- DatabaseConnector::createConnectionDetails(dbms = "pdw",
                                                                server = "SERVER_NAME",
                                                                user = NULL,
                                                                password = NULL,
                                                                port = 17001)

# For Oracle: define a schema that can be used to emulate temp tables:
oracleTempSchema <- NULL

# Database information
databaseFile <- "extras/databases.csv"
databases <- read.csv(databaseFile,as.is=TRUE)[,]

cohortsFile <- "inst/settings/CohortsToCreate.csv"
cohorts <- read.csv(cohortsFile,as.is=TRUE)[,]

packageName <- "epi756A101"
study <- "A101"

################################################################################
# WORK
################################################################################

# INITIAL MAIN RUN -------------------------------------------------------------
#-------------------------------------------------------------------------------
for(i in 1:nrow(databases)){
        print("#######################################################################")
        print(paste0("Run PLE:  ",databases[i,]$databaseId))
        print("#######################################################################")
        
        # The name of the database schema and table where the study-specific cohorts will be instantiated:
        cohortDatabaseSchema <- databases$cohortDatabaseSchema[i]
        cohortTable <- paste0(databases$cohortTable[i],"_",study)
        
        #Where is the CDM
        cdmDatabaseSchema <- databases$cdmDatabaseSchema[i]
        
        # Some meta-information that will be used by the export function:
        databaseId <- databases$databaseId[i]
        databaseName <- databases$databaseName[i]
        databaseDescription <- databases$databaseDescription[i]
        
        outputFolder <- file.path(studyFolder, databaseId)
        
        # Make the Cohorts
        createCohorts <- TRUE
        
        if(createCohorts){
                #Use PLE to make cohorts
                execute(connectionDetails = connectionDetails,
                        cdmDatabaseSchema = cdmDatabaseSchema,
                        cohortDatabaseSchema = cohortDatabaseSchema,
                        cohortTable = cohortTable,
                        oracleTempSchema = oracleTempSchema,
                        outputFolder = outputFolder,
                        databaseId = databaseId,
                        databaseName = databaseName,
                        databaseDescription = databaseDescription,
                        createCohorts = TRUE,
                        synthesizePositiveControls = FALSE,
                        runAnalyses = FALSE,
                        runDiagnostics = FALSE,
                        packageResults = FALSE,
                        maxCores = maxCores)
                
                # Trim Cohort End Dates
                for(i in 1:length(cohorts$atlasId)){
                        conn <- DatabaseConnector::connect(connectionDetails = connectionDetails)
                        
                        sql <- SqlRender::loadRenderTranslateSql(sqlFilename = "trimEndDate.sql",
                                                                 packageName = packageName,
                                                                 dbms = attr(conn, "dbms"),
                                                                 oracleTempSchema = NULL,
                                                                 cohortDatabaseSchema = cohortDatabaseSchema,
                                                                 cohortTable = cohortTable,
                                                                 cohortId = cohorts$cohortId[i],
                                                                 cdmDatabaseSchema = cdmDatabaseSchema)
                        
                        DatabaseConnector::executeSql(conn=conn,sql)
                        
                        DatabaseConnector::disconnect(conn)
                }
        }
        
        
        # Rest of the work
        execute(connectionDetails = connectionDetails,
                cdmDatabaseSchema = cdmDatabaseSchema,
                cohortDatabaseSchema = cohortDatabaseSchema,
                cohortTable = cohortTable,
                oracleTempSchema = oracleTempSchema,
                outputFolder = outputFolder,
                databaseId = databaseId,
                databaseName = databaseName,
                databaseDescription = databaseDescription,
                createCohorts = FALSE,
                synthesizePositiveControls = FALSE,
                runAnalyses = TRUE,
                runDiagnostics = TRUE,
                packageResults = TRUE,
                maxCores = maxCores)

        resultsZipFile <- file.path(outputFolder, "export", paste0("Results", databaseId, ".zip"))
        dataFolder <- file.path(outputFolder, "shinyData")
        prepareForEvidenceExplorer(resultsZipFile = resultsZipFile, dataFolder = dataFolder)
}

#RSHINY SETUP-------------------------------------------------------------------
#-------------------------------------------------------------------------------
# copy export objects to one directory ------------------------------------------
fullShinyDataFolder <- file.path(studyFolder, "shinyDataAll")
if (!file.exists(fullShinyDataFolder)) {
        dir.create(fullShinyDataFolder)
}
file.copy(from = c(list.files(file.path(studyFolder, "CDM_CPRD_V1102", "shinyData"), full.names = TRUE)),
          to = fullShinyDataFolder,
          overwrite = TRUE)

launchEvidenceExplorer(dataFolder = fullShinyDataFolder, blind = TRUE, launch.browser = FALSE)

################################################################################
# ADDITIONAL OUTPUT
################################################################################

# Plot Perference Score and Covariate Balance Before and 
#-------------------------------------------------------------------------------
ps <- readRDS("S:/GIT/BitBucket/epi_756/programs/epi756A101/results/CDM_CPRD_V1102/cmOutput/Ps_l1_s1_p1_t16022_c16020.rds")
fileName <-  file.path(studyFolder, paste0("PrefreenceScoreDistribution_A101.png"))
CohortMethod::plotPs(data = ps,
                     targetLabel = "T1 - Tramadol",
                     comparatorLabel = "C1 - Codeine",
                     showCountsLabel = FALSE,
                     showAucLabel = FALSE,
                     showEquiposeLabel = FALSE,
                     #title = "Title",
                     fileName = fileName)

# No Covariate Balance Plot since no matched patients