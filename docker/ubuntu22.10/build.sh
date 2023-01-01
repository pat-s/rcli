docker build --platform amd64 -t ubuntu-22.10-rcli:latest --file docker/ubuntu22.10/Dockerfile .

docker tag ubuntu-22.10-rcli pats22/ubuntu-22.10-rcli

# then push to remote
docker push pats22/ubuntu-22.10-rcli
