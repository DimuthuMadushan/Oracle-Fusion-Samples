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
