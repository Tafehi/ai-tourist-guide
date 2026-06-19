output "itineraries_table_name" {
  value = aws_dynamodb_table.itineraries.name
}

output "itineraries_table_arn" {
  value = aws_dynamodb_table.itineraries.arn
}

output "credits_table_name" {
  value = aws_dynamodb_table.credits.name
}

output "credits_table_arn" {
  value = aws_dynamodb_table.credits.arn
}
