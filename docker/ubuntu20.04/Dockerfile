FROM ubuntu:20.04

RUN export DEBIAN_FRONTEND=noninteractive && apt update -y && \
	apt-get install -y --no-install-recommends ruby ruby-dev && \
	gem install bashcov && \
	apt-get install -y --no-install-recommends curl gcc g++ lsb-release wget dpkg sudo apt-utils libbz2-dev libblas-dev libicu-dev liblapack-dev liblzma-dev libpcre3-dev make libpcre2-dev \
	dialog unzip zip lpr perl wget gfortran g++ xorg xorg-dev r-base-core libcurl4-openssl-dev file tzdata && \
	apt autoremove -y && \
	apt-get clean && \
	rm -rf /var/lib/apt/lists/
