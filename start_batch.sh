#zip Lambda function to get uploaded with Terraform 
cd /Users/alex/Documents/Batch_Pipeline_AWS/terraform/lambda
python3 zip_lambda.py

#apply Terraform  
cd /Users/alex/Documents/Batch_Pipeline_AWS/terraform
terraform init
terraform plan -out=plan.out
terraform apply -auto-approve plan.out

#cron job to upload script
cd /Users/alex/Documents/Batch_Pipeline_AWS
python3 upload/upload_s3.py