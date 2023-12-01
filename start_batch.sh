#zip Lambda function to get uploaded with Terraform 
cd /Users/alex/Documents/Batch_Pipeline_AWS/upload
python3 zip_lambda.py

#apply Terraform  
cd /Users/alex/Documents/Batch_Pipeline_AWS/terraform
terraform init
terraform plan -out=plan.out
terraform apply -auto-approve plan.out

#cron job to upload script
cd /Users/alex/Documents/Batch_Pipeline_AWS/upload
python3 upload_s3.py

/Users/alex/Documents/Batch_Pipeline_AWS