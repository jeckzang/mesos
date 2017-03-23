#
FROM centos:6.6

RUN yum groupinstall -y "Developement Tools"
RUN yum install -y python-devel java-1.7.0-openjdk-devel zlib-devel libcurl-devel openssl-devel cyrus-sasl-devel cyrus-sasl-md5 apr-devel subversion-devel apr-util-devel

# Install wget and tar
RUN yum install -y wget
RUN yum install -y tar

# Install maven.
RUN wget http://mirror.nexcess.net/apache/maven/maven-3/3.0.5/binaries/apache-maven-3.0.5-bin.tar.gz
RUN tar -zxf apache-maven-3.0.5-bin.tar.gz -C /opt/
RUN ln -s /opt/apache-maven-3.0.5/bin/mvn /usr/bin/mvn

# Install gcc version 4.7+
RUN cd /etc/yum.repos.d && wget http://people.centos.org/tru/devtools-2/devtools-2.repo
RUN yum install -y devtoolset-2-gcc-4.8.2 devtoolset-2-gcc-c++-4.8.2
RUN ln -s /opt/rh/devtoolset-2/root/usr/bin/* /usr/local/bin/
RUN yum install -y patch
RUN yum install -y devtoolset-2-binutils


# Install mesos
ENV VERSION 0.22.1
RUN wget http://www.apache.org/dist/mesos/$VERSION/mesos-$VERSION.tar.gz
RUN tar -zxf mesos-$VERSION.tar.gz -C /opt/

# env
ENV JAVA_HOME /usr/lib/jvm/java-1.7.0-openjdk.x86_64

# Make mesos
RUN cd /opt/mesos* && mkdir build && cd build && ../configure && make
RUN cd /opt/mesos* && cd build && make install

# grab gosu for easy step-down from root
RUN curl -o /usr/local/bin/gosu -SL "https://github.com/tianon/gosu/releases/download/1.2/gosu-amd64" \
&& chmod +x /usr/local/bin/gosu

# Install zookeeper
ENV ZOOKEEPER_VERSION 3.4.6
RUN wget http://mirror.metrocast.net/apache/zookeeper/zookeeper-$ZOOKEEPER_VERSION/zookeeper-$ZOOKEEPER_VERSION.tar.gz
RUN tar -zxf zookeeper-$ZOOKEEPER_VERSION.tar.gz -C /opt/
ENV ZOOKEEPER_HOME /opt/zookeeper-$ZOOKEEPER_VERSION

# Config zookeeper
RUN mkdir -p /var/zookeeper
RUN mv $ZOOKEEPER_HOME/conf/zoo_sample.cfg $ZOOKEEPER_HOME/conf/zoo.cfg
RUN grep -rl dataDir $ZOOKEEPER_HOME/conf/zoo.cfg | xargs sed -i 's/tmp/var/g'


# Install sparK
ENV SPARK_VERSION 1.4.0
RUN wget http://ftp.wayne.edu/apache/spark/spark-$SPARK_VERSION/spark-$SPARK_VERSION.tgz
RUN tar -zxf  spark-$SPARK_VERSION.tgz -C /opt/
ENV SPARK_HOME /opt/spark-$SPARK_VERSION
RUN cd $SPARK_HOME && mvn -DskipTests clean package

# create mesos user
ENV MESOS_USER mesos
ENV MESOS_USER_PASSWD mesos
ENV MESOS_USER_GROUP mesos
RUN groupadd $MESOS_USER
RUN useradd $MESOS_USER -g $MESOS_USER_GROUP

# chown
RUN chown -R mesos:mesos $ZOOKEEPER_HOME
RUN chown -R mesos:mesos /var/zookeeper

# Copy hosts file
ADD ./hosts /etc/hosts

# Copy bootstrap.sh
ADD ./bootstrap.sh /etc/bootstrap.sh

# Create temp directory
RUN mkdir /var/lib/mesos
RUN chown $MESOS_USER_GROUP:$MESOS_USER /var/lib/mesos

CMD ["/etc/bootstrap.sh", "-b"]

EXPOSE 5050
