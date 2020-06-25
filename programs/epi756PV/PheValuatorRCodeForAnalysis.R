# Run saved analysis settings -------------------------------------------------------------------
#devtools::install_github("ohdsi/PheValuator")
#setwd('S:/GIT/BitBucket/epi_756/programs/epi756PV/')
setwd('S:/BitBucket/epi_756/programs/epi756PV/')
library(PheValuator)

################################################################################
# VARIABLES
################################################################################

#options(fftempdir = "s:/fftemp") #CHANGE THIS: make sure this directory exists prior to run - should have at least 20GB of space on the drive
options(fftempdir = "d:/fftemp") #CHANGE THIS: make sure this directory exists prior to run - should have at least 20GB of space on the drive

connectionDetails <- createConnectionDetails(dbms ="pdw", server = "SERVER", port = "17001")

oracleTempSchema <- NULL

#CHANGE THIS: for your health outcome can do a universal replace of schizophrenia to your otucome, e.g., multipleMyeloma
#folder <- "S:/GIT/BitBucket/epi_756/programs/epi756PV/results" #CHANGE THIS: create this folder prior to run to store your results
folder <- "S:/BitBucket/epi_756/programs/epi756PV/results" #CHANGE THIS: create this folder prior to run to store your results

# Database information
databaseFile <- "databases.csv"
databases <- read.csv(databaseFile,as.is=TRUE)[,]

################################################################################
# RUN ALL COHORTS
################################################################################

runCohorts <- function(connectionDetails,dbsFile,cohortIDs){
  
  ################################################################################
  # VARIABLES
  ################################################################################
  dbs <- read.csv(dbsFile,as.is=TRUE)
  baseUrl <- "https://URL/WebAPI"
  
  ################################################################################
  # WORK
  ################################################################################
  conn <- DatabaseConnector::connect(connectionDetails = connectionDetails)
  
  ROhdsiWebApi::invokeCohortSetGeneration(baseUrl = baseUrl,
                                          sourceKeys = dbs$sourceKey,
                                          definitionIds = cohortIDs)
  
  ################################################################################
  # CLEAN
  ################################################################################
  DatabaseConnector::disconnect(conn)
}

runCohorts(connectionDetails = connectionDetails,
           dbsFile = databaseFile,
           cohortIDs = c(15385,15386,
                         15947)) #we run the cohort without the age restrictions to help from getting false negatives

################################################################################
# CREATE ANALYSIS SETTINGS
################################################################################
#CHANGE THIS: replace the excludedCovariateConceptIds with the list used to define your outcome concept set
covSettingsChronic <- createDefaultChronicCovariateSettings(excludedCovariateConceptIds = c(136834,432473,433856,434500,435956,436247,436248,437117,437692,437703,440556,440863,444192,759975,759988,759989,759990,759991,760103,760405,760406,760407,760408,760409,760410,760411,760412,760413,760414,760415,760416,760417,760418,760419,760420,760421,760422,760425,760688,761933,763793,763864,765013,765035,765308,4009606,4009607,4009608,4009609,4009610,4012285,4012431,4012433,4012436,4012437,4015081,4015194,4015494,4015495,4015496,4015498,4015499,4015500,4015501,4015502,4015503,4015975,4015977,4015979,4015980,4015981,4018351,4027460,4103168,4133012,4135747,4135748,4136839,4136840,4138277,4138412,4142118,4145054,4165404,4167913,4167914,4169989,4170313,4173672,4173673,4199545,4230399,4263628,4281541,4323194,37116533,37209093,37209108,37209109,37209110,37209111,37209369,37209370,37209371,37209372,40493184,40493210,45763653,45767653,45771398),
                                                            addDescendantsToExclude = FALSE)

