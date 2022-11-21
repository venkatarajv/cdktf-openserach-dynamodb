variable "table_name" {
    type = list(string)
    default = ["customers", "articles", "orders"]
}

variable "endpoint" {
  type = string
  default = "example.com"
}

variable "dynamodb_table_arn" {
  type = string
  default = "example.com"
}