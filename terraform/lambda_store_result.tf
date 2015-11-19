/*
 * This lambda is invoked by an SNS topic using the pattern described here:
 * https://github.com/hashicorp/terraform/issues/2885#issuecomment-152072270
 */

resource "aws_iam_role" "lambda_store_result" {
    name = "lambda_store_result"
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

resource "aws_iam_role_policy" "lambda_store_result_logs_policy" {
    name = "lambda_store_result_logs_policy"
    role = "${aws_iam_role.lambda_store_result.id}"
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

resource "aws_iam_role_policy" "lambda_store_result_sns_policy" {
    name = "lambda_store_result_sns_policy"
    role = "${aws_iam_role.lambda_store_result.id}"
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

resource "aws_lambda_function" "lambda_store_result" {
    filename = "lambdas.zip"
    depends_on = ["aws_sns_topic.check_results"]
    function_name = "lambda_store_result"
    description = "run a check"
    role = "${aws_iam_role.lambda_store_result.arn}"
    handler = "lambda_store_result.lambda_handler"
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
    --statement-id lambda_store_result_sns \
    --region ${var.aws_region} \
    --function-name lambda_store_result; \
aws lambda add-permission \
    --statement-id lambda_store_result_sns \
    --region ${var.aws_region} \
    --function-name lambda_store_result \
    --principal 'sns.amazonaws.com' \
    --action 'lambda:InvokeFunction' \
    --source-arn '${aws_sns_topic.check_results.arn}'
EOF
    }
}

// 2. subscribe Lambda function to the SNS topic 'check_results'
resource "aws_sns_topic_subscription" "check_results" {
  depends_on = ["aws_lambda_function.lambda_store_result"]
  topic_arn = "${aws_sns_topic.check_results.arn}"
  protocol = "lambda"
  endpoint = "${aws_lambda_function.lambda_store_result.arn}"
}

output "lambda_store_result.arn" { value = "${aws_lambda_function.lambda_run_check.arn}" }
