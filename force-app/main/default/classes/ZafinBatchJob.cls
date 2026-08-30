global class ZafinBatchJob implements Database.Batchable<Enrollment_Activity__c>,Database.AllowsCallouts {
 
	public class dataTracker{
  	  public string caseId;
  	  public String logId;
	}
    map<String,dataTracker> dataCaptureMap = new map<String,dataTracker>(); // ea.id / datatracker
    // -------------------------------------------------
    // START (Iterable version — compiler safe)
    // -------------------------------------------------
    global Iterable<Enrollment_Activity__c> start(Database.BatchableContext bc) {
        return [
            SELECT Id,
            Zafin_Post_Processing__c,
            Case_Number__c,
            Case_Number__r.Id,
            Case_Number__r.Promotion_CIF__c,
            Req_Initiator_2__c
            FROM Enrollment_Activity__c
            WHERE Zafin_Post_Processing__c = TRUE
            AND Case_Number__c != NULL
            AND Case_Number__r.Promotion_CIF__c != NULL
        ];
    }
    // -------------------------------------------------
    // EXECUTE
    // -------------------------------------------------
    global void execute(Database.BatchableContext bc,List<Enrollment_Activity__c> scope) {
		map<String,Enrollment_Activity__c> casesToProcrss = new map<String,Enrollment_Activity__c>();///add
        String recordId;
        //The ID of Salesforce email template
        List<EmailTemplate> emailTemplateIdList = [SELECT Id FROM EmailTemplate WHERE DeveloperName = 'PromoX_RADS_Refresh_Complete' Limit 1];
        String EmailTemplateId;
        if(emailTemplateIdList.isEmpty()){
           EmailTemplateId = null;
        }else{
            EmailTemplateId = emailTemplateIdList[0].Id;
        }
        //create a list to store the email message records
        List<Messaging.SingleEmailMessage> EmailMessageList = new list<Messaging.SingleEmailMessage>();
        //map empId --> user Id
        Map<String,Id>  usermap = new map<String,Id>(); // <employee Id code , userId>
        //used to look up all user ids at once
        List<String> empIdList = new List<String>();
        String orgWideEmail = [SELECT Id FROM OrgWideEmailAddress WHERE Address = 'force.delivery.coe@suntrust.com' LIMIT 1].Id;
        for (Enrollment_Activity__c ea : scope) {
            empIdList.add(ea.Req_Initiator_2__c);
            casesToProcrss.put(ea.Case_Number__c,ea); // add******************
        }
        List<user> coreUserList = new List<User>();
        coreUserList = [SELECT Id,truist__Truist_User_ID__c FROM user WHERE truist__Truist_User_ID__c in: empIdList];
        for(user cu : coreUserList){
            usermap.put(cu.truist__Truist_User_ID__c,cu.Id);
        }
        map<id,Id> emailToRecord = new map<id,Id>(); //eaRecord -> userId
        //*****KEY TO MAP USER ID INM SIGLE EMAIL
        for (Enrollment_Activity__c ea : scope) {
            emailToRecord.put(ea.id,usermap.get(ea.Req_Initiator_2__c));
        }
        //create emails for all ea records
        for (Enrollment_Activity__c ea : scope) {
                recordId = ea.Id;
                //create a single email
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                email.setToAddresses(new String[] {emailToRecord.get(ea.Id)});
                Messaging.SingleEmailMessage renderResult = Messaging.renderStoredEmailTemplate(EmailTemplateId,emailToRecord.get(ea.Id),recordId);
                email.setSubject(renderResult.getSubject());
                // Set the email body
                if(renderResult.getHtmlBody() == NULL){
                    email.setPlainTextBody(renderResult.getPlainTextBody());
                }
                else{
                    email.setHtmlBody(renderResult.getHtmlBody());
                }
                email.setSaveAsActivity(false);
                // Specify OrgWideEmailAddress for sender type
                email.setOrgWideEmailAddressId(orgWideEmail);
                //add SingleEmailMessage instance into list
                EmailMessageList.add(email);
        }

	///preform rads callout
        for (Enrollment_Activity__c ea : casesToProcrss.values()) { //update
            try {
                HttpRequest req = new HttpRequest();
                req.setEndpoint('callout:Rads_Offers/retrievePromotionalDetails');
                req.setMethod('POST');
                req.setHeader('Content-Type', 'application/json');
                Map<String, Object> payload = new Map<String, Object>{
                    'channelId'     => 'CPR',
                        'cifKey'        => ea.Case_Number__r.Promotion_CIF__c,
                        'correlationId' => UUID.randomUUID().toString()
                        };
                            system.debug('Show Request ' + payload);
                req.setBody(JSON.serialize(payload));
                HttpResponse res = new Http().send(req);
                System.debug('Response for EA ' + ea.Id + ': ' + res.getBody());
                //capture response
                RadsOffersClient.EnvelopeDTO dto = (RadsOffersClient.EnvelopeDTO) JSON.deserialize(res.getBody(), RadsOffersClient.EnvelopeDTO.class);
                //fire off dataCapture
                system.debug('Data capture fired off');

                // move to end
                //create map to track prams
                //PromotionDataCapture.processRecords(new case(Id = ea.Case_Number__c),dto.transactionId);
                DataTracker dataTracker = new DataTracker();
                dataTracker.caseid = ea.Case_Number__c;
                dataTracker.logid =dto.transactionId;
                dataCaptureMap.put(ea.id,dataTracker);
                //create and send emails
        }catch (Exception e) {
              System.debug('Error processing EA ' + ea.Id + ': ' + e.getMessage());
        }
        }
        system.debug('do scope update');
        for (Enrollment_Activity__c ea : casesToProcrss.values()) {
            dataTracker track = dataCaptureMap.get(ea.Id);
            PromotionDataCapture.processRecords(new case(Id = track.caseID),track.logId);  
       }
                for (Enrollment_Activity__c ea : scope) {
                     ea.Zafin_Post_Processing__c = false;    
 
                }
       Messaging.sendEmail(EmailMessageList);
       update(scope);
    }
    // -------------------------------------------------
    // FINISH
    // -------------------------------------------------
    global void finish(Database.BatchableContext bc) {
        System.debug('Rads Batch Job Completed.');
        List<Enrollment_Activity__c> eaRecords = new List<Enrollment_Activity__c>();
    }
}