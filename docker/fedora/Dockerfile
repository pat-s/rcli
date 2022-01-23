FROM fedora:latest

RUN yum -y --setopt=tsflags=nodocs install wget redhat-lsb-core sudo openblas-devel R readline-devel \
	xorg-x11-server-devel xorg-x11-server-Xorg xorg-x11-server-common xorg-x11-server-devel libX11-devel libXt-devel libcurl-devel ruby ruby-devel && \
	gem install bashcov
