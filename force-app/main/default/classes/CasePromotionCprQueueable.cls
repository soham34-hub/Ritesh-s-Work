public with sharing class CasePromotionCprQueueable implements Queueable, Database.AllowsCallouts {

    private final Id caseId;
    private final String cifKey;
    private final String accountNumber;

    public CasePromotionCprQueueable(Id caseId, String cifKey, String accountNumber) {
        this.caseId = caseId;
        this.cifKey = cifKey;
        this.accountNumber = accountNumber;
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
    static IProcessor processor = new DefaultProcessor();

    public void execute(QueueableContext qc) {
        system.debug('CORE MESSAGE: system queable is running!!!!');


        if (caseId == null || String.isBlank(cifKey)) {
            System.debug(LoggingLevel.WARN, 'CPR skipped: missing CaseId or CIF');
            return;
        }

        Case shell = new Case(
            Id = caseId,
            Account_Number__c = accountNumber,
            Promotion_CIF__c  = cifKey
        );

        RadsOffersClient.EnvelopeDTO env;

        try {
            env = RadsOffersClient.submitCprForCif(
                'CPR',
                cifKey,
                String.valueOf(caseId)
            );
        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR,
                'CPR callout failed for Case ' + caseId + ': ' + ex.getMessage());
            return;
        }

        if (env == null) {
            System.debug(LoggingLevel.ERROR, 'Null CPR response for Case ' + caseId);
            return;
        }

        String tlid = env.transactionId;

        if (String.isBlank(tlid)) {
            System.debug(LoggingLevel.ERROR,
                'CPR response missing TLID for Case ' + caseId);
        }

        try {
            processor.process(shell, tlid);
        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR,
                'PromotionDataCapture failed for Case ' + caseId + ', TLID=' + tlid + ': ' + ex.getMessage());
        }
    }
}