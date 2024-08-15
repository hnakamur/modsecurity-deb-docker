PKG_VERSION=3.0.12
PKG_REL_PREFIX=2hn1
ifdef NO_CACHE
DOCKER_NO_CACHE=--no-cache
endif

LOGUNLIMITED_BUILDER=logunlimited
LUAJIT_DEB_VERSION=2.1.20240314-1hn1

# Ubuntu 24.04
deb-ubuntu2404: build-ubuntu2404
	docker run --rm -v ./modsecurity-${PKG_VERSION}-${PKG_REL_PREFIX}ubuntu24.04:/dist modsecurity-ubuntu2404 bash -c \
	"cp /src/{lib,}modsecurity*${PKG_VERSION}* /dist/"
	tar zcf modsecurity-${PKG_VERSION}-${PKG_REL_PREFIX}ubuntu24.04.tar.gz ./modsecurity-${PKG_VERSION}-${PKG_REL_PREFIX}ubuntu24.04/

build-ubuntu2404: buildkit-logunlimited
	sudo mkdir -p modsecurity-${PKG_VERSION}-${PKG_REL_PREFIX}ubuntu24.04
	(set -x; \
	git submodule foreach --recursive git remote -v; \
	git submodule status --recursive; \
	docker buildx build --progress plain --builder ${LOGUNLIMITED_BUILDER} --load \
		${DOCKER_NO_CACHE} \
		--build-arg OS_TYPE=ubuntu --build-arg OS_VERSION=24.04 \
		--build-arg PKG_REL_DISTRIB=ubuntu24.04 \
		--build-arg PKG_VERSION=${PKG_VERSION} \
		--build-arg LUAJIT_DEB_VERSION=${LUAJIT_DEB_VERSION} \
		--build-arg LUAJIT_DEB_OS_ID=ubuntu24.04 \
		-t modsecurity-ubuntu2404 . \
	) 2>&1 | sudo tee modsecurity-${PKG_VERSION}-${PKG_REL_PREFIX}ubuntu24.04/modsecurity_${PKG_VERSION}-${PKG_REL_PREFIX}ubuntu24.04.build.log
	sudo xz --force modsecurity-${PKG_VERSION}-${PKG_REL_PREFIX}ubuntu24.04/modsecurity_${PKG_VERSION}-${PKG_REL_PREFIX}ubuntu24.04.build.log

run-ubuntu2404:
	docker run --rm -it modsecurity-ubuntu2404 bash

# Ubuntu 22.04
deb-ubuntu2204: build-ubuntu2204
	docker run --rm -v ./modsecurity-${PKG_VERSION}-${PKG_REL_PREFIX}ubuntu22.04:/dist modsecurity-ubuntu2204 bash -c \
	"cp /src/{lib,}modsecurity*${PKG_VERSION}* /dist/"
	tar zcf modsecurity-${PKG_VERSION}-${PKG_REL_PREFIX}ubuntu22.04.tar.gz ./modsecurity-${PKG_VERSION}-${PKG_REL_PREFIX}ubuntu22.04/

build-ubuntu2204: buildkit-logunlimited
	sudo mkdir -p modsecurity-${PKG_VERSION}-${PKG_REL_PREFIX}ubuntu22.04
	(set -x; \
	git submodule foreach --recursive git remote -v; \
	git submodule status --recursive; \
	docker buildx build --progress plain --builder ${LOGUNLIMITED_BUILDER} --load \
		${DOCKER_NO_CACHE} \
		--build-arg OS_TYPE=ubuntu --build-arg OS_VERSION=22.04 \
		--build-arg PKG_REL_DISTRIB=ubuntu22.04 \
		--build-arg PKG_VERSION=${PKG_VERSION} \
		--build-arg LUAJIT_DEB_VERSION=${LUAJIT_DEB_VERSION} \
		--build-arg LUAJIT_DEB_OS_ID=ubuntu22.04 \
		-t modsecurity-ubuntu2204 . \
	) 2>&1 | sudo tee modsecurity-${PKG_VERSION}-${PKG_REL_PREFIX}ubuntu22.04/modsecurity_${PKG_VERSION}-${PKG_REL_PREFIX}ubuntu22.04.build.log
	sudo xz --force modsecurity-${PKG_VERSION}-${PKG_REL_PREFIX}ubuntu22.04/modsecurity_${PKG_VERSION}-${PKG_REL_PREFIX}ubuntu22.04.build.log

run-ubuntu2204:
	docker run --rm -it modsecurity-ubuntu2204 bash

# Debian 12
deb-debian12: build-debian12
	docker run --rm -v ./modsecurity-${PKG_VERSION}-${PKG_REL_PREFIX}debian12:/dist modsecurity-debian12 bash -c \
	"cp /src/{lib,}modsecurity*${PKG_VERSION}* /dist/"
	tar zcf modsecurity-${PKG_VERSION}-${PKG_REL_PREFIX}debian12.tar.gz ./modsecurity-${PKG_VERSION}-${PKG_REL_PREFIX}debian12/

build-debian12: buildkit-logunlimited
	sudo mkdir -p modsecurity-${PKG_VERSION}-${PKG_REL_PREFIX}debian12
	(set -x; \
	git submodule foreach --recursive git remote -v; \
	git submodule status --recursive; \
	docker buildx build --progress plain --builder ${LOGUNLIMITED_BUILDER} --load \
		${DOCKER_NO_CACHE} \
		--build-arg OS_TYPE=debian --build-arg OS_VERSION=12 \
		--build-arg PKG_REL_DISTRIB=debian12 \
		--build-arg PKG_VERSION=${PKG_VERSION} \
		--build-arg LUAJIT_DEB_VERSION=${LUAJIT_DEB_VERSION} \
		--build-arg LUAJIT_DEB_OS_ID=debian12 \
		-t modsecurity-debian12 . \
	) 2>&1 | sudo tee modsecurity-${PKG_VERSION}-${PKG_REL_PREFIX}debian12/modsecurity_${PKG_VERSION}-${PKG_REL_PREFIX}debian12.build.log
	sudo xz --force modsecurity-${PKG_VERSION}-${PKG_REL_PREFIX}debian12/modsecurity_${PKG_VERSION}-${PKG_REL_PREFIX}debian12.build.log

run-debian12:
	docker run --rm -it modsecurity-debian12 bash

buildkit-logunlimited:
	if ! docker buildx inspect logunlimited 2>/dev/null; then \
		docker buildx create --bootstrap --name ${LOGUNLIMITED_BUILDER} \
			--driver-opt env.BUILDKIT_STEP_LOG_MAX_SIZE=-1 \
			--driver-opt env.BUILDKIT_STEP_LOG_MAX_SPEED=-1; \
	fi

exec:
	docker exec -it $$(docker ps -q) bash

.PHONY: deb-debian12 run-debian12 build-debian12 deb-ubuntu2204 run-ubuntu2204 build-ubuntu2204 buildkit-logunlimited exec
