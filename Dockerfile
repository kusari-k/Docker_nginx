FROM centos
MAINTAINER kusari-k

EXPOSE 80 443

RUN echo -e """[nginx-stable] \n\
name=nginx stable repo \n\
baseurl=http://nginx.org/packages/centos/\$releasever/\$basearch/ \n\
gpgcheck=1 \n\
enabled=1 \n\
gpgkey=https://nginx.org/keys/nginx_signing.key \n\
module_hotfixes=true \n\
[nginx-mainline] \n\
name=nginx mainline repo \n\
baseurl=http://nginx.org/packages/mainline/centos/\$releasever/\$basearch/ \n\
gpgcheck=1 \n\
enabled=1 \n\
gpgkey=https://nginx.org/keys/nginx_signing.key \n\
module_hotfixes=true""">/etc/yum.repos.d/nginx.repo
RUN sed -i -e "\$afastestmirror=true" /etc/dnf/dnf.conf
RUN dnf install -y https://rpms.remirepo.net/enterprise/remi-release-8.rpm && \
	dnf update -y && \
	dnf install -y nginx rsyslog @php:remi-7.3 php-mysql && \
	dnf clean all

#/etc/nginx/nginx.conf
RUN sed  -i -e "/http\ /a \ \ \ \ server_tokens off;" \
	-e "/keepalive/ s/65/5/" \
	-e "/include.*\.conf/a \ \ \ \ include\ \/etc\/nginx\/user_conf.d\/\*\.conf;" \
	-e "s/#gzip/gzip/" /etc/nginx/nginx.conf

#/etc/php.ini
RUN sed -i -e "/expose_php/ s/On/Off/" \
	-e "/post_max_size/ s/8/500/" \
	-e "/upload_max_filesize/ s/2/500/" \
	-e "/;date\.timezone/ s/=/=\ \"Asia\/Tokyo\"/" \
	-e "/;date\.timezone/ s/;//" \
	-e "/;mbstring\.language/ s/;//" \
	-e "/;mbstring\.internal_encoding/ s/=/=\ UTF-8/" \
	-e "/;mbstring\.internal_encoding/ s/;//" \
       	-e "/;mbstring\.http_input\ / s/=/=\ UTF-8/" \
       	-e "/;mbstring\.http_input\ / s/;//" \
       	-e "/;mbstring\.http_output\ / s/=/=\ pass/" \
       	-e "/;mbstring\.http_output\ / s/;//" \
	-e "/;mbstring\.encoding_translation/ s/Off/On/" \
	-e "/;mbstring\.encoding_translation/ s/;//" \
	-e "/;mbstring.detect_order/ s/;//" \
	-e "/;mbstring.substitute_character/ s/;//" /etc/php.ini

#/etc/php-fpm.d/www.conf
RUN sed -i -e "/user\ =/ s/apache/nginx/" \
	-e "/group\ =/ s/apache/nginx/" \
	-e "/max_children/ s/50/25/" \
	-e "/start_servers/ s/5/10/ " \
	-e "/min_spare_servers/ s/5/10/" \
	-e "/max_spare_servers/ s/35/20/" \
	-e "/max_requests/ s/;//" /etc/php-fpm.d/www.conf

#/etc/rsyslog.conf
RUN sed -i -e "/imjournal/ s/^/#/" \
	-e "s/off/on/" /etc/rsyslog.conf

RUN mkdir /etc/nginx/default_conf.d /etc/nginx/ssl && \
	cp /etc/nginx/conf.d/default.conf /etc/nginx/default_conf.d/default.conf.old && \
	cp -r /usr/share/nginx/html /etc/nginx/default_conf.d/ && \
	openssl dhparam -out /etc/nginx/ssl/dhparam.pem 2048

COPY run.sh  /usr/local/bin/
RUN  chmod 755 /usr/local/bin/run.sh

ENTRYPOINT ["/usr/local/bin/run.sh"]
