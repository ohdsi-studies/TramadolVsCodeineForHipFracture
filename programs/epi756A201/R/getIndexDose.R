#' @export
getIndexDose <- function(connectionDetails, 
                         cdmDatabaseSchema,
                         cohortDatabaseSchema,
                         cohortTable,
                         INGREDIENT_CONCEPT_ID,
                         COHORT_DEFINITION_ID,
                         MME,
                         psMatched, #1==yes, 0==No (to use the PS people or not)
                         treatmentGroup #1==tramadol, 0==Codeine
){
  conn <- DatabaseConnector::connect(connectionDetails = connectionDetails)
  
  sql <- SqlRender::loadRenderTranslateSql(sqlFilename = "getIndexDose.sql",
                                           packageName = packageName,
                                           dbms = attr(conn, "dbms"),
                                           oracleTempSchema = NULL,
                                           cohortTable = cohortTable,
                                           cdmDatabaseSchema = cdmDatabaseSchema,
                                           cohortDatabaseSchema = cohortDatabaseSchema,
                                           INGREDIENT_CONCEPT_ID = INGREDIENT_CONCEPT_ID,
                                           COHORT_DEFINITION_ID = COHORT_DEFINITION_ID,
                                           MME = MME,
                                           psMatched = psMatched,
                                           treatmentGroup = treatmentGroup)
  
  df <- DatabaseConnector::querySql(conn=conn,sql)
  
  DatabaseConnector::disconnect(conn)
  
  return(df)
}