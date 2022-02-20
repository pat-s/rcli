docker build --platform amd64 -t rockylinux8-rcli:latest --file docker/rockylinux8/Dockerfile .

docker tag rockylinux8-rcli pats22/rockylinux8-rcli

# then push to remote
docker push pats22/rockylinux8-rcli
