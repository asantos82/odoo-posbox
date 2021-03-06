FROM debian:jessie
MAINTAINER Andre Santos <dre.santos@gmail.com>

# Install some deps, lessc and less-plugin-clean-css, and wkhtmltopdf
RUN set -x; \
        apt-get update \
        && apt-get install -y --no-install-recommends \
	    sudo \
	    adduser \
	    apache2 \
	    postgresql-client \
	    python python-dateutil \
	    python-decorator \
	    python-docutils \
	    python-feedparser \
	    python-imaging \
	    python-jinja2 \
	    python-ldap \
	    python-libxslt1 \
	    python-lxml \
	    python-mako \
	    python-mock \
	    python-openid \
	    python-passlib \
	    python-psutil \
	    python-psycopg2 \
	    python-pybabel \
	    python-pychart \
	    python-pydot \
	    python-pyparsing \
	    python-pypdf \
	    python-reportlab \
	    python-requests \
	    python-simplejson \
	    python-tz python-unittest2 \
	    python-vatnumber \
	    python-vobject \
	    python-werkzeug \
	    python-xlwt \
	    python-yaml \
	    python-gevent \
	    python-serial \
	    python-pip \
	    python-dev \
	    net-tools \
	    vim \
	    mc \
	    mg \
	    screen \
	    iw \
	    hostapd \
	    isc-dhcp-server \
	    git \
	    rsync \
	    console-data \
	    gcc \
	    cron \
	    usbutils \
	&& pip install pyusb==1.0b1 \
	    qrcode \
	    evdev            

RUN set -x; \
	useradd --create-home --shell /bin/bash odoo \
	&& groupadd usbusers \
	&& usermod -a -G usbusers odoo \
	&& usermod -a -G lp odoo


RUN echo '* * * * * rm /var/run/odoo/sessions/*' | crontab -

WORKDIR "/home/odoo"
RUN set -x; \
	git clone -b 8.0 --no-checkout --depth 1 https://github.com/odoo/odoo.git 
RUN chown -R odoo:odoo /home/odoo/odoo	
WORKDIR "/home/odoo/odoo"

USER odoo
RUN set -x; \
	git config core.sparsecheckout true \
	&& echo -e "addons/web\naddons/web_kanban\naddons/hw_*\naddons/point_of_sale/tools/posbox/configuration\nopenerp/\nodoo.py" > sparse-checkout > /dev/null \
	&& git read-tree -mu HEAD

USER root
COPY config.py /home/odoo/odoo/openerp/tools/config.py
RUN set -x; \
	chown odoo:odoo /home/odoo/odoo/openerp/tools/config.py

COPY posbox_update.sh /home/odoo/odoo/addons/point_of_sale/tools/posbox/configuration/posbox_update.sh
RUN set -x; \
	chown odoo:odoo /home/odoo/odoo/addons/point_of_sale/tools/posbox/configuration/posbox_update.sh \
	&& chmod 755 /home/odoo/odoo/addons/point_of_sale/tools/posbox/configuration/posbox_update.sh

COPY main.py /home/odoo/odoo/addons/hw_posbox_upgrade/controllers/main.py
RUN set -x; \
	chown odoo:odoo /home/odoo/odoo/addons/hw_posbox_upgrade/controllers/main.py

COPY odoo.conf /home/odoo/odoo/addons/point_of_sale/tools/posbox/configuration/odoo.conf
RUN set -x; \
        chown odoo:odoo /home/odoo/odoo/addons/point_of_sale/tools/posbox/configuration/odoo.conf \
	&& chmod 644 /home/odoo/odoo/addons/point_of_sale/tools/posbox/configuration/odoo.conf

COPY hw_escpos_controllers_main.py /home/odoo/odoo/addons/hw_escpos/controllers/main.py
RUN set -x; \
        chown odoo:odoo /home/odoo/odoo/addons/hw_escpos/controllers/main.py \
        && chmod 644 /home/odoo/odoo/addons/hw_escpos/controllers/main.py 

VOLUME /var/log/odoo

USER root
RUN set -x; \
	touch /var/log/odoo/odoo-posbox.log \
	&& chown odoo:odoo /var/log/odoo/odoo-posbox.log

COPY 99-usb.rules /etc/udev/rules.d/99-usb.rules

EXPOSE 8869

#RUN set -x; \
#        udevadm control --reload-rules
#ca-certificates \
#            curl \
#            node-less \
#            node-clean-css \
#            python-pyinotify \
#            python-renderpm \
#            python-support \
#        && curl -o wkhtmltox.deb -SL http://nightly.odoo.com/extra/wkhtmltox-0.12.1.2_linux-jessie-amd64.deb \
#        && echo '40e8b906de658a2221b15e4e8cd82565a47d7ee8 wkhtmltox.deb' | sha1sum -c - \
#        && dpkg --force-depends -i wkhtmltox.deb \
#        && apt-get -y install -f --no-install-recommends \
#        && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false -o APT::AutoRemove::SuggestsImportant=false npm \
#        && rm -rf /var/lib/apt/lists/* wkhtmltox.deb

# Install Odoo
#ENV ODOO_VERSION 9.0
#ENV ODOO_RELEASE 20160609
#RUN set -x; \
#        curl -o odoo.deb -SL http://nightly.odoo.com/${ODOO_VERSION}/nightly/deb/odoo_${ODOO_VERSION}c.${ODOO_RELEASE}_all.deb \
#        && echo '56e7e5dc2525fd8c1522c05deb0f7f349a966260 odoo.deb' | sha1sum -c - \
#        && dpkg --force-depends -i odoo.deb \
#        && apt-get update \
#        && apt-get -y install -f --no-install-recommends \
#        && rm -rf /var/lib/apt/lists/* odoo.deb

# Copy entrypoint script and Odoo configuration file
#COPY ./entrypoint.sh /
#COPY ./openerp-server.conf /etc/odoo/
#RUN chown odoo /etc/odoo/openerp-server.conf

# Mount /var/lib/odoo to allow restoring filestore and /mnt/extra-addons for users addons
#RUN mkdir -p /mnt/extra-addons \
#        && chown -R odoo /mnt/extra-addons
#VOLUME ["/var/lib/odoo", "/mnt/extra-addons"]

# Expose Odoo services
#EXPOSE 8069 8071

# Set the default config file
#ENV OPENERP_SERVER /etc/odoo/openerp-server.conf

# Set default user when running the container
#USER odoo

#ENTRYPOINT ["/entrypoint.sh"]
#CMD ["openerp-server"]

