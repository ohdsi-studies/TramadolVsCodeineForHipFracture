################################################################################
# CONFIG
################################################################################
library(epi756A201)

# Optional: specify where the temporary files (used by the ff package) will be created:
options(fftempdir = "S:\\fftemp")
#options(fftempdir = "D:\\fftemp")

################################################################################
# VARIABLES
################################################################################
# Maximum number of cores to be used:
maxCores <- parallel::detectCores()

# The folder where the study intermediate and result files will be written:
studyFolder <- "S:/GIT/BitBucket/epi_756/programs/epi756A201/results"
#studyFolder <- "S:/BitBucket/epi_756/programs/epi756A201/results"

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

packageName <- "epi756A201"
study <- "A201"

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

# FIX CALIBRATED RESULTS -------------------------------------------------------
#-------------------------------------------------------------------------------
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

launchEvidenceExplorer(dataFolder = fullShinyDataFolder, blind = FALSE, launch.browser = FALSE)

################################################################################
# ADDITIONAL WORK
################################################################################

# EXPECTED SYSTEMATIC ERROR ----------------------------------------------------
#-------------------------------------------------------------------------------
for(i in 1:2){
        print(paste("Analysis ",i))
        negativesAll <- read.csv("S:/BitBucket/epi_756/programs/epi756A201/results/CDM_CPRD_V1102/export/cohort_method_result.csv")
        negatives <- negativesAll[negativesAll$outcome_id != 15066,]
        negatives <- negatives[negatives$analysis_id == i, ]
        negatives <- negatives[is.na(negatives$log_rr) == FALSE,]
        negatives <- negatives[is.na(negatives$se_log_rr) == FALSE,]
        null<- EmpiricalCalibration::fitMcmcNull(negatives$log_rr,negatives$se_log_rr)
        systematicError <- EmpiricalCalibration::computeExpectedSystematicError(null) 
        print(systematicError)
}


# DOSE WORK  -------------------------------------------------------------------
#-------------------------------------------------------------------------------
### LOAD MATCHED PATIENTS ###################
#This file is large and takes awhile to load into the DB
StratPop <- readRDS("S:/GIT/BitBucket/epi_756/programs/epi756A201/results/CDM_CPRD_V1102/cmOutput/StratPop_l1_s1_p1_t16022_c16020_s1_o15066.rds")
StratPop <- StratPop[,c(2,3)]
conn <- DatabaseConnector::connect(connectionDetails = connectionDetails)
DatabaseConnector::dbWriteTable(conn,value = StratPop,name=paste0('SCRATCH.dbo.EPI756_cohort_diagnostics_cprd_A201_StratPop'),
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

################################################################################
# ADDITIONAL OUTPUT
################################################################################

# Plot Perference Score and Covariate Balance Before and 
#-------------------------------------------------------------------------------
ps <- readRDS("S:/GIT/BitBucket/epi_756/programs/epi756A201/results/CDM_CPRD_V1102/cmOutput/Ps_l1_s1_p1_t16022_c16020.rds")
fileName <-  file.path(studyFolder, paste0("PrefrenceScoreDistribution_A201.png"))
CohortMethod::plotPs(data = ps,
                     targetLabel = "T1 - Tramadol",
                     comparatorLabel = "C1 - Codeine",
                     showCountsLabel = FALSE,
                     showAucLabel = FALSE,
                     showEquiposeLabel = FALSE,
                     #title = "Title",
                     fileName = fileName)


balance <- readRDS("S:/GIT/BitBucket/epi_756/programs/epi756A201/results/CDM_CPRD_V1102/balance/bal_t16022_c16020_o15066_a1.rds")
fileName <-  file.path(studyFolder, paste0("CDM_CPRD_V1102/CovariateBalanceBeforeAndAfterPS_A201.png"))
CohortMethod::plotCovariateBalanceScatterPlot(balance = balance,
                                              beforeLabel = "Before PS adjustment",
                                              afterLabel =  "After PS adjustment",
                                              showCovariateCountLabel = FALSE,
                                              showMaxLabel = FALSE,
                                              #title = ,
                                              fileName = fileName)
