FROM dadittoz/nginx-php:v8.3
LABEL maintainer="daditto <daditto@gmail.com>"
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y apt-utils p7zip-full clamdscan clamav-freshclam && apt-get clean
# db.de.clamav.net mirror is retired; use the default database mirror
RUN freshclam --stdout || echo "WARNING: freshclam failed at build time; databases will be fetched at runtime"
