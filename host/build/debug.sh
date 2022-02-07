#!/bin/sh

cmake -DCMAKE_BUILD_TYPE=DEBUG -DUHD_LOG_MIN_LEVEL=0 -DUHD_LOG_CONSOLE_LEVEL=0 ..
# && make -j32 && make install
