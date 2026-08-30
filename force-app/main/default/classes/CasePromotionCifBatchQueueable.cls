global with sharing class CasePromotionCifBatchQueueable
    implements Queueable, Database.AllowsCallouts {

    global class CaseDTO {
        global Id caseId;
        global String accountNumber;
        global CaseDTO(Id caseId, String accountNumber) {
            this.caseId = caseId;
            this.accountNumber = accountNumber;
        }
    }
    private final List<CaseDTO> dtos;
    global CasePromotionCifBatchQueueable(List<CaseDTO> dtos) {
        this.dtos = dtos;
    }
    global void execute(QueueableContext qc) {
        List<CasePromotionCprBatchQueueable.CprDTO> nextJobs =
            new List<CasePromotionCprBatchQueueable.CprDTO>();
        for (CaseDTO dto : dtos) {
            if (dto == null) {
                continue;
            }
            String cifValue = null;
            try {
                CasePromotionCifQueueable.IResolver resolver =
                    new CasePromotionCifQueueable.DefaultResolver();
                cifValue = resolver.find(
                    dto.accountNumber,
                    new Case(Id = dto.caseId)
                );

                if (!String.isBlank(cifValue)) {
                    update new Case(
                        Id = dto.caseId,
                        Promotion_CIF__c = cifValue
                    );
                }
            }
            catch (Exception ex) {
                System.debug('CIF lookup error: ' + ex.getMessage());
            }

            nextJobs.add(
                new CasePromotionCprBatchQueueable.CprDTO(
                    dto.caseId,
                    cifValue,
                    dto.accountNumber
                )
            );
        }
        if (Test.isRunningTest() ||
            CasePromotionCifQueueable.disableCprDuringTests) {
            return;
        }

        if (!nextJobs.isEmpty()) {
            System.enqueueJob(
                new CasePromotionCprBatchQueueable(nextJobs)
            );
        }
    }
}