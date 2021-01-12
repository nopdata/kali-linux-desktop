FROM kalilinux/kali-rolling

RUN echo "deb http://http.kali.org/kali kali-rolling main non-free contrib" > /etc/apt/sources.list && \
echo "deb-src http://http.kali.org/kali kali-rolling main non-free contrib" >> /etc/apt/sources.list
RUN sed -i 's#http://archive.ubuntu.com/#http://tw.archive.ubuntu.com/#' /etc/apt/sources.list

ENV DEBIAN_FRONTEND noninteractive
RUN apt-get -y update && apt-get -y dist-upgrade && apt-get clean \
    && apt-get install -y --no-install-recommends software-properties-common curl
RUN apt-get install -y --no-install-recommends --allow-unauthenticated \
        openssh-server pwgen sudo vim-tiny \
	    supervisor \
        net-tools \
        lxde x11vnc xvfb autocutsel \
	    xfonts-base lwm xterm \
        nginx \
        python3-pip python3-dev build-essential \
        mesa-utils libgl1-mesa-dri \
        dbus-x11 x11-utils \
    && apt-get -y autoclean \
    && apt-get -y autoremove \
    && rm -rf /var/lib/apt/lists/* \
    && pip3 install -U pip

# custom install by hiy
# install firefox
RUN apt-get update
RUN apt-get install gnupg -y
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys A6DCF7707EBC211F
RUN apt-add-repository "deb http://ppa.launchpad.net/ubuntu-mozilla-security/ppa/ubuntu focal main"
RUN apt-get update
RUN apt-get install firefox -y

# install korean
RUN apt-get install fcitx-hangul -y
RUN apt-get install fcitx-lib* -y
RUN apt-get install fonts-nanum* -y
RUN apt-get install whiptail -y

# install gef
RUN apt-get install gdb -y
RUN apt-get install wget -y
WORKDIR /tmp
RUN wget -q -O- https://github.com/hugsy/gef/raw/master/scripts/gef.sh | sh

# install pwntools
RUN apt-get install libssl-dev -y
RUN apt-get install libffi-dev -y
RUN python3 -m pip install --upgrade pwntools

# install openvpn
RUN apt-get install openvpn -y

# install lrzsz
RUN apt-get install lrzsz -y

# install ping
RUN apt-get install iputils-ping -y

# install nmap
RUN apt-get install nmap -y

# install wpscan
RUN apt-get install ruby ruby-dev libcurl4-openssl-dev make -y
RUN mkdir /srv/tool
WORKDIR /srv/tool
RUN git clone https://github.com/wpscanteam/wpscan
WORKDIR /srv/tool/wpscan
RUN gem install bundler && bundler install --without test
RUN gem install wpscan
RUN wpscan --update

# install vim
RUN apt-get install vim -y

# install binwalk
RUN apt-get install binwalk -y

# install john the ripper
RUN apt-get install john -y
RUN mkdir /srv/tool/wordlist
WORKDIR /srv/tool/wordlist
RUN wget https://github.com/brannondorsey/naive-hashcat/releases/download/data/rockyou.txt

# install python2.7
RUN apt-get install python2.7

# download LinEnum
WORKDIR /srv/tool
RUN git clone https://github.com/rebootuser/LinEnum

# install i386 library
RUN dpkg --ad-architecture i386
RUN apt-get update
RUN apt-get install libc6:i386 libncurses5:i386 libstdc++6:i386 -y

# update six package
WORKDIR /tmp
RUN wget https://files.pythonhosted.org/packages/6b/34/415834bfdafca3c5f451532e8a8d9ba89a21c9743a0c59fbd0205c7f9426/six-1.15.0.tar.gz
RUN python3 -m pip install six-1.15.0.tar.gz


# For installing other Kali metapackages check https://tools.kali.org/kali-metapackages
# RUN apt-get update && apt-cache search kali-linux && apt-get install -y   \
#         kali-tools-top10

ENV TINI_VERSION v0.19.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /bin/tini
RUN chmod +x /bin/tini

ADD image /
RUN pip3 install setuptools wheel && pip install -r /usr/lib/web/requirements.txt

EXPOSE 80
WORKDIR /root
ENV HOME=/root \
    SHELL=/bin/bash
ENTRYPOINT ["/startup.sh"]

CMD ["/bin/bash"]
