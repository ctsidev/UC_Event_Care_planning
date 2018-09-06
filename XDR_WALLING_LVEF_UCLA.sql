/**********************************************************************************************

Script purpose: Extract LVEF score from Echocardiography Orders using ord_value and narrative report
Programmers: 	Swamy Bachu, Javier Sanz
Created date: 	05/21/2018


Description:
			we did some work last week on the LVEF results and made some substantial progress. Basically, 
			we started by looking at the documentation found on epic’s website for the LVEF, which showed us 
			two registries DM_ACO and DM_CHF have some sort of data related to LVEF. Unfortunately, UCLA does  
			not use/load the DM_CHF registry. 



			In the table DM_ACO, a few columns that have the LVEF related information in them. 
			• LVEF_LAST
			• LVEF_LAST_DT
			• LVEF_L_ORD_ID
			• LVEF_L_LRR_ID
			• LVEF_L_UNIT
			• LVEF_LAST_NUM 
			• LVEF_LAST_BELOW_40_DT

			Using the LVEF_L_ORD_ID, we were able to trace back to the [ORDER_PROC] table. All these orders 
			were of ORDER_TYPE_C = 29 which is a ECHOCARDIOGRAPHY. The [ORDER_NARRATIVE] table has the details 
			of each echocardiography and the ejection fraction in the NARRATIVE column. Alternativelly, the LVEF 
			results can also be recorded in [ORDER_RESULTS].[ORD_VALUE] (joining on [ORDER_PROC_ID])

			We look at [LVEF_L_LRR_ID] and match it to component_id to confirm that they were 
			using [11858 LEFT VENTRICULAR EJECTION FRACTION]

			The attached script follows these steps to generate a table with the final results:

			Step 1: Pull  Echocardiography Orders.
			Step 2: Pull Narratives.
			Step 3: Pull LVEF narrative lines.
			Step 4: Create aggregates for each order line including the next line.
			Step 5: Create the final table to extract data from order_value or lowest LVEF score from the data.

			The final table might include more than one result for the same order_proc_id, when pulling from here, 
			we'd recommend selecting the lowest score available or perhaps the closest to a certain period of time, 
			depending on the PI question.

			We are working on improving the 79% margin of results obtained for LVEF using this method. Additionally, 
			we are working on a project using a Natural Language Processing in Python to optimize this process. As I 
			said, there is room for optimization but this first attempt is a solid place to start.:

**********************************************************************************************/
	
	
-------------------------------------
---- Step 1: Pull  Echocardiography ORders
-------------------------------------
DROP TABLE js_xdr_WALLING_opr PURGE;
CREATE TABLE js_xdr_WALLING_opr AS
SELECT DISTINCT pat.pat_id
               ,opr.order_proc_id
            --    ,opr.proc_id
            --    ,opr.description           
            --    ,eap.proc_name
            --    ,opr.proc_code
               ,opr.order_time
            --    ,opr.result_time
            --    ,opr.order_type_c
            --    ,xot.NAME                  AS order_type
            --    ,opr.abnormal_yn
            --    ,opr.order_status_c
            --    ,opr.radiology_status_c
            --    ,opr.specimen_source_c
            --    ,opr.specimen_type_c
                ,acc.acc_num
            --    ,xpt.NAME                  AS specimen_type
               ,res.line
               ,res.ord_value
            --    ,res.component_id
            --    ,cmp.NAME                  AS component_name
            --    ,res.component_comment
            --    ,res.result_time           AS res_result_time
            --    ,res.result_val_start_ln
            --    ,res.result_val_end_ln
            --    ,res.result_cmt_start_ln
            --    ,res.result_cmt_end_ln
            --    ,res.lrr_based_organ_id
  FROM js_xdr_walling_final_pat_coh                    pat
  JOIN order_proc               		opr ON pat.pat_id = opr.pat_id
  LEFT JOIN clarity.order_results       res ON opr.order_proc_id = res.order_proc_id
  LEFT JOIN clarity.order_rad_acc_num   acc ON opr.order_proc_id = acc.order_proc_id
