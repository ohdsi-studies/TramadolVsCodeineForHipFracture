################################################################################
# CONFIG
################################################################################
library(epi756A302)

# Optional: specify where the temporary files (used by the ff package) will be created:
options(fftempdir = "S:\\fftemp")
#options(fftempdir = "D:\\fftemp")

################################################################################
# VARIABLES
################################################################################
# Maximum number of cores to be used:
maxCores <- parallel::detectCores()

# The folder where the study intermediate and result files will be written:
studyFolder <- "S:/GIT/BitBucket/epi_756/programs/epi756A302/result"
#studyFolder <- "s:/BitBucket/epi_756/programs/epi756A302/results"

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

packageName <- "epi756A302"
study <- "A302"

# ################################################################################
# # WORK
# ################################################################################
# 
# # PLE --------------------------------------------------------------------------
# for(i in 1:nrow(databases)){
#         print("#######################################################################")
#         print(paste0("Run PLE:  ",databases[i,]$databaseId))
#         print("#######################################################################")
#         
#         # The name of the database schema and table where the study-specific cohorts will be instantiated:
#         cohortDatabaseSchema <- databases$cohortDatabaseSchema[i]
#         cohortTable <- paste0(databases$cohortTable[i],"_",study)
#         
#         #Where is the CDM
#         cdmDatabaseSchema <- databases$cdmDatabaseSchema[i]
#         
#         # Some meta-information that will be used by the export function:
#         databaseId <- databases$databaseId[i]
#         databaseName <- databases$databaseName[i]
#         databaseDescription <- databases$databaseDescription[i]
#         
#         outputFolder <- file.path(studyFolder, databaseId)
#         
#         # Make the Cohorts
#         createCohorts <- TRUE
#         
#         if(createCohorts){
#                 #Use PLE to make cohorts
#                 execute(connectionDetails = connectionDetails,
#                         cdmDatabaseSchema = cdmDatabaseSchema,
#                         cohortDatabaseSchema = cohortDatabaseSchema,
#                         cohortTable = cohortTable,
#                         oracleTempSchema = oracleTempSchema,
#                         outputFolder = outputFolder,
#                         databaseId = databaseId,
#                         databaseName = databaseName,
#                         databaseDescription = databaseDescription,
#                         createCohorts = TRUE,
#                         synthesizePositiveControls = FALSE,
#                         runAnalyses = FALSE,
#                         runDiagnostics = FALSE,
#                         packageResults = FALSE,
#                         maxCores = maxCores)
#                 
#                 # Trim Cohort End Dates
#                 for(i in 1:length(cohorts$atlasId)){
#                         conn <- DatabaseConnector::connect(connectionDetails = connectionDetails)
#                         
#                         sql <- SqlRender::loadRenderTranslateSql(sqlFilename = "trimEndDate.sql",
#                                                                  packageName = packageName,
#                                                                  dbms = attr(conn, "dbms"),
#                                                                  oracleTempSchema = NULL,
#                                                                  cohortDatabaseSchema = cohortDatabaseSchema,
#                                                                  cohortTable = cohortTable,
#                                                                  cohortId = cohorts$cohortId[i],
#                                                                  cdmDatabaseSchema = cdmDatabaseSchema)
#                         
#                         DatabaseConnector::executeSql(conn=conn,sql)
#                         
#                         DatabaseConnector::disconnect(conn)
#                 }
#         }
#         
#         
#         # Rest of the work
#         execute(connectionDetails = connectionDetails,
#                 cdmDatabaseSchema = cdmDatabaseSchema,
#                 cohortDatabaseSchema = cohortDatabaseSchema,
#                 cohortTable = cohortTable,
#                 oracleTempSchema = oracleTempSchema,
#                 outputFolder = outputFolder,
#                 databaseId = databaseId,
#                 databaseName = databaseName,
#                 databaseDescription = databaseDescription,
#                 createCohorts = FALSE,
#                 synthesizePositiveControls = FALSE,
#                 runAnalyses = TRUE,
#                 runDiagnostics = TRUE,
#                 packageResults = TRUE,
#                 maxCores = maxCores)
# 
#         resultsZipFile <- file.path(outputFolder, "export", paste0("Results", databaseId, ".zip"))
#         dataFolder <- file.path(outputFolder, "shinyData")
#         prepareForEvidenceExplorer(resultsZipFile = resultsZipFile, dataFolder = dataFolder)
# }
# 
# # FIX CALIBRATED RESULTS -------------------------------------------------------
# for(i in 1:nrow(databases)){
#         print("#######################################################################")
#         print(paste0("Get Calibrated CI:  ",databases[i,]$databaseId))
#         print("#######################################################################")
#         
#         # The name of the database schema and table where the study-specific cohorts will be instantiated:
#         cohortDatabaseSchema <- databases$cohortDatabaseSchema[i]
#         cohortTable <- paste0(databases$cohortTable[i],"_",study)
#         
#         #Where is the CDM
#         cdmDatabaseSchema <- databases$cdmDatabaseSchema[i]
#         
#         # Some meta-information that will be used by the export function:
#         databaseId <- databases$databaseId[i]
#         databaseName <- databases$databaseName[i]
#         databaseDescription <- databases$databaseDescription[i]
#         
#         outputFolder <- file.path(studyFolder, databaseId)
#         
#         # Rest of the work
#         execute(connectionDetails = connectionDetails,
#                 cdmDatabaseSchema = cdmDatabaseSchema,
#                 cohortDatabaseSchema = cohortDatabaseSchema,
#                 cohortTable = cohortTable,
#                 oracleTempSchema = oracleTempSchema,
#                 outputFolder = outputFolder,
#                 databaseId = databaseId,
#                 databaseName = databaseName,
#                 databaseDescription = databaseDescription,
#                 createCohorts = FALSE,
#                 synthesizePositiveControls = FALSE,
#                 runAnalyses = FALSE,
#                 runDiagnostics = FALSE,
#                 packageResults = TRUE,
#                 maxCores = maxCores)
#         
#         resultsZipFile <- file.path(outputFolder, "export", paste0("Results", databaseId, ".zip"))
#         dataFolder <- file.path(outputFolder, "shinyData")
#         prepareForEvidenceExplorer(resultsZipFile = resultsZipFile, dataFolder = dataFolder)
# }
# 
# # DO METAANALYSIS --------------------------------------------------------------
# doMetaAnalysis(packageName = packageName,
#                 studyFolder = studyFolder,
#                outputFolders = c(file.path(studyFolder, "MDCR"),
#                                  file.path(studyFolder, "MDCD"),
#                                 file.path(studyFolder, "OPTUM_DOD")),
#                maOutputFolder = file.path(studyFolder, "MetaAnalysis"),
#                maxCores = maxCores)
# 
# # copy export objects to one directory ------------------------------------------
# fullShinyDataFolder <- file.path(studyFolder, "shinyDataAll")
# 
# 
# if (!file.exists(fullShinyDataFolder)) {
#         dir.create(fullShinyDataFolder)
# }
# 
# file.copy(from = c(list.files(file.path(studyFolder, "CCAE", "shinyData"), full.names = TRUE),
#                    list.files(file.path(studyFolder, "MDCR", "shinyData"), full.names = TRUE),
#                    list.files(file.path(studyFolder, "MDCD", "shinyData"), full.names = TRUE),
#                    list.files(file.path(studyFolder, "OPTUM_DOD", "shinyData"), full.names = TRUE),
#                    list.files(file.path(studyFolder, "CPRD", "shinyData"), full.names = TRUE),
#                    list.files(file.path(studyFolder, "CDM_JMDC", "shinyData"), full.names = TRUE),
#                    list.files(file.path(studyFolder, "MetaAnalysis", "shinyData"), full.names = TRUE)),
#           to = fullShinyDataFolder,
#           overwrite = TRUE)
# 
# launchEvidenceExplorer(dataFolder = fullShinyDataFolder, blind = FALSE, launch.browser = FALSE)
# 
# 
# 
# outputFolder <- "result/MDCR"
# reference <- readRDS(file.path(outputFolder, "cmOutput", "outcomeModelReference.rds"))
# reference$outcomeModelFile[1]
# outcomeModel <- readRDS(file.path(outputFolder,
#                                   "cmOutput",
#                                   reference$outcomeModelFile[i]))

