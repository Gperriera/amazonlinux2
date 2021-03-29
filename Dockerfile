#
# Builds EP's base Linux image
# Also installs Java 8 from the download URL provided or a pre-defined default.
#

#####
# JDK download stage
#####
FROM amazonlinux:2 AS jdkdownloader

ARG javaDownloadUrl=https://cdn.azul.com/zulu/bin/zulu8.36.0.1-ca-jdk8.0.202-linux.x86_64.rpm
ARG javaMd5Checksum=bffa08ae3f5da1d14ed154bdf9da1e53 

COPY download-java.sh /
RUN chmod 700 ./download-java.sh && \
    ./download-java.sh

#####
# tini-init download stage
#####
FROM amazonlinux:2 AS tiniinitdownloader

ENV TINI_VERSION v0.18.0

# download tini and tini gpg key
# this is a Docker approved pattern. See: https://github.com/docker-library/official-images#init
COPY gpg-retry-download.sh /gpg-retry-download.sh
RUN chmod 777 gpg-retry-download.sh
RUN curl --connect-timeout 5 --speed-limit 10000 --speed-time 5 --location \
         --retry 10 --retry-max-time 300 --output /tini \
         https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini && \
    curl --connect-timeout 5 --speed-limit 10000 --speed-time 5 --location \
         --retry 10 --retry-max-time 300 --output /tini.asc \
         https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini.asc && \
    /gpg-retry-download.sh 595E85A6B1B4779EA4DAAEC70B588DFF0527A9B7 && \
    gpg --verify /tini.asc

#####
# Image build
#####
FROM amazonlinux:2

# Update for security and install epel rep
RUN yum update -y && \
    yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm && \
    yum -y clean all && \
    rm -rf /var/cache/yum

# install dependencies
RUN yum update -y && \
    yum install -y bind-utils hostname mysql nc tar tini xmlstarlet && \
    yum -y clean all && \
    rm -rf /var/cache/yum

# Install Java
COPY --from=jdkdownloader /java.rpm /
RUN yum -y localinstall java.rpm && \
    rm java.rpm

# Add Mo
RUN curl --connect-timeout 5 --speed-limit 10000 --speed-time 5 --location \
         --retry 10 --retry-max-time 300 --show-error --silent \
         https://raw.githubusercontent.com/tests-always-included/mo/master/mo --output mo && \
    chmod +x mo && \
    mv mo /usr/local/bin/

# Set environment variables.
ENV HOME /root
ENV JAVA_HOME /usr/lib/jvm/zulu-8

# Define working directory.
WORKDIR /root

# Install tini-init
COPY --from=tiniinitdownloader /tini /opt/bin/
RUN chmod 755 /opt/bin/tini
ENTRYPOINT ["/opt/bin/tini", "-g", "--", "/bin/sh", "-ac"]

# Define default command.
CMD ["bash"]
