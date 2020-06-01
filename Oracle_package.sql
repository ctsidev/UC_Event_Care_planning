create or replace package                   acp_cohort_refresh as 

  -----------------------------------------------------------------------------------------------------------
  --  SYSTEM:   Patient cohort identification
  --  REVISION: 1.0.0 
  --
  --  PURPOSE:  Identify Seriouslly Ill Primary Care patients and execute AD interventions/outreach
  -- 
  --  REVISION HISTORY
  --
  --  Version   Date        Author          Description
  --  --------  ----------  --------------  -----------------------------------------------------------------
  --  1.0.0     5/21/2020   Jsanz           Initial creation - Based on algorithm provided by ACP research team to
  --                                                          identify seriouslly illness cohort
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

      PROCEDURE p_create_adpolst_driver_tbl;

      PROCEDURE p_create_record_tbl;

      PROCEDURE p_create_DOC_STATUS_tbl;

      PROCEDURE p_create_lab_drv_tbl;

      PROCEDURE P_ACP_CREATE_DENOMINATOR(p_cohort_table in varchar2 DEFAULT 'CTSI_RESEARCH.XDR_ACP_COHORT',
                                        p_dept_driver_table in varchar2 DEFAULT 'CTSI_RESEARCH.XDR_ACP_DEPT_DRV',
                                        p_appt_driver_table in varchar2 DEFAULT 'CTSI_RESEARCH.XDR_ACP_APPT_STATUS');

      PROCEDURE p_acp_update_age(p_cohort_table in varchar2 DEFAULT 'CTSI_RESEARCH.XDR_ACP_COHORT');

      PROCEDURE p_acp_exclude_deceased(p_cohort_table in varchar2 DEFAULT 'CTSI_RESEARCH.XDR_ACP_COHORT')   ;

      PROCEDURE p_acp_flag_restricted(p_cohort_table in varchar2 DEFAULT 'CTSI_RESEARCH.XDR_ACP_COHORT'
                                , p_driver_table in varchar2 DEFAULT 'CTSI_RESEARCH.XDR_ACP_PAT_STATUS');

      PROCEDURE P_ACP_PL_DX_TBL(p_table_name  in varchar2 DEFAULT 'CTSI_RESEARCH.XDR_ACP_PL_DX'
                                , p_cohort_table in varchar2 DEFAULT 'CTSI_RESEARCH.XDR_ACP_COHORT'
                                , p_driver_table in varchar2 DEFAULT 'CTSI_RESEARCH.XDR_ACP_DX_LOOKUP');

      PROCEDURE P_ACP_PL_DX( p_cohort_table in varchar2 DEFAULT 'CTSI_RESEARCH.XDR_ACP_COHORT'
                            , p_table_name  in varchar2 DEFAULT 'CTSI_RESEARCH.XDR_ACP_PL_DX'
                            , p_dx_flag in varchar2) ;

      PROCEDURE P_ACP_PL_ESDL_DECOMPENSATION(p_cohort_table in varchar2  DEFAULT 'CTSI_RESEARCH.XDR_ACP_COHORT');
      PROCEDURE P_ACP_ENC_DX_TBL(p_table_name  in varchar2 DEFAULT 'CTSI_RESEARCH.XDR_ACP_ENC_DX'
                                , p_cohort_table in varchar2 DEFAULT 'CTSI_RESEARCH.XDR_ACP_COHORT'
                                , p_driver_table in varchar2 DEFAULT 'CTSI_RESEARCH.XDR_ACP_DX_LOOKUP'
                                , p_timeframe in number DEFAULT 3);


    PROCEDURE P_ACP_ENC_DX(p_cohort_table in varchar2 DEFAULT 'CTSI_RESEARCH.XDR_ACP_COHORT'
                                        , p_dx_table in varchar2 DEFAULT 'CTSI_RESEARCH.XDR_ACP_ENC_DX'
                                        , p_dx_flag in varchar2);

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
                                , p_driver_table  in varchar2 DEFAULT 'CTSI_RESEARCH.XDR_ACP_DX_LOOKUP'
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


END ACP_COHORT_REFRESH;