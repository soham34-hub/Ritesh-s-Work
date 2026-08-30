public with sharing class ZafinOfferService {

    // -----------------------------------------------------
    // DTO: Returned to LWC and controller
    // -----------------------------------------------------
    public class ZafinResponseDTO {
        @AuraEnabled public Integer statusCode;
        @AuraEnabled public String statusDescription;
        @AuraEnabled public String errorDescription;
        @AuraEnabled public String transactionId;
        @AuraEnabled public Boolean success;
        @AuraEnabled public String rawResponse;
    }

    // -----------------------------------------------------
    // Request body wrapper
    // -----------------------------------------------------
    public class PromoActionRequest {
        public String enrolmentActivityName;
        public PromoActionRequest(String enrolmentActivityName) {
            this.enrolmentActivityName = enrolmentActivityName;
        }
    }

    // -----------------------------------------------------
    // SYNC call (LWC / UI)
    // -----------------------------------------------------
    @AuraEnabled
    public static ZafinResponseDTO sendPromoActionSync(Id enrollmentActivityId) {
		system.debug('fire ZafinResponseDTO call');
        Enrollment_Activity__c ea = [
            SELECT Id, Name
            FROM Enrollment_Activity__c
            WHERE Id = :enrollmentActivityId
            LIMIT 1
        ];
        system.debug('show enrollment activity record send to zafin ' + ea);
        PromoActionRequest reqBody = new PromoActionRequest(ea.Name);
        String jsonBody = JSON.serialize(reqBody);

        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:Rads_Offers/promoAction');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setTimeout(120000);
        req.setBody(jsonBody);

        ZafinResponseDTO dto = new ZafinResponseDTO();
        HttpResponse res;

        // ---------------------------
        // SEND CALLOUT
        // ---------------------------
        try {
            system.debug(' zafin zafin callout');
            res = new Http().send(req);
            system.debug('SHOW STATUS CODE %%%%% ' + res.getStatusCode());
            if(res.getStatusCode() == 200){
                ea.Zafin_Post_Processing__c = true;
                update(ea);
             //   
                
                
                
            }
            dto.statusCode  = res.getStatusCode();
            dto.rawResponse = res.getBody();
            system.debug(' zafin zafin callout status code ' +  dto.statusCode);
			system.debug('print response ' + res.getBody());
            dto.success = (dto.statusCode >= 200 && dto.statusCode < 300);
        } catch (Exception ex) {
            system.debug(';zafin exception ' + ex);
                        dto.statusCode        = 0;
            dto.success           = false;
            dto.statusDescription = 'Callout failure';
            dto.errorDescription  = ex.getMessage();

            return dto;
        }

        // ---------------------------
        // PARSE RESPONSE (BEST EFFORT)
        // ---------------------------
        try {
            if (String.isNotBlank(dto.rawResponse)) {
                Map<String, Object> parsed =
                    (Map<String, Object>)
                        JSON.deserializeUntyped(dto.rawResponse);

                if (parsed.containsKey('statusDescription')) {
                    dto.statusDescription =
                        String.valueOf(parsed.get('statusDescription'));
                }

                if (parsed.containsKey('errorDescription')) {
                    dto.errorDescription =
                        String.valueOf(parsed.get('errorDescription'));
                }

                if (parsed.containsKey('transactionId')) {
                    dto.transactionId =
                        String.valueOf(parsed.get('transactionId'));
                }
            }
        } catch (Exception ex) {
            dto.errorDescription =
                (dto.errorDescription == null ? '' : dto.errorDescription)
                + ' | JSON parse warning: '
                + ex.getMessage();
        }
system.debug('dto details ' + dto);
        return dto;
    }

    // -----------------------------------------------------
    // ASYNC call (used by Batch)
    // -----------------------------------------------------
    @future(callout=true)
    public static void sendPromoAction(Id enrollmentActivityId) {

        Enrollment_Activity__c ea = [
            SELECT Id, Name
            FROM Enrollment_Activity__c
            WHERE Id = :enrollmentActivityId
            LIMIT 1
        ];

        PromoActionRequest reqBody =
            new PromoActionRequest(ea.Name);
        String jsonBody = JSON.serialize(reqBody);

        sendCalloutWithRetries(jsonBody, 3);
    }

    // -----------------------------------------------------
    // Retry logic (unchanged transport behavior)
    // -----------------------------------------------------
    private static void sendCalloutWithRetries(
        String body,
        Integer maxRetries
    ) {
        Integer attempt = 0;

        while (attempt < maxRetries) {
            attempt++;

            try {
                HttpRequest req = new HttpRequest();
                req.setEndpoint('callout:Rads_Offers/promoAction');
                req.setMethod('POST');
                req.setHeader('Content-Type', 'application/json');
                req.setTimeout(120000);
                req.setBody(body);

                HttpResponse res = new Http().send(req);
                Integer status   = res.getStatusCode();

                if (status >= 200 && status < 300) {
                    System.debug(
                        'ZafinOfferService_SUCCESS attempt ' + attempt
                    );
                    return;
                }

                if (status < 500) {
                    System.debug(
                        'ZafinOfferService client error ' + status
                        + ' — aborting'
                    );
                    return;
                }

            } catch (Exception ex) {
                System.debug(
                    'ZafinOfferService exception: ' + ex.getMessage()
                );
            }
        }

        System.debug(
            'ZafinOfferService failed after '
            + maxRetries + ' retries'
        );
    }
}