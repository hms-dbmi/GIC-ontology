create or replace PACKAGE TM_DATA_ACT_LOAD_PKG AS
/*
Create By      - Jaspreet Khanna 
Created        - May 2020
Prerequisites  - Standard i2b2 schema, TM_CZ user having DML permissions on i2b2 tables.
               - Procedure PRC_CRT_TABLES_ACT_HPDS_LOAD has to be run to create objects needed.
               - ACT data tables have to be loaded with the data from the DropBox script in listed tables 
               - tm_cz.NCATS_VISIT_DETAILS_HPDS,tm_cz.NCATS_DEMOGRAPHICS_HPDS,tm_cz.NCATS_LABS_HPDS,tm_cz.ACT_ICD10CM_DX_2018AA_HPDS,tm_cz.ACT_CPT_PX_2018AA_HPDS 
               - tm_cz.a_lab_cd_act_bch_map - should be populated with source system lab_cd to Loinc_cd 
               - tm_cz.a_ncats_visit_details_map - should be populated with source system visit_type cd to ACT visit_type code.
Expected Results:
               - Call to proc TM_DATA_ACT_LOAD_PKG.Run_MAP_Data_Load will populate 
               - Mapping data from source system to ACT format for various nodes in table - act_bch_ontology_map
               - Check mapping data is populated with listed data_types 
               - LABS - NCATS_LABS_HPDS 
               - ICD10 - ACT_ICD10CM_DX_2018AA_HPDS 
               - CPT - ACT_CPT_PX_2018AA_HPDS 
               - DEMOGRAPHICS - Hispanic
               - DEMOGRAPHICS - Race
               - VISIT - Length of stay
               - VISIT - Visit type 
               - If the above data is not populated, it might need code change based on how data is populated in sourcesystem.
               
               - Call to proc TM_DATA_ACT_LOAD_PKG.Run_EXTRCT_HPDS_Data will populate 
               - table tm_cz.HPDS_DATA_LATEST with HPDS extract in ACT format.  
               - GIC Version of code 
*/

FUNCTION   PARSE_NTH_VALUE (pValue varchar2, location NUMBER, delimiter VARCHAR2)
   return varchar2 ; 
   
PROCEDURE log_msg(
        p_runid IN NUMBER DEFAULT -9,
        p_msg      IN VARCHAR2,
        p_msg_type IN VARCHAR2 DEFAULT 'X');
        
PROCEDURE MAP_DATA_LOAD_NCATS_LABS_HPDS (
    p_runid        IN NUMBER )  ;   

PROCEDURE MAP_DATA_LOAD_ACT_ICD10CM_HPDS (
    p_runid        IN NUMBER )  ; 

PROCEDURE MAP_DATA_LOAD_ICD10_ICD9_HPDS (
    p_runid        IN NUMBER )  ;
    
PROCEDURE MAP_DATA_LOAD_ACT_CPT_PX_HPDS (
    p_runid        IN NUMBER )  ;    

PROCEDURE MAP_DATA_LOAD_VISIT_HPDS (
    p_runid        IN NUMBER )  ;

PROCEDURE MAP_DATA_LOAD_DEMOGRAPHCS_HPDS (
    p_runid        IN NUMBER )  ;    
    
PROCEDURE EXTRCT_HPDS_Demographics (
    p_runid        IN NUMBER ) ;

PROCEDURE EXTRCT_HPDS_Visit_data  (
    p_runid        IN NUMBER ) ;
    
PROCEDURE EXTRACT_ICD10_ICD9_DX_HPDS (
    p_runid        IN NUMBER
)   ; 
    
PROCEDURE EXTRCT_HPDS_ICD10 (
    p_runid        IN NUMBER
) ;    

PROCEDURE EXTRCT_HPDS_ICD10PCS_2018AA (
    p_runid        IN NUMBER ) ;
    
PROCEDURE EXTRCT_HPDS_CPT_PX_2018AA (
    p_runid        IN NUMBER
) ;    

PROCEDURE EXTRCT_HPDS_LAB_Results (
    p_runid        IN NUMBER) ;
--===============     
PROCEDURE  Run_EXTRCT_HPDS_Data  (
    p_runid        IN NUMBER );

PROCEDURE Run_MAP_Data_Load (p_runid  IN NUMBER ) ;  

END TM_DATA_ACT_LOAD_PKG;
/

create or replace PACKAGE BODY TM_DATA_ACT_LOAD_PKG AS

FUNCTION   PARSE_NTH_VALUE (pValue varchar2, location NUMBER, delimiter VARCHAR2)
   return varchar2
is
   v_posA number;
   v_posB number;

begin

   if location = 1 then
      v_posA := 1; -- Start at the beginning
   else
      v_posA := instr (pValue, delimiter, 1, location - 1);
      if v_posA = 0 then
         return null; --No values left.
      end if;
      v_posA := v_posA + length(delimiter);
   end if;

   v_posB := instr (pValue, delimiter, 1, location);
   if v_posB = 0 then -- Use the end of the file
      return substr (pValue, v_posA);
   end if;

   return substr (pValue, v_posA, v_posB - v_posA);

end ;

PROCEDURE log_msg(
      p_runid IN NUMBER DEFAULT -9,
      p_msg      IN VARCHAR2,
      p_msg_type IN VARCHAR2 DEFAULT 'X')
  AS
    v_logid NUMBER := 0;
    PRAGMA AUTONOMOUS_TRANSACTION;
  BEGIN
    select ETL_LOG_SEQ.nextval into v_logid from dual;
    INSERT INTO ETL_RUN_LOG VALUES
      (v_logid, p_runid, p_msg, p_msg_type, CURRENT_TIMESTAMP, DBMS_SESSION.unique_session_id
      );
    COMMIT;
  END;

