# emr-on-eks-rss

Remote Shuffle Service (RSS) provides the capability for Apache Spark applications to store shuffle data on a cluster of remote servers. See more details on Spark community document: [SPARK-25299][DISCUSSION] Improving Spark Shuffle Reliability.

The termination of Spot would lead to re-calculate, that would have cost and sometimes failed the LoB SLA. By using RSS, it significantly improve the resilience of Spark with Spot.

In this repo, we select Aapche Celeborn as the remote shuffle service for EMR on EKS powered by [Data on EKS](https://awslabs.github.io/data-on-eks/).


## Getting started

### Clone the repo

```shell
git clone https://github.com/aws-samples/sample-emr-on-eks-rss
```

### Configure Karpenter for Celeborn


#### Build Docker images

For the best practice in security, it's recommended to build your own images and publish them to your own Amazon ECR repository. Or you can use the published container images.


##### Login into Amazon ECR and create private Amazon ECR registry

```shell
export AWS_REGION=us-west-2
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text --region $AWS_REGION)
ECR_URL=$ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_URL

aws ecr create-repository --repository-name celeborn-server \
  --image-scanning-configuration scanOnPush=true
  
aws ecr create-repository --repository-name celeborn-client \
  --image-scanning-configuration scanOnPush=true
```

##### Build the Celeborn Server

```shell
export JDK_VERSION=8 
export SPARK_VERSION=3.3
docker build -t $ECR_URL/celeborn-server:spark${SPARK_VERSION}_jdk${JDK_VERSION} \
  --build-arg SPARK_VERSION=${SPARK_VERSION} \
  --build-arg JDK_VERSION=${JDK_VERSION} \
  --build-arg java_image_tag=${JDK_VERSION}-jdk-focal \
  -f docker/celeborn-server/Dockerfile .
```

##### Build the Celeborn Worker

```shell
export JDK_VERSION=8
export SPARK_VERSION=3.3
export EMR_VERSION=emr-6.10.0
aws ecr-public get-login-password --region us-east-1 | docker login --username AWS --password-stdin public.ecr.aws

docker build -t $ECR_URL/celeborn-client:${EMR_VERSION} \
  --build-arg SPARK_VERSION=${SPARK_VERSION} \
  --build-arg JDK_VERSION=${JDK_VERSION} \
  --build-arg SPARK_BASE_IMAGE=public.ecr.aws/emr-on-eks/spark/${EMR_VERSION}:latest \
  --build-arg java_image_tag=${JDK_VERSION}-jdk-focal \
  -f docker/celeborn-client/Dockerfile .
```

##### Modify the role in the ec2nodeclass in the Karpenter folder then apply the yamls.

```shell
kubectl apply -f karpenter/
```

In this examples, we choose i3en  instance type and Bottlerocket to host the Celeborn service. Bottlerocket is a free and open-source Linux-based operating system meant for hosting containers which is more suitable for hosting data workloads on Amazon EKS. Celeborn requires higher network and I/O performance, so you should choose the right EC2 instance types based on your shuffle size.
 
Modify the chart values for images if needed(optional)

##### config celeborn server and replace docker images if needed
```shell
vi charts/celeborn-shuffle-service/values.yaml
```

##### Deploy the chart

```shell
helm install celeborn charts/celeborn  -n celeborn \
--set image.tag=0.5 --create-namespace 
```

Check the Celeborn pods and verify the Celeborn service is up, by default Celeborn has 3(masters)+5(worker).

```shell
kubectl get pods -n celeborn
```

Output:
```shell
NAME                READY   STATUS    RESTARTS   AGE
celeborn-master-0   1/1     Running   0          16m
celeborn-master-1   1/1     Running   0          14m
celeborn-master-2   1/1     Running   0          13m
celeborn-worker-0   1/1     Running   0          16m
celeborn-worker-1   1/1     Running   0          12m
celeborn-worker-2   1/1     Running   0          11m
celeborn-worker-3   1/1     Running   0          9m57s
celeborn-worker-4   1/1     Running   0          8m22s
```

### Run tpcds benchmark with Apache Celeborn and Karpenter 

#### Generating tpcds data

In order to generate the dataset for TPCDS benchmark tests, you will need to replace <REPLACE-WITH-YOUR-S3BUCKET-NAME> with your bucket name in the data generation manifest, located in examples/benchmark/tpcds-benchmark-data-generation-1t.yaml then apply the yaml file.

```shell
kubectl apply -f tests/benchmark/tpcds-benchmark-data-generation-1t.yaml
```
Once you apply the tpcds-benchmark-data-generation-1t.yaml manifest, you should see the the driver and executor Pods coming up. It takes about an hour to finish the execution of the test data generation script. Once the execution is completed, you can see go into the Amazon S3 console and validate the bucket size.

#### Run the Benchmark

We have provided an example of benchmark using spark-operator, You will need to replace the <S3_BUCKET> and <SERVICE_ACCOUNT> placeholders in the benchmark file.
```shell
kubectl apply -f tests/benchmark/celeborn-benchmark.yml
```
