#!/bin/bash

# Set library paths
export LD_LIBRARY_PATH=/usr/local/cuda/targets/x86_64-linux/lib:/opt/workspace/cpp_project/thirdparty/mmdeploy/mmdeploy-1.1.0-linux-x86_64-cxx11abi-cuda11.3/lib:/opt/workspace/cpp_project/thirdparty/mmdeploy/mmdeploy-1.1.0-linux-x86_64-cxx11abi-cuda11.3/thirdparty/tensorrt/lib

# Define paths
IMAGE_PATH="assets/full-1.bmp"
DET_MODEL_PATH="/opt/workspace/mmdeploy/work_dirs/rtmdet-tiny-ins-fullsize_single_cat_20230511/"
CLS_MODEL_PATH="/opt/workspace/mmdeploy/work_dirs/mmpretrain_repvgg_cls_tensor_20240913"

# Run the native app
./build/bin/native_app "$IMAGE_PATH" "$DET_MODEL_PATH" "$CLS_MODEL_PATH"
