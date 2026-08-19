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

# `submitEssJobRequest` job: the package path and the definition name, as separate fields.
# E.g oracle/apps/ess/scm/advancedPlanning/collection/configuration
configurable string jobPackageName = "";

# E.g CSVController
configurable string jobDefName = "";

# Positional, comma-separated parameters for `submitEssJobRequest`.
# This contains the job parameters.
# E.g: "#NULL,Vision Operations,#NULL,#NULL,#NULL,#NULL,#NULL,INVOICE GATEWAY"
configurable string essParameters = "";

# `importBulkData` job: the ESS package path and job definition name, comma separated.
# This tells Oracle which job should process your data.
# For Supply Chain Planning, the documentation specifies:
# E.g /oracle/apps/ess/scm/advancedPlanning/collection/configuration/CSVController
configurable string jobName = "";

# Positional, comma-separated parameters for the `importBulkData` job, `#NULL` for unused positions.
# This contains the values required by the Oracle job.
# E.g EX8,2,UOM.zip,#NULL,...
configurable string parameterList = "";

# Metadata object id of the job the Scheduler submits. Use a harmless one.
# The `jobDefinitionId` tells Oracle what job to run. The request ID tells you which particular execution of that job you are tracking
# Depending on the specific Oracle REST endpoint, you may see the job identified by `JobPackageName` + `JobDefName` instead of directly supplying a `jobDefinitionId`.
configurable string jobDefinitionId = "";
