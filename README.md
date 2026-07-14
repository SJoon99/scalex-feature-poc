# scalex-feature-poc

ScaleX User/Dev Layer에서 사용할 feature를 개발하고 배포 artifact로 패키징하는 repository다.

이 repository는 feature의 source code, Helm chart와 테스트를 소유한다. 실제 배포 대상 cluster와 Karmada placement는 `scalex-federation`이 소유한다.

## 현재 POC: `rgw-analysis-web`

`chart/`는 하나의 cluster-neutral Helm release `rgw-analysis-web`을 제공한다.

구성 요소:

1. `dataset-seeder` Kubernetes Job — deterministic CSV를 S3/RGW에 업로드한다.
2. `analyzer` Kubernetes Job — input object를 기다린 뒤 row count/sum/average를 계산하고 `result.json`, `index.html`을 업로드한다.
3. `result-web` Deployment — AWS CLI sync sidecar가 result prefix를 nginx html dir로 polling sync하고 nginx가 정적 결과를 제공한다.
4. `result-web` Service — base type은 `ClusterIP`; Federation override가 필요한 cluster에서만 LoadBalancer로 바꾼다.
5. Optional `ObjectBucketClaim` — 기능 namespace에서 전용 bucket과 runtime credential을 요청한다.

공식 public runtime image만 사용한다.

- `public.ecr.aws/aws-cli/aws-cli:<pinned>`
- `nginx:<pinned>-alpine`

Script는 ConfigMap으로 mount되므로 첫 POC에서 image publish가 필요 없다.
S3 endpoint/bucket/region도 runtime ConfigMap을 통해 주입되어 Karmada가
member cluster별 endpoint를 안전하게 override할 수 있다.

## 책임

- Feature source code 개발
- 재사용 가능한 Helm chart 제공
- Unit/integration/render test
- Versioned chart artifact 생성
- Federation으로 승격할 immutable revision 제공

## 책임지지 않는 것

- 실제 member cluster 이름과 topology
- Karmada propagation/override policy
- Tower Argo bootstrap
- Cluster Infra 구성
- 운영 credential 보관

## Object storage contract

Feature Helm은 선택적으로 namespaced `ObjectBucketClaim`을 선언하고, workload가
사용할 Secret 이름을 참조한다. 실제 `CephObjectStore`, bucket `StorageClass`,
RGW endpoint는 각 `*-k8s` Infra가 제공하며, OBC placement는 Federation이
Karmada policy로 결정한다.

Rook이 생성하는 access/secret key 값은 chart나 Git에 저장하지 않는다. 같은
클러스터의 workload는 OBC Secret을 직접 사용할 수 있고, 다른 클러스터가 같은
bucket을 사용해야 할 때는 Tower credential bridge 또는 중앙 Secret Store가
해당 값을 전달한다.

## 기본 흐름

```text
source change
    ↓
test · lint · package
    ↓
versioned chart
    ↓ promotion
scalex-federation
```

## 디렉터리

| 경로 | 역할 |
|---|---|
| [`src/`](src/README.md) | Feature source code와 component |
| [`images/`](images/README.md) | Container image build context; current POC does not require custom images |
| [`chart/`](chart/README.md) | 재사용 가능한 workload Helm chart |
| [`tests/`](tests/README.md) | Runtime script and render contract tests |
| [`scripts/`](scripts/README.md) | 로컬·CI 공통 개발 도구 |

## 로컬 검증

```bash
./scripts/test.sh
```

개별 실행:

```bash
./tests/test-runtime-scripts.sh
./scripts/validate-chart.sh
./scripts/package-chart.sh
```

## 기본 원칙

- Chart는 특정 cluster 이름을 포함하지 않는다.
- Chart는 Karmada placement policy를 소유하지 않는다.
- Federation이 선택할 수 있도록 일관된 workload/component label을 제공한다.
- Base `result-web` Service는 `ClusterIP`이며 non-empty `metadata.annotations` map을 가진다.
- Runtime image는 tag와 immutable digest를 함께 고정한다.
- Secret 값은 source, image, chart에 포함하지 않는다.
