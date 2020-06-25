FROM amazonlinux

WORKDIR /tflite

RUN yum groupinstall -y development
RUN yum install -y python3.7
RUN yum install -y python3-devel
RUN pip3 install numpy wheel
RUN git clone --branch r2.2 https://github.com/tensorflow/tensorflow.git
RUN sh ./tensorflow/tensorflow/lite/tools/pip_package/build_pip_package.sh


ENTRYPOINT [ \
    "cp", \
    "./tensorflow/tensorflow/lite/tools/pip_package/gen/tflite_pip/python3/dist/tflite_runtime-2.2.0-cp37-cp37m-linux_x86_64.whl",\
    "./results/" ]