variable "kubeconfig_path" {
  description = "Path to a kubeconfig for out-of-cluster runs. Leave null in CI to use the runner pod's in-cluster config."
  type        = string
  default     = null
  sensitive   = true
}

variable "namespace" {
  description = "Namespace provisioned for this app by HomeInfra (apps.tf key)."
  type        = string
  default     = "teamificator-web"
}

variable "image_versions_file" {
  description = "YAML file pinning the container image to deploy."
  type        = string
  default     = "image-versions.yaml"
}

variable "public_hosts" {
  description = "Public hostnames Traefik should route to this app (TLS via Let's Encrypt)."
  type        = list(string)
  default = [
    "teamificator.parcerisa.dev",
  ]
}

variable "replicas" {
  description = "Number of app replicas."
  type        = number
  default     = 1
}
