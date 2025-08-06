#!/usr/bin/env bash
set -eu

read -p "Enter your Orchestration method for HyperPod (slurm/eks): " ORCH
read -p "Enter an instance type for your compute-nodes (default: ml.g5.12xlarge): " INSTANCETYPE
read -p "How many instances should be part of the compute-nodes group (default: 1): " INSTANCECOUNT

if [ -z $ORCH ]; then
  echo "Defaulting to Slurm Orchestration"
  ORCH=slurm
fi

if [ -z "$INSTANCETYPE" ]; then
  echo "Defaulting to ml.g5.12xlarge"
  INSTANCETYPE="ml.g5.12xlarge"
fi

if [ -z "$INSTANCECOUNT" ]; then
  echo "Defaulting to 1 instance"
  INSTANCECOUNT=1
fi

hyperpod_regex="^(ml\.p3\.|ml\.p4d\.|ml\.p5\.|ml\.g4dn\.|ml\.g5\.|ml\.trn1\.|ml\.inf1\.|ml\.inf2\.)"

if ! [[ "$INSTANCETYPE" =~ $hyperpod_regex ]]; then
  echo "Error: Instance type '$INSTANCETYPE' does not match pattern for HyperPod-compatible instances."
  echo "HyperPod requires GPU or accelerator-equipped instances (p3, p4d, p5, g4dn, g5, trn1, inf1, inf2)."
  exit 1
fi

if ! [[ $INSTANCECOUNT -ge 1 ]]; then
  echo "Instance count must be an integer greater than 0"
  exit 1
fi

echo "Gathering values from Parameter Store, this may take a while"

APPREMOTEWRITEURL=$(aws ssm get-parameter --name /Terraform/Prometheus/WriteEndpoint --query Parameter.Value)
TERRAFORMVPCSUBNET=$(aws ssm get-parameter --name /Terraform/VPC/PrivateSubnet --query Parameter.Value)
TERRAFORMSECURITYGROUP=$(aws ssm get-parameter --name /Terraform/VPC/SecurityGroup --query Parameter.Value)
TERRAFORMIAMROLE=$(aws ssm get-parameter --name /Terraform/IAM/HyperPodRole --query Parameter.Value)
TERRAFORMS3BUCKET="s3://$(aws ssm get-parameter --name /Terraform/S3/HyperPodBucket --query Parameter.Value --output text)/lifecycle-config/"
TERRAFORMFSXDNSNAME=$(aws ssm get-parameter --name /Terraform/FSx/HyperPodLustreDNSName --query Parameter.Value)
TERRAFORMFSXMOUNTNAME=$(aws ssm get-parameter --name /Terraform/FSx/HyperPodLustreMountName --query Parameter.Value)
TERRAFORMFSXFILESYSTEMID=$(aws ssm get-parameter --name /Terraform/FSx/HyperPodLustreFilesystemId --query Parameter.Value)
TERRAFORMEKSCLUSTERNAME=$(aws ssm get-parameter --name /Terraform/EKS/HyperpodClusterName --query Parameter.Value)
TERRAFORMEKSCLUSTERARN=$(aws ssm get-parameter --name /Terraform/EKS/HyperpodClusterARN --query Parameter.Value)
echo "Value for APPREMOTEWRITEURL:  ${APPREMOTEWRITEURL}"
echo "Value for TERRAFORMVPCSUBNET: ${TERRAFORMVPCSUBNET}"
echo "Value for TERRAFORMSECURITYGROUP:  ${TERRAFORMSECURITYGROUP}"
echo "Value for TERRAFORMIAMROLE:  ${TERRAFORMIAMROLE}"
echo "Value for TERRAFORMS3BUCKET:  ${TERRAFORMS3BUCKET}"
echo "Value for TERRAFORMFSXDNSNAME:  ${TERRAFORMFSXDNSNAME}"
echo "Value for TERRAFORMFSXMOUNTNAME:  ${TERRAFORMFSXMOUNTNAME}"
echo "Value for TERRAFORMFSXFILESYSTEMID:  ${TERRAFORMFSXFILESYSTEMID}"
echo "Value for TERRAFORMEKSCLUSTERNAME:  ${TERRAFORMEKSCLUSTERNAME}"
echo "Value for TERRAFORMEKSCLUSTERARN:  ${TERRAFORMEKSCLUSTERARN}"


if [[ $ORCH == "eks" && $TERRAFORMEKSCLUSTERNAME == "DNE" ]]; then
  echo "EKS Cluster does not exist! Did you deploy this using Terraform?"
  exit 1
