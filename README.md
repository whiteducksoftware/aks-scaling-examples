# AKS scaling examples

## Create AKS cluster

```bash
# Create 1 AKS clusters with VPA, KEDA and cluster-autoscaler enabled
cd ./src

# Login to Azure
az login
az account set --subscription <SUBSCRIPTION_ID>

# Execute Terraform
terraform init
terraform apply -auto-approve
```

### Enable VPA

```terraform
resource "azurerm_kubernetes_cluster" "aks" {
  workload_autoscaler_profile {
    vertical_pod_autoscaler_enabled = true
  }
}
```

### Enable KEDA

```terraform
resource "azurerm_kubernetes_cluster" "aks" {
  workload_autoscaler_profile {
    keda_enabled                    = true
  }
}
```

## Enable cluster-autoscaler

```terraform
# Set the global auto-scaler config
resource "azurerm_kubernetes_cluster" "aks" {

  auto_scaler_profile {
  }
}

# Enable auto-scaler per node pool
resource "azurerm_kubernetes_cluster_node_pool" "scale" {
  enable_auto_scaling   = true
}
```

## Horizontal Pod Autoscaler

This demo uses the VPA (needs to be activated on AKS) and metrics-server shipped with AKS

```bash
kubectl create ns hpa

# Create HPA and deployment resources vor v1 API
kubectl -n hpa apply -f ./k8s/hpav1.yaml
kubectl -n hpa get hpa hpa-demo-deployment-v1
kubectl -n hpa events
kubectl -n hpa get rs,pod
kubectl -n hpa get hpa hpa-demo-deployment-v1
kubectl -n hpa describe hpa hpa-demo-deployment-v1

# Create some load
watch -n 1 kubectl -n hpa get hpa,rs,pod
kubectl -n hpa run -i --tty load-generator-v1 --rm --image=busybox --restart=Never \
  -- /bin/sh -c "while sleep 0.01; do wget -q -O- http://hpa-demo-deployment-v1; done"
kubectl -n hpa describe hpa hpa-demo-deployment-v1

# Create HPA and deployment resources vor v2 API
kubectl -n hpa apply -f ./k8s/hpav2.yaml
kubectl -n hpa get hpa hpa-demo-deployment-v2
kubectl -n hpa events
kubectl -n hpa get rs,pod
kubectl -n hpa get hpa hpa-demo-deployment-v2
kubectl -n hpa describe hpa hpa-demo-deployment-v2
kubectl -n hpa get rs,pod

# Create some load
watch -n 1 kubectl -n hpa get hpa,rs,pod
kubectl -n hpa run -i --tty load-generator-v2 --rm --image=busybox --restart=Never \
  -- /bin/sh -c "while sleep 0.01; do wget -q -O- http://hpa-demo-deployment-v2; done"
kubectl -n hpa describe hpa hpa-demo-deployment-v2
```

## Vertical Pod Autoscaler

This demo uses the VPA (needs to be activated on AKS)

```bash
kubectl create ns vpa

# Create VPA and deployment resources with too low resources
kubectl -n vpa apply -f ./k8s/vpa-low.yaml
kubectl -n vpa describe pod hamster-low-
kubectl describe vpa/hamster-vpa-low
kubectl -n vpa events

# Create VPA and deployment resources with too high resources
kubectl -n vpa apply -f ./k8s/vpa-high.yaml
kubectl get pods -w 
kubectl -n vpa describe pod hamster-high-
kubectl describe vpa/hamster-vpa-high
kubectl -n vpa events 
```

## KEDA

This demo uses the KEDA (needs to be activated on AKS). Keda leverages Worload Identity to check if messages Azure Service Bus queue.

```bash
kubectl create ns keda

# Set the base64 encrypted "servicebus-connectionstring" for the ServiceBus in the file ./k8s/keda.yaml
kubectl -n keda apply -f ./k8s/keda.yaml
kubectl -n keda get triggerauthentications.keda.sh trigger-auth-service-bus-orders
kubectl -n keda get pods
kubectl -n keda describe scaledobjects.keda.sh order-processor-scaler

# Set the "ConnectionString" for the ServiceBus in the file ./orders/Keda.Samples.Dotnet.OrderGenerator/Program.cs
watch -n 1 kubectl -n keda get rs,pod
watch -n 1 az servicebus queue list -g <rg-name> --namespace-name <sb-name> -otsv --query "[].messageCount"

dotnet run --project ./orders/Keda.Samples.Dotnet.OrderGenerator/Keda.Samples.Dotnet.OrderGenerator.csproj
kubectl -n keda events
```

## cluster-autoscaler

This demo uses the cluster-autoscaler (needs to be activated on AKS)

```bash
kubectl create ns cluster
kubectl -n cluster run nginx --image nginx --replicas 500
kubectl -n cluster events
kubectl -n cluster get nodes -w
```
