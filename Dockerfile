FROM ubuntu:18.04

MAINTAINER <christoph.hahn@uni-graz.at>

RUN apt-get update && apt-get -y upgrade && apt-get install -y build-essential vim git wget ncbi-blast+ python3 python3-pip 

WORKDIR /usr/src

# install Hmmer
RUN wget http://eddylab.org/software/hmmer/hmmer-3.1b2.tar.gz && tar xvfz hmmer-3.1b2.tar.gz && \
	cd hmmer-3.1b2 && ./configure && make && make install && cd ..

# install Augustus
RUN apt install -y augustus augustus-data augustus-doc && \
	wget -O /usr/bin/augustus https://github.com/Gaius-Augustus/Augustus/releases/download/3.3.2/augustus
ENV AUGUSTUS_CONFIG_PATH /usr/share/augustus/config

# install BUSCO and set the default in the scripts to python3 so I don't have to type it each time
# and full path each time when called
RUN git clone --recursive https://gitlab.com/ezlab/busco.git && \
	cd busco && \
	git reset --soft 3927d240 && \
	python3 setup.py install && cd .. && \
	sed -i 's?/usr/bin/env python?/usr/bin/env python3?' /usr/src/busco/scripts/generate_plot.py && \
	sed -i 's?/usr/bin/env python?/usr/bin/env python3?' /usr/src/busco/scripts/run_BUSCO.py && \
	ln -s /usr/src/busco/scripts/*.py /usr/bin/

ADD config.ini /usr/src/busco/config
ENV BUSCO_CONFIG_FILE /usr/src/busco/config/config.ini

#Install R (R installation asks for timezone interactively so this needs to be switched off and set before)
ENV DEBIAN_FRONTEND noninteractive
ENV DEBCONF_NONINTERACTIVE_SEEN true
## preesed tzdata, update package index, upgrade packages and install needed software
# and finally ggplot2 with all dependencies
RUN echo "tzdata tzdata/Areas select Europe" > /tmp/preseed.txt; \
	echo "tzdata tzdata/Zones/Europe select Vienna" >> /tmp/preseed.txt; \
	debconf-set-selections /tmp/preseed.txt && \
	apt-get update && \
	apt-get install -y tzdata r-base && \
	R --vanilla -e 'install.packages("ggplot2", repos="http://cran.wu.ac.at/")'

#create working directory and move to entrypoint
VOLUME /home/data
WORKDIR /home/data
