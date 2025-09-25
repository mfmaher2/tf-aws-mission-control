provider "helm" {
  kubernetes = {
    #config_path = "~/.kube/config"
    #config_path = local.kubeconfig
    host                   = module.eks_al2023.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks_al2023.cluster_certificate_authority_data)

    # Configure authentication using AWS CLI for EKS cluster
    exec = {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", "${var.cluster_name}-al2023"]
      command     = "aws"
    }
  }

  # Registry credentials are configured at the resource level, not provider level
}


resource "helm_release" "cert_manager" {
  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = "v1.16.2"
  create_namespace = true
  namespace = "cert-manager"
  force_update = true

  set = [{
    name  = "installCRDs"
    value = "true"
  }]
}


resource "helm_release" "mission_control_datastax" {
  name        = "mission-control"
  namespace   = "mission-control"
  repository  = "oci://registry.replicated.com/mission-control"
  version    = "1.14.1"
  chart       = "mission-control"
  create_namespace = true
  repository_username = var.user_email
  repository_password = var.license_id
  #repository = "./mc-mimir-updated"
  values = [file(var.helm_override_file)]

  depends_on = [helm_release.cert_manager]

}

resource "kubernetes_namespace" "kubernetes_dashboard" {
  metadata {
    name = "kubernetes-dashboard"
  }
}


###
# Install the Metrics Server using the Helm provider
###
resource "helm_release" "metrics_server" {
  name       = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  namespace  = kubernetes_namespace.kubernetes_dashboard.metadata[0].name
  # Recent updates to the Metrics Server do not work with self-signed certificates by default.
  # Since Docker For Desktop uses such certificates, you’ll need to allow insecure TLS
  set = [{
    name  = "args"
    value = "{--kubelet-insecure-tls=true}"
  }]
  wait = true
}

# Output metadata of the Metrics Server release
output "metrics_server_service_metadata" {
  value = helm_release.metrics_server.metadata
}

