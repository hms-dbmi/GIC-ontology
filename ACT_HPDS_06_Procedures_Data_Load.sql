--Script for loading Procedures ACT fact data in HPDS.
--Mapping table tm_cz.a_ACT_ICD10PCS_PX_2018AA_map has mapping for BCH Procedures to ACT Procedures concept_paths
--It can be loaded from the csv file data_a_ACT_ICD10PCS_PX_2018AA_map.tar.gz
--HPDS Diagnosis data is loaded in ACT format.



insert into tm_cz.HPDS_DATA_LATEST( PATIENT_NUM,CONCEPT_PATH,NVAL_NUM,TVAL_CHAR,start_date)
select  distinct fact1.patient_num, replace(cd.act_concept_path,'\ACT','') ,null,cd.act_name_char c_name ,start_date
from i2b2demodata.observation_fact fact1, tm_cz.a_ACT_ICD10PCS_PX_2018AA_map cd
where cd.bch_concept_cd = fact1.CONCEPT_CD;

commit;


