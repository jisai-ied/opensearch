# Create Segurity Group
resource "aws_security_group" "opensearch" {
  name        = "opensearch"
  description = "Security Group for Opensearch deployment"
  vpc_id      = data.terraform_remote_state.cloudicity_core.outputs.vpc_id
}