public with sharing class RadsOffersClient {

    public static final String NAMED_CREDENTIAL = 'Rads_Offers';
    @TestVisible private static Integer DEFAULT_TIMEOUT_MS = 60000;
    @TestVisible private static EnvelopeDTO mockResponse;
    public class RadsOffersException extends Exception {}
    public static EnvelopeDTO dto;

public class EnvelopeDTO {
    @AuraEnabled public Integer statusCode;
    @AuraEnabled public String  statusDescription;
    @AuraEnabled public String  errorDescription;
    @AuraEnabled public String  transactionId;
}

    public static EnvelopeDTO submitCprForCif(String channelId,String cifKey,String correlationId){
        return submitCprForCif(channelId, cifKey, correlationId, null);
    }
    
    
	@AuraEnabled
	public static EnvelopeDTO refreshCaseData(
    Id caseId,String channelId,String cifKey,String correlationId,Map<String,String> extraHeaders){
    if (String.isBlank(channelId))
        throw new RadsOffersException('Missing channelId');
    if (String.isBlank(cifKey))
        throw new RadsOffersException('Missing cifKey');
    if (Test.isRunningTest() && mockResponse != null) {
        return mockResponse;
    }

    String generatedCorrelationId = UUID.randomUUID().toString();
    Map<String,Object> body = new Map<String,Object>{'channelId' => channelId,'cifKey' => cifKey,
        							  'correlationId' => generatedCorrelationId};
    try{
   HttpRequest req = new HttpRequest();
    req.setMethod('POST');
    req.setEndpoint('callout:' + NAMED_CREDENTIAL + '/retrievePromotionalDetails');
    req.setHeader('Content-Type', 'application/json');
    req.setHeader('Accept', 'application/json');
    req.setTimeout(DEFAULT_TIMEOUT_MS);
    req.setBody(JSON.serialize(body));

    if (extraHeaders != null) {
        for (String key : extraHeaders.keySet()) {
            req.setHeader(key, extraHeaders.get(key));
        }
    }
    HttpResponse resp = new Http().send(req);
    if (resp == null)
        throw new RadsOffersException('Null HTTP response');
    if (resp.getStatusCode() != 200)
        throw new RadsOffersException('HTTP error: ' + resp.getStatusCode());
     dto  = (EnvelopeDTO) JSON.deserialize(resp.getBody(), EnvelopeDTO.class);
    if (dto == null)
        throw new RadsOffersException('Null DTO from RADS');
    if (dto.statusCode != 200){
        
        throw new RadsOffersException('Service error: ' + dto.statusDescription);
    }
    
}    
catch(RadsOffersException e){
        List<API_RADS_Transaction_Log__c> rtlog = new List<API_RADS_Transaction_Log__c>();
        rtlog = [Select id,Error_Code__c,Error_Message__c,RADS_Last_Update__c from API_RADS_Transaction_Log__c where Id =: dto.transactionId Limit 1];
        Promotion_Enrollment__c pe = new Promotion_Enrollment__c();
        pe.Case_Number__c =  caseId;
        pe.CIF__c = cifKey;
        pe.Error_Code__c = rtlog[0].Error_Code__c;
        pe.Error_Message__c = rtlog[0].Error_Message__c;
        pe.RADS_Last_Update_Date__c = rtlog[0].RADS_Last_Update__c;
        pe.API_RADS_Transaction_Log__c = rtlog[0].id;
        insert pe;
        system.debug('checkPeRecord    ' + pe);
        Enrollment_Activity_Refresh__e evt = new Enrollment_Activity_Refresh__e(Case_Id__c = null,Enrollment_Activity_Id__c = '');
        EventBus.publish(evt);
        return dto;
    }
    case relatedrecord = new Case(Id = caseId);    
    //patch in data coversion code here!
    PromotionDataCapture.processRecords(relatedrecord,dto.transactionId);
    Enrollment_Activity_Refresh__e evt = new Enrollment_Activity_Refresh__e(Case_Id__c = relatedRecord.Id,Enrollment_Activity_Id__c = '');
    EventBus.publish(evt);

    
    return dto;
}
     
@AuraEnabled(cacheable=true)
	public static EnvelopeDTO submitCprForCif(String channelId, String cifKey, String correlationId, Map<String,String> extraHeaders) {
        if (String.isBlank(channelId))
            throw new RadsOffersException('Missing channelId');
        if (String.isBlank(cifKey))
            throw new RadsOffersException('Missing cifKey');
        if (Test.isRunningTest() && mockResponse != null) {
            return mockResponse;
        }
        Map<String,Object> body = new Map<String,Object>{'channelId' => channelId, 'cifKey' => cifKey,'correlationId' => UUID.randomUUID().toString()};
        HttpRequest req = new HttpRequest();
        req.setMethod('POST');
        req.setEndpoint('callout:' + NAMED_CREDENTIAL + '/retrievePromotionalDetails');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Accept', 'application/json');
        req.setTimeout(DEFAULT_TIMEOUT_MS);
        req.setBody(JSON.serialize(body));

        if (extraHeaders != null) {
            for (String key : extraHeaders.keySet()) {
                req.setHeader(key, String.valueOf(extraHeaders.get(key)));
            }
        }
        HttpResponse resp = new Http().send(req);
        if (resp == null)
            throw new RadsOffersException('Null HTTP response');
        if (resp.getStatusCode() != 200){
            system.debug(resp.getStatus());
            throw new RadsOffersException('HTTP error: ' + resp.getStatusCode());
        }
        EnvelopeDTO dto = (EnvelopeDTO)
            JSON.deserialize(resp.getBody(), EnvelopeDTO.class); 
        if (dto == null)
            throw new RadsOffersException('Null DTO from RADS');

        if (dto.statusCode == null || dto.statusCode != 200)
            throw new RadsOffersException('Service error: ' + dto.statusDescription);
        return dto;
    }
}