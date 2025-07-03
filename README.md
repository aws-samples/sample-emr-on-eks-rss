# emr-on-eks-rss

Remote Shuffle Service (RSS) provides the capability for Apache Spark applications to store shuffle data on a cluster of remote servers. See more details on Spark community document: [SPARK-25299][DISCUSSION] Improving Spark Shuffle Reliability.

The termination of Spot would lead to re-calculate, that would have cost and sometimes failed the LoB SLA. By using RSS, it significantly improve the resilience of Spark with Spot.

In this repo, we select Aapche Celeborn as the remote shuffle service for EMR on EKS powered by [Data on EKS](https://awslabs.github.io/data-on-eks/).


## Getting started

### Clone the repo

```shell
git clone
```

### Configure Karpenter for Celeborn

Karpenter automatically launches just the right compute resources to handle your cluster's applications. It is designed to let you take full advantage of the cloud with fast and simple compute provisioning for Kubernetes clusters. We will use Karpenter to host the celeborn pod.

```shell
cd emr-on-eks-rss
kubectl apply -f karpenter/
```

Check the nodepool and ec2nodeclass status

```shell
kubectl get nodepool
kubectl get ec2nodeclass
```

### Build docker images

Build the celeborn server with EMR on EKS

```shell
docker build -t celeborn-server:v1.0 -f docker/celeborn-server/Dockerfile
```

Build the celeborn worker with EMR on EKS
```shell
docker build -t celeborn-server:v1.0 -f docker/celeborn-client/Dockerfile
```

### Deploy the Celeborn Service by helm charts

We have provided the celeborn helm charts, please modify

```shell
helm install celeborn charts/celeborn -n kube-system
```




