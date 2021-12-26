docker build --platform amd64 -t centos8-rcli:latest --file docker/centos8/Dockerfile .

docker tag centos8-rcli pats22/centos8-rcli

# then push to remote
docker push pats22/centos8-rcli
