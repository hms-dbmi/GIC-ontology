High level steps required to generate the GIC java bin using CSV loader Jenkins job. 

Steps|Details
-----|-------
1 | Download the 8 GIC ACT ontology files from this git repo.
2 | Create mapping between your institute's ontology and the GIC ACT ontology files downloaded from the git repo.
3 | Extract your institute's fact data into HPDS format using the above created ontology mapping into a csv file.
4 | Use the CSV loader Jenkins job generate java bin files.
5 | Deploy generated java bins into various PIC-SURE application environments.

#### Step 1: Load the GIC ACT ontology data files into individual staging tables at your institute’s database. <br>
Ontology data has following columns:
 
ColumnName|OracleDatabaseDataType|Description|
----------|----------|----------
C_FULLNAME|Varchar2(4000)|Has standard ontology path for given c_basecode
C_NAME|Varchar2(4000)|Has standard name string for given c_basecode
C_BASECODE|Varchar2(100)|ACT standard code, which is one of the standard ontology.
HPDS_PATH|Varchar2(4000)|Expanded standard ontology path for given c_fullname

 
##### GIC ACT ontology data files:
* ACT_COVID_HPDS.dsv
* ACT_CPT_PX_2018AA_HPDS.dsv
* ACT_ICD10CM_DX_2018AA_HPDS.dsv
* ACT_MED_ALPHA_HPDS.dsv
* GIC_BIOSAMPLES_HPDS.dsv
* NCATS_DEMOGRAPHICS_HPDS.dsv
* NCATS_LABS_HPDS.dsv
* NCATS_VISIT_DETAILS_HPDS.dsv

#### Step 2: Map your institute’s data to the GIC ACT ontology.<br>
* Map your institute’s ontology to the GIC ACT ontology mapping files listed in Step 1. This process is different for each institution. For an example, visit the  Boston Children’s Hospital mapping [here](https://github.com/hms-dbmi/i2b2ACTtoHPDS/tree/BCH_ACT_Mappings/BCH%20files).

* Using the above created ontology mapping extract your institute’s fact data with GIC ACT ontology into allConcepts.csv file, listed are the details on the data attributes of the file.
* This file should have a header: "PATIENT_NUM","CONCEPT_PATH","NVAL_NUM","TVAL_CHAR","TIMESTAMP" 
* Data has to be sorted by concept_cd, patient_num,TIMESTAMP
 
HPDS Header| Details
----|----
PATIENT_NUM| Patient_num corresponding to the fact record.This is an integer value identifying the subject of the recorded observation fact.
CONCEPT_PATH|HPDS_PATH corresponds to the fact concept_cd from the mapping files listed above. This is an identifier for the concept of the observation fact. For compatibility with the PIC-SURE UI this path should represent a location in a hierarchy where each level is separated by a backslash and with a leading and trailing backslash. For example "\ACT demographics\AGE\\" would be the age for GIC. In general this can be any string value, so the UI will display whatever is inside HPDS. If this HPDS instance is part of a PIC-SURE networked environment, such as GIC, the same concept paths need to be used by all sites involved in the network so that queries can be federated across the network.
NVAL_NUM|A numeric value if this is a numeric concept, otherwise blank.
TVAL_CHAR|For categorical values: Find the records in the mapping file which matches the concept_path for this record and choose appropriate c_name value. For numerical values: It will always be ‘E’ .
TIMESTAMP|A timestamp for the observation fact record should be expressed as the number of milliseconds since January 1, 1970 GMT. This is equivalent to the Unix Epoch time value for the time of the observation multiplied by 1000.

 
#### Step 3: Extract / deploy java bin files from CSV file into the institute’s HPDS development environment <br>
Development Environment: Institute’s should load their data into their institute’s PIC-SURE development environment first, prior to loading their data into the production environment. 

##### Load HPDS Data From CSV using Jenkins job <br>
* Copy the above generated file allConcepts.csv in location /usr/local/docker-config/hpds_csv/allConcepts.csv.
* The “Load HPDS Data From CSV” Jenkins’ job extracts HPDS java bin data using the below files: 
  * /usr/local/docker-config/hpds_csv/allConcepts.csv
* The following bin files are generated in /usr/local/docker-config/hpds
  * allObservationsStore.javabin  
  * columnMeta.javabin  
#### STEP 4: Deploy data into the PIC-SURE environment. <br>
* After the bin files are generated, then restart PIC-SURE using the Jenkins job “Start PIC-SURE”. This will refresh data in the development environment.
 
* Quality Assurance Tests: Run the tests list in Step 5, as well as your own institute’s test to confirm the data is in the correct GIC ACT ontology format. 
* To deploy to any other environment, including your institute’s Production environment, login to the environment’s application server. Copy the new bin files generated and encryption_key  in /usr/local/docker-config/hpds
  * allObservationsStore.javabin 
  * columnMeta.javabin  
  * encryption_key
  
 
* Then restart PIC-SURE on the application's server using the Jenkins job “Start PIC-SURE”. This will refresh data in the environment.
 
 
#### Step 5: Quality Assurance Tests <br>
Below is a list of basic smoke tests institutions should run after the data has been loaded.  Each institution should run their own tests as it pertains to their data. <br>

Test: Search demographic age<br>
Expected result: Verify age returns a numerical value (example: 5), not a categorical value (example: Visit at age 01 months). Verify age is not a negative number. Verify there are no invalid birthdates: 01/01/0001 07/18/2096. Verify that there are no patients with NULL age.

Test: Search gender<br>
Expected result: Verify gender codes other than Male, Female, Ambiguous, Other, and No Information do not exist.

Test: Search negative patient_num<br>
Expected result: Verify negative patient_num do not exist.

Test: Search race<br>
Expected result: Confirm race codes other than Hispanic, American Indian or Alaska Native, Asian, Black or African American, Multiple race, Native Hawaiian or Other Pacific Islander, White, or No Information do not exist. 

Test: Search negative patient_num<br>
Expected result: Verify patient_num with negative numbers does not exist.

Test: Search visit details, age at visit<br>
Expected result: Verify age at visit returns a numerical value (example: 5), not a categorical value (example: Visit at age 01 months). Verify age is not a negative number. 

Test: Lab results <br>
Expected result: Verify that lab results are numeric values. 
