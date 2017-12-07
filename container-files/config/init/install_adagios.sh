cd /opt/adagios && python setup.py install && cd /opt/pynag && python setup.py install && cp /opt/adagios/adagios/apache/adagios.conf /etc/httpd/conf.d/ && chmod -R 777 /etc/adagios
nohup python /opt/adagios/adagios/manage.py runserver 0.0.0.0:8000 &
