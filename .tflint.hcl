config {
  module = false
  deep_check = true
  force = true
}
rule "terraform_dash_in_resource_name" {
  enabled = true
}
rule "terraform_documented_outputs" {
  enabled = true
}
rule "terraform_documented_variables" {
  enabled = true
}
