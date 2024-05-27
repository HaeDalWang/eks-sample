# 개요
Terraform을 이용한 EKS 구성 예제

## 사용방법
1. 원하는 디텍토리로 이동
2. variables.tf 파일 수정
3. terraform plan
4. terraform apply

## 유의사항
EKS 클러스터 마다 개인 VPC가 존재하도록 구성됩니다
EKS + VPC의 경우 aws module을 이용합니다
링크
- EKS: https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest
- VPC: https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest
기본적인 애드온들은 EKS Blueprint addons를 이용합니다
- addons: https://github.com/aws-ia/terraform-aws-eks-blueprints-addons

## 디렉토리 요약
eks-simple
- EKS + CommonAddones
- addons: ALB 컨트롤러, metrics서버, EBS csi driver, ExternalDNS, ClusterAutoscaler

karpenter-terraform
- EKS + karpenter
- addons: ALB 컨트롤러, metrics 서버, EBS csi driver, ExternalDNS, Karpenter
- 프로비저닝 예제를 위한 nodepool, nodeclass 리소스 파일

