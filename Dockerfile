



FROM ubuntu:18.04 

RUN apt-get -y update && apt-get -y upgrade

RUN apt-get -y install openjdk-8-jdk wget

# RUN mkdir /usr/local/tomcat
RUN wget http://apache.stu.edu.tw/tomcat/tomcat-8/v8.5.60/bin/apache-tomcat-8.5.60.tar.gz -O /tmp/tomcat.tar.gz
# RUN cd /tmp && tar xvfz tomcat.tar.gz
# RUN cp -Rv /tmp/apache-tomcat-8.5.60/* /usr/local/tomcat/

RUN tar -xzvf apache-tomcat-8.5.60.tar.gz
RUN mv apache-tomcat-8.5.60 /opt/tomcat
RUN chgrp -R tomcat /opt/tomcat
RUN chown -R tomcat /opt/tomcat
RUN chmod -R 755 /opt/tomcat
# ENV text = """  
# [Unit]
# Description=Apache Tomcat Web Server
# After=network.target
# [Service]
# Type=forking
# Environment=JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64/jre
# Environment=CATALINA_PID=/opt/tomcat/temp/tomcat.pid
# Environment=CATALINA_HOME=/opt/tomcat
# Environment=CATALINA_BASE=/opt/tomcat
# Environment='CATALINA_OPTS=-Xms512M -Xmx1024M -server -XX:+UseParallelGC'
# Environment='JAVA_OPTS=-Djava.awt.headless=true -Djava.security.egd=file:/dev/./urandom'
# ExecStart=/opt/tomcat/bin/startup.sh
# ExecStop=/opt/tomcat/bin/shutdown.sh
# User=tomcat
# Group=tomcat
# UMask=0007
# RestartSec=15
# Restart=always
# [Install]
# WantedBy=multi-user.target  """

# # RUN echo $foo

# RUN echo $text > /etc/systemd/system/tomcat.service


RUN systemctl daemon-reload
RUN systemctl start tomcat
RUN systemctl enable tomcat
RUN ufw allow 8080



RUN apt-get clean && apt-get purge mysql* && apt-get update -y && apt-get install -y && apt-get install -y mysql-server-5.7 && apt-get dist-upgrade
# EXPOSE 8080
# CMD /usr/local/tomcat/bin/catalina.sh run


RUN apt-get update && apt-get install -y \
    tar \
    wget \
    bash \
    rsync \
    python3.7 \
    python3-pip \
    software-properties-common \
    graphviz

# Fix certificate issues
RUN apt-get update && \
    apt-get install -y ca-certificates-java && \
    apt-get clean && \
    update-ca-certificates -f;


# Setup JAVA_HOME -- useful for docker commandline
ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64/
RUN export JAVA_HOME

RUN echo "export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64/" >> ~/.bashrc

RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*


# RUN chown -R mysql:root /var/lib/mysql/
 
ENV MYSQL_ROOT_PASSWORD  pass
#ENV MYSQL_DATABASE company
#RUN  useradd -m -U -d /opt/tomcat -s /bin/false tomcat

# RUN cd /tmp
### For whatever reason, when Apache Tomcat is updated, older versions are removed from the server.
### If the zip file is not found, you'll need to locate the latest version and update the following
### command, as well as a few others below. The file server is found here:
### http://www-us.apache.org/dist/tomcat/tomcat-8/
RUN  apt-get update -y
# RUN  apt-get install -y maven subversion git unzip wget curl

# install subversion client
RUN apt-get -y update && apt-get install -y subversion

RUN apt install -y  curl && \
     apt install -y tar && \
     apt install -y bash 

ARG MAVEN_VERSION=3.3.9
ARG USER_HOME_DIR="/root"

RUN mkdir -p /usr/share/maven /usr/share/maven/ref \
  && curl -fsSL http://apache.osuosl.org/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz \
    | tar -xzC /usr/share/maven --strip-components=1 \
  && ln -s /usr/share/maven/bin/mvn /usr/bin/mvn

ENV MAVEN_HOME /usr/share/maven
ENV MAVEN_CONFIG "$USER_HOME_DIR/.m2"

COPY mvn-entrypoint.sh /usr/local/bin/mvn-entrypoint.sh
COPY settings-docker.xml /usr/share/maven/ref/

VOLUME "$USER_HOME_DIR/.m2"
ENTRYPOINT ["/usr/local/bin/mvn-entrypoint.sh"]

CMD ["mvn"]

#RUN git clone https://github.com/GoTeamEpsilon/ctakes-rest-service.git

WORKDIR  ctakes-rest-service/
COPY ctakes-rest-service/sno_rx_16ab_db /docker-entrypoint-initdb.d/
COPY ctakes-rest-service/ctakes-web-rest ctakes-web-rest/
RUN mkdir ctakes-codebase-area && \ 
    cd ctakes-codebase-area && \
    svn export 'https://svn.apache.org/repos/asf/ctakes/trunk' && \
    cd trunk/ctakes-distribution && \
    mvn install -Dmaven.test.skip=true && \
    cd ../ctakes-assertion-zoner && \
    mvn install -Dmaven.test.skip=true && \
    cd  /ctakes-rest-service/ctakes-web-rest/ && \
    ls /ctakes-rest-service/ctakes-web-rest/ && \
    mvn install && \
    mv /ctakes-rest-service/ctakes-web-rest/target/ctakes-web-rest.war /opt/tomcat/latest/webapps/

#
EXPOSE 8080


