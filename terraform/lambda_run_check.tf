/*
 * This lambda is invoked by an SNS topic using the pattern described here:
 * https://github.com/hashicorp/terraform/issues/2885#issuecomment-152072270
 */

resource "aws_iam_role" "lambda_run_check" {
    name = "lambda_run_check"
    assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "lambda_run_check_logs_policy" {
    name = "lambda_run_check_logs_policy"
    role = "${aws_iam_role.lambda_run_check.id}"
    policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:PutLogEvents"
      ],
      "Resource": [
        "arn:aws:logs:*:*:*"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "lambda_run_check_sns_policy" {
    name = "lambda_run_check_sns_policy"
    role = "${aws_iam_role.lambda_run_check.id}"
    policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "sns:Publish"
            ],
            "Resource": [
                "${aws_sns_topic.check_results.arn}"
            ]
        }
    ]
}
EOF
}

resource "aws_lambda_function" "lambda_run_check" {
    filename = "lambdas.zip"
    depends_on = ["aws_sns_topic.check_runner"]
    function_name = "lambda_run_check"
    description = "run a check"
    role = "${aws_iam_role.lambda_run_check.arn}"
    handler = "lambda_run_check.lambda_handler"
    runtime = "python2.7"
    timeout = "120"

    //
    // 1. we have to manually call the aws-cli to give SNS permission to invoke this lambda func.
    // lambda function to allow SNS to invoke it.
    //
    provisioner "local-exec" {
    command = <<EOF
export AWS_ACCESS_KEY=${var.aws_access_key}; \
export AWS_SECRET_KEY=${var.aws_secret_key}; \
aws lambda remove-permission \
    --statement-id lambda_run_check_sns \
    --region ${var.aws_region} \
    --function-name lambda_run_check; \
aws lambda add-permission \
    --statement-id lambda_run_check_sns \
    --region ${var.aws_region} \
    --function-name lambda_run_check \
    --principal 'sns.amazonaws.com' \
    --action 'lambda:InvokeFunction' \
    --source-arn '${aws_sns_topic.check_runner.arn}'
EOF
    }
}

// 2. subscribe Lambda function to the SNS topic 'check_runner'
resource "aws_sns_topic_subscription" "check_runner" {
  depends_on = ["aws_lambda_function.lambda_run_check"]
  topic_arn = "${aws_sns_topic.check_runner.arn}"
  protocol = "lambda"
  endpoint = "${aws_lambda_function.lambda_run_check.arn}"
}

output "lambda_run_check.arn" { value = "${aws_lambda_function.lambda_run_check.arn}" }
