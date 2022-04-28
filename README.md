Comparing the Estimated Risk of Hip Fracture Among Subjects Exposed to Tramadol as Compared to Subjects Exposed to Codeine
=============

<img src="https://img.shields.io/badge/Study%20Status-Design%20Finalized-brightgreen.svg" alt="Study Status: Design Finalized">

- Analytics use case(s): **Population-Level Estimation**
- Study type: **Clinical Application**
- Tags: **tramadol, codeine, hip fracture**
- Study lead: **Erica A Voss**
- Study lead forums tag: **[Erica A Voss](https://www.ohdsi.org/who-we-are/collaborators/erica-voss/)**
- Study start date: **Feb 19, 2020**
- Study end date: **-**
- Protocol: **[Protocol - Tramadol vs Codeine and Risk of Hip Fracture](https://github.com/ohdsi-studies/TramadolVsCodeineForHipFracture/blob/master/Protocol%20-%20Tramadol%20Codeine%20and%20Risk%20of%20Hip%20Fracture%20-%20Amendment.docx)**
- Publications: **-**
- Results explorer: **-**

Hip fractures greatly impact an individual’s quality of life and carry a high risk of death within 1 year. Tramadol is a commonly used weak opioid for treatment of pain. A recent study by Wei et al. found that risk for hip fractures was higher for new users of tramadol than for new users of codeine or NSAIDs.  We were concerned of that study’s design choices because of several limitations such as: A less-than-optimal propensity score adjustment strategy, the absence of negative controls, the failure to address possible differences in the initial doses of tramadol versus codeine, and the fact that the study was done in only one data source limited to one countries data. We propose to do a study to assess hip fracture incidence among users of tramadol versus codeine that will reassess the relationship and address the Wei et al. study limitations. 

[Wei, J., et al., Association of Tramadol Use With Risk of Hip Fracture. J Bone Miner Res, 2020.](https://doi.org/10.1002/jbmr.3935)

Package Overview
=============
|Location| Content|
|-|-|
|Protocol - Tramadol vs Codeine and Risk of Hip Fracture.docx| The protocol is found at the root. |
|programs/epi756CohortDiagnostics/epi756CohortDiagnostics.R|The R script to run CohortDiagnostics on the cohorts in this study|
|programs/epi756CohortDiagnostics/epi756CohortDiagnostics.R|The R script to run CohortDiagnostics on the cohorts in this study|
|programs/epi756PV/PheValuatorRCodeForAnalysis.R| The R Script to run PheValuator, with focus on the Hip Fracture cohorts |
|programs/epi756A###| For each analysis (101, 102, 201, 202, 301, 302) outlined in the protocol, there is a study package.  Each package has a "extras/CodeToRun.R" file which executes the packages.  The following needs to be set for your evironment:  fftempdir, studyFolder, and the createConnectiongDetails.  The ReadMe within each package also provides more details.|

License
=============
The TramadolVsCodeineForHipFracture package is licensed under Apache License 2.0