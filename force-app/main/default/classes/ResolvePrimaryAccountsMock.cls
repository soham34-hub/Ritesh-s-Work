/* Author Daniel Haro
 * Mock class for the Account Search operation
 * returns CIFAccountSearchDefine.AccountSearchResponse_element  
 * primary focus is the AccountDetails_element class may need to be update for future operations
 * Class being generated with MVP and time restraints 
 * 
 * 
 */ 

@isTEST
global class ResolvePrimaryAccountsMock implements HttpCalloutMock {
    
    
     global ResolvePrimaryAccountsMock(Integer statusCode, String body) {
        //this.statusCode = statusCode;
        //this.body = body;
    }
    
    
    
    global HTTPResponse respond(HTTPRequest request) {
        HttpResponse response = new HttpResponse();
        
        CIFAccountSearchDefine.AccountSearchResponse_element accountResults = new CIFAccountSearchDefine.AccountSearchResponse_element();
		CIFAccountSearchDefine.AccountDetails_element rec1 = new CIFAccountSearchDefine.AccountDetails_element();
        rec1.AccountNumber = '000001100041352866';
        rec1.CIFStaticKey = '000012341234';
        accountResults.AccountDetails.add(rec1);
		String jsonString = JSON.serialize(accountResults);
        response.setBody(jsonString);
        return response;
    }


}