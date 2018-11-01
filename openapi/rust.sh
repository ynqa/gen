#!/bin/bash

# Copyright 2017 The Kubernetes Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -o errexit
set -o nounset
set -o pipefail

ARGC=$#

if [ $# -ne 2 ]; then
    echo "Usage:"
    echo "  $(basename ${0}) OUTPUT_DIR SETTING_FILE_PATH"
    echo "    Setting file should define KUBERNETES_BRANCH, CLIENT_VERSION, and PACKAGE_NAME"
    echo "    Setting file can define an optional USERNAME if you're working on a fork"
    echo "    Setting file can define an optional REPOSITORY if you're working on a ecosystem project"
    exit 1
fi


OUTPUT_DIR=$1
SETTING_FILE=$2
mkdir -p "${OUTPUT_DIR}"

SCRIPT_ROOT=$(dirname "${BASH_SOURCE}")
pushd "${SCRIPT_ROOT}" > /dev/null
SCRIPT_ROOT=`pwd`
popd > /dev/null

pushd "${OUTPUT_DIR}" > /dev/null
OUTPUT_DIR=`pwd`
popd > /dev/null

source "${SCRIPT_ROOT}/client-generator.sh"
source "${SETTING_FILE}"

SWAGGER_CODEGEN_COMMIT="${SWAGGER_CODEGEN_COMMIT:-v2.3.1}"; \
CLIENT_LANGUAGE=rust; \
CLEANUP_DIRS=(docs src); \
kubeclient::generator::generate_client "${OUTPUT_DIR}"

find "${OUTPUT_DIR}/src/" -type f -name \*.rs -exec sed -i 's/::models::Value/::serde_json::Value/g' {} +
find "${OUTPUT_DIR}/src/" -type f -name \*.rs -exec sed -i 's/ Value/ ::serde_json::Value/g' {} +
find "${OUTPUT_DIR}/src/" -type f -name \*.rs -exec sed -i 's/<Value/<::serde_json::Value/g' {} +
find "${OUTPUT_DIR}/src/" -type f -name \*.rs -exec sed -i 's/let query = ::url::form_urlencoded::Serializer::new(String::new())/let query = ::url::form_urlencoded::Serializer::new("?".to_string())/g' {} +
sed -i 's/not: Option<::models::V1beta1JsonSchemaProps>/not: Option<Box<::models::V1beta1JsonSchemaProps>>/g' "${OUTPUT_DIR}/src/models/v1beta1_json_schema_props.rs"
sed -i 's/not: ::models::V1beta1JsonSchemaProps/not: Box<::models::V1beta1JsonSchemaProps>/g' "${OUTPUT_DIR}/src/models/v1beta1_json_schema_props.rs"
sed -i 's/pub fn not(\&self) -> Option<\&::models::V1beta1JsonSchemaProps>/pub fn not(\&self) -> Option<\&Box<::models::V1beta1JsonSchemaProps>>/g' "${OUTPUT_DIR}/src/models/v1beta1_json_schema_props.rs"

echo "---Done."
