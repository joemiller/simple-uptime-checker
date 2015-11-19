resource "aws_sns_topic" "check_results" {
  name = "check_results"
}

output "sns_check_results.arn" { value = "${aws_sns_topic.check_results.arn}" }
