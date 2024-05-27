#---------------------------------------------------------------
# AWS auth configmap 수정 부분
# 주의사항: 테라폼으로 해당 configmap 수정시 테라폼으로 계속 관리하는것을 추천한다
#---------------------------------------------------------------

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