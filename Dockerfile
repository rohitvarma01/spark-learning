ARG debian_buster_image_tag=8-jre-slim
FROM openjdk:${debian_buster_image_tag} as builder
LABEL maintainer="Rohit Varma <rohit.varma@m2pfintech.com>"

ARG build_date

LABEL org.label-schema.build-date=${build_date}
LABEL org.label-schema.name="Apache Spark multinode Cluster on Docker - Spark Image"
LABEL org.label-schema.description="Spark image"

RUN apt-get update -y
RUN apt-get install -y python3-pip
RUN pip install --upgrade pip

RUN apt-get install -y curl vim wget software-properties-common ssh net-tools ca-certificates python3 python3-pip python3-numpy python3-matplotlib python3-scipy python3-pandas

# Specify Python version
ENV PYTHON_VERSION=3
RUN apt-get install -y python${PYTHON_VERSION} python${PYTHON_VERSION}-pip \
    && update-alternatives --install "/usr/bin/python" "python" "$(which python${PYTHON_VERSION})" 1

# Clean up APT cache
RUN apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Fix the value of PYTHONHASHSEED
ENV SPARK_VERSION=3.4.0 \
    HADOOP_VERSION=3 \
    SPARK_HOME=/opt/spark \
    PYTHONHASHSEED=1

# Download and uncompress Spark from the Apache archive
RUN wget --no-verbose -O apache-spark.tgz "https://archive.apache.org/dist/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz" \
    && mkdir -p /opt/spark \
    && tar -xf apache-spark.tgz -C /opt/spark --strip-components=1 \
    && rm apache-spark.tgz



# Apache spark environment
FROM builder as apache-spark

WORKDIR /opt/spark

ENV SPARK_MASTER_HOST spark-master
ENV SPARK_MASTER_PORT 7077

ENV SPARK_MASTER_WEBUI_PORT=8080 \
SPARK_LOG_DIR=/opt/spark/logs \
SPARK_MASTER_LOG=/opt/spark/logs/spark-master.out \
SPARK_WORKER_LOG=/opt/spark/logs/spark-worker.out \
SPARK_WORKER_WEBUI_PORT=8080 \
SPARK_WORKER_PORT=7000 \
SPARK_MASTER="spark://spark-master:7077" \
SPARK_WORKLOAD="master"

EXPOSE 8080 7077 6066

RUN mkdir -p $SPARK_LOG_DIR && \
touch $SPARK_MASTER_LOG && \
touch $SPARK_WORKER_LOG && \
ln -sf /dev/stdout $SPARK_MASTER_LOG && \
ln -sf /dev/stdout $SPARK_WORKER_LOG

COPY start-spark.sh /

CMD ["/bin/bash", "/start-spark.sh"]