bucket         = "terraform-state-nfs-storage"
key            = "nfs/terraform.tfstate"
region         = "us-east-1"
encrypt        = true
dynamodb_table = "terraform-state-lock-nfs"
