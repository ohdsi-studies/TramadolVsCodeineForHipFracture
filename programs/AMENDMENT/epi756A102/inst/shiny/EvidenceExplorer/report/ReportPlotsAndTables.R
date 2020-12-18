getPatientCounts <- function(attrition) {
  patientCounts <- attrition[attrition$description %in% c("Original cohorts","Matched on propensity score") & 
                               #attrition$exposureId %in% primaryTarCohortIds &
                               #attrition$databaseId %in% databaseIds & 
                               attrition$analysisId == 1,
                             c("databaseId", "description","exposureId", "subjects")]
  
  originalCohorts <- patientCounts[patientCounts$description == "Original cohorts",c("databaseId", "exposureId", "subjects")]
  names(originalCohorts) <- c("databaseId", "exposureId","originalCohort")
  matchedCohorts <- patientCounts[patientCounts$description == "Matched on propensity score",c("databaseId", "exposureId", "subjects")]
  names(matchedCohorts) <- c("databaseId", "exposureId","matchedCohort")
  
  originalMatchedCohorts <- merge(originalCohorts,matchedCohorts, by = c("databaseId", "exposureId"))
  originalMatchedCohorts$matchedPercent <- round(originalMatchedCohorts$matchedCohort / originalMatchedCohorts$originalCohort * 100, 2)
  originalMatchedCohorts <- merge(originalMatchedCohorts,exposureOfInterest, by = c("exposureId"))
  originalMatchedCohorts <- originalMatchedCohorts[,c("databaseId","exposureName","originalCohort","matchedCohort","matchedPercent")]
  
  return(originalMatchedCohorts)
}