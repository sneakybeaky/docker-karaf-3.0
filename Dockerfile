FROM java:8u66

MAINTAINER jon.barber@acm.org

EXPOSE 8181 8101 8778

ENV KARAF_VERSION 3.0.4
ENV DEPLOY_DIR /opt/karaf/deploy

RUN groupadd -r karaf && useradd -r -g karaf karaf
RUN mkdir /opt/karaf
RUN chown karaf:karaf /opt/karaf

USER karaf

ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64

RUN wget http://archive.apache.org/dist/karaf/${KARAF_VERSION}/apache-karaf-${KARAF_VERSION}.tar.gz -O /tmp/karaf.tar.gz

# Unpack
RUN tar xzf /tmp/karaf.tar.gz -C /opt/karaf
RUN ln -s /opt/karaf/apache-karaf-${KARAF_VERSION} /opt/karaf/karaf
RUN rm /tmp/karaf.tar.gz

# Add SSH keys
ADD keys.properties /opt/karaf/apache-karaf-${KARAF_VERSION}/etc/

# Startup and usage script
ADD ./usage /usr/bin/
ADD ./start /usr/bin/

# jolokia agent
RUN wget http://central.maven.org/maven2/org/jolokia/jolokia-jvm/1.3.1/jolokia-jvm-1.3.1-agent.jar -O /opt/karaf/karaf/jolokia-agent.jar

# Remove unneeded apps
RUN rm -rf /opt/karaf/karaf/deploy/README
RUN sed -i 's/^\(.*rootLogger.*\)out/\1stdout/' /opt/karaf/karaf/etc/org.ops4j.pax.logging.cfg

ENV KARAF_OPTS -javaagent:/opt/karaf/karaf/jolokia-agent.jar=host=0.0.0.0,port=8778,authMode=jaas,realm=karaf,user=admin,password=admin
ENV KARAF_HOME /opt/karaf/karaf
ENV PATH $PATH:$KARAF_HOME/bin

CMD ["/usr/bin/usage"]
