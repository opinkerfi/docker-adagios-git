############################################################
# Dockerfile to build a Naemon/Adagios server
# Based on appcontainers/nagios
############################################################

FROM centos:7
#LABEL com.example.version="0.0.1-beta"
LABEL vendor1="Opin Kerfi hf."
#LABEL com.example.release-date="2019-11-14"

ENV container docker
ENV ADAGIOS_HOST adagios.local
ENV ADAGIOS_USER thrukadmin
ENV ADAGIOS_PASS thrukadmin

# Systemd - preparation
RUN (cd /lib/systemd/system/sysinit.target.wants/; for i in *; do [ $i == \
	systemd-tmpfiles-setup.service ] || rm -f $i; done); \
	rm -f /lib/systemd/system/multi-user.target.wants/*;\
	rm -f /etc/systemd/system/*.wants/*;\
	rm -f /lib/systemd/system/local-fs.target.wants/*; \
	rm -f /lib/systemd/system/sockets.target.wants/*udev*; \
	rm -f /lib/systemd/system/sockets.target.wants/*initctl*; \
	rm -f /lib/systemd/system/basic.target.wants/*;\
	rm -f /lib/systemd/system/anaconda.target.wants/*;
# Systemd - preparation ends

# First install the opensource.is and consol labs repositories
RUN rpm -ihv http://opensource.is/repo/ok-release.rpm \
	&& rpm -Uvh https://labs.consol.de/repo/stable/rhel7/x86_64/labs-consol-stable.rhel7.noarch.rpm \
	&& yum update -y ok-release

# Redhat/Centos users need to install the epel repositories (fedora users skip this step)
RUN yum install -y epel-release && yum clean all && yum -y update

# Install naemon, adagios and other needed packages
RUN yum --enablerepo=ok-testing install -y naemon naemon-livestatus git adagios okconfig acl pnp4nagios python-setuptools postfix python-pip

# Now all the packages have been installed, and we need to do a little bit of
# configuration before we start doing awesome monitoring

# Lets make sure adagios can write to naemon configuration files, and that
# it is a valid git repo so we have audit trail
WORKDIR /etc/naemon
RUN 	git init /etc/naemon ;\
	git config user.name "admin" ;\
	git config user.email "admin@adagios.local" ;\
	git add . ;\
	git commit -a -m "Initial commit"

# Fix permissions for naemon and pnp4nagios
RUN 	chown -R naemon:naemon \
	/etc/naemon \
	/etc/adagios \
	/var/lib/adagios \
	/var/lib/pnp4nagios \
	/var/log/pnp4nagios \
	/var/spool/pnp4nagios \
	/etc/pnp4nagios/process_perfdata.cfg \
	/var/log/okconfig
# ACL group permissions need g+rwx
RUN 	chmod g+rwx -R \
	/etc/naemon \
	/etc/adagios \
	/var/lib/adagios \
	/var/lib/pnp4nagios \
	/var/log/pnp4nagios \
	/var/spool/pnp4nagios \
	/etc/pnp4nagios/process_perfdata.cfg /var/log/okconfig

RUN	setfacl -R -m group:naemon:rwx -m d:group:naemon:rwx \
	/etc/naemon/ \
	/etc/adagios \
	/var/lib/adagios \
	/var/lib/pnp4nagios \
	/var/log/pnp4nagios \
	/var/spool/pnp4nagios \
	/etc/pnp4nagios/process_perfdata.cfg \
	/var/log/okconfig

# Make sure nagios doesn't interfere
RUN	mkdir /etc/nagios/disabled ;\
	mv /etc/nagios/{nagios,cgi}.cfg /etc/nagios/disabled/

# Make objects created by adagios go to /etc/naemon/adagios
RUN	mkdir -p /etc/naemon/adagios ;\
	pynag config --append cfg_dir=/etc/naemon/adagios

# Make adagios naemon aware
RUN sed 's|/etc/nagios/passwd|/etc/thruk/htpasswd|g' -i /etc/httpd/conf.d/adagios.conf ;\
	sed 's|user=nagios|user=naemon|g' -i /etc/httpd/conf.d/adagios.conf ;\
	sed 's|group=nagios|group=naemon|g' -i /etc/httpd/conf.d/adagios.conf ;\
	sed 's|/etc/nagios/nagios.cfg|/etc/naemon/naemon.cfg|g' -i /etc/adagios/adagios.conf ;\
	sed 's|nagios_url = "/nagios|nagios_url = "/naemon|g' -i /etc/adagios/adagios.conf ;\
	sed 's|/etc/nagios/adagios/|/etc/naemon/adagios/|g' -i /etc/adagios/adagios.conf ;\
	sed 's|/etc/init.d/nagios|/etc/init.d/naemon|g' -i /etc/adagios/adagios.conf ;\
	sed 's|nagios_service = "nagios"|nagios_service = "naemon"|g' -i /etc/adagios/adagios.conf ;\
	sed 's|livestatus_path = None|livestatus_path = "/var/cache/naemon/live"|g' -i /etc/adagios/adagios.conf ;\
	sed 's|/usr/sbin/nagios|/usr/bin/naemon|g' -i /etc/adagios/adagios.conf

# Make okconfig naemon aware
RUN sed 's|/etc/nagios/nagios.cfg|/etc/naemon/naemon.cfg|g' -i /etc/okconfig.conf ;\
	sed 's|/etc/nagios/okconfig/|/etc/naemon/okconfig/|g' -i /etc/okconfig.conf ;\
	sed 's|/etc/nagios/okconfig/examples|/etc/naemon/okconfig/examples|g' -i /etc/okconfig.conf

RUN okconfig init && okconfig verify

# Add naemon to apache group so it has permissions to pnp4nagios's session files
RUN usermod -G apache naemon

# Allow Adagios to control the service
RUN sed 's|nagios|naemon|g' -i /etc/sudoers.d/adagios ;\
	sed 's|/usr/sbin/naemon|/usr/bin/naemon|g' -i /etc/sudoers.d/adagios

# Make naemon use nagios plugins, more people are doing it like that. And configure pnp4nagios
RUN sed -i 's|/usr/lib64/naemon/plugins|/usr/lib64/nagios/plugins|g' /etc/naemon/resource.cfg ;\
	sed -i 's|/etc/nagios/passwd|/etc/thruk/htpasswd|g' /etc/httpd/conf.d/pnp4nagios.conf ;\
	sed -i 's|user = nagios|user = naemon|g' /etc/pnp4nagios/npcd.cfg ;\
	sed -i 's|group = nagios|group = naemon|g' /etc/pnp4nagios/npcd.cfg


# Enable Naemon performance data and service performance data
RUN pynag config --set "process_performance_data=1" ;\
	pynag config --set 'service_perfdata_file=/var/lib/naemon/service-perfdata' ;\
	pynag config --set 'service_perfdata_file_template=DATATYPE::SERVICEPERFDATA\tTIMET::$TIMET$\tHOSTNAME::$HOSTNAME$\tSERVICEDESC::$SERVICEDESC$\tSERVICEPERFDATA::$SERVICEPERFDATA$\tSERVICECHECKCOMMAND::$SERVICECHECKCOMMAND$\tHOSTSTATE::$HOSTSTATE$\tHOSTSTATETYPE::$HOSTSTATETYPE$\tSERVICESTATE::$SERVICESTATE$\tSERVICESTATETYPE::$SERVICESTATETYPE$' ;\
	pynag config --set 'service_perfdata_file_mode=a' ;\
	pynag config --set 'service_perfdata_file_processing_interval=15';\
	pynag config --set 'service_perfdata_file_processing_command=process-service-perfdata-file'

# host performance data
RUN pynag config --set 'host_perfdata_file=/var/lib/naemon/host-perfdata' ;\
	pynag config --set 'host_perfdata_file_template=DATATYPE::HOSTPERFDATA\tTIMET::$TIMET$\tHOSTNAME::$HOSTNAME$\tHOSTPERFDATA::$HOSTPERFDATA$\tHOSTCHECKCOMMAND::$HOSTCHECKCOMMAND$\tHOSTSTATE::$HOSTSTATE$\tHOSTSTATETYPE::$HOSTSTATETYPE$' ;\
	pynag config --set 'host_perfdata_file_mode=a' ;\
	pynag config --set 'host_perfdata_file_processing_interval=15' ;\
	pynag config --set 'host_perfdata_file_processing_command=process-host-perfdata-file'

# host commands
RUN pynag add command command_name=process-service-perfdata-file command_line='/bin/mv /var/lib/naemon/service-perfdata /var/spool/pnp4nagios/service-perfdata.$TIMET$' ;\
	pynag add command command_name=process-host-perfdata-file command_line='/bin/mv /var/lib/naemon/host-perfdata /var/spool/pnp4nagios/host-perfdata.$TIMET$' ;\
	pynag config --append cfg_dir=/etc/naemon/commands/

RUN mv /etc/httpd/conf.d/thruk_cookie_auth_vhost.conf /etc/httpd/conf.d/thruk_cookie_auth_vhost.conf.disabled

RUN htpasswd -b /etc/thruk/htpasswd "$ADAGIOS_USER" "$ADAGIOS_PASS" ;\
	rm -f /etc/nagios/passwd ;\
	ln -s /etc/thruk/htpasswd /etc/nagios/passwd

# Redirect root URL to /adagios
RUN echo "RedirectMatch ^/$ /adagios" > /etc/httpd/conf.d/redirect.conf

# Enable debugging mode in livestatus broker
RUN sed -i '/broker_module/ s/$/ debug=1/' /etc/naemon/module-conf.d/livestatus.cfg

# Fix permissions for naemon and pnp4nagios
RUN chown -R naemon:naemon \
	/etc/naemon \
	/etc/adagios \
	/var/lib/adagios \
	/var/lib/pnp4nagios \
	/var/log/pnp4nagios \
	/var/spool/pnp4nagios \
	/etc/pnp4nagios/process_perfdata.cfg \
	/var/log/okconfig

# ACL group permissions need g+rwx
RUN	chmod g+rwx -R \
	/etc/naemon \
	/etc/adagios \
	/var/lib/adagios \
	/var/lib/pnp4nagios \
	/var/log/pnp4nagios \
	/var/spool/pnp4nagios \
	/etc/pnp4nagios/process_perfdata.cfg  \
	/var/log/okconfig

RUN setfacl -R -m group:naemon:rwx -m d:group:naemon:rwx \
	/etc/naemon/ \
	/etc/adagios \
	/var/lib/adagios \
	/var/lib/pnp4nagios \
	/var/log/pnp4nagios \
	/var/spool/pnp4nagios \
	/etc/pnp4nagios/process_perfdata.cfg \
	/var/log/okconfig

# Install Virtualenv
RUN pip install --upgrade pip ;\
	pip install virtualenv

# Clone repositories
RUN git clone git://github.com/opinkerfi/adagios.git /opt/adagios ;\
	git clone git://github.com/opinkerfi/okconfig.git /opt/okconfig ;\
	git clone git://github.com/pynag/pynag.git /opt/pynag

# Enable Virtualenv
RUN virtualenv /opt/venv ;\
	source /opt/venv/bin/activate

# Adagios setup
WORKDIR /opt/pynag
RUN python setup.py build ;\
	python setup.py install

RUN export DJANGO_VERSION="Django<1.9" ;\
	pip install $DJANGO_VERSION ;\
	pip install simplejson ;\
	pip install paramiko ;\
	pip install selenium

WORKDIR /opt/adagios
RUN python setup.py build ;\
	python setup.py install

# Start Adagios development server
#WORKDIR /opt/adagios/adagios
#RUN python manage.py migrate ;\
#RUN	python manage.py runserver 0.0.0.0:8080

# Enable services
RUN systemctl enable httpd naemon npcd

# Remove yum cache
RUN yum clean all -y && rm -rf /var/cache/yum

WORKDIR /etc/naemon

EXPOSE 80
EXPOSE 8080

VOLUME ["/etc/naemon", "/var/log/naemon"]
CMD ["/usr/sbin/init"]

#HEALTHCHECK --interval=2m --timeout=3s CMD curl -f http://localhost:80/ || exit 1
