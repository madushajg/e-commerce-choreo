import ballerina/http;
import ballerina/log;
import ballerinax/azure_cosmosdb;
import ballerina/lang.'int as langInt;

service / on new http:Listener(8090) {
    resource function post shoppingcart/items/[int accountId](@http:Payload json payload, http:Caller caller) 
    returns error? {
        string invIdString = (check payload.invId).toString();
        int quantity = check langInt:fromString((check payload.quantity).toString());
        azure_cosmosdb:DataPlaneClient azure_cosmosdbEndpoint = check new ({
            baseUrl: "https://640cb023-0ee0-4-231-b9ee.documents.azure.com:443/",
            primaryKeyOrResourceToken: "{COSMOS_DB_PRIMARY_KEY}"
        });
        azure_cosmosdb:Document createDocumentResponse = check azure_cosmosdbEndpoint->createDocument("ECOM_DB", 
        "ECOM_ITEM", {
            id: invIdString,
            "account_id": accountId,
            "quantity": quantity,
            "p3": 0
        }, 0, {isUpsertRequest: false});

        check caller->respond(());
    }

    resource function get shoppingcart/items/[int accountId](http:Caller caller) returns error? {
        azure_cosmosdb:DataPlaneClient azure_cosmosdbEndpoint1 = check new ({
            baseUrl: "https://640cb023-0ee0-4-231-b9ee.documents.azure.com:443/",
            primaryKeyOrResourceToken: "{COSMOS_DB_PRIMARY_KEY}"
        });

        string q = string `SELECT ei.id FROM ECOM_ITEM ei WHERE ei.account_id = ${accountId}`;

        stream<azure_cosmosdb:Document, error> queryDocumentsResponse = check azure_cosmosdbEndpoint1->queryDocuments(
        "ECOM_DB", "ECOM_ITEM", q, {enableCrossPartition: true});

        json[] j = [];
        string invId = "";
        string qty = "";

        error? e = queryDocumentsResponse.forEach(function(azure_cosmosdb:Document result) {
                                                      json|error q1 = result.documentBody.quantity;
                                                      if (q1 is json) {
                                                          qty = q1.toString();
                                                      }
                                                      invId = result.id;
                                                      j.push({invId: invId, quantity: qty});
                                                  });

        check queryDocumentsResponse.close();

        check caller->respond({"items": j});
    }

    resource function delete shoppingcart/items/[int accountId](http:Caller caller) returns error? {
        azure_cosmosdb:DataPlaneClient azure_cosmosdbEndpoint2 = check new ({
            baseUrl: "https://640cb023-0ee0-4-231-b9ee.documents.azure.com:443/",
            primaryKeyOrResourceToken: "{COSMOS_DB_PRIMARY_KEY}"
        });

        string q = string `SELECT ei.id FROM ECOM_ITEM ei WHERE ei.account_id = ${accountId}`;

        stream<azure_cosmosdb:Document, error> queryDocumentsResponse = check azure_cosmosdbEndpoint2->queryDocuments(
        "ECOM_DB", "ECOM_ITEM", q, {enableCrossPartition: true});

        error? e = queryDocumentsResponse.forEach(function(azure_cosmosdb:Document result) {
            string invId = result.id;
            log:printInfo("Item to be deleted: " + invId);
            azure_cosmosdb:DeleteResponse|error deleteDocumentResponse = azure_cosmosdbEndpoint2->deleteDocument("ECOM_DB", 
                 "ECOM_ITEM", invId, "p3");

            if (deleteDocumentResponse is azure_cosmosdb:DeleteResponse) {
                log:printInfo("Successfully deleted the inventory item: " + invId);
            } else {
                log:printError("Failed to delete", 'error = deleteDocumentResponse);
            }
        });

        check caller->respond();
    }

}
