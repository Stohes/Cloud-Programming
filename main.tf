provider "aws" {
  region = var.region # Change the region as necessary
}

# S3 Bucket for Elastic Beanstalk app version storage
resource "aws_s3_bucket" "app_bucket" {
  bucket = "${var.app_name}-bucket-iubh-cloud-programming"
}

# Upload the application version (app.zip) to S3
resource "aws_s3_object" "app_version" {
  bucket = aws_s3_bucket.app_bucket.bucket
  key    = "${var.app_name}.zip"
  source = "app.zip"
}

# Elastic Beanstalk Application
resource "aws_elastic_beanstalk_application" "streamlit_app" {
  name        = var.app_name
  description = "Streamlit Hello World app"
}

# Application version
resource "aws_elastic_beanstalk_application_version" "streamlit_app_version" {
  name        = "${var.app_name}-v1"
  application = aws_elastic_beanstalk_application.streamlit_app.name
  bucket      = aws_s3_bucket.app_bucket.bucket
  key         = aws_s3_object.app_version.key
}

# Elastic Beanstalk Environment
resource "aws_elastic_beanstalk_environment" "streamlit_env" {
  name                = "${var.app_name}-env"
  application         = aws_elastic_beanstalk_application.streamlit_app.name
  solution_stack_name = "64bit Amazon Linux 2023 v4.3.2 running Python 3.12"
}


# Output block to print the Elastic Beanstalk environment URL after deployment
output "app_url" {
  value = aws_elastic_beanstalk_environment.streamlit_env.endpoint_url
}
