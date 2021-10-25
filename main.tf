terraform {
  backend "kubernetes" {
    secret_suffix = "tfstate"
  }
}

provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "k3d-tfdemo"
}

resource "kubernetes_namespace" "nginx" {
  metadata {
    name = "nginx"
  }
}

module "nginx_svc" {
  source = "./modules/svc_deployment"

  name      = "nginx"
  namespace = kubernetes_namespace.nginx.id
  image     = "nginx"
  ports = [
    { name = "http", port = 80 },
    { name = "https", port = 443 },
  ]
  replicas = 3
}

resource "kubernetes_ingress" "nginx" {
  metadata {
    name      = "nginx-ingress"
    namespace = kubernetes_namespace.nginx.id
  }
  spec {
    backend {
      service_name = module.nginx_svc.service.metadata[0].name
      service_port = 80
    }
  }
}
