# #---------------------------------------------------------------
# # kubernetes 리소스
# # https://github.com/aws-ia/terraform-aws-eks-blueprints/blob/main/patterns/karpenter/main.tf#L180
# #---------------------------------------------------------------

# # 리소스 작성의 경우 Karpenter 공식문서 참조
# # https://karpenter.sh/preview/concepts/provisioners/

# # 1. 스토리
# # 온디맨드, 스핏 5:5 비율 생성
# # 온디맨드는 t3.medium만 생성
# # 스팟의 경우 t,m 시리즈 중 CPU가 1,2,4, Core 인스턴스만 생성
# # 우선적으로 Spot먼저 프로비저닝

# # 2. 리소스 매니페스트

# # 프로비저닝 조건 리소스 [온디맨드]
# resource "kubectl_manifest" "karpenter_provisioner_ondemand" {
#   yaml_body = <<YAML
# apiVersion: karpenter.sh/v1beta1
# kind: NodePool
# metadata:
#   name: ondemand
# spec:
#   template:
#     spec:
#       requirements:
#       - key: kubernetes.io/arch
#         operator: In
#         values: ["amd64"]
#       - key: node.kubernetes.io/instance-type
#         operator: In
#         values: ["t3.medium"]
#       - key: karpenter.sh/capacity-type
#         operator: In
#         values: ["on-demand"]
#       - key: karpenter.k8s.aws/instance-generation
#         operator: Gt
#         values: ["2"]
#       nodeClassRef:
#         apiVersion: karpenter.k8s.aws/v1beta1
#         kind: EC2NodeClass
#         name: default
#   limits:
#     cpu: "10"
#     memory: 10Gi
#   weight: 1 
#   disruption:
#     consolidationPolicy: WhenUnderutilized
#     expireAfter: 720h # 30 * 24h = 720h
# YAML
#   depends_on = [
#     module.eks_blueprints_addons
#   ]
# }


# # 프로비저닝 조건 리소스 [스팟]
# resource "kubectl_manifest" "karpenter_provisioner_spot" {
#   yaml_body = <<YAML
# apiVersion: karpenter.sh/v1beta1
# kind: NodePool
# metadata:
#   name: spot
# spec:
#   template:
#     spec:
#       requirements:
#       - key: kubernetes.io/arch
#         operator: In
#         values: ["amd64"]
#       - key: karpenter.k8s.aws/instance-category
#         operator: In
#         values: ["t", "m"]
#       - key: karpenter.sh/capacity-type
#         operator: In
#         values: ["spot"]
#       - key: karpenter.k8s.aws/instance-generation
#         operator: Gt
#         values: ["2"]
#       nodeClassRef:
#         apiVersion: karpenter.k8s.aws/v1beta1
#         kind: EC2NodeClass
#         name: default
#   limits:
#     cpu: "10"
#     memory: 10Gi
#   weight: 1 
#   disruption:
#     consolidationPolicy: WhenUnderutilized
#     expireAfter: 720h # 30 * 24h = 720h  
# YAML
#   depends_on = [
#     module.eks_blueprints_addons
#   ]
# }

# # AWS 인스턴스 Spec 템플릿
# # 서브넷, 보안그룹, 인스턴스프로필, 태그 지정
# # 참조: https://karpenter.sh/preview/concepts/node-templates/
# resource "kubectl_manifest" "karpenter_node_template" {
#   yaml_body = <<YAML
# apiVersion: karpenter.k8s.aws/v1beta1
# kind: EC2NodeClass
# metadata:
#   name: default
# spec:
#   amiFamily: AL2 # Amazon Linux 2
#   role: "KarpenterNodeRole-${module.eks.cluster_name}" # replace with your cluster name
#   subnetSelectorTerms:
#     - tags:
#         karpenter.sh/discovery: "${module.eks.cluster_name}"
#   securityGroupSelectorTerms:
#     - tags:
#         karpenter.sh/discovery: "${module.eks.cluster_name}"
# YAML
# }

# # 예시용 Deployment 
# # 'topologySpreadConstraints' 옵션을 사용하여 karpenter 의 설정 중 key:'capacity-spread' 값을 이용하여 배포
# ## 배포 완료 후 'kubectl scale deploy/inflate --replicas 10' 레플리카의 숫자를 늘리며 Pod 배포 확인
# ## 10개 기준 스팟,온디맨드 인스턴스 각각 2개씩 생성 된다 확인해보자

# resource "kubectl_manifest" "karpenter_example_deployment" {
#   yaml_body = <<-YAML
# apiVersion: apps/v1
# kind: Deployment
# metadata:
#   name: inflate
# spec:
#   replicas: 0
#   selector:
#     matchLabels:
#       app: inflate
#   template:
#     metadata:
#       labels:
#         app: inflate
#     spec:
#       terminationGracePeriodSeconds: 0
#       containers:
#         - name: inflate
#           image: public.ecr.aws/eks-distro/kubernetes/pause:3.7
#           resources:
#             requests:
#               cpu: 1
#               memory: 1.5Gi
#   YAML

#   depends_on = [
#     kubectl_manifest.karpenter_node_template
#   ]
# }