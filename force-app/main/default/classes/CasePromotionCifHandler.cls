public class CasePromotionCifHandler {

    public static void run(List<Case> newList, Map<Id, Case> oldMap) {

        if (newList == null || newList.isEmpty()) {
            return;
        }

        List<CasePromotionCifBatchQueueable.CaseDTO> dtos =
            new List<CasePromotionCifBatchQueueable.CaseDTO>();

        for (Case c : newList) {

            Case oldC = (oldMap == null ? null : oldMap.get(c.Id));
            Boolean isInsert = (oldC == null);

            // HARD STOP: Promotion Escalation is NO
            if (c.Promotion_Escalation__c == 'No') {
                continue;
            }

            // --- Promotion logic ---
            Boolean promotionYesOnInsert =
                isInsert &&
                c.Promotion_Escalation__c == 'Yes';

            Boolean promotionChangedToYesOnUpdate =
                !isInsert &&
                c.Promotion_Escalation__c == 'Yes' &&
                oldC.Promotion_Escalation__c != 'Yes';

            // --- Account logic ---
            Boolean accountChanged =
                !isInsert &&
                c.Account_Number__c != oldC?.Account_Number__c;

            // ---  CIF__c change logic (NEW) ---
            Boolean cifChanged =
                !isInsert &&
                c.CIF__c != oldC?.CIF__c;

            // Must meet at least one CIF-triggering condition
            if (!(promotionYesOnInsert ||
                  promotionChangedToYesOnUpdate ||
                  accountChanged ||
                  cifChanged)) {
                continue;
            }

            // Account number is always required
            if (String.isBlank(c.Account_Number__c)) {
                continue;
            }

            dtos.add(
                new CasePromotionCifBatchQueueable.CaseDTO(
                    c.Id,
                    c.Account_Number__c
                )
            );
        }

        if (!dtos.isEmpty()) {
            System.enqueueJob(new CasePromotionCifBatchQueueable(dtos));
        }
    }
}