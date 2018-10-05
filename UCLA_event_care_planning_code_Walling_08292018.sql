/****************************************************************************
Project Name: Event Care Planning
 Investigator Name: Dr Ann Walling, Dr Neil Wenger, and Dr Douglas Bell

	Author: Robert Follett/Javi Sanz
	Revision Date: 20180828
	Version: 1.0.1

	Background:
	UCLA EMR data for adults 18 or older that meet cohort criteria for serious illness (see cohorts below: advanced cancer, COPD, CHF, ESLD, etc.) 
    and have two encounter with primary care within the last year e.g. May 2017 to May 2018

	Instructions:
	The script will create a main table with all potential patients (denominator) and a series of flags (pl and dx) to help gauge the most accurate algorithm
    to define each sub-group. This code will pull all active problem list records and the last three years of outpatient diagnoses

    After this step, we will implement the following flags to pull/calculate additional indicators for each group.

    ESLD:
        -Labs results (Albumin, INR, Creatinine, Bilirubin, sodium, MELD)
        -MELD
        -Dialysis (limited since it doesn't get recorded at UCLA*)
    
    Advance cancer:
        -Oncology visits in the last two years
        -Chemotherapy treatments in the last two years (CPT codes and meds)

    CHF:
        -LVEF results (separate file)
        -Hospitalizations  with CHF diagnosis in the last 12 months
    
    COPD:
        -Hospitalizations  with COPD diagnosis in the last 12 months
    
	Finally, the code includes a section pull counts and samples for each criteria. The output shall be exported to a xlsx file that shall include the aggregated 
    counts for each cohort, the patients' information, and a brief data dictionary.

	For any questions regarding the script, feel free to contact me at
	jsanz@mednet.ucla.edu
****************************************************************************/

-- Additionaly list of files provided (drivers and such)

--     Diagnosis [XDR_WALLING_DX_LOOKUP_TEMP.csv]   line#   247
--     Labs [XDR_WALLING_LAB_DRV.csv]               line#   327
--     Death function [XDR_WALLING_DEATH_UCLA.sql]  ilne#   371
--     LVEF code [XDR_WALLING_LVEF_UCLA.sql]        line# 1,627


/****************************************************************************
Step 1:     Create drivers
                Primary Care Departments
	            Diagnoses
	            Labs (LOINC codes)

****************************************************************************/

----------------------------------------------------------------------------
--Step 1.1:     Create driver for departments for Primary Care visits using the following departments
--              Internal Medicine, Primary Care, and Family Practice
--              The codes below are UCLA specific. They are only here as a place holder.
----------------------------------------------------------------------------
drop table js_xdr_walling_IMFP_dept_drv purge;
create table js_xdr_walling_IMFP_dept_drv as 
select * from i2b2.lz_clarity_dept
where department_id in (
910314,
910310,
70085,
80366,
80039,
940035,
940043,
60155,
60156,
10511,
910227,
910228,
910230,
910231,
910177,
910178,
50541,
80273,
80279,
80114,
20511,
80169,
80179,
80044,
80382,
80329,
80049,
940012,
940013,
940015,
940016,
940017,
940018,
940019,
80087,
940038,
61026,
70001,
70009,
70003,
70005,
70006,
70007,
70008,
70010,
70011,
60678,
60679,
70079,
70032,
80168,
70034,
70035,
60152,
60153,
60159,
60160,
60161,
60162,
70080,
60167,
60170,
60173,
60175,
60176,
60177,
60178,
60180,
60181,
10009,
10014,
10030,
10031,
80399,
20560,
80000,
80368,
20570,
60079,
80337,
70186,
70190,
20561,
80379,
70232,
72005,
70210,
10501149,
80190,
80197,
60610,
60614,
60618,
60619,
60620,
60624,
60658,
60659,
60078,
60083,
10501190,
21200003,
21501001,
10501101,
80286,
80293,
60737,
60745,
70090,
70092,
70095,
20006,
20007,
20009,
70183,
70185,
80392,
20010,
70191,
20018,
80165,
20024,
80112,
80115,
70208,
70211,
70215,
70216,
80088,
80090,
30101101,
99102100,
70004,
80124,
80125,
80132,
80139,
80142,
80156,
80158,
80163,
80164,
80171,
60201,
80178,
72004,
72008,
80001,
80002,
80003,
80006,
80007,
80008,
80009,
80034,
80035,
80038,
80040,
80047,
80048,
80060,
80068
);

----------------------------------------------------------------------------
--Step 1.2:     Create diagnosis codes driver table

----------------------------------------------------------------------------
    --------------------------------------------------------------
    -- Step 1.2.1: Create table to load the diagnoses support file
    --------------------------------------------------------------
DROP TABLE js_xdr_WALLING_DX_LOOKUP_TEMP PURGE;
CREATE TABLE js_xdr_WALLING_DX_LOOKUP_TEMP
   (
    "ICD_TYPE" NUMBER(*,0), 
    "ICD_CODE" VARCHAR2(20 BYTE), 
	"ICD_DESC" VARCHAR2(254 BYTE),
    "DX_FLAG"	VARCHAR2(20 BYTE));

    --------------------------------------------------------------
    -- Step 1.2.2: Load DX driver support file from [XDR_WALLING_DX_LOOKUP_TEMP.csv]
    --------------------------------------------------------------

-- Calculate counts for QA
select DX_FLAG
,count(*) as ct
from js_xdr_WALLING_DX_LOOKUP_TEMP
group by DX_FLAG;

/*
ALS	        2
ASCITES	        4
BLEEDING	7
CANCER	        180
CHF	        46
CIRRHOSIS	50
COPD	        14
COPD_SPO2	11
ENCEPHALOPATHY	3
ESRD	        23
HEPATORENAL	2
PARKINSONS	3
PERITONITIS	19
*/

    --------------------------------------------------------------
    -- Step 1.2.3: Create final table including the dx_id from refference tables
    --------------------------------------------------------------
drop table js_xdr_WALLING_DX_LOOKUP purge;
create table js_xdr_WALLING_DX_LOOKUP as 
select edg.dx_id
,drv.*
from js_xdr_WALLING_DX_LOOKUP_TEMP      drv
join edg_current_icd9           edg on drv.icd_CODE = edg.CODE and drv.icd_type = 9
UNION
select edg.dx_id
,drv.*
from js_xdr_WALLING_DX_LOOKUP_TEMP      drv
join edg_current_icd10           edg on drv.icd_CODE = edg.CODE and drv.icd_type = 10
;


-- Calculate counts for QA
select DX_FLAG
,count(*) as ct
from js_xdr_WALLING_DX_LOOKUP
group by DX_FLAG;
/*
ALS	        199
ASCITES	        213
BLEEDING	86
CANCER	        13449
CHF	        5868
CIRRHOSIS	690
COPD	        621
COPD_SPO2	137
ENCEPHALOPATHY	147
ESRD	        1995
HEPATORENAL	38
PARKINSONS	250
PERITONITIS	411
*/


----------------------------------------------------------------------------
--Step 1.3:     Create driver table for all labs relevant to the study

----------------------------------------------------------------------------/
    --------------------------------------------------------------
    -- Step 1.3.1: Create table to load the labs support file
    --------------------------------------------------------------
DROP TABLE js_xdr_WALLING_LAB_DRV PURGE;
CREATE TABLE js_xdr_WALLING_LAB_DRV
   (
    "LOINC_MAPPING" VARCHAR2(20 BYTE),
	"LOINC_LONG_NAME" VARCHAR2(254 BYTE),
    "LAB_FLAG" VARCHAR2(100 BYTE)
    );

    --------------------------------------------------------------
    -- Step 1.3.2: Load lab driver support file from [XDR_WALLING_LAB_DRV.csv]
    --------------------------------------------------------------


-- Calculate counts for QA
select LAB_FLAG
,count(*) as ct
from js_xdr_WALLING_LAB_DRV
group by LAB_FLAG;

/* 
SODIUM	6
INR	1
CREATININE	9
BILIRUBIN	4
ALBUMIN	10
*/

/****************************************************************************
Step 2:     Create Denominator table

****************************************************************************/   

----------------------------------------------------------------------------
--Step 2.1:     Pull primary care Office visits in the last year WHERE patient > 18 years old
--              and the patient current PCP is a UC provider

--              appt_status_c codes in the WHERE clause exclude encounters that
--              didn't happended: "cancelled", "no shows", and "Left without seen" 
--              Look at ZC_APPT_STATUS to identify your own codes  since they are site specific.

select * from ZC_APPT_STATUS;
/*
1	Scheduled
2	Completed
3	Canceled            <----------------------
4	No Show             <----------------------
5	Left without seen   <----------------------
6	Arrived
7	Present
101	HH Incomplete
102	Pharmacy Billing Complete
*/

--          Death fucntion: at UCLA, we use the death function attached in file [XDR_WALLING_DEATH_UCLA.sql].
--          Feel free to use your own resoruces to remove deceased patients 
----------------------------------------------------------------------------
drop table js_xdr_walling_enc_list purge;
create table js_xdr_walling_enc_list as
select enc.pat_enc_csn_id
      ,enc.pat_id
      ,pat.cur_pcp_prov_id
      ,enc.effective_date_dt
      ,enc.appt_status_c
      --this is a function to calculate the vital status for the patient
      ,i2b2.f_death(pat.pat_id,2,1) as death_status
      ,enc.department_id
from pat_enc                        enc
join patient                       pat on enc.pat_id = pat.pat_id
join clarity_ser                    prov2 ON pat.cur_pcp_prov_id = prov2.PROV_ID  
                                            and prov2.user_id is not null
join js_xdr_walling_IMFP_dept_drv      dd on enc.department_id = dd.department_id
where enc.effective_date_dt between sysdate - 366 and sysdate 
        and round(months_between(TRUNC(sysdate), pat.birth_date)/12) >= 18
        and enc.enc_type_c = 101
        and (enc.appt_status_c is not null and enc.appt_status_c not in (3,4,5))
;

----------------------------------------------------------------------------
--Step 2.2:     Removed Known Deceased patients

----------------------------------------------------------------------------
delete from js_xdr_walling_enc_list 
where death_status = 'Known Deceased'; commit;

select count(*) from js_xdr_walling_enc_list;
-- 607,451 encounters

----------------------------------------------------------------------------
--Step 2.3:     Create Denominator table by pulling patient with more than two encounters

----------------------------------------------------------------------------
--Create master file based on denominator (visits) and flags based on diseases (PL and DX).
drop table js_xdr_walling_final_pat_coh purge;
create table js_xdr_walling_final_pat_coh as
select distinct coh.pat_id
      ,0 as PL_advanced_cancer
      ,0 as PL_ESLD
      ,0 as PL_COPD
      ,0 as PL_COPD_SPO2
      ,0 as PL_CHF
      ,0 as PL_ESRD
      ,0 as PL_ALS
      ,0 AS PL_CIRRHOSIS
      ,0 as DX_advanced_cancer
      ,0 as DX_ESLD
      ,0 as DX_COPD
      ,0 as dx_COPD_SPO2
      ,0 as DX_CHF
      ,0 as DX_ESRD
      ,0 as DX_ALS
      ,0 AS DX_CIRRHOSIS
      ,0 AS ANY_PL_DX
      ,case when mp.pat_id is not null then 1 else 0 end as ACTIVE_MYCHART
      ,ROUND(MONTHS_BETWEEN(CURRENT_DATE,pat.birth_date)/12) as CURRENT_AGE
from (
        select pat_id
            ,pat_enc_csn_id
            ,count(pat_enc_csn_id) over (partition by pat_id) as pat_enc_count 
        from js_xdr_walling_enc_list
                ) coh
left join clarity.patient pat on coh.pat_id = pat.pat_id
left join clarity.myc_patient mp on coh.pat_id = mp.pat_id
                    and (mp.status_cat_c is null or mp.status_cat_c = 1)                                 
    where pat_enc_count > 1 -- at least 2 encounters
;
select count(distinct pat_id) as pat_count FROM js_xdr_walling_final_pat_coh;


----------------------------------------------------------------------------
--Step 2.4:     Removed Restricted patients
--              Each site might have different codes for these patients
----------------------------------------------------------------------------

    ----------------------------------------------------------------------------
    --Step 2.4.1:     Look up flag values on your EPIC site and adapt
    --                Each site might have different codes for these patients
    ----------------------------------------------------------------------------
select * 
From ZC_BPA_TRIGGER_FYI;

/*
1018	Control
1053	Restricted Data -Permanent
6	Tracked
8	Restricted Data
9	Test Patient
*/

    ----------------------------------------------------------------------------
    --Step 2.4.2:     Removed Restricted patients

    ----------------------------------------------------------------------------
delete from js_xdr_walling_final_pat_coh 
where pat_id in 
                (
                select distinct coh.pat_id 
                from js_xdr_walling_final_pat_coh      coh
                LEFT JOIN patient_fyi_flags            flags on coh.pat_id = flags.patient_id
                LEFT JOIN patient_3                          on coh.pat_id = patient_3.pat_id
                WHERE
                            (patient_3.is_test_pat_yn = 'Y'
                            OR flags.PAT_FLAG_TYPE_C in (6,8,9,1018,1053))
            );
commit;

select count(*) from js_xdr_walling_final_pat_coh;
-- This will be considered the working denominator
-- 137,345 with 2 office visits



/****************************************************************************
Step 3:     Update PL flags in cohort table

****************************************************************************/   
----------------------------------------------------------------------------
--Step 3.1:     Pull Problem lists for each of the study related diagnoses
            
----------------------------------------------------------------------------
drop table js_xdr_walling_prob_list_all purge;
create table js_xdr_walling_prob_list_all as
SELECT DISTINCT coh.pat_id
               ,pl.problem_list_id
               ,pl.dx_id
               ,pl.description                AS prob_desc 
               ,pl.noted_date                 AS noted_date
               ,pl.date_of_entry              AS update_date
               ,pl.resolved_date              AS resolved_date
               ,zps.name                      AS problem_status            
               ,pl.hospital_pl_yn             AS hospital_problem
               ,drv.icd_code
               ,drv.ICD_DESC
               ,drv.icd_type
               ,drv.dx_flag
  FROM js_xdr_walling_final_pat_coh        coh
  JOIN patient                          pat   ON coh.pat_id = pat.pat_id
  JOIN problem_list                     pl    ON pat.pat_id = pl.pat_id AND rec_archived_yn = 'N'
  JOIN zc_problem_status                zps   ON pl.problem_status_c = zps.problem_status_c
  JOIN js_xdr_WALLING_DX_LOOKUP            drv   ON pl.dx_id = drv.dx_id
  where 
        zps.name = 'Active'
;


--gather some counts
select count(distinct pat_id) from js_xdr_walling_prob_list_all;
select dx_flag ,count(distinct pat_id)
from js_xdr_walling_prob_list_all
group by dx_flag;

----------------------------------------------------------------------------
--Step 3.2:     Update Problem List flags in cohort table
            
----------------------------------------------------------------------------
-- 1. cancer
update js_xdr_walling_final_pat_coh
set PL_ADVANCED_CANCER = 1
,any_pl_dx = 1
where pat_id in (select distinct pat_id
from js_xdr_walling_prob_list_all
WHERE DX_FLAG = 'CANCER'
);
commit;
-- 2. ALS
update js_xdr_walling_final_pat_coh
set PL_als = 1
,any_pl_dx = 1
where pat_id in (select distinct pat_id
from js_xdr_walling_prob_list_all
WHERE DX_FLAG = 'ALS'
);
commit;
-- 3. ESRD
update js_xdr_walling_final_pat_coh
set PL_esrd = 1
,any_pl_dx = 1
where pat_id in (select distinct pat_id
from js_xdr_walling_prob_list_all
WHERE DX_FLAG = 'ESRD'
);
commit;
-- 4. COPD
update js_xdr_walling_final_pat_coh
set PL_copd = 1
,any_pl_dx = 1
where pat_id in (select distinct pat_id
from js_xdr_walling_prob_list_all
WHERE DX_FLAG = 'COPD'
);
commit;
-- 5. CHF
update js_xdr_walling_final_pat_coh
set PL_CHF = 1
,any_pl_dx = 1
where pat_id in (select distinct pat_id
from js_xdr_walling_prob_list_all
WHERE DX_FLAG = 'CHF'
);
commit;
-- 6. CIRROHSIS
update js_xdr_walling_final_pat_coh
set PL_CIRRHOSIS = 1
,any_pl_dx = 1
where pat_id in (select distinct pat_id
from js_xdr_walling_prob_list_all
WHERE DX_FLAG = 'CIRRHOSIS'
);
commit;
-- 7. COPD_SPO2
update js_xdr_walling_final_pat_coh
set PL_COPD_SPO2 = 1
,any_pl_dx = 1
where pat_id in (select distinct pat_id
from js_xdr_walling_prob_list_all
WHERE DX_FLAG = 'COPD_SPO2'
);
commit;


