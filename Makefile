IMG_VERSION ?= nightly
UI_TAG ?= main
API_TAG ?= main

IMG_NAME ?= kaotoio/kaoto-standalone

build:
	docker build --build-arg ui_tag=${UI_TAG} --build-arg api_tag=${API_TAG} -t ${IMG_NAME}:${IMG_VERSION} .

push:
	docker push ${IMG_NAME}:${IMG_VERSION}

build-and-push:
	${MAKE} build
	${MAKE} push