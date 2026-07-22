FROM eclipse-temurin:21-jdk-jammy  
COPY target/*.jar product-service-loadtest.jar  
ENTRYPOINT ["java","-jar","/product-service-loadtest.jar"]

