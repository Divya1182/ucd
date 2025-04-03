# aws-terraform-hs-upsilon-eks-services
Repository to create resources in Product AWS Account which are used by BEF API deployed in Shared EKS cluster

## Service Account Module
This module will create Service Accounts and corresponding role providing EKS App access to AWS Product Account resource.<br>
It's entirely declaration based and SA's can be defined in tfvar file to auto create the roles and service accounts and registering the OpenID Connect Provider of corresponding EKS Clusters

### Defining the resources
Define the cluster_to_application_map variable in `env`.tfvar file to create corresponding role and SAs. <br>
Service Accounts are specific to each POD and are mapped to a specific role in Product AWS Account. <br>
Based on the below declaration below resrouces will be created in Product AWS Account - 

- OpenID Provider Client for EKS Cluster
- Create a Service Account which can be registered with the Application deployed in EKS cluster
- Create Role in Product AWS Account which the Service Account can assume to perform operation in Product AWS Account
  - The Role will be attached to the Policies defined in `policy_name` attribute
- `eks_namespace` is the EKS Hermes namespace assigned to the Product Team
- `application_name` is the EKS Application name deployed in EKS POD under Product namespace and cluster

### Example definition
Sample definition of Cluster-wise application workload in `env`.tfvar file

```tfvar
cluster_to_application_map = {
  hs-eks-1-dev = [{
                    application_name = "test-eks"
                    eks_namespace = "bef-event-flow-eks-dev"
                    policy_name = ["Enterprise/BefEKSTestEKSPolicies", "Enterprise/BefLambdaEC2NetworkAccess"]
                  },
                  {
                    application_name = "bef-eks"
                    eks_namespace = "bef-event-flow-eks-dev"
                    policy_name = ["Enterprise/BefEKSTestEKSPolicies", "Enterprise/BefLambdaEC2NetworkAccess"]
                  }
                ]
  hs-eks-2-dev = [
                  {
                    application_name = "bef-eventflow-intake"
                    eks_namespace = "bef-event-flow-eks-dev"
                    policy_name = ["Enterprise/BefEKSTestEKSPolicies"]
                  }
                ]
}
```

### Resource name format
Format of Role name and Service Account name generated are as below -
- Role Name - `cluster_name`-`application_name`-irsa-role
- SA Name   - `application_name`-service-account

Example - 
- Role Name - hs-eks-2-dev-test-eks-irsa-role
- SA Name   - test-eks-service-account

### Registering SA with POD
To register the Service Account with the EKS Application POD, below declaration is needed in Deployment YAML in application repo -
```yaml
# configure ServiceAccount for your eks workload
configureServiceAccount: true
serviceAccountName: "test-eks-service-account"
serviceAccountARN: "arn:aws:iam::364685145795:role/hs-eks-1-dev-test-eks-irsa-role" # Role ARN from Product AWS Account
```

> [!NOTE]
> Sample EKS Application can be found [here](https://git.express-scripts.com/ExpressScripts/test-eks)

