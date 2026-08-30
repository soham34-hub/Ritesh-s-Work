@isTest
public class CIFAccountSearchInvokeMock2 implements WebServiceMock{
     public void doInvoke(Object stub,Object request,Map<String, Object> response,String endpoint,String soapAction,
                          String requestName,String responseNS,String responseName,String responseType) {
     	CIFAccountSearchInvoke.AccountSearchEndpoint1 response_x = new CIFAccountSearchInvoke.AccountSearchEndpoint1();
        CIFAccountSearchDefine.AccountSearchResponse_element accountSearchReplyelement = getAccountSearchOperation(); 
        response.put('response_x', accountSearchReplyelement);
        }
   
    public static CIFAccountSearchDefine.AccountSearchResponse_element getAccountSearchOperation(){
    	CIFAccountSearchDefine.AccountSearchResponse_element account_search_reply_element= new CIFAccountSearchDefine.AccountSearchResponse_element();
        CIFAccountSearchDefine.AccountDetails_element AccountDetails_element= new CIFAccountSearchDefine.AccountDetails_element();
        AccountDetails_element.CIFStaticKey = 'TESTKEY001';
        account_search_reply_element.AccountDetails = new CIFAccountSearchDefine.AccountDetails_element[1];
        account_search_reply_element.AccountDetails[0] = AccountDetails_element;
        CIFAccountSearchDefine.Status_element Status_element= new CIFAccountSearchDefine.Status_element();
        CIFAccountSearchDefine.AccountSearchRequest_element AccountSearchRequest_element= new CIFAccountSearchDefine.AccountSearchRequest_element();
        CIFAccountSearchDefine.AddressDetails_element AddressDetails_element= new CIFAccountSearchDefine.AddressDetails_element();
        CIFAccountSearchDefine.StatusDetails_element StatusDetails_element= new CIFAccountSearchDefine.StatusDetails_element();        
        return account_search_reply_element;
        }
}