FROM azul/zulu-openjdk:8u51

MAINTAINER jon.barber@acm.org

EXPOSE 8181 8101 8778

ENV KARAF_VERSION 3.0.4

ENV APP_ROOT /opt/karaf
ENV KARAF_BASE ${APP_ROOT}/karaf
ENV KARAF_LOCAL_REPO ${KARAF_VERSION}

RUN apt-get -qq update
RUN apt-get -qq install wget

RUN groupadd -r karaf && useradd -r -g karaf karaf
RUN mkdir ${APP_ROOT}
# Set the owner & group permissions on the folder structure
RUN chown karaf:karaf ${APP_ROOT}

USER karaf

ENV JAVA_HOME /usr/lib/jvm/zulu-8-amd64

RUN wget http://archive.apache.org/dist/karaf/${KARAF_VERSION}/apache-karaf-${KARAF_VERSION}.tar.gz -O /tmp/karaf.tar.gz

# Unpack
RUN tar xzf /tmp/karaf.tar.gz -C /opt/karaf
RUN ln -s ${APP_ROOT}/apache-karaf-${KARAF_VERSION} ${KARAF_BASE}
RUN rm /tmp/karaf.tar.gz

# Add SSH keys
COPY keys.properties ${KARAF_BASE}/etc/

# Add PAX URL mvn config
COPY org.ops4j.pax.url.mvn.cfg ${KARAF_BASE}/etc/

# Startup and usage script
COPY ./usage /usr/bin/
COPY ./start /usr/bin/

# jolokia agent
RUN wget http://central.maven.org/maven2/org/jolokia/jolokia-jvm/1.3.1/jolokia-jvm-1.3.1-agent.jar -O ${KARAF_BASE}/jolokia-agent.jar

# Remove unneeded apps
RUN rm -rf ${KARAF_BASE}/deploy/README
RUN sed -i 's/^\(.*rootLogger.*\)out/\1stdout/' /opt/karaf/karaf/etc/org.ops4j.pax.logging.cfg

# Set the owner & group permissions on any new files
RUN chown karaf:karaf ${APP_ROOT}

ENV KARAF_OPTS -javaagent:${KARAF_BASE}/jolokia-agent.jar=host=0.0.0.0,port=8778,authMode=jaas,realm=karaf,user=admin,password=admin -Dapp.root=${APP_ROOT}
ENV KARAF_HOME ${KARAF_BASE}
ENV PATH $PATH:$KARAF_HOME/bin

CMD ["/usr/bin/usage"]
