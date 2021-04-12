create or replace package                   acp_cohort_refresh as 

  -----------------------------------------------------------------------------------------------------------
  --  SYSTEM:   Patient Data Load
  --  REVISION: 1.0.0 
  --
  --  PURPOSE:  Identify Seriouslly Ill Primary Care patients and execute AD interventions/outreach
  -- 
  --  REVISION HISTORY
  --
  --  Version   Date        Author          Description
  --  --------  ----------  --------------  -----------------------------------------------------------------
  --  1.0.0     5/21/2020   Jsanz           Initial creation - Based on algorithm provided by research team to
  --                                                          identify cohort, and capture the logic of the 
  --                                                          intervention mechanism
  --
  -----------------------------------------------------------------------------------------------------------
  
      v_code  NUMBER;
      v_errm  VARCHAR2(120);
      v_proc_name VARCHAR2(120);


      PROCEDURE PRINT_ERROR (v_proc_name varchar2, v_code number, v_errm varchar2);

      PROCEDURE p_create_pc_department_tbl;

      PROCEDURE p_create_initial_diagnoses_tbl;

      PROCEDURE p_create_final_diagnoses_tbl;

      PROCEDURE p_create_pat_status_tbl;

      PROCEDURE p_create_appt_status_tbl;

      PROCEDURE p_create_cpt_chemo_tbl;

      PROCEDURE p_create_appt_type_tbl;

--      PROCEDURE p_create_clinic_tbl;

      PROCEDURE p_create_adpolst_driver_tbl;

      PROCEDURE p_create_record_tbl;

      PROCEDURE p_create_DOC_STATUS_tbl;

      PROCEDURE p_create_lab_drv_tbl;

--      PROCEDURE p_create_rnd_arm_tbl;

      PROCEDURE P_ACP_CREATE_DENOMINATOR(p_cohort_table in varchar2 DEFAULT 'CTSI_RESEARCH.XDR_ACP_COHORT',
                                        p_dept_driver_table in varchar2 DEFAULT 'CTSI_RESEARCH.XDR_ACP_DEPT_DRV',
                                        p_appt_driver_table in varchar2 DEFAULT 'CTSI_RESEARCH.XDR_ACP_APPT_STATUS');

      PROCEDURE p_acp_update_age(p_cohort_table in varchar2 DEFAULT 'CTSI_RESEARCH.XDR_ACP_COHORT');

--      PROCEDURE p_acp_remove_deceased(p_cohort_table in varchar2 DEFAULT 'CTSI_RESEARCH.XDR_ACP_COHORT')   ;
      PROCEDURE p_acp_exclude_deceased(p_cohort_table in varchar2 DEFAULT 'CTSI_RESEARCH.XDR_ACP_COHORT')   ;
      
      PROCEDURE p_acp_update_death_date(p_cohort_table in varchar2 DEFAULT 'CTSI_RESEARCH.XDR_ACP_COHORT')   ;

--      PROCEDURE p_acp_remove_restricted(p_cohort_table in varchar2 DEFAULT 'CTSI_RESEARCH.XDR_ACP_COHORT'
--                                , p_driver_table in varchar2 DEFAULT 'CTSI_RESEARCH.XDR_ACP_PAT_STATUS');

      PROCEDURE p_acp_flag_restricted(p_cohort_table in varchar2 DEFAULT 'CTSI_RESEARCH.XDR_ACP_COHORT'
                                , p_driver_table in varchar2 DEFAULT 'CTSI_RESEARCH.XDR_ACP_PAT_STATUS');

--      PROCEDURE p_acp_prime(p_cohort_table in varchar2 DEFAULT 'CTSI_RESEARCH.XDR_ACP_COHORT'
--                                , p_prime_table in varchar2 DEFAULT 'CTSI_RESEARCH.XDR_PRIME_TEMP');
                                
