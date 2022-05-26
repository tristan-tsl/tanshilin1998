FROM maven:3-alpine as builder
WORKDIR /data
COPY . .
RUN mvn clean package -DskipTest
FROM java:8
VOLUME /tmp
COPY --from=builder /data/target/rocketmq-dashboard-*.jar /rocketmq-dashboard.jar
RUN sh -c 'touch /rocketmq-dashboard.jar'
ENV JAVA_OPTS=""
ENTRYPOINT [ "sh", "-c", "java $JAVA_OPTS -jar /rocketmq-dashboard.jar" ]