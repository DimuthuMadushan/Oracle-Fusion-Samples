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
//
// The run is split into three phases, each switched on its own. A phase that is off reads none of
// its own configuration, so only the keys the enabled phases need have to be filled in - which is
// why the job keys below carry empty defaults rather than being required.

// -------------------------------------------------------------------------------------------------
// Phase switches
// -------------------------------------------------------------------------------------------------

# Whether the `uploadFileToUcm` and `submitEssJobRequest` phase runs. It stages the archive in
# WebCenter Content and submits an ESS job over the document the upload returned.
configurable boolean enableUploadOperations = true;

# Whether the `importBulkData` and `getEssJobStatus` phase runs. It covers the same ground as the
# phase above in a single call, which is what Oracle recommends for FBDI imports.
configurable boolean enableImportOperations = false;

# Whether the `queryJobRequests`, `submitJobRequest` and `getJobRequest` phase runs. Off by default,
# because `submitJobRequest` starts a scheduled process on the instance instead of only reading from
# it - turn it on once `jobDefinitionId` names a job that is safe to run there.
configurable boolean enableSchedulerOperations = false;

// -------------------------------------------------------------------------------------------------
// Connection - read whichever phases are on
// -------------------------------------------------------------------------------------------------

# Both clients are created at startup, so both URLs are needed even when a phase that uses one is
# off.
#
# ERP Integrations base URL - `https://{fusionHost}/fscmRestApi/resources/{apiVersion}`.
configurable string erpServiceUrl = "https://*fusionHost*/fscmRestApi/resources/*apiVersion*";

# Scheduler base URL - `https://{fusionHost}/ess/rest/scheduler/v1`.
configurable string schedulerServiceUrl = "https://*fusionHost*/ess/rest/scheduler/v1";

# Fusion integration user, and its password.
configurable string username = ?;
configurable string password = ?;

// -------------------------------------------------------------------------------------------------
// The archive - read by the `enableUploadOperations` and `enableImportOperations` phases
// -------------------------------------------------------------------------------------------------

# Directory holding the FBDI CSV files to upload, or a single file. Packed into `zipFilePath` at
# the start of the run, and only read when one of the two upload phases is on. Keep it small - the
# API carries the archive as base64 in the JSON body.
configurable string dataDirPath = "./fbdi_data";

# Where the archive is written. Must be outside `dataDirPath`, because an archive cannot contain
# itself. Overwritten on every run.
configurable string zipFilePath = "./APInvoiceImport.zip";

# Name the file is stored under in WebCenter Content.
configurable string fileName = "APInvoiceImport.zip";

# UCM document account, which is interface-specific - `fin$/payables$/import$` for Payables
# invoices, `scm$/item$/import$` for items. Used in uploadFileToUcm, importBulkData
configurable string documentAccount = "fin$/payables$/import$";

// -------------------------------------------------------------------------------------------------
// `enableUploadOperations` phase
// -------------------------------------------------------------------------------------------------

# `submitEssJobRequest` job: the package path and the definition name, as separate fields.
# E.g oracle/apps/ess/scm/advancedPlanning/collection/configuration
configurable string jobPackageName = "";

# E.g CSVController
configurable string jobDefName = "";

# Positional, comma-separated parameters for `submitEssJobRequest`.
# This contains the job parameters.
# E.g: "#NULL,Vision Operations,#NULL,#NULL,#NULL,#NULL,#NULL,INVOICE GATEWAY"
configurable string essParameters = "";

// -------------------------------------------------------------------------------------------------
// `enableImportOperations` phase
// -------------------------------------------------------------------------------------------------

# `importBulkData` job: the ESS package path and job definition name, comma separated.
# This tells Oracle which job should process your data.
# For Supply Chain Planning, the documentation specifies:
# E.g /oracle/apps/ess/scm/advancedPlanning/collection/configuration/CSVController
configurable string jobName = "";

# Positional, comma-separated parameters for the `importBulkData` job, `#NULL` for unused positions.
# This contains the values required by the Oracle job.
# E.g EX8,2,UOM.zip,#NULL,...
configurable string parameterList = "";

// -------------------------------------------------------------------------------------------------
// `enableSchedulerOperations` phase
// -------------------------------------------------------------------------------------------------

# Metadata object id of the job the Scheduler submits. Use a harmless one.
# The `jobDefinitionId` tells Oracle what job to run. The request ID tells you which particular execution of that job you are tracking
# Depending on the specific Oracle REST endpoint, you may see the job identified by `JobPackageName` + `JobDefName` instead of directly supplying a `jobDefinitionId`.
configurable string jobDefinitionId = "";
