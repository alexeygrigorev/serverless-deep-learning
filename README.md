# Serverless Deep Learning

Presentation:

* https://www.slideshare.net/AlexeyGrigorev/serverless-deep-learning

## AWS Lambda limits

Imagine you want to use AWS Lambda for serving TenorFlow models

TensorFlow 2.2 is quite big

```
1,5G tensorflow
```
Even packing doesn't help:

```
573M build.zip
```

The limits for AWS Lambda is 50 mb packed / 250 mb unpacked - so it goes well above the limits



## TensorFlow Lite

Alternative: Use TF Lite

1. Compile it for the AWS Lambda environment
2. Convert your Keras model to TF-Lite format
3. Build a zip file with the lambda code
4. Test it
5. Deploy the code to AWS Lambda


### Compile TF-Lite

* Clone TF 
* Compile in inside docker using `amazonlinux` ([here](https://github.com/alexeygrigorev/serverless-deep-learning/blob/master/tflite-compile.dockerfile))
* Extract the compiled wheel from the image


Compile:
```bash
TF_LITE_BUILDER_IMAGE_NAME=tflite_amazonlinux
docker build -f tflite-compile.dockerfile -t ${TF_LITE_BUILDER_IMAGE_NAME} .
```

Extract the wheel:
```bash
docker run --rm \
    -v $(pwd)/tflite:/tflite/results \
    ${TF_LITE_BUILDER_IMAGE_NAME}
```

The result (for python 3.7) is already in the `tflite` folder: 

* [`tflite/tflite_runtime-2.2.0-cp37-cp37m-linux_x86_64.whl`](https://github.com/alexeygrigorev/serverless-deep-learning/blob/master/tflite/tflite_runtime-2.2.0-cp37-cp37m-linux_x86_64.whl)



Source:

* https://github.com/tpaul1611/python_tflite_for_amazonlinux


### Convert Keras to TF-Lite

* Save to `saved_model` format
* Load `saved_model` with TF-Lite converter
* Save it in TF-lite format


Saving the model:
```python
tf.saved_model.save(
    model, 
    output_folder,
)
```

Loading with TF-Lite converter and saving it:

```python
converter = tf.lite.TFLiteConverter.from_saved_model(output_folder)

tflite_model = converter.convert()

with tf.io.gfile.GFile('resnet50.tflite', 'wb') as f:
    f.write(tflite_model)
```

See the [keras_to_tflite.ipynb notebook](https://github.com/alexeygrigorev/serverless-deep-learning/blob/master/keras_to_tflite.ipynb) for the full example

Upload the model to S3 


### Building a Zip File 

* Build a zip file in docker
* Extract the file from the image

Building the zip file:
```bash
BUILDER_IMAGE_NAME=tflite_build_lambda
docker build -t ${BUILDER_IMAGE_NAME} -f build.dockerfile .
```

Extracting the file

```bash
docker run --rm \
    -v $(pwd):/app/results \
    ${BUILDER_IMAGE_NAME}
```

The result is only 20M:
```
20M build.zip
```

### Test it

* Unpack the zip file inside docker (use `amazonlinux`)
* Run the inference to make sure it works


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

* Request: `{'url': 'https://upload.wikimedia.org/wikipedia/commons/9/9a/Pug_600.jpg'}`
* Response: `{'pug': 0.99937063, 'Norwegian_elkhound': 0.0005375595, 'chow': 3.780921e-05}`



### AWS Lambda function

* Create a lambda function (e.g. "DeepLearningLambda")
* Upload the zip archive to S3
* Update the lambda function with AWS Cli

```bash
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

That's all! 
