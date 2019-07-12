SELECT DISTINCT st.study_id as "study_id"
				,'event_baseline_arm_1' as "redcap_event_name"
                ,pat.pat_mrn_id as "mrn"
                ,pat.pat_first_name as "first_name"
				,pat.pat_last_name as "last_name"
                ,dep.loc_name as "clinic"
                ,prv.provider_name as "pcp"
                ,coh.arm as "arm"
				--if you are using Oracle, this is the statement to merge the patient's address together				
				,CASE
                  WHEN pat.add_line_1 IS NULL 
   				   AND pat.add_line_2 IS NULL
                   AND pat.city IS NULL
                   AND pat.state_c IS NULL
                   AND pat.zip IS NULL
                    THEN NULL
                    ELSE pat.add_line_1 
					  || ' ' || pat.add_line_2 
                      || ', ' || pat.city 
                      || ', ' || xst.abbr
                      || ' '  || pat.zip       
                END AS address
				--if you are using MSSQL, this is the statement to merge the patient's address together
				-- concat(pat.add_line_1 , ' ', pat.add_line_2, ', ', pat.city ,  ', ' , xst.abbr , ' ' , pat.zip ) END AS address
				
                --,pat.email_address as "email_address"		__UCLA is going to ask patient's for their email directly
--                ,pat.add_line_1 as "address"
--                ,pat.city as "city"
--                ,xst.abbr as "state"
--                ,pat.zip as "zip_code"
--               ,pat.home_phone as "phone1"
--               ,pat.WORK_PHONE as "phone2"
                ,cm1.OTHER_COMMUNIC_NUM as "home_phone"
                ,cm2.OTHER_COMMUNIC_NUM as "work_phone"
                ,cm3.OTHER_COMMUNIC_NUM as "cell_phone"
				,cm4.OTHER_COMMUNIC_NUM as "Other_phone"
                ,coh.ad_polst_all as "ad_ever"
                ,coh.LAST_AD_POLST as "last_ad_dt"
                ,zla.name as "language"
                ,zla2.name as "preferred_language"
				,zla3.name as "preferred_lang_written_mat"
				--,emp.email as "pcp_email" -- At UCLA this field doesn't contain the provider's email address
                
                ,case when emp2.system_login is null then '' else LOWER(emp2.system_login) || '@mednet.ucla.edu' end "pcp_email"
				--UCLA specific, exclude deceased patients
                ,CASE WHEN coh.EXCLUSION_REASON = 'patient deceased' THEN 1 ELSE 0 END "patient_dead_yn"
				
				--phone contact prioritization
				,concat(
						concat(
								concat(case when cm1.CONTACT_PRIORITY is not null then cm1.CONTACT_PRIORITY
											when cm1.CONTACT_PRIORITY is null then 0 end ,  '| '  )
								,concat(case when cm2.CONTACT_PRIORITY is not null then cm2.CONTACT_PRIORITY 
											when cm2.CONTACT_PRIORITY is null then 0 end,'| ' )
								)
						,concat(
								concat(case when cm3.CONTACT_PRIORITY is not null then cm3.CONTACT_PRIORITY 
											when cm3.CONTACT_PRIORITY is null then 0 end ,'| ' )
								,case when cm4.CONTACT_PRIORITY is not null then cm4.CONTACT_PRIORITY 
										when cm4.CONTACT_PRIORITY is null then 0 end) 
						  ) as  "Phone_priority_HCWO"
                -------------------------
                --pending
                ------------------------------
--               ,pat.email_address as "email_address"
--               add a field to flag patients who became restricted after being selected for the cohort
--                ,CASE WHEN EXCLUSION_REASON = 'patient deceased' THEN EXCLUSION_DATE ELSE NULL END "death_date"

FROM xdr_acp_cohort_study_id            st
JOIN XDR_ACP_COHORT			            coh ON st.pat_id = coh.pat_id
LEFT JOIN patient			            pat ON coh.pat_id = pat.pat_id
LEFT JOIN V_CUBE_D_PROVIDER             prv ON coh.cur_pcp_prov_id = prv.provider_id
--join to pull the clinic name (we have a departments table at UCLA
left join i2b2.lz_clarity_dept          dep on coh.clinic_id = dep.loc_id 
LEFT JOIN zc_state  					xst ON pat.state_c = xst.state_c
LEFT JOIN ZC_LANGUAGE                   zla on coh.LANGUAGE_C = zla.LANGUAGE_C    --  value associated with the patient’s language 
LEFT JOIN ZC_LANGUAGE                   zla2 on pat.LANG_CARE_C = zla2.LANGUAGE_C -- The patient's preferred language to receive care. 
LEFT JOIN ZC_LANGUAGE                   zla3 on pat.LANG_WRIT_C = zla3.LANGUAGE_C -- The patient's preferred language to receive written material 
LEFT JOIN CLARITY_emp                   emp2 ON  coh.cur_pcp_prov_id = emp2.prov_id
-- the follwing two joins can yield the provider's email address
--Left join CLARITY_SER					SER ON coh.cur_pcp_prov_id = SER.prov_id
--LEFT JOIN CLARITY_EMP_DEMO              emp ON  emp.USER_ID =ser.USER_ID 

--phone number collection and prioritization
left join OTHER_COMMUNCTN cm1 on coh.pat_id = cm1.pat_id and cm1.OTHER_COMMUNIC_C = 7 --Home Phone
left join OTHER_COMMUNCTN cm2 on coh.pat_id = cm2.pat_id and cm2.OTHER_COMMUNIC_C = 1 --Cell Phone
left join OTHER_COMMUNCTN cm3 on coh.pat_id = cm3.pat_id and cm3.OTHER_COMMUNIC_C = 8 --Work Phone
left join OTHER_COMMUNCTN cm4 on coh.pat_id = cm4.pat_id and cm4.OTHER_COMMUNIC_C = 999 --Other Phone
-- The following JOIN is UCLA specific
left join XDR_ACP_COHORT_bk_05172019    prm on coh.pat_id = prm.pat_id and prm.prime = 1
where 
    -- patients in the PCORI cohort
    coh.selected = 1
    --exclude patients that are restricted
    and (coh.EXCLUSION_REASON is null or coh.EXCLUSION_REASON <> 'patient restricted')
    -- patients without an AD in the last three years, or not AD at all
    and (coh.ad_polst_all = 0 OR (current_DATe - coh.LAST_AD_POLST) > 365.25 *3)
    -- patients not already in PRIME (UCLA specific)
    and prm.pat_id is null
order by st.study_id
;--4631
