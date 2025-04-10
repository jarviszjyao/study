bucket         = "terraform-state-company-name"
key            = "nat-gateway/terraform.tfstate"
region         = "eu-west-1"
encrypt        = true
dynamodb_table = "terraform-locks"
