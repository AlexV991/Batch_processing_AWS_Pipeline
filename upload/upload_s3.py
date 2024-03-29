import os 
import boto3
import pandas as pd

#documents path
csv_path = os. getcwd() + "/data"
upload_path = os. getcwd() + "/upload"

#declare variables csv, py script & manifest
file_csv = 'Crime_Data_from_2020_to_Present.csv'
script_glue = 'script_glue.py'
json_manifest = 'crime_data_manifest.json'

#set variables for S3
client = boto3.client('s3')
#change this path!! 
bucket = 'batch-job-us-crime-iu'

#get file path of csv, script & manifest 
file_path_csv = os.path.join(csv_path, file_csv)
file_path_script_glue = os.path.join(upload_path, script_glue)
file_path_json_manifest = os.path.join(upload_path, json_manifest)

#load to s3
client.upload_file(file_path_script_glue, bucket, 'script/'+script_glue)
client.upload_file(file_path_json_manifest, bucket, 'manifest/'+json_manifest)
client.upload_file(file_path_csv, bucket, 'raw_data/'+file_csv)