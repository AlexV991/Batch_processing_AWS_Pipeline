#Use IAM User - change this! 
data "aws_iam_user" "user_AlexVoelkening" {
  user_name = "AlexVoelkening"
}

#Create IAM Policy
resource "aws_iam_policy" "IAM_policy_AlexVoelkening" {
  name        = "IAM_policy_AlexVoelkening"
  description = "Policy, die dem Benutzer Zugriff auf CloudTrail, KMS, IAM, AWS Glue, S3, QuickSight und Lambda gibt"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "cloudtrail:*",
        "glue:*",
        "s3:*",
        "quicksight:*",
        "lambda:*",
        "iam:*",
        "kms:*" 
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

#Attach IAM Policy to user
resource "aws_iam_user_policy_attachment" "IAM_policy_AlexVoelkening" {
  user       = data.aws_iam_user.user_AlexVoelkening.user_name
  policy_arn = aws_iam_policy.IAM_policy_AlexVoelkening.arn
}

#Create KMS & define policy
resource "aws_kms_key" "batch_key" {
  description             = "KMS key for Batch"
  deletion_window_in_days = 10
  enable_key_rotation     = true
  policy                  = jsonencode(
    {
  "Version": "2012-10-17",
  "Id": "key-default-1",
  "Statement": [
    {
      "Sid": "Enable IAM User Permissions",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::941177638899:root"
      },
      "Action": "kms:*",
      "Resource": "*"
    },
    {
      "Sid": "Allow access for AWS S3",
      "Effect": "Allow",
      "Principal": {
        "Service": "s3.amazonaws.com"
      },
      "Action": [
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:DescribeKey"
      ],
      "Resource": "*"
    },
    {
      "Sid": "Allow access for AWS QuickSight",
      "Effect": "Allow",
      "Principal": {
        "Service": "quicksight.amazonaws.com"
      },
      "Action": [
        "kms:Decrypt",
        "kms:DescribeKey"
      ],
      "Resource": "*"
    }
  ]
}
  )
  tags = {
    Name = "batch_key"
  }
}

#S3 Bucket 
#Create S3 Bucket in AWS 
resource "aws_s3_bucket" "batch_crime" {
  bucket = "batch-job-us-crime-iu"
}

resource "aws_s3_bucket_ownership_controls" "batch_crime" {
  bucket = aws_s3_bucket.batch_crime.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

#Block public access 
resource "aws_s3_bucket_acl" "batch_crime" {
  depends_on = [aws_s3_bucket_ownership_controls.batch_crime]
  bucket = aws_s3_bucket.batch_crime.id
  acl    = "private"
}

#Enable S3 Bucket versioning 
resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.batch_crime.id
  versioning_configuration {
    status = "Enabled"
  }
}

#use KMS with S3
resource "aws_s3_bucket_server_side_encryption_configuration" "batch_crime" {
  bucket = aws_s3_bucket.batch_crime.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.batch_key.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

#Create Sub-Folder for S3 Bucket
resource "aws_s3_object" "folder1" {
    bucket = "${aws_s3_bucket.batch_crime.id}"
    acl    = "private"
    key    = "data/"
    source = "/dev/null"
}

resource "aws_s3_object" "folder2" {
    bucket = "${aws_s3_bucket.batch_crime.id}"
    acl    = "private"
    key    = "raw_data/"
    source = "/dev/null"
}

resource "aws_s3_object" "folder3" {
    bucket = "${aws_s3_bucket.batch_crime.id}"
    acl    = "private"
    key    = "script/"
    source = "/dev/null"
    
}

resource "aws_s3_object" "folder4" {
    bucket = "${aws_s3_bucket.batch_crime.id}"
    acl    = "private"
    key    = "manifest/"
    source = "/dev/null"
    
}
#Lambda Function 
resource "aws_lambda_permission" "batch_crime" {
  function_name = aws_lambda_function.batch_crime_lambda.function_name
  statement_id  = "AllowExecutionFromS3"
  action        = "lambda:InvokeFunction"
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.batch_crime.arn 
}

#load local script lmbda_function.py to lambda
resource "aws_lambda_function" "batch_crime_lambda" {
  filename      = "lambda/lambda_function.py.zip"
  source_code_hash = filebase64sha256("lambda/lambda_function.py.zip")
  function_name = "lambda_batch_crime"
  role          = aws_iam_role.iam_for_batch_lambda.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.10"
  environment { 
    variables = {
    
      GLUE_JOB_NAME = aws_glue_job.glue_etl_job.name
      S3_BUCKET_NAME = aws_s3_bucket.batch_crime.id
    }
  }
}

#connecting Lambda function with S3
resource "aws_s3_bucket_notification" "batch_crime" {
  bucket = aws_s3_bucket.batch_crime.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.batch_crime_lambda.arn 
    events              = ["s3:ObjectCreated:*"] 
    filter_prefix       = "raw_data/Crime_Data_from_2020_to_Present.csv" 
  }
  depends_on = [aws_lambda_permission.batch_crime]
}

