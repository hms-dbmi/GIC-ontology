--Combined script for Visit ACT fact data for HPDS.
-- Combined_Script_ACT_DATA_02.sql has to be deployed before running this script to create


create table TM_CZ.A_NCATS_VISIT_DETAILS_MAP (  bch_visit_type varchar2(500) ,act_visit_type  varchar2(500)   );

--Mapping table visit type
insert into TM_CZ.A_NCATS_VISIT_DETAILS_MAP( bch_visit_type,act_visit_type    ) values ('Day Surgery','Other Ambulatory Visit');
insert into TM_CZ.A_NCATS_VISIT_DETAILS_MAP( bch_visit_type,act_visit_type    ) values ('Donor Recurring','Other Ambulatory Visit');
insert into TM_CZ.A_NCATS_VISIT_DETAILS_MAP( bch_visit_type,act_visit_type    ) values ('Emergency','Emergency Department Visit');
insert into TM_CZ.A_NCATS_VISIT_DETAILS_MAP( bch_visit_type,act_visit_type    ) values ('Inpatient','Inpatient Hospital Stay');
insert into TM_CZ.A_NCATS_VISIT_DETAILS_MAP( bch_visit_type,act_visit_type    ) values ('NULL care class code','No Information');
insert into TM_CZ.A_NCATS_VISIT_DETAILS_MAP( bch_visit_type,act_visit_type    ) values ('Observation','Other Ambulatory Visit');
insert into TM_CZ.A_NCATS_VISIT_DETAILS_MAP( bch_visit_type,act_visit_type    ) values ('Outpatient','Ambulatory Visit');
insert into TM_CZ.A_NCATS_VISIT_DETAILS_MAP( bch_visit_type,act_visit_type    ) values ('Recurring Outpatient Series','Ambulatory Visit');
insert into TM_CZ.A_NCATS_VISIT_DETAILS_MAP( bch_visit_type,act_visit_type    ) values ('T-CBAT','Other Ambulatory Visit');
insert into TM_CZ.A_NCATS_VISIT_DETAILS_MAP( bch_visit_type,act_visit_type    ) values ('X-Ambulatory Day Program','Other Ambulatory Visit');
insert into TM_CZ.A_NCATS_VISIT_DETAILS_MAP( bch_visit_type,act_visit_type    ) values ('Research Inpatient ','Inpatient Hospital Stay');
commit;

--Extract vist data

create table tm_cz.VISIT_FACT_DETAILS as
select distinct vd.patient_num,inout_cd,length_of_stay,
trunc( (start_date - cast(birth_date as date))/365 ) age_at_visit_yrs
from  i2b2demodata.visit_dimension vd, 
i2b2demodata.patient_dimension pd
where vd.patient_num = pd.patient_num 
 and trunc(start_date - cast(birth_date as date) ) >= 0;

--Visit Age

insert into TM_CZ.HPDS_DATA_LATEST ( patient_num,concept_path,nval_num,tval_char  )
select  patient_num,'\VisitInformation\Years\Age' concept_path,age_at_visit_yrs,'E'
from tm_cz.VISIT_FACT_DETAILS 
where age_at_visit_yrs >= 0 ;

--Visit type
insert into TM_CZ.HPDS_DATA_LATEST ( patient_num,concept_path,tval_char  )
SELECT DISTINCT
    b.patient_num,
    '\Visit Details\Visit type\' ,
    a.c_name visit_type
FROM
    (
        SELECT
           distinct v.inout_cd , v.patient_num,M.ACT_VISIT_TYPE
        FROM
            tm_cz.VISIT_FACT_DETAILS V, tm_cz.a_ncats_visit_details_map M
            WHERE v.inout_cd = M.BCH_VISIT_TYPE
    ) b,
    (
        SELECT
            *
        FROM
            tm_cz.a_ncats_visit_details
        WHERE
            c_fullname like '\ACT\Visit Details\Visit type\%'
    ) a
    where a.c_name = b.act_visit_type;
    


----Load lengthofstay
insert into TM_CZ.HPDS_DATA_LATEST ( patient_num,concept_path,tval_char  )
SELECT DISTINCT
    b.patient_num,
    '\Visit Details\Length of stay\',
    a.c_name lengthofstay
FROM
    (
        SELECT
            length_of_stay,
            patient_num
        FROM
            tm_cz.VISIT_FACT_DETAILS
        WHERE
            length_of_stay <= 10
    ) b,
    (
        SELECT
            *
        FROM
            tm_cz.a_ncats_visit_details
        WHERE
            c_visualattributes LIKE 'L%'
            AND c_fullname like '\ACT\Visit Details\Length of stay\%'
    ) a
where a.c_basecode = b.length_of_stay
union all
SELECT DISTINCT
    b.patient_num,
    '\Visit Details\Length of stay\',
    a.c_name lengthofstay
FROM
    (
        SELECT
            length_of_stay,
            patient_num
        FROM
            tm_cz.VISIT_FACT_DETAILS
        WHERE
            length_of_stay > 10
    ) b,
    (
        SELECT
            *
        FROM
            tm_cz.a_ncats_visit_details
        WHERE
            c_visualattributes LIKE 'L%'
            AND c_fullname = '\ACT\Visit Details\Length of stay\ > 10 days\'
    ) a ; 

commit;

