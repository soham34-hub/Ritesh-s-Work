global with sharing class CasePromotionCprBatchQueueable
    implements Queueable, Database.AllowsCallouts {
    global class CprDTO {
        global Id caseId;
        global String cifValue;
        global String accountNumber;
        global CprDTO(Id caseId, String cifValue, String accountNumber) {
            this.caseId = caseId;
            this.cifValue = cifValue;
            this.accountNumber = accountNumber;
        }
    }
    private List<CprDTO> items = new List<CprDTO>();
    global CasePromotionCprBatchQueueable(List<CprDTO> dtos) {
        for (CprDTO d : dtos) {
            items.add(new CprDTO(d.caseId, d.cifValue, d.accountNumber));
        }
    }
    global void execute(QueueableContext qc) {
        system.debug('CORE MESSAGE: system batch queable is running!!!!');

        for (CprDTO dto : items) {
            try {
                CasePromotionCprService.runCpr(new CasePromotionCprService.CprInput(dto.caseId,
                        dto.cifValue,dto.accountNumber)
                );
            }
            catch (Exception ex) {
                System.debug('CPR failed for Case ' + dto.caseId + ': ' + ex.getMessage());
            }
        }
    }
}