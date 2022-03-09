#
# Copyright 2018 Ettus Research, a National Instruments Company
# Copyright 2020 Ettus Research, a National Instruments Brand
#
# SPDX-License-Identifier: GPL-3.0-or-later
#
# - Find CUDA
# Find the CUDA includes and client library
# This module defines
#  CUDA_INCLUDE_DIRS
#  CUDA_LIBRARIES
#  CUDA_DRIVER_LIBRARY

############################################ CUDA ###################################################

#FIND_PACKAGE(CUDA 10 REQUIRED)
#FIND_LIBRARY(CUDA_DRIVER_LIBRARY
#             NAMES cuda_driver cuda
#             HINTS ${CUDA_TOOLKIT_ROOT_DIR}
#                   ENV CUDA_PATH
#             PATH_SUFFIXES nvidia/current lib64 lib/x64 lib)
#IF (NOT CUDA_DRIVER_LIBRARY)
#    FIND_LIBRARY(CUDA_DRIVER_LIBRARY
#                 NAMES cuda_driver cuda
#                 HINTS ${CUDA_TOOLKIT_ROOT_DIR}
#                       ENV CUDA_PATH
#                 PATH_SUFFIXES lib64/stubs lib/x64/stubs lib/stubs stubs compat)
#ENDIF ()
#MARK_AS_ADVANCED(CUDA_DRIVER_LIBRARY)

##################################################################################################
