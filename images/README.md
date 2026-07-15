# images

Feature component별 Containerfile/Dockerfile과 image build context를 둔다.

각 image는 독립적으로 versioning할 수 있어야 하며, runtime credential이나
cluster-specific 설정을 image에 포함하지 않는다. Bucket 이름과 endpoint도 image
build argument로 고정하지 않고 runtime ConfigMap으로 주입한다.
