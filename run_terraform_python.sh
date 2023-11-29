#cron job to upload script 
python3 upload_s3.py

#apply Terraform
cd /Users/alex/Documents/Batch_Pipeline_AWS/terraform
terraform init
terraform plan -out=plan.out
terraform apply -auto-approve plan.out