# This makefile will create docker images from a running container containing
# Flow123d (assuming the project is already compiled)

container_name          ?= contrelease
flow_install_location   ?= /opt/flow123d
flow_repo_location      ?= /opt/flow123d/flow123d


destination  ?= $(shell pwd)/publish
flow_version ?= $(strip $(shell docker exec $(container_name) cat $(flow_repo_location)/version ))
git_hash     ?= $(strip $(shell docker exec $(container_name) sh -c "cd $(flow_repo_location) && git rev-parse --short HEAD"))
git_branch   ?= $(strip $(shell docker exec $(container_name) sh -c "cd $(flow_repo_location) && git rev-parse --abbrev-ref HEAD"))

# default user
uid 				 ?= $(shell id -u)
gid 				 ?= $(shell id -u)

# name of the archives from CMake CPack tool
cmake_package_name=Flow123d-$(flow_version)-Linux.tar.gz

# final archive names
base_name=flow123d_$(flow_version)
docker_arch_name=$(base_name)_docker_image.tar.gz
docker_geomop_arch_name=$(base_name)_docker_geomop_image.tar.gz
lin_arch_name=$(base_name)_linux_install.tar.gz
win_arch_name=$(base_name)_windows_install.zip
win_geomop_arch_name=$(base_name)_windows_geomop_install.zip

# current date in two forms
current_date=$(shell date +"%d-%m-%Y %T")
build_date=$(shell date -u +"%Y-%m-%dT%H:%M:%SZ")

# path to the generated pdf
pdf_location=doc/reference_manual/flow123d_doc.pdf
ist_location=doc/reference_manual/input_reference.json

dexec=docker exec $(container_name)
dcp=docker cp $(container_name)

help:
	@echo "usage: "
	@echo "  all           packs entire flow"
	@echo "  help          prints this message"
	@echo "  info          prints package configuration"
	@echo "  push-to-hub   pushes docker image flow123d/$(flow_version) to the docker hub"


#$(destination)/$(win_arch_name) $(destination)/$(lin_arch_name)
all: info linux windows
	ls -la $(destination)


# human readable shortcut
linux: $(destination)/$(lin_arch_name)

# human readable shortcut
windows: $(destination)/$(win_arch_name)


# print package info
info:
	@echo "current configuration"
	@echo "  flow_version: $(flow_version)"
	@echo "  destination:  $(destination)"
	@echo "  git_hash:     $(git_hash)"
	@echo "  git_branch:   $(git_branch)"


# removes unwanted files before publishing to the flow.nti.tul.cz
remove-unwanted:
	rm -rf $(destination)/$(docker_arch_name)
	rm -rf $(destination)/tests
	rm -rf $(destination)/doc
	rm -rf $(destination)/config
	rm -rf $(destination)/bin
	rm -rf $(destination)/win
	rm -rf $(destination)/nsis
	rm -rf $(destination)/install.nsi
	@echo "Following files will be included in package: "
	ls -la $(destination)


# create docker image for windows users
$(destination)/$(win_arch_name): $(destination)/$(docker_arch_name)
	cp -r project/src/windows/* $(destination)/
	echo "$(flow_version)" > $(destination)/version

	docker run -it --rm -u $(uid):$(gid) -v $(destination):/nsis-project hp41/nsis /nsis-project/install.nsi
	echo "{\"build\": \"$(current_date)\", \"hash\": \"$(git_hash)\"}" > $(destination)/flow123d_$(flow_version)_win_install.json


# create docker image for linux users
$(destination)/$(lin_arch_name): $(destination)/$(docker_arch_name)
	mkdir -p install-linux
	cd install-linux && cmake \
		-DFLOW_VERSION="$(flow_version)" \
		-DFLOW123D_ROOT="$(flow_repo_location)" \
		-DIMAGE_TAG="flow123d/$(flow_version)" \
		-DIMAGE_NAME="$(docker_arch_name)" \
		-DDEST="$(destination)" \
		../project

	make -C install-linux package
	mv      install-linux/$(base_name).tar.gz $(destination)/$(lin_arch_name)
	echo "{\"build\": \"$(current_date)\", \"hash\": \"$(git_hash)\"}" > $(destination)/$(lin_arch_name:.tar.gz=.json)


# create a docker image using docker export containing installed flow123d
# from docker image flow123d/install
$(destination)/$(docker_arch_name): $(destination)/$(cmake_package_name)
	-@docker rmi -f flow123d/$(flow_version)
	cp $(destination)/$(cmake_package_name) project/src/docker/create/default/$(cmake_package_name)
	docker build \
         --build-arg flow_version=$(flow_version) \
         --build-arg flow_install_location=$(flow_install_location) \
         --build-arg cmake_package_name=$(cmake_package_name) \
         --build-arg git_hash=$(git_hash) \
         --build-arg build_date=$(build_date) \
         --tag flow123d/$(flow_version) \
         project/src/docker/create/default
	docker save flow123d/$(flow_version) > $(destination)/$(docker_arch_name)
	rm -rf project/src/docker/create/default/$(cmake_package_name)

# create package from flow123d project
$(destination)/$(cmake_package_name): $(destination)/tests $(destination)/flow123d_$(flow_version)_doc.pdf
	$(dexec) make -C $(flow_repo_location) package
	$(dcp):$(flow_repo_location)/build_tree/$(cmake_package_name) $(destination)/$(cmake_package_name)

# copy tests outside
$(destination)/tests:
	# create destination folders
	mkdir -p $(destination)/tests
	# clean and copy tests folder
	$(dexec) make -C $(flow_repo_location) clean-tests
	$(dcp):$(flow_repo_location)/tests/. $(destination)/tests

	# delete runtest because we will have to create other runtest for docker
	rm -rf $(destination)/tests/runtest


# call ref doc if pdf was not already created
$(destination)/flow123d_$(flow_version)_doc.pdf:
	$(dexec) make -C $(flow_repo_location) all                          # compile just in case
	$(dexec) make -C $(flow_repo_location) FORCE_DOC_UPDATE=1 ref-doc   # generate latex doc
	$(dexec) make -C $(flow_repo_location) html-doc                     # generate html doc
	$(dexec) make -C $(flow_repo_location) doxy-doc                     # generate source doc

	mkdir -p $(destination)/htmldoc
	mkdir -p $(destination)/doxygen
	mkdir -p $(destination)/config/docker/
	mkdir -p $(destination)/bin/

	$(dcp):$(flow_repo_location)/build_tree/$(pdf_location)             $(destination)/flow123d_$(flow_version)_doc.pdf
	$(dcp):$(flow_repo_location)/build_tree/htmldoc/html/src/.          $(destination)/htmldoc
	$(dcp):$(flow_repo_location)/build_tree/doc/online-doc/flow123d/.   $(destination)/doxygen
	$(dcp):$(flow_repo_location)/$(ist_location)                        $(destination)/input_reference.json
	$(dcp):$(flow_repo_location)/bin/fterm                              $(destination)/bin/fterm


# will push the images to the hub
# you must be logged in already in order to push the images to docker hub
push-to-hub:
	-docker push flow123d/$(flow_version)
