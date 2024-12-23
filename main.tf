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

# Create an IAM role for Elastic Beanstalk EC2 instances
resource "aws_iam_role" "eb_instance_role" {
  name               = "${var.app_name}-instance-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Attach the default Elastic Beanstalk policies to the role
resource "aws_iam_role_policy_attachment" "eb_instance_role_managed" {
  role       = aws_iam_role.eb_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWebTier"
}

resource "aws_iam_role_policy_attachment" "eb_instance_role_cloudwatch" {
  role       = aws_iam_role.eb_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Create an instance profile for the IAM role
resource "aws_iam_instance_profile" "eb_instance_profile" {
  name = "${var.app_name}-instance-profile"
  role = aws_iam_role.eb_instance_role.name
}

# Elastic Beanstalk Environment
resource "aws_elastic_beanstalk_environment" "streamlit_env" {
  name                = "${var.app_name}-env"
  application         = aws_elastic_beanstalk_application.streamlit_app.name
  solution_stack_name = "64bit Amazon Linux 2023 v4.3.2 running Python 3.12"

  # Set Elastic Beanstalk to use a single instance
  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "EnvironmentType"
    value     = "SingleInstance"
  }

  # Ensure the instance type is Free Tier eligible
  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "InstanceType"
    value     = "t2.micro"
  }

  # Set IAM role
  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = aws_iam_instance_profile.eb_instance_profile.name
  }

  # Set Streamlit default port
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "PORT"
    value     = "8080" # Streamlit default port
  }
}

# Output block to print the Elastic Beanstalk environment URL after deployment
output "app_url" {
  value = aws_elastic_beanstalk_environment.streamlit_env.endpoint_url
}
