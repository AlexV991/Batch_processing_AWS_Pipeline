#cron job to upload script 
python3 upload_s3.py

'''
aws s3 cp /Users/alex/Documents/Test_Batch/Crime_Data_from_2020_to_Present.csv  s3://batch-job-us-crime-iu/data/
aws s3 cp /Users/alex/Documents/Test_Batch/script_glue.py  s3://batch-job-us-crime-iu/script/
aws s3 cp /Users/alex/Documents/Test_Batch/crime_data_manifest.json  s3://batch-job-us-crime-iu/data/
'''