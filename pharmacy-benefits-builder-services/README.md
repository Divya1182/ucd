# Pharmacy Benefits Build Service

# To start application add below param in Vm
 -Dspring.profiles.active=local
-Dspring.config.location=classpath:/bootstrap-local.yml
-Dlogging.config=classpath:properties/common/log4j2.properties
-Dlogging.level.root=debug