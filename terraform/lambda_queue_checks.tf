resource "aws_iam_role" "lambda_queue_checks" {
    name = "lambda_queue_checks"
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

resource "aws_iam_role_policy" "lambda_queue_checks_logs_policy" {
    name = "lambda_queue_checks_logs_policy"
    role = "${aws_iam_role.lambda_queue_checks.id}"
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

resource "aws_iam_role_policy" "lambda_queue_checks_sns_policy" {
    name = "lambda_queue_checks_sns_policy"
    role = "${aws_iam_role.lambda_queue_checks.id}"
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
                "${aws_sns_topic.check_runner.arn}"
            ]
        }
    ]
}
EOF
}

resource "aws_lambda_function" "lambda_queue_checks" {
    filename = "lambdas.zip"
    function_name = "lambda_queue_checks"
    description = "queue checks to execute"
    role = "${aws_iam_role.lambda_queue_checks.arn}"
    handler = "lambda_queue_checks.lambda_handler"
    runtime = "python2.7"
    timeout = "120"
}

output "lambda_queue_checks.arn" { value = "${aws_lambda_function.lambda_queue_checks.arn}" }
