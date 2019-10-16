#!/bin/bash
set -e
BASEDIR=$(dirname "$0")
PARCEL=${1:-CDH_PYTHON-0.0.1.p0}
PARCEL_NAME=${PARCEL%%-*}
PARCEL_VERSION=${PARCEL#*-}
CONDA_URI=https://repo.anaconda.com/archive/Anaconda3-2019.07-Linux-x86_64.sh
PARCEL_DIR=/app/cloudera/parcels
PYTHON2_VERSION=2.7
PYTHON3_VERSION=3.6
TARGET_OS=centos7
OS_VERSION=el7

CONDA_VERSION=$(echo $CONDA_URI | cut -d - -f 2)

PARCEL_VERSION="${PARCEL_VERSION}-anaconda3_${CONDA_VERSION}-py2_${PYTHON2_VERSION}-py3_${PYTHON3_VERSION}"

echo "Building ${PARCEL_NAME} parcel version ${PARCEL_VERSION} including python ${PYTHON2_VERSION} and ${PYTHON3_VERSION} \
using ${CONDA_URI} with PREFIX ${PARCEL_DIR}/${PARCEL_NAME}-${PARCEL_VERSION}"

echo "Delete ${PARCEL_NAME}-${PARCEL_VERSION} parcel directory"
rm -rf ${PARCEL_DIR}/${PARCEL_NAME}-${PARCEL_VERSION}

echo "Delete target directory"
rm -rf ${BASEDIR}/target

echo "Create target directory"
mkdir -p ${BASEDIR}/target

# RHEL/CentOS
IMAGE_NAME=$(echo ${PARCEL_NAME} | tr '[:upper:]' '[:lower:]')

echo "Creating parcel: ${PARCEL_NAME}-${PARCEL_VERSION}-${OS_VERSION}.parcel"

yum install -y bzip2

mkdir -p ${PARCEL_DIR}
CONDA_EXECUTABLE=$(basename ${CONDA_URI})
curl -O ${CONDA_URI}
sh ${CONDA_EXECUTABLE} -b -p ${PARCEL_DIR}/${PARCEL_NAME}-${PARCEL_VERSION}
rm -f ${CONDA_EXECUTABLE}
export PATH=${PARCEL_DIR}/${PARCEL_NAME}-${PARCEL_VERSION}/bin:$PATH
conda create -y -q -n python2 python=$PYTHON2_VERSION
conda create -y -q -n python3 python=$PYTHON3_VERSION

mkdir -p ${PARCEL_DIR}/${PARCEL_NAME}-${PARCEL_VERSION}/{lib,meta}

echo "Create ${PARCEL_NAME}-${PARCEL_VERSION}/meta/parcel.json"
cp ${BASEDIR}/source/meta/* ${PARCEL_DIR}/${PARCEL_NAME}-${PARCEL_VERSION}/meta/
sed -i \
-e "s/__OS_VERSION__/${OS_VERSION}/g" \
-e "s/__PARCEL_VERSION__/${PARCEL_VERSION}/g" \
-e "s/__PARCEL_NAME__/${PARCEL_NAME}/g" \
${PARCEL_DIR}/${PARCEL_NAME}-${PARCEL_VERSION}/meta/parcel.json

echo "Create ${PARCEL_NAME}-${PARCEL_VERSION}/meta/py_env.sh"
sed -i \
-e "s/__OS_VERSION__/${OS_VERSION}/g" \
-e "s/__PARCEL_VERSION__/${PARCEL_VERSION}/g" \
-e "s/__PARCEL_NAME__/${PARCEL_NAME}/g" \
${PARCEL_DIR}/${PARCEL_NAME}-${PARCEL_VERSION}/meta/py_env.sh

echo "Create ${PARCEL_NAME}-${PARCEL_VERSION}-${OS_VERSION}.parcel"
tar -C ${PARCEL_DIR} -czf ${PARCEL_NAME}-${PARCEL_VERSION}-${OS_VERSION}.parcel ${PARCEL_NAME}-${PARCEL_VERSION} --owner=root --group=root && \
rm -rf ${PARCEL_DIR}/${PARCEL_NAME}-${PARCEL_VERSION}

mv ${PARCEL_NAME}-${PARCEL_VERSION}-${OS_VERSION}.parcel ${BASEDIR}/target

echo "Create manifest.json"
python ${BASEDIR}/lib/make_manifest.py ${BASEDIR}/target

echo "Update index.html"
python ${BASEDIR}/lib/create_index.py ${BASEDIR}/target

echo "Validation"
java -jar lib/validator.jar -f ${BASEDIR}/target/${PARCEL_NAME}-${PARCEL_VERSION}-${OS_VERSION}.parcel

echo "Successfully created ${PARCEL_NAME}-${PARCEL_VERSION}-${OS_VERSION}.parcel"