--      PROCEDURE P_ACP_PL_DX(p_cohort_table in varchar2 DEFAULT 'CTSI_RESEARCH.XDR_ACP_PL_DX', p_table_name in varchar2 DEFAULT 'CTSI_RESEARCH.XDR_ACP_COHORT', p_dx_flag in varchar2 DEFAULT 'CTSI_RESEARCH.XDR_ACP_DX_LOOKUP');
      PROCEDURE P_ACP_PL_DX_TBL(p_table_name  in varchar2 DEFAULT 'CTSI_RESEARCH.XDR_ACP_PL_DX'
                                , p_cohort_table in varchar2 DEFAULT 'CTSI_RESEARCH.XDR_ACP_COHORT'
                                , p_driver_table in varchar2 DEFAULT 'CTSI_RESEARCH.XDR_ACP_DX_LOOKUP');

      PROCEDURE P_ACP_PL_DX( p_cohort_table in varchar2 DEFAULT 'CTSI_RESEARCH.XDR_ACP_COHORT'
                            , p_table_name  in varchar2 DEFAULT 'CTSI_RESEARCH.XDR_ACP_PL_DX'
                            , p_dx_flag in varchar2) ;

--      PROCEDURE P_ACP_PL_DX(p_cohort_table in varchar2 DEFAULT 'CTSI_RESEARCH.XDR_ACP_COHORT',p_table_name  in varchar2 DEFAULT 'XDR_ACP_PL_DX','CANCER');
--      PROCEDURE P_ACP_PL_DX(p_cohort_table in varchar2 DEFAULT 'CTSI_RESEARCH.XDR_ACP_COHORT',p_table_name  in varchar2 DEFAULT 'XDR_ACP_PL_DX','CHF');
--      PROCEDURE P_ACP_PL_DX(p_cohort_table in varchar2 DEFAULT 'CTSI_RESEARCH.XDR_ACP_COHORT',p_table_name  in varchar2 DEFAULT 'XDR_ACP_PL_DX','ALS');
--      PROCEDURE P_ACP_PL_DX(p_cohort_table in varchar2 DEFAULT 'CTSI_RESEARCH.XDR_ACP_COHORT',p_table_name  in varchar2 DEFAULT 'XDR_ACP_PL_DX','COPD');
--      PROCEDURE P_ACP_PL_DX(p_cohort_table in varchar2 DEFAULT 'CTSI_RESEARCH.XDR_ACP_COHORT',p_table_name  in varchar2 DEFAULT 'XDR_ACP_PL_DX','COPD_SPO2');
--      PROCEDURE P_ACP_PL_DX(p_cohort_table in varchar2 DEFAULT 'CTSI_RESEARCH.XDR_ACP_COHORT',p_table_name  in varchar2 DEFAULT 'XDR_ACP_PL_DX','CIRRHOSIS');
--      PROCEDURE P_ACP_PL_DX(p_cohort_table in varchar2 DEFAULT 'CTSI_RESEARCH.XDR_ACP_COHORT',p_table_name  in varchar2 DEFAULT 'XDR_ACP_PL_DX','ESRD');
--      PROCEDURE P_ACP_PL_DX(p_cohort_table in varchar2 DEFAULT 'CTSI_RESEARCH.XDR_ACP_COHORT',p_table_name  in varchar2 DEFAULT 'XDR_ACP_PL_DX','PERITONITIS');
--      PROCEDURE P_ACP_PL_DX(p_cohort_table in varchar2 DEFAULT 'CTSI_RESEARCH.XDR_ACP_COHORT',p_table_name  in varchar2 DEFAULT 'XDR_ACP_PL_DX','HEPATORENAL');
--      PROCEDURE P_ACP_PL_DX(p_cohort_table in varchar2 DEFAULT 'CTSI_RESEARCH.XDR_ACP_COHORT',p_table_name  in varchar2 DEFAULT 'XDR_ACP_PL_DX','BLEEDING');
--      PROCEDURE P_ACP_PL_DX(p_cohort_table in varchar2 DEFAULT 'CTSI_RESEARCH.XDR_ACP_COHORT',p_table_name  in varchar2 DEFAULT 'XDR_ACP_PL_DX','ASCITES');
--      PROCEDURE P_ACP_PL_DX(p_cohort_table in varchar2 DEFAULT 'CTSI_RESEARCH.XDR_ACP_COHORT',p_table_name  in varchar2 DEFAULT 'XDR_ACP_PL_DX','ENCEPHALOPATHY');

      PROCEDURE P_ACP_PL_ESDL_DECOMPENSATION(p_cohort_table in varchar2  DEFAULT 'CTSI_RESEARCH.XDR_ACP_COHORT');
      PROCEDURE P_ACP_ENC_DX_TBL(p_table_name  in varchar2 DEFAULT 'CTSI_RESEARCH.XDR_ACP_ENC_DX'
                                , p_cohort_table in varchar2 DEFAULT 'CTSI_RESEARCH.XDR_ACP_COHORT'
                                , p_driver_table in varchar2 DEFAULT 'CTSI_RESEARCH.XDR_ACP_DX_LOOKUP'
                                , p_timeframe in number DEFAULT 3);


    PROCEDURE P_ACP_ENC_DX(p_cohort_table in varchar2 DEFAULT 'CTSI_RESEARCH.XDR_ACP_COHORT'
                                        , p_dx_table in varchar2 DEFAULT 'CTSI_RESEARCH.XDR_ACP_ENC_DX'
                                        , p_dx_flag in varchar2);
