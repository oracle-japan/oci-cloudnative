# ------------
# Stage 1 : Setup the build environment
FROM gradle:8.12 AS buildenv

# create source folder
RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app

# Refresh Deps.
COPY settings.gradle /usr/src/app
# copy buildscript and cache all dependencies
COPY build.gradle /usr/src/app
#
# ------------

# ------------
# Stage 2 : Build the application
#
FROM buildenv AS appbuild
# Copy the source code.
# This layer is recreated only when there are actual source chnages 
COPY src /usr/src/app/src

# Install the application
RUN gradle clean test bootJar && ls -ltr /usr/src/app/build/libs
# ------------

# ------------
# Stage 3 : Application container
#
FROM eclipse-temurin:21-jdk

RUN apt-get update && apt-get install -y procps

# copy the generated application distribution
COPY --from=appbuild /usr/src/app/build/libs/orders-0.0.1-SNAPSHOT.jar /app/orders-0.0.1-SNAPSHOT.jar
COPY  Sampling.acml /app/Sampling.acml

EXPOSE 80
WORKDIR /app
ENV TNS_ADMIN=/wallet/
CMD ["java", "-jar", "/app/orders-0.0.1-SNAPSHOT.jar", "--port=80"]
#
# ------------

