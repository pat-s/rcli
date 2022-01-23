docker build --platform amd64 -t centos7-rcli:latest --file docker/centos7/Dockerfile .

docker tag centos7-rcli pats22/centos7-rcli

# then push to remote
docker push pats22/centos7-rcli
