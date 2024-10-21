import ballerina/http;
import ballerina/io;


configurable string clientId = ?;

service / on new http:Listener(9090) {
    function init() {
        io:println("Service has started on port 9090");
    }
    resource function post api(http:Request req) {
        io:println("The api endpoint was triggered");
        io:println(clientId);        
    }

    resource function get api(http:Caller caller, http:Request req) {
        string link = string `<!DOCTYPE html>
        <html>
        <body>
        <a href="https://github.com/login/oauth/authorize?client_id=${clientId}">Login with GitHub</a>
        </body>
        </html>`;
        checkpanic caller->respond(link);
    }
}