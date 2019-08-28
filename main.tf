/* ========================================================================= */
/* ======== basic kubernetes set up code =================================== */
/* ========================================================================= */

terraform {
  required_version = "~> 0.11"
}

/* ======== VARIABLES ====================================================== */
variable "aws_provider_region"  { default = "us-west-2"               }
variable "environment"          { default = "staging"                 }
variable "cluster_name"         { default = "paolo-cluster"           }
variable "master_instance_size" { default = "t2.medium"               }
variable "node_instance_size"   { default = "t2.medium"               }
variable "node_count"           { default = "2"                       }
variable "kubernetes_version"   { default = "1.12.8"                  }
variable "tl_domain"            { default = "YOUR-DOMAIN.NET"         }
variable "vpc_cidr"             { default = "10.78.0.0/16"            }

/* ======== DATA =========================================================== */

data "aws_availability_zones" "available" {}

/* ======== AWS bootstap =================================================== */

provider "aws" {
  region                  = "${var.aws_provider_region}"
  shared_credentials_file = "$HOME/.aws/credentials"
  profile                 = "default"
}

/* ======== S3 BUCKET TO STORE STATE ======================================= */

resource "aws_s3_bucket" "k8s-state" {
  bucket_prefix = "${var.cluster_name}-${var.environment}-k8s-state"
  acl           = "private"
  versioning {
    enabled = true
  }
}

/* ======== NETWORK/VPC ==================================================== */

module "k8s-vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "1.64.0"
  name = "${var.cluster_name}-${var.environment}-k8s-vpc"
  cidr = "10.0.0.0/16"
  azs             = ["${data.aws_availability_zones.available.names[0]}", "${data.aws_availability_zones.available.names[1]}"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]
  assign_generated_ipv6_cidr_block = true
  enable_nat_gateway = false
  public_subnet_tags = {
    Name = "${var.cluster_name}-${var.environment}-k8s-pub-sn"
  }
  vpc_tags = {
    Name = "${var.cluster_name}-${var.environment}-k8s-vpc"
  }
}

/* ======== NETWORK/DNS ==================================================== */

resource "aws_route53_zone" "private" {
  name = "${var.tl_domain}"
  vpc {
    vpc_id = "${module.k8s-vpc.vpc_id}"
  }
}

/* ======== KUBERNETES ITSELF ============================================== */

resource "null_resource" "kops" {
  triggers {
      rerun = "${uuid()}"
  }

  provisioner "local-exec" {
    command = "kops create cluster --name=${var.cluster_name}.${var.tl_domain} --cloud=aws --zones=${module.k8s-vpc.azs[0]},${module.k8s-vpc.azs[1]} --master-size=${var.master_instance_size} --node-count=${var.node_count} --node-size=${var.node_instance_size} --master-zones=${module.k8s-vpc.azs[0]}  --state=s3://${aws_s3_bucket.k8s-state.id} --kubernetes-version ${var.kubernetes_version}   --out=kops-outputs --target=terraform"
  }

  provisioner "local-exec" {
    command = "cd ./kops-outputs && terraform init && echo \"yes\" | terraform apply && echo \"K8s cluster started. Wait some minutes before login to it.\" && sleep 420"
  }

  provisioner "local-exec" {
    when    = "destroy"
    command = "cd ./kops-outputs && echo \"yes\" | terraform destroy"
  }

  depends_on = ["aws_s3_bucket.k8s-state","aws_route53_zone.private"]

}
