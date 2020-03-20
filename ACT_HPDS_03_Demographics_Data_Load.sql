--Combined script for demographics ACT fact data for HPDS.

-- Combined_Script_ACT_DATA_01.sql has to be deployed before running this script 


-- 1. Converts age fact data into ACT fact data for HPDS.


insert into  TM_CZ.HPDS_DATA_LATEST
SELECT patient_num, '\Demographics\Years\Age\' concept_path ,trunc((sysdate - (cast(birth_date as date )) )/365)  years ,'E'
from i2b2demodata.patient_dimension
where  trunc((sysdate - (cast(birth_date as date )) )/365) >= 0;

commit;

--2 Converts sex fact data into ACT fact data for HPDS.

insert into TM_CZ.HPDS_DATA_LATEST
select patient_num ,'\Demographics\Sex\',null,decode(sex_cd,'Unknown','No Information',sex_cd) from i2b2demodata.patient_dimension;

commit;


--3 Converts hispanic fact data into ACT fact data for HPDS.

create table TM_CZ.FACT_HISP_BCH_ACT   as
select distinct patient_num, '\Demographics\Hispanic\' act_concept_path ,'Yes' act_name_char
from i2b2demodata.observation_fact  
where concept_cd in
(select concept_cd
from  i2b2demodata.concept_dimension cd
where concept_cd like 'DEM|ETHNICITY:%' 
and name_char in 
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
'Caribbean Islander') )
union all
--Non hispanic
select distinct patient_num, '\Demographics\Hispanic\' concept_path ,'No' name_char
from i2b2demodata.observation_fact   
where concept_cd in
(select concept_cd
from i2b2demodata.concept_dimension cd
where concept_cd like 'DEM|ETHNICITY:%' 
and name_char not in 
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
) )
union all
--No information
select distinct patient_num, '\Demographics\Hispanic\' act_concept_path ,'No Information' act_name_char
from i2b2demodata.observation_fact   
where concept_cd in
(select concept_cd
from i2b2demodata.concept_dimension cd
where concept_cd like 'DEM|ETHNICITY:%' 
and name_char = 'NOT DEFINED IN SOURCE') ;

insert into TM_CZ.HPDS_DATA_LATEST
select  distinct a.patient_num,a.act_concept_path ,null,a.act_name_char
from TM_CZ.FACT_HISP_BCH_ACT a ;

commit;

--4 Converts Race fact data into ACT fact data for HPDS.

insert into TM_CZ.HPDS_DATA_LATEST
SELECT 
patient_num,
'\Demographics\Race\' act_concept_path,
null,
nvl(a.c_name , 'No Information') act_name_char
FROM
    ( select  c_name from tm_cz.a_ncats_demographics  where c_fullname LIKE '\ACT\Demographics\Race%' ) a,
   ( select distinct patient_num,f1.concept_cd,cd.name_char  from i2b2demodata.observation_fact f1, i2b2demodata.concept_dimension cd
WHERE   cd.concept_cd LIKE 'DEM|RACE:%'
and f1.concept_cd = cd.concept_cd ) fact1
    where fact1.name_char = a.c_name (+);

commit;
--5 Converts Vital status  data into ACT fact data for HPDS.
insert into TM_CZ.HPDS_DATA_LATEST
select patient_num,'\Demographics\Vital Status\',null,'Known Deceased'
from tm_cz.delta_patient_dim 
where death_date is not null;

commit;
