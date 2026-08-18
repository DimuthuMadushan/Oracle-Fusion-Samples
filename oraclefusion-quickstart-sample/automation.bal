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

// One call to every operation both Oracle Fusion connectors expose, printing whatever comes back:
//
//   ballerinax/oraclefusion.erp.integrations  uploadFileToUcm, submitEssJobRequest,
//                                             importBulkData, getEssJobStatus
//   ballerinax/oraclefusion.common.scheduler  queryJobRequests, submitJobRequest, getJobRequest
//
// Nothing is asserted and no call is retried. Each result is printed and the run continues, so one
// operation being unavailable on the instance does not hide the rest.
//
// The ids the later calls need come from the earlier responses, not from configuration: the
// document `submitEssJobRequest` submits is the one `uploadFileToUcm` returned, the request
// `getEssJobStatus` reads is the one `importBulkData` submitted, and the request `getJobRequest`
// reads is the one `submitJobRequest` created.

import ballerina/io;
import ballerinax/oraclefusion.common.scheduler;
import ballerinax/oraclefusion.erp.integrations as erp;

public function main() returns error? {
    // The API expects the file as base64-encoded text, so read the zip and encode it.
    byte[] fileBytes = check io:fileReadBytes(filePath);
    string documentContent = fileBytes.toBase64();

    io:println("=== ERP Integrations ===");

    // 1. Stage the file in WebCenter Content, without submitting a job.
    erp:ErpIntegrationResponse|error uploadResult = erpClient->uploadFileToUcm({
        documentContent,
        documentAccount,
        contentType: "zip",
        fileName
    });
    printOutcome("uploadFileToUcm", uploadResult);

    // 2. Submit an ESS job over the document the upload returned.
    string? documentId = uploadResult is erp:ErpIntegrationResponse ? uploadResult?.documentId : ();
    if documentId is string {
        erp:ErpIntegrationResponse|error essResult = erpClient->submitEssJobRequest({
            jobPackageName,
            jobDefName,
            documentId,
            essParameters
        });
        printOutcome("submitEssJobRequest", essResult);
    } else {
        io:println("submitEssJobRequest -> skipped: uploadFileToUcm returned no documentId");
    }

    // 3. Upload and submit in a single call - the path Oracle recommends for FBDI imports.
    erp:ErpIntegrationResponse|error importResult = erpClient->importBulkData({
        documentContent,
        contentType: "zip",
        fileName,
        documentAccount,
        jobName,
        parameterList
    });
    printOutcome("importBulkData", importResult);

    // 4. Read the status of the job the import submitted.
    string? essRequestId = importResult is erp:ErpIntegrationResponse ? importResult?.reqstId : ();
    if essRequestId is string {
        erp:EssJobStatusResponse|error statusResult = erpClient->getEssJobStatus(essRequestId);
        printOutcome("getEssJobStatus", statusResult);
    } else {
        io:println("getEssJobStatus -> skipped: importBulkData returned no reqstId");
    }

    io:println("\n=== Scheduler ===");

    // 5. List the scheduled process requests on the instance.
    scheduler:RequestQueryResponse|error queryResult = schedulerClient->queryJobRequests();
    printOutcome("queryJobRequests", queryResult);

    // 6. Submit a scheduled process.
    scheduler:SubmitRequestResponse|error submitResult = schedulerClient->submitJobRequest({
        jobDefinitionId,
        description: "Ballerina connector quickstart"
    });
    printOutcome("submitJobRequest", submitResult);

    // 7. Read the request the submission created.
    int? requestId = submitResult is scheduler:SubmitRequestResponse ? submitResult.id : ();
    if requestId is int {
        scheduler:RequestDetails|error detailsResult = schedulerClient->getJobRequest(requestId);
        printOutcome("getJobRequest", detailsResult);
    } else {
        io:println("getJobRequest -> skipped: submitJobRequest returned no request id");
    }
}
