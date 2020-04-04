provider "aws" {
  region = "us-east-2"
}

#Vars
variable "server_port" {
  description = "this is the port of the server, we will use for the HTTP request"
  default     = 8080
}

//Return a Json with the availability zones
data "aws_availability_zones" "all" {}

#Objeto cluster for the machines configuration
resource "aws_launch_configuration" "example" {

  image_id        = "ami-0fc20dd1da406780b"
  instance_type   = "t2.micro"
  security_groups = ["${aws_security_group.instance.id}"]
  user_data       = <<-EOF
               #!/bin/bash
               echo "Hello, World Leon!" > index.html
               nohup busybox httpd -f -p "${var.server_port}" & 
               EOF

  //This help us to the high disponibility
  //Try to create the new resource first for don't generate unavailability
  lifecycle {
    create_before_destroy = true
  }
}

//this designate the configuration for the autoscaling
resource "aws_autoscaling_group" "example" {
  launch_configuration = "${aws_launch_configuration.example.id}"

  //indicate the name of zones
  availability_zones = "${data.aws_availability_zones.all.names}"

  //min and max number of machines
  min_size = 2
  max_size = 10

  tag {
    key   = "Name"
    value = "terraform-leon-cluster"

    //propagate the tags for all machines
    propagate_at_launch = true
  }
}

resource "aws_security_group" "instance" {
  name = "terraform-leon"

  ingress {

    //Ports Range usign the vars
    from_port = "${var.server_port}"
    to_port   = "${var.server_port}"

    protocol = "tcp"

    #For all
    cidr_blocks = ["0.0.0.0/0"]
  }
  //This help us to the high disponibility
  //Try to create the new resource first for don't generate unavailability
  lifecycle {
    create_before_destroy = true
  }
}


#Terraform init for create the proyect structure
#Terraform plan for review the proyect changes or errors
#Terraform apply for create the proyect

#Terraform graph -> Show the dependencies from the proyect
#We can past the result on this page for vizualize the graph
#http://dreampuf.github.io/GraphvizOnline/
