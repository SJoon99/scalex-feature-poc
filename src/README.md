# src

Feature를 구성하는 application/component source code를 둔다.

Component가 여러 개라면 역할별 하위 디렉터리로 분리한다. Cluster 이름,
Karmada policy, OBC provisioning, 운영 credential은 source code에 포함하지 않는다.

Object storage를 사용하는 코드는 endpoint, bucket과 credential을 환경변수 또는
파일 계약으로만 받으며 특정 Rook/Ceph 리소스 이름에 의존하지 않는다.
