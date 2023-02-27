terraform {
  required_version = ">= 1.3.2"

  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "~> 1.48.0"
    }
    infoblox = {
      # source = "infobloxopen/infoblox"

      # infoblox 2.2.0 returns an error when creating an A-record. The
      # workaround is to use version 2.1.0.
      # If you're using mac with Apple silicon then you'd have to build
      # version 2.1.0 yourself, place it in the following directory:
      #  ~/.terraform.d/plugins/terraform.local/local/infoblox/2.1.0/darwin_arm64/terraform-provider-infoblox_v2.1.0
      # and modify the source attribute as shown below
      source  = "terraform.local/local/infoblox"

      version = "2.1.0"
    }
  }
}

variable "openstack_project" {}

provider "openstack" {
  cloud = var.openstack_project
}

variable "infoblox_server" {}
variable "infoblox_username" {}

provider "infoblox" {
  server   = var.infoblox_server
  username = var.infoblox_username
}
