terraform {
  backend "s3" {
    bucket         = "cypress-studios-terraform-state"
    key            = "impostor-game/terraform.tfstate"
    region         = "us-west-2"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}


