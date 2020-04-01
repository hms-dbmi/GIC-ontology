This repo has steps to convert i2b2TM data into ACT HPDS data format. 
Following that picsure hpds data extraction and deployment steps.

1.ACT_HPDS_01_Table_Create.sql 

Creates listed tables which have ACT ontology and mappings to convert to ACT format. 

	TM_CZ.A_NCATS_DEMOGRAPHICS 
	TM_CZ.A_NCATS_VISIT_DETAILS 
	TM_CZ.A_ACT_ICD10PCS_PX_2018AA_MAP 
	TM_CZ.A_NCATS_ICD10_ICD9_DX_V1_MAP 
	TM_CZ.HPDS_DATA_LATEST 
	
2.ACT_HPDS_02_Data_Load_Manual.sql	

Loads listed data files in above created tables, the csv data has to be imported, sql scripts loads the data directly into tables. 

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

Loads Demographics fact data in HPDS ACT format.

4.ACT_HPDS_04_Visit_Data_Load.sql	

Loads Visit fact data in HPDS ACT format.

5.ACT_HPDS_05_Diagnosis_Data_Load.sql	

Loads Diagnosis fact data in HPDS ACT format.

6.ACT_HPDS_06_Procedures_Data_Load.sql	

Loads Procedures fact data in HPDS ACT format.
	
***Above steps will populate database table TM_CZ.HPDS_DATA_LATEST with the data in ACT HPDS format***

***Listed are the Steps for extraction of data in javabin format from the database tableand deployment on to App server***

Login on to ETL server

clone hpds-etl repo  https://github.com/hms-dbmi/pic-sure-hpds/tree/master/docker/pic-sure-hpds-etl 

cd /pic-sure-hpds/docker/pic-sure-hpds-etl/hpds/

**Modify listed files 3 files.

1.sql.properties - with oracle database connect string

datasource.password=< your password >
datasource.user=< your user >
datasource.url=< your db connection string (currently only oracle) sampleformat jdbc:oracle:thin:@aaaabbbb.us-east.rds.amazonaws.com:1521/ORCL >

2.loadQuery.sql - Modify to as listed.
SELECT PATIENT_NUM, CONCEPT_PATH, NVAL_NUM, TVAL_CHAR,START_DATE FROM TM_CZ.HPDS_DATA_LATEST  ORDER BY CONCEPT_PATH, PATIENT_NUM

3.Encryption.key- select any 32 character hexadecimal encryption key, lowercase a-f and numerals only

cd ..

docker-compose -f docker-compose-sql-loader.yml up


after the ETL extract process completes it generates listed 2 new files in /pic-sure-hpds/docker/pic-sure-hpds-etl/hpds/

columnMeta.javabin
allObservationsStore.javabin


3.Login on App server.

Copy above created new files + encryption_key on to App server eg in /scratch/act/act_test_phenotype_date_1

modify ../hpds-test-dataload/pic-sure-hpds-phenotype-load-example/docker-compose.yml
to map to these datafile for phenotype data source as listed 

    volumes:
       - /scratch/act/act_test_phenotype_date_1:/opt/local/hpds

docker-compose up -d


