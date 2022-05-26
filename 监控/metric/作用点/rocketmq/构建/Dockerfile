FROM maven:3-alpine as builder
COPY . .
RUN  mvn clean package -DskipTests
FROM java:8
COPY --from=builder target/*.jar app.jar
EXPOSE 5557
ENTRYPOINT ["java","-jar","app.jar"]