
  CREATE OR REPLACE  PACKAGE TM_DATA_ACT_LOAD_PKG AS
/*
Create By      - Jaspreet Khanna 
Created        - May 2020
Modified       - May 2022 
Prerequisites  - Standard i2b2 schema.
               - Procedure PRC_CRT_TABLES_ACT_HPDS_LOAD has to be run to create objects needed.
               - ACT ontology data tables have to be loaded with the data from the Git in listed tables .
               - NCATS_LABS_HPDS,ACT_ICD10CM_DX_2018AA_HPDS,ACT_CPT_PX_2018AA_HPDS,NCATS_DEMOGRAPHICS_HPDS,ACT_MED_ALPHA_HPDS,GIC_BIOSAMPLES_HPDS
               - a_lab_cd_act_bch_map - should be populated with source system lab_cd to Loinc_cd 
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
               - MED_ALPHA_HPDS
               - If the above data is not populated, it might need code change based on how data is populated in sourcesystem.
               - Call to proc Run_EXTRCT_HPDS_Data will populate 
               - table HPDS_DATA_LATEST with HPDS extract in ACT format. 
               - Removed code for Visit, ICD10-ICD9, COVID data load
               - Added new code for Variant virtual batches.
               - Modified logic for CSF and Human tissue data load.
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

PROCEDURE MAP_DATA_LOAD_DEMOGRAPHCS_HPDS (
    p_runid        IN NUMBER )  ;  
  
PROCEDURE MAP_DATA_LOAD_MED_ALPHA_HPDS (
    p_runid        IN NUMBER )  ;  
PROCEDURE MAP_BLOOD_GIC_BIOSAMPLES_HPDS (
    p_runid        IN NUMBER )  ;

 PROCEDURE MAP_CSF_GIC_BIOSAMPLES_HPDS (
    p_runid        IN NUMBER )  ;

 PROCEDURE MAP_VARIANT_BIOSAMPLES_HPDS (
    p_runid        IN NUMBER )  ;

  PROCEDURE MAP_PLASMA_GIC_BIOSAMPLES_HPDS (
    p_runid        IN NUMBER )  ;

 PROCEDURE MAP_TISSUE_GIC_BIOSAMPLES_HPDS (
    p_runid        IN NUMBER )  ;         

PROCEDURE MAP_DNA_GIC_BIOSAMPLES_HPDS (
    p_runid     IN NUMBER )  ;

PROCEDURE EXTRCT_HPDS_Demographics (
    p_runid        IN NUMBER ) ;

PROCEDURE EXTRCT_HPDS_ICD10 (
    p_runid        IN NUMBER
) ;    

PROCEDURE EXTRCT_HPDS_CPT_PX_2018AA (
    p_runid        IN NUMBER
) ;    

PROCEDURE EXTRCT_HPDS_LAB_Results (
    p_runid        IN NUMBER) ;

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
                    WHERE concept_path LIKE '\Bio Specimens\NucleicAcid%DNA%') na ,
                    (SELECT c_fullname, c_name, c_basecode, hpds_path
                    FROM GIC_BIOSAMPLES_HPDS
                    WHERE c_fullname like '\Bio Specimens\NucleicAcid\DNA\') hpds ; 

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

 PROCEDURE MAP_VARIANT_BIOSAMPLES_HPDS (
    p_runid        IN NUMBER )  
    AS
  BEGIN
  log_msg(p_runid, 'Start MAP_VARIANT_BIOSAMPLES_HPDS '||sql%rowcount, 'Y'); 
        DELETE FROM act_bch_ontology_map
        WHERE data_type = 'Variant';
        log_msg(p_runid, 'Delete existing data MAP_VARIANT_BIOSAMPLES_HPDS '||sql%rowcount, 'Y'); 
                INSERT INTO act_bch_ontology_map (  data_type,
                    act_concept_path,
                    act_name_char,
                    act_concept_cd,
                    bch_concept_path,
                    bch_name_char,
                    bch_concept_cd
                  )
               SELECT  'Variant' data_type,
                  hpds.hpds_path,
                  hpds.c_name,
                  hpds.c_basecode,
                  na.concept_path,
                  na.name_char,
                  na.concept_cd 
               FROM   (SELECT * from concept_dimension
                       WHERE concept_cd like 'BATCH%' and concept_path like '\WES\%' ) na ,
                    (SELECT c_fullname, c_name, c_basecode, hpds_path
                    FROM gic_biosamples_hpds
                    WHERE c_fullname like '\Variant Data Type\WES%' ) hpds ;

        log_msg(p_runid, 'End MAP_VARIANT_BIOSAMPLES_HPDS WES '||sql%rowcount, 'Y');  
               INSERT INTO act_bch_ontology_map (  data_type,
                    act_concept_path,
                    act_name_char,
                    act_concept_cd,
                    bch_concept_path,
                    bch_name_char,
                    bch_concept_cd
                  )
               SELECT  'Variant' data_type,
                  hpds.hpds_path,
                  hpds.c_name,
                  hpds.c_basecode,
                  na.concept_path,
                  na.name_char,
                  na.concept_cd 
               FROM   (SELECT * from concept_dimension
                       WHERE concept_cd like 'BATCH%' and concept_path like '\WGS\%' ) na ,
                    (SELECT c_fullname, c_name, c_basecode, hpds_path
                    FROM gic_biosamples_hpds
                    WHERE c_fullname like '\Variant Data Type\WGS%' ) hpds ;
        log_msg(p_runid, 'End MAP_VARIANT_BIOSAMPLES_HPDS WGS '||sql%rowcount, 'Y');          
            INSERT INTO act_bch_ontology_map (  data_type,
                    act_concept_path,
                    act_name_char,
                    act_concept_cd,
                    bch_concept_path,
                    bch_name_char,
                    bch_concept_cd
                  )
               SELECT  'Variant' data_type,
                  hpds.hpds_path,
                  hpds.c_name,
                  hpds.c_basecode,
                  na.concept_path,
                  na.name_char,
                  na.concept_cd 
               FROM   (SELECT * from concept_dimension
                       WHERE concept_cd like 'BATCH%' and concept_path like '\Genotype Array%' ) na ,
                    (SELECT c_fullname, c_name, c_basecode, hpds_path
                    FROM gic_biosamples_hpds
                    WHERE c_fullname like '\Variant Data Type\Genotype%' ) hpds ;      

        log_msg(p_runid, 'End MAP_VARIANT_BIOSAMPLES_HPDS Genotype '||sql%rowcount, 'Y'); 
        COMMIT;
               log_msg(p_runid, 'End MAP_VARIANT_BIOSAMPLES_HPDS Genotype ', 'Y'); 
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
            from patient_dimension  pd, ( select * from NCATS_DEMOGRAPHICS_HPDS where hpds_path like '\ACT Demographics\Sex\%' ) mp
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

PROCEDURE EXTRCT_HPDS_MED_ALPHA (
    p_runid        IN NUMBER
) AS

Begin

  delete from HPDS_DATA_LATEST where concept_path like '\ACT Medications\%';
  commit;
  log_msg(p_runid,'EXTRCT_HPDS_MED_ALPHA Start  ','X'); 

  for r_data in ( select distinct BCH_CONCEPT_CD from act_bch_ontology_map m where data_type =   'MED_ALPHA_HPDS'  order by bch_concept_cd  ) loop

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

     EXTRCT_HPDS_ICD10 ( p_runid  ) ;

     EXTRCT_HPDS_CPT_PX_2018AA ( p_runid   ) ;

     EXTRCT_HPDS_LAB_Results ( p_runid ) ;

     EXTRCT_HPDS_MED_ALPHA( p_runid  ) ; 

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

         MAP_DATA_LOAD_ACT_CPT_PX_HPDS ( p_runid ) ;

         MAP_DATA_LOAD_DEMOGRAPHCS_HPDS ( p_runid ) ;

         MAP_DATA_LOAD_MED_ALPHA_HPDS ( p_runid );

         MAP_BLOOD_GIC_BIOSAMPLES_HPDS ( p_runid );

         MAP_CSF_GIC_BIOSAMPLES_HPDS ( p_runid );

         MAP_VARIANT_BIOSAMPLES_HPDS ( p_runid );

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
       SELECT DISTINCT fact1.patient_num,  act_concept_path, null nval_num, 'True' act_name_char,cast( start_date as date) start_date
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
       SELECT DISTINCT fact1.patient_num,  act_concept_path, null nval_num, 'True' act_name_char,cast( start_date as date) start_date
       FROM observation_fact fact1 JOIN PATIENT_DIMENSION pd ON fact1.patient_num = pd.patient_num
       JOIN act_bch_ontology_map cd
       ON cd.bch_concept_cd=fact1.CONCEPT_CD WHERE cd.data_type =  'Variant';

 log_msg(p_runid,'EXTRCT_HPDS_EXOMES_IDS End  '||sql%rowcount,'X'); 
  commit;

end;


PROCEDURE           EXTRCT_HPDS_HUMANTISSUE (
    p_runid        IN NUMBER
) AS

Begin

 log_msg(p_runid,'EXTRCT_HPDS_HUMANTISSUE Start  ','X'); 

       INSERT into HPDS_DATA_LATEST( PATIENT_NUM,CONCEPT_PATH,NVAL_NUM,TVAL_CHAR,start_date)      
       SELECT DISTINCT fact1.patient_num,  act_concept_path, null nval_num, 'True' act_name_char,cast( start_date as date) start_date
       FROM observation_fact fact1 JOIN PATIENT_DIMENSION pd ON fact1.patient_num = pd.patient_num
       JOIN act_bch_ontology_map cd
       ON cd.bch_concept_cd=fact1.CONCEPT_CD WHERE cd.data_type =  'HumanTissue'
       AND   NVAL_NUM is not null ;

 log_msg(p_runid,'EXTRCT_HPDS_HUMANTISSUE End  '||sql%rowcount,'X'); 
  commit;
end;


PROCEDURE           EXTRCT_HPDS_NUCLEICACID (
    p_runid        IN NUMBER
) AS

Begin

 log_msg(p_runid,'EXTRCT_HPDS_NUCLEICACID Start  ','X'); 

       INSERT into HPDS_DATA_LATEST( PATIENT_NUM,CONCEPT_PATH,NVAL_NUM,TVAL_CHAR,start_date)      
       SELECT DISTINCT fact1.patient_num,  act_concept_path, null nval_num, 'True' act_name_char,cast( start_date as date) start_date
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