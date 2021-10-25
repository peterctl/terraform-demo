terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">=2.3.0"
    }
  }
}

variable "name" { type = string }
variable "namespace" { type = string }
variable "image" { type = string }
variable "ports" {
  type = list(object({
    name = string
    port = number
  }))
}
variable "replicas" {
  type    = number
  default = null
}
variable "service_type" {
  type    = string
  default = "ClusterIP"
}

resource "kubernetes_deployment" "main" {
  metadata {
    name      = "${var.name}-deployment"
    namespace = var.namespace
    labels = {
      app = var.name
    }
  }
  spec {
    replicas = var.replicas == null ? "" : tostring(var.replicas)
    selector {
      match_labels = {
        app = var.name
      }
    }
    template {
      metadata {
        namespace = var.namespace
        labels = {
          app = var.name
        }
      }
      spec {
        container {
          name  = var.name
          image = var.image
          dynamic "port" {
            for_each = var.ports
            content {
              name           = port.value.name
              container_port = port.value.port
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "main" {
  metadata {
    name      = "${var.name}-svc"
    namespace = var.namespace
    labels = {
      app = var.name
    }
  }
  spec {
    type = var.service_type
    selector = {
      app = var.name
    }
    dynamic "port" {
      for_each = var.ports
      content {
        port        = port.value.port
        name        = port.value.name
        target_port = port.value.port
      }
    }
  }
}

output "deployment" {
  value = kubernetes_deployment.main
}

output "service" {
  value = kubernetes_service.main
}
