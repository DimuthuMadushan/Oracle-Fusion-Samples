import ballerina/log;
import ballerinax/oraclefusion.common.scheduler;

public function main() returns error? {
    do {
        // Submit a new ESS job request
        scheduler:SubmitRequestBody jobRequest = {
            jobDefinitionId: jobDefinitionId,
            description: jobDescription
        };
        scheduler:SubmitRequestResponse submitResponse = check schedulerClient->submitJobRequest(jobRequest);
        int? requestId = submitResponse?.id;
        log:printInfo("ESS job submitted successfully", requestId = requestId);

        if requestId is () {
            return error("No request ID returned from ESS job submission");
        }

        // Fetch the submitted ESS job by request ID
        scheduler:GetJobRequestQueries getQueries = {};
        scheduler:RequestDetails jobDetails = check schedulerClient->getJobRequest(requestId, queries = getQueries);
        string? jobState = jobDetails?.state;
        string? jobDefId = jobDetails?.jobDefinitionId;
        log:printInfo("Fetched ESS job details", requestId = requestId, state = jobState, jobDefinitionId = jobDefId);

        // Query ESS job requests to list submitted jobs
        scheduler:QueryJobRequestsQueries queryParams = {
            q: string `id=${requestId}`
        };
        scheduler:RequestQueryResponse queryResponse = check schedulerClient->queryJobRequests(queries = queryParams);
        int? totalCount = queryResponse?.count;
        log:printInfo("Queried ESS job requests", totalCount = totalCount);

        scheduler:RequestDetails[]? jobItems = queryResponse?.items;
        if jobItems is scheduler:RequestDetails[] {
            foreach scheduler:RequestDetails jobItem in jobItems {
                int? itemId = jobItem?.requestId;
                string? itemState = jobItem?.state;
                string? itemDescription = jobItem?.description;
                log:printInfo("ESS job request", requestId = itemId, state = itemState, description = itemDescription);
            }
        }
    } on fail error e {
        log:printError("Error occurred", 'error = e);
        return e;
    }
}
