provider "aws" {
   region = "us-east-2"
}

resource "aws_instance" "example"{
   ami = "ami-0520e698dd500b1d1" 
   instance_type = "t2.nano"

   tags = {
      Name ="terraform-leon"
   }
}