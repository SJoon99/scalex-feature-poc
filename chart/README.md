# chart

Feature workload를 Kubernetes resource로 렌더링하는 재사용 가능한 Helm chart를 둔다.

Chart가 담당하는 것:

- Deployment, StatefulSet, Job 등 workload resource
- Service, ConfigMap, ServiceAccount 등 workload dependency
- Federation policy가 선택할 수 있는 공통 label
- Image repository/tag/digest와 runtime setting의 values contract

Chart는 특정 member cluster 이름이나 Karmada placement policy를 포함하지 않는다.
