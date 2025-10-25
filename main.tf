# --- Configure the AWS Provider ---
provider "aws" {
  region = "us-east-2" # Or your preferred region
}

# REPLACE IT WITH THIS DATA SOURCE:
data "aws_key_pair" "existing_key" {
  key_name = "web-key" # This must match the name of the key pair in your AWS Console
}

# --- Call the Web Server Module ---
module "web_server" {
  # Path to the module directory relative to this file
  source = "./modules/ec2-webserver"
  # --- Provide values for the module's input variables ---
  ami_id          = var.ami_id                        # Pass the value from the root variables.tf
  instance_type   = var.instance_type                 # Pass the value from the root variables.tf
  key_name        = data.aws_key_pair.existing_key.key_name  # Updated to use the data source
  index_html_path = "${path.root}/index.html"         # Provide the path to the index.html file in the root directory
  server_name     = "web-server"                      # Optionally override the default name (defined in module variables.tf)
}
