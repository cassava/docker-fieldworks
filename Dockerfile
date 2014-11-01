FROM ubuntu:12.04
MAINTAINER Ben Morgan <neembi@gmail.com>

# We can't answer interactive dialogs when building image
ENV DEBIAN_FRONTEND noninteractive

# Make sure the base system is up-to-date
RUN apt-get update && \
    apt-get -yq upgrade && \
    apt-get install -y openssh-server

# Add universe and multiverse repositories to sources.list
RUN apt-get install -y software-properties-common python-software-properties debconf-utils && \
    add-apt-repository "deb http://archive.ubuntu.com/ubuntu/ precise universe multiverse" && \
    add-apt-repository "deb http://archive.ubuntu.com/ubuntu/ precise-updates universe multiverse"

# Install dependencies for FieldWorks
RUN echo ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true | debconf-set-selections && \
    apt-get update && \
    apt-get install -y flashplugin-installer ttf-mscorefonts-installer unzip libxklavier16

# Install FieldWorks from SIL repository
RUN add-apt-repository "deb http://packages.sil.org/ubuntu precise main" && \
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 80F251AC2C56031F && \
    echo fieldworks-applications fieldworks/license/cpol-accepted select true | debconf-set-selections && \
    apt-get update && apt-get install -y fieldworks fieldworks-applications flexbridge && \
    adduser root fieldworks

# Configure SSH
ADD ssh/id_rsa.pub /root/.ssh/authorized_keys
RUN mkdir /var/run/sshd && \
    chown root:root /root/.ssh/authorized_keys

# Add yourself
RUN useradd -m you -u 1000 && \
    adduser you fieldworks

# Clean-up to reduce the image size
RUN apt-get clean

# Set up final image
ENV DEBIAN_FRONTEND text

# Start the ssh daemon
EXPOSE 22
CMD ["/usr/sbin/sshd", "-D"]
