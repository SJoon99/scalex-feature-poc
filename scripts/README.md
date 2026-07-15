# scripts

로컬 개발과 CI에서 공통으로 사용하는 test/build/package 보조 도구를 둔다.

스크립트는 기능 artifact 생성까지만 담당하며, 운영 cluster 또는 Karmada API에 직접 배포하지 않는다.
OBC provisioning과 runtime Secret/ConfigMap 동기화는 Federation repository의
관리-plane script가 담당한다.

| Script | Purpose |
|---|---|
| `test.sh` | Runs runtime script tests and Helm render validation. |
| `validate-chart.sh` | Runs `helm lint`, renders the chart, and verifies external Secret/ConfigMap consumption with no OBC ownership. |
| `package-chart.sh` | Packages `chart/` into `dist/` without deploying. |
