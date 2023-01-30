# Frontend build
FROM node:16 as FRONTEND
ARG ui_tag=main
WORKDIR /app
RUN git clone --depth 1 --branch ${ui_tag} https://github.com/KaotoIO/kaoto-ui.git 
WORKDIR /app/kaoto-ui
RUN yarn install --mode=skip-build
RUN KAOTO_API="" yarn run build

#Backend build
FROM quay.io/quarkus/ubi-quarkus-native-image:22.3-java17 as BACKEND
ARG api_tag=main
USER root
RUN microdnf install git curl
COPY --chown=quarkus:quarkus mvnw /code/mvnw
COPY --chown=quarkus:quarkus .mvn /code/.mvn
USER quarkus
WORKDIR /code
RUN git clone --depth 1 --branch ${api_tag} https://github.com/KaotoIO/kaoto-backend.git 
WORKDIR /code/kaoto-backend
RUN rm api/src/main/resources/META-INF/resources/*
COPY --from=FRONTEND /app/kaoto-ui/dist/* api/src/main/resources/META-INF/resources/
RUN /code/mvnw install -Pnative -DskipTests

#Final image
FROM quay.io/quarkus/quarkus-micro-image:1.0

#Get curl
COPY --from=BACKEND /usr/bin/curl   /usr/bin/
COPY --from=BACKEND \
 /lib64/libcurl.so.4 /lib64/libssl.so.1.1 /lib64/libcrypto.so.1.1  \
 /lib64/libnghttp2.so.14 /lib64/libidn2.so.0 /lib64/libssh.so.4 \
 /lib64/libpsl.so.5 /lib64/libgssapi_krb5.so.2 /lib64/libkrb5.so.3 \
 /lib64/libk5crypto.so.3  /lib64/libcom_err.so.2 /lib64/libldap-2.4.so.2 \
 /lib64/liblber-2.4.so.2 /lib64/libbrotlidec.so.1 /lib64/libunistring.so.2 \
 /lib64/libkrb5support.so.0 /lib64/libkeyutils.so.1 /lib64/libsasl2.so.3 \
 /lib64/libbrotlicommon.so.1 /lib64/libcrypt.so.1 \
 /lib64/

# Get Kaoto
WORKDIR /work/
RUN chown 1001 /work \
    && chmod "g+rwX" /work \
    && chown 1001:root /work
COPY --chown=1001 --from=BACKEND /code/kaoto-backend/api/target/*-runner /work/application

EXPOSE 8081
USER 1001

HEALTHCHECK --interval=3s --start-period=1s CMD curl --fail http://localhost:8081/ || exit 1

CMD ["./application", "-Dquarkus.http.host=0.0.0.0", "-Djava.util.logging.manager=org.jboss.logmanager.LogManager", "-Dquarkus.kubernetes-client.trust-certs=true"]

