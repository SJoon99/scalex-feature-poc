# tests

Feature 구현과 배포 artifact의 품질을 검증한다.

현재 검증 범위:

- ConfigMap-mounted runtime script behavior with a fake local AWS CLI/S3 store.
- Deterministic CSV upload contract.
- Analyzer `result.json` and `index.html` output contract.
- Result sync sidecar polling behavior.
- Helm lint/template render test.
- 기본 values schema, label contract, ClusterIP base Service, non-empty Service annotations, optional namespaced OBC, no Karmada/cluster-specific resources.

실제 placement와 multi-cluster 배포 검증은 `scalex-federation`의 release test에서 수행한다.
