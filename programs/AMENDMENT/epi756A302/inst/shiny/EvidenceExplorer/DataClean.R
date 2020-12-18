cohortMethodResult$i2 <- ifelse(cohortMethodResult$i2 < 0.01, "<0.01", round(cohortMethodResult$i2, 2)) 
#outcomeOfInterest$outcomeName[outcomeOfInterest$outcomeName == "[LEGEND HTN] Acute renal failure events"] <- "Acute renal failure"
#outcomeOfInterest$outcomeName[outcomeOfInterest$outcomeName == "[LEGEND HTN] Persons with end stage renal disease"] <- "End stage renal disease"
#outcomeOfInterest$outcomeName[outcomeOfInterest$outcomeName == "[LEGEND HTN] Persons with hepatic failure"] <- "Hepatic failure"
#outcomeOfInterest$outcomeName[outcomeOfInterest$outcomeName == "[LEGEND HTN] Acute pancreatitis events"] <- "Acute pancreatitis"
#exposureOfInterest$exposureName[exposureOfInterest$exposureName == "[OHDSI-Covid19] Hydroxychloroquine + Azithromycin"] <- "Hydroxychloroquine + Azithromycin with prior RA"
#exposureOfInterest$exposureName[exposureOfInterest$exposureName == "[OHDSI Cov19] New users of Hydroxychloroquine with prior rheumatoid arthritis"] <- "Hydroxychloroquine with prior RA"