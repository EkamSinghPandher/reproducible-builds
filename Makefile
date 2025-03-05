BUILD_IMAGE_NAME := go-hello-world-image
TEMP_CONTAINER_NAME := go-hello-world-container

.PHONY: all
all: build

.PHONY: build-image
build-image:
	sudo docker build -t $(BUILD_IMAGE_NAME) -f Containerfile .

.PHONY: build
build: build-image copy-artifacts create-digests

.PHONY: temp-container
temp-container:
	echo "Creating container $(TEMP_CONTAINER_NAME) from image $(BUILD_IMAGE_NAME)"
	docker create --name $(TEMP_CONTAINER_NAME) $(BUILD_IMAGE_NAME) tail -f /dev/null

.PHONY: copy-artifacts
copy-artifacts: clean-temp-container temp-container 
	mkdir -p bin
	sudo docker cp $(TEMP_CONTAINER_NAME):$(WORKDIR)/hello bin

.PHONY: clean-image
clean-image:
	docker rmi -f $(BUILD_IMAGE_NAME) || true

.PHONY: clean-temp-container
clean-temp-container:
	docker rm -f $(TEMP_CONTAINER_NAME) || true

.PHONY: clean-all
clean-all: clean-image clean-temp-container

.PHONY: verify-software
verify-software:
	./scripts/check-digests.sh
	./scripts/check-signatures.sh

.PHONY: create-digests
create-digests:
	./scripts/create-digests.sh

.PHONY: sign-digests
sign-digests:
	./scripts/sign-digests.sh $(arg)

.PHONY: verify-build
verify-build:
	@echo "Verifying build reproducibility..."
	@mkdir -p tmp
	@$(MAKE) build
	@cp ../bin/hello tmp/hello-1
	@$(MAKE) clean-all
	@$(MAKE) build
	@cp ../bin/hello tmp/hello-2
	@echo "Comparing digests..."
	@sha256sum tmp/hello-1 tmp/hello-2
	@diff <(sha256sum tmp/hello-1) <(sha256sum tmp/hello-2) && echo "Builds are identical!" || echo "Builds differ!"