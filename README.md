```
$ du -sh * | grep tensorflow
1,5G	tensorflow
972K	tensorflow-2.2.0.dist-info
4,1M	tensorflow_estimator
44K	tensorflow_estimator-2.2.0.dist-info
```

```
573M Jun 23 22:55 build.zip
```


```
ZIP_FILE="build.zip"
S3_BUCKET="data-science-temporary"
S3_KEY="lambdas/resnet50.zip"
FUNCTION_NAME="DeepLearningLambda"

aws s3 cp "${ZIP_FILE}" "s3://${S3_BUCKET}/${S3_KEY}"


aws lambda update-function-code \
    --function-name ${FUNCTION_NAME} \
    --s3-bucket ${S3_BUCKET} \
    --s3-key ${S3_KEY}
```


```
1,4G	tensorflow
```


https://stackoverflow.com/questions/59570081/how-to-use-tensorflow-lite-on-aws-lambda
https://github.com/tpaul1611/python_tflite_for_amazonlinux


```
TF_LITE_BUILDER_IMAGE_NAME=tflite_amazonlinux
docker build -f tflite-compile.dockerfile -t ${TF_LITE_BUILDER_IMAGE_NAME} .
```

```
docker run --rm \
    -v $(pwd)/tflite:/tflite/results \
    ${TF_LITE_BUILDER_IMAGE_NAME}
```

Result: `tflite/tflite_runtime-2.2.0-cp37-cp37m-linux_x86_64.whl`


Build the zip file 

```
BUILDER_IMAGE_NAME=tflite_build_lambda
docker build -t ${BUILDER_IMAGE_NAME} -f build.dockerfile .
```

Copy it

```
docker run --rm \
    -v $(pwd):/app/results \
    ${BUILDER_IMAGE_NAME}
```

```
22M Jun 25 16:23 build.zip
```

```
20M Jun 25 17:05 build.zip
```

Testing!


Build the test container
```
TEST_IMAGE_NAME=tflite_test_lambda
docker build -t ${TEST_IMAGE_NAME} -f test.dockerfile .
```

Run the test

```
docker run --rm \
    -v $(pwd)/resnet50.tflite:/tmp/resnet50.tflite \
    ${TEST_IMAGE_NAME}

```


{'url': 'https://upload.wikimedia.org/wikipedia/commons/9/9a/Pug_600.jpg'}
{'pug': 0.99937063, 'Norwegian_elkhound': 0.0005375595, 'chow': 3.780921e-05}