--Gether some counts
select 
SUM(PL_ADVANCED_CANCER) as PL_ADVANCED_CANCER
,SUM(PL_ALS) as PL_ALS
,SUM(PL_ESRD) as PL_ESRD
,SUM(PL_COPD) as PL_COPD
,SUM(PL_CHF) as PL_CHF
,SUM(PL_CIRRHOSIS) as PL_CIRRHOSIS
from js_xdr_walling_final_pat_coh;



/****************************************************************************
Step 4:     Add DX flags to cohort table

****************************************************************************/   
----------------------------------------------------------------------------
--Step 4.1:     Pull "Office Visit" diagnoses in the last three years for each of the study related diagnoses
--              using the dx driver table      
--              We are investigating expanding this selection criteria to other encounter types. 
----------------------------------------------------------------------------
drop table js_xdr_walling_dx_all purge;
create table js_xdr_walling_dx_all as
select coh.pat_id
    ,enc.pat_enc_csn_id
    ,lk.ICD_CODE
    ,lk.ICD_TYPE
    ,lk.dx_flag
FROM js_xdr_walling_final_pat_coh   coh
join pat_enc_dx                     dx on coh.pat_id = dx.pat_id
join js_xdr_WALLING_DX_LOOKUP       lk on dx.dx_id = lk.dx_id 
left join pat_enc                   enc on dx.pat_enc_csn_id = enc.pat_enc_csn_id
left JOIN ZC_DISP_ENC_TYPE          enctype ON enc.enc_type_c = enctype.disp_enc_type_c
where dx.CONTACT_DATE between sysdate - (365.25 * 3) and sysdate
    AND enc.enc_type_c = 101          --"Office Visit"
commit;
----------------------------------------------------------------------------
--Step 4.2:     Update AV Diagnoses flags in cohort table
            
----------------------------------------------------------------------------

--- update flags
-- 1. cancer
update js_xdr_walling_final_pat_coh
set DX_ADVANCED_CANCER = 1
,any_pl_dx = 1
where pat_id in (select distinct pat_id
from js_xdr_walling_dx_all
WHERE DX_FLAG = 'CANCER'
);
commit;
-- 2. ALS
update js_xdr_walling_final_pat_coh
set DX_als = 1
,any_pl_dx = 1
where pat_id in (select distinct pat_id
from js_xdr_walling_dx_all
WHERE DX_FLAG = 'ALS'
);
commit;
-- 3. ESRD
update js_xdr_walling_final_pat_coh
set DX_esrd = 1
,any_pl_dx = 1
where pat_id in (select distinct pat_id
from js_xdr_walling_dx_all
WHERE DX_FLAG = 'ESRD'
);
commit;
-- 4. COPD
update js_xdr_walling_final_pat_coh
set DX_copd = 1
,any_pl_dx = 1
where pat_id in (select distinct pat_id
from js_xdr_walling_dx_all
WHERE DX_FLAG = 'COPD'
);
commit;
-- 5. CHF
update js_xdr_walling_final_pat_coh
set DX_CHF = 1
,any_pl_dx = 1
where pat_id in (select distinct pat_id
from js_xdr_walling_dx_all
WHERE DX_FLAG = 'CHF'
);
commit;
-- 6. CIRROHSIS
update js_xdr_walling_final_pat_coh
set DX_CIRRHOSIS = 1
,any_pl_dx = 1
where pat_id in (select distinct pat_id
from js_xdr_walling_dx_all
WHERE DX_FLAG = 'CIRRHOSIS'
);
commit;
-- 7. COPD_SPO2
update js_xdr_walling_final_pat_coh
set DX_COPD_SPO2 = 1
,any_pl_dx = 1
where pat_id in (select distinct pat_id
from js_xdr_walling_dx_all
WHERE DX_FLAG = 'COPD_SPO2'
);
commit;



--Gether some counts
select 
SUM(DX_ADVANCED_CANCER) as DX_ADVANCED_CANCER
,SUM(DX_ALS) as DX_ALS
,SUM(DX_PARKINSONS) as DX_PARKINSONS
,SUM(DX_ESRD) as DX_ESRD
,SUM(DX_COPD) as DX_COPD
,SUM(DX_CHF) as DX_CHF
,SUM(DX_CIRRHOSIS) as DX_CIRRHOSIS
from js_xdr_walling_final_pat_coh;


/****************************************************************************
Step 5:     Advance Directive and POLST for patients with a PL or DX that fit any of the criteria
            
****************************************************************************/   
-------------------------------------------
--Step 5. 1:      Find scanned AD/POLST docs items in ZC_DOC_INFO_TYPE
-------------------------------------------
--Query the ZC_DOC_INFO_TYPE to pull the document types at your site
SELECT * FROM ZC_DOC_INFO_TYPE;

--At UCLA Advance directive or POLST scanned doc types:
/* 
DOC_INFO_TYPE_C      Name
10                   Advance Directives and Living Will
11                   Power of Attorney
200068               DNR (Do Not Resuscitate) Documentation
200096               Advance Directive/Power of Attorney
200097               Living Will
200099               POLST
200176               Advance Directive/Power of Attorney (Non-UCSF)
620002               AD/POLST/Plan of Action/Pre-Hospital DNR/No AD
200117               Pre-hospital DNR
200118               Power of Attorney for Healthcare
72108                External Living Will
72109                External DNR
72110                External Power of Attorney
200098               Advance Directive Pamphlet - may be have to exclude this
*/

-------------------------------------------
--Step 5.2:      Checking ACP scanned documents based on your findings from previous step
--                  (this code was contributed by __________________ from UCI)
-------------------------------------------
Select AA.PAT_ID, AA.PAT_MRN_ID , BB.DOC_INFO_ID,  BB.DOC_INFO_TYPE_C, BT.NAME, BB.DOC_STAT_C,    CD.NAME as cdname,
BB.DOC_RECV_TIME,  BB.IS_SCANNED_YN,  BB.SCAN_TIME ,   BB.DOC_DESCR, BB.scan_file
From [xxx] aa   add your cohort 
inner join DOC_INFORMATION BB on AA.PAT_ID = BB.DOC_PT_ID
 left outer join ZC_DOC_INFO_TYPE BT on BB.DOC_INFO_TYPE_C = BT.DOC_INFO_TYPE_C
 left outer join ZC_DOC_STAT CD on BB.DOC_STAT_C = CD.DOC_STAT_C  
WHERE (  BB.DOC_INFO_TYPE_C in ( '10' ,'11' ,'200068' ,'200096' ,'200097' ,'200099' ,  '200117' , '200118' , '200176' , '620002' , '72108' , '72109' , '72110 ' )) 

-- also checked via descriptive criteria and getting same results 
((BT.NAME LIKE '%ADV%DIRECT%' OR BT.NAME LIKE '%ADV%CARE%PLAN%' OR BT.NAME LIKE '%GOALS OF CARE%' OR BT.NAME LIKE 'DNR %'
OR BT.NAME LIKE '% DNR%' OR BT.NAME LIKE '%DO NOT RESUSCITATE%' OR BT.NAME LIKE 'DNI %' OR BT.NAME LIKE '%DO NOT INTUBATE%' OR BT.NAME LIKE '%POLST%' 
OR BT.NAME LIKE '%CODE STATUS%' OR BT.NAME LIKE '%CODE DOC%'  OR BT.NAME LIKE '%LIVING WILL%' OR BT.NAME LIKE '%DPOA%'
OR BT.NAME LIKE '%PAT%ADVOCATE%' OR BT.NAME LIKE '%POWER%ATTORNEY%' OR BT.NAME LIKE '%LPOA%') and BT.NAME not LIKE '%PAMPHLET%' ) 

and BB.IS_SCANNED_YN = 'Y'  Getting same result, either logic can work, IS_scanned_YN or scan_file is not full 
and BB.scan_file is not null


 --Getting same result, either logic can work, IS_scanned_YN or scan_file is not full  and BB.scan_file is not null

-------------------------------------------
--Step 5. 3:      Create driver table for the AD/POLST doc types with final set of codes (use your own codes)
-------------------------------------------
CREATE TABLE XDR_WALLING_ADPOLST_DOCTYPE AS
SELECT * 
FROM ZC_DOC_INFO_TYPE
where DOC_INFO_TYPE_C in ( 
'11'        --	Power of Attorney
,'300052'	--Advance Directive Enduring
,'10'	    --Advance Directives and Living Will
,'200068'	--DNR (Do Not Resuscitate) Documentation
,'300058'	---POLST
)



-------------------------------------------
--Step 5. 4:      Classify documents into AD or POLST category
--                Upon revision of your selection, your must group the different docs into these two categories
-------------------------------------------
ALTER TABLE XDR_WALLING_ADPOLST_DOCTYPE ADD DOC_GROUP VARCHAR2(10);
UPDATE XDR_WALLING_ADPOLST_DOCTYPE
SET DOC_GROUP = 'POLST'
WHERE 
    DOC_INFO_TYPE_C  IN ('200068'       --	DNR (Do Not Resuscitate) Documentation
                        ,'300058'        --	POLST);
                        );
COMMIT;    

UPDATE XDR_WALLING_ADPOLST_DOCTYPE
SET DOC_GROUP = 'AD'
WHERE 
    DOC_INFO_TYPE_C in ( 
                        '11'        --	Power of Attorney
                      ,'300052'	--Advance Directive Enduring
                        ,'10'	    --Advance Directives and Living Will
                        );
COMMIT;

-------------------------------------------
--  Step 5.5:   Pull all scanned docs
--              
-------------------------------------------
DROP TABLE js_xdr_walling_scan_docs PURGE;
CREATE TABLE js_xdr_walling_scan_docs AS 
SELECT distinct coh.pat_id
        ,bb.doc_info_id
        ,bb.SCAN_FILE
        ,bt.name as doc_type
        ,BT.DOC_GROUP
        ,case when bb.doc_recv_time between sysdate - (365.25 *3 ) AND sysdate then 1 else 0 end three_year_ad_polst
FROM js_xdr_walling_final_pat_coh          COH  
join DOC_INFORMATION                    BB on coh.PAT_ID = BB.DOC_PT_ID
join XDR_WALLING_ADPOLST_DOCTYPE        BT on BB.DOC_INFO_TYPE_C = BT.DOC_INFO_TYPE_C
WHERE 
    ANY_PL_DX = 1
    and BB.IS_SCANNED_YN = 'Y' 
    --and bb.doc_recv_time between sysdate - (365.25 *3 ) AND sysdate  --(last three years);   
    -- We noticed that in the case of AD/POLST documents, there were instances where the docs had been deleted
    and (bb.RECORD_STATE_C <> 2 OR bb.RECORD_STATE_C IS NULL)-- Deleted
    and (bb.DOC_STAT_C <> 35  OR bb.DOC_STAT_C IS NULL)-- Error
    and bb.DOC_REVOK_DT is null
    and bb.DOC_EXPIR_TIME is null
    ;

-------------------------------------------
--  Step 5.6: Create AD/POLST table based on DOC_GROUP classification
--
-------------------------------------------
DROP TABLE js_xdr_walling_AD_POLST PURGE ;
CREATE TABLE js_xdr_walling_AD_POLST AS 
SELECT DISTINCT PAT_ID
            ,CASE WHEN POLST_ALL = 0 OR POLST_ALL IS NULL THEN 0 ELSE 1 END POLST_ALL
            ,CASE WHEN AD_ALL = 0 OR AD_ALL IS NULL THEN 0 ELSE 1 END AD_ALL
            ,CASE WHEN POLST_THREE = 0 OR POLST_THREE IS NULL THEN 0 ELSE 1 END POLST_THREE
            ,CASE WHEN AD_THREE = 0 OR AD_THREE IS NULL THEN 0 ELSE 1 END AD_THREE
FROM (
        SELECT PAT_ID
                ,SUM(POLST_ALL) AS POLST_ALL
                ,SUM(AD_ALL) AS AD_ALL
                ,SUM(POLST_THREE) AS POLST_THREE
                ,SUM(AD_THREE) AS AD_THREE
        FROM (
                SELECT DISTINCT PAT_ID
                        ,CASE WHEN DOC_GROUP = 'POLST' THEN 1 ELSE 0 END POLST_ALL
                        ,CASE WHEN DOC_GROUP  = 'AD' THEN 1 ELSE 0 END AD_ALL
                        ,CASE WHEN DOC_GROUP = 'POLST' and three_year_ad_polst = 1 THEN 1 ELSE 0 END POLST_THREE
                        ,CASE WHEN DOC_GROUP  = 'AD' and three_year_ad_polst = 1 THEN 1 ELSE 0 END AD_THREE
                FROM js_xdr_walling_scan_DOCS
                )
        GROUP BY PAT_ID
    )
;
    



-------------------------------------------
--  Step 5.7: Create and populate AD/POLST variables
-------------------------------------------
ALTER TABLE js_xdr_walling_final_pat_coh ADD AD_ALL NUMBER;
UPDATE js_xdr_walling_final_pat_coh
SET AD_ALL = 1
WHERE PAT_ID IN 
    (
        SELECT DISTINCT PAT_ID
        FROM js_xdr_walling_AD_POLST
        WHERE AD_ALL = 1
    );
COMMIT;


ALTER TABLE js_xdr_walling_final_pat_coh ADD POLST_ALL NUMBER;
UPDATE js_xdr_walling_final_pat_coh
SET POLST_ALL = 1
WHERE PAT_ID IN 
    (
        SELECT DISTINCT PAT_ID
        FROM js_xdr_walling_AD_POLST
        WHERE POLST_ALL = 1
    );
COMMIT;

ALTER TABLE js_xdr_walling_final_pat_coh ADD AD_THREE NUMBER;
UPDATE js_xdr_walling_final_pat_coh
SET AD_THREE = 1
WHERE PAT_ID IN 
    (
        SELECT DISTINCT PAT_ID
        FROM js_xdr_walling_AD_POLST
        WHERE AD_THREE = 1
    );
COMMIT;


ALTER TABLE js_xdr_walling_final_pat_coh ADD POLST_THREE NUMBER;
UPDATE js_xdr_walling_final_pat_coh
SET POLST_THREE = 1
WHERE PAT_ID IN 
    (
        SELECT DISTINCT PAT_ID
        FROM js_xdr_walling_AD_POLST
        WHERE POLST_THREE = 1
    );
COMMIT;

/****************************************************************************
Step 6:     ESLD - calculate counts
            
****************************************************************************/   

