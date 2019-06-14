SELECT DISTINCT st.study_id as "study_id"
				,'event_baseline_arm_1' as "redcap_event_name"
                ,pat.pat_mrn_id as "mrn"
                ,pat.pat_first_name as "first_name"
				,pat.pat_last_name as "last_name"
                ,dep.loc_name as "clinic"
                ,prv.provider_name as "pcp"
                ,coh.arm as "arm"
				 ,CASE
                  WHEN pat.add_line_1 IS NULL 
                   AND pat.city IS NULL
                   AND pat.state_c IS NULL
                   AND pat.zip IS NULL
                    THEN NULL
                    ELSE pat.add_line_1 
                      || ', ' || pat.city 
                      || ', ' || xst.abbr
                      || ' '  || pat.zip       
                END AS address
                ,pat.email_address as "email_address"
--                ,pat.add_line_1 as "address"
--                ,pat.city as "city"
--                ,xst.abbr as "state"
--                ,pat.zip as "zip_code"
--               ,pat.home_phone as "phone1"
--               ,pat.WORK_PHONE as "phone2"
                ,cm1.OTHER_COMMUNIC_NUM as "home_phone"
                ,cm2.OTHER_COMMUNIC_NUM as "work_phone"
                ,cm3.OTHER_COMMUNIC_NUM as "cell_phone"
                ,coh.ad_polst_all as "ad_ever"
                ,coh.LAST_AD_POLST as "last_ad_dt"
                ,zla.name as "language"
                ,zla2.name as "preferred_language"
                ,case when emp.system_login is null then '' else LOWER(emp.system_login) || '@mednet.ucla.edu' end "pcp_email"
                ,CASE WHEN EXCLUSION_REASON = 'patient deceased' THEN 1 ELSE 0 END "patient_dead_yn"
                -------------------------
                --pending
                ------------------------------
--               ,pat.email_address as "email_address"
--               add a field to flag patients who became restricted after being selected for the cohort
--                ,CASE WHEN EXCLUSION_REASON = 'patient deceased' THEN EXCLUSION_DATE ELSE NULL END "death_date"

FROM XDR_ACP_COHORT			            coh --ON st.pat_id = coh.pat_id
LEFT JOIN patient			            pat ON coh.pat_id = pat.pat_id
LEFT JOIN V_CUBE_D_PROVIDER             prv ON coh.cur_pcp_prov_id = prv.provider_id
--join to pull the clinic name (we have a departments table at UCLA
left join i2b2.lz_clarity_dept          dep on coh.clinic_id = dep.loc_id 
LEFT JOIN zc_state  					xst ON pat.state_c = xst.state_c
LEFT JOIN ZC_LANGUAGE                   zla on coh.LANGUAGE_C = zla.LANGUAGE_C
LEFT JOIN ZC_LANGUAGE                   zla2 on pat.LANG_CARE_C = zla2.LANGUAGE_C
LEFT JOIN CLARITY_emp                   emp ON  coh.cur_pcp_prov_id = emp.prov_id
left join clarity.OTHER_COMMUNCTN  cm1 on coh.pat_id = cm1.pat_id and cm1.OTHER_COMMUNIC_C = 7 --Home Phone
left join clarity.OTHER_COMMUNCTN cm2 on coh.pat_id = cm2.pat_id and cm2.OTHER_COMMUNIC_C = 8 --Work Phone
left join clarity.OTHER_COMMUNCTN cm3 on coh.pat_id = cm3.pat_id and cm3.OTHER_COMMUNIC_C = 1 --Cell Phone
where 
    -- patients in the PCORI cohort
    coh.selected = 1
    --exclude patients that are restricted
    and (coh.EXCLUSION_REASON is null or coh.EXCLUSION_REASON <> 'patient restricted')
    -- patients without an AD in the last three years, or not AD at all
    and (coh.ad_polst_all = 0 OR (current_DATe - coh.LAST_AD_POLST) BETWEEN 0 AND 365.25 *3)
order by study_id
;--5042
