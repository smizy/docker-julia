
.PHONY: all
all: runtime

.PHONY: clean
clean:
	docker rmi -f smizy/julia:${TAG} || :

.PHONY: runtime
runtime:
	docker build \
		--build-arg BUILD_DATE=`date -u +"%Y-%m-%dT%H:%M:%SZ"` \
		--build-arg VCS_REF=${VCS_REF} \
		--build-arg VERSION=${VERSION} \
		--rm -t smizy/julia:${TAG} .
	docker images | grep julia

.PHONY: test
test:
	bats test/test_*.bats