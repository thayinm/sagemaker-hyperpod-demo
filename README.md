# SageMaker HyperPod Demo

This repository is designed to serve as a guide on how to get started with running & maintaining your own SageMaker HyperPod Cluster. Terraform is used to quickly and easily setup all the infrastructure we may want/need for our HyperPod Cluster:

- Our own VPC with a public & private subnet as well as a NAT gateway to route traffic from our private subnet through the IGW. See the SageMaker [documentation](https://docs.aws.amazon.com/sagemaker/latest/dg/infrastructure-connect-to-resources.html) for more details.
- A FSx Filesystem that will be used by all our nodes during training.
- An S3 Bucket to store our Lifecyle Configuration.
- The IAM role that will have the necessary permissions to create the cluster.
- Amazon Prometheus to enable observability of our cluster.
- Usage of SSM Parameter Store that will allow us to retrive key information about our infrastructure for use in both the lifecycle script and our AWS CLI command that will spin up the cluster (since this is not available in Terraform as of now.)

Based on the [awsome-distributed-training](https://github.com/aws-samples/awsome-distributed-training) repository provided by AWS.

## Getting Started

### Prerequisites

We need to ensure that the following packages/programs are installed before getting started:

- [jq](https://jqlang.org/download/)
- [Terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)
- [AWS CLI V2](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
- [SessionManagerPlugin for the AWS CLI](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html)

### Installation

First clone this repo and navigate to Terraform

```shell
git clone https://github.com/thayinm/sagemaker-hyperpod-demo.git && cd sagemaker-hyperpod-demo/Terraform
```

Next initialise Terraform and its modules then deploy. Make sure you have sufficient IAM permissions to create these resources, Terraform will utilise your credentials similar to how the AWS CLI does this to provision its resources.

```shell
terraform init && terraform plan
terraform apply -auto-approve
```

Now we can go back to our root folder and create 2 files that are necessary for spinning up a cluster. The first being a [provisioning_parameters.json](https://docs.aws.amazon.com/sagemaker/latest/dg/sagemaker-hyperpod-lifecycle-best-practices-slurm-base-config.html) file that is going to be used by each of our nodes when running the `on_create.sh` Lifecycle Script and the second being an `input-cli-json` file which we will use as input for the AWS CLI command to finally start cluster creation.

```shell
cd ..
chmod +x setup_cluster.sh
./setup_cluster.sh
```

Once we have generated both files we can now create the cluster. We will need to wait until the cluster has completed its setup (approx. 10 mins) before using `easy-ssh.sh` to ssh into our cluster.

```shell
aws sagemaker create-cluster --cli-input-json file://cluster-config.json
chmod +x easy-ssh.sh
./easy-ssh.sh ml-cluster
```

Now that we have access to our head node in the cluster we can switch from the root user to the ubuntu user and get started with some training.

```shell
sudo su ubuntu
```

## Clean Up
To clean up our resources we must first delete the cluster (wait for it to be deleted completely) and then we can bring down the Terraform stack

```shell
aws sagemaker delete-cluster --cluster-name ml-cluster
cd Terraform && terraform destroy
```
