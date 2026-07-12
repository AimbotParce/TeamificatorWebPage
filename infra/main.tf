###############################################################################
# teamificator.parcerisa.dev -- Teamificator web app
#
# Stateless Next.js app (listens on :3000). No PVC: nothing to persist. Served
# publicly through HomeInfra's Traefik "public" ingress, which terminates TLS
# with a Let's Encrypt certificate for each host in var.public_hosts.
#
# The namespace, GHCR pull secret (on the default ServiceAccount) and the
# ci-deploy RBAC used to apply this are provisioned by HomeInfra.
###############################################################################

locals {
  image  = yamldecode(file("${path.module}/${var.image_versions_file}")).image
  labels = { "app.kubernetes.io/name" = "teamificator-web" }
}

resource "kubernetes_deployment_v1" "web" {
  metadata {
    name      = "teamificator-web"
    namespace = var.namespace
    labels    = local.labels
  }

  spec {
    replicas = var.replicas

    selector {
      match_labels = local.labels
    }

    template {
      metadata {
        labels = local.labels
      }

      spec {
        container {
          name  = "web"
          image = local.image
          # :latest is mutable, so always re-pull on (re)start. Pin a digest or
          # version tag in image-versions.yaml for reproducible rollouts.
          image_pull_policy = "Always"

          port {
            name           = "http"
            container_port = 3000
          }

          env {
            name  = "NODE_ENV"
            value = "production"
          }

          readiness_probe {
            http_get {
              path = "/"
              port = 3000
            }
            initial_delay_seconds = 5
            period_seconds        = 10
          }

          liveness_probe {
            http_get {
              path = "/"
              port = 3000
            }
            initial_delay_seconds = 15
            period_seconds        = 20
          }

          resources {
            requests = {
              cpu    = "50m"
              memory = "128Mi"
            }
            limits = {
              memory = "512Mi"
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "web" {
  metadata {
    name      = "teamificator-web"
    namespace = var.namespace
    labels    = local.labels
  }

  spec {
    selector = local.labels

    port {
      name        = "http"
      port        = 80
      target_port = 3000
      protocol    = "TCP"
    }
  }
}

resource "kubernetes_ingress_v1" "web" {
  metadata {
    name      = "teamificator-web"
    namespace = var.namespace
  }

  spec {
    ingress_class_name = "public"

    dynamic "rule" {
      for_each = toset(var.public_hosts)

      content {
        host = rule.value

        http {
          path {
            path      = "/"
            path_type = "Prefix"

            backend {
              service {
                name = kubernetes_service_v1.web.metadata[0].name
                port {
                  number = 80
                }
              }
            }
          }
        }
      }
    }

    # Names the hosts for TLS so the websecure entrypoint's Let's Encrypt
    # resolver issues certificates. No secret_name: the certs are managed by
    # Traefik's ACME resolver.
    tls {
      hosts = var.public_hosts
    }
  }
}
