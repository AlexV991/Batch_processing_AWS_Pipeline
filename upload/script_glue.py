import sys
import pandas as pd 

#read csv  - change this path!! 
df = pd.read_csv('s3://batch-job-us-crime-iu/raw_data/Crime_Data_from_2020_to_Present.csv', sep=',', low_memory=False)

#convert datetime - delete timestamp 
df['Date Rptd'] = pd.to_datetime(df['Date Rptd']).dt.date

#delete all variables except datetime
counts = df['Date Rptd'].value_counts()

#save in new csv - change this path!! 
counts.to_csv('s3://batch-job-us-crime-iu/data/glue_result.csv', sep=',')