----------------------------------------------------------------------------
--Step 6.1:     Pull Labs based on lab driver LOINC codes
--               order_type_c = 7 is Lab Test, Check the codes at your site 
---------------------------------------------------------------------------- 
DROP TABLE js_xdr_walling_lab PURGE;
CREATE TABLE js_xdr_walling_lab AS 
  SELECT 	DISTINCT coh.pat_id,
                o.pat_enc_csn_id, 
                o.order_proc_id, 
                p.proc_id, 
                p.proc_code, 
                p.description, 
                o.component_id, 
                cc.name component_name, 
                p.order_time, 
                p.result_time, 
                o.result_date, 
                trim(o.ord_value) as ord_value, 
                o.ord_num_value, 
                o.reference_unit, 
                o.ref_normal_vals, 
                o.reference_low, 
                o.reference_high,
                p.order_status_c, 
                p.order_type_c,
                o.RESULT_FLAG_C,
                op2.specimn_taken_time,
                drv.LAB_FLAG,
		--If there is a relevant operator in this field ('%','<','>','='), it gets captured in its own field
                case when regexp_like(ord_value,'[%<>]=*','i') then regexp_substr(o.ord_value,'[><%]=*') else null end as harm_sign,
                trim(o.ord_value) as harm_text_val,
		/*
		In the following case statement, the code identifies three different value patterns and applies different strategies to clean the data:
		-If the result includes ':', or text, ':' it replaces with a default value. Ex 'NEGATIVE' or '12-19-08 6:45AM' --> '9999999'
		-If the result includes '<','>',or'=', the code strips that character and formats the number accordingly. Ex '<0.04' --> '0.04')
		-If the result includes '%', the code strips that character and formats the number accordingly. Ex. '28%' --> '28'
		
		All formatting shall respect decimal values
		*/
                case when regexp_like(ord_value,':','i')
                  or regexp_substr(ord_value,'[1-9]\d*(\.\,\d+)?') is null
                       then ord_num_value
                  when regexp_like(ord_value,'[<>]=*','i')
                       then to_number(regexp_substr(ord_value,'-?[[:digit:],.]*$'),'9999999999D9999999999', 'NLS_NUMERIC_CHARACTERS = ''.,''' )
                  when regexp_like(ord_value,'%','i') 
                       then to_number(regexp_substr(ord_value,'[1-9]\d*(\.\,\d+)?'),'9999999999D9999999999', 'NLS_NUMERIC_CHARACTERS = ''.,''' )
                  else ord_num_value end as harm_num_val,
                cc.common_name
              FROM order_results           o
              JOIN order_proc              p   ON p.order_proc_id = o.order_proc_id
              JOIN order_proc_2            op2 on p.ORDER_PROC_ID = op2.ORDER_PROC_ID 
              JOIN js_xdr_walling_final_pat_coh    coh ON p.pat_id = coh.pat_id AND (coh.PL_CIRRHOSIS = 1 OR COH.DX_CIRRHOSIS = 1)
              JOIN clarity_component       cc  ON o.component_id = cc.component_id
              LEFT JOIN lnc_db_main                ldm ON CC.DEFAULT_LNC_ID = ldm.record_id 
              join js_xdr_WALLING_LAB_DRV     drv ON coalesce(ldm.lnc_code, cc.loinc_code)  = drv.LOINC_MAPPING
              where 
                      p.order_type_c in (7)--, 26, 62, 63)			--double check this codes
                      --and p.ordering_date between to_date('03/01/2013','mm/dd/yyyy') and to_date('05/08/2018','mm/dd/yyyy')
                      --and p.ordering_date between to_date('03/01/2013','mm/dd/yyyy') and to_date('05/08/2018','mm/dd/yyyy')
                      and o.ord_value is not null
                      and o.order_proc_id is not null
                      AND p.order_time BETWEEN SYSDATE - (365.25 * 3) AND SYSDATE;

----------------------------------------------------------------------------
--Step 6.2:     Create MELD labs table
----------------------------------------------------------------------------
DROP table js_xdr_walling_MELD_LABS PURGE;
create table js_xdr_walling_MELD_LABS as
select * from (
select DISTINCT x.PAT_ID
                    ,x.BILIRUBIN
                    ,x.BILIRUBIN_result_time
                    ,x.INR
                    ,x.INR_result_time
                    ,x.diff_INR
                    ,x.ALBUMIN
                    ,x.ALBUMIN_result_time
                    ,x.diff_ALBUMIN
                    ,x.CREATININE
                    ,x.CREATININE_result_time
                    ,x.diff_creatinine
                    ,x.SODIUM
                    ,x.SODIUM_result_time
                    ,x.diff_SODIUM
                    ,MAX(x.BILIRUBIN_result_time) OVER (PARTITION BY x.PAT_ID) AS LATEST_LAB
 from (
         SELECT DISTINCT bili.PAT_ID
                            ,bili.result_time as BILIRUBIN_result_time
                            ,bili.harm_num_val as BILIRUBIN
                            ,inr.INR
                            ,inr.INR_result_time
                            ,ABS(bili.result_time - inr.INR_result_time) as diff_INR
                            ,alb.ALBUMIN
                            ,alb.ALBUMIN_result_time
                            ,ABS(bili.result_time - alb.ALBUMIN_result_time) as diff_ALBUMIN
                            ,cr.CREATININE
                            ,cr.CREATININE_result_time
                            ,ABS(bili.result_time - cr.CREATININE_result_time) as diff_creatinine
                            ,sod.SODIUM
                            ,sod.SODIUM_result_time
                            ,ABS(bili.result_time - sod.SODIUM_result_time) as diff_sodium
                        FROM js_xdr_walling_lab bili
                        JOIN (SELECT DISTINCT lab.PAT_ID
                                    ,lab.result_time as INR_result_time
                                    ,lab.harm_num_val as INR
                                    
                                    --,MAX(lab.result_time) OVER (PARTITION BY PAT_ID) AS LATEST_LAB
                                FROM js_xdr_walling_lab lab
                                WHERE LAB.LAB_FLAG = 'INR' AND lab.harm_num_val <> 9999999) inr on bili.pat_id = inr.pat_id and (bili.result_time - inr.INR_result_time) between -1 and 1
                        JOIN (SELECT DISTINCT lab.PAT_ID
                                    ,lab.result_time as ALBUMIN_result_time
                                    ,lab.harm_num_val as ALBUMIN
                                    
                                    --,MAX(lab.result_time) OVER (PARTITION BY PAT_ID) AS LATEST_LAB
                                FROM js_xdr_walling_lab lab
                                WHERE LAB.LAB_FLAG = 'ALBUMIN' AND lab.harm_num_val <> 9999999) alb on bili.pat_id = alb.pat_id and (bili.result_time - alb.ALBUMIN_result_time) between -1 and 1
                        JOIN (SELECT DISTINCT lab.PAT_ID
                                    ,lab.result_time as CREATININE_result_time
                                    ,lab.harm_num_val as CREATININE
                                    
                                    --,MAX(lab.result_time) OVER (PARTITION BY PAT_ID) AS LATEST_LAB
                                FROM js_xdr_walling_lab lab
                                WHERE LAB.LAB_FLAG = 'CREATININE' AND lab.harm_num_val <> 9999999) cr on bili.pat_id = cr.pat_id and (bili.result_time - cr.CREATININE_result_time) between -1 and 1                        
                        JOIN (SELECT DISTINCT lab.PAT_ID
                                    ,lab.result_time as SODIUM_result_time
                                    ,lab.harm_num_val as SODIUM
                                    
                                    --,MAX(lab.result_time) OVER (PARTITION BY PAT_ID) AS LATEST_LAB
                                FROM js_xdr_walling_lab lab
                                WHERE LAB.LAB_FLAG = 'SODIUM' AND lab.harm_num_val <> 9999999) sod on bili.pat_id = sod.pat_id and (bili.result_time - sod.SODIUM_result_time) between -1 and 1                        
                        WHERE bili.LAB_FLAG = 'BILIRUBIN' AND bili.harm_num_val <> 9999999                
                ) x
                )
                where LATEST_LAB = BILIRUBIN_result_time
                ;
                
SELECT COUNT(*),COUNT(DISTINCT PAT_ID) FROM js_xdr_walling_MELD_LABS                ;--2949	177
SELECT * FROM js_xdr_walling_MELD_LABS;


----------------------------------------------------------------------------
--Step 6.2.2:     Create final MELD table with the most recent group of labs per patient
----------------------------------------------------------------------------
DROP TABLE js_xdr_walling_MELD_LABS_FINAL PURGE;
CREATE table js_xdr_walling_MELD_LABS_FINAL as
select pat_id
        ,ALBUMIN
        ,ALBUMIN_RESULT_TIME
        ,BILIRUBIN
        ,BILIRUBIN_RESULT_TIME
        ,CREATININE
        ,CREATININE_RESULT_TIME
        ,INR
        ,INR_RESULT_TIME
        ,LATEST_LAB
        ,SODIUM
        ,SODIUM_RESULT_TIME
from (
        select pat_id
                ,ALBUMIN
                ,ALBUMIN_RESULT_TIME
                ,MIN(ABS(LATEST_LAB - ALBUMIN_RESULT_TIME)) OVER (partition by pat_id) as last_albumin
                ,ABS(LATEST_LAB - ALBUMIN_RESULT_TIME) as DIFF_ALBUMIN
                ,BILIRUBIN
                ,BILIRUBIN_RESULT_TIME
                ,CREATININE
                ,CREATININE_RESULT_TIME
                ,MIN(ABS(LATEST_LAB - CREATININE_RESULT_TIME)) OVER (partition by pat_id) as last_creatinine
                ,ABS(LATEST_LAB - CREATININE_RESULT_TIME) as DIFF_CREATININE
                ,INR
                ,INR_RESULT_TIME
                ,MIN(ABS(LATEST_LAB - INR_RESULT_TIME)) OVER (partition by pat_id) as last_inr
                ,ABS(LATEST_LAB - INR_RESULT_TIME) as DIFF_INR
                ,LATEST_LAB
                ,SODIUM
                ,SODIUM_RESULT_TIME
                ,MIN(ABS(LATEST_LAB - SODIUM_RESULT_TIME)) OVER (partition by pat_id) as last_sodium
                ,ABS(LATEST_LAB - SODIUM_RESULT_TIME) as DIFF_SODIUM
        from js_xdr_walling_MELD_LABS
        )x
where 
diff_inr = last_inr
and diff_sodium = last_sodium
and diff_albumin = last_albumin
and diff_creatinine = last_creatinine
;

select count(*), count( distinct LATEST_LAB) from js_xdr_walling_MELD_LABS_FINAL;



----------------------------------------------------------------------------
--Step 6.3:     Pull dialysis
            
----------------------------------------------------------------------------
    ----------------------------------------
    --Step 6.3.1:     Pull dialysis          
    ----------------------------------------
drop table js_xdr_walling_dialysis purge;
create table js_xdr_walling_dialysis as
SELECT DIAL.*
FROM PT_DIALYSIS_HX                 dial
JOIN js_xdr_walling_final_pat_coh    coh ON dial.pat_id = coh.pat_id AND (coh.PL_CIRRHOSIS = 1 OR COH.DX_CIRRHOSIS = 1);
 

    ----------------------------------------
    --Step 6.3.2:     Create table with patients on dialysis with 2 or more visits in the week before creatinine was measured
    ----------------------------------------
DROP table js_xdr_walling_DIALYSIS_final PURGE;
create table js_xdr_walling_DIALYSIS_final as
select pat_id, CREATININE_result_time
        from (
            select lab.pat_id
                    ,lab.CREATININE_result_time
                    ,count(dia.contact_date) dialysis_count
            from js_xdr_walling_MELD_LABS_FINAL  lab
            join js_xdr_walling_DIALYSIS          dia  on lab.pat_id = dia.pat_id and dia.CONTACT_DATE between lab.CREATININE_result_time - 7  and lab.CREATININE_result_time  
            group by lab.pat_id,lab.CREATININE_result_time
            )
        where dialysis_count >= 2;

----------------------------------------------------------------------------
--Step 6.4:     MELD calculation
            
----------------------------------------------------------------------------
DROP TABLE js_xdr_WALLING_MELD PURGE;
CREATE TABLE js_xdr_WALLING_MELD AS
select pat_id
,sodium
,Bilirubin
,creatinine
,inr
,meld + 1.32 * (137 - sodium) - (0.033 * meld * (137 - sodium)) as meld_na
from (
select pat_id
/* MELD(i) = round1[ 0.378 * loge(bilirubin)) + (1.120*loge(INR)) + (0.957*loge(creatinine)) + 0.643 ] * 10
1 rounded to the tenth decimal place.    */
,round(
    (
        (0.378 * ln(Bilirubin)) + (1.120 * ln(INR)) + ((0.957 * ln(Creatinine)) + 0.643)
    ) * 10
    ,1) as meld
,sodium
,Bilirubin
,creatinine
,inr
from(
        select 
                labs.pat_id
                ,labs.Bilirubin
                ,labs.INR
        --�	The upper limit of serum creatinine is capped at 4; in addition, if the patient had dialysis at least twice in the past week, the value for serum creatinine will be automatically adjusted to 4.0.
                ,case when labs.Creatinine > 4.0 or dia.pat_id is not null then 4.0
                    else labs.Creatinine
                    end Creatinine

                -- ,case when  dia.pat_id is not null then 1 else 0 end dialysis   
                -- ,labs.Creatinine AS ORIG_CREATININE
                --�	The lower limit of Serum Sodium (Na) is capped at 125, and the upper limit is capped at 137.
                ,case when labs.sodium > 137 then 137
                    when labs.sodium < 125 then 125
                    else labs.sodium
                    end sodium
        from js_xdr_walling_final_pat_coh     coh
        JOIN js_xdr_walling_MELD_LABS_FINAL                  LABS ON COH.PAT_ID = LABS.PAT_ID
        left join js_xdr_walling_DIALYSIS_final        dia on labs.pat_id = dia.pat_id and labs.CREATININE_RESULT_TIME = dia.CREATININE_RESULT_TIME
        )
);

select count(*), count(distinct pat_id) from js_xdr_WALLING_MELD;--733	733
--------------------------------------------------------------
-- Step 6.5: Create and populate ESLD decompensation variables
--------------------------------------------------------------
ALTER TABLE js_xdr_walling_final_pat_coh add  pl_ESDL_decompensation number;
update js_xdr_walling_final_pat_coh
set pl_ESDL_decompensation  = 1 
WHERE PAT_ID in 
(SELECT DISTINCT PAT_ID
            from js_xdr_walling_prob_list_all
            WHERE
            (DX_flag = 'ASCITES'
            OR dx_flag = 'BLEEDING'
            OR dx_flag = 'ENCEPHALOPATHY'
            OR dx_flag = 'HEPATORENAL'
            OR dx_flag = 'PERITONITIS')
            );
COMMIT;

ALTER TABLE js_xdr_walling_final_pat_coh add  DX_ESDL_decompensation number;
update js_xdr_walling_final_pat_coh
set DX_ESDL_decompensation  = 1 
WHERE PAT_ID in 
(SELECT DISTINCT PAT_ID
            from js_xdr_walling_DX_all
            WHERE
            (DX_flag = 'ASCITES'
            OR dx_flag = 'BLEEDING'
            OR dx_flag = 'ENCEPHALOPATHY'
            OR dx_flag = 'HEPATORENAL'
            OR dx_flag = 'PERITONITIS')
            );
COMMIT;

ALTER TABLE js_xdr_walling_final_pat_coh ADD  ALBUMIN NUMBER;
update js_xdr_walling_final_pat_coh
set ALBUMIN  = 1 
WHERE PAT_ID in 
(select DISTINCT X.PAT_ID
        FROM (
                SELECT PAT_ID
                    ,ORDER_TIME
                    ,harm_num_val
                    ,MAX(ORDER_TIME) OVER (PARTITION BY PAT_ID) AS LATEST_LAB
                FROM js_xdr_walling_lab
                WHERE LAB_FLAG = 'ALBUMIN'
            )x  
        where latest_lab = x.ORDER_TIME
        and x.harm_num_val < 3);
commit;

ALTER TABLE js_xdr_walling_final_pat_coh ADD INR NUMBER;
update js_xdr_walling_final_pat_coh
set INR  = 1 
WHERE PAT_ID in 
(select DISTINCT X.PAT_ID
        FROM (
                SELECT PAT_ID
                    ,ORDER_TIME
                    ,harm_num_val
                    ,MAX(ORDER_TIME) OVER (PARTITION BY PAT_ID) AS LATEST_LAB
                FROM js_xdr_walling_lab
                WHERE LAB_FLAG = 'INR'
            )x  
        where latest_lab = x.ORDER_TIME
        and x.harm_num_val > 1.3);
