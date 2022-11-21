resource "aws_lambda_function" "streaming" {
  for_each         = toset(var.table_name)
  function_name    = "streaming-${each.value}"
  role             = aws_iam_role.streaming.arn
  handler          = "${each.value}.handler"
  runtime          = "nodejs12.x"
  filename          = "/Users/venkataraj/openserach-dynamodb/modules/lambda/oslash.zip"
#  source_code_hash = data.archive_file.streaming[each.value].output_base64sha256
  layers           = [aws_lambda_layer_version.layer.arn]
  timeout          = 300

  environment {
    variables = {
      ENDPOINT = var.endpoint
      INDEX    = each.value
    }
  }

#   vpc_config {
#     security_group_ids = [$SECURITY_GROUP_ID]
#     subnet_ids         = [$SUBNET_ID]
#   }
}
#data "archive_file" "streaming" {
#  for_each    = toset(var.table_name)
#  type        = "zip"
#  source_file = "${sourceCodePath}/oslash.js"
#  output_path = "${sourceCodePath}/oslash.zip"
#}

resource "aws_lambda_layer_version" "layer" {
  filename             = "/Users/venkataraj/openserach-dynamodb/modules/lambda/layers.zip"
  #source_code_hash    = data.archive_file.layer.output_base64sha256
  layer_name          = "layer"
  compatible_runtimes = ["nodejs12.x"]
}

#data "archive_file" "layer" {
#  type        = "zip"
#  source_dir  = "${sourceCodePath}/layers"#"${path.module}/layer"
#  output_path = "${sourceCodePath}/layers.zip"#"${path.module}/layer.zip"
#}

resource "aws_lambda_event_source_mapping" "stream_mapping" {
  for_each          = toset(var.table_name)
  batch_size        = 100
  event_source_arn  = var.dynamodb_table_arn
  function_name     = aws_lambda_function.streaming[each.value].arn
  starting_position = "LATEST"
  depends_on        = [aws_iam_role.streaming]
}