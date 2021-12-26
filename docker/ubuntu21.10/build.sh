docker build --platform amd64 -t ubuntu-21.10-rcli:latest --file docker/ubuntu21.10/Dockerfile .

docker tag ubuntu-21.10-rcli pats22/ubuntu-21.10-rcli

# then push to remote
docker push pats22/ubuntu-21.10-rcli
