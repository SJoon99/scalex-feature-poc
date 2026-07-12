# scalex-feature-poc

ScaleX User/Dev Layer에서 사용할 feature를 개발하고 배포 artifact로 패키징하는 repository다.

이 repository는 feature의 source code, container image 정의, Helm chart와 테스트를 소유한다. 실제 배포 대상 cluster와 Karmada placement는 `scalex-federation`이 소유한다.

## 책임

- Feature source code 개발
- Container image build 정의
- 재사용 가능한 Helm chart 제공
- Unit/integration/render test
- Versioned artifact 생성
- Federation으로 승격할 immutable revision 제공

## 책임지지 않는 것

- 실제 member cluster 이름과 topology
- Karmada propagation/override policy
- Tower Argo bootstrap
- Cluster Infra 구성
- 운영 credential 보관

## 기본 흐름

```text
source change
    ↓
test · build · scan
    ↓
versioned image/chart
    ↓ promotion
scalex-federation
```

## 디렉터리

| 경로 | 역할 |
|---|---|
| [`src/`](src/README.md) | Feature source code와 component |
| [`images/`](images/README.md) | Container image build context |
| [`chart/`](chart/README.md) | 재사용 가능한 workload Helm chart |
| [`tests/`](tests/README.md) | Unit, integration, render test |
| [`scripts/`](scripts/README.md) | 로컬·CI 공통 개발 도구 |

## 기본 원칙

- Chart는 특정 cluster 이름을 포함하지 않는다.
- Chart는 Karmada placement policy를 소유하지 않는다.
- Federation이 선택할 수 있도록 일관된 workload/component label을 제공한다.
- Image와 chart는 version 또는 digest로 식별 가능해야 한다.
- Secret 값은 source, image, chart에 포함하지 않는다.
