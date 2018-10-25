# This Dockerfile will install flow123d into a flow123d/install image

FROM flow123d/install-geomop

ARG flow_version
ARG flow_install_location=/opt/flow123d
ARG cmake_package_name=Flow123d-${version}-Linux.tar.gz

ARG git_hash
ARG build_date

# Build-time metadata as defined at http://label-schema.org
LABEL org.label-schema.build-date="$build_date" \
      org.label-schema.name="Flow123d" \
      org.label-schema.description="Transport Processes in Fractured Media" \
      org.label-schema.url="http://flow123d.github.io/" \
      org.label-schema.vcs-ref="$git_hash" \
      org.label-schema.vcs-url="https://github.com/flow123d/flow123d" \
      org.label-schema.vendor="Technical University of Liberec" \
      org.label-schema.version="$flow_version" \
      org.label-schema.schema-version="1.0"

COPY ${cmake_package_name} /tmp/${cmake_package_name}

RUN mkdir -p ${flow_install_location} \
 && tar -xzf /tmp/${cmake_package_name} \
    -C ${flow_install_location} \
    --strip-components=1 \
 && rm -rf /tmp/${cmake_package_name} \
 && rm -rf ${flow_install_location}/tests \
 && echo "${cmake_package_name} successfully inserted into image"

# update PATH 
ENV PATH="/opt/flow123d/bin:${PATH}"

# save the image version
RUN echo $flow_version > /.dockerversion
