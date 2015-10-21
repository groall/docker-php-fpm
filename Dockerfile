FROM ubuntu:14.04

MAINTAINER      groall <groall@nodasoft.com>

# Let the conatiner know that there is no tty
ENV DEBIAN_FRONTEND noninteractive

# Set locale
RUN     locale-gen ru_RU.UTF-8 && locale-gen en_US.UTF-8 && dpkg-reconfigure locales

# Set time
RUN     mv /etc/localtime /etc/localtime-old && \
        ln -s /usr/share/zoneinfo/Europe/Moscow /etc/localtime

ENV     PHP5_DATE_TIMEZONE Europe/Moscow

# Update base image
# Add sources for latest nginx
# Install software requirements
RUN     apt-get update && \
        apt-get upgrade -y && \
        BUILD_PACKAGES="php5-fpm php5-mysql php-apc php5-curl php5-gd php5-intl php5-mcrypt php5-memcached \
        php5-xmlrpc php-pear php5-dev php-http php5-cli php5-imap php5-xdebug php5-imagick \
        gcc make g++ build-essential tcl wget git tzdata curl zip nano ca-certificates inotify-tools pwgen \
        libpcre3-dev libevent-dev libmagic-dev librabbitmq1 librabbitmq-dev libcurl3 libcurl4-openssl-dev libssh2-php libc6-dev" && \
        apt-get install -y $BUILD_PACKAGES && \
        apt-get remove --purge -y software-properties-common && \
        apt-get autoremove -y && \
        apt-get clean && \
        apt-get autoclean && \
        echo -n > /var/lib/apt/extended_states && \
        rm -rf /var/lib/apt/lists/* && \
        rm -rf /usr/share/man/?? && \
        rm -rf /usr/share/man/??_*

# Enable mcrypt
RUN     php5enmod mcrypt

# Tweak xdebug config
RUN     echo "xdebug.remote_port=9002" >> /etc/php5/fpm/conf.d/25-modules.ini && \
        echo "xdebug.remote_enable=1" >> /etc/php5/fpm/conf.d/25-modules.ini && \
        echo "xdebug.remote_handler=dbgp" >> /etc/php5/fpm/conf.d/25-modules.ini && \
        echo "xdebug.remote_host=172.17.42.1" >> /etc/php5/fpm/conf.d/25-modules.ini && \
        echo "xdebug.idekey=PHPSTORM" >> /etc/php5/fpm/conf.d/25-modules.ini && \
        echo "xdebug.max_nesting_level=1000" >> /etc/php5/fpm/conf.d/25-modules.ini && \
        echo "xdebug.remote_autostart=1" >> /etc/php5/fpm/conf.d/25-modules.ini

# Install pecl modules
RUN     yes | pecl install redis amqp  apcu-4.0.7 xhprof-0.9.4 raphf propro  pecl_http-1.7.6
RUN     echo "extension=redis.so" >> /etc/php5/fpm/conf.d/25-modules.ini && \
        echo "extension=amqp.so" >> /etc/php5/fpm/conf.d/25-modules.ini && \
        echo "extension=xhprof.so" >> /etc/php5/fpm/conf.d/25-modules.ini && \
        echo "extension=raphf.so" >> /etc/php5/fpm/conf.d/25-modules.ini && \
        echo "extension=propro.so" >> /etc/php5/fpm/conf.d/25-modules.ini && \
        echo "extension=http.so" >> /etc/php5/fpm/conf.d/25-modules.ini

RUN     echo "extension=redis.so" >> /etc/php5/cli/conf.d/25-modules.ini && \
        echo "extension=amqp.so" >> /etc/php5/cli/conf.d/25-modules.ini && \
        echo "extension=xhprof.so" >> /etc/php5/cli/conf.d/25-modules.ini && \
        echo "extension=raphf.so" >> /etc/php5/cli/conf.d/25-modules.ini && \
        echo "extension=propro.so" >> /etc/php5/cli/conf.d/25-modules.ini && \
        echo "extension=http.so" >> /etc/php5/cli/conf.d/25-modules.ini

# Tweak php config
RUN     sed -i -e"s/upload_max_filesize\s*=\s*2M/upload_max_filesize = 100M/g" /etc/php5/fpm/php.ini && \
        sed -i -e"s/post_max_size\s*=\s*8M/post_max_size = 100M/g" /etc/php5/fpm/php.ini && \
        sed -i -e"s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g" /etc/php5/fpm/php.ini

# Tweak php-fpm config
RUN     sed -i -e "s/;daemonize\s*=\s*yes/daemonize = no/g" /etc/php5/fpm/php-fpm.conf

EXPOSE 9000

CMD ["/usr/sbin/php5-fpm", "-F"]