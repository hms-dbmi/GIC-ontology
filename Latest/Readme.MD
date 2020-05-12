This repo has steps to convert i2b2TM data into ACT HPDS data format, following that picsure hpds data extraction and deployment steps are there.

There are two database scripts
PRC_CRT_TABLES_ACT_HPDS_LOAD.sql - Creates objects needed for the compilation of TM_DATA_ACT_LOAD_PKG.
TM_DATA_ACT_LOAD_PKG.sql         - This Package has database scripts to create BCH to ACT ontology mapping, 
and then extract HPDS data in ACT format.

Pre-requiste to run the ACT HPDS extract is to stage datafiles in folder Latest/ACT_HPDS_Datafiles 
Into database table listed.
	tm_cz.ACT_CPT_PX_2018AA_HPDS
	tm_cz.ACT_ICD10CM_DX_2018AA_HPDS
	tm_cz.NCATS_DEMOGRAPHICS_HPDS	
	tm_cz.NCATS_LABS_HPDS
	tm_cz.NCATS_VISIT_DETAILS_HPDS
Using files
	ACT_CPT_PX_2018AA_HPDS.csv	
	ACT_ICD10CM_DX_2018AA_HPDS.csv.gz
	NCATS_DEMOGRAPHICS_HPDS.csv	
	NCATS_LABS_HPDS.csv	
	NCATS_VISIT_DETAILS_HPDS.csv

datafiles in folder Latest/Datafiles_HPDS/SQL are loaded in listed tables
- tm_cz.a_lab_cd_act_bch_map - should be populated with source system lab_cd to Loinc_cd 
- tm_cz.a_ncats_visit_details_map - should be populated with source system visit_type cd to ACT visit_type code.

After that procedure TM_DATA_ACT_LOAD_PKG.Run_MAP_Data_Load (p_runid  IN NUMBER ) is run to populate 
table tm_cz.ACT_BCH_ONTOLOGY_MAP which creates mapping between your sourcesystem and ACT ontology mapping, depending upon the concept_cd naming convention used in your sourcesystem you might have to tweak the matching logic if not populated for any node.

After that TM_DATA_ACT_LOAD_PKG.Run_EXTRCT_HPDS_Data (p_runid  IN NUMBER )
Which i2b2 tables and  tm_cz.ACT_BCH_ONTOLOGY_MAP and extracts data in table TM_CZ.HPDS_DATA_LATEST.

Listed are the Steps for extraction of data in javabin format from the database table and deployment on to App server

Login on to ETL server

clone hpds-etl repo https://github.com/hms-dbmi/pic-sure-hpds/tree/master/docker/pic-sure-hpds-etl

cd /pic-sure-hpds/docker/pic-sure-hpds-etl/hpds/

**Modify listed 3 files.

1 sql.properties - with oracle database connect string

datasource.password=< your password >

datasource.user=< your user >

datasource.url=< your db connection string (currently only oracle) sampleformat jdbc:oracle:thin:@aaaabbbb.us-east.rds.amazonaws.com:1521/ORCL >

2 loadQuery.sql - Modify to as listed.

SELECT PATIENT_NUM, CONCEPT_PATH, NVAL_NUM, TVAL_CHAR,START_DATE FROM TM_CZ.HPDS_DATA_LATEST ORDER BY CONCEPT_PATH, PATIENT_NUM

3 Encryption.key- select any 32 character hexadecimal encryption key, lowercase a-f and numerals only

cd ..

docker-compose -f docker-compose-sql-loader.yml up

after the ETL extract process completes it generates listed 2 new files in /pic-sure-hpds/docker/pic-sure-hpds-etl/hpds/

columnMeta.javabin

allObservationsStore.javabin

3.Login on App server.

Copy above created new files + encryption_key on to App server eg in /scratch/act/act_test_phenotype_date_1

modify ../hpds-test-dataload/pic-sure-hpds-phenotype-load-example/docker-compose.yml to map to these datafile for phenotype data source as listed

volumes:
   - /scratch/act/act_test_phenotype_date_1:/opt/local/hpds
docker-compose up -d
