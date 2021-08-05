import ballerina/log;
import ballerinax/azure_cosmosdb;
import ballerina/http;
import ballerina/uuid;

service / on new http:Listener(8090) {
    resource function get ordermgt/'order/[string orderId](http:Caller caller) returns error? {

        azure_cosmosdb:DataPlaneClient azure_cosmosdbEndpoint1 = check new ({
            baseUrl: "https://640cb023-0ee0-4-231-b9ee.documents.azure.com:443/",
            primaryKeyOrResourceToken: "{COSMOS_DB_PRIMARY_KEY}"
        });
        stream<azure_cosmosdb:Document, error> queryDocumentsResponse = check azure_cosmosdbEndpoint1->queryDocuments(
        "ECOM_DB", "ECOM_ORDER", "SELECT eo.id, eo.orderDetails FROM ECOM_ORDER eo WHERE eo.id = \"" + orderId + "\"", 
        {enableCrossPartition: true});

        json j = check queryDocumentsResponse.next();
        
        check caller->respond(check j.value.documentBody.orderDetails);
    }
    resource function post 'order(@http:Payload json payload, http:Caller caller) returns error? {
        string orderId = uuid:createType1AsString();

        azure_cosmosdb:DataPlaneClient azure_cosmosdbEndpoint = check new ({
            baseUrl: "https://640cb023-0ee0-4-231-b9ee.documents.azure.com:443/",
            primaryKeyOrResourceToken: "{COSMOS_DB_PRIMARY_KEY}"
        });
        azure_cosmosdb:Document createDocumentResponse = check azure_cosmosdbEndpoint->createDocument("ECOM_DB", 
        "ECOM_ORDER", {
            id: orderId,
            "orderDetails": payload,
            "p4": 0
        }, 0, {isUpsertRequest: false});
        log:printInfo("Placed the order. OrderId: " + orderId + ", Account Id: " + (check payload.accountId).toString());

        check caller->respond(orderId);
    }

}
