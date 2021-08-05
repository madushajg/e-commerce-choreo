import ballerina/log;
import ballerina/http;

service / on new http:Listener(8090) {
    resource function get admin/invsearch/[string query](http:Caller caller) returns error? {

        log:printInfo("Request for serching in inventory. Query : " + query);
        http:Client invClient = check new ("https://inventory-service-madusha.choreoapps.dev/inventory");

        json resp = check invClient->get("/search/" + query, targetType = json);
        check caller->respond(resp);
    }
    resource function post admin/cartitems/[string accountId](@http:Payload json payload, http:Caller caller) 
    returns error? {

        log:printInfo("Request for adding new item to the cart. Acc/Id : " + accountId + ", Item: " + payload.toString());
        http:Client cartClient = check new ("https://cart-service-madusha.choreoapps.dev/shoppingcart");
        http:Response postResponse = check cartClient->post("/items/" + accountId, payload);

        check caller->respond(postResponse);
    }
    resource function get admin/checkout/[int accountId](http:Caller caller) returns error? {

        http:Client orderMgtClient = check new ("https://ordermgt-service-madusha.choreoapps.dev");
        http:Client billingClient = check new ("https://billing-service-madusha.choreoapps.dev");
        http:Client shippingClient = check new ("https://shipping-service-madusha.choreoapps.dev");
        http:Client cartClient1 = check new ("https://cart-service-madusha.choreoapps.dev");
        json cartResp = check cartClient1->get("/shoppingcart/items/" + accountId.toString(), targetType = json);

        json[] items = <json[]>(check cartResp.items);
        if (items.length() == 0) {

            http:Response resp1 = new;
            resp1.statusCode = 400;
            resp1.setPayload("empty cart");
            check caller->respond(resp1);
        } else {
            json mappedValue = {
                "accountId": accountId,
                "items": check cartResp.items
            };

            string orderId = check orderMgtClient->post("/order", mappedValue, targetType = string);

            string receiptNumber = check billingClient->post("/billing/payment", {"orderId": orderId}, 
            targetType = string);

            string trackingNumber = check shippingClient->post("/shipping/delivery", {"orderId": orderId}, 
            targetType = string);

            _ = check cartClient1->delete("/shoppingcart/items/" + accountId.toString(), targetType = http:Response);

            check caller->respond({
                "accountId": accountId,
                "orderId": orderId,
                "receiptNumber": receiptNumber,
                "trackingNumber": trackingNumber
            });
        }
    }
}
