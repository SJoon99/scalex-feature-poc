# rgw-analysis-web Helm chart

This chart renders one cluster-neutral logical release, `rgw-analysis-web`, for the ScaleX RGW/S3 analysis POC.

It creates:

- `dataset-seeder` Kubernetes `Job` that uploads a deterministic CSV input object.
- `analyzer` Kubernetes `Job` that waits for the input object, computes row count/sum/average, and uploads `result.json` plus `index.html`.
- `result-web` `Deployment` with:
  - an AWS CLI S3 sync sidecar that polls the result prefix into a shared nginx html directory;
  - an official nginx container serving the synced files.
- `result-web` `Service`, base type `ClusterIP`.
- ConfigMaps `rgw-analysis-web-scripts` and `rgw-analysis-web-nginx` for shell scripts and nginx config.
- ServiceAccount with token automount disabled.

The chart intentionally does **not** contain member cluster names, Karmada policy,
ObjectBucketClaims, StorageClasses, runtime bindings, or credentials.

## Required object-storage binding

The release platform must provide the configured Secret and ConfigMap before the
workloads can start. The chart only references them.

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: rgw-analysis-web-s3
type: Opaque
stringData:
  AWS_ACCESS_KEY_ID: replace-me
  AWS_SECRET_ACCESS_KEY: replace-me
```

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: rgw-analysis-web-runtime
data:
  S3_ENDPOINT_URL: https://s3.example.invalid
  S3_BUCKET: generated-bucket-name
  AWS_DEFAULT_REGION: us-east-1
```

Their names are configured through `s3.secretName` and `s3.configMapName`.

## Important values

| Value | Purpose |
|---|---|
| `s3.configMapName` | Existing normalized ConfigMap containing endpoint, bucket and region. |
| `s3.secretName` | Existing Secret consumed by Jobs and sync sidecar. |
| `s3.inputKey` | Deterministic CSV input object key. |
| `s3.resultPrefix` | Prefix synced into nginx html dir. |
| `s3.resultJsonKey` | Uploaded JSON result key. |
| `s3.resultIndexKey` | Uploaded HTML result key. |
| `images.awsCli.tag` | Explicit AWS CLI runtime image tag. |
| `images.nginx.tag` | Explicit nginx runtime image tag. |
| `resultWeb.service.type` | Base Service type; default remains `ClusterIP`. |
| `resultWeb.service.annotations` | Non-empty base Service annotation map for safe Federation JSON patches. |

Base Service annotations default to:

```yaml
scalex.io/exposure: internal
```

This keeps `/metadata/annotations` present so Federation can patch keys such as `lbipam.cilium.io/ips` without replacing Argo/Karmada tracking annotations.

## Render locally

```bash
helm lint ./chart
helm template rgw-analysis-web ./chart
```

## Label contract

Every workload/selectable object includes:

```yaml
scalex.io/release: rgw-analysis-web
scalex.io/component: dataset-seeder | analyzer | result-web
```

Federation repositories can select on these labels without this chart embedding cluster placement details.

## Deterministic rendered names

When rendered with Helm release name `rgw-analysis-web`, resource names are:

| Kind | Name |
|---|---|
| ConfigMap | `rgw-analysis-web-scripts` |
| ConfigMap | `rgw-analysis-web-nginx` |
| Job | `rgw-analysis-web-dataset-seeder` |
| Job | `rgw-analysis-web-analyzer` |
| Deployment | `rgw-analysis-web-result-web` |
| Service | `rgw-analysis-web-result-web` |

`rgw-analysis-web-runtime` is deliberately absent from rendered resources; it is
owned by the Federation runtime binding step.
