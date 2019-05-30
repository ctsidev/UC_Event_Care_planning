# -*- coding: utf-8 -*-
"""
Created on Wed May  1 09:59:12 2019

@author: JSanz

Purpose: Email each Primary Care Provider with their list of patients
        included in the ACP cohort


Additional features:
        Data destination
            Update "Email sent to PCP (yes/no)" field in REDCAP (5/20/19)
            Create CSV report to upload to REDCAP (5/20/19)
        Data source:
            CSV file (REDCAP report) (5/20/19)
            REDCAP
            Clarity (on hold: future infrastrcuture changes might prevent this)
        Other features
            Integrate PCP name in the email body (done, 5/26/19)
            Use file for email text (done, 5/29/19)
"""
# ----------------------------------------------
# import the following libraries
# ----------------------------------------------
import csv
import smtplib
from tabulate import tabulate
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
import texttable as tt
from datetime import datetime
from pytz import timezone

# ----------------------------------------------
# Variables
# ----------------------------------------------
text = ''
html = ''
email_count = 0
#path_to_redcap_file = 'C:/Users/jsanz/Downloads/PCORI.csv'
path_to_redcap_report = 'C:/Users/jsanz/Downloads/send_email_report.csv'
# create list to hold PCPs and patient panels for each one
patient_panel = []

# set up patient counter
pat_count = 1

# set up a second pcp_email field to identified when the patient list changes
# to a different provider
prev_pcp_email = ''
sender_email = 'UC Health Care Planning <UCHealthCarePlanning@mednet.ucla.edu>'
# ----------------------------------------------
# Functions
# ----------------------------------------------
# reset emails (plain and html)
# Include paths to letter templates (plain and html)
def get_text():
    with open('C:/Users/jsanz/Documents/GitHub/UC_Event_Care_planning/Recruitment/letter.txt', 'r') as myfile:
        text = myfile.read()
    return text

def get_html():
    with open('C:/Users/jsanz/Documents/GitHub/UC_Event_Care_planning/Recruitment/letter.html', 'r') as myfile:
        html = myfile.read()
    return html

# send email
def send_email(receiver_email, receiver_name, patient_panel):
    text = get_text()
    html = get_html()
    # Reset patient table for email
    patient_table = []
    # Add header
    patient_table.append(['mrn', 'first name', 'last name'])
    # Generate report
    for item in patient_panel:
        patient_table.append([str(item[1]), str(item[2]), str(item[3])])
        # capture present time for report
        los_angeles_time = timezone('America/Los_Angeles')
        ts = datetime.now(los_angeles_time)
        start_time = str(ts.strftime("%Y-%m-%d %H:%M:%S"))
        # save patient record to report
        email_sent_report.write(str(item[0]) + ',1,' + start_time + '\n')

    # Generate plain email version
    text = text.format(patients=tabulate(patient_table, headers="firstrow",
                                         tablefmt="pipe"),
                        name = receiver_name)
    print(text)
    # Generate html email version
    html = html.format(patients=tabulate(patient_table, headers="firstrow",
                                         tablefmt="html"),
                        name = receiver_name)
    print(html)

    # set up message parameters
    message = MIMEMultipart("alternative", None, [MIMEText(text, 'plain'),
                                                  MIMEText(html, 'html')])
    message['Subject'] = 'UC Health Advance Care Planning Study'
    message['From'] = sender_email
    message['To'] = receiver_email

    # set up SMTP server parameters
    server = smtplib.SMTP('SMTP server')
    server.ehlo()
    server.sendmail(sender_email, receiver_email, message.as_string())
    server.quit()

# Reset text and html fields
    text = get_text()
    html = get_html()

# ----------------------------------------------
# Read data file
# ----------------------------------------------
with open('C:/Users/jsanz/Downloads/PCORI.csv') as f:
    reader = csv.reader(f)
    pcp_patient_list = list(reader)
# delete   headers
del pcp_patient_list[0]

# open file to save sent email report. It shall be changed for the second run
email_sent_report = open('path_to_redcap_report', 'w')
email_sent_report.write('study_id,first_email_sent_pcp_yn,first_email_sent_pcp_dt\n')


# Loop through PCP-patient list, for every PCP, do an subloop to find all pats
for record in pcp_patient_list:
    # Save PCP email and PCP name to variables
    pcp_email = str(record[3])
    pcp_name = str(record[2])

    # first record can be directly put into patient_panel list
    if pat_count == 1:
        # capture study_id, mrn, patient last name, potient first name
        patient_panel.append([str(record[0]), str(record[4]), str(record[6]),
                              str(record[5])])
        pat_count += 1
        prev_pcp_email = pcp_email
        prev_pcp_name = pcp_name
    # second patient needs to check if PCP is still the same
    else:
        # If PCP si still the same, add patient to patient_panel, add count
        # record PCP email
        if pcp_email == prev_pcp_email:
            # capture study_id, mrn, patient last name, potient first name
            patient_panel.append([str(record[0]), str(record[4]),
                                  str(record[6]), str(record[5])])
            pat_count += 1
            prev_pcp_email = pcp_email
            prev_pcp_name = pcp_name
        else:
            # If PCP has changed, send email to last PCP, reset lists, load
            # new patient, add count, and record PCP email
            send_email(prev_pcp_email, prev_pcp_name, patient_panel)
            email_count += 1
            patient_panel = []
            # capture study_id, mrn, patient last name, potient first name
            patient_panel.append([str(record[0]), str(record[4]),
                                  str(record[6]), str(record[5])])
            prev_pcp_email = pcp_email
            prev_pcp_name = pcp_name
            pat_count += 1

# send last patient list
send_email(pcp_email, pcp_name, patient_panel)
email_count += 1

# ----------------------------------------------
# Print results
# ----------------------------------------------
print('Total number of patients: {0} Total number of emails/PCP: {1}'
      .format(pat_count, email_count))
email_sent_report.close()
