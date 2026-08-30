public with sharing class CasePromotionCprService {

    public class CprInput {
        public Id caseId;
        public String cifKey;
        public String accountNumber;

        public CprInput(Id caseId, String cifKey, String accountNumber) {
            this.caseId = caseId;
            this.cifKey = cifKey;
            this.accountNumber = accountNumber;
        }
    }

    public interface IProcessor {
        void process(Case relatedRecord, String tlid);
    }

    public class DefaultProcessor implements IProcessor {
        public void process(Case relatedRecord, String tlid) {
            PromotionDataCapture.processRecords(relatedRecord, tlid);
             //adding in platform event to fire off refesh
			Enrollment_Activity_Refresh__e evt = new Enrollment_Activity_Refresh__e(Case_Id__c = relatedRecord.Id,Enrollment_Activity_Id__c = tlid);
			EventBus.publish(evt);
        }
    }

    @TestVisible
    private static IProcessor processor = new DefaultProcessor();

    public static void runCpr(CprInput input) {

        if (input == null ||
            input.caseId == null ||
            String.isBlank(input.cifKey)) {

            System.debug(LoggingLevel.WARN, 'CPR skipped: missing CaseId or CIF');
            return;
        }

        Case shell = new Case(
            Id = input.caseId,
            Account_Number__c = input.accountNumber,
            Promotion_CIF__c  = input.cifKey
        );

        RadsOffersClient.EnvelopeDTO env;

        try {
            env = RadsOffersClient.submitCprForCif(
                'CPR',
                input.cifKey,
                String.valueOf(input.caseId)
            );
            
        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR,
                'CPR callout failed for Case ' + input.caseId + ': ' + ex.getMessage());
            return;
        }

        if (env == null) {
            System.debug(LoggingLevel.ERROR,
                'Null CPR response for Case ' + input.caseId);
            return;
        }

        String tlid = env.transactionId;

        if (String.isBlank(tlid)) {
            System.debug(LoggingLevel.ERROR,
                'CPR response missing TLID for Case ' + input.caseId);
        }

        try {
            processor.process(shell, tlid);
        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR,
                'PromotionDataCapture failed for Case ' + input.caseId +
                ', TLID=' + tlid + ': ' + ex.getMessage());
        }
    }
}