--
--      PROCEDURE P_ACP_ENC_DX('XDR_ACP_COHORT','XDR_ACP_ENC_DX','CHF');
--      PROCEDURE P_ACP_ENC_DX('XDR_ACP_COHORT','XDR_ACP_ENC_DX','ALS');
--      PROCEDURE P_ACP_ENC_DX('XDR_ACP_COHORT','XDR_ACP_ENC_DX','COPD');
--      PROCEDURE P_ACP_ENC_DX('XDR_ACP_COHORT','XDR_ACP_ENC_DX','COPD_SPO2');
--      PROCEDURE P_ACP_ENC_DX('XDR_ACP_COHORT','XDR_ACP_ENC_DX','CIRRHOSIS');
--      PROCEDURE P_ACP_ENC_DX('XDR_ACP_COHORT','XDR_ACP_ENC_DX','ESRD');
--      PROCEDURE P_ACP_ENC_DX('XDR_ACP_COHORT','XDR_ACP_ENC_DX','PERITONITIS');
--      PROCEDURE P_ACP_ENC_DX('XDR_ACP_COHORT','XDR_ACP_ENC_DX','HEPATORENAL');
--      PROCEDURE P_ACP_ENC_DX('XDR_ACP_COHORT','XDR_ACP_ENC_DX','BLEEDING');
--      PROCEDURE P_ACP_ENC_DX('XDR_ACP_COHORT','XDR_ACP_ENC_DX','ASCITES');
--      PROCEDURE P_ACP_ENC_DX('XDR_ACP_COHORT','XDR_ACP_ENC_DX','ENCEPHALOPATHY');

      PROCEDURE P_ACP_DX_ESDL_DECOMPENSATION(p_cohort_table in varchar2  DEFAULT 'CTSI_RESEARCH.XDR_ACP_COHORT');

      PROCEDURE p_acp_flag_pat_with_dxpl(p_cohort_table in varchar2  DEFAULT 'CTSI_RESEARCH.XDR_ACP_COHORT');
      PROCEDURE P_ACP_DEPT_VISIT_ONC(p_cohort_table in varchar2 DEFAULT 'CTSI_RESEARCH.XDR_ACP_COHORT'
                                    , p_dept in varchar2 DEFAULT 'ONC'
                                    , p_years in number DEFAULT 1
                                    , p_criteria in varchar2 DEFAULT 'CANCER');


      PROCEDURE P_ACP_DEPT_VISIT_NEPH(p_cohort_table in varchar2 DEFAULT 'CTSI_RESEARCH.XDR_ACP_COHORT'
                                    , p_dept in varchar2 DEFAULT 'NEPH'
                                    , p_years in number DEFAULT 1
                                    , p_criteria in varchar2 DEFAULT 'ESRD');
      PROCEDURE P_ACP_DEPT_ADMIT(p_cohort_table in varchar2
                                , p_driver_table in varchar2
                                , p_years in number
                                , p_criteria in varchar2);     

      PROCEDURE P_ACP_CHEMO_PROC(p_cohort_table in varchar2 DEFAULT 'CTSI_RESEARCH.XDR_ACP_COHORT'
                                , p_driver_table  in varchar2 DEFAULT 'CTSI_RESEARCH.XDR_ACP_CHEMO_CPT'
                                , p_timeframe in number DEFAULT 2);

      PROCEDURE P_ACP_CHEMO_MEDS(p_cohort_table in varchar2 DEFAULT 'CTSI_RESEARCH.XDR_ACP_COHORT'
                                , p_med_keyword  in varchar2 DEFAULT 'CHEMO'
                                , p_timeframe in number DEFAULT 2);                      

       PROCEDURE P_ACP_LAB_PULL(p_table_name in varchar2 DEFAULT 'CTSI_RESEARCH.XDR_ACP_LAB'
                                , p_cohort_table in varchar2 DEFAULT 'CTSI_RESEARCH.XDR_ACP_COHORT'
                                , p_driver_table  in varchar2 DEFAULT 'CTSI_RESEARCH.XDR_ACP_LAB_DRV'
                                , p_timeframe in number DEFAULT 3);

       PROCEDURE P_ACP_LAB_MELD_TABLE( p_lab_table in varchar2 DEFAULT 'CTSI_RESEARCH.XDR_ACP_LAB'
                                , p_meld_table in varchar2 DEFAULT 'CTSI_RESEARCH.XDR_ACP_MELD_TABLE')   ;  

       PROCEDURE P_ACP_MELD(p_cohort_table in varchar2 DEFAULT 'CTSI_RESEARCH.XDR_ACP_COHORT'
                                , p_lab_table in varchar2  DEFAULT 'CTSI_RESEARCH.XDR_ACP_MELD_TABLE');

      PROCEDURE P_ACP_EF_NARR(p_table_name in varchar2  DEFAULT 'CTSI_RESEARCH.XDR_ACP_NARR'
                                , p_cohort_table in varchar2 DEFAULT 'CTSI_RESEARCH.XDR_ACP_COHORT'
                                , p_timeframe in number DEFAULT 3);

      PROCEDURE P_ACP_EF_FLAG(p_cohort_table in varchar2 DEFAULT 'CTSI_RESEARCH.XDR_ACP_COHORT'
                                ,p_narr_table in varchar2 DEFAULT  'CTSI_RESEARCH.XDR_ACP_NARR');

      PROCEDURE P_ACP_MERGE_CRITERION(p_cohort_table in varchar2 DEFAULT 'CTSI_RESEARCH.XDR_ACP_COHORT');

      PROCEDURE P_ACP_AGE_CRTIERIA(p_cohort_table in varchar2 DEFAULT 'CTSI_RESEARCH.XDR_ACP_COHORT'
                                    ,p_age_limit in varchar2 DEFAULT 75);


      PROCEDURE P_ACP_ADPOLST(p_adpolst_table in varchar2 DEFAULT 'CTSI_RESEARCH.XDR_ACP_ADPOLST'
                            ,p_cohort_table in varchar2 DEFAULT 'CTSI_RESEARCH.XDR_ACP_COHORT'
                            , p_driver_adpolst in varchar2 DEFAULT 'CTSI_RESEARCH.XDR_ACP_ADPOLST_DRV'
                            , p_driver_record_stat in varchar2 DEFAULT 'CTSI_RESEARCH.XDR_ACP_RECORD_STATE'
                            , p_driver_doc_stat in varchar2 DEFAULT 'CTSI_RESEARCH.XDR_ACP_DOC_STATUS');


      PROCEDURE P_ACP_ADPOLST_update(p_cohort_table in varchar2 DEFAULT 'CTSI_RESEARCH.XDR_ACP_COHORT'
                            , p_adpolst_table in varchar2 DEFAULT 'CTSI_RESEARCH.XDR_ACP_ADPOLST');

      PROCEDURE P_ACP_ADPOLST_date(p_cohort_table in varchar2 DEFAULT 'CTSI_RESEARCH.XDR_ACP_COHORT'
                            , p_adpolst_table in varchar2 DEFAULT 'CTSI_RESEARCH.XDR_ACP_ADPOLST');    
                            
      PROCEDURE P_ACP_ADPOLST_merge(p_cohort_table in varchar2 DEFAULT 'CTSI_RESEARCH.XDR_ACP_COHORT');                            

      PROCEDURE P_ACP_loc_last_pcp(p_cohort_table in varchar2  DEFAULT 'CTSI_RESEARCH.XDR_ACP_COHORT' 
                            , p_driver_dept in varchar2 DEFAULT 'CTSI_RESEARCH.XDR_ACP_DEPT_DRV'
                            , p_driver_appt_type in varchar2 DEFAULT 'CTSI_RESEARCH.XDR_ACP_APPT_TYPE'
                            , p_driver_appt_status in varchar2 DEFAULT 'CTSI_RESEARCH.XDR_ACP_APPT_STATUS');

      PROCEDURE P_ACP_LOC_MOST_VISITS(p_cohort_table in varchar2  DEFAULT 'CTSI_RESEARCH.XDR_ACP_COHORT' 
                            , p_driver_dept in varchar2 DEFAULT 'CTSI_RESEARCH.XDR_ACP_DEPT_DRV'
                            , p_driver_appt_type in varchar2 DEFAULT 'CTSI_RESEARCH.XDR_ACP_APPT_TYPE'
                            , p_driver_appt_status in varchar2 DEFAULT 'CTSI_RESEARCH.XDR_ACP_APPT_STATUS');

      PROCEDURE P_ACP_loc_last_visit(p_cohort_table in varchar2  DEFAULT 'CTSI_RESEARCH.XDR_ACP_COHORT' 
                            , p_driver_dept in varchar2 DEFAULT 'CTSI_RESEARCH.XDR_ACP_DEPT_DRV'
                            , p_driver_appt_type in varchar2 DEFAULT 'CTSI_RESEARCH.XDR_ACP_APPT_TYPE'
                            , p_driver_appt_status in varchar2 DEFAULT 'CTSI_RESEARCH.XDR_ACP_APPT_STATUS');

      PROCEDURE P_ACP_CLINIC(p_cohort_table in varchar2  DEFAULT 'CTSI_RESEARCH.XDR_ACP_COHORT');

