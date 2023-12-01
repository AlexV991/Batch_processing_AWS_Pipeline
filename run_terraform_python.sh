#apply Terraform- change the path! 
cd /Users/alex/Documents/Batch_Pipeline_AWS/terraform
terraform init
terraform plan -out=plan.out
terraform apply -auto-approve plan.out

#cron job to upload script - change the path! 
cd /Users/alex/Documents/Batch_Pipeline_AWS/upload
python3 upload_s3.py

