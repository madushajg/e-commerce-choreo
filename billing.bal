import ballerina/log;
import ballerina/http;
import ballerina/uuid;

service / on new http:Listener(8090) {
    resource function post billing/payment(@http:Payload json payload, http:Caller caller) returns error? {

        http:Client httpEndpoint = check new ("https://ordermgt-service-madusha.choreoapps.dev/ordermgt");
        json getResponse = check httpEndpoint->get("/order/" + (check payload.orderId).toString(), targetType = json);
        string receiptNumber = uuid:createType1AsString();

        log:printInfo("Billing completed. Order Id: " + (check payload.orderId).toString() + "Receipt Number" + 
        receiptNumber);
        check caller->respond(receiptNumber);
    }
}
