/*CUSTOM CODE TO TRIM TO END OF 90th YEAR AND 365 DAYS AFTER COHORT_START*/
WITH CTE_GET_END_DATES AS (
	SELECT c.COHORT_DEFINITION_ID, c.SUBJECT_ID, c.COHORT_START_DATE, 
		c.COHORT_END_DATE, 
		CASE WHEN p.YEAR_OF_BIRTH+89 < YEAR(c.COHORT_END_DATE) THEN DATEFROMPARTS (p.YEAR_OF_BIRTH+89,12,31)  ELSE c.COHORT_END_DATE END AS COHORT_END_DATE_89YRS, /*Trim the end date to the 89th year*/
		CASE WHEN DATEADD(dd,365,c.COHORT_START_DATE) < c.COHORT_END_DATE THEN DATEADD(dd,365,c.COHORT_START_DATE)  ELSE c.COHORT_END_DATE END AS COHORT_END_DATE_365DAYS /*Trim the end date to 365*/
	FROM @cohortDatabaseSchema.@cohortTable c
		JOIN @cdmDatabaseSchema.PERSON p
			ON p.PERSON_ID = c.SUBJECT_ID
	WHERE COHORT_DEFINITION_ID = @cohortId
),
CTE_PICK_END_DATE AS (
  SELECT COHORT_DEFINITION_ID, SUBJECT_ID, COHORT_START_DATE, COHORT_END_DATE,
  	CASE 
  		WHEN COHORT_END_DATE <= COHORT_END_DATE_89YRS AND COHORT_END_DATE <= COHORT_END_DATE_365DAYS THEN COHORT_END_DATE
  		WHEN COHORT_END_DATE_89YRS < COHORT_END_DATE AND COHORT_END_DATE_89YRS < COHORT_END_DATE_365DAYS THEN COHORT_END_DATE_89YRS
  		WHEN COHORT_END_DATE_365DAYS < COHORT_END_DATE AND COHORT_END_DATE_365DAYS < COHORT_END_DATE_89YRS THEN COHORT_END_DATE_365DAYS
  		ELSE DATEFROMPARTS (2999,12,31)
  	END COHORT_END_DATE_CALC
  FROM CTE_GET_END_DATES
)
SELECT *
INTO #PICK_END_DATE
FROM CTE_PICK_END_DATE;

UPDATE @cohortDatabaseSchema.@cohortTable 
SET @cohortDatabaseSchema.@cohortTable.COHORT_END_DATE = #PICK_END_DATE.COHORT_END_DATE_CALC
FROM #PICK_END_DATE 
WHERE #PICK_END_DATE.COHORT_DEFINITION_ID = @cohortDatabaseSchema.@cohortTable.COHORT_DEFINITION_ID
AND #PICK_END_DATE.SUBJECT_ID = @cohortDatabaseSchema.@cohortTable.SUBJECT_ID
AND #PICK_END_DATE.COHORT_START_DATE = @cohortDatabaseSchema.@cohortTable.COHORT_START_DATE
AND #PICK_END_DATE.COHORT_END_DATE_CALC != @cohortDatabaseSchema.@cohortTable.COHORT_END_DATE;
