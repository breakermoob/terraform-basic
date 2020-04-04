provider "aws" {
  region = "us-east-2"
}

#Vars
variable "server_port" {
  description = "this is the port of the server, we will use for the HTTP request"
  default     = 8080
}
variable "lb_port" {
  description = "this is the port of the server, we will use for the HTTP request"
  default     = 80
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

  //Load Balancer and Health check
  load_balancers    = ["${aws_elb.example.name}"]
  health_check_type = "ELB"

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

//elastic load balancer
resource "aws_elb" "example" {

  name = "terraform-leon-cluster"

  availability_zones = "${data.aws_availability_zones.all.names}"
  security_groups    = ["${aws_security_group.elb.id}"]

  listener {

    lb_port     = "${var.lb_port}"
    lb_protocol = "http"

    instance_port     = "${var.server_port}"
    instance_protocol = "http"
  }

  //This send an internal request each 30 seconds
  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    interval            = 30
    target              = "HTTP:${var.server_port}/"
  }

}

resource "aws_security_group" "elb" {
  name = "terraform-leon-elb"

  ingress {
    from_port   = "${var.lb_port}"
    to_port     = "${var.lb_port}"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  //Open all ports
  egress {
    from_port = 0
    to_port   = 0
    //all protocols
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

output "elb_dns_name" {
  value = "${aws_elb.example.dns_name}"
}




#Terraform init for create the proyect structure
#Terraform plan for review the proyect changes or errors
#Terraform apply for create the proyect

#Terraform graph -> Show the dependencies from the proyect
#We can past the result on this page for vizualize the graph
#http://dreampuf.github.io/GraphvizOnline/
