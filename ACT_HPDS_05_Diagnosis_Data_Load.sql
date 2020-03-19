--script for loading Diagnosis ACT fact data in HPDS.
--New mapping table tm_cz.a_NCATS_ICD10_ICD9_DX_V1_map is created to convert BCH diagnosis to ACT Diagnosis concept_paths
--It can be loaded from the csv file data_A_NCATS_ICD10_ICD9_DX_V1_MAP.tar.gz
--HPDS Diagnosis data is loaded in ACT format.


set serveroutput on
begin
insert into tm_cz.HPDS_DATA_LATEST( PATIENT_NUM,CONCEPT_PATH,NVAL_NUM,TVAL_CHAR)
select distinct patient_num,act_concept_path ,null,act_name_char
from i2b2demodata.observation_fact   fact1, tm_cz.a_NCATS_ICD10_ICD9_DX_V1_map cd
where cd.bch_concept_cd = fact1.CONCEPT_CD;

dbms_output.put_line( 'Inserted Rows '||sql%rowcount);
commit;
end;