commit;

ALTER TABLE js_xdr_walling_final_pat_coh ADD  MELD NUMBER;
update js_xdr_walling_final_pat_coh
set MELD  = 1 
WHERE PAT_ID in 
(select DISTINCT PAT_ID
        FROM js_xdr_walling_meld
        where meld_na > 19);
commit;

--------------------------------------------------------------
-- Step 6.6 Create and update ESLD criteria flag
--              PL cirrhosis + [hepatic decompensation (PL or dx) or MELD >18]
--------------------------------------------------------------
ALTER TABLE js_xdr_walling_final_pat_coh ADD ESDL_A NUMBER;
UPDATE js_xdr_walling_final_pat_coh
SET ESDL_A = 1
WHERE
    PAT_ID IN (select PAT_ID
                from js_xdr_walling_final_pat_coh
                WHERE
                    PL_CIRRHOSIS = 1
                    and (
                        pl_ESDL_decompensation = 1 
                        OR dx_ESDL_decompensation = 1
                        )
                );
COMMIT;

ALTER TABLE js_xdr_walling_final_pat_coh ADD ESDL_B NUMBER;
UPDATE js_xdr_walling_final_pat_coh
SET ESDL_B = 1
WHERE
    PAT_ID IN (select PAT_ID
                from js_xdr_walling_final_pat_coh
                WHERE
                    PL_CIRRHOSIS = 1
                    and MELD = 1
                );
COMMIT;
----------------------------------------------------
--Step 6.7  GATHER COUNTS
----------------------------------------------------
SELECT 
        pl_ESDL_decompensation
        ,dx_ESDL_decompensation
        ,ALBUMIN
        ,INR
        ,MELD 
        ,ESDL_A
        ,ESDL_B
        ,AD_THREE
        ,AD_ALL
        ,POLST_THREE
        ,POLST_ALL
        ,ACTIVE_MYCHART
        ,COUNT(DISTINCT PAT_ID) 
FROM js_xdr_walling_final_pat_coh
WHERE ESDL_A = 1 or ESDL_B = 1
group by pl_ESDL_decompensation
        ,dx_ESDL_decompensation
        ,ALBUMIN
        ,INR
        ,MELD 
        ,ESDL_A
        ,ESDL_B
        ,AD_THREE
        ,AD_ALL
        ,POLST_THREE
        ,POLST_ALL
        ,ACTIVE_MYCHART;

----------------------------------------------------
--Step 6.8  Pull sample for chart review. Export to xlsx file
----------------------------------------------------
select mrn
        ,pl_ESDL_decompensation
        ,dx_ESDL_decompensation
        ,ALBUMIN
        ,INR
        ,MELD 
        ,ESDL_A
        ,ESDL_B
        ,AD_THREE
        ,AD_ALL
        ,POLST_THREE
        ,POLST_ALL
        ,ACTIVE_MYCHART
        ,'PL cirrhosis + [hepatic decompensation (PL or dx)' as sample_group
        --These are placeholder fields to be filled out by the Investigator reviewing the charts
        ,NULL as "Advanced condition?"
        ,NULL as "Advanced Illness Group"
        ,NULL as "Notes"
        ,NULL as "ACP Priority"
        ,NULL as "Necessary	AD/POLST"
        ,NULL as "Right?"
        ,NULL as "Notes"
        ,NULL as "Year"        
from (
        SELECT ROWNUM AS RECORD_ID
                ,pat.pat_mrn_id as mrn
                ,coh.*
        FROM js_xdr_walling_final_pat_coh  coh
        join patient                        pat on coh.pat_id = pat.pat_id
        where
            ESDL_B = 1
        ORDER BY dbms_random.random)
WHERE RECORD_ID < 11
UNION ALL
select mrn
        ,pl_ESDL_decompensation
        ,dx_ESDL_decompensation
        ,ALBUMIN
        ,INR
        ,MELD 
        ,ESDL_A
        ,ESDL_B
        ,AD_THREE
        ,AD_ALL
        ,POLST_THREE
        ,POLST_ALL
        ,ACTIVE_MYCHART
        ,'PL cirrhosis or MELD >18' as sample_group
        --These are placeholder fields to be filled out by the Investigator reviewing the charts
        ,NULL as "Advanced Illness Group"
        ,NULL as "Advanced condition?"
        ,NULL as "Notes"
        ,NULL as "ACP Priority"
        ,NULL as "Necessary	AD/POLST"
        ,NULL as "Right?"
        ,NULL as "Notes"
        ,NULL as "Year"        
from (
        SELECT ROWNUM AS RECORD_ID
                ,pat.pat_mrn_id as mrn
                ,coh.*
        FROM js_xdr_walling_final_pat_coh  coh
        join patient                        pat on coh.pat_id = pat.pat_id
        where
            ESDL_A = 1
        ORDER BY dbms_random.random)
WHERE RECORD_ID < 11
;                

/****************************************************************************
Step 7:     Advanced cancer
            
****************************************************************************/  

--------------------------------------------------------------
-- Step 7.1: Pull Oncology Office visits
--------------------------------------------------------------
DROP TABLE js_xdr_walling_onc PURGE;
CREATE TABLE js_xdr_walling_onc AS
SELECT DISTINCT  PAT.PAT_ID
                ,enc.PAT_ENC_CSN_ID
                ,enc.EFFECTIVE_DATE_DT
                ,dep.specialty 
                ,prv.primary_specialty
FROM js_xdr_walling_final_pat_coh          coh
JOIN PAT_ENC                            enc on coh.pat_id = enc.pat_id
JOIN PATIENT                            pat ON COH.PAT_ID = PAT.PAT_ID
LEFT JOIN CLARITY_DEP                   dep ON enc.department_id = dep.department_id
LEFT JOIN v_cube_d_provider             prv ON enc.visit_prov_id = prv.provider_id
WHERE 
--with advanced cancer
    (coh.PL_ADVANCED_CANCER = 1 OR COH.DX_ADVANCED_CANCER = 1)
    AND
            (REGEXP_LIKE(dep.specialty,'Oncology','i')
            OR
            REGEXP_LIKE(prv.primary_specialty,'Oncology','i')
            )
    and enc.enc_type_c = 101
    AND enc.EFFECTIVE_DATE_DT between sysdate - (365.25 * 2) AND sysdate
    ; 
select count(*), count(distinct pat_id) from js_xdr_walling_onc                ;--14300	1240  
--------------------------------------------------------------
-- Step 7.2: Classify patients based on the oncology visit threshold
--------------------------------------------------------------
ALTER TABLE js_xdr_walling_final_pat_coh ADD ONC_VISIT varchar2(25);
MERGE INTO js_xdr_walling_final_pat_coh coh
USING
(select pat_id
        ,case when MONTHS_BETWEEN(SYSDATE,LAST_ENC_DATE) < 6 then 'SIX MONTHS'
              when MONTHS_BETWEEN(SYSDATE,LAST_ENC_DATE) < 12 then 'ONE YEAR'
              when MONTHS_BETWEEN(SYSDATE,LAST_ENC_DATE) BETWEEN 12 AND 24 then 'TWO YEAR'
              ELSE 'NO VISIT'
        END ONC_VISIT
        ,LAST_ENC_DATE
from 
    (select pat_id
            ,max(EFFECTIVE_DATE_DT) AS LAST_ENC_DATE
    from js_xdr_walling_onc
    group by pat_id) 
    )r
 ON 
(coh.pat_id = r.pat_id)
WHEN MATCHED THEN
update SET ONC_VISIT = r.ONC_VISIT
;
COMMIT;


SELECT ONC_VISIT,COUNT(*) FROM js_xdr_walling_final_pat_coh GROUP BY ONC_VISIT;


--------------------------------------------------------------
-- Step 7.3: Pull Chemotherapy procedures
--------------------------------------------------------------
DROP TABLE js_xdr_walling_PRC_chemo PURGE;
CREATE TABLE js_xdr_walling_PRC_chemo AS
SELECT DISTINCT coh.pat_id
               ,cpt.pat_enc_csn_id
               ,enc.EFFECTIVE_DATE_DT          AS proc_date
               ,'CPT'                     AS proc_type
               ,cpt.cpt_code              AS proc_code 
               ,eap.proc_name 
  FROM js_xdr_walling_final_pat_coh          coh
  JOIN pat_enc                  enc on coh.pat_id = enc.pat_id
  JOIN arpb_transactions                  cpt  ON enc.pat_enc_csn_id = cpt.pat_enc_csn_id 
  LEFT JOIN clarity_eap eap  ON cpt.cpt_code = eap.proc_code
WHERE
    (coh.PL_ADVANCED_CANCER = 1 OR COH.DX_ADVANCED_CANCER = 1)
    AND
    CPT.cpt_code in ('96401' ,'96402' ,'96405' ,'96406' ,'96409' ,'96411' ,'96413' ,'96415','96416','96417' ,'96423'
                    ,'96420', '96422', '96425', '96440','96446', '96450')
AND TRUNC(enc.EFFECTIVE_DATE_DT ) BETWEEN sysdate - (365.25 * 2) AND sysdate
          AND tx_type_c = 1					-----  Charges only
          AND void_date is null 
UNION
SELECT DISTINCT coh.pat_id
               ,tx.pat_enc_csn_id
               ,tx.SERVICE_DATE          AS proc_date
               ,'CPT'               AS proc_type
               ,tx.cpt_code              AS proc_code 
               ,eap.proc_name 
  FROM js_xdr_walling_final_pat_coh          coh
  join  hsp_account                     acc on coh.pat_id = acc.pat_id 
  JOIN HSP_TRANSACTIONS                  tx  ON acc.HSP_ACCOUNT_ID = tx.HSP_ACCOUNT_ID 
  JOIN pat_enc                  enc on tx.pat_enc_csn_id = enc.pat_enc_csn_id
  LEFT JOIN clarity_eap eap  ON tx.cpt_code = eap.proc_code
WHERE
    (coh.PL_ADVANCED_CANCER = 1 OR COH.DX_ADVANCED_CANCER = 1)
    AND
    tx.cpt_code in ('96401' ,'96402' ,'96405' ,'96406' ,'96409' ,'96411' ,'96413' ,'96415','96416','96417' ,'96423'
                    ,'96420', '96422', '96425', '96440','96446', '96450')
AND TRUNC(enc.EFFECTIVE_DATE_DT ) BETWEEN sysdate - (365.25 * 2) AND sysdate
;
select count(*), count(distinct pat_id) from js_xdr_walling_PRC_chemo                ;--11108	588


--------------------------------------------------------------
-- Step 7.4: Pull Chemotherapy medications
--          m.medication_id != 800001 is used to excluded dummy records in the UCLA system
--------------------------------------------------------------
DROP TABLE js_xdr_WALLING_med_CHEMO PURGE;
CREATE TABLE js_xdr_WALLING_med_CHEMO AS
select med1.*,
        xmrs.NAME                                                       AS result,
        cm.name medication_name, 
        cm.generic_name
FROM (
        SELECT  m.pat_id,
            m.pat_enc_csn_id, 
            m.order_med_id, 
            m.ordering_date, 
            m.start_date,
            m.end_date,
          case when m.medication_id != 800001 then m.medication_id
               else coalesce(omi.dispensable_med_id, m.user_sel_med_id) end as used_med_id,        
            zom.name as ordering_mode,
            zoc.name as order_class
        FROM js_xdr_walling_final_pat_coh      coh
        JOIN order_med                      m   ON coh.pat_id = m.pat_id
        LEFT JOIN order_medinfo omi on m.order_med_id = omi.order_med_id
        left join zc_order_class zoc on m.order_class_C = zoc.order_class_c
        left join zc_ordering_mode zom on m.ordering_mode_c = zom.ordering_mode_c
        WHERE 
            (coh.PL_ADVANCED_CANCER = 1 OR COH.DX_ADVANCED_CANCER = 1)
            AND TRUNC(m.ordering_date) BETWEEN sysdate - (365.25 * 2) AND sysdate
            and zoc.name <> 'Historical Med'
    ) med1
LEFT JOIN clarity_medication cm on med1.used_med_id = cm.medication_id
LEFT JOIN mar_admin_info  mar   ON med1.order_med_id = mar.order_med_id
LEFT JOIN zc_mar_rslt     xmrs  ON mar.mar_action_c = xmrs.result_c

WHERE 
  (
  (med1.ordering_mode = 'Inpatient'                                       
            AND nvl(mar.taken_time,to_date('01/01/0001')) <> '01/01/0001'       -- taken_time was valid
            AND nvl(mar.sig,-1) > 0                                             -- and SIG was valid and > 0
            AND nvl(mar.mar_action_c,-1) <> 125                                 -- and action was anything other than 'Not Given'
         ) 
         OR med1.ordering_mode != 'Inpatient'
        )
    AND med1.used_med_id IS NOT NULL
    AND (
        cm.pharm_subclass_c in (2150) 
        or regexp_like(cm.name,'chemo','i')
        or regexp_like(cm.generic_name,'chemo','i')
    )
;

--------------------------------------------------------------
-- Step 7.5: Combine Chemotherapy procedures and medications
--------------------------------------------------------------
drop TABLE js_xdr_WALLING_CHEMO purge;
CREATE TABLE js_xdr_WALLING_CHEMO AS
SELECT DISTINCT CHE.PAT_ID
            ,PAT.PAT_MRN_ID
        ,CHE.PROC_DATE AS CHEMO_DATE
FROM js_xdr_walling_PRC_chemo  CHE
JOIN patient PAT ON CHE.PAT_ID = PAT.PAT_ID
UNION
SELECT DISTINCT CHE.PAT_ID
            ,PAT.PAT_MRN_ID
        ,CHE.ORDERING_DATE  AS CHEMO_DATE
FROM js_xdr_WALLING_med_CHEMO      CHE
JOIN patient PAT ON CHE.PAT_ID = PAT.PAT_ID
;

SELECT COUNT(*),COUNT(DISTINCT PAT_ID) FROM js_xdr_WALLING_CHEMO;      --7575	626


--------------------------------------------------------------
-- Step 7.6: Create and update chemotherapy criteria flag
--------------------------------------------------------------
ALTER TABLE js_xdr_walling_final_pat_coh ADD CHEMO_TIMEFRAME varchar2(25);
MERGE INTO js_xdr_walling_final_pat_coh coh
USING
(select pat_id
        ,case when MONTHS_BETWEEN(SYSDATE,LAST_ENC_DATE) < 6 then 'SIX MONTHS'
              when MONTHS_BETWEEN(SYSDATE,LAST_ENC_DATE) < 12 then 'ONE YEAR'
              when MONTHS_BETWEEN(SYSDATE,LAST_ENC_DATE) BETWEEN 12 AND 24 then 'TWO YEAR'
              ELSE 'NO VISIT'
        END CHEMO_TIMEFRAME
        ,LAST_ENC_DATE
from 
    (select pat_id
            ,max(CHEMO_DATE) AS LAST_ENC_DATE
    from js_xdr_WALLING_CHEMO
    group by pat_id)
    )r
 ON 
(coh.pat_id = r.pat_id)
WHEN MATCHED THEN
update SET coh.CHEMO_TIMEFRAME = r.CHEMO_TIMEFRAME
;
COMMIT;

SELECT CHEMO_TIMEFRAME,COUNT(*) FROM js_xdr_walling_final_pat_coh GROUP BY CHEMO_TIMEFRAME;
--------------------------------------------------------------
-- Step 7.7: Create and update CANCER criteria flag
--
--          Criteria PL + Oncology visit last year
--          Criteria: AV(DX) + chemotherapy last two years
--------------------------------------------------------------
ALTER TABLE js_xdr_walling_final_pat_coh ADD CANCER_A NUMBER;

