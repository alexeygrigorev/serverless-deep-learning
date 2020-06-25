TF_LITE_BUILDER_IMAGE_NAME=tflite_amazonlinux
BUILDER_IMAGE_NAME=tflite_build_lambda
TEST_IMAGE_NAME=tflite_test_lambda

CURDIR=$(shell pwd)


build_image_tflite_compile:
	docker build -f tflite-compile.dockerfile -t ${TF_LITE_BUILDER_IMAGE_NAME} .

tflite_compile: build_image_tflite_compile
	docker run --rm \
		-v ${CURDIR}/tflite:/tflite/results \
		${TF_LITE_BUILDER_IMAGE_NAME}

.PHONY: build_image
build_image:
	docker build -t ${BUILDER_IMAGE_NAME} -f build.dockerfile .

build_file:
	docker run --rm \
		-v ${CURDIR}:/app/results \
		${BUILDER_IMAGE_NAME}

.PHONY: build
build: build_file


build_test: build
	docker build -t ${TEST_IMAGE_NAME} -f test.dockerfile .

test: build_test
	docker run --rm \
		-v ${CURDIR}/resnet50.tflite:/tmp/resnet50.tflite \
		${TEST_IMAGE_NAME}


.PHONY: update_lambda
update_lambda: test
	./upload.sh


  