--   LEFT JOIN clarity.clarity_eap         eap ON opr.proc_id = eap.proc_id
--   LEFT JOIN clarity.clarity_component	cmp	ON res.component_id = cmp.component_id
--   LEFT JOIN clarity.zc_order_type       xot ON opr.order_type_c = xot.order_type_c 
--   LEFT JOIN clarity.zc_specimen_type    xpt ON opr.specimen_type_c = xpt.specimen_type_c
  WHERE 
  		(pat.pl_chf = 1 or pat.dx_chf = 1)
        AND opr.order_status_c = 5                    				--Completed
        AND OPR.ORDER_TYPE_C = 29
		AND opr.result_time between SYSDATE - (365.25 * 3) AND SYSDATE
;
CREATE INDEX js_xdr_WALLING_opr_patidx ON js_xdr_WALLING_opr (pat_id);
CREATE INDEX js_xdr_WALLING_opr_ordidx ON js_xdr_WALLING_opr (order_proc_id);
CREATE INDEX js_xdr_WALLING_opr_opridx ON js_xdr_WALLING_opr (order_type_c, proc_id);
SELECT COUNT(*) FROM js_xdr_WALLING_opr;                                             --82161
SELECT COUNT(DISTINCT pat_id) FROM js_xdr_WALLING_opr;                               --32066


-------------------------------------
---- Step 2: Pull Narratives
-------------------------------------
DROP TABLE JS_xdr_WALLING_NARR PURGE;
CREATE TABLE jS_xdr_WALLING_NARR AS
SELECT DISTINCT opr.pat_id
               ,opr.acc_num
               ,opr.order_proc_id
               ,nar.line           AS narr_line
               ,nar.narrative      AS narr_narrative
		   ,order_time
		   ,ord_value
  FROM xdr_WALLING_OPR                      opr
  JOIN order_narrative  nar ON opr.order_proc_id = nar.order_proc_id
  WHERE trim(nar.narrative) IS NOT NULL
;
CREATE INDEX JS_xdr_WALLING_NARR_patidx ON JS_xdr_WALLING_NARR (pat_id);
CREATE INDEX JS_xdr_WALLING_NARR_opridx ON JS_xdr_WALLING_NARR (order_proc_id);
SELECT COUNT(*) FROM JS_xdr_WALLING_NARR;                                          --3796268
SELECT COUNT(DISTINCT pat_id) FROM JS_xdr_WALLING_NARR;                            --31961


----------------------------------------------------------------------------------
---- Step 3: Pull LVEF narrative lines 
----------------------------------------------------------------------------------
DROP TABLE js_xdr_WALLING_lvef PURGE;
 commit;
CREATE TABLE js_XDR_WALLING_LVEF
	AS
		SELECT PAT_ID
		      ,ACC_NUM
		      ,ORDER_PROC_ID
		      ,NARR_LINE
		      ,ORDER_TIME
		      ,ORD_VALUE
		      ,NARR_NARRATIVE
		  FROM js_XDR_WALLING_NARR
		 WHERE (			LOWER(NARR_NARRATIVE) LIKE '%ejection%'
			    OR UPPER(NARR_NARRATIVE) LIKE '%LVEF%'
			    OR LOWER(NARR_NARRATIVE) LIKE '%fraction%'		);
COMMIT;
SELECT COUNT(*), COUNT(DISTINCT pat_id) FROM js_xdr_WALLING_lvef;  --140508	29678

-------------------------------------------------------------
---- Step 4: Create aggregates for each order line 
------------------------------------------------------------
DROP TABLE js_XDR_WALLING_LVEF_AGG PURGE;
CREATE TABLE js_XDR_WALLING_LVEF_AGG
	AS
		SELECT LVEF.PAT_ID
		      ,LVEF.ORDER_PROC_ID
		      ,LVEF.ACC_NUM
		      ,LVEF.ORDER_TIME
		      ,LVEF.ORD_VALUE
		      ,LISTAGG(NARR.NARR_LINE
		                  || '|'
		                  || NARR.NARR_NARRATIVE,' || ') WITHIN  GROUP(			 ORDER BY NARR.NARR_LINE		) NARR_AGG
		  FROM js_XDR_WALLING_LVEF LVEF
          JOIN js_XDR_WALLING_NARR NARR ON LVEF.ORDER_PROC_ID = NARR.ORDER_PROC_ID 
		  							AND NARR.NARR_LINE  BETWEEN LVEF.NARR_LINE and LVEF.NARR_LINE  + 1
		 GROUP BY LVEF.PAT_ID
		      ,LVEF.ORDER_PROC_ID
		      ,LVEF.ACC_NUM
		      ,LVEF.ORDER_TIME
		      ,LVEF.ORD_VALUE;