UPDATE js_xdr_walling_final_pat_coh
SET CANCER_A = 1
WHERE
    PAT_ID IN (
                SELECT DISTINCT PAT_ID
                FROM js_xdr_walling_final_pat_coh
                WHERE
                    --Criteria PL + Oncology visit last year
                    PL_ADVANCED_CANCER = 1 AND ONC_VISIT IN ('SIX MONTHS','ONE YEAR')
                )
;      --897
COMMIT;

ALTER TABLE js_xdr_walling_final_pat_coh ADD CANCER_B NUMBER;
UPDATE js_xdr_walling_final_pat_coh
SET CANCER_B = 1
WHERE
    PAT_ID IN (
                SELECT DISTINCT PAT_ID
                FROM js_xdr_walling_final_pat_coh
                WHERE
                    --Criteria: AV(DX) + chemotherapy last two years
                    DX_ADVANCED_CANCER = 1 AND CHEMO_TIMEFRAME is NOT NULL AND CHEMO_TIMEFRAME <> 'NO VISIT'
                )
;      --897
COMMIT;

--------------------------------------------------------------
-- Step 7.8: Gather counts
--------------------------------------------------------------
SELECT 
        pl_ADVANCED_CANCER
        ,DX_ADVANCED_CANCER
        ,ONC_VISIT
        ,CHEMO_TIMEFRAME
        ,AD_THREE
        ,AD_ALL
        ,POLST_THREE
        ,POLST_ALL
        ,ACTIVE_MYCHART
        ,CANCER_A
        ,CANCER_B
,COUNT(DISTINCT PAT_ID) 
FROM js_xdr_walling_final_pat_coh
WHERE CANCER_A = 1 or CANCER_B = 1
group by pl_ADVANCED_CANCER
        ,DX_ADVANCED_CANCER
        ,ONC_VISIT
        ,CHEMO_TIMEFRAME
        ,AD_THREE
        ,AD_ALL
        ,POLST_THREE
        ,POLST_ALL
        ,ACTIVE_MYCHART
        ,CANCER_A
        ,CANCER_B;
----------------------------------------------------
--Step 7.9  Pull sample for chart review. Export to xlsx file
----------------------------------------------------
select mrn
        ,pl_ADVANCED_CANCER
        ,DX_ADVANCED_CANCER
        ,ONC_VISIT
        ,CHEMO_TIMEFRAME
        ,AD_THREE
        ,AD_ALL
        ,POLST_THREE
        ,POLST_ALL
        ,ACTIVE_MYCHART
        ,CANCER_A
        ,CANCER_B
        ,'PL + Oncology visit last year' as sample_group
        --These are placeholder fields to be filled out by the Investigator reviewing the charts
        ,NULL as "Advanced condition?"
        ,NULL as "Advanced Illness Group"
        ,NULL as "Notes"
        ,NULL as "ACP Priority"
        ,NULL as "Necessary	AD/POLST"
        ,NULL as "Right?"
        ,NULL as "Notes"
        ,NULL as "Year"        
from (
        SELECT ROWNUM AS RECORD_ID
                ,pat.pat_mrn_id as mrn
                ,coh.*
        FROM js_xdr_walling_final_pat_coh  coh
        join patient                        pat on coh.pat_id = pat.pat_id
        where
            CANCER_A = 1
        ORDER BY dbms_random.random)
WHERE RECORD_ID < 11
UNION ALL
select mrn
        ,pl_ADVANCED_CANCER
        ,DX_ADVANCED_CANCER
        ,ONC_VISIT
        ,CHEMO_TIMEFRAME
        ,AD_THREE
        ,AD_ALL
        ,POLST_THREE
        ,POLST_ALL
        ,ACTIVE_MYCHART
        ,CANCER_A
        ,CANCER_B
        ,'AV(DX) + chemotherapy last two years' as sample_group
        --These are placeholder fields to be filled out by the Investigator reviewing the charts
        ,NULL as "Advanced Illness Group"
        ,NULL as "Advanced condition?"
        ,NULL as "Notes"
        ,NULL as "ACP Priority"
        ,NULL as "Necessary	AD/POLST"
        ,NULL as "Right?"
        ,NULL as "Notes"
        ,NULL as "Year"        
from (
        SELECT ROWNUM AS RECORD_ID
                ,pat.pat_mrn_id as mrn
                ,coh.*
        FROM js_xdr_walling_final_pat_coh  coh
        join patient                        pat on coh.pat_id = pat.pat_id
        where
            CANCER_B = 1
        ORDER BY dbms_random.random)
WHERE RECORD_ID < 11
;

/****************************************************************************
Step 8:     CHF
            
****************************************************************************/ 
-------------------------------------------
--  Step 8.1:     Pull records for admission with a CHF diagnosis (not necessarily principal)
-------------------------------------------
DROP TABLE js_xdr_WALLING_CHF_HOSP PURGE; 
CREATE TABLE js_xdr_WALLING_CHF_HOSP AS 
SELECT DISTINCT coh.pat_id, 
	    dx.pat_enc_csn_id, 
	    dx.contact_date, 
	    lk.ICD_CODE,
        lk.ICD_DESC,
        lk.ICD_TYPE,
        enc.hosp_admsn_time, 
        enc.hosp_disch_time
FROM js_xdr_walling_final_pat_coh    coh
JOIN pat_enc_hsp                enc ON coh.pat_id = enc.pat_id
JOIN pat_enc_dx             dx ON enc.pat_enc_csn_id = dx.pat_enc_csn_id
join js_xdr_walling_dx_lookup  LK on dx.dx_id = lk.dx_id AND lk.DX_FLAG = 'CHF'
WHERE 
    (coh.PL_CHF = 1 OR coh.dx_CHF = 1)
    AND dx.contact_date BETWEEN sysdate - 365.25 AND sysdate
;
SELECT COUNT(*), COUNT(DISTINCT PAT_ID)  FROM js_xdr_WALLING_CHF_HOSP;      --4832	802
-------------------------------------------
--  Step 8.2:    Create and update CHF hospitalization criteria flag
-------------------------------------------
ALTER TABLE js_xdr_walling_final_pat_coh ADD CHF_HOSP NUMBER;
UPDATE js_xdr_walling_final_pat_coh
SET CHF_HOSP = 1
WHERE PAT_ID IN 
    (
        SELECT DISTINCT PAT_ID
        FROM js_xdr_WALLING_CHF_HOSP
    );
COMMIT;


-------------------------------------------
--  Step 8.3:     Pull and calculate LVEF values
-------------------------------------------
-- The attached script [XDR_WALLING_LVEF_UCLA.sql] generates the table XDR_WALLING_LVEF_FINAL
-- with the results of the patients EF test

-------------------------------------------
--  Step 8.4:     Create and update LVEF flag in cohort table based on criteria (=<31)
-------------------------------------------
ALTER TABLE js_xdr_walling_final_pat_coh ADD LVEF NUMBER;

update js_xdr_walling_final_pat_coh
set LVEF = 1
where 
    pat_id in (select distinct pat_id
            from JS_XDR_WALLING_LVEF_FINAL
            WHERE lvef_final_value in ('1','2','3','4','5','6','7','8','9'
            ,'10','11','12','13','14','15','16','17','18','19','20'
            ,'21','22','23','24','25','26','27','28','29','30','31')
            );
commit;--588 rows updated.

-------------------------------------------
--  Step 8.5:     Create and update CHF criteria flag

--        CHF_A: Any ambulatory CHF diagnosis (including PL) and any EF < 31%  OR
--        CHF_B: PL and 1 admission with a CHF diagnosis (not necessarily principal)
------------------------------------------
ALTER TABLE js_xdr_walling_final_pat_coh ADD CHF_A NUMBER;
UPDATE js_xdr_walling_final_pat_coh
SET CHF_A = 1
WHERE PAT_ID IN (
                select DISTINCT PAT_ID
                from js_xdr_walling_final_pat_coh 
                where
                    --Criteria: (PL OR AV(DX)) AND EF < 31
                    (PL_CHF = 1 OR DX_CHF = 1) AND LVEF = 1
                )
;--586 rows updated.
COMMIT;
ALTER TABLE js_xdr_walling_final_pat_coh ADD CHF_B NUMBER;
UPDATE js_xdr_walling_final_pat_coh
SET CHF_B = 1
WHERE PAT_ID IN (
                select DISTINCT PAT_ID
                from js_xdr_walling_final_pat_coh 
                where
                    --Criteria: (PL) AND CHF admission
                    PL_CHF = 1  AND CHF_HOSP = 1
                    );--713 rows updated.
COMMIT;                    
-------------------------------------------
--  Step 8.6:     calculate counts
-------------------------------------------
SELECT 
        PL_CHF
        ,DX_CHF
        ,LVEF
        ,CHF_HOSP
        ,AD_THREE
        ,AD_ALL
        ,POLST_THREE
        ,POLST_ALL
        ,ACTIVE_MYCHART
        ,CHF_A
        ,CHF_B
,COUNT(DISTINCT PAT_ID) 
FROM js_xdr_walling_final_pat_coh
WHERE CHF_A = 1 or CHF_B = 1
group by  PL_CHF
        ,DX_CHF
        ,LVEF
        ,CHF_HOSP
        ,AD_THREE
        ,AD_ALL
        ,POLST_THREE
        ,POLST_ALL
        ,ACTIVE_MYCHART
        ,CHF_A
        ,CHF_B;

----------------------------------------------------
--Step 8.7  Pull sample for chart review. Export to xlsx file
----------------------------------------------------
select mrn
        ,PL_CHF
        ,DX_CHF
        ,LVEF
        ,CHF_HOSP
        ,AD_THREE
        ,AD_ALL
        ,POLST_THREE
        ,POLST_ALL
        ,ACTIVE_MYCHART
        ,CHF_A
        ,CHF_B
        ,'(PL OR AV(DX)) AND EF < 31' as sample_group
        --These are placeholder fields to be filled out by the Investigator reviewing the charts
        ,NULL as "Advanced condition?"
        ,NULL as "Advanced Illness Group"
        ,NULL as "Notes"
        ,NULL as "ACP Priority"
        ,NULL as "Necessary	AD/POLST"
        ,NULL as "Right?"
        ,NULL as "Notes"
        ,NULL as "Year"        
from (
        SELECT ROWNUM AS RECORD_ID
                ,pat.pat_mrn_id as mrn
                ,coh.*
        FROM js_xdr_walling_final_pat_coh  coh
        join patient                        pat on coh.pat_id = pat.pat_id
        where
            CHF_A = 1
        ORDER BY dbms_random.random)
WHERE RECORD_ID < 11
UNION ALL
select mrn
        ,PL_CHF
        ,DX_CHF
        ,LVEF
        ,CHF_HOSP
        ,AD_THREE
        ,AD_ALL
        ,POLST_THREE
        ,POLST_ALL
        ,ACTIVE_MYCHART
        ,CHF_A
        ,CHF_B
        ,'(PL) AND CHF admission' as sample_group
        --These are placeholder fields to be filled out by the Investigator reviewing the charts
        ,NULL as "Advanced Illness Group"
        ,NULL as "Advanced condition?"
        ,NULL as "Notes"
        ,NULL as "ACP Priority"
        ,NULL as "Necessary	AD/POLST"
        ,NULL as "Right?"
        ,NULL as "Notes"
        ,NULL as "Year"        
from (
        SELECT ROWNUM AS RECORD_ID
                ,pat.pat_mrn_id as mrn
                ,coh.*
        FROM js_xdr_walling_final_pat_coh  coh
        join patient                        pat on coh.pat_id = pat.pat_id
        where
            CHF_B = 1
        ORDER BY dbms_random.random)
WHERE RECORD_ID < 11
;

/****************************************************************************
Step 9:     COPD
            
****************************************************************************/ 

-------------------------------------------
--  Step 9.1:     Pull hospitzalizations in the last 12 months
-------------------------------------------
DROP TABLE js_xdr_WALLING_COPD_HSP PURGE; 
CREATE TABLE js_xdr_WALLING_COPD_HSP AS 
SELECT DISTINCT coh.pat_id, 
	    dx.pat_enc_csn_id, 
	    dx.contact_date, 
	    lk.ICD_CODE,
        lk.ICD_DESC,
        lk.ICD_TYPE,
        enc.hosp_admsn_time, 
        enc.hosp_disch_time
FROM js_xdr_walling_final_pat_coh    coh
JOIN pat_enc_hsp                enc ON coh.pat_id = enc.pat_id
JOIN pat_enc_dx             dx ON enc.pat_enc_csn_id = dx.pat_enc_csn_id
join js_xdr_walling_dx_lookup  LK on dx.dx_id = lk.dx_id AND lk.DX_FLAG = 'COPD'
WHERE 
    (coh.PL_COPD = 1 OR coh.dx_COPD = 1)
    AND dx.contact_date BETWEEN SYSDATE - 365.25 AND SYSDATE --)'05/31/2017' AND '05/30/2018'
;

-------------------------------------------
--  Step 9.2:     Create and update hospitzalizations flag
-------------------------------------------
ALTER TABLE js_xdr_walling_final_pat_coh ADD COPD_HOSP NUMBER;
UPDATE js_xdr_walling_final_pat_coh
SET COPD_HOSP = 1
WHERE PAT_ID IN 
    (
        SELECT DISTINCT PAT_ID
        FROM js_xdr_WALLING_COPD_HSP
    );
COMMIT;


--------------------------------------------------------------
--  Step 9.3:     Create and update COPD criteria flag
--
--              PL and 1 admission with a COPD diagnosis (not necessarily principal)
--------------------------------------------------------------
ALTER TABLE js_xdr_walling_final_pat_coh ADD COPD NUMBER;

UPDATE js_xdr_walling_final_pat_coh
SET COPD = 1
WHERE
    PAT_ID IN (
                SELECT DISTINCT PAT_ID
                FROM js_xdr_walling_final_pat_coh
                WHERE
                    --PL and 1 admission with a COPD diagnosis (not necessarily principal)
                    PL_COPD = 1 
                AND  
                    (
                        
                            PL_COPD_SPO2 = 1
                            OR
                            DX_COPD_SPO2 = 1
                         
                        OR COPD_HOSP = 1
                    )
                )
;
COMMIT;
-------------------------------------------
--  Step 9.4:     calculate counts
-------------------------------------------
SELECT 
        PL_COPD
        ,DX_COPD
        ,COPD_HOSP
        ,PL_COPD_SPO2
        ,DX_COPD_SPO2
        ,AD_THREE
        ,AD_ALL
        ,POLST_THREE
        ,POLST_ALL
        ,ACTIVE_MYCHART
,COUNT(DISTINCT PAT_ID) 
FROM js_xdr_walling_final_pat_coh
WHERE copd = 1
group by PL_COPD
        ,DX_COPD
        ,COPD_HOSP
        ,PL_COPD_SPO2
        ,DX_COPD_SPO2
        ,AD_THREE
        ,AD_ALL
        ,POLST_THREE
        ,POLST_ALL
        ,ACTIVE_MYCHART;


----------------------------------------------------
--Step 9.5:  Pull sample for chart review. Export to xlsx file
----------------------------------------------------
select mrn
        ,PL_COPD
        ,DX_COPD
        ,PL_COPD_SPO2
        ,DX_COPD_SPO2
        ,COPD_HOSP
        ,AD_THREE
        ,AD_ALL
        ,POLST_THREE
        ,POLST_ALL
        ,ACTIVE_MYCHART
        ,'PL and 1 admission with a COPD diagnosis (not necessarily principal)' as sample_group
        --These are placeholder fields to be filled out by the Investigator reviewing the charts
        ,NULL as "Advanced Illness Group"
        ,NULL as "Advanced condition?"
        ,NULL as "Notes"
        ,NULL as "ACP Priority"
        ,NULL as "Necessary	AD/POLST"
        ,NULL as "Right?"
        ,NULL as "Notes"
        ,NULL as "Year"        
from (
        SELECT ROWNUM AS RECORD_ID
                ,pat.pat_mrn_id as mrn
                ,coh.*
        FROM js_xdr_walling_final_pat_coh  coh
        join patient                        pat on coh.pat_id = pat.pat_id
        where
            COPD = 1
        ORDER BY dbms_random.random)
