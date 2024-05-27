# EKS 클러스터
기존 CLusterAutoScaller를 삭제후 Karpenter를 사용하는 예제
비용 최적화를 위해 On-demend와 Spot을 둘다 프로비저닝의 사용하고 우선순서 및 비율을 상세히 조정한다

## 구성환경
- 예시 클러스터 1개
- helm Chart
    + ExternalDNS
- 예시 VPC 및 3개의 서브넷(3 az)
    + karpenter 프로비저너 설정 구성시 배포되는 az의 범위 또한 3개

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

4. security.tf
aws authconfigmap 수정
- karpenter가 노드 join을 위해 mapRole을 추가하여야한다
**karpenter를 제외 추가적인 권한이 필요시 variables.tf에서 추가**

5. kube-rsc.tf
프로비저닝 리소스
- 프로비저닝의 대한 룰를 명세 한다 (복수 개 가능)
- on-demend,spot 비율 5:5
- 우선순서: spot -> on-demend
노드 템플릿 리소스
- 배포 되는 인스턴스의 정보를 담는다
- 사용할 aws EC2 스펙를 명시하는 리소스
예시용 Deployment 리소스
- Pod 배포시 옵션을 통해 특정 인스턴스(spot,on-demend) 선택
- Replicas: 10 -> 

## 생성/삭제 순서
모듈 생성 순서 (삭제는 반대)
- vpc -> eks -> Addons -> kube-resources
삭제시 고려 사항: ingress 로드밸런서, pvc EBS볼륨, CRD 리소스