PROCEDURE MAP_DATA_LOAD_NCATS_LABS_HPDS (
    p_runid        IN NUMBER )  
    AS
  BEGIN
        log_msg(p_runid, 'Start MAP_DATA_LOAD_NCATS_LABS_HPDS: '||sql%rowcount, 'Y'); 
        DELETE FROM act_bch_ontology_map
        WHERE data_type = 'NCATS_LABS_HPDS';
        
        
        INSERT INTO act_bch_ontology_map (  data_type,
            act_concept_path,
            act_name_char,
            act_concept_cd,
            bch_concept_path,
            bch_name_char,
            bch_concept_cd  )
        SELECT DISTINCT 'NCATS_LABS_HPDS' src, replace(a.hpds_path, '\Lab Test Results\', '\ACT Laboratory Tests\')||'\'  act_concept_path,
            a.c_name act_name_char,a.c_basecode act_concept_cd,
            bch.bch_concept_path,bch.bch_name_char,bch.bch_concept_cd
        FROM (  SELECT 'LOINC:'||b.loinc_lab_code bch_concept_cd, cd.concept_path bch_concept_path, cd.name_char bch_name_char
                FROM TM_CZ.A_LAB_CD_ACT_BCH_MAP b,
                     I2B2DEMODATA.concept_dimension cd
                WHERE b.bch_lab_code = cd.concept_cd
                AND b.loinc_lab_code is not null ) bch, 
                TM_CZ.NCATS_LABS_HPDS a
        WHERE bch.bch_concept_cd = a.c_basecode 
        UNION
        SELECT  DISTINCT 'NCATS_LABS_HPDS' src, replace(a.hpds_path, '\Lab Test Results\', '\ACT Laboratory Tests\')||'\'  act_concept_path,
            a.c_name act_name_char,a.c_basecode act_concept_cd,
            b.concept_path bch_concept_path,b.name_char bch_name_char,b.concept_cd bch_concept_cd
        FROM I2B2DEMODATA.concept_dimension b, 
             TM_CZ.NCATS_LABS_HPDS a
        WHERE b.name_char = a.c_name
        AND concept_path like '\i2b2\Lab View\%'; --182 Rows Inserted
        log_msg(p_runid, 'End MAP_DATA_LOAD_NCATS_LABS_HPDS: '||sql%rowcount, 'Y'); 
        COMMIT;
  END;

PROCEDURE MAP_DATA_LOAD_ACT_ICD10CM_HPDS (
    p_runid        IN NUMBER )  
    AS
  BEGIN
     log_msg(p_runid, 'Start MAP_DATA_LOAD_ACT_ICD10CM_HPDS: ', 'Y');  
        DELETE FROM act_bch_ontology_map
        WHERE data_type = 'ACT_ICD10CM_DX_2018AA_HPDS';
        log_msg(p_runid, 'Delete existing data MAP_DATA_LOAD_ACT_ICD10CM_HPDS: '||sql%rowcount, 'Y');        
        -- matched based on ICD cd
        --in addition  nodes are matched based on c_name/name_char too
        
        INSERT INTO act_bch_ontology_map (  data_type,
            bch_concept_path,
            bch_name_char,
            bch_concept_cd,
            act_concept_path,
            act_name_char,
            act_concept_cd )
            select distinct  'ACT_ICD10CM_DX_2018AA_HPDS' src ,cd.concept_path bch_concept_path,cd.name_char bch_name_char , cd.concept_cd bch_concept_cd 
            ,a.hpds_path||'\'  act_concept_path,
            a.c_name  act_name_char, a.c_basecode act_concept_cd 
            from I2B2DEMODATA.concept_dimension cd, tm_cz.ACT_ICD10CM_DX_2018AA_HPDS a
            where concept_cd like 'ICD9%'
            and concept_path like '%\Diag%'--ICD10:I25.761
            and  name_char = ltrim(replace ( c_name,parse_nth_value(c_name,1,' ') ,'')) 
            --and replace(C_BASECODE,'ICD10CM','ICD10') <> cd.concept_cd
            --and cd.concept_cd like 'ICD9%'-- 3358
            union 
            select distinct 'ACT_ICD10CM_DX_2018AA_HPDS' src ,cd.concept_path bch_concept_path,cd.name_char bch_name_char , cd.concept_cd bch_concept_cd 
            ,a.hpds_path||'\'  act_concept_path,
            a.c_name  act_name_char, a.c_basecode act_concept_cd 
            from I2B2DEMODATA.concept_dimension cd, tm_cz.ACT_ICD10CM_DX_2018AA_HPDS a
            where concept_cd like 'ICD%'
            and concept_path like '%\Diag%'
            and replace(C_BASECODE,'ICD10CM','ICD10') = cd.concept_cd ;--95130 rows inserted.
        
           
     log_msg(p_runid, 'End MAP_DATA_LOAD_ACT_ICD10CM_HPDS: Inserted Rows '||sql%rowcount, 'Y');   
      COMMIT;
  END;
 

PROCEDURE MAP_DATA_LOAD_ICD10_ICD9_HPDS (
    p_runid        IN NUMBER )  
    AS
  BEGIN
     TM_LOG_PKG.log_msg(p_runid, 'Start MAP_NCATS_ICD10_ICD9_DX_V1_HPDS: ', 'Y');  
        DELETE FROM act_bch_ontology_map
        WHERE data_type = 'NCATS_ICD10_ICD9_DX_V1_HPDS';
        TM_LOG_PKG.log_msg(p_runid, 'Delete existing data MAP_NCATS_ICD10_ICD9_DX_V1_HPDS: '||sql%rowcount, 'Y');        
        -- matched based on ICD cd
        --in addition  nodes are matched based on c_name/name_char too
        -- MAP_NCATS_ICD10_ICD9_DX_V1_HPDS
        INSERT INTO act_bch_ontology_map (  data_type,
            bch_concept_path,
            bch_name_char,
            bch_concept_cd,
            act_concept_path,
            act_name_char,
            act_concept_cd
          )
        select distinct 'NCATS_ICD10_ICD9_DX_V1_HPDS' src ,bch.orig_concept_path bch_concept_path,bch.name_char bch_name_char , bch.concept_cd bch_concept_cd ,act.hpds_path act_concept_path,
        act.c_name  act_name_char, act.c_basecode act_concept_cd 
         from 
         (  select replace(concept_path, '\'||last_node||'\','\') concept_path  ,name_char, concept_cd,orig_concept_path from
               ( SELECT
                    tm_cz.tm_data_utility_pkg.parse_nth_value(concept_path, (tm_cz.tm_data_utility_pkg.num_occurances(concept_path,'\') ),'\') last_node ,concept_path
                    ,name_char, concept_cd,orig_concept_path
                FROM
                    (
                        SELECT
                            replace(concept_path,'\i2b2\Diagnosis\10\','\') concept_path,name_char, concept_cd,concept_path orig_concept_path
                        FROM
                            i2b2demodata.concept_dimension
                        WHERE
                            concept_cd like 'ICD9:%'
                    )  )c  ) bch,
         (  select replace(c_fullname, '\'||last_node||'\','\') c_fullname  ,c_name, c_basecode, replace(hpds_path,'Diagnoses\','\ACT Diagnoses ICD10-ICD9\')  hpds_path from
               ( SELECT
                    tm_cz.tm_data_utility_pkg.parse_nth_value(c_fullname, (tm_cz.tm_data_utility_pkg.num_occurances(c_fullname,'\') ),'\') last_node ,c_fullname
                    ,c_name, c_basecode,hpds_path
                FROM
                    (
                        SELECT
                            replace(c_fullname,'\Diagnoses\','\') c_fullname,c_name, c_basecode,hpds_path
                        FROM
                            tm_cz.ncats_icd10_icd9_dx_v1_hpds
                        WHERE
                            c_basecode like 'ICD9:%'
                    )) ) act
                    where tm_cz.tm_data_utility_pkg.parse_nth_value(act.c_fullname, (tm_cz.tm_data_utility_pkg.num_occurances(act.c_fullname,'\') ),'\')   = tm_cz.tm_data_utility_pkg.parse_nth_value( bch.concept_path, (tm_cz.tm_data_utility_pkg.num_occurances(bch.concept_path,'\') ),'\')
                    and act.c_basecode = bch.concept_cd
                    and act.c_name = bch.name_char; --24264
             TM_LOG_PKG.log_msg(p_runid, 'End  ICD9 - MAP_NCATS_ICD10_ICD9_DX_V1_HPDS: Inserted Rows '||sql%rowcount, 'Y');   
        INSERT INTO act_bch_ontology_map (  data_type,
            bch_concept_path,
            bch_name_char,
            bch_concept_cd,
            act_concept_path,
            act_name_char,
            act_concept_cd
          )
        select distinct 'NCATS_ICD10_ICD9_DX_V1_HPDS' src ,cd.concept_path bch_concept_path,cd.name_char bch_name_char , cd.concept_cd bch_concept_cd ,
        replace(a.hpds_path,'Diagnoses\','\ACT Diagnoses ICD10-ICD9\') act_concept_path,
        a.c_name  act_name_char, a.c_basecode act_concept_cd 
        from i2b2demodata.concept_dimension cd, tm_cz.NCATS_ICD10_ICD9_DX_V1_hpds a
        where concept_cd like 'ICD10%'
        and concept_path like '%\Diag%'
        and C_BASECODE = cd.concept_cd ;-- 102428


     TM_LOG_PKG.log_msg(p_runid, 'End  ICD10 - MAP_NCATS_ICD10_ICD9_DX_V1_HPDS: Inserted Rows '||sql%rowcount, 'Y');   
      COMMIT;
  END;
 
  
PROCEDURE MAP_DATA_LOAD_ACT_CPT_PX_HPDS (
    p_runid        IN NUMBER )  
    AS
  BEGIN
     log_msg(p_runid, 'Start MAP_DATA_LOAD_ACT_CPT_PX_HPDS: ', 'Y');  
        DELETE FROM act_bch_ontology_map
        WHERE data_type = 'ACT_CPT_PX_2018AA_HPDS';
        log_msg(p_runid, 'Delete existing data MAP_DATA_LOAD_ACT_CPT_PX_HPDS: '||sql%rowcount, 'Y');   
        
        --AND matched based on CPT cd
        --IN ADDITION  nodes are matched based on c_name/name_char too
        INSERT INTO act_bch_ontology_map (  data_type,
                bch_concept_path,
                bch_name_char,
                bch_concept_cd,
                act_concept_path,
                act_name_char,
                act_concept_cd )
                select 'ACT_CPT_PX_2018AA_HPDS' src, b.concept_path bch_concept_path,b.name_char bch_name_char,b.concept_cd bch_concept_cd,
                a.hpds_path||'\' act_concept_path,a.c_name act_name_char,a.c_basecode act_concept_cd
                from
                ( select *
                from I2B2DEMODATA.concept_dimension
                WHERE concept_path like '%\Procedures\%'
                and  parse_nth_value(concept_cd,1,':')  in ('CPT4' ) ) b, tm_cz.ACT_CPT_PX_2018AA_HPDS a
                where b.concept_cd = a.c_basecode--7599/8725 in cd
                union
                select 'ACT_CPT_PX_2018AA_HPDS' src, b.concept_path bch_concept_path,b.name_char bch_name_char,b.concept_cd bch_concept_cd,
                a.hpds_path||'\' act_concept_path,a.c_name act_name_char,a.c_basecode act_concept_cd
                from
                (select *
                from I2B2DEMODATA.concept_dimension
                WHERE concept_path like '%\Procedures\%'
                and  parse_nth_value(concept_cd,1,':')  in ('CPT4' ) ) b, tm_cz.ACT_CPT_PX_2018AA_HPDS a
                where b.name_char = a.c_name--2586/8725 in cd
                and b.concept_cd <> a.c_basecode ;--7,824 rows inserted.

     log_msg(p_runid, 'End MAP_DATA_LOAD_ACT_CPT_PX_HPDS: Inserted Rows '||sql%rowcount, 'Y');        
     COMMIT;
  END;

PROCEDURE MAP_DATA_LOAD_VISIT_HPDS (
    p_runid        IN NUMBER )  
    AS
  BEGIN
     log_msg(p_runid, 'Start MAP_DATA_LOAD_VISIT_HPDS: ', 'Y');  
        DELETE FROM act_bch_ontology_map
        WHERE data_type in ( 'Visit type','Length of stay');
        log_msg(p_runid, 'Delete existing data MAP_DATA_LOAD_VISIT_HPDS: '||sql%rowcount, 'Y');  
        
        --Loads mapping for visit type and length of stay   
        --tm_cz.a_ncats_visit_details_map has source system visit type (inout_cd visit_dimension ) 
        --mapped to act visit_type code. 
            INSERT INTO act_bch_ontology_map (
                bch_concept_path,
                bch_name_char,
                bch_concept_cd,
                act_concept_path,
                act_name_char,
                act_concept_cd,
                data_type)
            SELECT
                null bch_concept_path,
                m.bch_visit_type bch_name_char,
                null bch_concept_cd,
                '\ACT Visit Details\Visit type\' act_concept_path,
                 m.act_visit_type act_name_char,
                a.c_basecode,
                'Visit type'   --'visit_details_map'
            from tm_cz.a_ncats_visit_details_map m,  tm_cz.NCATS_VISIT_DETAILS_HPDS a
            where c_fullname like '\ACT\Visit Details\Visit type\%'
            and a.c_name = m.act_visit_type; --11 rows inserted.
        log_msg(p_runid, 'Inserted Visit type  data MAP_DATA_LOAD_VISIT_HPDS: '||sql%rowcount, 'Y'); 
            --Populating data for '\ACT Visit Details\Length of stay
            
            Insert into TM_CZ.ACT_BCH_ONTOLOGY_MAP (ACT_CONCEPT_PATH,ACT_NAME_CHAR,ACT_CONCEPT_CD,BCH_CONCEPT_PATH,BCH_NAME_CHAR,BCH_CONCEPT_CD,DATA_TYPE) values ('\ACT Visit Details\Length of stay\','> 10 days',null,null,'> 10 days',null,'Length of stay');
            Insert into TM_CZ.ACT_BCH_ONTOLOGY_MAP (ACT_CONCEPT_PATH,ACT_NAME_CHAR,ACT_CONCEPT_CD,BCH_CONCEPT_PATH,BCH_NAME_CHAR,BCH_CONCEPT_CD,DATA_TYPE) values ('\ACT Visit Details\Length of stay\','9','9',null,'9',null,'Length of stay');
            Insert into TM_CZ.ACT_BCH_ONTOLOGY_MAP (ACT_CONCEPT_PATH,ACT_NAME_CHAR,ACT_CONCEPT_CD,BCH_CONCEPT_PATH,BCH_NAME_CHAR,BCH_CONCEPT_CD,DATA_TYPE) values ('\ACT Visit Details\Length of stay\','8','8',null,'8',null,'Length of stay');
            Insert into TM_CZ.ACT_BCH_ONTOLOGY_MAP (ACT_CONCEPT_PATH,ACT_NAME_CHAR,ACT_CONCEPT_CD,BCH_CONCEPT_PATH,BCH_NAME_CHAR,BCH_CONCEPT_CD,DATA_TYPE) values ('\ACT Visit Details\Length of stay\','7','7',null,'7',null,'Length of stay');
            Insert into TM_CZ.ACT_BCH_ONTOLOGY_MAP (ACT_CONCEPT_PATH,ACT_NAME_CHAR,ACT_CONCEPT_CD,BCH_CONCEPT_PATH,BCH_NAME_CHAR,BCH_CONCEPT_CD,DATA_TYPE) values ('\ACT Visit Details\Length of stay\','6','6',null,'6',null,'Length of stay');
            Insert into TM_CZ.ACT_BCH_ONTOLOGY_MAP (ACT_CONCEPT_PATH,ACT_NAME_CHAR,ACT_CONCEPT_CD,BCH_CONCEPT_PATH,BCH_NAME_CHAR,BCH_CONCEPT_CD,DATA_TYPE) values ('\ACT Visit Details\Length of stay\','5','5',null,'5',null,'Length of stay');
            Insert into TM_CZ.ACT_BCH_ONTOLOGY_MAP (ACT_CONCEPT_PATH,ACT_NAME_CHAR,ACT_CONCEPT_CD,BCH_CONCEPT_PATH,BCH_NAME_CHAR,BCH_CONCEPT_CD,DATA_TYPE) values ('\ACT Visit Details\Length of stay\','4','4',null,'4',null,'Length of stay');
            Insert into TM_CZ.ACT_BCH_ONTOLOGY_MAP (ACT_CONCEPT_PATH,ACT_NAME_CHAR,ACT_CONCEPT_CD,BCH_CONCEPT_PATH,BCH_NAME_CHAR,BCH_CONCEPT_CD,DATA_TYPE) values ('\ACT Visit Details\Length of stay\','3','3',null,'3',null,'Length of stay');
            Insert into TM_CZ.ACT_BCH_ONTOLOGY_MAP (ACT_CONCEPT_PATH,ACT_NAME_CHAR,ACT_CONCEPT_CD,BCH_CONCEPT_PATH,BCH_NAME_CHAR,BCH_CONCEPT_CD,DATA_TYPE) values ('\ACT Visit Details\Length of stay\','2','2',null,'2',null,'Length of stay');
            Insert into TM_CZ.ACT_BCH_ONTOLOGY_MAP (ACT_CONCEPT_PATH,ACT_NAME_CHAR,ACT_CONCEPT_CD,BCH_CONCEPT_PATH,BCH_NAME_CHAR,BCH_CONCEPT_CD,DATA_TYPE) values ('\ACT Visit Details\Length of stay\','10','10',null,'10',null,'Length of stay');
            Insert into TM_CZ.ACT_BCH_ONTOLOGY_MAP (ACT_CONCEPT_PATH,ACT_NAME_CHAR,ACT_CONCEPT_CD,BCH_CONCEPT_PATH,BCH_NAME_CHAR,BCH_CONCEPT_CD,DATA_TYPE) values ('\ACT Visit Details\Length of stay\','1','1',null,'1',null,'Length of stay');
             --11 rows inserted.
            log_msg(p_runid, 'Inserted Length of stay  data MAP_DATA_LOAD_VISIT_HPDS: 11', 'Y'); 
     log_msg(p_runid, 'End MAP_DATA_LOAD_VISIT_HPDS: ', 'Y');        
     COMMIT;
  END;
--
PROCEDURE MAP_DATA_LOAD_DEMOGRAPHCS_HPDS (
    p_runid        IN NUMBER )  
    AS
  BEGIN
     log_msg(p_runid, 'Start MAP_DATA_LOAD_DEMOGRAPHCS_HPDS: ', 'Y');  
        DELETE FROM act_bch_ontology_map
        WHERE data_type in ( 'Hispanic','Race' );
        log_msg(p_runid, 'Delete existing data MAP_DATA_LOAD_DEMOGRAPHCS_HPDS: '||sql%rowcount, 'Y'); 
        --Loads mapping for Hispanic and Race flag from Observation_Fact table.
        --
        
        INSERT INTO act_bch_ontology_map (
            bch_concept_path,
            bch_name_char,
            bch_concept_cd,
            act_concept_path,
            act_name_char,
            act_concept_cd,
            data_type)
        SELECT  bch_concept_path,
            bch_name_char,
            bch_concept_cd,
            act_concept_path,
            act_name_char,
            act_concept_cd,
            'Hispanic' data_type 
        FROM 
           (SELECT
                concept_path bch_concept_path,
                concept_cd bch_concept_cd,
                name_char bch_name_char,
                '\ACT Demographics\Hispanic\' act_concept_path,
                'DEM|HISP:N' act_concept_cd,
                'No Information' act_name_char
            FROM I2B2DEMODATA.concept_dimension cd
            WHERE concept_cd = 'DEM|ETHNICITY:0'
            AND name_char = 'NOT DEFINED IN SOURCE'
        
           UNION ALL
           SELECT
                concept_path bch_concept_path,
                concept_cd bch_concept_cd,
                name_char bch_name_char,
                '\ACT Demographics\Hispanic\' act_concept_path,
                'DEM|HISP:N' act_concept_cd,
                'No' act_name_char
            FROM I2B2DEMODATA.concept_dimension cd
            WHERE concept_cd like 'DEM|ETHNICITY:%' 
            AND name_char NOT IN 
                    ('Latin American',
                    'Hispanic or Latino',
                    'Mexican',
                    'Central American',
                    'Costa Rican',
                    'Salvadoran',
                    'Central American Indian',
                    'Dominican (Republic)',
                    'Guatamalan',
                    'Mexican American',
                    'Mexicano',
                    'Argentinean',
                    'Colombian',
                    'Brazilian',
                    'Venezuelan',
                    'Cuban',
                    'South American',
                    'Paraguayan',
                    'Peruvian',
                    'Honduran',
                    'Chilean',
                    'Haitian',
                    'Puerto Rican',
                    'Caribbean Islander',
                    'NOT DEFINED IN SOURCE'
                    ) 
            UNION ALL
            SELECT
                concept_path bch_concept_path,
                concept_cd bch_concept_cd,
                name_char bch_name_char,
                '\ACT Demographics\Hispanic\' act_concept_path,
                'DEM|HISP:Y' act_concept_cd,
                'Yes' act_name_char
            FROM  I2B2DEMODATA.concept_dimension cd
            WHERE concept_cd like 'DEM|ETHNICITY:%' 
            AND name_char in 
                    ('Latin American',
                    'Hispanic or Latino',
                    'Mexican',
                    'Central American',
                    'Costa Rican',
                    'Salvadoran',
                    'Central American Indian',
                    'Dominican (Republic)',
                    'Guatamalan',
                    'Mexican American',
                    'Mexicano',
                    'Argentinean',
                    'Colombian',
                    'Brazilian',
                    'Venezuelan',
                    'Cuban',
                    'South American',
                    'Paraguayan',
                    'Peruvian',
                    'Honduran',
                    'Chilean',
                    'Haitian',
                    'Puerto Rican',
                    'Caribbean Islander')    );--170
            log_msg(p_runid, 'Inserted Hispanic rows MAP_DATA_LOAD_DEMOGRAPHCS_HPDS: '||sql%rowcount, 'Y');      
            INSERT INTO act_bch_ontology_map (
                bch_concept_path,
                bch_name_char,
                bch_concept_cd,
                act_concept_path,
                act_name_char,
                act_concept_cd,
                data_type)
            select   distinct r.concept_path  bch_concept_path,
                r.name_char bch_name_char,
                r.concept_cd bch_concept_cd,
                '\ACT Demographics\Race\' act_concept_path,
                nvl(a.c_name , 'No Information') act_name_char,
                nvl(a.c_basecode,'DEM|RACE:NI') act_concept_cd,
                'Race' data_type from
             ( select  * from tm_cz.NCATS_DEMOGRAPHICS_HPDS  where c_fullname LIKE '\ACT\Demographics\Race%' ) a,
             ( select * from I2B2DEMODATA.concept_dimension cd
                            WHERE   cd.concept_cd LIKE 'DEM|RACE:%' ) r
                             where r.name_char = a.c_name (+); --12 rows inserted.
             log_msg(p_runid, 'Inserted Race rows MAP_DATA_LOAD_DEMOGRAPHCS_HPDS: '||sql%rowcount, 'Y');           

     log_msg(p_runid, 'End MAP_DATA_LOAD_DEMOGRAPHCS_HPDS: ', 'Y');        
     COMMIT;
  END;
  

 PROCEDURE EXTRCT_HPDS_Demographics (
    p_runid        IN NUMBER
) AS
    v_count        NUMBER;
    v_step         VARCHAR2(400);
    v_code         NUMBER;
    v_sqlerrm      VARCHAR2(400);
BEGIN

    log_msg(p_runid,'EXTRCT_HPDS_Demographics Start  ','X'); 
        
        log_msg(p_runid,'EXTRCT_HPDS_Demographics Age Start  ','X'); 
        
            insert into  TM_CZ.HPDS_DATA_LATEST( PATIENT_NUM ,CONCEPT_PATH , NVAL_NUM , TVAL_CHAR ,START_DATE )
            SELECT patient_num, '\ACT Demographics\Years\Age\' concept_path ,trunc((sysdate - (cast(birth_date as date )) )/365)  years ,'E',trunc(sysdate)
            from I2B2DEMODATA.patient_dimension
            where  trunc((sysdate - (cast(birth_date as date )) )/365) >= 0;

        log_msg(p_runid,'EXTRCT_HPDS_Demographics Age End  '||sql%rowcount,'X');                   

        
        log_msg(p_runid,'EXTRCT_HPDS_Demographics Gender Start ','X'); 

            insert into  TM_CZ.HPDS_DATA_LATEST( PATIENT_NUM ,CONCEPT_PATH , NVAL_NUM , TVAL_CHAR ,START_DATE )
            select patient_num ,'\ACT Demographics\Sex\',null,decode(sex_cd,'Unknown','No Information',sex_cd) ,trunc(sysdate)
            from I2B2DEMODATA.patient_dimension ;

        log_msg(p_runid,'EXTRCT_HPDS_Demographics Gender End  '||sql%rowcount,'X');                   

        log_msg(p_runid,'EXTRCT_HPDS_Demographics HipanicFlag Start  ','X'); 

            INSERT INTO  TM_CZ.HPDS_DATA_LATEST( PATIENT_NUM ,CONCEPT_PATH , NVAL_NUM , TVAL_CHAR ,START_DATE )
            SELECT  DISTINCT patient_num,m.act_concept_path ,null,m.act_name_char, trunc(sysdate)
            FROM  I2B2DEMODATA.observation_fact fact1 , act_bch_ontology_map m
            WHERE  fact1.concept_cd = m.bch_concept_cd
            AND  m.data_type = 'Hispanic';

            
        log_msg(p_runid,'EXTRCT_HPDS_Demographics HipanicFlag End  '||sql%rowcount,'X');                   

        log_msg(p_runid,'EXTRCT_HPDS_Demographics Race Start  ','X'); 
        
                INSERT INTO  TM_CZ.HPDS_DATA_LATEST( PATIENT_NUM ,CONCEPT_PATH , NVAL_NUM , TVAL_CHAR ,START_DATE )
                SELECT distinct patient_num,act_concept_path,null,act_name_char,trunc(sysdate)
                FROM I2B2DEMODATA.observation_fact  fact1, act_bch_ontology_map m
                WHERE   fact1.concept_cd = m.bch_concept_cd
                AND m.DATA_TYPE = 'Race' ;

                    
        log_msg(p_runid,'EXTRCT_HPDS_Demographics Race End  '||sql%rowcount,'X'); 
             
        log_msg(p_runid,'EXTRCT_HPDS_Demographics Vital Status Start  ','X');
             insert into  TM_CZ.HPDS_DATA_LATEST ( PATIENT_NUM ,CONCEPT_PATH , NVAL_NUM , TVAL_CHAR ,START_DATE )
             select patient_num,'\ACT Demographics\Vital Status\',null,'Known Deceased' ,death_date
             from I2B2DEMODATA.patient_dimension 
             where death_date is not null;
                
        log_msg(p_runid,'EXTRCT_HPDS_Demographics Vital Status End  '||sql%rowcount,'X');    
    log_msg(p_runid,'EXTRCT_HPDS_Demographics End  ','X'); 
    commit;

END;


----Visit Details
PROCEDURE EXTRCT_HPDS_Visit_data  (
    p_runid        IN NUMBER
) AS
    v_count        NUMBER;
    v_step         VARCHAR2(400);
    v_code         NUMBER;
    v_sqlerrm      VARCHAR2(400);
    v_sql          VARCHAR2(4000);
    /* Pre requesite table tm_cz.a_ncats_visit_details_map  should be populated with mapping data   */
BEGIN

        log_msg(p_runid,'EXTRCT_HPDS_Visit_data Start  ','X'); 
        v_sql := 'TRUNCATE TABLE tm_cz.visit_fact_details ';

        log_msg(p_runid,'Load tm_cz.visit_fact_details Start  ','X'); 
        execute immediate v_sql;

        log_msg(p_runid,'Refresh data tm_cz.visit_fact_details Start ','X'); 
            v_sql := 'INSERT INTO tm_cz.visit_fact_details ( patient_num,inout_cd,length_of_stay,age_at_visit_yrs,start_date) '||
            'SELECT patient_num, inout_cd, length_of_stay, trunc( (start_date - birth_date) / 365) age_at_visit_yrs, start_date '||
            'FROM ( SELECT DISTINCT '||
                       ' vd.patient_num, '||
                       ' inout_cd, '||
                       ' length_of_stay, '||
                       ' CAST(start_date AS DATE) start_date,'||
                       ' CAST(birth_date AS DATE) birth_date '||
                     ' FROM ('||
                           ' SELECT DISTINCT '||
                              '  patient_num, '||
                              '  inout_cd, '||
                              '  length_of_stay, '||
                              '  to_timestamp(start_date,''DD-MON-RR HH.MI.SSXFF AM'') start_date '||
                            ' FROM I2B2DEMODATA.visit_dimension '||
                       ' ) vd, I2B2DEMODATA.patient_dimension pd '||
                   ' WHERE  vd.patient_num = pd.patient_num '||
              '  ) WHERE trunc( (start_date - birth_date) / 365) >= 0 ';
               execute immediate v_sql;
              dbms_output.put_line(v_sql);
        log_msg(p_runid,'Refresh data tm_cz.visit_fact_details End '||SQL%ROWCOUNT,'X'); 

        log_msg(p_runid,'EXTRCT_HPDS_Visit_data Age Start  ','X'); 
        
            insert into TM_CZ.HPDS_DATA_LATEST ( patient_num,concept_path,nval_num,tval_char,start_date  )
            select  distinct patient_num,'\ACT Visit Details\Years\Age\' concept_path,age_at_visit_yrs,'E',start_date
            from tm_cz.VISIT_FACT_DETAILS ;
        log_msg(p_runid,'EXTRCT_HPDS_Visit_data Age End  '||SQL%ROWCOUNT,'X'); 

        log_msg(p_runid,'EXTRCT_HPDS_Visit_data Visit type Start  ','X'); 

            insert into TM_CZ.HPDS_DATA_LATEST ( patient_num,concept_path,tval_char,start_date  )                    
            SELECT  distinct v.patient_num, m.act_concept_path, m.act_name_char,start_date
            FROM tm_cz.VISIT_FACT_DETAILS V, act_bch_ontology_map m
            where m.data_type =   'Visit type' -- 'visit_details_map'
            and  v.inout_cd = M.BCH_name_char;
   
       log_msg(p_runid,'EXTRCT_HPDS_Visit_data Visit type End  '||SQL%ROWCOUNT,'X');    
       log_msg(p_runid,'EXTRCT_HPDS_Visit_data Length of stay Start  ','X'); 


        insert into TM_CZ.HPDS_DATA_LATEST ( patient_num,concept_path,tval_char ,start_date )
                SELECT DISTINCT
                    b.patient_num,
                    a.act_concept_path,
                    a.act_name_char ,
                    b.start_date
                FROM
                    (
                        SELECT
                            length_of_stay,
                            patient_num,
                            start_date
                        FROM
                            tm_cz.VISIT_FACT_DETAILS
                        WHERE length_of_stay <= 10
                        AND   length_of_stay > 0
                            
                    ) b,
                    (
                        SELECT
                            *
                        FROM TM_CZ.ACT_BCH_ONTOLOGY_MAP
                        WHERE data_type =  'Length of stay'
                    ) a
                where a.bch_name_char = to_char(b.length_of_stay)
                union all
                SELECT DISTINCT
                    b.patient_num,
                    a.act_concept_path,
                    a.act_name_char ,
                    start_date
                FROM
                    (
                        SELECT
                            length_of_stay,
                            patient_num,
                            start_date
                        FROM
                            tm_cz.VISIT_FACT_DETAILS
                        WHERE
                            length_of_stay > 10
                    ) b,
                    (
                        SELECT  *
                        FROM TM_CZ.ACT_BCH_ONTOLOGY_MAP
                        WHERE data_type =  'Length of stay'
                        AND  act_name_char = '> 10 days'
                    ) a ;
   
      log_msg(p_runid,'EXTRCT_HPDS_Visit_data Length of stay Start  '||SQL%ROWCOUNT,'X'); 
      log_msg(p_runid,'EXTRCT_HPDS_Visit_data End  ','X'); 
      commit;
END;

---ICD10-9
PROCEDURE EXTRACT_ICD10_ICD9_DX_HPDS (
    p_runid        IN NUMBER
) AS

BEGIN
    tm_log_pkg.log_msg(p_runid,'EXTRACT_ICD10_ICD9_DX_HPDS Start  ','X'); 

            INSERT into tm_cz.HPDS_DATA_LATEST( PATIENT_NUM,CONCEPT_PATH,NVAL_NUM,TVAL_CHAR,start_date)      
            SELECT distinct patient_num,act_concept_path ,null,act_name_char,  cast (start_date as date)   
            FROM I2B2DEMODATA.observation_fact   fact1, act_bch_ontology_map m
            WHERE fact1.concept_cd = m.bch_concept_cd 
            AND data_type =  'NCATS_ICD10_ICD9_DX_V1_HPDS' ;
    tm_log_pkg.log_msg(p_runid,'EXTRACT_ICD10_ICD9_DX_HPDS End  '||sql%rowcount,'X'); 
    commit;
end;

---ICD10

PROCEDURE EXTRCT_HPDS_ICD10 (
    p_runid        IN NUMBER
) AS

BEGIN
    log_msg(p_runid,'EXTRCT_HPDS_ICD10 Start  ','X'); 

            INSERT into tm_cz.HPDS_DATA_LATEST( PATIENT_NUM,CONCEPT_PATH,NVAL_NUM,TVAL_CHAR,start_date)      
            SELECT distinct patient_num,act_concept_path ,null,act_name_char,  cast (start_date as date)   
            FROM I2B2DEMODATA.observation_fact   fact1, act_bch_ontology_map m
            WHERE fact1.concept_cd = m.bch_concept_cd 
            AND data_type =  'ACT_ICD10CM_DX_2018AA_HPDS';
    log_msg(p_runid,'EXTRCT_HPDS_ICD10 End  '||sql%rowcount,'X'); 
    commit;
end;

---ICD10PCS
PROCEDURE EXTRCT_HPDS_ICD10PCS_2018AA (
    p_runid        IN NUMBER
) AS

Begin

  log_msg(p_runid,'EXTRCT_HPDS_ICD10PCS_2018AA Start  ','X'); 

        INSERT into tm_cz.HPDS_DATA_LATEST( PATIENT_NUM,CONCEPT_PATH,NVAL_NUM,TVAL_CHAR,start_date)      
        SELECT distinct patient_num,act_concept_path ,null,act_name_char,  cast( start_date as date) start_date
        FROM I2B2DEMODATA.observation_fact   fact1, act_bch_ontology_map m
        WHERE fact1.concept_cd = m.bch_concept_cd  
        AND data_type =   'ACT_ICD10CM_DX_2018AA_HPDS';
        
  log_msg(p_runid,'EXTRCT_HPDS_ICD10PCS_2018AA End  '||sql%rowcount,'X'); 
  commit;
end;
--
PROCEDURE EXTRCT_HPDS_CPT_PX_2018AA (
    p_runid        IN NUMBER
) AS

Begin

  log_msg(p_runid,'EXTRCT_HPDS_CPT_PX_2018AA Start  ','X'); 

        INSERT into tm_cz.HPDS_DATA_LATEST( PATIENT_NUM,CONCEPT_PATH,NVAL_NUM,TVAL_CHAR,start_date)      
        SELECT distinct patient_num,act_concept_path ,null,act_name_char,  cast( start_date as date) start_date
        FROM I2B2DEMODATA.observation_fact   fact1, act_bch_ontology_map m
        WHERE fact1.concept_cd = m.bch_concept_cd  
        AND data_type =   'ACT_CPT_PX_2018AA_HPDS';
        
  log_msg(p_runid,'EXTRCT_HPDS_CPT_PX_2018AA End  '||sql%rowcount,'X'); 
  commit;
end;

PROCEDURE EXTRCT_HPDS_LAB_Results (
    p_runid        IN NUMBER
) AS

 begin

  log_msg(p_runid,'EXTRCT_HPDS_LAB_Results Start  ','X'); 
       insert into tm_cz.HPDS_DATA_LATEST ( PATIENT_NUM,CONCEPT_PATH,NVAL_NUM,TVAL_CHAR,start_date)
       SELECT DISTINCT fact1.patient_num,  act_concept_path, nval_num,'E',cast( start_date as date) start_date
        FROM
            (   SELECT patient_num, concept_cd,nval_num,start_date
                FROM I2B2DEMODATA.observation_fact
                WHERE concept_cd LIKE 'LAB:%'
                AND tval_char NOT IN (
                        '\\',
                        '|-------',
                        '--',
                        '.',
                        '-',
                        '#',
                        '*',
                        '+',
                        '+++',
                        '++',
                        '++++'  ) ) fact1,
            tm_cz.act_bch_ontology_map m
        WHERE fact1.concept_cd = m.bch_concept_cd            
        --AND fact1.patient_num = pd.Patient_Num 
        AND data_type =  'NCATS_LABS_HPDS'  ;
        
        
  log_msg(p_runid,'EXTRCT_HPDS_LAB_Results Start  '||sql%rowcount,'X'); 
  commit;
 end;

PROCEDURE  Run_EXTRCT_HPDS_Data  (
    p_runid        IN NUMBER ) AS
    v_sql          VARCHAR2(4000) ;
BEGIN
     log_msg(p_runid,'Run_EXTRCT_HPDS_Data Start  ','X'); 
     v_sql := 'Create table tm_cz.HPDS_DATA_LATEST_'||to_char(sysdate,'MMDD') ||' AS select * from tm_cz.HPDS_DATA_LATEST ';
     execute immediate v_sql;
     dbms_output.put_line(v_sql);
     v_sql := 'Truncate table tm_cz.HPDS_DATA_LATEST ';
     
     execute immediate v_sql;
     
     dbms_output.put_line(v_sql);
    
     EXTRCT_HPDS_Demographics ( p_runid  ) ;
    
     EXTRCT_HPDS_Visit_data  ( p_runid  ) ;
    
     EXTRACT_ICD10_ICD9_DX_HPDS ( p_runid )   ; 
         
     EXTRCT_HPDS_ICD10 ( p_runid  ) ;
    
     EXTRCT_HPDS_CPT_PX_2018AA ( p_runid   ) ;
    
     EXTRCT_HPDS_LAB_Results ( p_runid ) ;
     log_msg(p_runid,'Run_EXTRCT_HPDS_Data End  ','X'); 
 
END;
    
PROCEDURE Run_MAP_Data_Load (p_runid  IN NUMBER ) AS

BEGIN
log_msg(p_runid,'Start Run_MAP_Data_Load   ','X');   
         execute immediate 'Truncate table tm_cz.act_bch_ontology_map '; 
         MAP_DATA_LOAD_NCATS_LABS_HPDS ( p_runid   ); 
          
         MAP_DATA_LOAD_ACT_ICD10CM_HPDS ( p_runid );
         
         MAP_DATA_LOAD_ICD10_ICD9_HPDS( p_runid );
        
         MAP_DATA_LOAD_ACT_CPT_PX_HPDS ( p_runid ) ;
        
         MAP_DATA_LOAD_VISIT_HPDS ( p_runid);
        
         MAP_DATA_LOAD_DEMOGRAPHCS_HPDS ( p_runid ) ;
log_msg(p_runid,'End Run_MAP_Data_Load   ','X');   
END;

END TM_DATA_ACT_LOAD_PKG;
/






