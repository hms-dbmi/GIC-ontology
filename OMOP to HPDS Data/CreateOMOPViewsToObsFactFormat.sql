
  CREATE OR REPLACE FORCE EDITIONABLE VIEW "NCATSTEST_CRCDATA"."CONDITION_VIEW" ("PATIENT_NUM", "CONCEPT_CD", "ENCOUNTER_NUM", "INSTANCE_NUM", "PROVIDER_ID", "START_DATE", "MODIFIER_CD", "OBSERVATION_BLOB", "VALTYPE_CD", "TVAL_CHAR", "NVAL_NUM", "VALUEFLAG_CD", "QUANTITY_NUM", "UNITS_CD", "END_DATE", "LOCATION_CD", "CONFIDENCE_NUM", "SOURCESYSTEM_CD", "UPDATE_DATE", "DOWNLOAD_DATE", "IMPORT_DATE", "UPLOAD_ID") AS 
  SELECT
	PERSON_ID,
	TO_CHAR(CONDITION_CONCEPT_ID),
	VISIT_OCCURRENCE_ID,
	1,
	PROVIDER_ID,
	CONDITION_START_DATE,
	'@',
	NULL,
	NULL,
	NULL,
	NULL,
	NULL,
	NULL,
	NULL,
	NULL,
	NULL,
	NULL,
	NULL,
	NULL,
	NULL,
	NULL,
	NULL 
FROM
	CONDITION_OCCURRENCE;


  CREATE OR REPLACE FORCE EDITIONABLE VIEW "NCATSTEST_CRCDATA"."PROCEDURE_VIEW" ("PATIENT_NUM", "CONCEPT_CD", "ENCOUNTER_NUM", "INSTANCE_NUM", "PROVIDER_ID", "START_DATE", "MODIFIER_CD", "OBSERVATION_BLOB", "VALTYPE_CD", "TVAL_CHAR", "NVAL_NUM", "VALUEFLAG_CD", "QUANTITY_NUM", "UNITS_CD", "END_DATE", "LOCATION_CD", "CONFIDENCE_NUM", "SOURCESYSTEM_CD", "UPDATE_DATE", "DOWNLOAD_DATE", "IMPORT_DATE", "UPLOAD_ID") AS 
  SELECT
	PERSON_ID ,
	TO_CHAR(PROCEDURE_CONCEPT_ID),
	VISIT_OCCURRENCE_ID ,
	1,
	PROVIDER_ID,
	PROCEDURE_DATE,
	'@',
	NULL,
	NULL,
	NULL,
	NULL,
	NULL,
	NULL,
	NULL,
	NULL,
	NULL,
	NULL,
	NULL,
	NULL,
	NULL,
	NULL,
	NULL 
FROM
	PROCEDURE_OCCURRENCE;

  CREATE OR REPLACE FORCE EDITIONABLE VIEW "NCATSTEST_CRCDATA"."MEASUREMENT_VIEW" ("PATIENT_NUM", "CONCEPT_CD", "ENCOUNTER_NUM", "INSTANCE_NUM", "PROVIDER_ID", "START_DATE", "MODIFIER_CD", "OBSERVATION_BLOB", "VALTYPE_CD", "TVAL_CHAR", "NVAL_NUM", "VALUEFLAG_CD", "QUANTITY_NUM", "UNITS_CD", "END_DATE", "LOCATION_CD", "CONFIDENCE_NUM", "SOURCESYSTEM_CD", "UPDATE_DATE", "DOWNLOAD_DATE", "IMPORT_DATE", "UPLOAD_ID") AS 
  SELECT
	PERSON_ID,
	TO_CHAR(MEASUREMENT_CONCEPT_ID),
	VISIT_OCCURRENCE_ID ,
	1,
	PROVIDER_ID,
	MEASUREMENT_DATE,
	'@',
	NULL,
	CASE 
		WHEN VALUE_AS_NUMBER IS NOT NULL 
		THEN 'N' 
		ELSE 'T' 
	END,
	CASE 
		WHEN OPERATOR_CONCEPT_ID = 4172703 
		THEN 'E' 
		WHEN OPERATOR_CONCEPT_ID = 4171756 
		THEN 'LT' 
		WHEN OPERATOR_CONCEPT_ID = 4172704 
		THEN 'GT' 
		WHEN OPERATOR_CONCEPT_ID = 4171754 
		THEN 'LE' 
		WHEN OPERATOR_CONCEPT_ID = 4171755 
		THEN 'GE' 
		WHEN OPERATOR_CONCEPT_ID IS NULL 
		THEN 'E' 
		ELSE NULL 
	END,
	VALUE_AS_NUMBER,
	TO_CHAR(VALUE_AS_CONCEPT_ID),
	NULL,
	NULL,
	NULL,
	NULL,
	NULL,
	NULL,
	NULL,
	NULL,
	NULL,
	NULL 
