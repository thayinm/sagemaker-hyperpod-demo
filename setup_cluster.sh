set -eu

# Check if jq is installed.
if ! command -v jq 2>&1 >/dev/null
then
    echo "jq could not be found, please install jq"
    exit 1
fi
APPREMOTEWRITEURL=$(aws ssm get-parameter --name /Terraform/Prometheus/WriteEndpoint --query Parameter.Value)
TERRAFORMVPCSUBNET=$(aws ssm get-parameter --name /Terraform/VPC/PrivateSubnet --query Parameter.Value)
TERRAFORMSECURITYGROUP=$(aws ssm get-parameter --name /Terraform/VPC/SecurityGroup --query Parameter.Value)
TERRAFORMIAMROLE=$(aws ssm get-parameter --name /Terraform/IAM/HyperPodRole --query Parameter.Value)
TERRAFORMS3BUCKET="s3://$(aws ssm get-parameter --name /Terraform/S3/HyperPodBucket | jq -r .Parameter.Value)/lifecycle-config/"
echo "Value for APPREMOTEWRITEURL:  ${APPREMOTEWRITEURL}"
echo "Value for TERRAFORMVPCSUBNET: ${TERRAFORMVPCSUBNET}"
echo "Value for TERRAFORMSECURITYGROUP:  ${TERRAFORMSECURITYGROUP}"
echo "Value for TERRAFORMIAMROLE:  ${TERRAFORMIAMROLE}"
echo "Value for TERRAFORMS3BUCKET:  ${TERRAFORMS3BUCKET}"

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

echo "Uploading LifeCycleConfig to S3:  ${TERRAFORMS3BUCKET}"
aws s3 sync ./LifecycleConfig $TERRAFORMS3BUCKET