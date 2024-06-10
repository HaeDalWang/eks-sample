# EKS 클러스터
기존 CLusterAutoScaller를 삭제후 Karpenter를 사용하는 예제
비용 최적화를 위해 On-demend와 Spot을 둘다 프로비저닝의 사용하고 우선순서 및 비율을 상세히 조정한다

## variables.tf

## 눈여겨볼 작업 사항
1. eks.tf의 vpc모듈
프라이빗 서브넷 별도의 태그
- karpenter가 프로비저닝시 해당 태그로 구분하여 프로비저닝

2. eks.tf eks모듈
tag 항목의 merge
- karpenter가 클러스터를 특정하기 위해 태그 추가
노드그룹의 보안그룹에 태그 추가
- karpenter가 프로비저닝시 사용할 보안그룹을 태그로 구분

3. main.tf
aws_ecrpublic_authorization_token 리소스의 경우
- karpenter의 컨테이너 이미지가 ECR 퍼블릭에 존재하기 떄문에 ECR 로그인 후 다운받아야하기에 필요
- 리전이 서울이 아닌이유는 ECR 퍼블릭에 경우 us 리전에만 존재
    + https://docs.aws.amazon.com/ko_kr/general/latest/gr/ecr-public.html

4.