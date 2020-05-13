FROM maven:3.5.3-jdk-8-alpine as build

COPY bookkeeper-benchmark/ /bookkeeper/src/bookkeeper-benchmark/
COPY bookkeeper-common/ /bookkeeper/src/bookkeeper-common/
COPY bookkeeper-common-allocator/ /bookkeeper/src/bookkeeper-common-allocator/
COPY bookkeeper-dist/ /bookkeeper/src/bookkeeper-dist/
COPY bookkeeper-http/ /bookkeeper/src/bookkeeper-http/
COPY bookkeeper-proto/ /bookkeeper/src/bookkeeper-proto
COPY bookkeeper-server/ /bookkeeper/src/bookkeeper-server/
COPY bookkeeper-stats/ /bookkeeper/src/bookkeeper-stats/
COPY bookkeeper-stats-providers/ /bookkeeper/src/bookkeeper-stats-providers/
COPY buildtools/ /bookkeeper/src/buildtools/
COPY circe-checksum/ /bookkeeper/src/circe-checksum/
COPY conf/ /bookkeeper/src/conf/
COPY cpu-affinity/ /bookkeeper/src/cpu-affinity/
COPY deploy/ /bookkeeper/src/deploy/
COPY dev/ /bookkeeper/src/dev/
COPY docker/ /bookkeeper/src/docker/
COPY metadata-drivers/ /bookkeeper/src/metadata-drivers/
COPY microbenchmarks/ /bookkeeper/src/microbenchmarks/
COPY shaded/ /bookkeeper/src/shaded/
COPY site/ /bookkeeper/src/site/
COPY stats/ /bookkeeper/src/stats/
COPY stream/ /bookkeeper/src/stream/
COPY tests/ /bookkeeper/src/tests/
COPY tools/ /bookkeeper/src/tools/
COPY pom.xml /bookkeeper/src/pom.xml
COPY LICENSE /bookkeeper/src/LICENSE
COPY NOTICE /bookkeeper/src/NOTICE
COPY README.md /bookkeeper/src/README.md

WORKDIR /bookkeeper/src
RUN mvn dependency:go-offline
#RUN mvn clean install --batch-mode -pl '!tests' -DskipTests=true
#RUN mvn -pl bookkeeper clean package -DskipTests
RUN mvn -pl :bookkeeper-dist-server clean package -DskipTests

# The image is based on the master branch
FROM apache/bookkeeper:latest

ARG BK_VERSION=4.11.0
ARG DISTRO_NAME=bookkeeper-server-${BK_VERSION}-SNAPSHOT

COPY --from=build /bookkeeper/src/bookkeeper-dist/server/target/${DISTRO_NAME}-bin.tar.gz /opt

RUN set -x \
    && yum install bash \
    && rm -rf /opt/bookkeeper \
    && cd /opt \
    && tar -xzf "$DISTRO_NAME-bin.tar.gz" \
    && mv /opt/${DISTRO_NAME}/ /opt/bookkeeper/
    #&& rm -rf "$DISTRO_NAME-bin.tar.gz"

COPY --from=build /bookkeeper/src/docker/scripts/ /opt/bookkeeper/scripts/

RUN chmod +x -R /opt/bookkeeper/scripts/

WORKDIR /opt/bookkeeper

ENTRYPOINT [ "/bin/bash", "/opt/bookkeeper/scripts/entrypoint.sh" ]
CMD ["bookie"]

HEALTHCHECK --interval=10s --timeout=60s CMD /bin/bash /opt/bookkeeper/scripts/healthcheck.sh
