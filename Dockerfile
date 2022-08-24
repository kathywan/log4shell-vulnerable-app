# Lacework Agent: adding a build stage
FROM lacework/datacollector:latest-sidecar AS agent-build-image

FROM gradle:7.3.1-jdk17 AS builder
COPY --chown=gradle:gradle . /home/gradle/src
WORKDIR /home/gradle/src
RUN gradle bootJar --no-daemon


FROM openjdk:8u181-jdk-alpine
EXPOSE 8080
# Lacework Agent: copying the binary
COPY --from=agent-build-image /var/lib/lacework-backup /var/lib/lacework-backup
# Lacework Agent: setting up configurations  
RUN  --mount=type=secret,id=LW_AGENT_ACCESS_TOKEN  \
  mkdir -p /var/lib/lacework/config &&             \
  echo '{"tokens": {"accesstoken": "'$(cat /run/secrets/LW_AGENT_ACCESS_TOKEN)'"}}' > /var/lib/lacework/config/config.json

RUN mkdir /app
COPY --from=builder /home/gradle/src/build/libs/*.jar /app/spring-boot-application.jar
ENTRYPOINT ["/var/lib/lacework-backup/lacework-sidecar.sh"]
CMD ["java", "-jar", "/app/spring-boot-application.jar"]