COMMIT;


SELECT COUNT(*),  COUNT(DISTINCT pat_id),  COUNT(DISTINCT ORDER_PROC_ID)   FROM js_XDR_WALLING_LVEF_AGG;   ---64640	29678	64611
--------------------------------------------------------------------------------------------------------------------------
---- Step 5: Create the final table to extract data from order_value or lowest lvef score from the data 
--------------------------------------------------------------------------------------------------------------------------
DROP TABLE js_XDR_WALLING_LVEF_FINAL PURGE;
COMMIT;

CREATE TABLE js_XDR_WALLING_LVEF_FINAL
	AS
		WITH CTE AS (
			SELECT PAT_ID
			      ,ORDER_PROC_ID
			      ,ORDER_TIME
			      ,ORD_VALUE
			      ,TRIM(	CASE
					WHEN
						REGEXP_LIKE(SUBSTR(NARR_AGG,REGEXP_INSTR(LOWER(NARR_AGG),'\d++.(to|-).\d++.(|^%)',5),8),'(to|-)','i')
					THEN SUBSTR(NARR_AGG,REGEXP_INSTR(LOWER(NARR_AGG),'\d++.(to|-).\d++.(|^%)',5),2)
					ELSE SUBSTR(NARR_AGG,REGEXP_INSTR(LOWER(NARR_AGG),'\d++.(|^%)',5),2)
				END) AS TEST_VALUES
			      ,NARR_AGG
			  FROM js_XDR_WALLING_LVEF_AGG
		) SELECT PAT_ID
		        ,ORDER_PROC_ID
		        ,ORDER_TIME
		        ,CASE
				WHEN
					ORD_VALUE IS NULL
				THEN TEST_VALUES
				ELSE (CASE
						WHEN	REGEXP_LIKE ( ORD_VALUE	,'\+.\-','i' )
						THEN TO_CHAR(TO_NUMBER(REGEXP_SUBSTR(ORD_VALUE,'[1-9]\d*(\.\,\d+)?'),'9999999999D9999999999','NLS_NUMERIC_CHARACTERS = ''.,''') - 5)
						ELSE COALESCE(REGEXP_SUBSTR(ORD_VALUE,'[1-9]\d*(\.\,\d+)?'),REGEXP_SUBSTR(ORD_VALUE,'?[[:digit:],.]*$') )
					END)END AS LVEF_FINAL_VALUE
		        ,TEST_VALUES NARR_VALUE
		        ,ORD_VALUE
		        ,NARR_AGG
		    FROM CTE;

COMMIT;
SELECT COUNT(*),  COUNT(DISTINCT pat_id),  COUNT(DISTINCT ORDER_PROC_ID)   FROM js_XDR_WALLING_LVEF_FINAL;   ---64640	29678	64611

select COUNT(*),  COUNT(DISTINCT pat_id),  COUNT(DISTINCT ORDER_PROC_ID)  from js_XDR_WALLING_LVEF_FINAL where LVEF_FINAL_VALUE is null;--0	0	0



select count(*), count(distinct order_proc_id), count(distinct pat_id )  from js_XDR_WALLING_LVEF_FINAL;  ---64640	64611	29678

select count(*), count(distinct order_proc_id), count(distinct pat_id ) from js_XDR_WALLING_LVEF_FINAL  ----5624	5623	3111
where lvef_final_value in ('1','2','3','4','5','6','7','8','9','10','11','12','13','14','15','16','17','18','19','20','21','22','23','24','25','26','27','28','29','30','31');