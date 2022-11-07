IMG_NAME ?= kaotoio/kaoto-standalone

build:
	docker build --build-arg UI_TAG=${UI_TAG} --build-arg API_TAG=${API_TAG} -t ${IMG_NAME}:${IMG_VERSION} .

push:
	docker push ${IMG_NAME}:${IMG_VERSION}

build-and-push:
	${MAKE} build
	${MAKE} push

