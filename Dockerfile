# debian
FROM debian:stretch-slim
ENV PHP_VERSION=7.2
ENV PHP_PEAR_PHP_BIN="/usr/bin/php${PHP_VERSION}"
ARG DEBIAN_VERSION=stretch
MAINTAINER dadittoz <daditto@gmail.com>
ENV DEBIAN_FRONTEND noninteractive
ADD /etc/apt /etc/apt
RUN apt-get update && \
	apt-get upgrade -y && \
	apt-get install -y --no-install-recommends ca-certificates apt-transport-https lsb-release gnupg dirmngr gettext \
		inotify-tools supervisor unrar unzip wget zip cron curl locales && \
	echo -n > /var/lib/apt/extended_states
RUN useradd -u 500 core

# --------------
# locale
RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
RUN sed -i -e 's/# ru_RU.UTF-8 UTF-8/ru_RU.UTF-8 UTF-8/' /etc/locale.gen
RUN dpkg-reconfigure locales

# --------------
# nginx
#RUN rm -rf /etc/nginx/nginx.conf
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys ABF5BD827BD9BF62 && \
        echo "deb http://www.nginx.org/packages/debian/ ${DEBIAN_VERSION} nginx" > /etc/apt/sources.list.d/nginx.list && \
        apt-get install -y nginx && \
        echo -n > /var/lib/apt/extended_states

# --------------
# php
RUN wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg
RUN echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" | tee /etc/apt/sources.list.d/php.list
RUN apt-get update
RUN apt-get install -y php-pear libmcrypt-dev libreadline-dev php${PHP_VERSION}-dev libzip-dev libzstd-dev
RUN apt-get install -y php${PHP_VERSION}-cli php${PHP_VERSION}-curl php${PHP_VERSION}-fpm php${PHP_VERSION}-gd php${PHP_VERSION}-mysql php${PHP_VERSION}-mongo php${PHP_VERSION}-redis php${PHP_VERSION}-xmlrpc php${PHP_VERSION}-apcu php${PHP_VERSION}-opcache php${PHP_VERSION}-mbstring php${PHP_VERSION}-intl php${PHP_VERSION}-imagick php${PHP_VERSION}-xml php${PHP_VERSION}-zip php${PHP_VERSION}-soap php${PHP_VERSION}-memcached php${PHP_VERSION}-bcmath php${PHP_VERSION}-gmp
RUN update-alternatives --set php /usr/bin/php${PHP_VERSION}
RUN echo "opcache.interned_strings_buffer=8 \n opcache.memory_consumption=128 \n opcache.huge_code_pages=on" >> /etc/php/${PHP_VERSION}/mods-available/opcache.ini
#php-mcrypt
RUN pecl install mcrypt-1.0.3
RUN echo "extension=mcrypt.so" > /etc/php/${PHP_VERSION}/mods-available/mcrypt.ini
RUN ln -s /etc/php/${PHP_VERSION}/mods-available/mcrypt.ini /etc/php/${PHP_VERSION}/fpm/conf.d/20-mcrypt.ini
RUN ln -s /etc/php/${PHP_VERSION}/mods-available/mcrypt.ini /etc/php/${PHP_VERSION}/cli/conf.d/20-mcrypt.ini
#phpredis
RUN yes yes | pecl install redis-5.0.2
RUN echo "extension=redis.so" > /etc/php/${PHP_VERSION}/mods-available/redis.ini


# --------------
# clean default configs and create dirs
RUN rm -rf /etc/nginx/addon.d && rm -rf /etc/php/${PHP_VERSION}/fpm/pool.d && \
        mkdir -p /etc/nginx/addon.d /etc/php/${PHP_VERSION}/fpm/pool.d
RUN rm -rf /etc/nginx/*.d && \
        mkdir -p /etc/nginx/addon.d /etc/nginx/conf.d /etc/nginx/host.d /etc/nginx/nginx.d /etc/nginx/global.d


# --------------
# php:config
RUN mkdir /config /data
ADD config /config
ADD etc /etc
RUN envsubst < /etc/php-fpm/php-fpm.conf | tee /etc/php-fpm/php-fpm.conf.new
RUN mv /etc/php-fpm/php-fpm.conf.new /etc/php-fpm/php-fpm.conf
RUN rm -rf /etc/php/${PHP_VERSION}/fpm/pool.d
RUN cp -rp /etc/php-fpm/* /etc/php/${PHP_VERSION}/fpm
RUN rm -rf /etc/php-fpm
#ADD usr /usr

# --------------
# nginx:config
RUN echo "real_ip_header X-Forwarded-For;" | tee -a /etc/nginx/nginx.d/nginx-cloudflare-ips.conf
RUN curl https://www.cloudflare.com/ips-v4 | awk '{print "set_real_ip_from " $0 ";" }' | tee -a /etc/nginx/nginx.d/nginx-cloudflare-ips.conf
RUN curl https://www.cloudflare.com/ips-v6 | awk '{print "set_real_ip_from " $0 ";" }' | tee -a /etc/nginx/nginx.d/nginx-cloudflare-ips.conf

# --------------
# supervisor:config
RUN envsubst < /etc/supervisor/conf.d/base-services.conf | tee /etc/supervisor/conf.d/base-services.conf.new
RUN mv /etc/supervisor/conf.d/base-services.conf.new /etc/supervisor/conf.d/base-services.conf


# --------------
# boot script
RUN chmod +x /config/loop
CMD /config/loop

# --------------
# clean up
RUN apt-get clean
RUN echo -n > /var/lib/apt/extended_states

# --------------
# settings
EXPOSE 80
