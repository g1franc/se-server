
# Space Engineers on Linux
# Dockerfile based on original work by webanck.
# See https://github.com/webanck/docker-wine-steam

FROM ubuntu:14.04
MAINTAINER Guillaume FRANCOIS <guillaume.francois55@gmail.com>

RUN mkdir -p /home/root
ENV HOME /home/root
WORKDIR /home/root

# Setting up the wineprefix to force 32 bit architecture.
ENV WINEPREFIX /home/root/.wine
ENV WINEARCH win32

# Disabling warning messages from wine, comment for debug purpose.
ENV WINEDEBUG -all

######################### START  INSTALLATIONS ##########################

# Disable interaction from package installation during the docker image building.
ENV DEBIAN_FRONTEND noninteractive

# We want the 32 bits version of wine allowing winetricks.
RUN	dpkg --add-architecture i386 && \

# Set the time zone.
	echo "Europe/Paris" > /etc/timezone && \
	dpkg-reconfigure -f noninteractive tzdata && \

# Updating and upgrading a bit.
	apt-get update && \
	apt-get upgrade -y && \

# We need software-properties-common to add ppas.
	apt-get install -y --no-install-recommends software-properties-common && \

# Add the wine PPA.
	add-apt-repository ppa:ubuntu-wine/ppa && \
	apt-get update && \

# Installation of win, winetricks and temporary xvfb to install winetricks tricks during docker build.
	apt-get install -y --no-install-recommends wine1.7 winetricks xvfb && \

# Installation of winbind to stop ntlm error messages.
	apt-get install -y --no-install-recommends winbind && \

# Installation of winetricks tricks as wine user.
	su -p -l root -c winecfg && \
	su -p -l root -c 'xvfb-run -a winetricks -q corefonts' && \
	su -p -l root -c 'xvfb-run -a winetricks -q dotnet20' && \
	su -p -l root -c 'xvfb-run -a winetricks -q dotnet40' && \
	su -p -l root -c 'xvfb-run -a winetricks -q xna40' && \
	su -p -l root -c 'xvfb-run -a winetricks d3dx9' && \
	su -p -l root -c 'xvfb-run -a winetricks -q directplay' && \

# Installation of git, build tools and sigmap.
	apt-get install -y --no-install-recommends build-essential git-core && \
	git clone https://github.com/marjacob/sigmap.git && \
	(cd sigmap && exec make) && \
	install sigmap/bin/sigmap /usr/local/bin/sigmap && \
	rm -rf sigmap/ && \

# Cleaning up.
	apt-get autoremove -y --purge build-essential git-core && \
	apt-get autoremove -y --purge software-properties-common && \
	apt-get autoremove -y --purge xvfb && \
	apt-get autoremove -y --purge && \
	apt-get clean -y && \
	rm -rf /home/root/.cache && \
	rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

######################### END OF INSTALLATIONS ##########################

ADD install.sh /install.sh
RUN /install.sh && rm /install.sh

# Launching the server as the wine user.
ENTRYPOINT ["/usr/local/bin/sigmap", "-m 15:2", "/usr/local/bin/space-engineers-server", "-noconsole"]
CMD [""]
