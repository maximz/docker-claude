# --platform linux/amd64 required because Google Chrome apt repo only provides amd64 packages
# See: https://stackoverflow.com/a/78466930/130164
docker build --platform linux/amd64 -t cc -f Dockerfile .
