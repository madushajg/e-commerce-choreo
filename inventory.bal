import ballerinax/azure_cosmosdb;
import ballerina/http;

service / on new http:Listener(8090) {
    resource function get inventory/search/[string query](http:Caller caller) returns error? {

        azure_cosmosdb:DataPlaneClient azure_cosmosdbEndpoint = check new ({
            baseUrl: "https://640cb023-0ee0-4-231-b9ee.documents.azure.com:443/",
            primaryKeyOrResourceToken: "{COSMOS_DB_PRIMARY_KEY}"
        });
        stream<azure_cosmosdb:Document, error> queryDocumentsResponse = check azure_cosmosdbEndpoint->queryDocuments(
        "ECOM_DB", "ECOM_INVENTORY", string `SELECT ei.id, ei.description FROM ECOM_INVENTORY ei WHERE ei.description LIKE "%${
        query}%"`, {enableCrossPartition: true});

        json j = check queryDocumentsResponse.next();

        json result = {
            "id": check j.value.id,
            "desciption": check j.value.documentBody.description
        };
        check caller->respond(result);
    }
}
