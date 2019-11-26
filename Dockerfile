FROM centos:centos7
MAINTAINER gardar@ok.is

ENV ADAGIOS_HOST adagios.local
ENV ADAGIOS_USER thrukadmin
ENV ADAGIOS_PASS thrukadmin

# - Install basic packages (e.g. python-setuptools is required to have python's easy_install)
# - Install yum-utils so we have yum-config-manager tool available
# - Install inotify, needed to automate daemon restarts after config file changes
# - Install jq, small library for handling JSON files/api from CLI
# - Install supervisord (via python's easy_install - as it has the newest 3.x version)
# - Install the opensource.is and consol labs repositories
# - Install Deps
# - Install Nagios 4
# - Enable and start services 
# - Install Livestatus    
# - Add check_mk livestatus broker module to nagios config
# - Install Remote Livestatus service
#   (needs livestatus xinetd config below)
RUN \
  yum update -y && \
  yum install -y epel-release && \
  yum install -y iproute python-setuptools hostname inotify-tools yum-utils which jq top && \
  yum clean all && \
  easy_install supervisor && \
  rpm -ihv http://opensource.is/repo/ok-release.rpm && \
  rpm -Uvh https://labs.consol.de/repo/stable/rhel7/x86_64/labs-consol-stable.rhel7.noarch.rpm && \
  yum update -y ok-release && \
  yum clean all && yum -y update && \
  yum install -y git acl libstdc++-static python-setuptools facter mod_wsgi postfix python-pip sudo && \
  pip install --upgrade pip && \
  yum install -y nagios nagios-plugins-all pnp4nagios && \
  systemctl enable nagios && \
  chkconfig npcd on && \
  systemctl enable httpd && \
  yum install -y check-mk-livestatus && \
  echo "broker_module=/usr/lib64/check_mk/livestatus.o /var/spool/nagios/cmd/livestatus debug=1" >> /etc/nagios/nagios.cfg && \
  yum install -y xinetd && \
  cd /etc/nagios && \
  git init /etc/nagios/ && \
  git config user.name "User" && \
  git config user.email "email@mail.com" && \
  git add * && \
  git commit -m "Initial commit" && \
  chown -R nagios:nagios /etc/nagios/* /etc/nagios/.git && \
  mkdir -p /opt/pynag && \
  cd /opt/ && \
  pip install django==1.6 && \
  pip install simplejson && \
  git clone git://github.com/pynag/pynag.git && \
  mkdir -p /opt/adagios && \
  git clone git://github.com/opinkerfi/adagios.git && \
  cd /opt/adagios/adagios && \
  cp -r etc/adagios /etc/adagios && \
  chown -R nagios:nagios /etc/adagios && \
  chmod g+w -R /etc/adagios && \
  mkdir -p /var/lib/adagios/userdata && \
  chown nagios:nagios /var/lib/adagios && \
  mkdir /etc/nagios/adagios && \
  mkdir -p /etc/nagios/adagios /etc/nagios/commands && \
  echo "cfg_dir=/etc/nagios/adagios" >> /etc/nagios/nagios.cfg && \
  echo "cfg_dir=/etc/nagios/commands" >> /etc/nagios/nagios.cfg && \
  sed -i 's|debug_level=0|debug_level=1|g' /etc/nagios/nagios.cfg && \
  usermod -G apache nagios && \
  sed -i 's|^\(nagios_init_script\)=\(.*\)$|\1="sudo /usr/bin/nagios-supervisor-wrapper.sh"|g' /etc/adagios/adagios.conf && \
  echo "nagios ALL=NOPASSWD: /usr/bin/nagios-supervisor-wrapper.sh" >> /etc/sudoers.d/adagios && \
  echo "RedirectMatch ^/$ /adagios" > /etc/httpd/conf.d/redirect.conf

ADD container-files/etc/xinetd.d/livestatus /etc/xinetd.d/livestatus

# Add supervisord conf, bootstrap.sh files
ADD container-files /
ADD supervisord-nagios.conf /etc/supervisor.d/supervisord-nagios.conf

EXPOSE 80
# Livestatus remote service
EXPOSE 6557

VOLUME ["/data", "/etc/nagios", "/var/log/nagios", "/etc/adagios", "/opt/adagios", "/opt/pynag"]

ENTRYPOINT ["/config/bootstrap.sh"]
