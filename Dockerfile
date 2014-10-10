FROM ubuntu:14.04
MAINTAINER Ben Morgan <neembi@gmail.com>

# We can't answer interactive dialogs when building image
ENV DEBIAN_FRONTEND noninteractive

# Make sure the base system is up-to-date
RUN apt-get update && \
    apt-get -yq upgrade

# Add universe and multiverse repositories to sources.list
RUN apt-get install -y software-properties-common python-software-properties debconf-utils && \
    add-apt-repository "deb http://archive.ubuntu.com/ubuntu/ trusty universe multiverse" && \
    add-apt-repository "deb http://archive.ubuntu.com/ubuntu/ trusty-updates universe multiverse"

# Install dependencies for FieldWorks
RUN echo ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true | debconf-set-selections && \
    apt-get update && \
    apt-get install -y flashplugin-installer ttf-mscorefonts-installer unzip libxklavier16

# Install FieldWorks from SIL repository
RUN add-apt-repository "deb http://packages.sil.org/ubuntu trusty main" && \
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 80F251AC2C56031F && \
    echo fieldworks-applications fieldworks/license/cpol-accepted select true | debconf-set-selections && \
    apt-get update && apt-get install -y fieldworks fieldworks-applications flexbridge

# Install Go, because we will need it in a moment
RUN apt-get install -y golang-go

# Replace 1000 and 100 with your user / group id
RUN export uid=1000 gid=100 && \
    mkdir -p /home/you && \
    echo "you:x:${uid}:${gid}:You,,,:/home/you:/bin/bash" >> /etc/passwd && \
    echo "you:x:${uid}:" >> /etc/group && \
    echo "you ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/you && \
    chmod 0440 /etc/sudoers.d/you && \
    chown ${uid}:${gid} -R /home/you

# Configure FieldWorks
RUN adduser you fieldworks

# Compile and install srvcmd
USER you
COPY srvcmd.go /home/you/srvcmd.go
RUN cd /home/you && \
    go build srvcmd.go

USER root
RUN install -m755 /home/you/srvcmd /usr/local/bin/srvcmd && \
    rm /home/you/srvcmd /home/you/srvcmd.go

# Clean-up to reduce the image size
RUN apt-get clean

# Set up final image
USER you
ENV HOME /home/you
ENV DEBIAN_FRONTEND text
EXPOSE 3030
ENTRYPOINT ["/usr/local/bin/srvcmd", "-listen=:3030", "-timeout=1000"]