#Create Glue ETL Job
resource "aws_glue_job" "glue_etl_job" {
  name = "glue_etl_job"
  role_arn = aws_iam_role.batch_glue_role.arn 
  glue_version = "4.0" 
  command {
    script_location = "s3://${aws_s3_bucket.batch_crime.bucket}/script/script_glue.py" 
    python_version = "3" 
  }
}

resource "aws_glue_security_configuration" "glue_etl_job_security" {
  name = "glue_etl_job_security"
  encryption_configuration {
    cloudwatch_encryption {
      cloudwatch_encryption_mode = "DISABLED"
    }

    job_bookmarks_encryption {
      job_bookmarks_encryption_mode = "DISABLED"
    }

    s3_encryption {
      kms_key_arn        = aws_kms_key.batch_key.arn
      s3_encryption_mode = "SSE-KMS"
    }
  }
}

#IAM Roles for the Project 
#IAM for AWS Glue
#IAM role for AWS Glue
resource "aws_iam_role" "batch_glue_role" {
  name = "batch_glue_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
        Service = "glue.amazonaws.com"
        }
      },
    ]
  })
}

# Create S3 policy 
resource "aws_iam_policy" "s3_batch_policy" {
  name        = "s3_batch_policy"
  description = "Allow to access S3 buckets"
  policy      = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:DescribeKey",
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ],
        "Resource": "*"
      }
    ]
  }
  EOF
}

# Create cloud_watch policy 
resource "aws_iam_policy" "cloudwatch_batch_policy" {
  name        = "cloudwatch_batch_policy"
  description = "Allow to access CloudWatch events"
  policy      = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "events:PutEvents",
          "events:PutRule",
          "events:PutTargets"
        ],
        "Resource": "*"
      }
    ]
  }
  EOF
}

# Attach policies to the IAM Glue role 
resource "aws_iam_policy_attachment" "glue_attachment" {
  for_each = toset([
   "arn:aws:iam::941177638899:policy/s3_batch_policy",
   "arn:aws:iam::941177638899:policy/cloudwatch_batch_policy"
  ])
  name       = "glue_attachment"
  roles      = [aws_iam_role.batch_glue_role.name, aws_iam_role.iam_for_batch_lambda.name]
  policy_arn = each.value
}
 

#IAM for Lambda
#IAM role for Lambda
resource "aws_iam_role" "iam_for_batch_lambda" {
  name = "iam_for_batch_lambda"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
}

# Attach policies to the IAM role 
resource "aws_iam_role_policy_attachment" "glue_service_role" {
  role       = aws_iam_role.iam_for_batch_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

#IAM role for QuickSight
resource "aws_iam_role" "batch_quicksight_role" {
  name = "batch_quicksight_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "quicksight.amazonaws.com"

        }
      },
    ]
  })
}

# Create policy Quicksight
resource "aws_iam_policy" "IAM_for_quicksight" {
  name        = "IAM_for_quicksight"
  description = "Allow to access S3 buckets & Decrypt KMS"
  policy      = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
        "kms:Encrypt",
        "kms:Decrypt",
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ],
        "Resource": "*"
      }
    ]
  }
  EOF
}

# Attach policie to IAM QuickSight role 
resource "aws_iam_policy_attachment" "QuickSight_attachment" {
  name       = "QuickSight_attachment"
  roles      = [aws_iam_role.batch_quicksight_role.name]
  policy_arn = aws_iam_policy.IAM_for_quicksight.arn
}