create or replace FUNCTION f_death 
  (pi_pat_id            IN lz_clarity_patient.pat_id%TYPE
  ,pi_data_type         IN INTEGER                                              --1=death_date, 2=patient_status, 3=current_age
  ,pi_source            IN INTEGER                                              --1=typical query from sql developer/sqlplus/etc, 2=automated job query, 3=CKD (Check if still used)
  ) 
  RETURN VARCHAR2
AS 

  v_birth_date               lz_clarity_patient.birth_date%TYPE                 := NULL;
  v_death_date               lz_clarity_patient.death_date%TYPE                 := NULL;
  v_pat_status_c             lz_clarity_patient.pat_status_c%TYPE               := NULL;
  v_patient_status           lz_clarity_patient.patient_status%TYPE             := NULL;
  
  v_death_date_pat           DATE           := NULL;
  v_death_date_encip         DATE           := NULL;
  v_death_date_derived       DATE           := NULL;
  v_return                   VARCHAR2(254)  := NULL;

BEGIN
  SELECT birth_date
        ,death_date
        ,pat_status_c
        ,patient_status
    INTO v_birth_date
        ,v_death_date
        ,v_pat_status_c
        ,v_patient_status
    FROM i2b2.lz_clarity_patient pat
    WHERE pat.pat_id = pi_pat_id;
    
    IF v_pat_status_c = 2 OR v_death_date IS NOT NULL THEN                      -- Deceased according to patient data
      v_death_date_pat := nvl(v_death_date,trunc(to_date('12/31/' || to_char(extract(year from sysdate) - 1),'mm/dd/yyyy'))); -- Default death date to 12/31 of previous year, if one is not provided
    END IF;

  BEGIN
    SELECT MAX(hosp_disch_time) /*+ index(v_death_date_encip lz_clarity_enc_ip_deathidx) */
      INTO v_death_date_encip
      FROM i2b2.lz_clarity_enc_inpatient  
      WHERE pat_id = pi_pat_id
        AND (disch_disp_c IN ('20', '40', '41', '42', '71') OR ed_disposition_c = '8');   -- dispositions of expired

    IF v_death_date_pat IS NULL AND v_death_date_encip IS NULL THEN             -- pt is not known deceased
      v_death_date_derived := NULL;
    ELSIF v_death_date_pat IS NOT NULL AND v_death_date_encip IS NULL THEN      -- patient data states that pt has a death date
      v_death_date_derived := v_death_date_pat;
    ELSIF v_death_date_pat IS NULL AND v_death_date_encip IS NOT NULL THEN      -- encounter inpatient data states pt has a death date
      v_death_date_derived := v_death_date_encip;
    ELSIF v_death_date_pat < v_death_date_encip THEN                            -- use the earlier death date recorded
      v_death_date_derived := v_death_date_pat;
    ELSE 
      v_death_date_derived := v_death_date_encip;
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      v_death_date_derived := NULL;
  END;
  
  CASE pi_data_type
    WHEN 1 THEN
      IF pi_source = 2 THEN
        IF v_death_date_derived IS NOT NULL AND v_death_date IS NULL THEN       -- automated jobs use SQLPlus; SQLPlus uses a different date format.
          v_return := to_char(v_death_date_derived, 'DD-MON-YYYY HH24:MI');
        ELSE 
          v_return := to_char(v_death_date, 'DD-MON-YYYY HH24:MI');
        END IF;
      ELSE
        IF v_death_date_derived IS NOT NULL AND v_death_date IS NULL THEN
          v_return := to_char(v_death_date_derived, 'MM/DD/YYYY HH24:MI');
        ELSE 
          v_return := to_char(v_death_date, 'MM/DD/YYYY HH24:MI');
        END IF;
      END IF;
    WHEN 2 THEN
      --Per email on 6/19/2017 titled "Diagnoses template"
      IF v_death_date_derived IS NOT NULL THEN
        v_return := 'Known Deceased';
      ELSE 
        v_return := 'Not Known Deceased';
      END IF;
    WHEN 3 THEN
      IF v_death_date_derived IS NOT NULL AND v_death_date IS NULL THEN
        v_return := to_char(trunc(months_between(v_death_date_derived, v_birth_date)/12));
      ELSE 
        IF v_death_date IS NOT NULL THEN
          v_return := to_char(trunc(months_between(v_death_date, v_birth_date)/12));
        ELSE
          v_return := to_char(trunc(months_between(SYSDATE, v_birth_date)/12));
        END IF;
      END IF;
    ELSE NULL;
  END CASE;
  
  RETURN v_return;
EXCEPTION
  WHEN OTHERS THEN
    RETURN NULL;
END f_death;