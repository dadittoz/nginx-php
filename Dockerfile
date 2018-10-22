FROM dadittoz/nginx-php:v7.2
MAINTAINER daditto <daditto@gmail.com>
ENV DEBIAN_FRONTEND noninteractive

RUN apt-get install -y apt-utils
RUN apt-get install -y p7zip-full clamdscan clamav-freshclam
RUN echo DatabaseMirror db.de.clamav.net > /etc/freshclam.conf
RUN freshclam -v
