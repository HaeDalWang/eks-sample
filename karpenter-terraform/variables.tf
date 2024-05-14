variable "aws_auth_mapRoles" {
  description = "AWS auth data"
  type = list(any)
  default = []
}

variable "aws_auth_mapUsers" {
  description = "AWS auth data"
  type = list(any)
  default = []
}
variable "aws_auth_mapAccounts" {
  description = "AWS auth data"
  type = list(any)
  default = []
}