
  CREATE TABLE "XDR_ACP_COHORT" 
   (	"PAT_ID" VARCHAR2(18 BYTE), 
	"PL_CANCER" NUMBER, 
	"PL_ESLD" NUMBER, 
	"PL_COPD" NUMBER, 
	"PL_COPD_SPO2" NUMBER, 
	"PL_CHF" NUMBER, 
	"PL_ESRD" NUMBER, 
	"PL_ALS" NUMBER, 
	"PL_CIRRHOSIS" NUMBER, 
	"CREATION_DATE" TIMESTAMP (6), 
	"PL_COPD_SP02" NUMBER, 
	"PL_PERITONITIS" NUMBER, 
	"PL_HEPATORENAL" NUMBER, 
	"PL_BLEEDING" NUMBER, 
	"PL_ASCITES" NUMBER, 
	"PL_ENCEPHALOPATHY" NUMBER, 
	"PL_ESDL_DECOMPENSATION" NUMBER, 
	"DX_ALS" NUMBER, 
	"DX_CANCER" NUMBER, 
	"DX_CHF" NUMBER, 
	"DX_ESRD" NUMBER, 
	"DX_CIRRHOSIS" NUMBER, 
	"NEPH_VISIT" NUMBER, 
	"ONC_VISIT" NUMBER, 
	"COPD_ADMIT" NUMBER, 
	"CHF_ADMIT" NUMBER, 
    "MELD" NUMBER, 
    "EF" NUMBER, 
    "AD_POLST_THREE" NUMBER, 
    "AD_POLST_ALL" NUMBER,   
    "CANCER" NUMBER, 
	"ESLD" NUMBER, 
	"COPD" NUMBER, 
	"CHF" NUMBER, 
	"ESRD" NUMBER, 
	"ALS" NUMBER, 
    "AGE" NUMBER
   )

-- Create denominator
exec P_ACP_CREATE_DENOMINATOR('xdr_acp_cohort');
--remove excluded patients
exec P_ACP_REMOVE_DECEASED('xdr_acp_cohort');
exec P_ACP_REMOVE_RESTRICTED('xdr_acp_cohort');
--apply problem list dx criterion
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
--apply encounter dx criterion (3 years)
exec P_ACP_ENC_DX('xdr_acp_cohort','CANCER');
exec P_ACP_ENC_DX('xdr_acp_cohort','CHF');
exec P_ACP_ENC_DX('xdr_acp_cohort','ALS');
exec P_ACP_ENC_DX('xdr_acp_cohort','CIRRHOSIS');
exec P_ACP_ENC_DX('xdr_acp_cohort','ESRD');
--apply visit to departments criterion (oncology and nephrology)
exec P_ACP_DEPT_VISIT('xdr_acp_cohort','ONC',1,'CANCER');
exec P_ACP_DEPT_VISIT('xdr_acp_cohort','NEPH',1,'ESRD');
--apply admision for certain conditions (CHF AND COPD)
exec P_ACP_DEPT_ADMIT('xdr_acp_cohort',1,'CHF');
exec P_ACP_DEPT_ADMIT('xdr_acp_cohort',1,'COPD');




-- Create denominator
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


--remove excluded patients (DECEASED)
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

--remove excluded patients (RESTRICTED)
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


--apply problem list dx criterion
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

--apply problem list dx criteria for ESDL decompensation combination
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

--apply encounter dx criterion (3 years)
create or replace procedure P_ACP_ENC_DX(p_table_name in varchar2, p_dx_flag in varchar2) as
 q1 varchar2(4000);
begin

 q1 := 'UPDATE ' || p_table_name  || ' 
  SET DX_' || p_dx_flag || ' = 1 
  WHERE 
    PAT_ID IN ( 
                SELECT DISTINCT coh.pat_id 
                FROM ' || p_table_name  || '          coh 
                JOIN pat_enc_dx                     dx on coh.pat_id = dx.pat_id 
                JOIN JSANZ.js_xdr_WALLING_DX_LOOKUP   drv   ON dx.dx_id = drv.dx_id AND drv.dx_flag = ''' || p_dx_flag || ''' 
                left join pat_enc                   enc on dx.pat_enc_csn_id = enc.pat_enc_csn_id 
                WHERE 
                    dx.CONTACT_DATE between sysdate - (365.25 * 3) and sysdate 
                    AND enc.enc_type_c = 101)';
EXECUTE IMMEDIATE q1;
end;

--apply visit to departments criterion (oncology and nephrology)
create or replace procedure P_ACP_DEPT_VISIT(p_table_name in varchar2, p_dept in varchar2, p_years in number, p_criteria in varchar2) as
 q1 varchar2(4000);
begin
 q1 := 'UPDATE ' || p_table_name  || ' 
  SET ' || p_dept || '_VISIT = 1  
  WHERE  
    PAT_ID IN ( 
                SELECT DISTINCT  coh.PAT_ID 
FROM ' || p_table_name  || '          coh 
JOIN clarity.PAT_ENC                            enc on coh.pat_id = enc.pat_id 
LEFT JOIN clarity.CLARITY_DEP                   dep ON enc.department_id = dep.department_id 
LEFT JOIN clarity.v_cube_d_provider             prv ON enc.visit_prov_id = prv.provider_id 
WHERE 
    (coh.PL_' || p_criteria || ' = 1 OR coh.DX_' || p_criteria || ' = 1) 
    AND 
            (REGEXP_LIKE(dep.specialty,''' || p_dept || ''',''i'') 
            OR 
            REGEXP_LIKE(prv.primary_specialty,''' || p_dept || ''',''i'') 
            ) 
    and enc.enc_type_c = 101 
    AND enc.EFFECTIVE_DATE_DT between sysdate - (365.25 * '|| p_years ||' ) AND sysdate
    )';
 EXECUTE IMMEDIATE q1;
end;

--apply admision for certain conditions (CHF AND COPD)
create or replace procedure P_ACP_DEPT_ADMIT(p_table_name in varchar2, p_years in number, p_criteria in varchar2) as
 q1 varchar2(4000);
begin
 q1 := 'UPDATE ' || p_table_name  || ' 
  SET ' || p_criteria || '_ADMIT = 1 
  WHERE 
    PAT_ID IN ( 
                SELECT DISTINCT  coh.PAT_ID 
                FROM ' || p_table_name  || '          coh 
                JOIN pat_enc_hsp                     enc ON coh.pat_id = enc.pat_id 
                JOIN pat_enc_dx                      dx ON enc.pat_enc_csn_id = dx.pat_enc_csn_id 
                join JSANZ.js_xdr_walling_dx_lookup  drv on dx.dx_id = drv.dx_id AND drv.DX_FLAG = ''' || p_criteria || ''' 
                WHERE 
                    (coh.PL_' || p_criteria || ' = 1 OR COH.DX_' || p_criteria || ' = 1) 
                    AND dx.contact_date between sysdate - (365.25 * '|| p_years ||' ) AND sysdate
                    )';
 EXECUTE IMMEDIATE q1;
end;


-- MELD


-- EJECTION FRACTION
-- Merge criterion
-- Age criteria
-- finalize selection