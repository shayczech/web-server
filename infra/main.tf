# ------------------------------------------------------------------------------
# Provider and root module
# ------------------------------------------------------------------------------

provider "aws" {
  region = "us-east-2"
}

module "web_server" {
  source = "./modules/ec2-webserver"

  ami_id          = var.ami_id
  instance_type   = var.instance_type
  key_name        = "new-secure-key"
  index_html_path = "${path.root}/index.html"
  server_name     = "web-server"
}
