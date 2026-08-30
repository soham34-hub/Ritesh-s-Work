global with sharing class CasePromotionCifQueueable
    implements Queueable, Database.AllowsCallouts {

    @TestVisible
    public static Boolean disableCprDuringTests = false;

    @TestVisible
    public static IResolver resolver = new DefaultResolver();

    /********************************************************************
     * DTO
     ********************************************************************/
    global class CaseDTO {
        public Id caseId;
        public String accountNumber;
        public String escalationFlag;
        public String promotionCif;
        public Boolean fireCif;
        public Boolean fireCpr;

        global CaseDTO(
            Id caseId,
            String accountNumber,
            String escalationFlag,
            String promotionCif,
            Boolean fireCif,
            Boolean fireCpr
        ) {
            this.caseId         = caseId;
            this.accountNumber  = accountNumber;
            this.escalationFlag = escalationFlag;
            this.promotionCif   = promotionCif;
            this.fireCif        = fireCif;
            this.fireCpr        = fireCpr;
        }
    }

    /********************************************************************
     * Resolver Interface
     ********************************************************************/
    global interface IResolver {
        String find(String accountNumber, Case c);
    }

    global class DefaultResolver implements IResolver {
        public String find(String accountNumber, Case c) {
            return new ResolvePrimaryCIF().findPromoCif(accountNumber, c);
        }
    }

    /********************************************************************
     * Instance vars
     ********************************************************************/
    private final CaseDTO dto;

    global CasePromotionCifQueueable(CaseDTO dto) {
        this.dto = dto;
    }

    /********************************************************************
     * EXECUTE
     ********************************************************************/
    global void execute(QueueableContext qc) {

        if (dto == null) return;

        String cifValue = dto.promotionCif;

        // ------------------ CIF RESOLUTION ------------------
        if (dto.fireCif && !String.isBlank(dto.accountNumber)) {
            try {
                Case shell = new Case(
                    Id = dto.caseId,
                    Account_Number__c = dto.accountNumber
                );

                cifValue = resolver.find(dto.accountNumber, shell);

                if (!String.isBlank(cifValue)) {
                    update new Case(
                        Id = dto.caseId,
                        Promotion_CIF__c = cifValue
                    );
                }

            } catch (Exception ex) {
                System.debug('CIF error: ' + ex.getMessage());
            }
        }

        // ------------------ CPR AGGREGATION ------------------
        if (dto.fireCpr && !disableCprDuringTests) {
            QueueableAggregator.add(
                new CasePromotionCprBatchQueueable.CprDTO(
                    dto.caseId,
                    cifValue,
                    dto.accountNumber
                )
            );
        }
    }

    /********************************************************************
     * FINALIZER — Enqueue ONE CPR batch job
     ********************************************************************/
    global void finish(AsyncApexJob job) {

        if (!QueueableAggregator.enqueued &&
            !QueueableAggregator.cprJobs.isEmpty() &&
            !disableCprDuringTests) {

            QueueableAggregator.enqueued = true;

            System.enqueueJob(
                new CasePromotionCprBatchQueueable(
                    QueueableAggregator.cprJobs
                )
            );
        }
    }
}