import ballerina/log;
import ballerina/lang.runtime;
import ballerinax/oraclefusion.erp.integrations;

public function main() returns error? {
    do {
        // Submit the ESS job
        integrations:SubmitEssJobRequest essJobRequest = {
            jobPackageName: jobPackageName,
            jobDefName: jobDefName,
            documentId: documentId,
            essParameters: essParameters
        };
        integrations:ErpIntegrationResponse submitResponse = check erpClient->submitEssJobRequest(essJobRequest);
        string? requestId = submitResponse?.reqstId;
        log:printInfo("ESS job submitted successfully", requestId = requestId);

        if requestId is () {
            return error("No request ID returned from ESS job submission");
        }

        // Poll for job status
        string jobStatus = "WAIT";
        while jobStatus == "WAIT" || jobStatus == "RUNNING" || jobStatus == "PAUSED" {
            runtime:sleep(5);
            integrations:EssJobStatusResponse statusResponse = check erpClient->getEssJobStatus(requestId);
            integrations:EssJobStatusItem[]? statusItems = statusResponse?.items;
            if statusItems is integrations:EssJobStatusItem[] && statusItems.length() > 0 {
                integrations:EssJobStatusItem firstItem = statusItems[0];
                string? currentStatus = firstItem?.requestStatus;
                if currentStatus is string {
                    jobStatus = currentStatus;
                    log:printInfo("ESS job status", requestId = requestId, status = jobStatus);
                }
            }
        }

        if jobStatus == "SUCCEEDED" {
            log:printInfo("ESS job completed successfully", requestId = requestId, finalStatus = jobStatus);
        } else {
            log:printError("ESS job did not succeed", requestId = requestId, finalStatus = jobStatus);
            return error(string `ESS job ended with status: ${jobStatus}`);
        }
    } on fail error e {
        log:printError("Error occurred", 'error = e);
        return e;
    }
}