################################################################################
# RUNNING FOR IMMORTAL TIME BIAS FIX
################################################################################
#fixed removeSubjectsWithPriorOutcome = true,       "priorOutcomeLookback": 9999,

studyFolder <- "S:/GIT/BitBucket/epi_756_ImmortalTimeBiasReview/programs/epi756A302/result"
study <- "A302"

#delete files we want to regenerate after fixing removeSubjectsWithPriorOutcome = TRUE
files <- list.files(studyFolder,
                    pattern = "StudyPop_",
                    full.names = TRUE,
                    recursive = TRUE)
files
unlink(files)

files <- list.files(studyFolder,
                    pattern = "StratPop_",
                    full.names = TRUE,
                    recursive = TRUE)
files
unlink(files)

files <- list.files(studyFolder,
                    pattern = "om_",
                    full.names = TRUE,
                    recursive = TRUE)
files
unlink(files)

files <- intersect(
        list.files(studyFolder,
                    pattern = "bal_",
                    full.names = TRUE,
                    recursive = TRUE),
        list.files(studyFolder,
                   pattern = ".rds",
                   full.names = TRUE,
                   recursive = TRUE))
files
unlink(files)

files <- list.files(studyFolder,
                    pattern = "Ps_.*_o",
                    full.names = TRUE,
                    recursive = TRUE)
files
unlink(files)


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

# # DO METAANALYSIS --------------------------------------------------------------
doMetaAnalysis(packageName = packageName,
                studyFolder = studyFolder,
               outputFolders = c(file.path(studyFolder, "MDCR"),
                                 file.path(studyFolder, "MDCD"),
                                file.path(studyFolder, "OPTUM_DOD")),
               maOutputFolder = file.path(studyFolder, "MetaAnalysis"),
               maxCores = maxCores)


fullShinyDataFolder <- file.path(studyFolder, "shinyDataAll")
if (!file.exists(fullShinyDataFolder)) {
        dir.create(fullShinyDataFolder)
}
file.copy(from = c(list.files(file.path(studyFolder, "CCAE", "shinyData"), full.names = TRUE),
                   list.files(file.path(studyFolder, "MDCR", "shinyData"), full.names = TRUE),
                   list.files(file.path(studyFolder, "MDCD", "shinyData"), full.names = TRUE),
                   list.files(file.path(studyFolder, "OPTUM_DOD", "shinyData"), full.names = TRUE),
                   list.files(file.path(studyFolder, "CDM_CPRD_V1102", "shinyData"), full.names = TRUE),
                   list.files(file.path(studyFolder, "JMDC", "shinyData"), full.names = TRUE),
                   list.files(file.path(studyFolder, "MetaAnalysis", "shinyData"), full.names = TRUE)),
          to = fullShinyDataFolder,
          overwrite = TRUE)

launchEvidenceExplorer(dataFolder = fullShinyDataFolder, blind = TRUE, launch.browser = FALSE)


