create or replace PROCEDURE PRC_CRT_TABLES_ACT_HPDS_LOAD
    AS
    v_sql varchar2(4000);
    v_counts  NUMBER;
  BEGIN
  /*
Create By      - Jaspreet Khanna 
Created        - May 2020
Prerequisites  -  

Expected Results: Creates listed Objects needed for ACT HPDS data load
                
*/
  --TM_LOG_PKG.log_msg(p_runid, 'Start PROC_CREATE_TABLES ', 'Y');
  --tm_cz.HPDS_DATA_LATEST
  
  --tm_cz.VISIT_FACT_DETAILS
    
  --tm_cz.ACT_BCH_ONTOLOGY_MAP
  --tm_cz.A_NCATS_VISIT_DETAILS_MAP   
  --tm_cz.A_LAB_CD_ACT_BCH_MAP
  
  --tm_cz.NCATS_VISIT_DETAILS_HPDS
  --tm_cz.ACT_COVID_V3_HPDS
  --tm_cz.NCATS_LABS_HPDS
  --tm_cz.ACT_ICD10CM_DX_2018AA_HPDS
  --tm_cz.ACT_CPT_PX_2018AA_HPDS
  --tm_cz.ETL_RUN_LOG
  --tm_cz.ETL_LOG_SEQ

  v_sql := 'CREATE TABLE TM_CZ.HPDS_DATA_LATEST '||
   '(PATIENT_NUM NUMBER,  '||
	'CONCEPT_PATH VARCHAR2(4000),  '||
	'NVAL_NUM NUMBER,  '||
	'TVAL_CHAR VARCHAR2(2000),  '||
	'START_DATE TIMESTAMP '||
    ')  NOCOMPRESS LOGGING ';
    dbms_output.put_line( v_sql);

    select count(*) into v_counts 
    from dba_tables 
    where table_name = 'HPDS_DATA_LATEST' 
    and owner = 'TM_CZ';
    IF  v_counts = 0 THEN
    execute immediate v_sql;
    --TM_LOG_PKG.log_msg(p_runid, 'Create Table HPDS_DATA_LATEST '||sql%rowcount, 'Y'); 
    END IF;
  v_sql := 'CREATE TABLE TM_CZ.ACT_BCH_ONTOLOGY_MAP  '||
   '(ACT_CONCEPT_PATH VARCHAR2(4000),  '||
	'ACT_NAME_CHAR VARCHAR2(2000),  '||
	'ACT_CONCEPT_CD VARCHAR2(400),  '||
	'BCH_CONCEPT_PATH VARCHAR2(4000),  '||
	'BCH_NAME_CHAR VARCHAR2(2000),  '||
	'BCH_CONCEPT_CD VARCHAR2(400),  '||
	'DATA_TYPE VARCHAR2(1000) '||
    ')  NOCOMPRESS LOGGING ';


dbms_output.put_line( v_sql);
    select count(*) into v_counts 
    from dba_tables 
    where table_name = 'ACT_BCH_ONTOLOGY_MAP' 
    and owner = 'TM_CZ';
    IF  v_counts = 0 THEN
    execute immediate v_sql;
    --TM_LOG_PKG.log_msg(p_runid, 'Create Table ACT_BCH_ONTOLOGY_MAP '||sql%rowcount, 'Y'); 
    END IF;  

  v_sql := 'CREATE TABLE TM_CZ.VISIT_FACT_DETAILS   '||
   '(PATIENT_NUM NUMBER,   '||
	'INOUT_CD VARCHAR2(50),   '||
	'LENGTH_OF_STAY NUMBER(38,0),   '||
	'AGE_AT_VISIT_YRS NUMBER,   '||
	'START_DATE DATE  '||
    ') NOCOMPRESS LOGGING ';
dbms_output.put_line( v_sql);

    select count(*) into v_counts 
    from dba_tables 
    where table_name = 'VISIT_FACT_DETAILS' 
    and owner = 'TM_CZ';
    IF  v_counts = 0 THEN
    execute immediate v_sql;
    --TM_LOG_PKG.log_msg(p_runid, 'Create Table VISIT_FACT_DETAILS '||sql%rowcount, 'Y'); 
    END IF;

   v_sql := 'CREATE TABLE TM_CZ.A_NCATS_VISIT_DETAILS_MAP  '||
   '(BCH_VISIT_TYPE VARCHAR2(500), '||
	'ACT_VISIT_TYPE VARCHAR2(500) )  NOCOMPRESS LOGGING ';
