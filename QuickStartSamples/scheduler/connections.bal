import ballerinax/oraclefusion.common.scheduler;

final scheduler:Client schedulerClient = check new scheduler:Client(
    config = {
        auth: {
            username: erpUsername,
            password: erpPassword
        }
    },
    serviceUrl = serviceUrl
);
