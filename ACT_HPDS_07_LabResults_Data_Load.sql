 set serveroutput on
 begin
 
 for r_data in (  select  distinct patient_num from tm_cz.delta_patient_dim order by patient_num  ) loop 

insert into tm_cz.HPDS_DATA_LATEST ( PATIENT_NUM,CONCEPT_PATH,NVAL_NUM,TVAL_CHAR,start_date)
       SELECT DISTINCT
            fact1.patient_num,
            c_fullname concept_path,
            nval_num,
            tval_char,
            start_date
        FROM
            (
                SELECT
                    *
                FROM
                    tm_cz.delta_obs_fact
                WHERE
                    concept_cd LIKE 'LAB:%'
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
                        '++++'
                    )
            ) fact1,
            tm_cz.A_LAB_DATA_ACT_BCH_MAP_PATH1 m
        WHERE
            fact1.concept_cd = m.bch_lab_code            
            AND patient_num = r_data.patient_num;
            
       DBMS_OUTPUT.put_line( sql%rowcount);

        commit;
 end loop;
 
 end;