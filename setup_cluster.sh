#!/usr/bin/env bash
set -eu

APPREMOTEWRITEURL=$(aws ssm get-parameter --name /Terraform/Prometheus/WriteEndpoint --query Parameter.Value)
TERRAFORMVPCSUBNET=$(aws ssm get-parameter --name /Terraform/VPC/PrivateSubnet --query Parameter.Value)
TERRAFORMSECURITYGROUP=$(aws ssm get-parameter --name /Terraform/VPC/SecurityGroup --query Parameter.Value)
TERRAFORMIAMROLE=$(aws ssm get-parameter --name /Terraform/IAM/HyperPodRole --query Parameter.Value)
TERRAFORMS3BUCKET="s3://$(aws ssm get-parameter --name /Terraform/S3/HyperPodBucket --query Parameter.Value --output text)/lifecycle-config/"
TERRAFORMFSXDNSNAME=$(aws ssm get-parameter --name /Terraform/FSx/HyperPodLustreDNSName --query Parameter.Value)
TERRAFORMFSXMOUNTNAME=$(aws ssm get-parameter --name /Terraform/FSx/HyperPodLustreMountName --query Parameter.Value)
echo "Value for APPREMOTEWRITEURL:  ${APPREMOTEWRITEURL}"
echo "Value for TERRAFORMVPCSUBNET: ${TERRAFORMVPCSUBNET}"
echo "Value for TERRAFORMSECURITYGROUP:  ${TERRAFORMSECURITYGROUP}"
echo "Value for TERRAFORMIAMROLE:  ${TERRAFORMIAMROLE}"
echo "Value for TERRAFORMS3BUCKET:  ${TERRAFORMS3BUCKET}"
echo "Value for TERRAFORMFSXDNSNAME:  ${TERRAFORMFSXDNSNAME}"
echo "Value for TERRAFORMFSXMOUNTNAME:  ${TERRAFORMFSXMOUNTNAME}"



echo "Writing to cluster-config.json"

cat << EOF > cluster-config.json
{
    "ClusterName": "ml-cluster",
    "InstanceGroups": [
      {
        "InstanceGroupName": "controller-machine",
        "InstanceType": "ml.m5.2xlarge",
        "InstanceCount": 1,
        "LifeCycleConfig": {
          "SourceS3Uri": ${TERRAFORMS3BUCKET},
          "OnCreate": "on_create.sh"
        },
        "ExecutionRole": ${TERRAFORMIAMROLE},
        "ThreadsPerCore": 1
      },
      {
        "InstanceGroupName": "compute-nodes",
        "InstanceType": "ml.g5.2xlarge",
        "InstanceCount": 2,
        "LifeCycleConfig": {
          "SourceS3Uri": ${TERRAFORMS3BUCKET},
          "OnCreate": "on_create.sh"
        },
        "ExecutionRole": ${TERRAFORMIAMROLE},
        "ThreadsPerCore": 1
      }
    ],
    "VpcConfig": {
      "SecurityGroupIds": [${TERRAFORMSECURITYGROUP}],
      "Subnets":[${TERRAFORMVPCSUBNET}]
    }
}
EOF

echo "Writing to provisioning_parameters.json"

cat << EOF > ./LifecycleConfig/provisioning_parameters.json
{
  "version": "1.0.0",
  "workload_manager": "slurm",
  "controller_group": "controller-machine",
  "login_group": "my-login-group",
  "worker_groups": [
    {
      "instance_group_name": "compute-nodes",
      "partition_name": "dev"
    }
  ],
"fsx_dns_name": $TERRAFORMFSXDNSNAME,
"fsx_mountname": $TERRAFORMFSXMOUNTNAME
}
EOF

echo "Uploading LifeCycleConfig to S3:  ${TERRAFORMS3BUCKET}"
aws s3 sync ./LifecycleConfig $TERRAFORMS3BUCKET