--      PROCEDURE P_ACP_COORDINATOR(p_cohort_table in varchar2 DEFAULT 'CTSI_RESEARCH.XDR_ACP_COHORT'
--                            , p_driver_table in varchar2 DEFAULT 'CTSI_RESEARCH.XDR_ACP_CLINICS');

      PROCEDURE P_ACP_INTERV_ARM_ASSIGNMENT(p_cohort_table in varchar2  DEFAULT 'CTSI_RESEARCH.XDR_ACP_COHORT'
                                    , p_driver_table in varchar2  DEFAULT 'CTSI_RESEARCH.XDR_ACP_RANDOMIZATION');

--      PROCEDURE p_prime_criteria(p_cohort_table in varchar2 DEFAULT 'CTSI_RESEARCH.XDR_ACP_COHORT'
--                                    ,p_prime_table in varchar2 DEFAULT 'CTSI_RESEARCH.XDR_PRIME_TEMP');
      procedure p_assign_study_id(p_cohort_table in varchar2 DEFAULT 'CTSI_RESEARCH.XDR_ACP_COHORT'
                                , p_study_table  varchar2 DEFAULT 'XDR_ACP_COHORT_STUDY_ID');
      PROCEDURE p_acp_clean_up(p_table_name in varchar2);
      
      PROCEDURE p_acp_truncate_tbl(p_table_name in varchar2);
