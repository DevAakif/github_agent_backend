import ballerina/http;
import ballerina/io;

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
    resource function post auth2(string code) returns error? {
        io:println("Code: ", code);
        http:Client copilotAuthClient = check new ("https://github.com");
        http:Response response = check copilotAuthClient->post(string `/login/oauth/access_token?client_id=${clientId}&client_secret=${clientSecret}&code=${code}`,"The auth2 endpoint is successful");
        io:println("Auth2 endpoint is triggered: ",response.statusCode);
    }
    resource function get hello() {
        io:println("Hello World");
    }
}
