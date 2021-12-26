docker build --platform amd64 -t fedora-rcli:latest --file docker/fedora/Dockerfile .

docker tag fedora-rcli pats22/fedora-rcli

# then push to remote
docker push pats22/fedora-rcli
