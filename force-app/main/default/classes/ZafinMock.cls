@IsTest
public class ZafinMock implements HttpCalloutMock {

    public static Integer attemptCount = 0;
    public static Id logId;

    public HttpResponse respond(HttpRequest req) {

        attemptCount++;

        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');

        // --- Attempt #1: simulate 500 server error ---
        if (attemptCount == 1) {
            res.setStatusCode(500);
            res.setBody('{"error": "Server error"}');
            return res;
        }

        // --- Attempt #2: simulate a callout exception ---
        if (attemptCount == 2) {
            throw new CalloutException('Simulated timeout');
        }

        // --- Attempt #3: return success ---
        res.setStatusCode(200);
        res.setBody('{"status": "SUCCESS", "transactionId" :" ' + logId + ' "}');
        return res;
    }
}