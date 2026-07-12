# tests

Feature 구현과 배포 artifact의 품질을 검증한다.

향후 검증 범위:

- Unit test
- Component integration test
- Container build test
- Helm lint/template test
- 기본 values schema와 label contract

실제 placement와 multi-cluster 배포 검증은 `scalex-federation`의 release test에서 수행한다.
