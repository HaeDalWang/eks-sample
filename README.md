# eks-sample
Terraform으로 EKS만 간단히 만들기

## 사용한 모듈

aws 공식 EKS 모듈 사용
- https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest

aws 공식 vpc 모듈 사용
- https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest


## 구성된 사항

새로운 S3 버킷 & DynamoDB 테이블 (백엔드 & Lock파일)
- S3 버전관리 활성화 
- S3 서버 사이드 암호화 활성화
- S3 퍼블릭 접근 제한

새로운 VPC 
- 하나의 NatGateway
- 3개의 서브넷
- 도메인 호스트네임 활성화

새로운 EKS 클러스터
- 1.27 버전
- endpoint public/private 둘다 사용
- Private 서브넷의 배포된 노드그룹
  + 노드 그룹
    - t3.large 타입
    - 초기 2개의 노드 

### Output
- 완성된 kubeconfig 업데이트 awscli 명령어 

