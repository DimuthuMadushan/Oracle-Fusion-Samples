import ballerina/io;
import ballerina/log;
import ballerina/zip;
import ballerinax/oraclefusion.erp.integrations;

final integrations:Client erpClient = check new integrations:Client(
    config = {
        auth: {
            username: erpUsername,
            password: erpPassword
        }
    },
    serviceUrl = serviceUrl
);

public function main() returns error? {
    do {
        string sourcePath = "./AccDetails.csv";
        string targetPath = "./AccDetails.zip";
        check zip:compress(sourcePath, targetPath, {overwrite: true});
        log:printInfo("CSV file compressed successfully", targetPath = targetPath);

        byte[] & readonly zipBytes = check io:fileReadBytes(targetPath);
        string base64Content = zipBytes.toBase64();
        log:printInfo("Base64 encoded ZIP content", base64Content = base64Content);

        integrations:UploadFileToUcmRequest uploadRequest = {
            documentContent: base64Content,
            documentAccount: documentAccount,
            contentType: "zip",
            fileName: "AccDetails.zip"
        };
        integrations:ErpIntegrationResponse uploadResponse = check erpClient->uploadFileToUcm(uploadRequest);
        string? documentId = uploadResponse?.documentId;
        log:printInfo("File uploaded to UCM successfully", documentId = documentId);
    } on fail error e {
        log:printError("Error occurred", 'error = e);
        return e;
    }
}
