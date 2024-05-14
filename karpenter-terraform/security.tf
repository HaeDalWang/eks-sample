#---------------------------------------------------------------
# AWS auth configmap 수정 부분
# 주의사항: 테라폼으로 해당 configmap 수정시 테라폼으로 계속 관리하여야한다
# - 아래 씌여진 mapRole을 삭제할 경우 karpenter 및 EKS 마스터 권한이 사라짐으로 유의해야한다
#---------------------------------------------------------------

# Karpenter 변수로 생겨났습니다 굳이 아래 안써도됨

# resource "kubernetes_config_map_v1_data" "aws_auth" {
#   metadata {
#     name      = "aws-auth"
#     namespace = "kube-system"
#   }

#   data  = {
#     mapRoles    = yamlencode(concat(var.aws_auth_mapRoles, 
#     [{
#       rolearn  = module.eks_blueprints_addons.karpenter.node_iam_role_arn
#       username = "system:node:{{EC2PrivateDNSName}}"
#       groups = [
#         "system:bootstrappers",
#         "system:nodes",
#       ]
#     },
#     {
#       # sandbox는 노드그룹의 이름과 동일하게
#       rolearn  = module.eks.eks_managed_node_groups["sandbox"].iam_role_arn
#       username = "system:node:{{EC2PrivateDNSName}}"
#       groups = [
#         "system:bootstrappers",
#         "system:nodes",
#       ]
#     }
#     ]))
#     mapUsers    = yamlencode(var.aws_auth_mapUsers)
#     mapAccounts = yamlencode(var.aws_auth_mapAccounts)
#   }
#   force = true

#   depends_on = [
#     module.eks
#   ]
# }