WHERE RECORD_ID < 11
;          


/****************************************************************************
Step 10:     ALS
            
****************************************************************************/ 
--------------------------------------------------------------
--  Step 10.1:     Create and update ALS criteria flag
--
--              PL and DX
--------------------------------------------------------------
ALTER TABLE js_xdr_walling_final_pat_coh ADD ALS NUMBER;

UPDATE js_xdr_walling_final_pat_coh
SET ALS = 1
WHERE
    PAT_ID IN (
                SELECT DISTINCT PAT_ID
                FROM js_xdr_walling_final_pat_coh
                WHERE
                    --PL and 1 admission with a COPD diagnosis (not necessarily principal)
                    PL_ALS = 1 AND DX_ALS = 1
                )
;
COMMIT;
-------------------------------------------
--  Step 10.2:     calculate counts
-------------------------------------------
SELECT 
        PL_ALS
        ,DX_ALS
        ,AD_THREE
        ,AD_ALL
        ,POLST_THREE
        ,POLST_ALL
        ,ACTIVE_MYCHART
,COUNT(DISTINCT PAT_ID) 
FROM js_xdr_walling_final_pat_coh
WHERE ALS = 1
group by PL_ALS
        ,DX_ALS
        ,AD_THREE
        ,AD_ALL
        ,POLST_THREE
        ,POLST_ALL
        ,ACTIVE_MYCHART;


----------------------------------------------------
--Step 10.3:  Pull sample for chart review. Export to xlsx file
----------------------------------------------------
select mrn
        ,PL_ALS
        ,DX_ALS
        ,AD_THREE
        ,AD_ALL
        ,POLST_THREE
        ,POLST_ALL
        ,ACTIVE_MYCHART
        ,'PL and 1 DX' as sample_group
        --These are placeholder fields to be filled out by the Investigator reviewing the charts
        ,NULL as "Advanced Illness Group"
        ,NULL as "Advanced condition?"
        ,NULL as "Notes"
        ,NULL as "ACP Priority"
        ,NULL as "Necessary	AD/POLST"
        ,NULL as "Right?"
        ,NULL as "Notes"
        ,NULL as "Year"        
from (
        SELECT ROWNUM AS RECORD_ID
                ,pat.pat_mrn_id as mrn
                ,coh.*
        FROM js_xdr_walling_final_pat_coh  coh
        join patient                        pat on coh.pat_id = pat.pat_id
        where
            ALS = 1
        ORDER BY dbms_random.random)
WHERE RECORD_ID < 11
;          




--[PL = 1 or DX >= 1] and Nephrology visit (inpt or ambulatory) in the past year
/****************************************************************************
Step 11:    ESRD
            
****************************************************************************/  
--------------------------------------------------------------
-- Step 11.1: Pull Nephrology visit (inpt or ambulatory) in the past year
--------------------------------------------------------------
DROP TABLE js_xdr_walling_neph PURGE;
CREATE TABLE js_xdr_walling_neph AS
SELECT DISTINCT  PAT.PAT_ID
                ,enc.PAT_ENC_CSN_ID
                ,enc.EFFECTIVE_DATE_DT
                ,dep.specialty 
                ,prv.primary_specialty
FROM js_xdr_walling_final_pat_coh          coh
JOIN PAT_ENC                            enc on coh.pat_id = enc.pat_id
JOIN PATIENT                            pat ON COH.PAT_ID = PAT.PAT_ID
LEFT JOIN CLARITY_DEP                   dep ON enc.department_id = dep.department_id
LEFT JOIN v_cube_d_provider             prv ON enc.visit_prov_id = prv.provider_id
WHERE 
--with ESRD
    (coh.PL_ESRD = 1 OR COH.DX_ESRD = 1)
    AND
            (REGEXP_LIKE(dep.specialty,'Neph','i')
            OR
            REGEXP_LIKE(prv.primary_specialty,'Neph','i')
            )
    AND enc.EFFECTIVE_DATE_DT between '05/31/2017' AND '05/30/2018'
    ; 
select count(*), count(distinct pat_id) from js_xdr_walling_neph                ;--10524	580



--------------------------------------------------------------
-- Step 11.2: Create and update NEPH_VISIT criteria flag
--
--------------------------------------------------------------
ALTER TABLE js_xdr_walling_final_pat_coh ADD NEPH_VISIT NUMBER;

UPDATE js_xdr_walling_final_pat_coh
SET NEPH_VISIT = 1
WHERE
    PAT_ID IN (
                SELECT DISTINCT PAT_ID
                FROM js_xdr_walling_neph
                )
;      --897
COMMIT;

--------------------------------------------------------------
-- Step 11.3: Create and update ESRD criteria flag
--
--------------------------------------------------------------
ALTER TABLE js_xdr_walling_final_pat_coh ADD ESRD NUMBER;

UPDATE js_xdr_walling_final_pat_coh
SET ESRD = 1
WHERE
    (
       (PL_ESRD = 1 OR DX_ESRD = 1 )
        AND NEPH_VISIT = 1
    )
    OR
    (PL_ESRD = 1 AND DX_ESRD = 1)
;      --897
COMMIT;

--------------------------------------------------------------
-- Step 11.4: Gather counts
--------------------------------------------------------------
SELECT 
        PL_ESRD
        ,DX_ESRD
        ,NEPH_VISIT
        ,AD_THREE
        ,AD_ALL
        ,POLST_THREE
        ,POLST_ALL
        ,ACTIVE_MYCHART
,COUNT(DISTINCT PAT_ID) 
FROM js_xdr_walling_final_pat_coh
WHERE PL_ESRD = 1 OR DX_ESRD = 1
group by PL_ESRD
        ,DX_ESRD
        ,NEPH_VISIT
        ,AD_THREE
        ,AD_ALL
        ,POLST_THREE
        ,POLST_ALL;

----------------------------------------------------
--Step 11.5  Pull sample for chart review. Export to xlsx file
----------------------------------------------------
select mrn
        ,PL_ESRD
        ,DX_ESRD
        ,NEPH_VISIT
        ,AD_THREE
        ,AD_ALL
        ,POLST_THREE
        ,POLST_ALL
        ,ACTIVE_MYCHART
        ,'[PL = 1 or DX >= 1] and Nephrology visit (inpt or ambulatory) in the past year' as sample_group
        --These are placeholder fields to be filled out by the Investigator reviewing the charts
        ,NULL as "Advanced condition?"
        ,NULL as "Advanced Illness Group"
        ,NULL as "Notes"
        ,NULL as "ACP Priority"
        ,NULL as "Necessary	AD/POLST"
        ,NULL as "Right?"
        ,NULL as "Notes"
        ,NULL as "Year"        
from (
        SELECT ROWNUM AS RECORD_ID
                ,pat.pat_mrn_id as mrn
                ,coh.*
        FROM js_xdr_walling_final_pat_coh  coh
        join patient                        pat on coh.pat_id = pat.pat_id
        where
            (PL_ESRD = 1 OR DX_ESRD = 1 )
            AND NEPH_VISIT = 1
        ORDER BY dbms_random.random)
WHERE RECORD_ID < 11
UNION
select mrn
        ,PL_ESRD
        ,DX_ESRD
        ,NEPH_VISIT
        ,AD_THREE
        ,AD_ALL
        ,POLST_THREE
        ,POLST_ALL
        ,ACTIVE_MYCHART
        ,'[PL = 1 AND DX = 1]' as sample_group
        --These are placeholder fields to be filled out by the Investigator reviewing the charts
        ,NULL as "Advanced condition?"
        ,NULL as "Advanced Illness Group"
        ,NULL as "Notes"
        ,NULL as "ACP Priority"
        ,NULL as "Necessary	AD/POLST"
        ,NULL as "Right?"
        ,NULL as "Notes"
        ,NULL as "Year"        
from (
        SELECT ROWNUM AS RECORD_ID
                ,pat.pat_mrn_id as mrn
                ,coh.*
        FROM js_xdr_walling_final_pat_coh  coh
        join patient                        pat on coh.pat_id = pat.pat_id
        where
            (PL_ESRD = 1 AND DX_ESRD = 1 )
        ORDER BY dbms_random.random)
WHERE RECORD_ID < 11;

/****************************************************************************
Step 12:     Age Criteria
            
****************************************************************************/ 
--------------------------------------------------------------
--  Step 12.1:     Create additional flags to calculate criteria aggregated coutns
--
--------------------------------------------------------------
--Flag patients that fit any of the criterion
ALTER TABLE js_xdr_walling_final_pat_coh ADD ANY_CRITERIA number;
UPDATE js_xdr_walling_final_pat_coh
SET ANY_CRITERIA = 1
WHERE
        copd = 1
        OR CHF_A = 1
        OR CHF_B = 1
        OR als = 1
        OR ESDL_A = 1
        OR ESDL_B = 1
        OR cancer_a = 1
        OR cancer_b = 1
        OR esrd = 1;
COMMIT;

--create elements for age criteira counts
ALTER TABLE js_xdr_walling_final_pat_coh ADD PL_AGG number;
ALTER TABLE js_xdr_walling_final_pat_coh ADD copd_alt number;
ALTER TABLE js_xdr_walling_final_pat_coh ADD chf_alt number;
ALTER TABLE js_xdr_walling_final_pat_coh ADD esrd_alt number;
ALTER TABLE js_xdr_walling_final_pat_coh ADD als_alt number;
ALTER TABLE js_xdr_walling_final_pat_coh ADD ADVANCED_CANCER_alt number;
MERGE INTO js_xdr_walling_final_pat_coh coh
USING 
(select pat_id
                --aggregate all the PL diagnosis across conditions.
                ,pl_copd + pl_chf + PL_ESRD + PL_ALS + PL_ADVANCED_CANCER AS PL_AGG
                --identify which patients have both type of dx for each condition (PL and encounter)
                ,case when pl_copd = 1 and dx_copd = 1 then 1 else 0 end copd_alt
                ,case when pl_chf = 1 and dx_chf = 1 then 1 else 0 end chf_alt
                ,case when pl_esrd = 1 and dx_esrd = 1 then 1 else 0 end esrd_alt
                ,case when pl_als = 1 and dx_als = 1 then 1 else 0 end als_alt
                ,case when PL_ADVANCED_CANCER = 1 and DX_ADVANCED_CANCER = 1 then 1 else 0 end ADVANCED_CANCER_alt
        from js_xdr_walling_final_pat_coh 
        where 
                --age limit (initial cut-off date to gather counts)
                current_age >= 65
                --patient not already in one of the criteria (exclude patietns already selected for any of the existing criterion)
                and ANY_CRITERIA IS NULL) r
                ON
                (coh.pat_id = r.pat_id)
                WHEN MATCHED THEN
                UPDATE SET PL_AGG = R.PL_AGG
                ,copd_alt = r.copd_alt
                ,chf_alt = r.chf_alt
                ,esrd_alt = r.esrd_alt
                ,als_alt = r.als_alt
                ,ADVANCED_CANCER_alt = r.ADVANCED_CANCER_alt;
commit;


-------------------------------------------------------------------
-- Step 12.2     Pull aggregates records to explore in excel (i e, pivot table) if needed.
-------------------------------------------------------------------
select 
current_age
,pl_agg
,(ADVANCED_CANCER_alt + copd_alt + chf_alt + esrd_alt + als_alt) as condition_agg
,case when AD_ALL = 1 or POLST_ALL = 1 then 1 else 0 end ad_polst_all
,case when AD_THREE = 1 or POLST_THREE = 1 then 1 else 0 end ad_polst_three
,count(*) 
from js_xdr_walling_final_pat_coh
where 
        --patient in one of the criteria
        ANY_CRITERIA is null
        and current_age >=65
group by 
current_age
,pl_agg
,(ADVANCED_CANCER_alt + copd_alt + chf_alt + esrd_alt + als_alt)
,case when AD_ALL = 1 or POLST_ALL = 1 then 1 else 0 end
,case when AD_THREE = 1 or POLST_THREE = 1 then 1 else 0 end 
order by current_age
;


-------------------------------------------------------------------
-- Step 12.3     Pull counts to fill out age criteria exploration sheet
--               [Total cohort numbers table - Age Criteria.docx]
-------------------------------------------------------------------

/*-------------------------------------------------------------------
      Generate counts for report

For the total cohort numbers you will have to add the different counts for each group within each criteria

For instance, in the "All current serious illness definitions" section, reuslts from the query are
1	0	401	All current serious illness definitions 
1	1	676	All current serious illness definitions 
0	0	1912	All current serious illness definitions 
Total cohort numbers: 401 + 676 + 1,912 = 2,989
ACP ever: 401 + 676 = 1,077
ACP 3y = 676
*/-------------------------------------------------------------------
select 
case when AD_ALL = 1 or POLST_ALL = 1 then 1 else 0 end ad_polst_all
,case when AD_THREE = 1 or POLST_THREE = 1 then 1 else 0 end ad_polst_three
,count(*)
,'All current serious illness definitions ' as criteria
from js_xdr_walling_final_pat_coh 
where 
        --patient in one of the criteria
        ANY_CRITERIA = 1
group by 
case when AD_ALL = 1 or POLST_ALL = 1 then 1 else 0 end
,case when AD_THREE = 1 or POLST_THREE = 1 then 1 else 0 end

UNION ALL

select 
case when AD_ALL = 1 or POLST_ALL = 1 then 1 else 0 end ad_polst_all
,case when AD_THREE = 1 or POLST_THREE = 1 then 1 else 0 end ad_polst_three
,count(*) 
,'2 dx in the problem list if >=65' as criteria
from js_xdr_walling_final_pat_coh
where 
        --patient NOT in one of the criteria
        ANY_CRITERIA IS NULL
        AND PL_AGG >= 2
        and current_age >= 65
group by 
case when AD_ALL = 1 or POLST_ALL = 1 then 1 else 0 end
,case when AD_THREE = 1 or POLST_THREE = 1 then 1 else 0 end 


UNION ALL

select 
case when AD_ALL = 1 or POLST_ALL = 1 then 1 else 0 end ad_polst_all
,case when AD_THREE = 1 or POLST_THREE = 1 then 1 else 0 end ad_polst_three
,count(*) 
,'2 dx in the problem list if >=75 as criteria' as criteria
from js_xdr_walling_final_pat_coh
where 
        --patient NOT in one of the criteria
        ANY_CRITERIA IS NULL
        AND PL_AGG >= 2
        and current_age >= 75
group by 
case when AD_ALL = 1 or POLST_ALL = 1 then 1 else 0 end
,case when AD_THREE = 1 or POLST_THREE = 1 then 1 else 0 end 


UNION ALL

select 
case when AD_ALL = 1 or POLST_ALL = 1 then 1 else 0 end ad_polst_all
,case when AD_THREE = 1 or POLST_THREE = 1 then 1 else 0 end ad_polst_three
,count(*) 
,'2 dx in the problem list AND encounter codes if >=65' as criteria
from js_xdr_walling_final_pat_coh
where 
        --patient NOT in one of the criteria
        ANY_CRITERIA IS NULL
        and current_age >= 65
        and (ADVANCED_CANCER_alt + copd_alt + chf_alt + esrd_alt + als_alt)  >= 2
group by 
case when AD_ALL = 1 or POLST_ALL = 1 then 1 else 0 end
,case when AD_THREE = 1 or POLST_THREE = 1 then 1 else 0 end 

UNION ALL

select 
case when AD_ALL = 1 or POLST_ALL = 1 then 1 else 0 end ad_polst_all
,case when AD_THREE = 1 or POLST_THREE = 1 then 1 else 0 end ad_polst_three
,count(*) 
,'2 dx in the problem list AND encounter codes if >=75' as criteria
from js_xdr_walling_final_pat_coh
where 
        --patient NOT in one of the criteria
        ANY_CRITERIA IS NULL
        AND current_age >= 75
        and (ADVANCED_CANCER_alt + copd_alt + chf_alt + esrd_alt + als_alt)  >= 2