--      PROCEDURE p_acp_remove_not_selected(p_cohort_table in varchar2 DEFAULT 'CTSI_RESEARCH.XDR_ACP_COHORT');

      PROCEDURE p_truncate_rwb_weekly(p_cohort_table in varchar2 DEFAULT  'CTSI_RESEARCH.XDR_ACP_COHORT'
                                      , p_rwb_table in varchar2 DEFAULT 'CTSI_RESEARCH.XDR_ACP_RWB_WEEKLY'
                                      ,p_tbl_outreach_temp in varchar2 DEFAULT 'CTSI_RESEARCH.XDR_ACP_SMARTFORMS_ENC'
                                      ,p_tbl_outreach_hx in varchar2 DEFAULT 'CTSI_RESEARCH.XDR_ACP_SMARTFORMS_ENC_HX');

      PROCEDURE p_save_smartforms(p_tbl_smartform in varchar2 DEFAULT  'CTSI_RESEARCH.XDR_ACP_SMARTFORMS'
                                      , p_tbl_outreach_temp in varchar2 DEFAULT 'CTSI_RESEARCH.XDR_ACP_SMARTFORMS_ENC');
      
      PROCEDURE p_trigger_intervention_arm_1_2(p_cohort_table in varchar2 DEFAULT  'CTSI_RESEARCH.XDR_ACP_COHORT'
                                        ,p_rwb_table in varchar2 DEFAULT 'CTSI_RESEARCH.XDR_ACP_RWB_WEEKLY'
                                        ,p_rwb_hx_table in varchar2 DEFAULT 'CTSI_RESEARCH.XDR_ACP_RWB_WEEKLY_HX'
                                        ,p_appt_type_table in varchar2 DEFAULT  'CTSI_RESEARCH.XDR_ACP_APPT_TYPE'
                                        ,p_clinic_table in varchar2 DEFAULT 'CTSI_RESEARCH.XDR_ACP_RANDOMIZATION'
                                        ,p_dept_driver_table in varchar2 DEFAULT 'CTSI_RESEARCH.XDR_ACP_DEPT_DRV'            
                                        );
      
      PROCEDURE p_trigger_intervention_arm_3(p_cohort_table in varchar2 DEFAULT  'CTSI_RESEARCH.XDR_ACP_COHORT'
                                        ,p_rwb_table in varchar2 DEFAULT 'CTSI_RESEARCH.XDR_ACP_RWB_WEEKLY'
                                        ,p_rwb_hx_table in varchar2 DEFAULT 'CTSI_RESEARCH.XDR_ACP_RWB_WEEKLY_HX'
                                        ,p_appt_type_table in varchar2 DEFAULT  'CTSI_RESEARCH.XDR_ACP_APPT_TYPE'
                                        ,p_clinic_table in varchar2 DEFAULT 'CTSI_RESEARCH.XDR_ACP_RANDOMIZATION'
                                        ,p_dept_driver_table in varchar2 DEFAULT 'CTSI_RESEARCH.XDR_ACP_DEPT_DRV'
                                        );                                  
                                        
      PROCEDURE p_acp_orange_dot(p_cohort_table in varchar2 DEFAULT  'CTSI_RESEARCH.XDR_ACP_COHORT'
                               ,p_dot_history_table in varchar2 DEFAULT  'CTSI_RESEARCH.XDR_ACP_PCP_CLINIC_ARM_HX'
                               ,p_clinic_table in varchar2 DEFAULT  'CTSI_RESEARCH.XDR_ACP_RANDOMIZATION'
                               ,p_study_id_table in varchar2 DEFAULT 'CTSI_RESEARCH.XDR_ACP_COHORT_STUDY_ID');
                               

      PROCEDURE p_acp_grey_dot(p_cohort_table in varchar2 DEFAULT  'CTSI_RESEARCH.XDR_ACP_COHORT'
                               ,p_dot_history_table in varchar2 DEFAULT  'CTSI_RESEARCH.XDR_ACP_PCP_CLINIC_ARM_HX'
                               ,p_study_id_table in varchar2 DEFAULT 'CTSI_RESEARCH.XDR_ACP_COHORT_STUDY_ID');


      PROCEDURE p_acp_red_dot(p_cohort_table in varchar2 DEFAULT  'CTSI_RESEARCH.XDR_ACP_COHORT'
                               ,p_dot_history_table in varchar2 DEFAULT  'CTSI_RESEARCH.XDR_ACP_PCP_CLINIC_ARM_HX'
                               ,p_intervention_table in varchar2 DEFAULT  'CTSI_RESEARCH.XDR_ACP_RWB_WEEKLY'
                               ,p_study_id_table in varchar2 DEFAULT 'CTSI_RESEARCH.XDR_ACP_COHORT_STUDY_ID');

