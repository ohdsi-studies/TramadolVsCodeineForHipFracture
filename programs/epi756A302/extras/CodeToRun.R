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

################################################################################
# WORK
################################################################################

# PLE --------------------------------------------------------------------------
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

# FIX CALIBRATED RESULTS -------------------------------------------------------
for(i in 1:nrow(databases)){
        print("#######################################################################")
        print(paste0("Get Calibrated CI:  ",databases[i,]$databaseId))
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
                runAnalyses = FALSE,
                runDiagnostics = FALSE,
                packageResults = TRUE,
                maxCores = maxCores)
        
        resultsZipFile <- file.path(outputFolder, "export", paste0("Results", databaseId, ".zip"))
        dataFolder <- file.path(outputFolder, "shinyData")
        prepareForEvidenceExplorer(resultsZipFile = resultsZipFile, dataFolder = dataFolder)
}

# DO METAANALYSIS --------------------------------------------------------------
doMetaAnalysis(packageName = packageName,
                studyFolder = studyFolder,
               outputFolders = c(file.path(studyFolder, "MDCR"),
                                 file.path(studyFolder, "MDCD"),
                                file.path(studyFolder, "OPTUM_DOD")),
               maOutputFolder = file.path(studyFolder, "MetaAnalysis"),
               maxCores = maxCores)

# copy export objects to one directory ------------------------------------------
fullShinyDataFolder <- file.path(studyFolder, "shinyDataAll")


if (!file.exists(fullShinyDataFolder)) {
        dir.create(fullShinyDataFolder)
}

file.copy(from = c(list.files(file.path(studyFolder, "CCAE", "shinyData"), full.names = TRUE),
                   list.files(file.path(studyFolder, "MDCR", "shinyData"), full.names = TRUE),
                   list.files(file.path(studyFolder, "MDCD", "shinyData"), full.names = TRUE),
                   list.files(file.path(studyFolder, "OPTUM_DOD", "shinyData"), full.names = TRUE),
                   list.files(file.path(studyFolder, "CPRD", "shinyData"), full.names = TRUE),
                   list.files(file.path(studyFolder, "CDM_JMDC", "shinyData"), full.names = TRUE),
                   list.files(file.path(studyFolder, "MetaAnalysis", "shinyData"), full.names = TRUE)),
          to = fullShinyDataFolder,
          overwrite = TRUE)

launchEvidenceExplorer(dataFolder = fullShinyDataFolder, blind = FALSE, launch.browser = FALSE)



outputFolder <- "result/MDCR"
reference <- readRDS(file.path(outputFolder, "cmOutput", "outcomeModelReference.rds"))
reference$outcomeModelFile[1]
outcomeModel <- readRDS(file.path(outputFolder,
                                  "cmOutput",
                                  reference$outcomeModelFile[i]))



################################################################################
# DOSE WORK
################################################################################

### LOAD MATCHED PATIENTS ###################
#This file is large and takes awhile to load into the DB
StratPop <- readRDS("S:/GIT/BitBucket/epi_756/programs/epi756A302/result/MDCD/cmOutput/StratPop_l1_s1_p1_t16023_c15906_s1_o16021.rds")
StratPop <- StratPop[,c(2,3)]
conn <- DatabaseConnector::connect(connectionDetails = connectionDetails)
DatabaseConnector::dbWriteTable(conn,value = StratPop,name=paste0('SCRATCH.dbo.EPI756_cohort_diagnostics_mdcd_A302_StratPop'),
                                overwrite=TRUE,append=FALSE,temporary=FALSE,oracleTempSchema=NULL)

StratPop <- readRDS("S:/GIT/BitBucket/epi_756/programs/epi756A302/result/MDCR/cmOutput/StratPop_l1_s1_p1_t16023_c15906_s1_o16021.rds")
StratPop <- StratPop[,c(2,3)]
conn <- DatabaseConnector::connect(connectionDetails = connectionDetails)
DatabaseConnector::dbWriteTable(conn,value = StratPop,name=paste0('SCRATCH.dbo.EPI756_cohort_diagnostics_mdcr_A302_StratPop'),
                                overwrite=TRUE,append=FALSE,temporary=FALSE,oracleTempSchema=NULL)


StratPop <- readRDS("S:/GIT/BitBucket/epi_756/programs/epi756A302/result/OPTUM_DOD/cmOutput/StratPop_l1_s1_p1_t16023_c15906_s1_o16021.rds")
StratPop <- StratPop[,c(2,3)]
conn <- DatabaseConnector::connect(connectionDetails = connectionDetails)
DatabaseConnector::dbWriteTable(conn,value = StratPop,name=paste0('SCRATCH.dbo.EPI756_cohort_diagnostics_optum_dod_A302_StratPop'),
                                overwrite=TRUE,append=FALSE,temporary=FALSE,oracleTempSchema=NULL)



### DEFINE WHAT WE WANT TO RUN ###################
doseRunsFile <- "extras/doseRuns.csv"
doseRuns <-read.csv(doseRunsFile,as.is=TRUE)[,]

#Empty data frame to load the results in
doseResults <- data.frame(title=character(), lowerWisker=numeric(), Q1=numeric(), median=numeric(), Q2=numeric(), upperWisker=numeric())

for(z in 1:nrow(doseRuns)){
        for(i in 1:nrow(databases)){
                print("#######################################################################")
                print(paste0("DOSE WORK:  ",databases[i,]$databaseId," -- ",doseRuns$TITLE[z]))
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
                
                #---------------------------------------------------------------
                df <- getIndexDose(connectionDetails = connectionDetails,
                                   cdmDatabaseSchema = cdmDatabaseSchema,
                                   cohortDatabaseSchema = cohortDatabaseSchema,
                                   cohortTable = cohortTable,
                                   INGREDIENT_CONCEPT_ID = doseRuns$INGREDIENT_CONCEPT_ID[z],
                                   COHORT_DEFINITION_ID = doseRuns$COHORT_DEFINITION_ID[z],
                                   MME = doseRuns$MME[z],
                                   psMatched = doseRuns$psMatched[z],
                                   treatmentGroup = doseRuns$treatmentGroup[z])
                
                #get the Q1,Median,Q2
                test <- boxplot.stats(df$DAILY_DOSE_MME)
                dfFormatted <- cbind(doseRuns$TITLE[z],round(test$stats[1],1),round(test$stats[2],1),round(test$stats[3],1),round(test$stats[4],1),round(test$stats[5],1))
                colnames(dfFormatted) <- c('title','lowerWisker','Q1','median','Q2','upperWisker')
                
                doseResults <- rbind(doseResults,dfFormatted)
                
        }
}

write.csv(doseResults,paste0("results/doseResults_",study,".csv"))
