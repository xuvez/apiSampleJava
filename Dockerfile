# build stage
FROM maven:3.5-jdk-8-alpined
WORKDIR /java
COPY . /java/
RUN mvn clean package

# final stage
#FROM openjdk:8-jre-alpine
#COPY --from=build-env /java/target/*.jar /app.jar
#CMD java -jar app.jar