group by 
case when AD_ALL = 1 or POLST_ALL = 1 then 1 else 0 end
,case when AD_THREE = 1 or POLST_THREE = 1 then 1 else 0 end 


UNION ALL

select 
case when AD_ALL = 1 or POLST_ALL = 1 then 1 else 0 end ad_polst_all
,case when AD_THREE = 1 or POLST_THREE = 1 then 1 else 0 end ad_polst_three
,count(*) 
,'1 dx in the problem list if >=65' as criteria
from js_xdr_walling_final_pat_coh
where 
        --patient NOT in one of the criteria
        ANY_CRITERIA IS NULL
        AND PL_AGG >= 1
        and current_age >= 65
group by 
case when AD_ALL = 1 or POLST_ALL = 1 then 1 else 0 end
,case when AD_THREE = 1 or POLST_THREE = 1 then 1 else 0 end 


UNION ALL

select 
case when AD_ALL = 1 or POLST_ALL = 1 then 1 else 0 end ad_polst_all
,case when AD_THREE = 1 or POLST_THREE = 1 then 1 else 0 end ad_polst_three
,count(*) 
,'1 dx in the problem list if >=75' as criteria
from js_xdr_walling_final_pat_coh
where 
        --patient NOT in one of the criteria
        ANY_CRITERIA IS NULL
        AND PL_AGG >= 1
        and current_age >= 75
group by 
case when AD_ALL = 1 or POLST_ALL = 1 then 1 else 0 end
,case when AD_THREE = 1 or POLST_THREE = 1 then 1 else 0 end 
;
-------------------------------------------------------------------
-- Step 12.4     Create Age Criteria flag for '1 dx in the problem list if >=75' as criteria
-------------------------------------------------------------------
ALTER TABLE js_xdr_walling_final_pat_coh ADD AGE_CRITERIA NUMBER;
UPDATE js_xdr_walling_final_pat_coh
SET AGE_CRITERIA = 1
WHERE 
        ANY_CRITERIA IS NULL
        AND PL_AGG >= 1
        and current_age >= 75;
COMMIT;

/****************************************************************************
Step 13:     gather comprehensive counts across all criterion
            
****************************************************************************/   

-------------------------------------------------------------------
-- Step 13.1     Consolidate criteria with +1 subgroups into one (CHF, ESLD, and Advanced Cancer)
-------------------------------------------------------------------

alter table js_xdr_walling_final_pat_coh add cancer number;

update js_xdr_walling_final_pat_coh
set cancer = 1
where
cancer_a = 1
or cancer_b = 1;
commit;

alter table js_xdr_walling_final_pat_coh add esld number;

update js_xdr_walling_final_pat_coh
set ESLD = 1
where
ESDL_A = 1
or ESDL_B = 1;
commit;


alter table js_xdr_walling_final_pat_coh add CHF number;

update js_xdr_walling_final_pat_coh
set CHF = 1
where
CHF_A = 1
or CHF_B = 1;
commit;

-------------------------------------------------------------------
-- Step 13.2     Pull stratified counts report for each criteria
-------------------------------------------------------------------
select
criteria
,sum(AD_POLST_NEVER) as AD_POLST_NEVER
,sum(AD_POLST_MORE_THAN_THREE) as AD_POLST_MORE_THAN_THREE
,sum(AD_POLST_THREE_OR_LESS) as AD_POLST_THREE_OR_LESS
,SUM(TOTAL_PATIENTS) AS TOTAL_PATIENTS
FROM (
SELECT
CRITERIA
,case when AD_POLST = 'AD_POLST_NEVER' then TOTAL_PATIENTS end AD_POLST_NEVER
,case when AD_POLST = 'AD_POLST_MORE_THAN_THREE' then TOTAL_PATIENTS end AD_POLST_MORE_THAN_THREE
,case when AD_POLST = 'AD_POLST_THREE_OR_LESS' then TOTAL_PATIENTS end AD_POLST_THREE_OR_LESS
,TOTAL_PATIENTS
FROM(
select 
'ADVANCED CANCER' AS CRITERIA
,CASE WHEN AD_THREE = 1 OR POLST_THREE = 1 THEN 'AD_POLST_THREE_OR_LESS'
      WHEN AD_ALL = 1 OR POLST_ALL = 1 THEN 'AD_POLST_MORE_THAN_THREE'
      ELSE 'AD_POLST_NEVER'
END AD_POLST
,SUM(CANCER) as TOTAL_PATIENTS
from js_xdr_walling_final_pat_coh
WHERE CANCER = 1
GROUP BY 
CASE WHEN AD_THREE = 1 OR POLST_THREE = 1 THEN 'AD_POLST_THREE_OR_LESS'
      WHEN AD_ALL = 1 OR POLST_ALL = 1 THEN 'AD_POLST_MORE_THAN_THREE'
      ELSE 'AD_POLST_NEVER'
END
))
GROUP BY CRITERIA

UNION ALL

select
criteria
,sum(AD_POLST_NEVER) as AD_POLST_NEVER
,sum(AD_POLST_MORE_THAN_THREE) as AD_POLST_MORE_THAN_THREE
,sum(AD_POLST_THREE_OR_LESS) as AD_POLST_THREE_OR_LESS
,SUM(TOTAL_PATIENTS) AS TOTAL_PATIENTS
FROM (
SELECT
CRITERIA
,case when AD_POLST = 'AD_POLST_NEVER' then TOTAL_PATIENTS end AD_POLST_NEVER
,case when AD_POLST = 'AD_POLST_MORE_THAN_THREE' then TOTAL_PATIENTS end AD_POLST_MORE_THAN_THREE
,case when AD_POLST = 'AD_POLST_THREE_OR_LESS' then TOTAL_PATIENTS end AD_POLST_THREE_OR_LESS
,TOTAL_PATIENTS
FROM(
select 
'CANCER_A' AS CRITERIA
,CASE WHEN AD_THREE = 1 OR POLST_THREE = 1 THEN 'AD_POLST_THREE_OR_LESS'
      WHEN AD_ALL = 1 OR POLST_ALL = 1 THEN 'AD_POLST_MORE_THAN_THREE'
      ELSE 'AD_POLST_NEVER'
END AD_POLST
,SUM(CANCER_A) as TOTAL_PATIENTS
from js_xdr_walling_final_pat_coh
WHERE CANCER_A = 1
GROUP BY 
CASE WHEN AD_THREE = 1 OR POLST_THREE = 1 THEN 'AD_POLST_THREE_OR_LESS'
      WHEN AD_ALL = 1 OR POLST_ALL = 1 THEN 'AD_POLST_MORE_THAN_THREE'
      ELSE 'AD_POLST_NEVER'
END
))
GROUP BY CRITERIA

UNION ALL

select
criteria
,sum(AD_POLST_NEVER) as AD_POLST_NEVER
,sum(AD_POLST_MORE_THAN_THREE) as AD_POLST_MORE_THAN_THREE
,sum(AD_POLST_THREE_OR_LESS) as AD_POLST_THREE_OR_LESS
,SUM(TOTAL_PATIENTS) AS TOTAL_PATIENTS
FROM (
SELECT
CRITERIA
,case when AD_POLST = 'AD_POLST_NEVER' then TOTAL_PATIENTS end AD_POLST_NEVER
,case when AD_POLST = 'AD_POLST_MORE_THAN_THREE' then TOTAL_PATIENTS end AD_POLST_MORE_THAN_THREE
,case when AD_POLST = 'AD_POLST_THREE_OR_LESS' then TOTAL_PATIENTS end AD_POLST_THREE_OR_LESS
,TOTAL_PATIENTS
FROM(
select 
'CANCER_B' AS CRITERIA
,CASE WHEN AD_THREE = 1 OR POLST_THREE = 1 THEN 'AD_POLST_THREE_OR_LESS'
      WHEN AD_ALL = 1 OR POLST_ALL = 1 THEN 'AD_POLST_MORE_THAN_THREE'
      ELSE 'AD_POLST_NEVER'
END AD_POLST
,SUM(CANCER_B) as TOTAL_PATIENTS
from js_xdr_walling_final_pat_coh
WHERE CANCER_B = 1
GROUP BY 
CASE WHEN AD_THREE = 1 OR POLST_THREE = 1 THEN 'AD_POLST_THREE_OR_LESS'
      WHEN AD_ALL = 1 OR POLST_ALL = 1 THEN 'AD_POLST_MORE_THAN_THREE'
      ELSE 'AD_POLST_NEVER'
END
))
GROUP BY CRITERIA

UNION ALL

select
criteria
,sum(AD_POLST_NEVER) as AD_POLST_NEVER
,sum(AD_POLST_MORE_THAN_THREE) as AD_POLST_MORE_THAN_THREE
,sum(AD_POLST_THREE_OR_LESS) as AD_POLST_THREE_OR_LESS
,SUM(TOTAL_PATIENTS) AS TOTAL_PATIENTS
FROM (
SELECT
CRITERIA
,case when AD_POLST = 'AD_POLST_NEVER' then TOTAL_PATIENTS end AD_POLST_NEVER
,case when AD_POLST = 'AD_POLST_MORE_THAN_THREE' then TOTAL_PATIENTS end AD_POLST_MORE_THAN_THREE
,case when AD_POLST = 'AD_POLST_THREE_OR_LESS' then TOTAL_PATIENTS end AD_POLST_THREE_OR_LESS
,TOTAL_PATIENTS
FROM(
select 
'ALS' AS CRITERIA
,CASE WHEN AD_THREE = 1 OR POLST_THREE = 1 THEN 'AD_POLST_THREE_OR_LESS'
      WHEN AD_ALL = 1 OR POLST_ALL = 1 THEN 'AD_POLST_MORE_THAN_THREE'
      ELSE 'AD_POLST_NEVER'
END AD_POLST
,SUM(ALS) as TOTAL_PATIENTS
from js_xdr_walling_final_pat_coh
WHERE ALS = 1
GROUP BY 
CASE WHEN AD_THREE = 1 OR POLST_THREE = 1 THEN 'AD_POLST_THREE_OR_LESS'
      WHEN AD_ALL = 1 OR POLST_ALL = 1 THEN 'AD_POLST_MORE_THAN_THREE'
      ELSE 'AD_POLST_NEVER'
END
))
GROUP BY CRITERIA

UNION ALL

select
criteria
,sum(AD_POLST_NEVER) as AD_POLST_NEVER
,sum(AD_POLST_MORE_THAN_THREE) as AD_POLST_MORE_THAN_THREE
,sum(AD_POLST_THREE_OR_LESS) as AD_POLST_THREE_OR_LESS
,SUM(TOTAL_PATIENTS) AS TOTAL_PATIENTS
FROM (
SELECT
CRITERIA
,case when AD_POLST = 'AD_POLST_NEVER' then TOTAL_PATIENTS end AD_POLST_NEVER
,case when AD_POLST = 'AD_POLST_MORE_THAN_THREE' then TOTAL_PATIENTS end AD_POLST_MORE_THAN_THREE
,case when AD_POLST = 'AD_POLST_THREE_OR_LESS' then TOTAL_PATIENTS end AD_POLST_THREE_OR_LESS
,TOTAL_PATIENTS
FROM(
select 
'CHF' AS CRITERIA
,CASE WHEN AD_THREE = 1 OR POLST_THREE = 1 THEN 'AD_POLST_THREE_OR_LESS'
      WHEN AD_ALL = 1 OR POLST_ALL = 1 THEN 'AD_POLST_MORE_THAN_THREE'
      ELSE 'AD_POLST_NEVER'
END AD_POLST
,SUM(CHF) as TOTAL_PATIENTS
from js_xdr_walling_final_pat_coh
WHERE CHF = 1
GROUP BY 
CASE WHEN AD_THREE = 1 OR POLST_THREE = 1 THEN 'AD_POLST_THREE_OR_LESS'
      WHEN AD_ALL = 1 OR POLST_ALL = 1 THEN 'AD_POLST_MORE_THAN_THREE'
      ELSE 'AD_POLST_NEVER'
END
))
GROUP BY CRITERIA

UNION ALL

select
criteria
,sum(AD_POLST_NEVER) as AD_POLST_NEVER
,sum(AD_POLST_MORE_THAN_THREE) as AD_POLST_MORE_THAN_THREE
,sum(AD_POLST_THREE_OR_LESS) as AD_POLST_THREE_OR_LESS
,SUM(TOTAL_PATIENTS) AS TOTAL_PATIENTS
FROM (
SELECT
CRITERIA
,case when AD_POLST = 'AD_POLST_NEVER' then TOTAL_PATIENTS end AD_POLST_NEVER
,case when AD_POLST = 'AD_POLST_MORE_THAN_THREE' then TOTAL_PATIENTS end AD_POLST_MORE_THAN_THREE
,case when AD_POLST = 'AD_POLST_THREE_OR_LESS' then TOTAL_PATIENTS end AD_POLST_THREE_OR_LESS
,TOTAL_PATIENTS
FROM(
select 
'CHF_A' AS CRITERIA
,CASE WHEN AD_THREE = 1 OR POLST_THREE = 1 THEN 'AD_POLST_THREE_OR_LESS'
      WHEN AD_ALL = 1 OR POLST_ALL = 1 THEN 'AD_POLST_MORE_THAN_THREE'
      ELSE 'AD_POLST_NEVER'
END AD_POLST
,SUM(CHF_A) as TOTAL_PATIENTS
from js_xdr_walling_final_pat_coh
WHERE CHF_A = 1
GROUP BY 
CASE WHEN AD_THREE = 1 OR POLST_THREE = 1 THEN 'AD_POLST_THREE_OR_LESS'
      WHEN AD_ALL = 1 OR POLST_ALL = 1 THEN 'AD_POLST_MORE_THAN_THREE'
      ELSE 'AD_POLST_NEVER'
END
))
GROUP BY CRITERIA

UNION ALL

select
criteria
,sum(AD_POLST_NEVER) as AD_POLST_NEVER
,sum(AD_POLST_MORE_THAN_THREE) as AD_POLST_MORE_THAN_THREE
,sum(AD_POLST_THREE_OR_LESS) as AD_POLST_THREE_OR_LESS
,SUM(TOTAL_PATIENTS) AS TOTAL_PATIENTS
FROM (
SELECT
CRITERIA
,case when AD_POLST = 'AD_POLST_NEVER' then TOTAL_PATIENTS end AD_POLST_NEVER
,case when AD_POLST = 'AD_POLST_MORE_THAN_THREE' then TOTAL_PATIENTS end AD_POLST_MORE_THAN_THREE
,case when AD_POLST = 'AD_POLST_THREE_OR_LESS' then TOTAL_PATIENTS end AD_POLST_THREE_OR_LESS
,TOTAL_PATIENTS
FROM(
select 
'CHF_B' AS CRITERIA
,CASE WHEN AD_THREE = 1 OR POLST_THREE = 1 THEN 'AD_POLST_THREE_OR_LESS'
      WHEN AD_ALL = 1 OR POLST_ALL = 1 THEN 'AD_POLST_MORE_THAN_THREE'
      ELSE 'AD_POLST_NEVER'
END AD_POLST
,SUM(CHF_B) as TOTAL_PATIENTS
from js_xdr_walling_final_pat_coh
WHERE CHF_B = 1
GROUP BY 
CASE WHEN AD_THREE = 1 OR POLST_THREE = 1 THEN 'AD_POLST_THREE_OR_LESS'
      WHEN AD_ALL = 1 OR POLST_ALL = 1 THEN 'AD_POLST_MORE_THAN_THREE'
      ELSE 'AD_POLST_NEVER'
END
))
GROUP BY CRITERIA

UNION ALL

