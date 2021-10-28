--------------------------------------------------------
--  DDL for Package TM_DATA_ACT_LOAD_PKG
--
--------------------------------------------------------

  CREATE OR REPLACE  PACKAGE TM_DATA_ACT_LOAD_PKG AS
/*
Create By      - Jaspreet Khanna 
Created        - May 2020
Modified       - Sep 2021 
Prerequisites  - Standard i2b2 schema.
               - Procedure PRC_CRT_TABLES_ACT_HPDS_LOAD has to be run to create objects needed.
               - ACT ontology data tables have to be loaded with the data from the Git in listed tables .
               - NCATS_LABS_HPDS,ACT_ICD10CM_DX_2018AA_HPDS,ACT_CPT_PX_2018AA_HPDS,NCATS_VISIT_DETAILS_HPDS,NCATS_DEMOGRAPHICS_HPDS,ACT_COVID_HPDS,ACT_MED_ALPHA_HPDS,GIC_BIOSAMPLES_HPDS
               - a_lab_cd_act_bch_map - should be populated with source system lab_cd to Loinc_cd 
               - a_ncats_visit_details_map - should be populated with source system visit_type cd to ACT visit_type code.
               - a_med_cd_act_bch_map  - should be populated with source system medication_cd to Rxnorm code. 
Expected Results:
               - Call to proc Run_MAP_Data_Load will populate 
               - Mapping data from source system to ACT format for various nodes in table - act_bch_ontology_map
               - Check mapping data is populated with listed data_types 
               - LABS - NCATS_LABS_HPDS 
               - ICD10 - ACT_ICD10CM_DX_2018AA_HPDS 
               - CPT - ACT_CPT_PX_2018AA_HPDS 
               - DEMOGRAPHICS - Hispanic
               - DEMOGRAPHICS - Race
               - DEMOGRAPHICS - Demographic Age
               - VISIT - Length of stay
               - VISIT - Visit type 
               --VISIT - Visit Age
               - ACT_COVID_HPDS  -- ACT_COVID_DERIVED
               - ACT_COVID_HPDS  -- ACT_COVID_DERIVED_LAB
               - MED_ALPHA_HPDS
               - If the above data is not populated, it might need code change based on how data is populated in sourcesystem.
               - Call to proc Run_EXTRCT_HPDS_Data will populate 
               - table HPDS_DATA_LATEST with HPDS extract in ACT format. 
               - Modified COVID node to load medication data + removal of schema prefix restructure of code.
*/

FUNCTION   NUM_OCCURANCES (
  input_str nvarchar2,
  search_str nvarchar2
) return number ;


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

PROCEDURE MAP_DATA_LOAD_ACT_CPT_PX_HPDS (
    p_runid        IN NUMBER )  ;    

PROCEDURE MAP_DATA_LOAD_VISIT_HPDS (
    p_runid        IN NUMBER )  ;

PROCEDURE MAP_DATA_LOAD_DEMOGRAPHCS_HPDS (
    p_runid        IN NUMBER )  ;  

PROCEDURE MAP_DATA_LOAD_COVID_HPDS (
    p_runid        IN NUMBER )  ;    

PROCEDURE MAP_DATA_LOAD_MED_ALPHA_HPDS (
    p_runid        IN NUMBER )  ;  