elif [[ $ORCH == "eks" && $TERRAFORMEKSCLUSTERNAME != "DNE" ]]; then
  echo "Prepping config for EKS Orchestration"
  cat << EOF > cluster-config.json
{
    "ClusterName": "ml-cluster",
    "Orchestrator": { 
      "Eks": 
      {
        "ClusterArn": ${TERRAFORMEKSCLUSTERARN}
      }
    },
    "InstanceGroups": [
      {
        "InstanceGroupName": "worker-group-1",
        "InstanceType": "${INSTANCETYPE}",
        "InstanceCount": ${INSTANCECOUNT},
        "InstanceStorageConfigs": [
          {
            "EbsVolumeConfig": {
              "VolumeSizeInGB": 500
            }
          }
        ],
        "LifeCycleConfig": {
          "SourceS3Uri": "${TERRAFORMS3BUCKET}eks",
          "OnCreate": "on_create.sh"
        },
        "ExecutionRole": ${TERRAFORMIAMROLE},
        "ThreadsPerCore": 2,
        "OnStartDeepHealthChecks": ["InstanceStress", "InstanceConnectivity"]
      },
      {
        "InstanceGroupName": "worker-group-2",
        "InstanceType": "ml.m5.2xlarge",
        "InstanceCount": 1,
        "InstanceStorageConfigs": [
          {
            "EbsVolumeConfig": {
              "VolumeSizeInGB": 500
            }
          }
        ],
        "LifeCycleConfig": {
          "SourceS3Uri": "${TERRAFORMS3BUCKET}eks",
          "OnCreate": "on_create.sh"
        },
        "ExecutionRole": ${TERRAFORMIAMROLE},
        "ThreadsPerCore": 1
      }
    ],
    "VpcConfig": {
      "SecurityGroupIds": [${TERRAFORMSECURITYGROUP}],
      "Subnets":[${TERRAFORMVPCSUBNET}]
    },
    "NodeRecovery": "Automatic"
}
EOF
  echo "Creating StorageClass yaml"
  cat << EOF > storageclass.yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: fsx-sc
provisioner: fsx.csi.aws.com
parameters:
  fileSystemId: $TERRAFORMFSXFILESYSTEMID # Replace with your FSx file system ID
  subnetId: $TERRAFORMVPCSUBNET  # Replace with your subnet ID
  securityGroupIds: $TERRAFORMSECURITYGROUP # Replace with your security group ID
EOF
  echo "Creating PersistentVolume yaml"
  cat << EOF > pv.yaml
  apiVersion: v1
  kind: PersistentVolume
  metadata:
    name: fsx-pv
  spec:
    capacity:
      storage: 1200Gi  # Adjust based on your FSx volume size
    volumeMode: Filesystem
    accessModes:
      - ReadWriteMany
    persistentVolumeReclaimPolicy: Retain
    storageClassName: fsx-sc
    csi:
      driver: fsx.csi.aws.com
      volumeHandle: $TERRAFORMFSXFILESYSTEMID  # Replace with your FSx file system ID
      volumeAttributes:
        dnsname: $TERRAFORMFSXDNSNAME  # Replace with your FSx file system DNS name
        mountname: $TERRAFORMFSXMOUNTNAME  # Replace with your FSx file system mountname
EOF
  echo "Creating PersistentVolumeClaim yaml"
  cat << EOF > pvc.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: fsx-claim
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: fsx-sc
  resources:
    requests:
      storage: 1200Gi  # Should match the PV size
EOF

  echo "Uploading LifeCycleConfig to S3:  ${TERRAFORMS3BUCKET}eks"
  aws s3 sync ./LifecycleConfig/eks "${TERRAFORMS3BUCKET}eks"
else
  echo "Prepping config for Slurm Orchestration"  
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
          "SourceS3Uri": "${TERRAFORMS3BUCKET}/slurm",
          "OnCreate": "on_create.sh"
        },
        "ExecutionRole": ${TERRAFORMIAMROLE},
        "ThreadsPerCore": 1
      },
      {
        "InstanceGroupName": "compute-nodes",
        "InstanceType": "${INSTANCETYPE}",
        "InstanceCount": ${INSTANCECOUNT},
        "LifeCycleConfig": {
          "SourceS3Uri": "${TERRAFORMS3BUCKET}",
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
  
  cat << EOF > ./LifecycleConfig/slurm/provisioning_parameters.json
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
  
  echo "Uploading LifeCycleConfig to S3:  ${TERRAFORMS3BUCKET}slurm"
  aws s3 sync ./LifecycleConfig/slurm "${TERRAFORMS3BUCKET}slurm"
fi
