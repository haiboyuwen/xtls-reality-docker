docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t ywhb/xtls-reality:latest \
  --push \
  .