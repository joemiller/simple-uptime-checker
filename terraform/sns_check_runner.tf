resource "aws_sns_topic" "check_runner" {
  name = "check_runner"
}

output "sns_check_runner.arn" { value = "${aws_sns_topic.check_runner.arn}" }
