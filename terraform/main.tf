provider "kubernetes" {
  config_path           = "~/.kube/config"  # Adjust the path if needed
  config_context_cluster = "minikube"
}

resource "kubernetes_deployment_v1" "nginx" {
  metadata {
    name = "nginx-deployment"
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "nginx"
      }
    }

    template {
      metadata {
        labels = {
          app = "nginx"
        }
      }

      spec {
        container {
          image = "nginx:latest"
          name  = "nginx"
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "nginx" {
  metadata {
    name = "nginx-service"
  }

  spec {
    selector = {
      app = kubernetes_deployment_v1.nginx.spec[0].template[0].metadata[0].labels.app
    }

    port {
      port        = 80
      target_port = 80
    }

    type = "NodePort"
  }
}
