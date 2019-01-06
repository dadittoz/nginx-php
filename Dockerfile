FROM dadittoz/nginx-php:v7.2
MAINTAINER daditto <daditto@gmail.com>
ENV DEBIAN_FRONTEND noninteractive

RUN mkdir -p setup && cd setup && \
  curl -sSL https://downloads.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz -o ioncube.tar.gz && \
  tar -xzf ioncube.tar.gz && \
  export PHP_EXT_DIR=$(php-config --extension-dir) && \
  mv ./ioncube/ioncube_loader_lin_7.2.so  $PHP_EXT_DIR/ && \
  echo "zend_extension = $PHP_EXT_DIR/ioncube_loader_lin_7.2.so" >> /etc/php/7.2/fpm/php.ini && \
  cd .. && rm -rf setup
