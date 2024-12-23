import ballerina/http;
import ballerina/io;
import ballerina/lang.'string as strings;
import ballerina/url;

type RequestPayload record{
        string prompt;
};

configurable string clientId = ?;
configurable string clientSecret = ?;

@http:ServiceConfig {
    cors: {
        allowOrigins: ["http://localhost:3000"],
        allowCredentials: true,
        //allowHeaders: ["authorization","content-type"],
        allowMethods: ["POST","GET"]
    }
}
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
        http:Response response = check copilotAuthClient->post(string `/login/oauth/access_token?client_id=${clientId}&client_secret=${clientSecret}&code=${code}`, "The auth2 endpoint is successful");
        string responseText = check response.getTextPayload();
        map<string> formDataMap = check getFormDataMap(responseText);
        io:println(formDataMap.get("access_token"));
        string accessToken = formDataMap.get("access_token");
        json responseJson = {"token": accessToken};
        return responseJson;
    }

    resource function post chat(@http:Header{name: "Authorization"} string accessToken, RequestPayload payloadBody) returns json|error {

        json[] messages = [
            {
            role: "system",
            content: "You are a helpful assistant that replies to user messages"
            },
            {
            role: "user",
            content: payloadBody.prompt
            }
        ];

        io:println("Message:", messages);

        http:Client chatClient = check new ("https://api.githubcopilot.com", auth = {
            "token": accessToken
        });
        
        json response = check chatClient->/chat/completions.post({messages}, headers = {
            "content-Type": "application/json"
        });

        json[] testResponse = check response.choices.ensureType();
        string finalResponse =check testResponse[0].message.content.ensureType();
        io:println("chat response: ", finalResponse);
        return {"chatResponse": finalResponse}; 
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
