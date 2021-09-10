set define off;

CREATE OR REPLACE  PROCEDURE PRC_CRT_TABLES_ACT_HPDS_LOAD 
    AS
    v_sql varchar2(4000);
    v_counts  NUMBER;
  BEGIN
  /*
Create By      - Jaspreet Khanna 
Created        - May 2020
Update         - Sep 2021
Prerequisites  -  

Expected Results: Creates listed Objects needed for ACT HPDS data load

*/
  --TM_LOG_PKG.log_msg(p_runid, 'Start PROC_CREATE_TABLES ', 'Y');
  --HPDS_DATA_LATEST
  --VISIT_FACT_DETAILS
  --ACT_BCH_ONTOLOGY_MAP
  --A_NCATS_VISIT_DETAILS_MAP   
  --A_LAB_CD_ACT_BCH_MAP
  --NCATS_VISIT_DETAILS_HPDS
  --NCATS_LABS_HPDS
  --ACT_ICD10CM_DX_2018AA_HPDS
  --ACT_CPT_PX_2018AA_HPDS
  --ETL_RUN_LOG
  --ETL_LOG_SEQ
  --ACT_COVID_HPDS
  --MED_ALPHA_HPDS
  --NCATS_ICD10_ICD9_DX_V1_HPDS

  v_sql := 'CREATE TABLE HPDS_DATA_LATEST '||
   '(PATIENT_NUM NUMBER,  '||
	'CONCEPT_PATH VARCHAR2(4000),  '||
	'NVAL_NUM NUMBER,  '||
	'TVAL_CHAR VARCHAR2(2000),  '||
	'START_DATE DATE '||
    ')  NOCOMPRESS LOGGING ';

    select count(*) into v_counts 
    from dba_tables 
    where table_name = 'HPDS_DATA_LATEST' 
    and owner = 'I2B2_BLUE';
    IF  v_counts = 0 THEN
    execute immediate v_sql;
    END IF;
  v_sql := 'CREATE TABLE ACT_BCH_ONTOLOGY_MAP  '||
   '(ACT_CONCEPT_PATH VARCHAR2(4000),  '||
	'ACT_NAME_CHAR VARCHAR2(2000),  '||
	'ACT_CONCEPT_CD VARCHAR2(400),  '||
	'BCH_CONCEPT_PATH VARCHAR2(4000),  '||
	'BCH_NAME_CHAR VARCHAR2(2000),  '||
	'BCH_CONCEPT_CD VARCHAR2(400),  '||
	'DATA_TYPE VARCHAR2(1000) '||
    ')  NOCOMPRESS LOGGING ';

    select count(*) into v_counts 
    from dba_tables 
    where table_name = 'ACT_BCH_ONTOLOGY_MAP' 
    and owner = 'I2B2_BLUE';
    IF  v_counts = 0 THEN
    execute immediate v_sql;
    END IF;  

  v_sql := 'CREATE TABLE VISIT_FACT_DETAILS   '||
   '(PATIENT_NUM NUMBER,   '||
	'INOUT_CD VARCHAR2(50),   '||
	'LENGTH_OF_STAY NUMBER(38,0),   '||
	'AGE_AT_VISIT_YRS NUMBER,   '||
	'START_DATE DATE  '||
    ') NOCOMPRESS LOGGING ';

    select count(*) into v_counts 
    from dba_tables 
    where table_name = 'VISIT_FACT_DETAILS' 
    and owner = 'I2B2_BLUE';
    IF  v_counts = 0 THEN
    execute immediate v_sql;
    END IF;

   v_sql := 'CREATE TABLE A_NCATS_VISIT_DETAILS_MAP  '||
   '(BCH_VISIT_TYPE VARCHAR2(500), '||
	'ACT_VISIT_TYPE VARCHAR2(500) )  NOCOMPRESS LOGGING ';

    select count(*) into v_counts 
    from dba_tables 
    where table_name = 'A_NCATS_VISIT_DETAILS_MAP' 
    and owner = 'I2B2_BLUE';
    IF  v_counts = 0 THEN
    execute immediate v_sql;
    END IF;
    v_sql := 'CREATE TABLE A_MED_CD_ACT_BCH_MAP '||
    '(	BCH_CONCEPT_CD VARCHAR2(100),  '||
	'ACT_CONCEPT_CD VARCHAR2(100),  '||
	'BCH_CONCEPT_PATH VARCHAR2(4000) ,  '|| 
	'BCH_NAME_CHAR VARCHAR2(2000) )  '||
    'NOCOMPRESS NOLOGGING ' ;

    select count(*) into v_counts 
    from dba_tables 
    where table_name = 'A_MED_CD_ACT_BCH_MAP' 
    and owner = 'I2B2_BLUE';

    IF  v_counts = 0 THEN
    execute immediate v_sql;
    END IF;

    v_sql := 'CREATE TABLE A_LAB_CD_ACT_BCH_MAP   '||
             '( BCH_LAB_CODE VARCHAR2(500),   '||
	         'LOINC_LAB_CODE VARCHAR2(500)  '||
             ' )  NOCOMPRESS LOGGING ';

    select count(*) into v_counts 
    from dba_tables 
    where table_name = 'A_LAB_CD_ACT_BCH_MAP' 
    and owner = 'I2B2_BLUE';
    IF  v_counts = 0 THEN
    execute immediate v_sql;
    END IF;

    v_sql := 'CREATE TABLE NCATS_VISIT_DETAILS_HPDS ( '||
    'C_FULLNAME VARCHAR2(4000), '||
	'C_NAME VARCHAR2(4000), '|| 
	'C_BASECODE VARCHAR2(100),  '||
	'HPDS_PATH VARCHAR2(4000) )  '||
    'NOCOMPRESS NOLOGGING ';

    select count(*) into v_counts 
    from dba_tables 
    where table_name = 'NCATS_VISIT_DETAILS_HPDS' 
    and owner = 'I2B2_BLUE';
    IF  v_counts = 0 THEN
    execute immediate v_sql;
    END IF;

    v_sql := 'CREATE TABLE NCATS_DEMOGRAPHICS_HPDS ( '||
    'C_FULLNAME VARCHAR2(4000), '||
	'C_NAME VARCHAR2(4000), '|| 
	'C_BASECODE VARCHAR2(100),  '||
	'HPDS_PATH VARCHAR2(4000) )  '||
    'NOCOMPRESS NOLOGGING ';

    select count(*) into v_counts 
    from dba_tables 
    where table_name = 'NCATS_DEMOGRAPHICS_HPDS' 
    and owner = 'I2B2_BLUE';
    IF  v_counts = 0 THEN
    execute immediate v_sql;
    END IF;

    v_sql := 'CREATE TABLE NCATS_LABS_HPDS ( '||
    'C_FULLNAME VARCHAR2(4000), '||
	'C_NAME VARCHAR2(4000), '|| 
	'C_BASECODE VARCHAR2(100),  '||
	'HPDS_PATH VARCHAR2(4000) )  '||
    'NOCOMPRESS NOLOGGING ';

    select count(*) into v_counts 
    from dba_tables 
    where table_name = 'NCATS_LABS_HPDS' 
    and owner = 'I2B2_BLUE';
    IF  v_counts = 0 THEN
    execute immediate v_sql;
    END IF;

    v_sql := 'CREATE TABLE ACT_ICD10CM_DX_2018AA_HPDS ( '||
    'C_FULLNAME VARCHAR2(4000), '||
	'C_NAME VARCHAR2(4000), '|| 
	'C_BASECODE VARCHAR2(100),  '||
	'HPDS_PATH VARCHAR2(4000) )  '||
    'NOCOMPRESS NOLOGGING ';
    select count(*) into v_counts 
    from dba_tables 
    where table_name = 'ACT_ICD10CM_DX_2018AA_HPDS' 
    and owner = 'I2B2_BLUE';
    IF  v_counts = 0 THEN
    execute immediate v_sql;
    END IF;


    v_sql := 'CREATE TABLE ACT_CPT_PX_2018AA_HPDS ( '||
    'C_FULLNAME VARCHAR2(4000), '||
	'C_NAME VARCHAR2(4000), '|| 
	'C_BASECODE VARCHAR2(100),  '||
	'HPDS_PATH VARCHAR2(4000) )  '||
    'NOCOMPRESS NOLOGGING ';
    
    select count(*) into v_counts 
    from dba_tables 
    where table_name = 'ACT_CPT_PX_2018AA_HPDS' 
    and owner = 'I2B2_BLUE';
    IF  v_counts = 0 THEN
    execute immediate v_sql;
    END IF;


    v_sql := '  CREATE TABLE ETL_RUN_LOG '||
    '(	LOG_ID NUMBER NOT NULL ENABLE, '||
	'RUN_ID NUMBER NOT NULL ENABLE, '||
	'LOG_MESSAGE VARCHAR2(4000 BYTE) NOT NULL ENABLE, '||
	'LOG_MESSAGE_TYPE VARCHAR2(32 BYTE) NOT NULL ENABLE, '||
	'LOG_TIMESTAMP TIMESTAMP (6) WITH LOCAL TIME ZONE NOT NULL ENABLE, '||
	'LOG_SESSION_ID VARCHAR2(32 BYTE) '||
    ' ) NOCOMPRESS LOGGING ' ;

    select count(*) into v_counts 
    from dba_tables 
    where table_name = 'ETL_RUN_LOG' 
    and owner = 'I2B2_BLUE';
    IF  v_counts = 0 THEN
    execute immediate v_sql;
    END IF;

     v_sql := 'CREATE TABLE NCATS_ICD10_ICD9_DX_V1_HPDS ( '||
    'C_FULLNAME VARCHAR2(4000), '||
	'C_NAME VARCHAR2(4000), '|| 
	'C_BASECODE VARCHAR2(100),  '||
	'HPDS_PATH VARCHAR2(4000) )  '||
    'NOCOMPRESS NOLOGGING ';

    select count(*) into v_counts 
    from dba_tables 
    where table_name = 'NCATS_ICD10_ICD9_DX_V1_HPDS' 
    and owner = 'I2B2_BLUE';
    IF  v_counts = 0 THEN
    execute immediate v_sql;
    END IF;
     v_sql := 'CREATE TABLE MED_ALPHA_HPDS ( '||
    'C_FULLNAME VARCHAR2(4000), '||
	'C_NAME VARCHAR2(4000), '|| 
	'C_BASECODE VARCHAR2(100),  '||
	'HPDS_PATH VARCHAR2(4000) )  '||
    'NOCOMPRESS NOLOGGING ';

    select count(*) into v_counts 
    from dba_tables 
    where table_name = 'MED_ALPHA_HPDS' 
    and owner = 'I2B2_BLUE';

    IF  v_counts = 0 THEN
        execute immediate v_sql;
    END IF;

      v_sql := 'CREATE TABLE ACT_COVID_HPDS ( '||
    'C_FULLNAME VARCHAR2(4000), '||
	'C_NAME VARCHAR2(4000), '|| 
	'C_BASECODE VARCHAR2(100),  '||
	'HPDS_PATH VARCHAR2(4000) )  '||
    'NOCOMPRESS NOLOGGING ';

    select count(*) into v_counts 
    from dba_tables 
    where table_name = 'ACT_COVID_HPDS' 
    and owner = 'I2B2_BLUE';
    IF  v_counts = 0 THEN
    execute immediate v_sql;
    END IF;

    v_sql := '  CREATE SEQUENCE  ETL_LOG_SEQ  MINVALUE 1 '||
    ' MAXVALUE 999999999999999999999999999 INCREMENT BY 1 START WITH 1 CACHE 20 NOCYCLE ORDER ';

    select count(*) into v_counts 
    from dba_objects
    where object_name = 'ETL_LOG_SEQ' 
    and object_type = 'SEQUENCE'
    and owner = 'I2B2_BLUE';
    IF  v_counts = 0 THEN
    execute immediate v_sql;
 
    END IF;

  END;

/
