# -*- coding: utf-8 -*-
"""
Created on Wed May  1 09:59:12 2019

@author: JSanz

Purpose: Email each Primary Care Provider with their list of patients 
        included in the ACP cohort


Additional features:
        Data destination
            Update "Email sent to PCP (yes/no)" field in REDCAP
            Create CSV report to upload to REDCAP
            
        Data source:
            Clarity
            CSV file (REDCAP report)
            REDCAP
        
        
"""

# import the following libraries
import smtplib
from array import *
from string import Template
from tabulate import tabulate
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText

# Variables
text = ''
html = ''

# Functions to reset 
def get_text():
    text = """
Dear Dr. , 

UCLA Health is reaching out to primary care patients with serious illness who have no advance care planning in CareConnect to encourage these patients to complete an advance directive and bring it to their primary care physician.  To evaluate the effect of this system-wide quality improvement intervention, we will survey some of these patients about advance care planning.  

The patients listed below are candidates for this survey.  Please review the list and notify one of us if we should exclude any patient from being approached to participate because:
•         the patient is cognitively incapable of being surveyed or
•         the patient would be harmed by being surveyed or
•         the patient does not speak English or Spanish.

List of your patients
{table}

If you do not respond with patients to be excluded, we will assume that all patients can be contacted.

Thank you,


Neil Wenger                                                                            Anne Walling
NWenger@mednet.ucla.edu                                               AWalling@mednet.ucla.edu 
310-794-2288                                                                          310-794-0741
 

"""
    return text

def get_html():
    html = """
    <html><body><p>Dear ,</p>
    <p>We have recently identified the following patients as candidates for the ACP blah, blah, blah</p>
    {table}
    <p>Please, do not hesirtate to contact us if you are aware that any of these patients should not be included etcetera...</p>
    <p>Regards,</p>
    <p>ACP team</p>
    </body></html>
    """
    return html

# Set up the email parameters
#me = 'me@gmail.com'
#password = 'passWord'
#server = 'smtp.gmail.com:587'
#you = 'you@gmail.com'


# create test data
pcp_tup = ((12345,'drno@mednet.ucla.edu', 'Dr No'),(67890,'jsanz@mednet.ucla.edu','Dr Javier Sanz' ))
    
patient_tup = ((12345, '1111111', 'john' ,'doe')
,(12345, '2222222', 'jane' ,'new')
,(67890, '4040604','Curton' ,'Anastassia')
,(67890, '6627934','Russell' ,'Robinett')
,(67890, '1683497','Giddy' ,'Jaine')
,(67890, '2819889','Shilliday' ,'Margy')
,(67890, '5818979','Kingscott' ,'Cissy')
,(67890, '8259685','Patton' ,'Roch')
,(67890, '7066200','Stockton' ,'Leta')
,(67890, '0720085','Kenningley' ,'Kaine')
,(67890, '3260196','Schettini' ,'Marve')
,(67890, '9288125','Frankham' ,'Christean')
,(67890, '4951694','Saward' ,'Merilyn')
,(67890, '4462494','Fiddy' ,'Gordy')
,(67890, '2398769','Kondratowicz' ,'Kahaleel')
,(67890, '8540721','Bennie' ,'Brandtr')
)
# find provider
for record in pcp_tup:
    # load provider into list
    pcp = []
    pcp = record
#    reset patient panel list
    patient_panel = []
    print(record)
    # add header to patient panel list
    patient_panel.insert(0, ['mrn','first name','last name'])
#   Look for patients for this provider
    for pat in patient_tup:
        # if patient pcp matches provider, add to patient_panel list
        if pcp[0] == pat[0]:
            print(pat)
            count = len(patient_panel) + 1
            patient_panel.insert(count, (pat))
# After patient panel for provider has been completed, create message body
    text = get_text()
    html = get_html()
    text = text.format(table=tabulate(patient_panel, headers="firstrow", tablefmt="grid"))
    print(text)
#    html = html.format(table=tabulate(patient_panel, headers="firstrow", tablefmt="myformat"))
#    print(html)
# set up message parameters
    message = MIMEMultipart( "alternative", None, [MIMEText(text)])
                                                   #MIMEText(html,'html')])
    message['Subject'] = 'UC Health Advance Care Planning Study'
    message['From'] = 'ACP-UCLA@mednet.ucla.edu'
    message['To'] = pcp[1]
# set up SMTP server parameters
    server = smtplib.SMTP('mitsmail.mednet.ucla.edu')
    server.ehlo()
#    server.starttls()
#    server.login(me, password)
    server.sendmail('ACP-UCLA@mednet.ucla.edu', 'jsanz@mednet.ucla.edu', message.as_string())
    server.quit()
#    print(message.as_string())
# Reset text and html fields
    text = get_text()
    html = get_html()
