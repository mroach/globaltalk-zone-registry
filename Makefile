DOCKER_REGISTRY = ghcr.io/mroach/globaltalk-zone-registry
TAG = $(DOCKER_REGISTRY):latest
REVISION = $(shell git rev-parse --short HEAD)

image:
	docker build \
		--pull \
		--tag $(TAG) \
		--label "org.opencontainers.image.url=https://github.com/mroach/globaltalk-zone-registry" \
		--label "org.opencontainers.image.revision=$(REVISION)" \
		--label "org.opencontainers.image.created=$(shell date --rfc-3339=seconds)" \
		--label "org.opencontainers.image.licenses=MIT" \
		--label "org.opencontainers.image.authors=git@c.mroach.com" \
		.

push:
	docker push $(TAG)