select
criteria
,sum(AD_POLST_NEVER) as AD_POLST_NEVER
,sum(AD_POLST_MORE_THAN_THREE) as AD_POLST_MORE_THAN_THREE
,sum(AD_POLST_THREE_OR_LESS) as AD_POLST_THREE_OR_LESS
,SUM(TOTAL_PATIENTS) AS TOTAL_PATIENTS
FROM (
SELECT
CRITERIA
,case when AD_POLST = 'AD_POLST_NEVER' then TOTAL_PATIENTS end AD_POLST_NEVER
,case when AD_POLST = 'AD_POLST_MORE_THAN_THREE' then TOTAL_PATIENTS end AD_POLST_MORE_THAN_THREE
,case when AD_POLST = 'AD_POLST_THREE_OR_LESS' then TOTAL_PATIENTS end AD_POLST_THREE_OR_LESS
,TOTAL_PATIENTS
FROM(
select 
'COPD' AS CRITERIA
,CASE WHEN AD_THREE = 1 OR POLST_THREE = 1 THEN 'AD_POLST_THREE_OR_LESS'
      WHEN AD_ALL = 1 OR POLST_ALL = 1 THEN 'AD_POLST_MORE_THAN_THREE'
      ELSE 'AD_POLST_NEVER'
END AD_POLST
,SUM(COPD) as TOTAL_PATIENTS
from js_xdr_walling_final_pat_coh
WHERE COPD = 1
GROUP BY 
CASE WHEN AD_THREE = 1 OR POLST_THREE = 1 THEN 'AD_POLST_THREE_OR_LESS'
      WHEN AD_ALL = 1 OR POLST_ALL = 1 THEN 'AD_POLST_MORE_THAN_THREE'
      ELSE 'AD_POLST_NEVER'
END
))
GROUP BY CRITERIA

UNION ALL

select
criteria
,sum(AD_POLST_NEVER) as AD_POLST_NEVER
,sum(AD_POLST_MORE_THAN_THREE) as AD_POLST_MORE_THAN_THREE
,sum(AD_POLST_THREE_OR_LESS) as AD_POLST_THREE_OR_LESS
,SUM(TOTAL_PATIENTS) AS TOTAL_PATIENTS
FROM (
SELECT
CRITERIA
,case when AD_POLST = 'AD_POLST_NEVER' then TOTAL_PATIENTS end AD_POLST_NEVER
,case when AD_POLST = 'AD_POLST_MORE_THAN_THREE' then TOTAL_PATIENTS end AD_POLST_MORE_THAN_THREE
,case when AD_POLST = 'AD_POLST_THREE_OR_LESS' then TOTAL_PATIENTS end AD_POLST_THREE_OR_LESS
,TOTAL_PATIENTS
FROM(
select 
'ESLD' AS CRITERIA
,CASE WHEN AD_THREE = 1 OR POLST_THREE = 1 THEN 'AD_POLST_THREE_OR_LESS'
      WHEN AD_ALL = 1 OR POLST_ALL = 1 THEN 'AD_POLST_MORE_THAN_THREE'
      ELSE 'AD_POLST_NEVER'
END AD_POLST
,SUM(ESLD) as TOTAL_PATIENTS
from js_xdr_walling_final_pat_coh
WHERE ESLD = 1
GROUP BY 
CASE WHEN AD_THREE = 1 OR POLST_THREE = 1 THEN 'AD_POLST_THREE_OR_LESS'
      WHEN AD_ALL = 1 OR POLST_ALL = 1 THEN 'AD_POLST_MORE_THAN_THREE'
      ELSE 'AD_POLST_NEVER'
END
))
GROUP BY CRITERIA

UNION ALL

select
criteria
,sum(AD_POLST_NEVER) as AD_POLST_NEVER
,sum(AD_POLST_MORE_THAN_THREE) as AD_POLST_MORE_THAN_THREE
,sum(AD_POLST_THREE_OR_LESS) as AD_POLST_THREE_OR_LESS
,SUM(TOTAL_PATIENTS) AS TOTAL_PATIENTS
FROM (
SELECT
CRITERIA
,case when AD_POLST = 'AD_POLST_NEVER' then TOTAL_PATIENTS end AD_POLST_NEVER
,case when AD_POLST = 'AD_POLST_MORE_THAN_THREE' then TOTAL_PATIENTS end AD_POLST_MORE_THAN_THREE
,case when AD_POLST = 'AD_POLST_THREE_OR_LESS' then TOTAL_PATIENTS end AD_POLST_THREE_OR_LESS
,TOTAL_PATIENTS
FROM(
select 
'ESLD_A' AS CRITERIA
,CASE WHEN AD_THREE = 1 OR POLST_THREE = 1 THEN 'AD_POLST_THREE_OR_LESS'
      WHEN AD_ALL = 1 OR POLST_ALL = 1 THEN 'AD_POLST_MORE_THAN_THREE'
      ELSE 'AD_POLST_NEVER'
END AD_POLST
,SUM(ESDL_A) as TOTAL_PATIENTS
from js_xdr_walling_final_pat_coh
WHERE ESDL_A = 1
GROUP BY 
CASE WHEN AD_THREE = 1 OR POLST_THREE = 1 THEN 'AD_POLST_THREE_OR_LESS'
      WHEN AD_ALL = 1 OR POLST_ALL = 1 THEN 'AD_POLST_MORE_THAN_THREE'
      ELSE 'AD_POLST_NEVER'
END
))
GROUP BY CRITERIA

UNION ALL

select
criteria
,sum(AD_POLST_NEVER) as AD_POLST_NEVER
,sum(AD_POLST_MORE_THAN_THREE) as AD_POLST_MORE_THAN_THREE
,sum(AD_POLST_THREE_OR_LESS) as AD_POLST_THREE_OR_LESS
,SUM(TOTAL_PATIENTS) AS TOTAL_PATIENTS
FROM (
SELECT
CRITERIA
,case when AD_POLST = 'AD_POLST_NEVER' then TOTAL_PATIENTS end AD_POLST_NEVER
,case when AD_POLST = 'AD_POLST_MORE_THAN_THREE' then TOTAL_PATIENTS end AD_POLST_MORE_THAN_THREE
,case when AD_POLST = 'AD_POLST_THREE_OR_LESS' then TOTAL_PATIENTS end AD_POLST_THREE_OR_LESS
,TOTAL_PATIENTS
FROM(
select 
'ESLD_B' AS CRITERIA
,CASE WHEN AD_THREE = 1 OR POLST_THREE = 1 THEN 'AD_POLST_THREE_OR_LESS'
      WHEN AD_ALL = 1 OR POLST_ALL = 1 THEN 'AD_POLST_MORE_THAN_THREE'
      ELSE 'AD_POLST_NEVER'
END AD_POLST
,SUM(ESDL_B) as TOTAL_PATIENTS
from js_xdr_walling_final_pat_coh
WHERE ESDL_B = 1
GROUP BY 
CASE WHEN AD_THREE = 1 OR POLST_THREE = 1 THEN 'AD_POLST_THREE_OR_LESS'
      WHEN AD_ALL = 1 OR POLST_ALL = 1 THEN 'AD_POLST_MORE_THAN_THREE'
      ELSE 'AD_POLST_NEVER'
END
))
GROUP BY CRITERIA

UNION ALL

select
criteria
,sum(AD_POLST_NEVER) as AD_POLST_NEVER
,sum(AD_POLST_MORE_THAN_THREE) as AD_POLST_MORE_THAN_THREE
,sum(AD_POLST_THREE_OR_LESS) as AD_POLST_THREE_OR_LESS
,SUM(TOTAL_PATIENTS) AS TOTAL_PATIENTS
FROM (
SELECT
CRITERIA
,case when AD_POLST = 'AD_POLST_NEVER' then TOTAL_PATIENTS end AD_POLST_NEVER
,case when AD_POLST = 'AD_POLST_MORE_THAN_THREE' then TOTAL_PATIENTS end AD_POLST_MORE_THAN_THREE
,case when AD_POLST = 'AD_POLST_THREE_OR_LESS' then TOTAL_PATIENTS end AD_POLST_THREE_OR_LESS
,TOTAL_PATIENTS
FROM(
select 
'ESRD' AS CRITERIA
,CASE WHEN AD_THREE = 1 OR POLST_THREE = 1 THEN 'AD_POLST_THREE_OR_LESS'
      WHEN AD_ALL = 1 OR POLST_ALL = 1 THEN 'AD_POLST_MORE_THAN_THREE'
      ELSE 'AD_POLST_NEVER'
END AD_POLST
,SUM(ESRD) as TOTAL_PATIENTS
from js_xdr_walling_final_pat_coh
WHERE ESRD = 1
GROUP BY 
CASE WHEN AD_THREE = 1 OR POLST_THREE = 1 THEN 'AD_POLST_THREE_OR_LESS'
      WHEN AD_ALL = 1 OR POLST_ALL = 1 THEN 'AD_POLST_MORE_THAN_THREE'
      ELSE 'AD_POLST_NEVER'
END
))
GROUP BY CRITERIA

UNION ALL


select
criteria
,sum(AD_POLST_NEVER) as AD_POLST_NEVER
,sum(AD_POLST_MORE_THAN_THREE) as AD_POLST_MORE_THAN_THREE
,sum(AD_POLST_THREE_OR_LESS) as AD_POLST_THREE_OR_LESS
,SUM(TOTAL_PATIENTS) AS TOTAL_PATIENTS
FROM (
SELECT
CRITERIA
,case when AD_POLST = 'AD_POLST_NEVER' then TOTAL_PATIENTS end AD_POLST_NEVER
,case when AD_POLST = 'AD_POLST_MORE_THAN_THREE' then TOTAL_PATIENTS end AD_POLST_MORE_THAN_THREE
,case when AD_POLST = 'AD_POLST_THREE_OR_LESS' then TOTAL_PATIENTS end AD_POLST_THREE_OR_LESS
,TOTAL_PATIENTS
FROM(
select 
'ANY_CRITERIA' AS CRITERIA
,CASE WHEN AD_THREE = 1 OR POLST_THREE = 1 THEN 'AD_POLST_THREE_OR_LESS'
      WHEN AD_ALL = 1 OR POLST_ALL = 1 THEN 'AD_POLST_MORE_THAN_THREE'
      ELSE 'AD_POLST_NEVER'
END AD_POLST
,SUM(ANY_CRITERIA) as TOTAL_PATIENTS
from js_xdr_walling_final_pat_coh
WHERE ANY_CRITERIA = 1
GROUP BY 
CASE WHEN AD_THREE = 1 OR POLST_THREE = 1 THEN 'AD_POLST_THREE_OR_LESS'
      WHEN AD_ALL = 1 OR POLST_ALL = 1 THEN 'AD_POLST_MORE_THAN_THREE'
      ELSE 'AD_POLST_NEVER'
END
))
GROUP BY CRITERIA

UNION ALL

select
criteria
,sum(AD_POLST_NEVER) as AD_POLST_NEVER
,sum(AD_POLST_MORE_THAN_THREE) as AD_POLST_MORE_THAN_THREE
,sum(AD_POLST_THREE_OR_LESS) as AD_POLST_THREE_OR_LESS
,SUM(TOTAL_PATIENTS) AS TOTAL_PATIENTS
FROM (
SELECT
CRITERIA
,case when AD_POLST = 'AD_POLST_NEVER' then TOTAL_PATIENTS end AD_POLST_NEVER
,case when AD_POLST = 'AD_POLST_MORE_THAN_THREE' then TOTAL_PATIENTS end AD_POLST_MORE_THAN_THREE
,case when AD_POLST = 'AD_POLST_THREE_OR_LESS' then TOTAL_PATIENTS end AD_POLST_THREE_OR_LESS
,TOTAL_PATIENTS
FROM(
select 
'AGE_CRITERIA' AS CRITERIA
,CASE WHEN AD_THREE = 1 OR POLST_THREE = 1 THEN 'AD_POLST_THREE_OR_LESS'
      WHEN AD_ALL = 1 OR POLST_ALL = 1 THEN 'AD_POLST_MORE_THAN_THREE'
      ELSE 'AD_POLST_NEVER'
END AD_POLST
,SUM(AGE_CRITERIA) as TOTAL_PATIENTS
from js_xdr_walling_final_pat_coh
where 
        --patient NOT in one of the criteria
        AGE_CRITERIA = 1
GROUP BY 
CASE WHEN AD_THREE = 1 OR POLST_THREE = 1 THEN 'AD_POLST_THREE_OR_LESS'
      WHEN AD_ALL = 1 OR POLST_ALL = 1 THEN 'AD_POLST_MORE_THAN_THREE'
      ELSE 'AD_POLST_NEVER'
END
))
GROUP BY CRITERIA

UNION ALL

select
criteria
,sum(AD_POLST_NEVER) as AD_POLST_NEVER
,sum(AD_POLST_MORE_THAN_THREE) as AD_POLST_MORE_THAN_THREE
,sum(AD_POLST_THREE_OR_LESS) as AD_POLST_THREE_OR_LESS
,SUM(TOTAL_PATIENTS) AS TOTAL_PATIENTS
FROM (
SELECT
CRITERIA
,case when AD_POLST = 'AD_POLST_NEVER' then TOTAL_PATIENTS end AD_POLST_NEVER
,case when AD_POLST = 'AD_POLST_MORE_THAN_THREE' then TOTAL_PATIENTS end AD_POLST_MORE_THAN_THREE
,case when AD_POLST = 'AD_POLST_THREE_OR_LESS' then TOTAL_PATIENTS end AD_POLST_THREE_OR_LESS
,TOTAL_PATIENTS
FROM(
select 
'ALL_SELECTED' AS CRITERIA
,CASE WHEN AD_THREE = 1 OR POLST_THREE = 1 THEN 'AD_POLST_THREE_OR_LESS'
      WHEN AD_ALL = 1 OR POLST_ALL = 1 THEN 'AD_POLST_MORE_THAN_THREE'
      ELSE 'AD_POLST_NEVER'
END AD_POLST
,SUM(AGE_CRITERIA) + SUM(ANY_CRITERIA) as TOTAL_PATIENTS
from js_xdr_walling_final_pat_coh
where 
        --patient NOT in one of the criteria
        AGE_CRITERIA = 1
        OR ANY_CRITERIA = 1
GROUP BY 
CASE WHEN AD_THREE = 1 OR POLST_THREE = 1 THEN 'AD_POLST_THREE_OR_LESS'
      WHEN AD_ALL = 1 OR POLST_ALL = 1 THEN 'AD_POLST_MORE_THAN_THREE'
      ELSE 'AD_POLST_NEVER'
END
))
GROUP BY CRITERIA;

/****************************************************************************
Step 14:     Clean up
            
****************************************************************************/   
DROP TABLE js_xdr_walling_IMFP_dept_drv PURGE;
DROP TABLE js_xdr_WALLING_DX_LOOKUP_TEMP PURGE;
DROP TABLE js_xdr_WALLING_DX_LOOKUP PURGE;
DROP TABLE js_xdr_WALLING_LAB_DRV PURGE;
DROP TABLE js_xdr_walling_enc_list PURGE;
DROP TABLE js_xdr_walling_prob_list_all PURGE;
DROP TABLE js_xdr_walling_dx_all PURGE;
DROP TABLE js_xdr_walling_scan_docs PURGE;
DROP TABLE js_xdr_walling_AD_POLST PURGE ;
DROP table js_xdr_walling_MELD_LABS PURGE;
DROP TABLE js_xdr_walling_MELD_LABS_FINAL PURGE;
DROP TABLE js_xdr_walling_dialysis PURGE;
DROP TABLE js_xdr_walling_DIALYSIS_final PURGE;
DROP TABLE js_xdr_WALLING_MELD PURGE;
DROP TABLE js_xdr_walling_onc PURGE;
DROP TABLE js_xdr_walling_PRC_chemo PURGE;
DROP TABLE js_xdr_WALLING_med_CHEMO PURGE;
DROP TABLE js_xdr_WALLING_CHEMO PURGE;
DROP TABLE js_xdr_WALLING_CHF_HOSP PURGE; 
DROP TABLE js_xdr_WALLING_COPD_HSP PURGE; 
DROP TABLE xdr_walling_NEPH PURGE; 
DROP TABLE js_xdr_WALLING_DX_LOOKUP_TEMP PURGE;


