export EMRCLUSTER_NAME=emr-eks-celeborn-emr-data-team-a
export AWS_REGION=us-west-2
export ACCOUNTID=$(aws sts get-caller-identity --query Account --output text)
export VIRTUAL_CLUSTER_ID=$(aws emr-containers list-virtual-clusters --query "virtualClusters[?name == '$EMRCLUSTER_NAME' && state == 'RUNNING'].id" --output text)
export EMR_ROLE_ARN=arn:aws:iam::$ACCOUNTID:role/emr-eks-celeborn-emr-data-team-a
export S3BUCKET=emr-eks-celeborn-emr-20250524113100067400000006
export ECR_URL="$ACCOUNTID.dkr.ecr.$AWS_REGION.amazonaws.com"
export JOB_TEMPLATE_ID=$(aws emr-containers list-job-templates --query "templates[?name == 'celeborn_dra_template'].id" --output text)

#aws emr-containers create-job-template --cli-input-json file://./celeborn_dra_template.json


aws emr-containers start-job-run \
--virtual-cluster-id $VIRTUAL_CLUSTER_ID \
--name emr610-clb-8 \
--job-template-id $JOB_TEMPLATE_ID \
--job-template-parameters '{
    "EmrRoleARN": "'$EMR_ROLE_ARN'",
    "CustomImageURI": "724853865853.dkr.ecr.us-west-2.amazonaws.com/eks-celeborn:emr-6.10.0",
    "DataLocation": "s3://'$S3BUCKET'/TPCDS-TEST-3T\",\"s3://'$S3BUCKET'/TPCDS-TEST-3T-RESULT",
    
    "QueryList": "q24a-v2.4,q25-v2.4,q26-v2.4,q27-v2.4,q30-v2.4q31-v2.4,q32-v2.4,q33-v2.4,q34-v2.4,q36-v2.4,q37-v2.4,q39a-v2.4,q39b-v2.4,q41-v2.4,q42-v2.4,q43-v2.4,q52-v2.4,q53-v2.4,q55-v2.4,q56-v2.4,q60-v2.4,q61-v2.4,q63-v2.4,q67-v2.4,q73-v2.4,q77-v2.4,q83-v2.4,q86-v2.4,q98-v2.4",
    "DRA_enabled": "true",
    "DRA_executorIdleTimeout": "5s",

    "DRA_shuffleTracking": "true",
    "DRA_trackingTimeout": "5s",
    "AQE_localShuffleReader": "false",
    "RSS_server": "celeborn-master-0.celeborn-master-svc.celeborn:9097,celeborn-master-1.celeborn-master-svc.celeborn:9097,celeborn-master-2.celeborn-master-svc.celeborn:9097",

    "PodNamePrefix": "clb-dra-track",
    "EKSNodegroup": "spark-app",
    "LoggerLevel": "WARN",
    "LogS3BucketUri": "s3://'$S3BUCKET'/elasticmapreduce/emr-containers"
  }'