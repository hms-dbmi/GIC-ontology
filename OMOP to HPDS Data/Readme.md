*OMOP to HPDS Data*
The tables contained in this directory map ACT paths and ACT codes  to HPDS Paths to OMOP Standard and Source Concept IDs. They can be
used to map from OMOP CDM to HPDS format. 

The files are tab separated.

The files use the ACT V2.0.1 version of the ontology. The majority of the ontologies are sourced from UMLS. The ACT network is currently using V4 of the ontology and includes historical paths.

Columns in each file are:
- ACT_C_FULLNAME	 - The C_FULLNAME field from act metadata tables. The paths should be comprised of UMLS AUIs where ever possible. 
- OMOP_S_CONCEPT_ID	 - OMOP Standard Concept ID - These are only filled in for concept_ids that have a one-to one mapping to source. 
- OMOP_NS_CONCEPT_ID	- OMOP Source Concept ID - Every source concept should have on of these. If it is standard vocabulary ( RxNorm, LOINC, etc) they match exactly to Standard Concept IDs.
- C_NAME	- Concept description
- C_BASECODE	- Standard terminology code with prefix, i.e. ICD10CM:C50, LOINC:1988-5.
- HPDS_PATH - Path used in HPDS which is comprised of parent hierarchy of C_NAME strings




Notes:
https://docs.google.com/document/d/1QEYkY3SWhxz04SkI6G8bXJDy530WmdX1CmnbkieWYB8/edit
