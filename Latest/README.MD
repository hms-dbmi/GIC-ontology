Below are the general steps to populate data in HPDS in ACT format.

1. Load data from the ACT drop box into the staging table. In addition, populate source system specific mappings with lab result and visit type as provided by BCH.
2. Populate the database table TM_CZ.HPDS_DATA_LATEST with your source data using ACT ontology.
3. Upload data from the TM_CZ.HPDS_DATA_LATEST table into HPDS using either a CSV file loader or a SQL Load.

## Step 1 
### Load data from the ACT drop box into the staging table.

There are two database scripts:
- PRC_CRT_TABLES_ACT_HPDS_LOAD.sql - This script creates objects needed for the compilation of database package. 
- TM_DATA_ACT_LOAD_PKG.TM_DATA_ACT_LOAD_PKG.sql - This package contains database scripts to create BCH to ACT ontology mapping, and then extracts HPDS data in ACT format.

1. Before you can extract ACT HPDS data, you must stage data files from the folder Latest/ACT_HPDS_Datafiles, which are orignally from the ACT drop box, into the following database tables:

- tm_cz.ACT_CPT_PX_2018AA_HPDS 
- tm_cz.ACT_ICD10CM_DX_2018AA_HPDS 
- tm_cz.NCATS_DEMOGRAPHICS_HPDS 
- tm_cz.NCATS_LABS_HPDS 
- tm_cz.NCATS_VISIT_DETAILS_HPDS 
- tm_cz.act_covid_hpds
- tm_cz.ncats_icd10_icd9_dx_v1_hpds

2. There are additional source system specific data mapping files located in the folder Latest/Datafiles_HPDS/SQL that should load data into the following tables:

- tm_cz.a_lab_cd_act_bch_map: should be populated with source system lab_cd to Loinc_cd.
- tm_cz.a_ncats_visit_details_map: should be populated with source system visit_type cd to ACT visit_type code.

## Step 2
### Populate the database table TM_CZ.HPDS_DATA_LATEST with your source data using ACT ontology

1. Run TM_DATA_ACT_LOAD_PKG.Run_MAP_Data_Load to populate the data mapping table tm_cz.ACT_BCH_ONTOLOGY_MAP, which creates mapping between your source system and ACT ontology mapping, depending upon the concept_cd naming convention used in your source system you might have to tweak the matching logic if no match is found for any of the ontology nodes.

2. Run TM_DATA_ACT_LOAD_PKG.Run_EXTRCT_HPDS_Data, which extracts HPDS data in ACT format to the TM_CZ.HPDS_DATA_LATEST table.

## Step 3
### Upload Data into HPDS 
To upload data into HPDS, there are two options:

1. Load HPDS Data from CSV using the Jenkins job - "Load HPDS Data From CSV" in [https://github.com/hms-dbmi/pic-sure-all-in-one](https://github.com/hms-dbmi/pic-sure-all-in-one) 

Generate the source file from the TM_CZ.HPDS_DATA_LATEST database table, which is populated with ACT data in steps 1 and 2. 

This job loads HPDS data from /usr/local/docker-config/hpds_csv/allConcepts.csv

That file then starts with this header:

"PATIENT_NUM","CONCEPT_PATH","NVAL_NUM","TVAL_CHAR","TIMESTAMP"

The corresponding columns are:

- PATIENT_NUM: This is an integer value identifying the subject of the recorded observation fact.

- CONCEPT_PATH: This is an identifier for the concept of the observation fact. For compatibility with the PIC-SURE UI this path should represent a location in a hierarchy where each level is separated by a backslash and with a leading and trailing backslash. For example "\demographics\AGE\" would be the age in the default NHANES dataset. In general this can be any string value, so the UI will display whatever is inside HPDS. If this HPDS instance is part of a PIC-SURE networked environment the same concept paths should be used in all sites involved in the network so that queries can be federated across the network.

- NVAL_NUM: A numeric value if this is a numeric concept, otherwise blank.

- TVAL_CHAR: A text value if this is a categorical concept, otherwise blank.

- TIMESTAMP: A timestamp for the observation fact, this should be expressed as the number of milliseconds since January 1, 1970 GMT. This is equivalent to the Unix Epoch time value for the time of the observation multiplied by 1000.


2. Load HPDS Data Using SQL Loader

Login on to ETL server
clone hpds-etl repo https://github.com/hms-dbmi/pic-sure-hpds/tree/master/docker/pic-sure-hpds-etl
cd /pic-sure-hpds/docker/pic-sure-hpds-etl/hpds/

Modify the following 3 files:
- sql.properties - with oracle database connect string
datasource.password=< your password >
datasource.user=< your user >
datasource.url=< your db connection string (currently only oracle) sampleformat jdbc:oracle:thin:@aaaabbbb.us-east.rds.amazonaws.com:1521/ORCL >
- loadQuery.sql - Modify to as listed.
SELECT PATIENT_NUM, CONCEPT_PATH, NVAL_NUM, TVAL_CHAR,START_DATE FROM TM_CZ.HPDS_DATA_LATEST ORDER BY CONCEPT_PATH, PATIENT_NUM,START_DATE
- Encryption_key- select any 32 character hexadecimal encryption key, lowercase a-f and numerals only
cd ..
docker-compose -f docker-compose-sql-loader.yml up
after the ETL extract process completes it generates listed 2 new files in /pic-sure-hpds/docker/pic-sure-hpds-etl/hpds/
columnMeta.javabin
allObservationsStore.javabin

Login to the Application server.
Copy the new files above and encryption_key on to App server eg in /scratch/act/act_test_phenotype_date_1
modify ../hpds-test-dataload/pic-sure-hpds-phenotype-load-example/docker-compose.yml to map to these datafile for phenotype data source as listed
volumes:
/scratch/act/act_test_phenotype_date_1:/opt/local/hpds docker-compose up -d
