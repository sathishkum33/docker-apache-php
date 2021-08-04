# Pulling the operating system from docker
FROM oraclelinux:8.4
	
MAINTAINER Sathish Kumar <sathishkum33@gmail.com>

#Adding argument for build
ARG app_port

# Add EPERL repo
RUN yum install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm -y
RUN yum install https://rpms.remirepo.net/enterprise/remi-release-8.rpm -y
    
#Adding timezone to the server
ENV TZ=America/New_York
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN dnf -y install dnf-utils
RUN dnf module reset php -y
RUN dnf module install php:remi-7.4 -y

# Update the repository sources list
RUN yum -y update
	
# Install Apache, PHP and misc tools
RUN yum -y install supervisor \
    git \
    tree \
    httpd \
    php \
    php-common \
    php-zip \
    php-fpm \
    php-pdo \
    php-pdo-dblib \
    php-xml \
    php-json \
    php-ldap \
    php-mysqlnd \   
    bind-utils \
    pwgen \
    psmisc \
    net-tools \
    hostname \
    curl \
    curl-devel \
    sqlite \
    sendmail \
    zip \
    which \
    freetds \
    sudo \
    cronie

# Add config files and scripts
COPY lib/httpd /etc/init.d
COPY lib/php-fpm /etc/init.d
RUN chmod 755 /var/log/httpd
RUN mkdir -p /run/php-fpm

RUN sed -E -i -e 's/^short_open_tag = Off/short_open_tag = On/' /etc/php.ini \
 && sed -E -i -e 's/^expose_php = On/expose_php = Off/' /etc/php.ini \
 && sed -E -i -e 's/^error_reporting = E_ALL \& \~E_DEPRECATED \& \~E_STRICT/error_reporting = E_ALL \& \~E_NOTICE \& \~E_STRICT \& \~E_DEPRECATED/' /etc/php.ini \
 && sed -E -i -e 's/^;html_errors = On/html_errors = On/' /etc/php.ini \
 && sed -E -i -e 's/session.cookie_httponly =/session.cookie_httponly = True/' /etc/php.ini
 
RUN echo "ServerTokens Prod" >> /etc/httpd/conf/httpd.conf \
   && echo "ServerSignature Off" >> /etc/httpd/conf/httpd.conf \
   && echo "ServerName localhost" >> /etc/httpd/conf/httpd.conf \
   && echo "Header always unset X-Powered-By" >> /etc/httpd/conf/httpd.conf \
   && sed -E -i -e "s/^Listen 80/Listen ${app_port}/" /etc/httpd/conf/httpd.conf \
   && sed -E -i -e 's/^DocumentRoot "\/var\/www\/html"/#DocumentRoot "\/var\/www\/html"/' /etc/httpd/conf/httpd.conf \
   && sed -E -i -e 's/DirectoryIndex index.html/DirectoryIndex index.html index.phtml index.php default.php default.phtml/' /etc/httpd/conf/httpd.conf \   
   &&  sed -E -i -e  '/LogFormat.*common/a \   \ ErrorLogFormat "{ \\"time\\":\\"%t\\", \\"function\\":\\"[%-m:%l]\\", \\"pid\\":\\"%P\\", \\"message\\":\\"%M\\", \\"vhost-ServerName\\":\\"%v\\", \\"referer\\":\\"%-{Referer}i\\" }"' /etc/httpd/conf/httpd.conf \
   && sed -E -i -e  '/LogFormat.*common/a \   \ LogFormat "{ \\"time\\":\\"%t\\", \\"time-taken\\":\\"%T\\", \\"IP-client\\":\\"%{X-Forwarded-For}i\\", \\"IP-remote\\":\\"%a\\", \\"remote-hostname\\":\\"%h\\", \\"request-url\\":\\"%V\\", \\"request-context\\":\\"%U\\", \\"query\\":\\"%q\\", \\"method\\":\\"%m\\", \\"status\\":\\"%>s\\", \\"vhost-ServerName\\":\\"%v\\", \\"userAgent\\":\\"%{User-agent}i\\", \\"referer\\":\\"%{Referer}i\\" }" json' /etc/httpd/conf/httpd.conf \
   && sed -E -i -e 's/CustomLog "logs\/access_log" combined/CustomLog "\/var\/log\/httpd\/httpd_access_log.json" combined/' /etc/httpd/conf/httpd.conf \
   && sed -E -i -e 's/ErrorLog "logs\/error_log"/ErrorLog "\/var\/log\/httpd\/httpd_error_log.json"/' /etc/httpd/conf/httpd.conf 

# Configure servicies
ADD lib/start.sh /start.sh
ADD lib/supervisord.conf /etc/supervisord.d/httpd.ini
RUN chmod 755 /start.sh
 
EXPOSE $app_port
 
CMD ["/bin/bash", "/start.sh"]