--
--      PROCEDURE p_acp_flagged_prime(p_cohort_table in varchar2 DEFAULT 'CTSI_RESEARCH.XDR_ACP_COHORT'
--                                , p_driver_table in varchar2 DEFAULT 'CTSI_RESEARCH.XDR_ACP_PRIME');

      PROCEDURE p_simulation_intervention(p_cohort_table in varchar2 DEFAULT  'CTSI_RESEARCH.XDR_ACP_COHORT'
                                  ,p_wrb_table in varchar2 DEFAULT 'CTSI_RESEARCH.XDR_ACP_RWB_WEEKLY_SIMU'
                                  ,p_wrb_hx_table in varchar2 DEFAULT 'CTSI_RESEARCH.XDR_ACP_RWB_WEEKLY_HX_SIMU'
                                  ,p_appt_type_table in varchar2 DEFAULT  'CTSI_RESEARCH.XDR_ACP_APPT_TYPE'
                                  ,p_clinic_table in varchar2 DEFAULT 'CTSI_RESEARCH.XDR_ACP_RANDOMIZATION'
                                  ,p_dept_driver_table in varchar2 DEFAULT 'CTSI_RESEARCH.XDR_ACP_DEPT_DRV'
                                  ,RWB_SUBMISSION_DATE_report in varchar2 DEFAULT '12/15/2019'
                                  ,RWB_SUBMISSION_DATE_appt in varchar2 DEFAULT '12/15/2018'
                                  ,GO_LIVE_DATE  in varchar2 DEFAULT '12/16/2018');                                

      PROCEDURE p_simulation_intervention_drv;
                                   
        
      PROCEDURE p_simulation_intervention_bat(p_cohort_table in varchar2 DEFAULT  'CTSI_RESEARCH.XDR_ACP_COHORT'
                                  ,p_wrb_table in varchar2 DEFAULT 'CTSI_RESEARCH.XDR_ACP_RWB_WEEKLY_SIMU'
                                  ,p_wrb_hx_table in varchar2 DEFAULT 'CTSI_RESEARCH.XDR_ACP_RWB_WEEKLY_HX_SIMU'
                                  ,p_appt_type_table in varchar2 DEFAULT  'CTSI_RESEARCH.XDR_ACP_APPT_TYPE'
                                  ,p_clinic_table in varchar2 DEFAULT 'CTSI_RESEARCH.XDR_ACP_RANDOMIZATION'
                                  ,RWB_SUBMISSION_DATE_report in varchar2 DEFAULT '12/15/2019'
                                  ,RWB_SUBMISSION_DATE_appt in varchar2 DEFAULT '12/15/2018'
                                  ,GO_LIVE_DATE  in varchar2 DEFAULT '12/16/2018');  
                                  
                                  
      procedure p_acp_optout(p_cohort_table in varchar2  DEFAULT 'CTSI_RESEARCH.XDR_ACP_COHORT'
      , p_patient_table in varchar2 DEFAULT 'I2B2.LZ_CLARITY_PATIENT'
      , p_optout_table in varchar2 DEFAULT 'CTSI_RESEARCH.XDR_ACP_OPT_OUTS');
      
      procedure p_acp_race;
      
      procedure p_tableau_reporting;
      
      PROCEDURE p_hm_cleanup;

END ACP_COHORT_REFRESH;
