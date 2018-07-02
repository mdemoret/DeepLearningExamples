FROM pytorch/pytorch:0.4_cuda9_cudnn7

ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8

ADD . /workspace/gnmt/pytorch
RUN pip install -r /workspace/gnmt/pytorch/requirements.txt

WORKDIR /workspace/gnmt/pytorch