cohortArgsChronic <- createCreateEvaluationCohortArgs(xSpecCohortId = 15385, #CHANGE THIS: to your xSpec
                                                      xSensCohortId = 15386, #CHANGE THIS: to your xSens
                                                      covariateSettings = covSettingsChronic,
                                                      baseSampleSize = 2000000,
                                                      lowerAgeLimit = 50, #CHANGE THESE: if you want different age settings
                                                      upperAgeLimit = 90, 
                                                      startDate = "19001010", #CHANGE THES: if you want if you want different start/end dates
                                                      endDate = "21000101",
                                                      saveEvaluationCohortPlpData = TRUE,
                                                      modelType = "chronic")

##### First phenotype algorithm to test ##############
alg1TestArgs <- createTestPhenotypeAlgorithmArgs(cutPoints = c("EV",0.5),
                                                 phenotypeCohortId = 15385, #CHANGE THIS: 1st phenotype algorithm to test
                                                 washoutPeriod = 365) #CHANGE THIS: to how many continuous observation days prior to index (e.g., 365)

analysis1 <- createPheValuatorAnalysis(analysisId = 15385,
                                       description = "xSpec",
                                       createEvaluationCohortArgs = cohortArgsChronic,
                                       testPhenotypeAlgorithmArgs = alg1TestArgs)

##### Second phenotype algorithm to test ##############
alg2TestArgs <- createTestPhenotypeAlgorithmArgs(cutPoints = c("EV",0.5),
                                                 phenotypeCohortId = 15947, #CHANGE THIS: 1st phenotype algorithm to test
                                                 washoutPeriod = 365) #CHANGE THIS: to how many continuous observation days prior to index (e.g., 365)

analysis2 <- createPheValuatorAnalysis(analysisId = 15947,
                                       description = "[TESTING WITHOUT 821] [EPI_756] O2 - (WOUT AGE) (Primary Hip Fracture ER/IP Dx with Hip Fracture procedures +/- 7 days) OR (Primary Hip Fracture procedures with Hip Fracture ER/IP +/- 7 days)", #CHANGE THIS: to a good name for your phenotype algorithm to test
                                       createEvaluationCohortArgs = cohortArgsChronic,
                                       testPhenotypeAlgorithmArgs = alg2TestArgs)


pheValuatorAnalysisList <- list(analysis1,analysis2) #include in the list all the analyses from above
savePheValuatorAnalysisList(pheValuatorAnalysisList, file.path(folder, "pheValuatorAnalysisSettings.json"))

################################################################################
# PheValuate!
################################################################################
for(i in 1:nrow(databases)){
  print("#######################################################################")
  print(paste0("Run PV:  ",databases[i,]$databaseId))
  print("#######################################################################")
  
  outFolder <- file.path(folder, databases[i,]$databaseId)
  
  pheValuatorAnalysisList <- loadPheValuatorAnalysisList(file.path(folder, "pheValuatorAnalysisSettings.json"))
  
  referenceTable <- runPheValuatorAnalyses(connectionDetails = connectionDetails,
                                           cdmDatabaseSchema = databases[i,]$cdmDatabaseSchema,
                                           cohortDatabaseSchema = databases[i,]$cohortDatabaseSchema,
                                           cohortTable = databases[i,]$cohortTable,
                                           workDatabaseSchema = databases[i,]$workDatabaseSchema,
                                           outputFolder = outFolder,
                                           pheValuatorAnalysisList = pheValuatorAnalysisList)
}

#after the run, this will display the results - can replace the print function to write.csv()
for(i in 1:nrow(databases)){
  outFolder <- file.path(folder, databases[i,]$databaseId)
  write.csv(summarizePheValuatorAnalyses(readRDS(file.path(outFolder, "reference.rds")), outFolder),paste0("PV_",databases[i,]$databaseId,".csv"))
}

# for(i in 1:nrow(databases)){
#   resFile <- readRDS(file.path(folder, databases[i,]$databaseId,"TestResults_a6.rds"))
#   attr(resFile, "misses") 
# }
# 
# rds <- readRDS(file.path("S:\\GIT\\BitBucket\\epi_756\\programs\\epi756PV\\results\\OPTUM_DOD\\EvaluationCohort_e1\\model_main.rds"))
# model <- rds$model$varImp[rds$model$varImp$covariateValue!=0,]

doTestPhenotypeAlgorithm
