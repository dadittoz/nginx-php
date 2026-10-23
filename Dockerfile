FROM dadittoz/nginx-php:v7.2-bookworm
LABEL maintainer="daditto <daditto@gmail.com>"
ENV DEBIAN_FRONTEND=noninteractive

# ionCube loaders tarball from 2026-10-23 (loader v15.5.1); bump both when updating.
ARG IONCUBE_URL=https://downloads.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz
ARG IONCUBE_SHA256=739962bd012e77ee82bf01f77a9641f050e4be057f0a5d1a95fe59ce11fd62ba

RUN mkdir -p setup && cd setup && \
  curl -fsSL "$IONCUBE_URL" -o ioncube.tar.gz && \
  echo "$IONCUBE_SHA256  ioncube.tar.gz" | sha256sum -c - && \
  tar -xzf ioncube.tar.gz && \
  export PHP_EXT_DIR=$(php-config --extension-dir 2>/dev/null || php -r 'echo ini_get("extension_dir");') && \
  mv ./ioncube/ioncube_loader_lin_7.2.so  $PHP_EXT_DIR/ && \
  sed -i "1i zend_extension = $PHP_EXT_DIR/ioncube_loader_lin_7.2.so" /etc/php/7.2/fpm/php.ini && \
  cd .. && rm -rf setup
