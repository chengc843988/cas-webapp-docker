FROM centos:centos7

MAINTAINER Apereo Foundation

ENV PATH=$PATH:$JRE_HOME/bin
ARG cas_version

RUN yum -y install wget tar unzip git \
    && yum -y clean all

# change JDK to 12, 
# 1. change zulu version no
# 2. change java version
# 3. zulu's hash code!
# 4. change the jre's home
#    java_version=8.0.131; \
#    zulu_version=8.21.0.1; \
#    java_hash=1931ed3beedee0b16fb7fd37e069b162; \


# Download Azul Java, verify the hash, and install \
RUN set -x; \
    zulu_version=12.2.3-ca; \
    java_version=12.0.1; \
    java_hash=772a8d0b5f2e610d9061ed448c9221a8; \
    cd / \
    && wget https://cdn.azul.com/zulu/bin/zulu$zulu_version-jdk$java_version-linux_x64.tar.gz \
    && echo "$java_hash  zulu$zulu_version-jdk$java_version-linux_x64.tar.gz" | md5sum -c - \
    && tar -zxvf zulu$zulu_version-jdk$java_version-linux_x64.tar.gz -C /opt \
    && rm zulu$zulu_version-jdk$java_version-linux_x64.tar.gz \
    && ln -s /opt/zulu$zulu_version-jdk$java_version-linux_x64/ /opt/jre-home;

# make sure where zulu's installed!!
# JDK12: is moved to /opt/zulu...../
# JDK1.8: is in /opt/zulu/jre
RUN whereis java; ls -ald /opt/

# maybe zulu has no security directory!
RUN [[ -d /opt/jre-home/lib/security ]] || mkdir -p /opt/jre-home/lib/security/


RUN cd / \
	&& wget http://cdn.azul.com/zcek/bin/ZuluJCEPolicies.zip \
    && unzip ZuluJCEPolicies.zip \
    && mv -f ZuluJCEPolicies/*.jar /opt/jre-home/lib/security \
    && rm ZuluJCEPolicies.zip;

# Set up Oracle Java properties
# RUN set -x; \
#     java_version=8u112; \
#     java_bnumber=15; \
#     java_semver=1.8.0_112; \
#     java_hash=eb51dc02c1607be94249dc28b0223be3712b618ef72f48d3e2bfd2645db8b91a; \

# # Download Oracle Java, verify the hash, and install \
#     cd / \
#     && wget --no-check-certificate --no-cookies --header "Cookie: oraclelicense=accept-securebackup-cookie" \
#     http://download.oracle.com/otn-pub/java/jdk/$java_version-b$java_bnumber/server-jre-$java_version-linux-x64.tar.gz \
#     && echo "$java_hash  server-jre-$java_version-linux-x64.tar.gz" | sha256sum -c - \
#     && tar -zxvf server-jre-$java_version-linux-x64.tar.gz -C /opt \
#     && rm server-jre-$java_version-linux-x64.tar.gz \
#     && ln -s /opt/jdk$java_semver/ /opt/jre-home;

# Download the CAS overlay project \
RUN cd / \
    && git clone --depth 1 --single-branch -b $cas_version https://github.com/apereo/cas-overlay-template.git cas-overlay \
    && mkdir -p /etc/cas \
    && mkdir -p cas-overlay/bin;

COPY thekeystore /etc/cas/
COPY bin/*.* cas-overlay/bin/
COPY etc/cas/config/*.* /cas-overlay/etc/cas/config/
COPY etc/cas/services/*.* /cas-overlay/etc/cas/services/

#RUN chmod -R 750 cas-overlay/bin \
#    && chmod 750 cas-overlay/mvnw \
#    && chmod 750 cas-overlay/build.sh \
#    && chmod 750 /opt/jre-home/bin/java;

# chmod to 755 or 750
RUN chmod -R 750 cas-overlay/bin \
    && chmod 750 cas-overlay/gradlew \
    && chmod 750 cas-overlay/gradlew.bat \
    && chmod 750 /opt/jre-home/bin/java;    
    
# Enable if you are using Oracle Java
#	&& chmod 750 /opt/jre-home/jre/bin/java;

EXPOSE 8080 8443

WORKDIR /cas-overlay

ENV JAVA_HOME /opt/jre-home
ENV PATH $PATH:$JAVA_HOME/bin:.

# RUN ./mvnw clean package -T 10 && rm -rf /root/.m2
RUN ./gradlew clean build

# some security issue, if not run as root
# RUN chmod 0777 /cas-overlay

CMD ["/cas-overlay/bin/run-cas.sh"]