dbms_output.put_line( v_sql);

    select count(*) into v_counts 
    from dba_tables 
    where table_name = 'A_NCATS_VISIT_DETAILS_MAP' 
    and owner = 'TM_CZ';
    IF  v_counts = 0 THEN
    execute immediate v_sql;
    --TM_LOG_PKG.log_msg(p_runid, 'Create Table A_NCATS_VISIT_DETAILS_MAP '||sql%rowcount, 'Y'); 
    END IF;

  v_sql := 'CREATE TABLE TM_CZ.A_LAB_CD_ACT_BCH_MAP   '||
   '( BCH_LAB_CODE VARCHAR2(500),   '||
	'LOINC_LAB_CODE VARCHAR2(500)  '||
   ' )  NOCOMPRESS LOGGING ';
dbms_output.put_line( v_sql);

    select count(*) into v_counts 
    from dba_tables 
    where table_name = 'A_LAB_CD_ACT_BCH_MAP' 
    and owner = 'TM_CZ';
    IF  v_counts = 0 THEN
    execute immediate v_sql;
    --TM_LOG_PKG.log_msg(p_runid, 'Create Table A_LAB_CD_ACT_BCH_MAP '||sql%rowcount, 'Y'); 
    END IF;

    v_sql := 'CREATE TABLE TM_CZ.NCATS_VISIT_DETAILS_HPDS  '||
   '(	C_HLEVEL VARCHAR2(20),   '||
	'C_FULLNAME VARCHAR2(700),   '||
	'C_NAME VARCHAR2(2000),   '||
	'C_SYNONYM_CD CHAR(1),   '||
	'C_VISUALATTRIBUTES CHAR(3),   '||
	'C_TOTALNUM VARCHAR2(200),   '||
	'C_BASECODE VARCHAR2(50),   '||
	'C_METADATAXML CLOB,   '||
	'C_FACTTABLECOLUMN VARCHAR2(50),  '|| 
	'C_TABLENAME VARCHAR2(50),   '||
	'C_COLUMNNAME VARCHAR2(50),   '||
	'C_COLUMNDATATYPE VARCHAR2(50),  '|| 
	'C_OPERATOR VARCHAR2(10),   '||
	'C_DIMCODE VARCHAR2(700),  '|| 
	'C_COMMENT CLOB,   '||
	'C_TOOLTIP VARCHAR2(900),  '|| 
	'M_APPLIED_PATH VARCHAR2(700),   '||
	'UPDATE_DATE VARCHAR2(50),   '||
	'DOWNLOAD_DATE VARCHAR2(50),   '||
	'IMPORT_DATE VARCHAR2(50),  '||
	'SOURCESYSTEM_CD VARCHAR2(50),   '||
	'VALUETYPE_CD VARCHAR2(50),   '||
	'M_EXCLUSION_CD VARCHAR2(25),   '||
	'C_PATH VARCHAR2(4000),   '||
	'C_SYMBOL VARCHAR2(50),   '||
	'HPDS_PATH VARCHAR2(4000)  '||
    ') NOCOMPRESS LOGGING  '||
    'LOB (C_METADATAXML) STORE AS SECUREFILE (  '||
  'TABLESPACE TRANSMART ENABLE STORAGE IN ROW CHUNK 8192  '||
  'NOCACHE LOGGING  NOCOMPRESS  KEEP_DUPLICATES   '||
  'STORAGE(INITIAL 106496 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645  '||
  'PCTINCREASE 0  '||
  'BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT))   '||
  'LOB (C_COMMENT) STORE AS SECUREFILE (  '||
  'TABLESPACE TRANSMART ENABLE STORAGE IN ROW CHUNK 8192  '||
  'NOCACHE LOGGING  NOCOMPRESS  KEEP_DUPLICATES  '|| 
  'STORAGE(INITIAL 106496 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645  '||
  'PCTINCREASE 0  '||
  'BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)) ';
