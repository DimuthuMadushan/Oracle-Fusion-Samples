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

import ballerina/io;
import ballerina/zip;
import ballerinax/oraclefusion.common.scheduler;
import ballerinax/oraclefusion.erp.integrations;

# Packs the FBDI CSV files into the archive the upload phases carry, and returns it base64-encoded,
# which is how the ERP Integrations API takes a file - as text inside the JSON body.
#
# + return - The archive as base64-encoded text, or an error if it could not be built or read
function prepareArchive() returns string|error {
    // `includeSourceDirectory: false` is what makes the archive loadable: Oracle matches each
    // entry name against the interface table it feeds, so the CSV files have to sit at the root of
    // the zip. Left at its default the source directory becomes a wrapping entry, every name gains
    // a prefix, and the import fails on an instance that accepted the same data yesterday.
    //
    // `overwrite: true` because the sample is meant to be re-run. `zipFilePath` must be outside
    // `dataDirPath` - the archive cannot contain itself, and `compress` rejects it if it would.
    check zip:compress(dataDirPath, zipFilePath, {includeSourceDirectory: false, overwrite: true});

    // Print what went in, since a missing or misnamed CSV is the failure that shows up much later
    // as an ESS job in `ERROR` with nothing wrong on the Ballerina side.
    zip:Entry[] entries = check zip:listEntries(zipFilePath);
    string entryNames = string:'join(", ", ...from zip:Entry entry in entries
                select entry.name);

    io:println(string `compress -> ${zipFilePath} (${entryNames})`);

    byte[] fileBytes = check io:fileReadBytes(zipFilePath);
    return fileBytes.toBase64();
}

# Stages the archive in WebCenter Content, then submits an ESS job over the document the upload
# returned - the two calls that split what `runImportOperations` does in one.
#
# Needs `documentAccount`, and `jobPackageName`, `jobDefName` and `essParameters` for the job.
#
# + documentContent - The archive, base64-encoded
function runUploadOperations(string documentContent) {
    io:println("\n=== Upload and submit ===");

    // 1. Stage the file in WebCenter Content, without submitting a job.
    integrations:ErpIntegrationResponse|error uploadResult = erpClient->uploadFileToUcm({
        documentContent,
        documentAccount,
        contentType: "zip",
        fileName
    });
    printOutcome("uploadFileToUcm", uploadResult);

    // 2. Submit an ESS job over the document the upload returned.
    string? documentId = uploadResult is integrations:ErpIntegrationResponse ? uploadResult?.documentId : ();
    if documentId is string {
        integrations:ErpIntegrationResponse|error essResult = erpClient->submitEssJobRequest({
            jobPackageName,
            jobDefName,
            documentId,
            essParameters
        });
        printOutcome("submitEssJobRequest", essResult);
    } else {
        io:println("submitEssJobRequest -> skipped: uploadFileToUcm returned no documentId");
    }
}

# Uploads and submits in a single call - the path Oracle recommends for FBDI imports - then reads
# the status of the job it started.
#
# Needs `documentAccount`, and `jobName` and `parameterList` for the job.
#
# + documentContent - The archive, base64-encoded
function runImportOperations(string documentContent) {
    io:println("\n=== Bulk import ===");

    // 1. Upload and submit in one operation instead of two.
    integrations:ErpIntegrationResponse|error importResult = erpClient->importBulkData({
        documentContent,
        contentType: "zip",
        fileName,
        documentAccount,
        jobName,
        parameterList
    });
    printOutcome("importBulkData", importResult);

    // 2. Read the status of the job the import submitted.
    string? essRequestId = importResult is integrations:ErpIntegrationResponse ? importResult?.reqstId : ();
    if essRequestId is string {
        integrations:EssJobStatusResponse|error statusResult = erpClient->getEssJobStatus(essRequestId);
        printOutcome("getEssJobStatus", statusResult);
    } else {
        io:println("getEssJobStatus -> skipped: importBulkData returned no reqstId");
    }
}

# Runs the three operations `ballerinax/oraclefusion.common.scheduler` exposes: lists the scheduled
# process requests, submits one, and reads back the request the submission created.
#
# Off by default because, unlike the ERP calls, `submitJobRequest` starts a scheduled process on the
# instance - which needs a `jobDefinitionId` that is safe to run there, and is not something every
# instance the sample is pointed at has.
function runSchedulerOperations() {
    io:println("\n=== Scheduler ===");

    // 1. List the scheduled process requests on the instance.
    scheduler:RequestQueryResponse|error queryResult = schedulerClient->queryJobRequests();
    printOutcome("queryJobRequests", queryResult);

    // 2. Submit a scheduled process.
    scheduler:SubmitRequestResponse|error submitResult = schedulerClient->submitJobRequest({
        jobDefinitionId,
        description: "Ballerina connector quickstart"
    });
    printOutcome("submitJobRequest", submitResult);

    // 3. Read the request the submission created.
    int? requestId = submitResult is scheduler:SubmitRequestResponse ? submitResult.id : ();
    if requestId is int {
        scheduler:RequestDetails|error detailsResult = schedulerClient->getJobRequest(requestId);
        printOutcome("getJobRequest", detailsResult);
    } else {
        io:println("getJobRequest -> skipped: submitJobRequest returned no request id");
    }
}

# Prints what one call returned - the response payload, or the error.
#
# Fusion puts the useful part of a failure in the response body, which the Ballerina HTTP client
# carries in the error detail rather than the message, so both are printed.
#
# + operation - Connector operation that was called
# + outcome - What it returned
function printOutcome(string operation, anydata|error outcome) {
    if outcome is error {
        io:println(string `${operation} -> error: ${outcome.message()} | ${outcome.detail().toString()}`);
        return;
    }
    io:println(string `${operation} -> ${outcome.toJsonString()}`);
}
