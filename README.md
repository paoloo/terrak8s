# terrak8s

![CI status](https://github.com/paoloo/terrak8s/workflows/CI/badge.svg)

An experimental single-file kubernetes bootstrap with **terraform 0.11** and **kops**. The idea behind this is to create structures with the minimum to zero amount of human interaction and provide usable and replicable environments. Also, to make some tests using _Github Actions_.

## Usage

install **kops**, **terraform**, type:

```
terraform init && echo "yes" | terraform apply
```

Sit and wait. It will take a while to build but it will work. When it's over, we will have the following file structure:

```
paolo@daath ~/Workspace/DEVOPS/terrak8s/ $ tree
.
├── main.tf
├── kops-outputs
│   ├── data
│   │   ├── aws_iam_role_masters.paolo-cluster.YOUR-DOMAIN.NET_policy
│   │   ├── aws_iam_role_nodes.paolo-cluster.YOUR-DOMAIN.NET_policy
│   │   ├── aws_iam_role_policy_masters.paolo-cluster.YOUR-DOMAIN.NET_policy
│   │   ├── aws_iam_role_policy_nodes.paolo-cluster.YOUR-DOMAIN.NET_policy
│   │   ├── aws_key_pair_kubernetes.paolo-cluster.YOUR-DOMAIN.NET-695502361aa61660eb4c0bd2409db54a_public_key
│   │   ├── aws_launch_configuration_master-us-west-2a.masters.paolo-cluster.YOUR-DOMAIN.NET_user_data
│   │   └── aws_launch_configuration_nodes.paolo-cluster.YOUR-DOMAIN.NET_user_data
│   ├── kubernetes.tf
│   └── terraform.tfstate
└── terraform.tfstate

2 directories, 11 files
```

There will be outputs with endpoints and everything that you need to know.

Now you are ready to use your kubernetes cluster.

## Adding a applications

create a `deployment.yml` and just

```
kubectl apply -f deployment.yml
```

## Tests

this is also experimental but this repository is verified by *github actions* using a hashicorp docker image to test my code, as seen [here](https://github.com/paoloo/terrak8s/actions).

## TODO

- convert to terraform 0.12
