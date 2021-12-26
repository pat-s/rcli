FROM centos:8

RUN yum -y --setopt=tsflags=nodocs install epel-release yum-utils && \
	yum -y config-manager --set-enabled powertools && \
	yum -y --setopt=tsflags=nodocs install wget redhat-lsb-core sudo openblas R texinfo-tex openblas-devel ruby ruby-devel && \
	gem install bashcov

