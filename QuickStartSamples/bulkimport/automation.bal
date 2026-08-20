import ballerina/io;
import ballerina/log;
import ballerina/zip;
import ballerinax/oraclefusion.erp.integrations;

public function main() returns error? {
    do {
        string sourcePath = "./AccDetails.csv";
        string targetPath = "./AccDetails.zip";
        check zip:compress(sourcePath, targetPath, {overwrite: true});
        log:printInfo("CSV file compressed successfully", targetPath = targetPath);

        byte[] & readonly zipBytes = check io:fileReadBytes(targetPath);
        string base64Content = zipBytes.toBase64();
        log:printInfo("Base64 encoding completed");

        integrations:ImportBulkDataRequest bulkRequest = {
            documentContent: base64Content,
            contentType: "zip",
            fileName: "AccDetails.zip",
            documentAccount: documentAccount,
            jobName: jobName,
            parameterList: parameterList
        };
        integrations:ErpIntegrationResponse bulkResponse = check erpClient->importBulkData(bulkRequest);
        string? requestId = bulkResponse?.reqstId;
        log:printInfo("Bulk import submitted successfully", requestId = requestId);
    } on fail error e {
        log:printError("Error occurred", 'error = e);
        return e;
    }
}
