# rgw-analysis-web Helm chart

This chart renders one cluster-neutral logical release, `rgw-analysis-web`, for the ScaleX RGW/S3 analysis POC.

It creates:

- `dataset-seeder` Kubernetes `Job` that uploads a deterministic CSV input object.
- `analyzer` Kubernetes `Job` that waits for the input object, computes row count/sum/average, and uploads `result.json` plus `index.html`.
- `result-web` `Deployment` with:
  - an AWS CLI S3 sync sidecar that polls the result prefix into a shared nginx html directory;
  - an official nginx container serving the synced files.
- `result-web` `Service`, base type `ClusterIP`.
- ConfigMaps `rgw-analysis-web-scripts` and `rgw-analysis-web-runtime` for shell scripts and nginx config.
- ServiceAccount with token automount disabled.
- Optional namespaced `ObjectBucketClaim` for an application-owned bucket.

The chart intentionally does **not** contain member cluster names, Karmada `PropagationPolicy`, Karmada `OverridePolicy`, or credentials.

## ObjectBucketClaim and required Secret

When `objectStorage.claim.enabled=true`, the chart declares an OBC in the Helm
release namespace. The target cluster's Rook provisioner creates the bucket and
its generated Secret/ConfigMap. The chart never renders access-key values.

For same-cluster consumption, `s3.secretName` may reference the generated OBC
Secret directly. A cross-cluster release must mirror that generated credential
through a platform credential bridge or external Secret store before workloads
in another member cluster can start.

The configured runtime Secret must contain:

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

The Secret name is configurable through `s3.secretName`.

## Important values

| Value | Purpose |
|---|---|
| `objectStorage.claim.enabled` | Render a feature-owned namespaced OBC. |
| `objectStorage.claim.name` | OBC name; Rook uses it for generated Secret/ConfigMap names. |
| `objectStorage.claim.bucketName` | Explicit bucket name when the release requires a stable cross-cluster contract. |
| `objectStorage.claim.generateBucketName` | Prefix for a generated bucket name; mutually exclusive with `bucketName`. |
| `objectStorage.claim.storageClassName` | Infra-provided object bucket StorageClass. |
| `s3.endpointUrl` | S3/RGW endpoint URL used with `aws --endpoint-url`. |
| `s3.bucket` | Bucket containing input and output objects. |
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
| ConfigMap | `rgw-analysis-web-runtime` |
| Job | `rgw-analysis-web-dataset-seeder` |
| Job | `rgw-analysis-web-analyzer` |
| Deployment | `rgw-analysis-web-result-web` |
| Service | `rgw-analysis-web-result-web` |
