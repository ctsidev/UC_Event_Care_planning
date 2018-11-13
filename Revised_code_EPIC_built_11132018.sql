exec P_ACP_CREATE_DENOMINATOR('xdr_acp_cohort');
exec P_ACP_REMOVE_DECEASED('xdr_acp_cohort');
exec P_ACP_REMOVE_RESTRICTED('xdr_acp_cohort');
exec P_ACP_PL_DX('xdr_acp_cohort','CANCER');
exec P_ACP_PL_DX('xdr_acp_cohort','CHF');
exec P_ACP_PL_DX('xdr_acp_cohort','ALS');
exec P_ACP_PL_DX('xdr_acp_cohort','COPD');
exec P_ACP_PL_DX('xdr_acp_cohort','COPD_SPO2');
exec P_ACP_PL_DX('xdr_acp_cohort','CIRRHOSIS');
exec P_ACP_PL_DX('xdr_acp_cohort','ESRD');
exec P_ACP_PL_DX('xdr_acp_cohort','PERITONITIS');
exec P_ACP_PL_DX('xdr_acp_cohort','HEPATORENAL');
exec P_ACP_PL_DX('xdr_acp_cohort','BLEEDING');
exec P_ACP_PL_DX('xdr_acp_cohort','ASCITES');
exec P_ACP_PL_DX('xdr_acp_cohort','ENCEPHALOPATHY');
exec P_ACP_ESDL_DECOMPENSATION('xdr_acp_cohort');



create or replace procedure p_acp_create_denominator(p_table_name in varchar2) as
 q1 varchar2(4000);
begin

 q1 := 'INSERT INTO ' || p_table_name  || '(PAT_ID,CREATION_DATE)  
        SELECT DISTINCT x.pat_id
            ,SYSDATE AS CREATION_DATE
        FROM (SELECT enc.pat_id
            ,count(enc.pat_enc_csn_id) AS pat_enc_count
        FROM clarity.pat_enc                        enc
        JOIN clarity.patient                        pat   ON enc.pat_id = pat.pat_id
        LEFT JOIN ctsi_research.' || p_table_name || '  coh   ON pat.pat_id = coh.pat_id and coh.pat_id IS NULL
        JOIN clarity.clarity_ser                    prov2 ON pat.cur_pcp_prov_id = prov2.PROV_ID  
                                                    AND prov2.user_id IS NOT NULL
        JOIN jsanz.js_xdr_walling_IMFP_dept_drv      dd on enc.department_id = dd.department_id
        WHERE 

                enc.effective_date_dt between sysdate - 366 and sysdate 
                and floor(months_between(TRUNC(sysdate), pat.birth_date)/12) >= 18
                and enc.enc_type_c = 101
                and (enc.appt_status_c is not null and enc.appt_status_c not in (3,4,5))
                GROUP BY enc.PAT_ID)x
        WHERE x.pat_enc_count > 1';
 EXECUTE IMMEDIATE q1;
end;



create or replace procedure p_acp_remove_deceased(p_table_name in varchar2) as
 q1 varchar2(4000);
begin

 q1 := 'DELETE FROM ' || p_table_name  ||
        ' WHERE pat_id IN 
            (SELECT DISTINCT coh.PAT_ID 
            FROM ' || p_table_name  || '     coh 
            JOIN patient            pat on coh.pat_id = pat.pat_id 
            WHERE 
                i2b2.f_death(pat.pat_id,2,1)  = ''Known Deceased'')';
 EXECUTE IMMEDIATE q1;
end;



create or replace procedure p_acp_remove_restricted(p_table_name in varchar2) as
 q1 varchar2(4000);
begin

 q1 := 'DELETE FROM ' || p_table_name  ||
        ' WHERE pat_id IN 
            (
                SELECT DISTINCT coh.pat_id  
                FROM xdr_ACP_COHORT                   coh 
                LEFT JOIN patient_fyi_flags           flags ON coh.pat_id = flags.patient_id 
                LEFT JOIN patient_3                         ON coh.pat_id = patient_3.pat_id 
                WHERE 
                            (patient_3.is_test_pat_yn = ''Y'' 
                            OR flags.PAT_FLAG_TYPE_C in (6,8,9,1018,1053))
            )';
 EXECUTE IMMEDIATE q1;
end;



create or replace procedure P_ACP_PL_DX(p_table_name in varchar2, p_dx_flag in varchar2) as
 q1 varchar2(4000);
begin

 q1 := '
  UPDATE ' || p_table_name  || 
  ' SET PL_' || p_dx_flag || ' = 1
  WHERE 
    PAT_ID IN (
                SELECT DISTINCT coh.pat_id
                FROM ' || p_table_name  || '          coh 
                JOIN problem_list                     pl    ON coh.pat_id = pl.pat_id AND pl.rec_archived_yn = ''N'' 
                JOIN zc_problem_status                zps   ON pl.problem_status_c = zps.problem_status_c 
                JOIN JSANZ.js_xdr_WALLING_DX_LOOKUP   drv   ON pl.dx_id = drv.dx_id AND drv.dx_flag = ''' || p_dx_flag || '''
  where  
        zps.name = ''Active'')';
 EXECUTE IMMEDIATE q1;
end;


create or replace procedure P_ACP_ESDL_DECOMPENSATION(p_table_name in varchar2) as
 q1 varchar2(4000);
begin

 q1 := '
  UPDATE ' || p_table_name  || 
  ' SET pl_ESDL_decompensation = 1 
  WHERE  
        PL_PERITONITIS = 1 
        OR PL_ASCITES = 1 
        OR PL_BLEEDING = 1 
        OR PL_ENCEPHALOPATHY = 1 
        OR PL_HEPATORENAL = 1 
        OR PL_PERITONITIS = 1';
 EXECUTE IMMEDIATE q1;
end;