FROM
	MEASUREMENT;

  CREATE OR REPLACE FORCE EDITIONABLE VIEW "NCATSTEST_CRCDATA"."OBSERVATION_VIEW" ("PATIENT_NUM", "CONCEPT_CD", "ENCOUNTER_NUM", "INSTANCE_NUM", "PROVIDER_ID", "START_DATE", "MODIFIER_CD", "OBSERVATION_BLOB", "VALTYPE_CD", "TVAL_CHAR", "NVAL_NUM", "VALUEFLAG_CD", "QUANTITY_NUM", "UNITS_CD", "END_DATE", "LOCATION_CD", "CONFIDENCE_NUM", "SOURCESYSTEM_CD", "UPDATE_DATE", "DOWNLOAD_DATE", "IMPORT_DATE", "UPLOAD_ID") AS 
  SELECT
	PERSON_ID ,
	OBSERVATION_CONCEPT_ID,
	VISIT_OCCURRENCE_ID ,
	1,
	PROVIDER_ID,
	OBSERVATION_DATE,
	'@',
	NULL,
	CASE 
		WHEN VALUE_AS_STRING IS NOT NULL 
		THEN 'T' 
		ELSE 'N' 
	END,
	VALUE_AS_STRING,
	VALUE_AS_NUMBER,
	TO_CHAR(VALUE_AS_CONCEPT_ID),
	NULL,
	NULL,
	NULL,
	NULL,
	NULL,
	NULL,
	NULL,
	NULL,
	NULL,
	NULL 
FROM
	OBSERVATION;


  CREATE OR REPLACE FORCE EDITIONABLE VIEW "NCATSTEST_CRCDATA"."ALL_SOURCE_CONCEPTS" ("ENCOUNTER_NUM", "PATIENT_NUM", "CONCEPT_CD", "PROVIDER_ID", "START_DATE", "END_DATE", "MODIFIER_CD", "INSTANCE_NUM", "VALTYPE_CD", "LOCATION_CD", "TVAL_CHAR", "NVAL_NUM", "VALUEFLAG_CD", "UNITS_CD", "STANDARD_CONCEPT_ID", "SOURCE_VALUE", "DOMAIN_ID") AS 
  SELECT
			ENCOUNTER_NUM, 
 			PATIENT_NUM, 
   			CONCEPT_CD, 
   			PROVIDER_ID, 
   			START_DATE, 
			END_DATE, 
            MODIFIER_CD,
            INSTANCE_NUM,
            valtype_cd,
            location_cd,
            tval_char,
            nval_num,
            valueflag_cd,
            units_cd,
            STANDARD_CONCEPT_ID,
            SOURCE_VALUE,
            DOMAIN_ID
FROM (
 SELECT  
			visit_occurrence_id AS ENCOUNTER_NUM, 
 			PERSON_ID AS PATIENT_NUM, 
   			cast(condition_source_concept_id as varchar2(30)) AS CONCEPT_CD, 
   			provider_id AS PROVIDER_ID, 
   			condition_start_datetime AS START_DATE, 
			condition_end_datetime AS END_DATE, 
            NULL AS MODIFIER_CD,
            NULL AS INSTANCE_NUM,
            NULL AS valtype_cd,
            NULL AS location_cd,
            NULL AS tval_char,
            NULL AS nval_num,
            NULL AS valueflag_cd,
            NULL AS units_cd,
   			condition_concept_id AS STANDARD_CONCEPT_ID,
            condition_source_value AS SOURCE_VALUE,
            'CONDITION' AS DOMAIN_ID
--			condition_occurrence_id integer NOT NULL, 
--			condition_start_datetime TIMESTAMP NULL, 
--			condition_end_datetime TIMESTAMP NULL, 
--			condition_type_concept_id integer NOT NULL, --modifier?
--			stop_reason varchar(20) NULL, 
--			visit_detail_id integer NULL, 
--			condition_status_source_value varchar(50) NULL );  
FROM CONDITION_OCCURRENCE
UNION
--HINT DISTRIBUTE ON KEY (person_id)
 SELECT 
 			visit_occurrence_id AS ENCOUNTER_NUM, 
 			PERSON_ID AS PATIENT_NUM, 
   			cast(drug_source_concept_id as varchar2(30)) AS CONCEPT_CD, 
   			provider_id AS PROVIDER_ID, 
   			drug_exposure_start_datetime AS START_DATE, 
			drug_exposure_END_datetime AS END_DATE, 
            NULL AS MODIFIER_CD,
            NULL AS INSTANCE_NUM,
            NULL AS valtype_cd,
            NULL AS location_cd,
            NULL AS tval_char,
            NULL AS nval_num,
            NULL AS valueflag_cd,
            NULL AS units_cd,
   			drug_concept_id AS STANDARD_CONCEPT_ID,
            drug_source_value AS SOURCE_VALUE,
            'DRUG' AS DOMAIN_ID
