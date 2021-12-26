docker build --platform amd64 -t ubuntu-20.04-rcli:latest --file docker/ubuntu20.04/Dockerfile .

docker tag ubuntu-20.04-rcli pats22/ubuntu-20.04-rcli

# then push to remote
docker push pats22/ubuntu-20.04-rcli
