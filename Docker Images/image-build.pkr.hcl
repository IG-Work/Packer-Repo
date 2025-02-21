packer {
  required_plugins {
    docker = {
      version = ">= 1.0.8"
      source  = "github.com/hashicorp/docker"
    }
  }
}

variable "docker_image" {
  type    = string
  default = "ubuntu:jammy"
}

source "docker" "ubuntu" {
  image  = var.docker_image
  commit = true
}

source "docker" "ubuntu-focal" {
  image  = "ubuntu:focal"
  commit = true
}

build {
  name = "learn-packer"
  sources = [
    "source.docker.ubuntu",
    "source.docker.ubuntu-focal",
  ]

  provisioner "shell" {
    environment_vars = [
      "FOO=hello world",
    ]
    inline = [
      "echo Adding file to Docker Container",
      "echo \"FOO is $FOO\" > example.txt",
    ]
  }

  provisioner "shell" {
    inline = ["echo Running ${var.docker_image} Docker image."]
  }

  post-processor "docker-tag" {
    repository = "docker.io"
    tags       = ["ubuntu-jammy", "packer-rocks1"]
    only       = ["docker.ubuntu"]
  }

  post-processor "docker-tag" {
    repository = "docker.io"
    tags       = ["ubuntu-focal", "packer-rocks2"]
    only       = ["docker.ubuntu-focal"]
  }
  /*post-processor "docker-import" {
    repository = "swampdragons/testpush"
    tag        = "0.7"
  }
  post-processor "docker-push" {}*/
}