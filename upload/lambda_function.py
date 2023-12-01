import json
import urllib.parse
import boto3

print('Loading function')

s3 = boto3.client('s3')
glue_job_name = 'glue_etl_job'

# Create a Glue client
glue = boto3.client('glue')

def lambda_handler(event, context):
    # Start the Glue job
    response = glue.start_job_run(
        JobName = glue_job_name
    )

    # Get the Glue job run ID
    glue_job_run_id = response['JobRunId']

    # Return the Glue job run ID as the output of the Lambda function
    return {
        'statusCode': 200,
        'body': json.dumps('Glue job run ID: ' + glue_job_run_id)
    }
