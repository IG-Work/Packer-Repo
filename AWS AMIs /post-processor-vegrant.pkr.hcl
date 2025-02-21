packer {
  required_plugins {
    amazon = {
      version = "= 1.3.3"
      source  = "github.com/hashicorp/amazon"
    }
    vagrant = {
      version = ">= 1.1.1"
      source = "github.com/hashicorp/vagrant"
    }
  }
}

variable "ami_prefix" {
  type    = string
  default = "nginx-packer-var"
}

locals {
  timestamp = regex_replace(timestamp(), "[- TZ:]", "")
}

source "amazon-ebs" "ubuntu" {
  ami_name      = "ubuntu-aws-nginx"
  instance_type = "t2.micro"
  region        = "ap-south-1"
  source_ami_filter {
    filters = {
      name                = "ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-20250115"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["099720109477"]
  }
  ssh_username = "ubuntu"
}

source "amazon-ebs" "ubuntu-focal" {
  ami_name      = "${var.ami_prefix}-focal-${local.timestamp}"
  instance_type = "t2.micro"
  region        = "ap-south-1"
  source_ami_filter {
    filters = {
      name                = "ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-20250115"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["099720109477"]
  }
  ssh_username = "ubuntu"
}

build {
  name = "build1"
  sources = [
    "source.amazon-ebs.ubuntu",
    "source.amazon-ebs.ubuntu-focal"
  ]

  provisioner "shell" {
    environment_vars = [
      "FOO=hello world",
    ]
    inline = [
      "echo Installing Nginx",
      "sleep 30",
      "sudo apt update",
      "sudo apt install -y nginx",
      "echo \"FOO is $FOO\" > /tmp/example.txt",
    ]
  }

  post-processors {
    post-processor "vagrant" {
      output = "output-vagrant/ubuntu-{{timestamp}}.box"
    }
    post-processor "compress" {
      output = "output-image/ubuntu-{{timestamp}}.tar.gz"
    }

    # Shell post-processor to delete the AMI and snapshots
    /*post-processor "shell" {
      inline = [
        # Deregister the AMI using the artifact ID
        "aws ec2 deregister-image --image-id ${artifact.id}",
        
        # Retrieve the snapshot ID associated with the AMI and delete it
        "SNAPSHOT_ID=$(aws ec2 describe-images --image-ids ${artifact.id} --query 'Images[0].BlockDeviceMappings[0].Ebs.SnapshotId' --output text)",
        "aws ec2 delete-snapshot --snapshot-id $SNAPSHOT_ID"
      ]
    }*/
  }
}
