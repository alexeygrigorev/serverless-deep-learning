FROM amazonlinux

WORKDIR /tflite

RUN yum groupinstall -y development
RUN yum install -y python3.7
RUN yum install -y python3-devel

RUN pip3 install wheel

WORKDIR /app

COPY tflite/tflite_runtime-2.2.0-cp37-cp37m-linux_x86_64.whl tflite_runtime-2.2.0-cp37-cp37m-linux_x86_64.whl

RUN pip3 install \
    numpy==1.16.5 \
    Pillow==6.2.1 \ 
    tflite_runtime-2.2.0-cp37-cp37m-linux_x86_64.whl \
    -t build

WORKDIR /app/build

RUN (find . -name "tests" | xargs -n1 rm -rf) && \
    (find . -name \*.pyc | xargs -n1 rm -rf) && \
    (find . -name "__pycache__" | xargs -n1 rm -rf) && \
    (find . -name "*.dist-info" | xargs -n1 rm -rf)

COPY imagenet_classes.json imagenet_classes.json
COPY index.py index.py

RUN zip -r ../build.zip * > /dev/null

WORKDIR /app

ENTRYPOINT [ "cp", "build.zip", "results/build.zip" ]
