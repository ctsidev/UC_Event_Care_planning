# UC_Event_Care_planning
## Advance Care Planning Script Overview
 Investigator Name: Dr. Ann Walling, Dr. Neil Wenger, and Dr. Douglas Bell

	Author: Robert Follett/Javi Sanz
	Revision Date: 20180828
	Version: 1.0.1
---
Background:
	UCLA EMR data for adults 18 or older that meet cohort criteria for serious illness (see cohorts below: advanced cancer, COPD, CHF, ESLD, etc.) and have two encounters with primary care within the last year e.g. May 2017 to May 2018

	Overview:
	The script will create a main table with all potential patients (denominator) and a series of flags (i.e., problem list diagnosis, outpatient diagnoses, etc…) to help gauge the most accurate algorithm to define each sub-group. This code will pull all active problem list records and the last three years of outpatient diagnoses
    After this step, we will implement the following flags to pull/calculate additional indicators for each group.
*	ESLD:
	*	Labs results (Albumin, INR, Creatinine, Bilirubin, and sodium) Find the latest set of labs that took place within 48 hours.
	*	MELD
	*	Dialysis (limited since outpatient episodes don’t get recorded at UCLA*)
*	Advance cancer:
	*	Oncology visits in the last two years
	*	Chemotherapy treatments in the last two years (CPT codes and meds)
*	CHF:
	*	LVEF results (separate file)
	*	Hospitalizations with CHF diagnosis in the last 12 months
*	COPD:
	*	Hospitalizations with COPD diagnosis in the last 12 months
Within the section for each criteria, there is a statement to export counts and sample data for chart review.    

Specific instructions
These are a few items that require special attention and/or customization: 
*	The code is written to pull from the Clarity datamart and it creates a series of temporary tables to store calculations and certain data used along the process.
*	Step 1: A series of drivers are provided to standardize the data pull. Diagnoses use ICD codes that are translated into [dx_id] at each site. The labs use LOINC codes.
*	Step 2: The denominator is calculated by using a department selection and counting all adult patients with more than 2 “Office Visit” encounters in the last 12 months, and where the patient’s status is not known deceased, and their PCP is a UC doctor.
	*	Death function: At UCLA we use a death function to accurately capture the patient’s status. This function is included as a support file [XDR_WALLING_DEATH_UCLA.sql] but if you have your own method to make this assessment, feel free to use it instead.
*	Step 3: The problem list has no time restriction and pulls all “active” records
*	Step 4: The encounter diagnoses are extracted from “Office visit” encounters only and with a time limit of three years.
*	Step 5: For advance directive and POLST, the script walks through the process of creating a [doc_type] driver lists from the [ZC_DOC_INFO_TYPE] table, which is specific for each site, and uses it to pull scanned documents. There are some new conditions added to exclude “deleted” and “expired” records. 
*	Step 6: ESLD. It pulls a series of labs based on the driver from step 1. 
	*	The [ord_value] is harmonized into [harm_num_val] to optimize the calculations and avoid errors. The variable [order_type_c] = 7 refers to “labs” at UCLA. Check the equivalent value at your site.
	*	MELD: Additionally, the code builds a MELD score for each patient. The dialysis component doesn’t find many records because this procedure is done outside UCLA, but maybe other sites have this information in their EMR. This is used within the MELD calculation to cap creatinine to 4.0 max.
	*	The criterion is:
		*	PL cirrhosis + [hepatic decompensation (PL or Dx) or MELD >18]
*	Step 7: Advanced Cancer. 
	*	Oncology: The script pulls oncology encounters from the last two years based on department name. 
	*	Chemo: It also looks at chemotherapy treatment by pulling CPT codes (the codes are hardcoded into the script since there are just a few of them), and “not historical medications” where med name ‘%chemo%’. It builds a timeframe for each of these criteria, and applies them accordingly.
		*	m.medication_id != 800001 is used to exclude med dummy records in the UCLA system. Yours might be different.
	*	The two criteria are :
		*	PL advanced cancer + oncology visit in the past 12 months
		*	Dx advanced cancer + chemotherapy in the past 2 years
*	Step 8: CHF. This section pulls hospitalization from table [pat_enc_hsp] in the last 12 months where there was a CHF diagnosis (no need to qualify the code if the code was “primary”, “discharge”, “POA”, etc…)
	*	The ejection fraction extraction code is provided on an additional file. [XDR_WALLING_LVEF_UCLA.sql]. The code looks for the lowest score in the last three years.
	*	The two criteria are :
		*	PL or Dx for HF and any EF < 31% OR
	*	PL and 1 admission with a HF dx (not necessarily principal)
*	Step 9: COPD.  This section pulls hospitalization from table [pat_enc_hsp] in the last 12 months, where there was a COPD diagnosis (again, no need to qualify the codes). 
	*	The Supplemental oxygen element, relevant to the criteria, is being calculated on the problem list and encounter diagnosis section and labeled “COPD_SPO2”.
	*	The criterion is:
		*	PL COPD + [(V or Z code) OR 1 admission with a COPD dx (not necessarily principal)]
*	Finally, the code includes a section for each criteria to pull counts and samples. The output shall be exported to an Excel file that shall include the aggregated counts for each cohort, the patients' information, and a brief data dictionary. It has a series of placeholder items to be filled by the investigator doing the chart abstraction (see Sample abstraction form COPD.xlsx:  for an example). The data dictionary contains detailed information about the review.

Additional script materials
 Additional list of files provided (drivers and such)
*	UCLA_event_care_planning_code_Walling_08292018.sql: script to extract data from Clarity
*	XDR_WALLING_LVEF_UCLA.sql: code to extract and calculate ejection fraction results.
*	XDR_WALLING_DEATH_UCLA.sql: Death SQL function at UCLA
*	XDR_WALLING_DX_LOOKUP_TEMP.csv: reference codes to use when pulling diagnoses codes.
*	XDR_WALLING_LAB_DRV.csv: reference codes to use when pulling labs. 
Other materials
*	UCLA_event_care_planning_code_Walling_08292018.sql: script to extract data from Clarity
*	Data_dictionary.xlsx: Brief explanation of the different fields in the data abstraction document, and instructions on how to review the charts.
*	Sample abstraction form COPD.xlsx: This document shows what an abstraction document looks like. It includes two tabs loaded from the script (sample and aggregated counts), and the data dictionary

For any questions regarding the script, feel free to contact me at
	jsanz@mednet.ucla.edu