PROCEDURE MAP_BLOOD_GIC_BIOSAMPLES_HPDS (
    p_runid        IN NUMBER )  ;
    
 PROCEDURE MAP_CSF_GIC_BIOSAMPLES_HPDS (
    p_runid        IN NUMBER )  ;
    
 PROCEDURE MAP_GNOME_GIC_BIOSAMPLES_HPDS (
    p_runid        IN NUMBER )  ;
    
  PROCEDURE MAP_PLASMA_GIC_BIOSAMPLES_HPDS (
    p_runid        IN NUMBER )  ;
    
 PROCEDURE MAP_TISSUE_GIC_BIOSAMPLES_HPDS (
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

PROCEDURE EXTRCT_HPDS_CPT_PX_2018AA (
    p_runid        IN NUMBER
) ;    

PROCEDURE EXTRCT_HPDS_LAB_Results (
    p_runid        IN NUMBER) ;

PROCEDURE  EXTRACT_COVID_DATA_HPDS ( 
    p_runid   IN NUMBER) ;

PROCEDURE  EXTRCT_HPDS_MED_ALPHA     (
    p_runid        IN NUMBER );    

PROCEDURE  Run_EXTRCT_HPDS_Data  (
    p_runid        IN NUMBER );

PROCEDURE Run_MAP_Data_Load (p_runid  IN NUMBER ) ;  

PROCEDURE           EXTRCT_HPDS_CSF ( p_runid                IN NUMBER) ;
PROCEDURE           EXTRCT_HPDS_EXOMES_IDS (  p_runid        IN NUMBER );
PROCEDURE           EXTRCT_HPDS_HUMANTISSUE ( p_runid        IN NUMBER);
PROCEDURE           EXTRCT_HPDS_NUCLEICACID ( p_runid        IN NUMBER );
PROCEDURE           EXTRCT_HPDS_PLASMA ( p_runid             IN NUMBER );
PROCEDURE           EXTRCT_HPDS_WHOLE_BLOOD ( p_runid        IN NUMBER ) ;

END TM_DATA_ACT_LOAD_PKG;

/

--------------------------------------------------------
--  DDL for Package Body TM_DATA_ACT_LOAD_PKG
--------------------------------------------------------

  CREATE OR REPLACE  PACKAGE BODY TM_DATA_ACT_LOAD_PKG AS

FUNCTION   NUM_OCCURANCES (
  input_str nvarchar2,
  search_str nvarchar2
) return number
as
  num number;
begin
  num := 0;
  while instr(input_str, search_str, 1, num + 1) > 0 loop
    num := num + 1;
  end loop;
  return num;
end;

FUNCTION   PARSE_NTH_VALUE (pValue varchar2, location NUMBER, delimiter VARCHAR2)
   return varchar2
is
   v_posA number;
   v_posB number;

begin
--TM_DATA_ACT_LOAD_PKG Body

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
        SELECT DISTINCT 'NCATS_LABS_HPDS' src, a.hpds_path  act_concept_path, a.c_name act_name_char,a.c_basecode act_concept_cd,
            null ,null,bch.bch_lab_code
        FROM  A_LAB_CD_ACT_BCH_MAP bch ,
                NCATS_LABS_HPDS a
        WHERE 'LOINC:'||bch.loinc_lab_code = a.c_basecode 
        UNION
        SELECT DISTINCT 'NCATS_LABS_HPDS' src, a.hpds_path  act_concept_path, a.c_name act_name_char,a.c_basecode act_concept_cd,
            null ,null,b.concept_cd
        FROM concept_dimension b, 
             NCATS_LABS_HPDS a
        WHERE b.name_char = a.c_name
        AND concept_cd like 'LAB%'  ; 


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

        INSERT INTO act_bch_ontology_map (  data_type,
            bch_concept_path,
            bch_name_char,
            bch_concept_cd,
            act_concept_path,
            act_name_char,
            act_concept_cd )
        SELECT DISTINCT
            'ACT_ICD10CM_DX_2018AA_HPDS' src,
            cd.concept_path bch_concept_path,
            cd.name_char bch_name_char,
            cd.concept_cd bch_concept_cd,
            a.hpds_path  act_concept_path,
            a.c_name act_name_char,
            a.c_basecode act_concept_cd
                    from concept_dimension cd, ACT_ICD10CM_DX_2018AA_HPDS a
                    where replace(C_BASECODE,'ICD10CM','ICD10') = cd.concept_cd ;
        
             log_msg(p_runid, 'End MAP_DATA_LOAD_ACT_ICD10CM_HPDS: Inserted Rows '||sql%rowcount, 'Y');   
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

        INSERT INTO act_bch_ontology_map (  data_type,
                bch_concept_path,
                bch_name_char,
                bch_concept_cd,
                act_concept_path,
                act_name_char,
                act_concept_cd )
                select 'ACT_CPT_PX_2018AA_HPDS' src, b.concept_path bch_concept_path,b.name_char bch_name_char,b.concept_cd bch_concept_cd,
                a.hpds_path act_concept_path,a.c_name act_name_char,a.c_basecode act_concept_cd
                from
                ( select *
                from concept_dimension
                WHERE concept_path like '%\Procedures\%'
                and  concept_cd like 'CPT4%' ) b, ACT_CPT_PX_2018AA_HPDS a
                where b.concept_cd = a.c_basecode
                union
                select 'ACT_CPT_PX_2018AA_HPDS' src, b.concept_path bch_concept_path,b.name_char bch_name_char,b.concept_cd bch_concept_cd,
                a.hpds_path act_concept_path,a.c_name act_name_char,a.c_basecode act_concept_cd
                from
                (select *
                from concept_dimension
                WHERE concept_path like '%\Procedures\%'
                 and  concept_cd like 'CPT4%' ) b, ACT_CPT_PX_2018AA_HPDS a
                where b.name_char = a.c_name
                and b.concept_cd <> a.c_basecode ;

     log_msg(p_runid, 'End MAP_DATA_LOAD_ACT_CPT_PX_HPDS: Inserted Rows '||sql%rowcount, 'Y');        
     COMMIT;
  END;

PROCEDURE MAP_DATA_LOAD_VISIT_HPDS (
    p_runid        IN NUMBER )  
    AS
  BEGIN
     log_msg(p_runid, 'Start MAP_DATA_LOAD_VISIT_HPDS: ', 'Y');  
        DELETE FROM act_bch_ontology_map
        WHERE data_type in ( 'Visit type','Length of stay', 'Visit Age');
        log_msg(p_runid, 'Delete existing data MAP_DATA_LOAD_VISIT_HPDS: '||sql%rowcount, 'Y');  


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
               hpds_path act_concept_path,
                 m.act_visit_type act_name_char,
                a.c_basecode,
                'Visit type'  
            from a_ncats_visit_details_map m,  NCATS_VISIT_DETAILS_HPDS a
            where c_fullname like '%\Visit type\%'
            and a.c_name = m.act_visit_type; 
            
        log_msg(p_runid, 'Inserted Visit type  data MAP_DATA_LOAD_VISIT_HPDS: '||sql%rowcount, 'Y'); 
            --Populating data for '\ACT Visit Details\Length of stay

             Insert into ACT_BCH_ONTOLOGY_MAP (ACT_CONCEPT_PATH,ACT_NAME_CHAR,ACT_CONCEPT_CD,BCH_CONCEPT_PATH,BCH_NAME_CHAR,BCH_CONCEPT_CD,DATA_TYPE) 
             select hpds_path, decode( c_name,'> 10 days','> 10 days',c_basecode   ) ACT_NAME_CHAR,c_basecode ACT_CONCEPT_CD, null BCH_CONCEPT_PATH, decode( c_name,'> 10 days','> 10 days',c_basecode   ) BCH_NAME_CHAR,null,'Length of stay' 
             from NCATS_VISIT_DETAILS_HPDS 
             where c_fullname like '%\Length of stay\_%';
             
            log_msg(p_runid, 'Inserted Length of stay  data MAP_DATA_LOAD_VISIT_HPDS: 11', 'Y'); 
            
            --
           
            INSERT INTO act_bch_ontology_map (
                bch_concept_path,
                bch_name_char,
                bch_concept_cd,
                act_concept_path,
                act_name_char,
                act_concept_cd,
                data_type)
            select 
                null bch_concept_path,
                null bch_name_char,
                null bch_concept_cd,
                hpds_path act_concept_path,
                c_name act_name_char,
                c_basecode act_concept_cd,
                'Visit Age'
           from NCATS_VISIT_DETAILS_HPDS 
           where hpds_path like '\ACT Visit Details\Age at visit' ;
           
          log_msg(p_runid, 'Inserted Visit Age  data MAP_DATA_LOAD_VISIT_HPDS: '||sql%rowcount, 'Y'); 
            --
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
        WHERE data_type in ( 'Hispanic','Race','Demographic Age' );
        log_msg(p_runid, 'Delete existing data MAP_DATA_LOAD_DEMOGRAPHCS_HPDS: '||sql%rowcount, 'Y'); 
        --Loads mapping for Hispanic and Race flag from Observation_Fact table.

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
           (  SELECT
                concept_path bch_concept_path,
                concept_cd bch_concept_cd,
                name_char bch_name_char,
                hpds_path act_concept_path,
                c_basecode act_concept_cd,
                c_name act_name_char
            FROM concept_dimension cd , ( select * from NCATS_DEMOGRAPHICS_HPDS where c_basecode = 'DEM|HISP:NI'  )
            WHERE concept_cd = 'DEM|ETHNICITY:0'
            AND name_char = 'NOT DEFINED IN SOURCE'
           UNION ALL
           SELECT
                concept_path bch_concept_path,
                concept_cd bch_concept_cd,
                name_char bch_name_char,
                hpds_path act_concept_path,
                c_basecode act_concept_cd,
                c_name act_name_char
            FROM concept_dimension cd , ( select * from NCATS_DEMOGRAPHICS_HPDS where c_basecode = 'DEM|HISP:N'  )            
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
                hpds_path act_concept_path,
                c_basecode act_concept_cd,
                c_name act_name_char
            FROM concept_dimension cd , ( select * from NCATS_DEMOGRAPHICS_HPDS where c_basecode = 'DEM|HISP:Y'  )            
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
                    'Caribbean Islander')   
 
     );
                    
                    
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
                nvl(hpds_path,'\ACT Demographics\Race\'||'No Information' )  act_concept_path,
                nvl(a.c_name , 'No Information') act_name_char,
                nvl(a.c_basecode,'DEM|RACE:NI') act_concept_cd,
                'Race' data_type from
             ( select  * from NCATS_DEMOGRAPHICS_HPDS  where c_fullname LIKE '\ACT\Demographics\Race%' ) a,
             ( select * from concept_dimension cd
                            WHERE   cd.concept_cd LIKE 'DEM|RACE:%' ) r
                             where r.name_char = a.c_name (+); 


             log_msg(p_runid, 'Inserted Race rows MAP_DATA_LOAD_DEMOGRAPHCS_HPDS: '||sql%rowcount, 'Y');  
            
            INSERT INTO act_bch_ontology_map (
                bch_concept_path,
                bch_name_char,
                bch_concept_cd,
                act_concept_path,
                act_name_char,
                act_concept_cd,
                data_type)
            select 
                null bch_concept_path,
                null bch_name_char,
                null bch_concept_cd,
                hpds_path act_concept_path,
                c_name act_name_char,
                c_basecode act_concept_cd,
                'Demographic Age'
           from NCATS_DEMOGRAPHICS_HPDS 
           where hpds_path like '\ACT Demographics\Age';
           
        log_msg(p_runid, 'Inserted Demographic Age rows MAP_DATA_LOAD_DEMOGRAPHCS_HPDS: '||sql%rowcount, 'Y');  

     log_msg(p_runid, 'End MAP_DATA_LOAD_DEMOGRAPHCS_HPDS: ', 'Y');        
     COMMIT;
  END;

PROCEDURE MAP_DATA_LOAD_COVID_HPDS (
    p_runid        IN NUMBER )  
    AS
    v_rowcounts NUMBER := 0;
  BEGIN
     log_msg(p_runid, 'Start MAP_DATA_LOAD_COVID_HPDS: ', 'Y');  
        DELETE FROM act_bch_ontology_map
        WHERE data_type in( 'ACT_COVID_DERIVED','ACT_COVID_DERIVED_LAB') ;

        log_msg(p_runid, 'Delete existing data MAP_DATA_LOAD_COVID_HPDS: '||sql%rowcount, 'Y');        
--ICD9
INSERT INTO act_bch_ontology_map (  data_type,
            bch_concept_path,
            bch_name_char,
            bch_concept_cd,
            act_concept_path,
            act_name_char,
            act_concept_cd
          )
SELECT distinct 'ACT_COVID_DERIVED' src , 
          b.concept_path bch_concept_path,
          b.name_char bch_name_char,
          b.concept_cd bch_concept_cd,
          a.hpds_path  act_concept_path,
          a.c_name  act_name_char,
          a.c_basecode  act_concept_cd
         from
        ( SELECT c_fullname,c_name,c_basecode, hpds_path
        FROM ACT_COVID_HPDS ) a,concept_dimension b
        where replace(a.c_basecode,'ICD9CM','ICD9') = b.concept_cd 
        and b.concept_cd like 'ICD9%' 
        ;
        v_rowcounts := v_rowcounts + sql%rowcount;
--ICD10
INSERT INTO act_bch_ontology_map (  data_type,
            bch_concept_path,
            bch_name_char,
            bch_concept_cd,
            act_concept_path,
            act_name_char,
            act_concept_cd
          )
        SELECT distinct 'ACT_COVID_DERIVED' src , 
          b.concept_path bch_concept_path,
          b.name_char bch_name_char,
          b.concept_cd bch_concept_cd,
          a.hpds_path  act_concept_path,
          a.c_name  act_name_char,
          a.c_basecode  act_concept_cd
         from
        ( SELECT c_fullname,c_name,c_basecode, hpds_path
        FROM act_covid_hpds ) a,concept_dimension b
        where replace(a.c_basecode,'ICD10CM','ICD10') = b.concept_cd 
        and b.concept_cd like 'ICD10%' 
        ;
        v_rowcounts := v_rowcounts + sql%rowcount;

--Concept_cd match
        INSERT INTO act_bch_ontology_map (  data_type,
            bch_concept_path,
            bch_name_char,
            bch_concept_cd,
            act_concept_path,
            act_name_char,
            act_concept_cd
          )
        select distinct 'ACT_COVID_DERIVED' src , 
          b.concept_path bch_concept_path,
          b.name_char bch_name_char,
          b.concept_cd bch_concept_cd,
          a.hpds_path  act_concept_path,
          a.c_name  act_name_char,
          a.c_basecode  act_concept_cd
         from
        ( SELECT c_fullname,c_name,c_basecode, hpds_path
        FROM act_covid_hpds
        ) a,concept_dimension b
        where a.c_basecode = b.concept_cd 
        and parse_nth_value(c_basecode,1,':') not in ('ICD10CM','ICD9CM','ICD10PCS'  )
        ;
        v_rowcounts := v_rowcounts + sql%rowcount;
--ICDPROC
INSERT INTO act_bch_ontology_map (  data_type,
                    bch_concept_path,
                    bch_name_char,
                    bch_concept_cd,
                    act_concept_path,
                    act_name_char,
                    act_concept_cd
                  )
SELECT distinct 'ACT_COVID_DERIVED' src , 
                  b.concept_path bch_concept_path,
                  b.name_char bch_name_char,
                  b.concept_cd bch_concept_cd,
                  a.hpds_path  act_concept_path,
                  a.c_name  act_name_char,
                  a.c_basecode  act_concept_cd
                 from
                ( SELECT c_fullname,c_name,c_basecode, hpds_path
                FROM act_covid_hpds ) a,concept_dimension b
                where replace(a.c_basecode,'ICD10PCS','ICD10PROC') = b.concept_cd
                and b.concept_cd like 'ICD10PROC%';
                v_rowcounts := v_rowcounts + sql%rowcount;
 --Meds  

INSERT INTO act_bch_ontology_map (  data_type,
            bch_concept_path,
            bch_name_char,
            bch_concept_cd,
            act_concept_path,
            act_name_char,
            act_concept_cd
          )
SELECT DISTINCT
    'ACT_COVID_DERIVED' src,    bch_concept_path,
    bch_name_char,
    bch_concept_cd,
    a.hpds_path act_concept_path,
    a.c_name act_name_char,
    a.c_basecode act_concept_cd
FROM
    a_med_cd_act_bch_map b,
    act_covid_hpds a
WHERE a.c_basecode = b.act_concept_cd
AND parse_nth_value(c_basecode,1,':') = 'RXNORM';
v_rowcounts := v_rowcounts + sql%rowcount;

--Labs

INSERT INTO act_bch_ontology_map (  data_type,
                    bch_concept_path,
                    bch_name_char,
                    bch_concept_cd,
                    act_concept_path,
                    act_name_char,
                    act_concept_cd
                  )
SELECT distinct 'ACT_COVID_DERIVED_LAB' src , 
                  null bch_concept_path,
                  null bch_name_char,
                  b.bch_concept_cd,
                  a.hpds_path  act_concept_path,
                  a.c_name  act_name_char,
                  a.c_basecode  act_concept_cd from
                (SELECT c_fullname, c_name, c_basecode,  hpds_path
                FROM act_covid_hpds ) a, 
                ( select  bch_lab_code bch_concept_cd, 
                'LOINC:'||loinc_lab_code bch_loinc_cd
                from A_LAB_CD_ACT_BCH_MAP  m where  loinc_lab_code is not null ) b
                where  a.c_basecode = b.bch_loinc_cd ;

        v_rowcounts := v_rowcounts + sql%rowcount; 
        log_msg(p_runid, 'End MAP_DATA_LOAD_COVID_HPDS: '||v_rowcounts, 'Y'); 
        COMMIT;
  END;

PROCEDURE MAP_DATA_LOAD_MED_ALPHA_HPDS (
    p_runid        IN NUMBER )  
    AS
  BEGIN
        log_msg(p_runid, 'Start MAP_DATA_LOAD_MED_ALPHA_HPDS: '||sql%rowcount, 'Y'); 
        DELETE FROM act_bch_ontology_map
        WHERE data_type = 'MED_ALPHA_HPDS';
        log_msg(p_runid, 'Delete existing data MAP_DATA_LOAD_MED_ALPHA_HPDS: '||sql%rowcount, 'Y'); 
        INSERT INTO act_bch_ontology_map (  data_type,
            act_concept_path,
            act_name_char,
            act_concept_cd,
            bch_concept_path,
            bch_name_char,
            bch_concept_cd
          )
      select distinct 'MED_ALPHA_HPDS' src, a.hpds_path act_concept_path,a.c_name act_name_char,a.c_basecode act_concept_cd,
         bch_concept_path, bch_name_char, bch_concept_cd
        from A_MED_CD_ACT_BCH_MAP b,
         ACT_MED_ALPHA_HPDS a
         where  a.c_basecode = b.act_concept_cd 
         AND a.hpds_path LIKE '%Medications%' 
         AND bch_concept_cd like 'ADMINMED:%' ;


        log_msg(p_runid, 'End MAP_DATA_LOAD_MED_ALPHA_HPDS: '||sql%rowcount, 'Y'); 
        COMMIT;
  END;    
---

PROCEDURE MAP_DNA_GIC_BIOSAMPLES_HPDS (
    p_runid        IN NUMBER )  
    AS
  BEGIN
        log_msg(p_runid, 'Start DNA_GIC_BIOSAMPLES_HPDS: '||sql%rowcount, 'Y'); 
        DELETE FROM act_bch_ontology_map
        WHERE data_type = 'NucleicAcid';
       log_msg(p_runid, 'Delete existing data DNA_GIC_BIOSAMPLES_HPDS: '||sql%rowcount, 'Y'); 

                INSERT INTO act_bch_ontology_map (  data_type,
                    act_concept_path,
                    act_name_char,
                    act_concept_cd,
                    bch_concept_path,
                    bch_name_char,
                    bch_concept_cd
                  )
               SELECT 'NucleicAcid' data_type,
                  hpds.hpds_path,
                  hpds.c_name,
                  hpds.c_basecode,
                  na.concept_path,
                  na.name_char,
                  na.concept_cd 
               FROM   (SELECT * from concept_dimension
                    WHERE concept_path LIKE '\Bio Specimens\NucleicAcid%DNA%') na ,-- pending confirmation
                    (SELECT c_fullname, c_name, c_basecode, hpds_path
                    FROM GIC_BIOSAMPLES_HPDS
                    WHERE c_fullname like '\Bio Specimens\NucleicAcid\') hpds ;



       log_msg(p_runid, 'End DNA_GIC_BIOSAMPLES_HPDS: '||sql%rowcount, 'Y'); 
        COMMIT;
  END;  

  PROCEDURE MAP_PLASMA_GIC_BIOSAMPLES_HPDS (
    p_runid        IN NUMBER )  
    AS
  BEGIN
        log_msg(p_runid, 'Start MAP_PLASMA_GIC_BIOSAMPLES_HPDS '||sql%rowcount, 'Y'); 
        DELETE FROM act_bch_ontology_map
        WHERE data_type = 'Plasma';
        log_msg(p_runid, 'Delete existing data MAP_PLASMA_GIC_BIOSAMPLES_HPDS '||sql%rowcount, 'Y'); 

                INSERT INTO act_bch_ontology_map (  data_type,
                    act_concept_path,
                    act_name_char,
                    act_concept_cd,
                    bch_concept_path,
                    bch_name_char,
                    bch_concept_cd
                  )
               SELECT 'Plasma' data_type,
                  hpds.hpds_path,
                  hpds.c_name,
                  hpds.c_basecode,
                  na.concept_path,
                  na.name_char,
                  na.concept_cd 
               FROM   (SELECT * from concept_dimension
                    WHERE concept_path LIKE  '\Bio Specimens\HumanFluid\Plasma\Plasma\SPECIMENS:HF.PLS.000\' ) na ,
                    (SELECT c_fullname, c_name, c_basecode, hpds_path
                    FROM gic_biosamples_hpds
                    WHERE c_basecode = 'BIOSPECIMEN:HF.PLS.000 Quantity') hpds ;

        log_msg(p_runid, 'End MAP_PLASMA_GIC_BIOSAMPLES_HPDS '||sql%rowcount, 'Y'); 
        COMMIT;
  END;  

PROCEDURE MAP_BLOOD_GIC_BIOSAMPLES_HPDS (
    p_runid        IN NUMBER )  
    AS
  BEGIN
        log_msg(p_runid, 'Start MAP_BLOOD_GIC_BIOSAMPLES_HPDS '||sql%rowcount, 'Y'); 
        DELETE FROM act_bch_ontology_map
        WHERE data_type = 'Blood';
        log_msg(p_runid, 'Delete existing data MAP_BLOOD_GIC_BIOSAMPLES_HPDS '||sql%rowcount, 'Y'); 

                INSERT INTO act_bch_ontology_map (  data_type,
                    act_concept_path,
                    act_name_char,
                    act_concept_cd,
                    bch_concept_path,
                    bch_name_char,
                    bch_concept_cd
                  )
               SELECT 'Blood' data_type,
                  hpds.hpds_path,
                  hpds.c_name,
                  hpds.c_basecode,
                  na.concept_path,
                  na.name_char,
                  na.concept_cd 
               FROM   (SELECT * from concept_dimension
                    WHERE concept_path LIKE  '\Bio Specimens\HumanFluid\Blood (Whole)\Blood (Whole)\SPECIMENS:HF.BLD.000%' ) na ,
                    (SELECT c_fullname, c_name, c_basecode, hpds_path
                    FROM gic_biosamples_hpds
                    WHERE c_basecode = 'BIOSPECIMEN:HF.BLD.000 Quantity') hpds ;



        log_msg(p_runid, 'End MAP_BLOOD_GIC_BIOSAMPLES_HPDS '||sql%rowcount, 'Y'); 
        COMMIT;
  END;  
  

PROCEDURE MAP_TISSUE_GIC_BIOSAMPLES_HPDS (
    p_runid        IN NUMBER )  
    AS
  BEGIN
        log_msg(p_runid, 'Start MAP_TISSUE_GIC_BIOSAMPLES_HPDS '||sql%rowcount, 'Y'); 
        DELETE FROM act_bch_ontology_map
        WHERE data_type = 'HumanTissue';
        log_msg(p_runid, 'Delete existing data MAP_TISSUE_GIC_BIOSAMPLES_HPDS '||sql%rowcount, 'Y'); 

                INSERT INTO act_bch_ontology_map (  data_type,
                    act_concept_path,
                    act_name_char,
                    act_concept_cd,
                    bch_concept_path,
                    bch_name_char,
                    bch_concept_cd
                  )
               SELECT 'HumanTissue' data_type,
                  hpds.hpds_path,
                  hpds.c_name,
                  hpds.c_basecode,
                  na.concept_path,
                  na.name_char,
                  na.concept_cd 
               FROM   (SELECT * from concept_dimension
                    WHERE concept_path LIKE  '\Bio Specimens\HumanTissue%' ) na ,
                    (SELECT c_fullname, c_name, c_basecode, hpds_path
                    FROM gic_biosamples_hpds
                    WHERE c_basecode = 'BIOSPECIMEN:HT.TS.000 Available') hpds ;



        log_msg(p_runid, 'End MAP_TISSUE_GIC_BIOSAMPLES_HPDS '||sql%rowcount, 'Y'); 
        COMMIT;
  END; 
  

 PROCEDURE MAP_GNOME_GIC_BIOSAMPLES_HPDS (
    p_runid        IN NUMBER )  
    AS
  BEGIN
        log_msg(p_runid, 'Start MAP_GNOME_GIC_BIOSAMPLES_HPDS '||sql%rowcount, 'Y'); 
        DELETE FROM act_bch_ontology_map
        WHERE data_type = 'Gnome';
        log_msg(p_runid, 'Delete existing data MAP_GNOME_GIC_BIOSAMPLES_HPDS '||sql%rowcount, 'Y'); 

                INSERT INTO act_bch_ontology_map (  data_type,
                    act_concept_path,
                    act_name_char,
                    act_concept_cd,
                    bch_concept_path,
                    bch_name_char,
                    bch_concept_cd
                  )
               SELECT 'Gnome' data_type,
                  hpds.hpds_path,
                  hpds.c_name,
                  hpds.c_basecode,
                  na.concept_path,
                  na.name_char,
                  na.concept_cd 
               FROM   (SELECT * from concept_dimension
                    WHERE concept_path LIKE   '\Next Generation Sequencing\Exomes\'  ) na ,
                    (SELECT c_fullname, c_name, c_basecode, hpds_path
                    FROM gic_biosamples_hpds
                    WHERE c_basecode = 'DNA.DATA' ) hpds ;



        log_msg(p_runid, 'End MAP_GNOME_GIC_BIOSAMPLES_HPDS '||sql%rowcount, 'Y'); 
        COMMIT;
  END; 
  
  PROCEDURE MAP_CSF_GIC_BIOSAMPLES_HPDS (
    p_runid        IN NUMBER )  
    AS
  BEGIN
        log_msg(p_runid, 'Start MAP_CSF_GIC_BIOSAMPLES_HPDS '||sql%rowcount, 'Y'); 
        DELETE FROM act_bch_ontology_map
        WHERE data_type = 'CSF';
        log_msg(p_runid, 'Delete existing data MAP_CSF_GIC_BIOSAMPLES_HPDS '||sql%rowcount, 'Y'); 

                INSERT INTO act_bch_ontology_map (  data_type,
                    act_concept_path,
                    act_name_char,
                    act_concept_cd,
                    bch_concept_path,
                    bch_name_char,
                    bch_concept_cd
                  )
                SELECT 'CSF' data_type,
                  hpds.hpds_path,
                  hpds.c_name,
                  hpds.c_basecode,
                  na.concept_path,
                  na.name_char,
                  na.concept_cd 
               FROM   (SELECT distinct concept_cd, null concept_path, null name_char
                       from observation_fact
                     where concept_cd = 'SPECIMENS:HF.CSF.000') na,
                    (SELECT c_fullname, c_name, c_basecode, hpds_path
                    FROM gic_biosamples_hpds
                    WHERE c_basecode = 'BIOSPECIMEN:HF.CSF.000 Available' ) hpds ;

        log_msg(p_runid, 'End MAP_CSF_GIC_BIOSAMPLES_HPDS '||sql%rowcount, 'Y'); 
        COMMIT;
  END; 

---
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

            insert into  HPDS_DATA_LATEST( PATIENT_NUM ,CONCEPT_PATH , NVAL_NUM , TVAL_CHAR ,START_DATE )
            SELECT distinct patient_num, hpds_path concept_path ,trunc((sysdate - (cast(birth_date as date )) )/365)  years ,null c_name,trunc(sysdate)
            from patient_dimension  pd, ( select * from NCATS_DEMOGRAPHICS_HPDS where hpds_path like '\ACT Demographics\Age' )mp
            where  trunc((sysdate - (cast(birth_date as date )) )/365) >= 0;

        log_msg(p_runid,'EXTRCT_HPDS_Demographics Age End  '||sql%rowcount,'X');                   


        log_msg(p_runid,'EXTRCT_HPDS_Demographics Gender Start ','X'); 
            insert into  HPDS_DATA_LATEST( PATIENT_NUM ,CONCEPT_PATH , NVAL_NUM , TVAL_CHAR ,START_DATE )
            select distinct patient_num ,nvl(hpds_path,'\ACT Demographics\Sex\No Information' ) hpds_path ,null,decode(sex_cd,'Male','Male','Female','Female','No Information') ,trunc(sysdate)
            from patient_dimension  pd, ( select * from NCATS_DEMOGRAPHICS_HPDS where hpds_path like '\ACT Demographics\Sex\%' )mp
            where decode(sex_cd,'Male','Male','Female','Female','No Information') = mp.c_name(+);

        log_msg(p_runid,'EXTRCT_HPDS_Demographics Gender End  '||sql%rowcount,'X');                   

        log_msg(p_runid,'EXTRCT_HPDS_Demographics HipanicFlag Start  ','X'); 

            INSERT INTO  HPDS_DATA_LATEST( PATIENT_NUM ,CONCEPT_PATH , NVAL_NUM , TVAL_CHAR ,START_DATE )
            SELECT  DISTINCT fact1.patient_num,m.act_concept_path ,null,m.act_name_char, trunc(sysdate)
            FROM  observation_fact fact1 , act_bch_ontology_map m ,patient_dimension  pd
            WHERE  fact1.concept_cd = m.bch_concept_cd
            AND fact1.patient_num = pd.patient_num
            AND  m.data_type = 'Hispanic';


        log_msg(p_runid,'EXTRCT_HPDS_Demographics HipanicFlag End  '||sql%rowcount,'X');                   

        log_msg(p_runid,'EXTRCT_HPDS_Demographics Race Start  ','X'); 

                INSERT INTO  HPDS_DATA_LATEST( PATIENT_NUM ,CONCEPT_PATH , NVAL_NUM , TVAL_CHAR ,START_DATE )
                SELECT distinct fact1.patient_num,act_concept_path,null,act_name_char,trunc(sysdate)
                FROM observation_fact  fact1, act_bch_ontology_map m ,patient_dimension  pd
                WHERE   fact1.concept_cd = m.bch_concept_cd
                AND fact1.patient_num = pd.patient_num
                AND m.DATA_TYPE = 'Race' ;


        log_msg(p_runid,'EXTRCT_HPDS_Demographics Race End  '||sql%rowcount,'X'); 

        log_msg(p_runid,'EXTRCT_HPDS_Demographics Vital Status Start  ','X');
             insert into  HPDS_DATA_LATEST ( PATIENT_NUM ,CONCEPT_PATH , NVAL_NUM , TVAL_CHAR ,START_DATE )
             select distinct patient_num,hpds_path,null,c_name ,death_date
             from patient_dimension pd, ( select * from NCATS_DEMOGRAPHICS_HPDS where hpds_path like '\ACT Demographics\Vital Status\%' ) mp
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
    /* Pre requesite table a_ncats_visit_details_map  should be populated with mapping data   */
BEGIN
null;
/*
        log_msg(p_runid,'EXTRCT_HPDS_Visit_data Start  ','X'); 
        v_sql := 'TRUNCATE TABLE visit_fact_details ';

        log_msg(p_runid,'Load visit_fact_details Start  ','X'); 
        execute immediate v_sql;

        log_msg(p_runid,'Refresh data visit_fact_details Start ','X'); 
            v_sql := 'INSERT INTO visit_fact_details ( patient_num,inout_cd,length_of_stay,age_at_visit_yrs,start_date) '||
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
                            ' FROM visit_dimension where  dbms_lob.substr(visit_blob,9,1) not in ( ''Canceled'',''No Show'')'||
                       ' ) vd, patient_dimension pd '||
                   ' WHERE  vd.patient_num = pd.patient_num '||
              '  ) WHERE trunc( (start_date - birth_date) / 365) >= 0 ';
               execute immediate v_sql;
              dbms_output.put_line(v_sql);

        log_msg(p_runid,'Refresh data visit_fact_details End '||SQL%ROWCOUNT,'X'); 
              commit;
        log_msg(p_runid,'EXTRCT_HPDS_Visit_data Age Start  ','X'); 

            insert into HPDS_DATA_LATEST ( patient_num,concept_path,nval_num,tval_char,start_date  )
            select  distinct patient_num,  act_concept_path,age_at_visit_yrs,act_name_char,start_date
            from VISIT_FACT_DETAILS v, (select * from act_bch_ontology_map m
            where data_type = 'Visit Age')m ;-- Modified 'E' to c_name

        log_msg(p_runid,'EXTRCT_HPDS_Visit_data Age End  '||SQL%ROWCOUNT,'X'); 
            commit;
        log_msg(p_runid,'EXTRCT_HPDS_Visit_data Visit type Start  ','X'); 

            insert into HPDS_DATA_LATEST ( patient_num,concept_path,tval_char,start_date  )                    
            SELECT  distinct v.patient_num, m.act_concept_path, m.act_name_char,start_date
            FROM VISIT_FACT_DETAILS V, act_bch_ontology_map m
            where m.data_type =   'Visit type' -- 'visit_details_map'
            and  v.inout_cd = M.BCH_name_char;

       log_msg(p_runid,'EXTRCT_HPDS_Visit_data Visit type End  '||SQL%ROWCOUNT,'X');  
                     commit;
       log_msg(p_runid,'EXTRCT_HPDS_Visit_data Length of stay Start  ','X'); 


        insert into HPDS_DATA_LATEST ( patient_num,concept_path,tval_char ,start_date )
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
                            VISIT_FACT_DETAILS
                        WHERE length_of_stay <= 10
                        AND   length_of_stay > 0

                    ) b,
                    (
                        SELECT
                            *
                        FROM ACT_BCH_ONTOLOGY_MAP
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
                            VISIT_FACT_DETAILS
                        WHERE
                            length_of_stay > 10
                    ) b,
                    (
                        SELECT  *
                        FROM ACT_BCH_ONTOLOGY_MAP
                        WHERE data_type =  'Length of stay'
                        AND  act_name_char = '> 10 days'
                    ) a ;

      log_msg(p_runid,'EXTRCT_HPDS_Visit_data Length of stay End  '||SQL%ROWCOUNT,'X'); 
      commit;
      log_msg(p_runid,'EXTRCT_HPDS_Visit_data End  ','X'); 
      commit;
      */
END;

---ICD10-9
PROCEDURE EXTRACT_ICD10_ICD9_DX_HPDS (
    p_runid        IN NUMBER
) AS

BEGIN
null;
        /* for r_data in (select * from act_bch_ontology_map m
                     where data_type =  'NCATS_ICD10_ICD9_DX_V1_HPDS' ) loop
            INSERT into HPDS_DATA_LATEST( PATIENT_NUM,CONCEPT_PATH,NVAL_NUM,TVAL_CHAR,start_date)      
            SELECT distinct patient_num,act_concept_path ,null,act_name_char,  cast (start_date as date)   
            FROM observation_fact   fact1, act_bch_ontology_map m
            WHERE fact1.concept_cd = m.bch_concept_cd 
            AND data_type =  'NCATS_ICD10_ICD9_DX_V1_HPDS'
            AND  M.BCH_CONCEPT_CD = r_data.BCH_CONCEPT_CD
            ;*/ 
 
end;

---ICD10

PROCEDURE EXTRCT_HPDS_ICD10 (
    p_runid        IN NUMBER
) AS

begin


     log_msg(p_runid,'EXTRCT_HPDS_ICD10 Start  ','X'); 
    
        for r_data in ( select * from act_bch_ontology_map m
                       where data_type =  'ACT_ICD10CM_DX_2018AA_HPDS' ) loop
            
            INSERT into HPDS_DATA_LATEST( PATIENT_NUM,CONCEPT_PATH,NVAL_NUM,TVAL_CHAR,start_date)      
            SELECT DISTINCT fact1.patient_num,  act_concept_path, nval_num, null act_name_char,cast( start_date as date) start_date
            FROM observation_fact   fact1, act_bch_ontology_map m ,patient_dimension pd
            WHERE fact1.concept_cd = m.bch_concept_cd 
            AND fact1.patient_num = pd.patient_num
            AND data_type =  'ACT_ICD10CM_DX_2018AA_HPDS'
            AND M.BCH_CONCEPT_CD = r_data.BCH_CONCEPT_CD 
            AND NVAL_NUM is not null ;
            
     log_msg(p_runid,'EXTRCT_HPDS_ICD10 End  '||sql%rowcount,'X');             
            
            INSERT into HPDS_DATA_LATEST( PATIENT_NUM,CONCEPT_PATH,NVAL_NUM,TVAL_CHAR,start_date) 
            SELECT DISTINCT fact1.patient_num,  act_concept_path,null nval_num,  act_name_char,cast( start_date as date) start_date
            FROM observation_fact   fact1, act_bch_ontology_map m ,patient_dimension pd
            WHERE fact1.concept_cd = m.bch_concept_cd 
            AND fact1.patient_num = pd.patient_num
            AND data_type =  'ACT_ICD10CM_DX_2018AA_HPDS'
            AND M.BCH_CONCEPT_CD = r_data.BCH_CONCEPT_CD 
            AND NVAL_NUM is  null ;
            
            
     log_msg(p_runid,'EXTRCT_HPDS_ICD10 End  '||sql%rowcount,'X'); 
    
    commit;
    end loop;
    commit;
   log_msg(p_runid,'EXTRCT_HPDS_ICD10 End  '); 
end; 


PROCEDURE EXTRCT_HPDS_CPT_PX_2018AA (
    p_runid        IN NUMBER
) AS

Begin

  log_msg(p_runid,'EXTRCT_HPDS_CPT_PX_2018AA Start  ','X'); 
        for r_data in (select * from act_bch_ontology_map m
                       where data_type = 'ACT_CPT_PX_2018AA_HPDS' ) loop
                                          
        INSERT into HPDS_DATA_LATEST( PATIENT_NUM,CONCEPT_PATH,NVAL_NUM,TVAL_CHAR,start_date)      
        SELECT DISTINCT fact1.patient_num,  act_concept_path, nval_num, null act_name_char,cast( start_date as date) start_date
        FROM observation_fact   fact1, act_bch_ontology_map m,patient_dimension pd
        WHERE fact1.concept_cd = m.bch_concept_cd  
        AND fact1.patient_num = pd.patient_num       
        AND data_type =   'ACT_CPT_PX_2018AA_HPDS'
        AND m.bch_concept_cd  = r_data.bch_concept_cd
        AND NVAL_NUM IS NOT NULL;
        
   log_msg(p_runid,'EXTRCT_HPDS_CPT_PX_2018AA End  '||sql%rowcount,'X');        
        
        INSERT into HPDS_DATA_LATEST( PATIENT_NUM,CONCEPT_PATH,NVAL_NUM,TVAL_CHAR,start_date)      
        SELECT DISTINCT fact1.patient_num,  act_concept_path,null nval_num,  act_name_char,cast( start_date as date) start_date
        FROM observation_fact   fact1, act_bch_ontology_map m, patient_dimension pd
        WHERE fact1.concept_cd = m.bch_concept_cd  
        AND fact1.patient_num = pd.patient_num        
        AND data_type =   'ACT_CPT_PX_2018AA_HPDS'
        AND m.bch_concept_cd  = r_data.bch_concept_cd
        AND NVAL_NUM IS  NULL;

  log_msg(p_runid,'EXTRCT_HPDS_CPT_PX_2018AA End  '||sql%rowcount,'X'); 
          commit;
        end loop;
  commit;
    log_msg(p_runid,'EXTRCT_HPDS_CPT_PX_2018AA End  ','X'); 
end;

PROCEDURE EXTRCT_HPDS_LAB_Results (
    p_runid        IN NUMBER
) AS

 begin

       log_msg(p_runid,'EXTRCT_HPDS_LAB_Results Start  ','X'); 
  
       for r_data in ( select * from act_bch_ontology_map m
                       where data_type =  'NCATS_LABS_HPDS' ) loop
       insert into HPDS_DATA_LATEST ( PATIENT_NUM,CONCEPT_PATH,NVAL_NUM,TVAL_CHAR,start_date)
        SELECT DISTINCT fact1.patient_num,  act_concept_path, nval_num, null act_name_char,cast( start_date as date) start_date
       FROM
            (   SELECT patient_num, concept_cd,nval_num,start_date
                FROM observation_fact
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
            act_bch_ontology_map m, patient_dimension pd
        WHERE fact1.concept_cd = m.bch_concept_cd  
        AND fact1.patient_num = pd.patient_num
        AND data_type =  'NCATS_LABS_HPDS' 
        AND fact1.concept_cd = r_data.bch_concept_cd 
        AND NVAL_NUM IS NOT NULL ;
      
      log_msg(p_runid,'EXTRCT_HPDS_LAB_Results End  '||sql%rowcount,'X');         
            
       insert into HPDS_DATA_LATEST ( PATIENT_NUM,CONCEPT_PATH,NVAL_NUM,TVAL_CHAR,start_date)
       SELECT DISTINCT fact1.patient_num,  act_concept_path,null nval_num,  act_name_char,cast( start_date as date) start_date
       FROM
            (   SELECT patient_num, concept_cd,nval_num,start_date
                FROM observation_fact
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
            act_bch_ontology_map m ,patient_dimension pd
        WHERE fact1.concept_cd = m.bch_concept_cd  
        AND fact1.patient_num = pd.patient_num        
        AND data_type =  'NCATS_LABS_HPDS' 
        AND fact1.concept_cd = r_data.bch_concept_cd 
        AND NVAL_NUM IS  NULL ;                       
    
          
        log_msg(p_runid,'EXTRCT_HPDS_LAB_Results End  '||sql%rowcount,'X'); 
     
        commit;
   end loop;
 commit; 
  log_msg(p_runid,'EXTRCT_HPDS_LAB_Results End  ','X'); 
 

 end;

PROCEDURE EXTRACT_COVID_DATA_HPDS (
    p_runid        IN NUMBER
) AS

BEGIN
null;
/*
    log_msg(p_runid,'EXTRACT_COVID_DATA_HPDS Start  ','X'); 

            for r_data in (select * from act_bch_ontology_map m
            where data_type =  'ACT_COVID_DERIVED' ) loop
            
            
                        INSERT into HPDS_DATA_LATEST( PATIENT_NUM,CONCEPT_PATH,NVAL_NUM,TVAL_CHAR,start_date)      
                        SELECT distinct patient_num,act_concept_path ,null,act_name_char,  cast (start_date as date)   
                        FROM observation_fact   fact1, act_bch_ontology_map m
                        WHERE fact1.concept_cd = m.bch_concept_cd 
                        AND data_type =  'ACT_COVID_DERIVED'  
                        AND  m.bch_concept_cd  = r_data.bch_concept_cd ;
                        commit;
            
            end loop;
            commit;

            
            log_msg(p_runid,'ACT_COVID_DERIVED_LAB Start  ','X'); 
            for r_data in (select * from act_bch_ontology_map m
                           where data_type =  'ACT_COVID_DERIVED_LAB' ) loop


            INSERT into HPDS_DATA_LATEST( PATIENT_NUM,CONCEPT_PATH,NVAL_NUM,TVAL_CHAR,start_date)      
            SELECT distinct patient_num,act_concept_path , nval_num,act_name_char,  cast (start_date as date)   
            FROM observation_fact   fact1, act_bch_ontology_map m
            WHERE fact1.concept_cd = m.bch_concept_cd 
            AND M.BCH_CONCEPT_CD = r_data.BCH_CONCEPT_CD
            AND m.data_type =  'ACT_COVID_DERIVED_LAB'  ;   -- Modified 'E' to c_name/act_name_char
    
            log_msg(p_runid,'ACT_COVID_DERIVED_LAB End  '||sql%rowcount,'X'); 
            commit;
            end loop;
            commit;

    log_msg(p_runid,'EXTRACT_COVID_DATA_HPDS End  '||sql%rowcount,'X'); 
    commit;
    */
end; 


PROCEDURE EXTRCT_HPDS_MED_ALPHA (
    p_runid        IN NUMBER
) AS

Begin

  delete from HPDS_DATA_LATEST where concept_path like '\ACT Medications\%';
  --commit;
  log_msg(p_runid,'EXTRCT_HPDS_MED_ALPHA Start  ','X'); 

  for r_data in ( select * from act_bch_ontology_map m where data_type =   'MED_ALPHA_HPDS' order by bch_concept_cd  ) loop

       INSERT into HPDS_DATA_LATEST( PATIENT_NUM,CONCEPT_PATH,NVAL_NUM,TVAL_CHAR,start_date)      
       SELECT DISTINCT fact1.patient_num,  act_concept_path, nval_num, null act_name_char,cast( start_date as date) start_date
       FROM observation_fact   fact1, act_bch_ontology_map m , patient_dimension pd
       WHERE fact1.concept_cd = m.bch_concept_cd 
       AND fact1.patient_num = pd.patient_num         
       AND M.BCH_CONCEPT_CD = r_data.BCH_CONCEPT_CD
       AND m.data_type =  'MED_ALPHA_HPDS' 
       AND NVAL_NUM IS NOT NULL ;
       
   log_msg(p_runid,'EXTRCT_HPDS_MED_ALPHA End concept_cd '||r_data.bch_concept_cd||' Rows count '||sql%rowcount,'X');       
       
       INSERT into HPDS_DATA_LATEST( PATIENT_NUM,CONCEPT_PATH,NVAL_NUM,TVAL_CHAR,start_date)      
       SELECT DISTINCT fact1.patient_num,  act_concept_path,null nval_num,  act_name_char,cast( start_date as date) start_date
        FROM observation_fact   fact1, act_bch_ontology_map m, patient_dimension pd
       WHERE fact1.concept_cd = m.bch_concept_cd 
        AND fact1.patient_num = pd.patient_num         
       AND M.BCH_CONCEPT_CD = r_data.BCH_CONCEPT_CD
       AND m.data_type =  'MED_ALPHA_HPDS' 
       AND NVAL_NUM IS  NULL ;

  log_msg(p_runid,'EXTRCT_HPDS_MED_ALPHA End concept_cd '||r_data.bch_concept_cd||' Rows count '||sql%rowcount,'X'); 
  commit;
  end loop;
  log_msg(p_runid,'EXTRCT_HPDS_MED_ALPHA End concept_cd End'); 
end;


--
/*
PROCEDURE EXTRCT_HPDS_MED_VA (
    p_runid        IN NUMBER
) AS

Begin

  log_msg(p_runid,'EXTRCT_HPDS_MED_VA Start  ','X'); 

        for r_data in ( select distinct patient_num from patient_dimension order by patient_num   ) loop

        INSERT into HPDS_DATA_LATEST( PATIENT_NUM,CONCEPT_PATH,NVAL_NUM,TVAL_CHAR,start_date)      
        SELECT distinct patient_num,act_concept_path ,null,act_name_char,  cast( start_date as date) start_date
        FROM observation_fact fact1, act_bch_ontology_map m
        WHERE fact1.concept_cd = m.bch_concept_cd  
        AND data_type =   'MED_VA_HPDS'
        and patient_num = r_data.patient_num ;


        TM_LOG_PKG.log_msg(p_runid,'EXTRCT_HPDS_MED_VA End  '||r_data.patient_num||' ' ||sql%rowcount,'X'); 

        commit;
        End Loop;
  log_msg(p_runid,'EXTRCT_HPDS_MED_VA End  ','X'); 
end;
*/
--   


PROCEDURE  Run_EXTRCT_HPDS_Data  (
    p_runid        IN NUMBER ) AS
    v_sql          VARCHAR2(4000) ;
    v_prf          VARCHAR2(10);
BEGIN
     log_msg(p_runid,'Run_EXTRCT_HPDS_Data Start  ','X'); 
     v_prf := to_char( sysdate,'MMDDHHMISS');
     v_sql := 'Alter table HPDS_DATA_LATEST rename to HPDS_DATA_LATEST_'||v_prf;
     
     execute immediate v_sql;
     dbms_output.put_line(v_sql);
     v_sql := 'Create table HPDS_DATA_LATEST as select * from HPDS_DATA_LATEST_'||v_prf ||' where 0 > 1 ';

     execute immediate v_sql;

     dbms_output.put_line(v_sql);

     EXTRCT_HPDS_Demographics ( p_runid  ) ;

     --EXTRCT_HPDS_Visit_data  ( p_runid  ) ;Commented out for this release

     --EXTRACT_ICD10_ICD9_DX_HPDS ( p_runid )   ; Commented out for this release

     EXTRCT_HPDS_ICD10 ( p_runid  ) ;

     EXTRCT_HPDS_CPT_PX_2018AA ( p_runid   ) ;

     EXTRCT_HPDS_LAB_Results ( p_runid ) ;

    --EXTRACT_COVID_DATA_HPDS ( p_runid  ) ; Commented out for this release

    EXTRCT_HPDS_MED_ALPHA( p_runid  ) ; 

    --EXTRCT_HPDS_MED_VA( p_runid  ) ; 
    --Added new for subcounts 
    
    EXTRCT_HPDS_CSF         ( p_runid );
    EXTRCT_HPDS_EXOMES_IDS  (  p_runid ); 
    EXTRCT_HPDS_HUMANTISSUE ( p_runid );
    EXTRCT_HPDS_NUCLEICACID ( p_runid );
    EXTRCT_HPDS_PLASMA      ( p_runid );
    EXTRCT_HPDS_WHOLE_BLOOD ( p_runid );

     log_msg(p_runid,'Run_EXTRCT_HPDS_Data End  ','X'); 

END;

PROCEDURE Run_MAP_Data_Load (p_runid  IN NUMBER ) AS

BEGIN
log_msg(p_runid,'Start Run_MAP_Data_Load   ','X');   
         execute immediate 'Truncate table act_bch_ontology_map '; 
         MAP_DATA_LOAD_NCATS_LABS_HPDS ( p_runid   ); 

         MAP_DATA_LOAD_ACT_ICD10CM_HPDS ( p_runid );

        -- MAP_DATA_LOAD_ICD10_ICD9_HPDS( p_runid );

         MAP_DATA_LOAD_ACT_CPT_PX_HPDS ( p_runid ) ;

         MAP_DATA_LOAD_VISIT_HPDS ( p_runid);

         MAP_DATA_LOAD_DEMOGRAPHCS_HPDS ( p_runid ) ;

         MAP_DATA_LOAD_COVID_HPDS ( p_runid   ) ;

         MAP_DATA_LOAD_MED_ALPHA_HPDS ( p_runid );
         
         MAP_BLOOD_GIC_BIOSAMPLES_HPDS ( p_runid );
    
         MAP_CSF_GIC_BIOSAMPLES_HPDS ( p_runid );
    
         MAP_GNOME_GIC_BIOSAMPLES_HPDS ( p_runid );
    
         MAP_PLASMA_GIC_BIOSAMPLES_HPDS ( p_runid );
    
         MAP_TISSUE_GIC_BIOSAMPLES_HPDS ( p_runid );
         MAP_DNA_GIC_BIOSAMPLES_HPDS  ( p_runid );
         
  

log_msg(p_runid,'End Run_MAP_Data_Load   ','X');   
END;

PROCEDURE           EXTRCT_HPDS_CSF (
    p_runid        IN NUMBER
) AS

Begin

 log_msg(p_runid,'EXTRCT_HPDS_CSF Start  ','X'); 

       INSERT into HPDS_DATA_LATEST( PATIENT_NUM,CONCEPT_PATH,NVAL_NUM,TVAL_CHAR,start_date)      
       SELECT DISTINCT fact1.patient_num,  act_concept_path, nval_num, null act_name_char,cast( start_date as date) start_date
       FROM observation_fact fact1 JOIN PATIENT_DIMENSION pd ON fact1.patient_num = pd.patient_num
       JOIN act_bch_ontology_map cd
       ON cd.bch_concept_cd=fact1.CONCEPT_CD WHERE cd.data_type =  'CSF'
       AND   NVAL_NUM is not null ;

 log_msg(p_runid,'EXTRCT_HPDS_CSF End  '||sql%rowcount,'X'); 
  commit;
end;

PROCEDURE           EXTRCT_HPDS_EXOMES_IDS (
    p_runid        IN NUMBER
) AS

Begin

 log_msg(p_runid,'EXTRCT_HPDS_EXOMES_IDS Start  ','X'); 
       INSERT into HPDS_DATA_LATEST( PATIENT_NUM,CONCEPT_PATH,NVAL_NUM,TVAL_CHAR,start_date)      
       SELECT DISTINCT fact1.patient_num,  act_concept_path, nval_num, 'True' act_name_char,cast( start_date as date) start_date
       FROM observation_fact fact1 JOIN PATIENT_DIMENSION pd ON fact1.patient_num = pd.patient_num
       JOIN act_bch_ontology_map cd
       ON cd.bch_concept_cd=fact1.CONCEPT_CD WHERE cd.data_type =  'Gnome';

 log_msg(p_runid,'EXTRCT_HPDS_EXOMES_IDS End  '||sql%rowcount,'X'); 
  commit;
end;


PROCEDURE           EXTRCT_HPDS_HUMANTISSUE (
    p_runid        IN NUMBER
) AS

Begin

 log_msg(p_runid,'EXTRCT_HPDS_HUMANTISSUE Start  ','X'); 

        --\Bio Specimens\HumanTissue\   True
       INSERT into HPDS_DATA_LATEST( PATIENT_NUM,CONCEPT_PATH,NVAL_NUM,TVAL_CHAR,start_date)      
       SELECT DISTINCT fact1.patient_num,  act_concept_path, nval_num, null act_name_char,cast( start_date as date) start_date
       FROM observation_fact fact1 JOIN PATIENT_DIMENSION pd ON fact1.patient_num = pd.patient_num
       JOIN act_bch_ontology_map cd
       ON cd.bch_concept_cd=fact1.CONCEPT_CD WHERE cd.data_type =  'HumanTissue'
       AND   NVAL_NUM is not null ;

        --BIOSPECIMEN:HT.TS.000 Available

 log_msg(p_runid,'EXTRCT_HPDS_HUMANTISSUE End  '||sql%rowcount,'X'); 
  commit;
end;


PROCEDURE           EXTRCT_HPDS_NUCLEICACID (
    p_runid        IN NUMBER
) AS

Begin

 log_msg(p_runid,'EXTRCT_HPDS_NUCLEICACID Start  ','X'); 

       INSERT into HPDS_DATA_LATEST( PATIENT_NUM,CONCEPT_PATH,NVAL_NUM,TVAL_CHAR,start_date)      
       SELECT DISTINCT fact1.patient_num,  act_concept_path, nval_num, 'True' act_name_char,cast( start_date as date) start_date
       FROM observation_fact fact1 JOIN PATIENT_DIMENSION pd ON fact1.patient_num = pd.patient_num
       JOIN act_bch_ontology_map cd
       ON cd.bch_concept_cd=fact1.CONCEPT_CD WHERE cd.data_type =  'NucleicAcid'
       AND   NVAL_NUM is not null ;

 log_msg(p_runid,'EXTRCT_HPDS_NUCLEICACID End  '||sql%rowcount,'X'); 
  commit;
end;


PROCEDURE           EXTRCT_HPDS_PLASMA (
    p_runid        IN NUMBER
) AS

Begin

 log_msg(p_runid,'EXTRCT_HPDS_PLASMA Start  ','X'); 

       INSERT into HPDS_DATA_LATEST( PATIENT_NUM,CONCEPT_PATH,NVAL_NUM,TVAL_CHAR,start_date)      
       SELECT DISTINCT fact1.patient_num,  act_concept_path, nval_num, null act_name_char,cast( start_date as date) start_date
       FROM observation_fact fact1 JOIN PATIENT_DIMENSION pd ON fact1.patient_num = pd.patient_num
       JOIN act_bch_ontology_map cd
       ON cd.bch_concept_cd=fact1.CONCEPT_CD WHERE cd.data_type =  'Plasma'
       AND   NVAL_NUM is not null ;

 log_msg(p_runid,'EXTRCT_HPDS_PLASMA End  '||sql%rowcount,'X'); 
  commit;
end;


PROCEDURE       EXTRCT_HPDS_WHOLE_BLOOD (
    p_runid        IN NUMBER
) AS

Begin

log_msg(p_runid,'EXTRCT_HPDS_WHOLE_BLOOD Start  ','X'); 

        
       INSERT into HPDS_DATA_LATEST( PATIENT_NUM,CONCEPT_PATH,NVAL_NUM,TVAL_CHAR,start_date)      
       SELECT DISTINCT fact1.patient_num,  act_concept_path, nval_num, null act_name_char,cast( start_date as date) start_date
       FROM observation_fact fact1 JOIN PATIENT_DIMENSION pd ON fact1.patient_num = pd.patient_num
       JOIN act_bch_ontology_map cd
       ON cd.bch_concept_cd=fact1.CONCEPT_CD WHERE cd.data_type =  'Blood'
       AND   NVAL_NUM is not null ;

log_msg(p_runid,'EXTRCT_HPDS_WHOLE_BLOOD End  '||sql%rowcount,'X'); 
commit;
end;

END TM_DATA_ACT_LOAD_PKG;


/

