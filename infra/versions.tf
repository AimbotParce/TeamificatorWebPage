terraform {
  required_version = ">= 1.5"

  # State is a Secret (+ a Lease for locking) in this app's namespace, written
  # by the runner's ci-deploy ServiceAccount. No cloud backend, no credentials.
  backend "kubernetes" {
    secret_suffix     = "state"
    namespace         = "teamificator-web"
    in_cluster_config = true
  }

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.35"
    }
  }
}

# null kubeconfig_path -> in-cluster config (the runner pod's ci-deploy token).
# Set it only for out-of-cluster (laptop) runs.
provider "kubernetes" {
  config_path = var.kubeconfig_path
}
