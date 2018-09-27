#!/usr/bin/env bash
#
# Copyright 2018 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

PROJECT_ID=$1
GCS_BUCKET_NAME=$2
# Copying the scripts to the bucket
gsutil cp *.sh gs://$GCS_BUCKET_NAME/
# Execute deployment manager
gcloud deployment-manager deployments create source-mysql --template mysql-dm.jinja --project=${PROJECT_ID} --properties="GCS_BUCKET_NAME:${GCS_BUCKET_NAME}"