--			drug_exposure_start_datetime TIMESTAMP NULL, 
--			drug_exposure_end_datetime TIMESTAMP NULL, 
--			verbatim_end_date date NULL, 
--			drug_type_concept_id integer NOT NULL, 
--			stop_reason varchar(20) NULL, 
--			refills integer NULL, 
--			quantity float NULL, 
--			days_supply integer NULL, 
--			sig CLOB NULL, 
--			route_concept_id integer NULL, 
--			lot_number varchar(50) NULL, 
--			visit_detail_id integer NULL, 
--			route_source_value varchar(50) NULL, 
--			dose_unit_source_value varchar(50) NULL );  
FROM DRUG_EXPOSURE
UNION
--HINT DISTRIBUTE ON KEY (person_id)
SELECT
 			visit_occurrence_id AS ENCOUNTER_NUM, 
 			PERSON_ID AS PATIENT_NUM, 
   			cast(procedure_source_concept_id as varchar2(30)) AS CONCEPT_CD, 
   			provider_id AS PROVIDER_ID, 
   			procedure_datetime AS START_DATE, 
			NULL AS END_DATE, 
            NULL AS MODIFIER_CD,
            NULL AS INSTANCE_NUM,
            NULL AS valtype_cd,
            NULL AS location_cd,
            NULL AS tval_char,
            NULL AS nval_num,
            NULL AS valueflag_cd,
            NULL AS units_cd,
   			procedure_concept_id AS STANDARD_CONCEPT_ID,
            procedure_source_value AS SOURCE_VALUE,
            'PROCEDURE' AS DOMAIN_ID
--			procedure_occurrence_id integer NOT NULL, 
--			procedure_datetime TIMESTAMP NULL, 
--			procedure_type_concept_id integer NOT NULL, 
--			modifier_concept_id integer NULL, 
--			quantity integer NULL, 
--			visit_detail_id integer NULL, 
--			modifier_source_value varchar(50) NULL );  
FROM PROCEDURE_OCCURRENCE
UNION
SELECT 
			visit_occurrence_id AS ENCOUNTER_NUM, 
 			PERSON_ID AS PATIENT_NUM, 
   			cast(device_source_concept_id as varchar2(30)) AS CONCEPT_CD, 
   			provider_id AS PROVIDER_ID, 
   			device_exposure_start_datetime AS START_DATE, 
			device_exposure_end_datetime AS END_DATE, 
            device_type_concept_id AS MODIFIER_CD,
            NULL AS INSTANCE_NUM,
            NULL AS valtype_cd,
            NULL AS location_cd,
            NULL AS tval_char,
            NULL AS nval_num,
            NULL AS valueflag_cd,
            NULL AS units_cd,
   			device_exposure_id AS STANDARD_CONCEPT_ID, --device_concept_id??
            device_source_value AS SOURCE_VALUE,
            'DEVICE' AS DOMAIN_ID
