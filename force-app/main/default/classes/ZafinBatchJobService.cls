global class ZafinBatchJobService implements Database.Batchable<Enrollment_Activity__c>, Database.AllowsCallouts {
 
    // Queried once in constructor-shared across all execute() chunks
    private String emailTemplateId;
    private String orgWideEmailId;
 
    global ZafinBatchJobService() {
        List<EmailTemplate> templates = [
            SELECT Id FROM EmailTemplate
            WHERE DeveloperName = 'PromoX_RADS_Refresh_Complete'
            LIMIT 1
        ];
        emailTemplateId = templates.isEmpty() ? null : templates[0].Id;
        List<OrgWideEmailAddress> orgEmails = [
            SELECT Id FROM OrgWideEmailAddress
            WHERE Address = 'force.delivery.coe@suntrust.com'
            LIMIT 1
        ];
        orgWideEmailId = orgEmails.isEmpty() ? null : orgEmails[0].Id;
    }
 
    // START
    
 
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
 
    // EXECUTE
 
    global void execute(Database.BatchableContext bc, List<Enrollment_Activity__c> scope) {
 
        List<String> empIdList = new List<String>();
        for (Enrollment_Activity__c ea : scope) {
            if (ea.Req_Initiator_2__c != null) {
                empIdList.add(ea.Req_Initiator_2__c);
            }
        }
        Map<String, User> userByEmpId = new Map<String, User>();
        for (User u : [
            SELECT Id,truist__Truist_User_ID__c,Email FROM user WHERE truist__Truist_User_ID__c IN :empIdList
        ]) {
            userByEmpId.put(u.truist__Truist_User_ID__c, u);
        }
 

        Map<Id, DataTracker> dataCaptureMap = new Map<Id, DataTracker>();
 
        for (Enrollment_Activity__c ea : scope) {
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
                System.debug('RADS request payload: ' + payload);
                req.setBody(JSON.serialize(payload));
 
                HttpResponse res = new Http().send(req);
                System.debug('RADS response for EA ' + ea.Id + ': ' + res.getBody());
 
                RadsOffersClient.EnvelopeDTO dto =
                    (RadsOffersClient.EnvelopeDTO) JSON.deserialize(res.getBody(), RadsOffersClient.EnvelopeDTO.class);
 
                DataTracker tracker  = new DataTracker();
                tracker.caseId       = ea.Case_Number__c;
                tracker.logId        = dto.transactionId;
                dataCaptureMap.put(ea.Id, tracker);
                System.debug('dto.transactionId ' +dto.transactionId);
                System.debug('dto.transactionId ' +dto);
 
            } catch (Exception e) {
                System.debug('RADS callout failed for EA ' + ea.Id + ': '
                             + e.getMessage() + '\n' + e.getStackTraceString());
            }
        }
 
        Map<Id, String> caseToLogIdMap = new Map<Id, String>();
        List<Case> casesForSync        = new List<Case>();
 
        for (Enrollment_Activity__c ea : scope) {
            DataTracker tracker = dataCaptureMap.get(ea.Id);
            if (tracker != null && tracker.caseId != null) {
                caseToLogIdMap.put(tracker.caseId, tracker.logId); // keyed by Case Id
                casesForSync.add(new Case(Id = tracker.caseId));
            } else {
                System.debug('Skipping data sync for EA ' + ea.Id + ' — no RADS response captured.');
            }
        }
 
        if (!casesForSync.isEmpty()) {
            PromotionDataSyncService.bulkProcess(casesForSync, caseToLogIdMap);
        }

        List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
 
        for (Enrollment_Activity__c ea : scope) {
            System.debug('Enrollment_Activity__c---->' +ea);
            System.debug('ea.Req_Initiator_2__c---->' + ea.Req_Initiator_2__c);
            User initiator = userByEmpId.get(ea.Req_Initiator_2__c);
            System.debug('userByEmpId---->' + userByEmpId);
            System.debug('initiator'+initiator);
            if (initiator == null || String.isBlank(initiator.Email) || emailTemplateId == null) {
            //if (initiator == null){
                System.debug('Skipping email for EA ' + ea.Id
                             + ' — missing user, email address, or email template.');
                System.debug('initiator---->' + initiator);
                continue;
            }
            try {
                Messaging.SingleEmailMessage rendered =
                    Messaging.renderStoredEmailTemplate(emailTemplateId, initiator.Id, ea.Id);
 
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                email.setToAddresses(new List<String>{ initiator.Email });
                email.setSubject(rendered.getSubject());
                if (rendered.getHtmlBody() != null) {
                    email.setHtmlBody(rendered.getHtmlBody());
                } else {
                    email.setPlainTextBody(rendered.getPlainTextBody());
                }
                email.setSaveAsActivity(false);
                if (orgWideEmailId != null) {
                    email.setOrgWideEmailAddressId(orgWideEmailId);
                }
                emailList.add(email);
 
            } catch (Exception e) {
                System.debug('Email build failed for EA ' + ea.Id + ': ' + e.getMessage());
            }
        }
 
  
        for (Enrollment_Activity__c ea : scope) {
            ea.Zafin_Post_Processing__c = false;
        }
 
        if (!emailList.isEmpty()) {
            Messaging.sendEmail(emailList);
        }
        update scope; 
    }
 
    // FINISH
  
    global void finish(Database.BatchableContext bc) {
        System.debug('ZafinBatchJobService completed.');
    }
 
 
    public class DataTracker {
        public String caseId;
        public String logId;
    }
}