dbms_output.put_line( v_sql);

    select count(*) into v_counts 
    from dba_tables 
    where table_name = 'NCATS_VISIT_DETAILS_HPDS' 
    and owner = 'TM_CZ';
    IF  v_counts = 0 THEN
    execute immediate v_sql;
    --TM_LOG_PKG.log_msg(p_runid, 'Create Table NCATS_VISIT_DETAILS_HPDS '||sql%rowcount, 'Y'); 
    END IF;
 
    
  
    v_sql := 'create table tm_cz.NCATS_DEMOGRAPHICS_HPDS as select * from tm_cz.NCATS_VISIT_DETAILS_HPDS where 0 > 1';
     
    
    select count(*) into v_counts 
    from dba_tables 
    where table_name = 'NCATS_DEMOGRAPHICS_HPDS' 
    and owner = 'TM_CZ';
    IF  v_counts = 0 THEN
    execute immediate v_sql;
    --TM_LOG_PKG.log_msg(p_runid, 'Create Table NCATS_DEMOGRAPHICS_HPDS '||sql%rowcount, 'Y'); 
    END IF;

    v_sql := 'create table tm_cz.NCATS_LABS_HPDS as select * from tm_cz.NCATS_VISIT_DETAILS_HPDS where 0 > 1';
    
    select count(*) into v_counts 
    from dba_tables 
    where table_name = 'NCATS_LABS_HPDS' 
    and owner = 'TM_CZ';
    IF  v_counts = 0 THEN
    execute immediate v_sql;
    --TM_LOG_PKG.log_msg(p_runid, 'Create Table NCATS_LABS_HPDS '||sql%rowcount, 'Y'); 
    END IF;
    
    
    v_sql := 'create table tm_cz.ACT_ICD10CM_DX_2018AA_HPDS as select * from tm_cz.NCATS_VISIT_DETAILS_HPDS where 0 > 1';
    
    select count(*) into v_counts 
    from dba_tables 
    where table_name = 'ACT_ICD10CM_DX_2018AA_HPDS' 
    and owner = 'TM_CZ';
    IF  v_counts = 0 THEN
    execute immediate v_sql;
    --TM_LOG_PKG.log_msg(p_runid, 'Create Table ACT_ICD10CM_DX_2018AA_HPDS '||sql%rowcount, 'Y'); 
    END IF;
    
    
    v_sql := 'create table tm_cz.ACT_CPT_PX_2018AA_HPDS as select * from tm_cz.NCATS_VISIT_DETAILS_HPDS where 0 > 1';
    
    select count(*) into v_counts 
    from dba_tables 
    where table_name = 'ACT_CPT_PX_2018AA_HPDS' 
    and owner = 'TM_CZ';
    IF  v_counts = 0 THEN
    execute immediate v_sql;
    --TM_LOG_PKG.log_msg(p_runid, 'Create Table ACT_CPT_PX_2018AA_HPDS '||sql%rowcount, 'Y'); 
    END IF;
    
    v_sql := 'create table tm_cz.ACT_COVID_V3_HPDS as select * from tm_cz.NCATS_VISIT_DETAILS_HPDS where 0 > 1';
    select count(*) into v_counts 
    from dba_tables 
    where table_name = 'ACT_COVID_V3_HPDS' 
    and owner = 'TM_CZ';
    IF  v_counts = 0 THEN
    execute immediate v_sql;
    --TM_LOG_PKG.log_msg(p_runid, 'Create Table ACT_COVID_V3_HPDS '||sql%rowcount, 'Y'); 
    END IF;
    
    --TM_LOG_PKG.log_msg(p_runid, 'End ACT_COVID_V3_HPDS ', 'Y');     
    v_sql := '  CREATE TABLE TM_CZ.ETL_RUN_LOG '||
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
    and owner = 'TM_CZ';
    IF  v_counts = 0 THEN
    execute immediate v_sql;
    --TM_LOG_PKG.log_msg(p_runid, 'Create Table ACT_COVID_V3_HPDS '||sql%rowcount, 'Y'); 
    END IF;

    v_sql := '  CREATE SEQUENCE  TM_CZ.ETL_LOG_SEQ  MINVALUE 1 '||
    ' MAXVALUE 999999999999999999999999999 INCREMENT BY 1 START WITH 1 CACHE 20 NOCYCLE ORDER ';
    
    select count(*) into v_counts 
    from dba_objects
    where object_name = 'ETL_LOG_SEQ' 
    and object_type = 'SEQUENCE'
    and owner = 'TM_CZ';
    IF  v_counts = 0 THEN
    execute immediate v_sql;
    --TM_LOG_PKG.log_msg(p_runid, 'Create Table ACT_COVID_V3_HPDS '||sql%rowcount, 'Y'); 
    END IF;

  END;
