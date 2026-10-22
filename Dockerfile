# debian
FROM debian:trixie-slim
ENV PHP_VERSION=8.3
ARG DEBIAN_VERSION=trixie
LABEL maintainer="dadittoz <daditto@gmail.com>"
ENV DEBIAN_FRONTEND=noninteractive
# contrib + non-free for unrar
RUN sed -i 's/^Components: main$/Components: main contrib non-free/' /etc/apt/sources.list.d/debian.sources
RUN apt-get update && \
	apt-get upgrade -y && \
	apt-get install -y --no-install-recommends ca-certificates lsb-release gnupg gettext-base \
		inotify-tools supervisor unrar unzip wget zip cron curl locales procps && \
	echo -n > /var/lib/apt/extended_states
RUN useradd -u 500 core

# --------------
# locale
RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
RUN sed -i -e 's/# ru_RU.UTF-8 UTF-8/ru_RU.UTF-8 UTF-8/' /etc/locale.gen
RUN dpkg-reconfigure locales

# --------------
# nginx
RUN curl -fsSL https://nginx.org/keys/nginx_signing.key | gpg --dearmor -o /usr/share/keyrings/nginx-archive-keyring.gpg && \
        echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] http://nginx.org/packages/debian ${DEBIAN_VERSION} nginx" > /etc/apt/sources.list.d/nginx.list && \
        apt-get update && apt-get install -y nginx && \
        echo -n > /var/lib/apt/extended_states

# --------------
# php
RUN curl -fsSLo /tmp/debsuryorg-archive-keyring.deb https://packages.sury.org/debsuryorg-archive-keyring.deb && \
        dpkg -i /tmp/debsuryorg-archive-keyring.deb && rm /tmp/debsuryorg-archive-keyring.deb && \
        echo "deb [signed-by=/usr/share/keyrings/debsuryorg-archive-keyring.gpg] https://packages.sury.org/php/ ${DEBIAN_VERSION} main" > /etc/apt/sources.list.d/php.list
RUN apt-get update
# same extension set as 7.2 image; mcrypt/redis now from sury packages instead of pecl, mongo -> mongodb
RUN apt-get install -y php${PHP_VERSION}-cli php${PHP_VERSION}-curl php${PHP_VERSION}-fpm php${PHP_VERSION}-gd php${PHP_VERSION}-mysql php${PHP_VERSION}-mongodb php${PHP_VERSION}-redis php${PHP_VERSION}-xmlrpc php${PHP_VERSION}-apcu php${PHP_VERSION}-opcache php${PHP_VERSION}-mbstring php${PHP_VERSION}-intl php${PHP_VERSION}-imagick php${PHP_VERSION}-xml php${PHP_VERSION}-zip php${PHP_VERSION}-soap php${PHP_VERSION}-memcached php${PHP_VERSION}-bcmath php${PHP_VERSION}-gmp php${PHP_VERSION}-mcrypt
RUN update-alternatives --set php /usr/bin/php${PHP_VERSION}
RUN echo "opcache.interned_strings_buffer=8 \n opcache.memory_consumption=128 \n opcache.huge_code_pages=on" >> /etc/php/${PHP_VERSION}/mods-available/opcache.ini


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

# --------------
# nginx:config
RUN echo "real_ip_header X-Forwarded-For;" | tee -a /etc/nginx/nginx.d/nginx-cloudflare-ips.conf
RUN curl -fsSL https://www.cloudflare.com/ips-v4 | awk '{print "set_real_ip_from " $0 ";" }' | tee -a /etc/nginx/nginx.d/nginx-cloudflare-ips.conf
RUN curl -fsSL https://www.cloudflare.com/ips-v6 | awk '{print "set_real_ip_from " $0 ";" }' | tee -a /etc/nginx/nginx.d/nginx-cloudflare-ips.conf

# --------------
# supervisor:config
RUN envsubst < /etc/supervisor/conf.d/base-services.conf | tee /etc/supervisor/conf.d/base-services.conf.new
RUN mv /etc/supervisor/conf.d/base-services.conf.new /etc/supervisor/conf.d/base-services.conf


# --------------
# boot script
RUN chmod +x /config/loop
CMD ["/config/loop"]

# --------------
# clean up
RUN apt-get clean
RUN echo -n > /var/lib/apt/extended_states

# --------------
# settings
EXPOSE 80