--			device_exposure_start_datetime TIMESTAMP NULL, 
--			device_exposure_end_datetime TIMESTAMP NULL, 
--			unique_device_id varchar(50) NULL, 
--			quantity integer NULL, 
--			visit_detail_id integer NULL, 
FROM DEVICE_EXPOSURE
UNION
SELECT
			visit_occurrence_id AS ENCOUNTER_NUM, 
 			PERSON_ID AS PATIENT_NUM, 
   			cast(measurement_source_concept_id as varchar2(30)) AS CONCEPT_CD, 
   			provider_id AS PROVIDER_ID, 
   			measurement_datetime AS START_DATE, 
			NULL AS END_DATE, 
            measurement_type_concept_id AS MODIFIER_CD,
            NULL AS INSTANCE_NUM,
            NULL AS valtype_cd, --DECODE THIS IS THE FUTURE operator_concept_id
            NULL AS location_cd,
            NVL2(value_as_number, 
                DECODE(operator_concept_id, 4172703, 'E', 4171756, 'LT', 4172704, 'GT', 4171755, 'GE', 4171754, 'LE', 'E'),
                VALUE_SOURCE_VALUE) AS TVAL_CHAR, -- need to decode covid labs
            value_as_number AS nval_num,
            NULL AS valueflag_cd,
            unit_source_value AS units_cd, -- DECODE THIS TO QUERY BY VALUE unit_concept_id IN THE FUTURE FOR NOW JUST USE THE UNIT SOURCE VALUE
   			measurement_concept_id AS STANDARD_CONCEPT_ID, --device_concept_id??
            measurement_source_value AS SOURCE_VALUE,
            'MEASUREMENT' AS DOMAIN_ID
--            value_source_value as value_source_value
--			measurement_id integer NOT NULL, 
--			measurement_datetime TIMESTAMP NULL, 
--			measurement_time varchar(10) NULL, 
--			operator_concept_id integer NULL, -- CHANGE OPERATOR TO OMOP CONCEPT_ID IN ONTOLOGY <, <=, =, >=, >.
--			value_as_concept_id integer NULL
--			range_low float NULL, 
--			range_high float NULL, 
--			visit_detail_id integer NULL, 
--			value_source_value varchar(50) NULL );  
FROM MEASUREMENT --where value_source_value like 'Not%' order by tval_char;
UNION
SELECT 
			visit_occurrence_id AS ENCOUNTER_NUM, 
 			PERSON_ID AS PATIENT_NUM, 
   			cast(observation_source_concept_id as varchar2(30)) AS CONCEPT_CD, 
   			provider_id AS PROVIDER_ID, 
   			observation_datetime AS START_DATE, 
			NULL AS END_DATE, 
            observation_type_concept_id AS MODIFIER_CD,
            NULL AS INSTANCE_NUM,
            NULL AS valtype_cd, --DECODE THIS IS THE FUTURE operator_concept_id
            NULL AS location_cd,
            NVL2(value_as_number, 
                'E',
                VALUE_AS_STRING) AS TVAL_CHAR, -- need to decode covid labs
            value_as_number AS nval_num,
            NULL AS valueflag_cd,
            unit_source_value AS units_cd, -- DECODE THIS TO QUERY BY VALUE unit_concept_id IN THE FUTURE FOR NOW JUST USE THE UNIT SOURCE VALUE
   			observation_concept_id AS STANDARD_CONCEPT_ID, --device_concept_id??
            observation_source_value AS SOURCE_VALUE,
            'OBSERVATION' AS DOMAIN_ID
--            value_source_value as value_source_value
--          value_as_concept_id Integer NULL, 
--			qualifier_concept_id integer NULL, 
--			unit_concept_id integer NULL, 
--			visit_detail_id integer NULL, 
--			qualifier_source_value varchar(50) NULL );  
FROM OBSERVATION);

-- COVID Lab View (Special case for combining Code and Harmonized Lab Value)

CREATE OR REPLACE VIEW VISIT_DIMENSION
	(
		ENCOUNTER_NUM,
		PATIENT_NUM,
		ACTIVE_STATUS_CD,
		START_DATE,
		END_DATE,
		INOUT_CD,
		LOCATION_CD,
		LOCATION_PATH,
		LENGTH_OF_STAY,
		VISIT_BLOB,
		UPDATE_DATE,
		DOWNLOAD_DATE,
		IMPORT_DATE,
		SOURCESYSTEM_CD,
		UPLOAD_ID 
	)
	AS 
SELECT
	VISIT_OCCURRENCE_ID,
	PERSON_ID,
	NULL,
	VISIT_START_DATE,
	VISIT_END_DATE,
	VISIT_CONCEPT_ID, --inout_cd
	CARE_SITE_ID, --location_cd
	NULL, --location_path
	TRUNC(VISIT_END_DATE) - TRUNC(VISIT_START_DATE),
	NULL,
	NULL,
	NULL,
	NULL,
	NULL,
	NULL 
FROM
	VISIT_OCCURRENCE;
commit;

--SELECT * FROM VISIT_DIMENSION;
