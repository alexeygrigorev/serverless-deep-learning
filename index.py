import os
import os.path

import re
import sys
import time
import json

from io import BytesIO
from urllib import request

import boto3
import botocore

import numpy as np
from PIL import Image

import tflite_runtime.interpreter as tflite


s3_client = boto3.client('s3')


model_bucket = 'data-science-temporary'
model_key = 'tf-models/resnet50.tflite'

model_local_path = '/tmp/resnet50.tflite'


with open('imagenet_classes.json') as f_in:
    imagenet_classes = json.load(f_in)


def download_from_s3(bucket, key, where):
    t0 = time.perf_counter()
    s3_client.download_file(bucket, key, where)
    t1 = time.perf_counter()
    print('downloading model took %0.3f sec' % (t1 - t0))


def download_model():
    if os.path.exists(model_local_path):
        print('using existing model from %s' % model_local_path)
        return

    download_from_s3(model_bucket, model_key, model_local_path)


def download_image(url):
    with request.urlopen(url) as resp:
        buffer = resp.read()
    stream = BytesIO(buffer)
    img = Image.open(stream)
    return img


def preprocess_image(img, target_size=(224, 224)):
    # color_mode='rgb',
    # target_size=None,
    # interpolation='nearest',
    if img.mode != 'RGB':
        img = img.convert('RGB')
    img = img.resize(target_size, Image.NEAREST)
    return img


def own_preprocess_input(x):
    # caffe preprocessing

    # 'RGB'->'BGR'
    x = x[..., ::-1]

    mean = [103.939, 116.779, 123.68]

    x[..., 0] -= mean[0]
    x[..., 1] -= mean[1]
    x[..., 2] -= mean[2]

    return x


download_model()

interpreter = tflite.Interpreter(model_path=model_local_path)
interpreter.allocate_tensors()


def run_inference(x):
    input_details = interpreter.get_input_details()
    input_index = input_details[0]['index']
    output_details = interpreter.get_output_details()
    output_index = output_details[0]['index']

    interpreter.set_tensor(input_index, x)
    interpreter.invoke()

    preds = interpreter.get_tensor(output_index)
    return preds


def predict(img):
    img = preprocess_image(img)
    x = np.array(img).astype('float32')

    x = np.expand_dims(x, axis=0)
    x = own_preprocess_input(x)

    return run_inference(x)


def decode_predictions(preds, top=3):
    results = []

    for pred in preds:
        top_indices = pred.argsort()[-top:][::-1]

        result = {imagenet_classes[i]: float(pred[i]) for i in top_indices}
        results.append(result)

    return results


def handler(event, context):
    # print(event)

    img = download_image(event['url'])
    preds = predict(img)
    result = decode_predictions(preds)[0]

    return result
