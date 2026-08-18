// Copyright (c) 2026, WSO2 LLC. (http://www.wso2.com).
//
// WSO2 LLC. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

// Only the values the seven calls cannot work without. Everything else the operations accept is
// either optional, or derived from an earlier response - see `automation.bal`.

# ERP Integrations base URL - `https://{fusionHost}/fscmRestApi/resources/{apiVersion}`.
configurable string erpServiceUrl = ?;

# Scheduler base URL - `https://{fusionHost}/ess/rest/scheduler/v1`.
configurable string schedulerServiceUrl = ?;

# Fusion integration user, and its password.
configurable string username = ?;
configurable string password = ?;

# Path to the FBDI zip to upload. Keep it small - the API carries it as base64 in the JSON body.
configurable string filePath = ?;

# Name the file is stored under in WebCenter Content.
configurable string fileName = "APInvoiceImport.zip";

# UCM document account, which is interface-specific - `fin$/payables$/import$` for Payables
# invoices, `scm$/item$/import$` for items. Used in uploadFileToUcm, importBulkData
configurable string documentAccount = "fin$/payables$/import$";

# `importBulkData` job: the ESS package path and job definition name, comma separated.
# This tells Oracle which job should process your data.
# For Supply Chain Planning, the documentation specifies:
# E.g /oracle/apps/ess/scm/advancedPlanning/collection/configuration/CSVController
configurable string jobName = ?;

# Positional, comma-separated parameters for the `importBulkData` job, `#NULL` for unused positions.
# This contains the values required by the Oracle job.
# E.g EX8,2,UOM.zip,#NULL,...
configurable string parameterList = ?;

# `submitEssJobRequest` job: the package path and the definition name, as separate fields.
# E.g oracle/apps/ess/scm/advancedPlanning/collection/configuration
configurable string jobPackageName = ?;

# E.g CSVController
configurable string jobDefName = ?;

# Positional, comma-separated parameters for `submitEssJobRequest`.
# This contains the job parameters.
configurable string essParameters = ?;

# Metadata object id of the job the Scheduler submits. Use a harmless one.
# The `jobDefinitionId` tells Oracle what job to run. The request ID tells you which particular execution of that job you are tracking
# Depending on the specific Oracle REST endpoint, you may see the job identified by `JobPackageName` + `JobDefName` instead of directly supplying a `jobDefinitionId`.
configurable string jobDefinitionId = ?;
