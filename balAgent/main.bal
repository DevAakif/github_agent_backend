import ballerina/http;
import ballerina/io;
import ballerina/lang.'string as strings;
import ballerina/url;

configurable string clientId = ?;
configurable string clientSecret = ?;

service / on new http:Listener(9090) {
    function init() {
        io:println("Service has started on port 9090");
    }

    resource function get auth() returns error? {
        http:Client githubClient = check new (string `https://github.com/login/oauth/authorize?client_id= ${clientId}`);
        http:Response response = check githubClient->get("/");
        io:println(response);
    }

    resource function get auth2(string code) returns json|error {
        io:println("Code: ", code);
        http:Client copilotAuthClient = check new ("https://github.com");
        http:Response response = check copilotAuthClient->post(string `/login/oauth/access_token?client_id=${clientId}&client_secret=${clientSecret}&code=${code}&redirect_url=""`, "The auth2 endpoint is successful");
        string responseText = check response.getTextPayload();
        map<string> formDataMap = check getFormDataMap(responseText);
        io:println(formDataMap.get("access_token"));
        return {"token": formDataMap.get("access_token")};

        // map<string> response = check copilotAuthClient->post(string `/login/oauth/access_token?client_id=${clientId}&client_secret=${clientSecret}&code=${code}`,"The auth2 endpoint is successful");

        // io:println("Auth2 endpoint is triggered: ",response.statusCode);
        // string header = check response.getHeader("Content-type");
        // string body = check response.getTextPayload();
        // mime:Entity entity = check response.getEntity();
        // response.getFo
        // io:println("response data: ",body);
    }

    resource function get hello() {
        io:println("Hello World");
    }
}

isolated function getFormDataMap(string formData) returns map<string>|error {
    map<string> parameters = {};
    if formData == "" {
        return parameters;
    }
    var decodedValue = url:decode(formData, "UTF-8");
    if decodedValue is error {
        return error("form data decode failure");
    }
    if strings:indexOf(decodedValue, "=") is () {
        return error("Datasource does not contain form data");
    }
    string[] entries = re `&`.split(decodedValue);
    foreach string entry in entries {
        int? index = entry.indexOf("=");
        if index is int && index != -1 {
            string name = entry.substring(0, index);
            name = name.trim();
            string value = entry.substring(index + 1);
            value = value.trim();
            parameters[name] = value;
        }
    }
    return parameters;
}
