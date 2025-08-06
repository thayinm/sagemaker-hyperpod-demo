# SageMaker HyperPod Demo

This repository is designed to serve as a guide on how to get started with running & maintaining your own SageMaker HyperPod Cluster. Terraform is used to quickly and easily setup all the infrastructure you may want/need for our HyperPod Cluster:

- Our own VPC with a public & private subnet as well as a NAT gateway to route traffic from our private subnet through the IGW. See the SageMaker [documentation](https://docs.aws.amazon.com/sagemaker/latest/dg/infrastructure-connect-to-resources.html) for more details.
- A FSx Filesystem that will be used by all our nodes during training.
- An S3 Bucket to store our Lifecyle Configuration.
- The IAM role that will have the necessary permissions to create the cluster.
- Amazon Prometheus to enable observability of our cluster.
- Usage of SSM Parameter Store that will allow us to retrive key information about our infrastructure for use in both the lifecycle script and our AWS CLI command that will spin up the cluster (since this is not available in Terraform as of now.)
- Optionally deploy an EKS Cluster with Addons for use as the orchestration strategy.

Based on the [awsome-distributed-training](https://github.com/aws-samples/awsome-distributed-training) repository provided by AWS.

## Getting Started

### Prerequisites

You need to ensure that the following packages/programs are installed before getting started:

- [jq](https://jqlang.org/download/)
- [Terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)
- [AWS CLI V2](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
- [SessionManagerPlugin for the AWS CLI](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html)

### Prerequisites for EKS Orchestration (Optional)

If you are going to use an EKS Cluster for Orchestration then the following packages/programs should also be installed:

- [Kubectl](https://kubernetes.io/docs/tasks/tools/)
- [Helm](https://helm.sh/docs/intro/install/)

### Installation (Slurm)

First clone this repo and navigate to Terraform

```shell
git clone https://github.com/thayinm/sagemaker-hyperpod-demo.git && cd sagemaker-hyperpod-demo/Terraform
```

Next initialise Terraform and its modules then deploy. Make sure you have sufficient IAM permissions to create these resources, Terraform will utilise your credentials similar to how the AWS CLI does this to provision its resources.

```shell
terraform init && terraform plan
terraform apply -auto-approve
```

Now you can go back to our root folder and create 2 files that are necessary for spinning up a cluster. The first being a [provisioning_parameters.json](https://docs.aws.amazon.com/sagemaker/latest/dg/sagemaker-hyperpod-lifecycle-best-practices-slurm-base-config.html) file that is going to be used by each of our nodes when running the `on_create.sh` Lifecycle Script and the second being an `cluster_config.json` file which you will use as input for the AWS CLI command to finally start cluster creation. Be sure to enter `slurm` when prompted.

```shell
cd ..
chmod +x setup_cluster.sh
./setup_cluster.sh
```

Once you have generated both files you can now create the cluster. You will need to wait until the cluster has completed its setup (approx. 10 mins) before using `easy-ssh.sh` to ssh into our cluster.

```shell
aws sagemaker create-cluster --cli-input-json file://cluster-config.json
chmod +x easy-ssh.sh
./easy-ssh.sh ml-cluster
```

Now that you have access to our head node in the cluster you can switch from the root user to the ubuntu user and get started with some training.

```shell
sudo su ubuntu
```

### Installation (EKS)

First clone this repo and navigate to Terraform

```shell
git clone https://github.com/thayinm/sagemaker-hyperpod-demo.git && cd sagemaker-hyperpod-demo/Terraform
```

In Terraform you will need to uncomment the last few lines in `main.tf` to deploy an EKS cluster with the required Addons into your VPC.

```terraform
## FOR SM HYPERPOD EKS UNCOMMENT THE BELOW
  eks_cluster_arn  = module.eks.eks_cluster_arn
  eks_cluster_name = module.eks.eks_cluster_name
}

## FOR SM HYPERPOD EKS UNCOMMENT THE BELOW

module "eks" {
  source                = "./modules/eks"
  private_subnets       = module.sagemaker_vpc.private_subnet_ids
  eks_security_group_id = module.sagemaker_vpc.security_group_id
  kubernetes_version    = "1.32"
}
```

Once complete you can now run the following commands in the terminal to deploy all infrastructure to you AWS Account:

```bash
terraform init && terraform plan
terraform apply -auto-approve
```

Now go back to the root directory and run the `setup_cluster.sh` script to create several config files that can then be used to setup the EKS Cluster and create the Hyperpod Cluster. Be sure to enter `eks` when prompted.

```bash
cd ..
chmod +x setup_cluster.sh
./setup_cluster.sh
```

The following files will be generated, the .yaml files enable connection to the FSx Lustre Volume:

- cluster_config.json
- pv.yaml
- pvc.yaml
- storageclass.yaml

Before creation of the HyperPod Cluster, install all packages from the Helm Chart onto the EKS Cluster. First add your AWS EKS credentials to Kube config then update & install the Helm Chart.

```bash
EKS_CLUSTER_NAME=$(aws ssm get-parameter --name /Terraform/EKS/HyperpodClusterName --query Parameter.Value)
aws eks update-kubeconfig --name $EKS_CLUSTER_NAME

cd helm_chart
helm dependencies update HyperPodHelmChart
```

Test the Helm Chart

```bash
helm lint HyperPodHelmChart
```

Conduct a dry run

```bash
helm install hyperpod-dependencies HyperPodHelmChart --dry-run
```

Finally deploy & verify the Helm Chart

```bash
helm install dependencies HyperPodHelmChart --namespace kube-system
helm list
cd ..
```

Deploy the HyperPod Cluster, once deployed check that its available in EKS

```bash
aws sagemaker create-cluster --cli-input-json file://cluster-config.json
kubectl get nodes
```

Setup FSx Luster Volume for use by HyperPod in EKS

```bash
kubectl apply -f storageclass.yaml
kubectl apply -f pv.yaml
kubectl apply -f pvc.yaml
```

## Clean Up
To clean up our resources you must first delete the cluster (wait for it to be deleted completely) and then you can bring down the Terraform stack

```shell
aws sagemaker delete-cluster --cluster-name ml-cluster
cd Terraform && terraform destroy
```
