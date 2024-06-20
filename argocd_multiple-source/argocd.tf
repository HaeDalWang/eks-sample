## Argocd 네임스페이스
resource "kubernetes_namespace_v1" "argocd" {
  metadata {
    name = "argocd"
  }
}
# ## Argocd 비밀번호
# resource "htpasswd_password" "argocd" {
#   password = jsondecode(data.aws_secretsmanager_secret_version.ops.secret_string)["argocd"]
# }

# ArgoCD 배포
resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "7.1.3"
  namespace  = kubernetes_namespace_v1.argocd.metadata[0].name
  values = [templatefile("./helm_values/argocd.yaml", {
    argocdpassword = "bsd0705!"
  })]
}

# ArgoCD ecr updater 배포
resource "helm_release" "argocd-ecr-updater" {
  name       = "argocd-ecr-updater"
  repository = "https://karlderkaefer.github.io/argocd-ecr-updater"
  chart      = "argocd-ecr-updater"
  version    = "0.3.22"
  namespace  = kubernetes_namespace_v1.argocd.metadata[0].name
  values     = [templatefile("./helm_values/argocd-ecr-updater.yaml", {})]
}

# ArgoCD ecr updater IRSA 진행
module "argocd-ecr-updater_irsa" {
  source    = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version   = "5.39.0"
  role_name = "argocd-ecr-updater"

  role_policy_arns = {
    policy = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  }

  oidc_providers = {
    main = {
      provider_arn = module.eks.oidc_provider_arn
      namespace_service_accounts = [
        "argocd:argocd-ecr-updater"
      ]
    }
  }

  depends_on = [
    helm_release.argocd-ecr-updater
  ]
}

# ArgoCD ecr updater을 통해 매번 가저올 ArgoCD Repo을 작성
# argocd-ecr-updater: enabled <-- 해당 라벨이 달려있으면 argocd-updater가 알아서 갱신함
# resource "kubernetes_manifest" "helm-ecr-secret" {
#   manifest = yamldecode(<<-EOF
# apiVersion: v1
# kind: Secret
# stringData:
#   enableOCI: "true"
#   name: helm-ecr
#   type: helm
#   url: 863422182520.dkr.ecr.ap-northeast-2.amazonaws.com
#   username: AWS
#   password: ""
# metadata:
#   labels:
#     argocd-ecr-updater: enabled
#     argocd.argoproj.io/secret-type: repository
#   name: helm-ecr
#   namespace: argocd
#   annotations:
#     kubectl.kubernetes.io/last-applied-configuration: ""
# EOF
# )
#   depends_on = [
#     module.argocd-ecr-updater_irsa
#   ]
# }

## ArgoCD Application 추가
resource "kubernetes_manifest" "helm-ecr-secret" {
manifest = yamldecode(<<-EOF
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: nginx-dev
  namespace: argocd
spec:
  project: default
  destination:
    server: https://kubernetes.default.svc
    namespace: default
  sources:
  - repoURL: '863422182520.dkr.ecr.ap-northeast-2.amazonaws.com'
    chart: nginx
    targetRevision: 0.1.0
    helm:
      valueFiles:
      - $values/values-dev.yaml
  - repoURL: https://github.com/HaeDalWang/helm-nginx.git
    targetRevision: 0.1.0
    ref: values
EOF
)
}