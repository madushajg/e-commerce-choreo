import ballerina/log;
import ballerina/http;
import ballerina/uuid;

service / on new http:Listener(8090) {
    resource function post shipping/delivery(@http:Payload json payload, http:Caller caller) returns error? {

        http:Client httpEndpoint = check new ("https://ordermgt-service-madusha.choreoapps.dev/ordermgt");
        json getResponse = check httpEndpoint->get("/order/" + (check payload.orderId).toString(), targetType = json);
        string trackingNumber = uuid:createType1AsString();

        log:printInfo("Updated shipping records. Order Id: " + (check payload.orderId).toString() + "Tracking Number" + 
        trackingNumber);
        check caller->respond(trackingNumber);
    }
}
