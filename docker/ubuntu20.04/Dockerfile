FROM ubuntu:20.04

RUN  DEBIAN_FRONTEND=noninteractive && apt update -y && \
	apt install -y --no-install-recommends ruby ruby-dev && \
	gem install bashcov && \
	apt install -y --no-install-recommends curl gcc g++ lsb-release wget dpkg sudo apt-utils \
	dialog unzip zip lpr perl wget gfortran g++ && \
	apt autoremove -y && \
	apt-get clean && \
	rm -rf /var/lib/apt/lists/
