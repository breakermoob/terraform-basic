provider "aws" {
   region = "us-east-2"
}

resource "aws_instance" "example"{

   #Type of machine
   ami = "ami-0fc20dd1da406780b" 
   instance_type = "t2.micro"

   #Add security gruop for expose the ports, with this we can get the id from the security group
   vpc_security_group_ids = ["${aws_security_group.instance.id}"]

   user_data = <<-EOF
               #!/bin/bash
               echo "Hello, World Leon!" > index.html
               nohub busybox https -f -p 8080 & 
               EOF

   tags = {
      Name ="terraform-leon"
   }
}

resource "aws_security_group" "instance" {
   name = "terraform-leon"

   ingress{
      //Ports Range
      from_port = 8080
      to_port = 8080

      protocol = "tcp"

      #For all
      cidr_blocks = ["0.0.0.0/0"]
   }
}

#Terraform init for create the proyect structure
#Terraform plan for review the proyect changes or errors
#Terraform apply for create the proyect

#Terraform graph -> Show the dependencies from the proyect
#We can past the result on this page for vizualize the graph
#http://dreampuf.github.io/GraphvizOnline/