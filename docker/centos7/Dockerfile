FROM centos:7

RUN yum -y install epel-release yum-utils && \
	# install ruby 2.7
	yum install -y --setopt=tsflags=nodocs centos-release-scl-rh && \
	yum install -y --setopt=tsflags=nodocs rh-ruby27-ruby rh-ruby27-ruby-devel && \
	export PATH=/opt/rh/rh-ruby27/root/usr/local/bin:/opt/rh/rh-ruby27/root/usr/bin${PATH:+:${PATH}} && \
	export LD_LIBRARY_PATH=/opt/rh/rh-ruby27/root/usr/local/lib64:/opt/rh/rh-ruby27/root/usr/lib64${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}} && \
	export MANPATH=/opt/rh/rh-ruby27/root/usr/local/share/man:/opt/rh/rh-ruby27/root/usr/share/man:$MANPATH && \
	export PKG_CONFIG_PATH=/opt/rh/rh-ruby27/root/usr/local/lib64/pkgconfig:/opt/rh/rh-ruby27/root/usr/lib64/ pkgconfig${PKG_CONFIG_PATH:+:${PKG_CONFIG_PATH}} && \
	export XDG_DATA_DIRS=/opt/rh/rh-ruby27/root/usr/local/share:/opt/rh/rh-ruby27/root/usr/share:${XDG_DATA_DIRS:-/usr/local/share:/usr/share} && \
	export PATH=/opt/rh/rh-ruby27/root/usr/local/bin:$PATH && \
	# install r-deps
	yum -y install --setopt=tsflags=nodocs wget redhat-lsb-core sudo openblas R texinfo-tex openblas-devel && \
	gem install bashcov
