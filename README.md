Scripts have to be deployed in listed order to convert i2b2TM data into HPDS ACT ontology format.

1.ACT_HPDS_01_Table_Create.sql 

Creates listed tables

	TM_CZ.A_NCATS_DEMOGRAPHICS 
	TM_CZ.A_NCATS_VISIT_DETAILS 
	TM_CZ.A_ACT_ICD10PCS_PX_2018AA_MAP 
	TM_CZ.A_NCATS_ICD10_ICD9_DX_V1_MAP 
	TM_CZ.HPDS_DATA_LATEST 
	
2.ACT_HPDS_02_Data_Load_Manual.sql	

Loads listed data in above created tables, the csv data has has to be imported, sql scripts loads the data directly into tables. 
After that validate the data got loaded correctly.

	data_A_ACT_ICD10PCS_PX_2018AA_MAP.tar.gz
	data_A_NCATS_ICD10_ICD9_DX_V1_MAP.tar.gz
	data_insert_metadata_visits_oracle_V201.sql
	data_insert_ncats_demographics.sql
	
	Should load listed  rows counts
	select count(*) from  TM_CZ.A_NCATS_DEMOGRAPHICS ;          --164
	select count(*) from  TM_CZ.A_NCATS_VISIT_DETAILS ;         --161
	select count(*) from  TM_CZ.A_ACT_ICD10PCS_PX_2018AA_MAP ;  --176544
	select count(*) from  TM_CZ.A_NCATS_ICD10_ICD9_DX_V1_MAP ;  --833228
	
3.ACT_HPDS_03_Demographics_Data_Load.sql	

Loads Demographics data in HPDS ACT format.

4.ACT_HPDS_04_Visit_Data_Load.sql	

Loads Visit data in HPDS ACT format.

5.ACT_HPDS_05_Diagnosis_Data_Load.sql	

Loads Diagnosis data in HPDS ACT format.

6.ACT_HPDS_06_Procedures_Data_Load.sql	

Loads Procedures data in HPDS ACT format.
	
