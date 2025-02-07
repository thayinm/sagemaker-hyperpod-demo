# sagemaker-hyperpod-demo
This repository is designed to serve as a guide on how to get started with running & maintaining your own SageMaker HyperPod Cluster. Terraform is used to quickly and easily setup all the infrastructure we may want/need for our HyperPod Cluster:
- Our own VPC with a public & private subnet as well as a NAT gateway to route traffic from our private subnet through the IGW. See the SageMaker [documentation](https://docs.aws.amazon.com/sagemaker/latest/dg/infrastructure-connect-to-resources.html) for more details.
- A FSx Filesystem that will be used by all our nodes during training.
- An S3 Bucket to store our Lifecyle Configuration.
- The IAM role that will have the necessary permissions to create the cluster.
- Amazon Prometheus to enable observability of our cluster.
- Usage of SSM Parameter Store that will allow us to retrive key information about our infrastructure for use in both the lifecycle script and our AWS CLI command that will spin up the cluster (since this is not available in Terraform as of now.)

## Getting Started
### Prerequisites
We need to ensure that the following packages/programs are installed before getting started:
- [jq](https://jqlang.org/download/)
- [terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)
- [awscli v2](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)

### Installation
First clone this repo and navigate to Terraform

```shell
git clone https://github.com/thayinm/sagemaker-hyperpod-demo.git && cd sagemaker-hyperpod-demo
```

Next initialise Terraform and its modules then deploy. Make sure you have sufficient IAM permissions to create these resources, Terraform will utilise your credentials similar to how the AWS CLI does this to provision its resources.

```shell
terraform init && terraform plan
terraform apply -auto-approve
```