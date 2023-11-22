# How to resolve the external IP of a public-facing NLB/ALB

## Problem statement
Since zCompute is not a public DNS registrar (like AWS Route53, GoDaddy, etc.) public-facing Load Balancers (both NLB & ALB) get an external DNS identifier which can't be resolved, only the external IP is resolvable but the AWS Load Balancer Controller doesn't provide it - so users are required to manually look for it. 

## Alternatives
1. Login into the zCompute web console, find the Load Balancer resource and fetch the external IP
2. Use the Symp CLI tool to programatically fetch the external IP - note that Symp also require zCompute-level authentication
3. Use the AWS CLI tool to programatically fetch the external IP - note you will be required to provide AWS credentials (access & secret keys)
4. SSH into a Kubernetes node (using the predefined key-pair) and use the pre-installed AWS CLI tool to programatically fetch the external IP (no need to authenticate with zCompute as all nodes use an instance profile)
5. Use a [node-shell](https://github.com/kvaps/kubectl-node-shell) utility (built-in with OpenLens but you can also deploy it independently) to do the same as #4
6. Use the AWS CLI docker image (no need for any authentication as it will run on a Kubernetes node which already use an instance profile)

## Example for alternative #6
Assuming we have a running service/ingress named `wordpress-1700633749` on the `wp` namespace, we can describe it in order to get the public DNS of the Load Balancer, or we can use such command (replace `service` with `ingress` if relevant):
```shell
kubectl get service wordpress-1700633749 -n wp -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

Once we have the public DNS of the Load Balancer (either manually or programmatically), which we will use to populate the `PUBLIC_DNS` parameter in the below command before running it:
```shell
kubectl run aws --image amazon/aws-cli --restart=Never --rm -i --env PUBLIC_DNS=elb-ad7071e0-4d9c-4e7d-8478-0dc10241fecd.elb.services.symphony.public \
    --command -- /bin/bash << EOF
        yum install -y -q jq
        aws ec2 describe-network-interfaces \
        --endpoint-url \$(curl -s http://169.254.169.254/openstack/latest/meta_data.json | jq -c -r '.cluster_url')"/api/v2/aws/ec2" \
        --filter Name=addresses.private-ip-address,Values=\$(getent hosts \$(echo "\$PUBLIC_DNS" | cut -d. -f1) | cut -d\  -f1)  \
        --query 'NetworkInterfaces[0].Association.PublicIp' \
        --output text
EOF
```

This command will do the below:
* Start a new AWS CLI pod that will be deleted once the execution finishes
* Install jq in order to parse the internal API endpoint location of the zCompute cluster
* Find out the private IP of the private DNS equivalent of the public DNS
* Invoke the AWS CLI command to find the public IP linked with the private IP

The output should contain the external IP of the Load Balancer, as well as a message about the pod deletion - for example: \
172.16.20.62 \
pod "aws" deleted
