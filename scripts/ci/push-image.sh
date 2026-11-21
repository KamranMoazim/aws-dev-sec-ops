#!/usr/bin/env bash
# Usage: push-image.sh <ecr-repository-url> <tag>
# Tags are immutable, so a re-run of the same commit skips the push instead of failing.
set -euo pipefail

repository_url="$1"
tag="$2"
repository_name="${repository_url#*/}"

if aws ecr describe-images --repository-name "$repository_name" --image-ids imageTag="$tag" >/dev/null 2>&1; then
  echo "Image $repository_name:$tag already exists, skipping push"
else
  docker push "$repository_url:$tag"
fi
