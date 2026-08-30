public class PromotionDataSyncService {
 
    private String transactionLogId;
    private String caseNumber;
    private PromoXTreeCreatorService.dataSet dataSet;
    private List<API_RADS_Transaction_Log__c> apiLog            = new List<API_RADS_Transaction_Log__c>();
    private List<API_Account__c>              apiAccountRecords = new List<API_Account__c>();
    private List<API_Promotion_Account_Transactions__c> apiTransactionList  = new List<API_Promotion_Account_Transactions__c>();
    private List<Promotion_Account_Transactions__c>     permTransactionList = new List<Promotion_Account_Transactions__c>();

    public API_RADS_Transaction_Log__c logRecToUpdate;
    // Cross-record maps - public so bulkProcess() can aggregate across all instances
    public Map<String,Promotion_Enrollment__c>  enrollmentCrossRecords      = new Map<String,Promotion_Enrollment__c>();
    public Map<String,Promotion_Rewards__c>     rewardCrossRecords          = new Map<String,Promotion_Rewards__c>();
    public Map<String,Promotion_Account__c>     accountCrossRecords         = new Map<String,Promotion_Account__c>();
    public Map<String,Promotion_Condition__c>   conditionsCrossRecords      = new Map<String,Promotion_Condition__c>();
    public Map<String,Promotion_Rule_Set__c>    promotionRuleSetCrossRecords= new Map<String,Promotion_Rule_Set__c>();
    public Map<String,Promotion_Rule__c>        ruleCrossRecords            = new Map<String,Promotion_Rule__c>();
    public Map<String,Promotion_Rule_Progress__c> ruleProgressCrossRecords    = new Map<String,Promotion_Rule_Progress__c>();
    public List<Promotion_Account_Transactions__c> txnToInsert = new List<Promotion_Account_Transactions__c>();
    public List<Promotion_Account_Transactions__c> txnToUpdate = new List<Promotion_Account_Transactions__c>();

    private Map<String,Promotion_Enrollment__c> enrollmentUpdates       = new Map<String,Promotion_Enrollment__c>();
    private Map<String,Promotion_Rewards__c>   rewardUpdates           = new Map<String,Promotion_Rewards__c>();
    private Map<String,Promotion_Account__c>   accountUpdates          = new Map<String,Promotion_Account__c>();
    private Map<String,Promotion_Condition__c> conditionsUpdates       = new Map<String,Promotion_Condition__c>();
    private Map<String,Promotion_Rule_Set__c> promotionRuleSetUpdates = new Map<String,Promotion_Rule_Set__c>();
    private Map<String,Promotion_Rule__c>   ruleCrossUpdates        = new Map<String,Promotion_Rule__c>();
    private Map<String,Promotion_Rule_Progress__c> ruleProgressUpdates     = new Map<String,Promotion_Rule_Progress__c>();

    private class BulkData {

        Map<String, API_RADS_Transaction_Log__c>      logById             = new Map<String, API_RADS_Transaction_Log__c>();
        Map<String, List<API_Promotion_Enrollment__c>>   apiEnrollByLogId    = new Map<String, List<API_Promotion_Enrollment__c>>();
        Map<String, List<API_Promotion_Rewards__c>>  apiRewardByLogId    = new Map<String, List<API_Promotion_Rewards__c>>();
        Map<String, List<API_Account__c>> apiAccountByLogId   = new Map<String, List<API_Account__c>>();
        Map<String, List<API_Promotion_Conditions__c>>  apiConditionByLogId = new Map<String, List<API_Promotion_Conditions__c>>();
        Map<String, List<API_Promotion_Rule_Set__c>>   apiRuleSetByLogId   = new Map<String, List<API_Promotion_Rule_Set__c>>();
        Map<String, List<API_Promotion_Rules__c>>    apiRuleByLogId      = new Map<String, List<API_Promotion_Rules__c>>();
        Map<String, List<API_Promotion_Rule_Progress__c>>          apiRuleProgByLogId  = new Map<String, List<API_Promotion_Rule_Progress__c>>();
        Map<String, List<API_Promotion_Account_Transactions__c>>   apiTxnByLogId       = new Map<String, List<API_Promotion_Account_Transactions__c>>();

        Map<Id, List<Promotion_Enrollment__c>>  permEnrollByCaseId   = new Map<Id, List<Promotion_Enrollment__c>>();
        Map<Id, List<Promotion_Rewards__c>>     permRewardByCaseId   = new Map<Id, List<Promotion_Rewards__c>>();
        Map<Id, List<Promotion_Account__c>>     permAccountByCaseId  = new Map<Id, List<Promotion_Account__c>>();
        Map<Id, List<Promotion_Condition__c>>   permCondByCaseId     = new Map<Id, List<Promotion_Condition__c>>();
        Map<Id, List<Promotion_Rule_Set__c>>    permRuleSetByCaseId  = new Map<Id, List<Promotion_Rule_Set__c>>();
        Map<Id, List<Promotion_Rule__c>>       permRuleByCaseId     = new Map<Id, List<Promotion_Rule__c>>();
        Map<Id, List<Promotion_Rule_Progress__c>>        permRuleProgByCaseId = new Map<Id, List<Promotion_Rule_Progress__c>>();
        Map<Id, List<Promotion_Account_Transactions__c>> permTxnByCaseId      = new Map<Id, List<Promotion_Account_Transactions__c>>();

    }
 
    /** 
     * @param cases   --       Cases in the current batch scope
     * @param caseToLogIdMap -- Map of Case Id → transactionLogId
     */

    public static void bulkProcess(List<Case> cases, Map<Id,String> caseToLogIdMap) {
        Set<String> logIds  = new Set<String>();
        Set<Id>     caseIds = new Set<Id>();
        for (Case c : cases) {
            caseIds.add(c.Id);
            if (caseToLogIdMap.get(c.Id) != null) {
                logIds.add(caseToLogIdMap.get(c.Id));
            }
        }
        System.debug('caseIds --------->'+caseIds);
        System.debug('caseIds --------->'+logIds);
        BulkData bd = fetchAll(logIds, caseIds); 
//Log - API_RADS_Transaction_Log__c
        List<PromotionDataSyncService> processors      = new List<PromotionDataSyncService>();
        List<API_RADS_Transaction_Log__c> logRecsToUpdate = new List<API_RADS_Transaction_Log__c>(); 
        for (Case c : cases) {
            PromotionDataSyncService svc = new PromotionDataSyncService();
            svc.initialize(c, caseToLogIdMap.get(c.Id), bd);
            processors.add(svc);
            if (svc.logRecToUpdate != null) {
                logRecsToUpdate.add(svc.logRecToUpdate);
            }
        }
//Enrollment - Promotion_Enrollment__c
        Map<Id,Promotion_Enrollment__c> enrollmentsMap = new Map<Id,Promotion_Enrollment__c>();
        List<Promotion_Enrollment__c> newEnrollmentList = new List<Promotion_Enrollment__c>();
        for (PromotionDataSyncService svc : processors) {
            svc.buildEnrollments();
            for (Promotion_Enrollment__c peRec : svc.enrollmentCrossRecords.values()){
                if(peRec.id != null){
                    enrollmentsMap.put(peRec.Id, peRec);
                }else{
                    newEnrollmentList.add(peRec);
                }
            }
        }
        List<Promotion_Enrollment__c> allEnrollments = new List<Promotion_Enrollment__c>();
        allEnrollments.addAll(enrollmentsMap.values());
        allEnrollments.addAll(newEnrollmentList);
         System.debug('allEnrollments --------->'+allEnrollments);
        if (!allEnrollments.isEmpty()) upsert allEnrollments;
// Rewards - Promotion_Rewards__c

        Map<Id,Promotion_Rewards__c> RewardsMap = new Map<Id,Promotion_Rewards__c>();
        List<Promotion_Rewards__c> newRewardsList = new List<Promotion_Rewards__c>();
        for (PromotionDataSyncService svc : processors) {
            svc.buildRewards();
            for (Promotion_Rewards__c peRec : svc.rewardCrossRecords.values()){
                if(peRec.id != null){
                    RewardsMap.put(peRec.Id, peRec);
                }else{
                    newRewardsList.add(peRec);
                }
            }
        }
        List<Promotion_Rewards__c> allRewards = new List<Promotion_Rewards__c>();
        allRewards.addAll(RewardsMap.values());
        allRewards.addAll(newRewardsList);
        if (!allRewards.isEmpty()) upsert allRewards;
// Account - Promotion_Account__c

        Map<Id,Promotion_Account__c> accountsMap = new Map<Id,Promotion_Account__c>();
        List<Promotion_Account__c> newAccountsList = new List<Promotion_Account__c>();
        for (PromotionDataSyncService svc : processors) {
            svc.buildAccounts();
            for (Promotion_Account__c accRec : svc.accountCrossRecords.values()){
                if(accRec.id != null){
                    accountsMap.put(accRec.Id, accRec);
                }else{
                    newAccountsList.add(accRec);
                }
            }
        }
         List<Promotion_Account__c> allAccounts = new List<Promotion_Account__c>();
        allAccounts.addAll(accountsMap.values());
        allAccounts.addAll(newAccountsList);
        if (!allAccounts.isEmpty()) upsert allAccounts;

// allConditions - Promotion_Condition__c
       Map<Id,Promotion_Condition__c> conditionsToUpdate = new Map<Id,Promotion_Condition__c>();
         List<Promotion_Condition__c>  conditionsToInsert = new List<Promotion_Condition__c>();
        for (PromotionDataSyncService svc : processors) {
            svc.buildConditions();
            for(Promotion_Condition__c cond : svc.conditionsCrossRecords.values()){
                if(cond.Id != null){
                   conditionsToUpdate.put(cond.Id,cond); 
                }else{
                   conditionsToInsert.add(cond); 
                }
            }
            
        }
         List<Promotion_Condition__c>  allConditions = new List<Promotion_Condition__c>();
         allConditions.addAll(conditionsToUpdate.values());
         allConditions.addAll(conditionsToInsert);
         if(allConditions.isEmpty()) upsert allConditions;

// allRuleSets - Promotion_Rule_Set__c
        Map<Id,Promotion_Rule_Set__c> ruleSetsToUpdate = new Map<Id,Promotion_Rule_Set__c>();
        List<Promotion_Rule_Set__c> ruleSetsToInsert = new List<Promotion_Rule_Set__c>();
        for (PromotionDataSyncService svc : processors) {
            svc.buildRuleSets();
            for(Promotion_Rule_Set__c promoRuleset : svc.promotionRuleSetCrossRecords.values()){
                if(promoRuleset.Id != null){
                    ruleSetsToUpdate.put(promoRuleset.Id, promoRuleset);
                }else{
                   ruleSetsToInsert.add(promoRuleset); 
                }
            }
        }
        List<Promotion_Rule_Set__c> allRuleSets = new List<Promotion_Rule_Set__c>();
        allRuleSets.addAll(ruleSetsToUpdate.Values());
        allRuleSets.addAll(ruleSetsToInsert);
        if(!allRuleSets.isEmpty()) upsert allRuleSets;

 // allRules - Promotion_Rule__c
        Map<Id,Promotion_Rule__c> rulesToUpdate = new Map<Id,Promotion_Rule__c>();
        List<Promotion_Rule__c> rulesToInsert = new List<Promotion_Rule__c>();
        for (PromotionDataSyncService svc : processors) {
            svc.buildRules();
            for(Promotion_Rule__c promorule : svc.ruleCrossRecords.values()){
                if(promorule.id != null){
                   rulesToUpdate.put(promorule.id,promorule); 
                }else{
                    rulesToInsert.add(promorule);
                }
            }
        }
        List<Promotion_Rule__c> allRules = new List<Promotion_Rule__c>();
        allRules.addAll(rulesToUpdate.values());
        allRules.addAll(rulesToInsert);
        if(!allRules.isEmpty()) upsert allRules;

 // allProgressRules - Promotion_Rule_Progress__c
        Map<Id,Promotion_Rule_Progress__c> progressRulesToUpdate = new Map<Id,Promotion_Rule_Progress__c>();
        List<Promotion_Rule_Progress__c> progressRulesToInsert = new List<Promotion_Rule_Progress__c>();
        for (PromotionDataSyncService svc : processors) {
            svc.buildRuleProgress();
            for(Promotion_Rule_Progress__c promoRuleProgress : svc.ruleProgressCrossRecords.values()){
                if(promoRuleProgress.Id != null){
                    progressRulesToUpdate.put(promoRuleProgress.Id, promoRuleProgress);
                }else{
                    progressRulesToInsert.add(promoRuleProgress);
                }
            }
        }
        List<Promotion_Rule_Progress__c> allProgressRuleRecords = new List<Promotion_Rule_Progress__c>();
        allProgressRuleRecords.addAll(progressRulesToUpdate.Values());
        allProgressRuleRecords.addAll(progressRulesToInsert);
        if(!allProgressRuleRecords.isEmpty()) upsert allProgressRuleRecords;
        
    // Transactions -Promotion_Account_Transactions__c

        List<Promotion_Account_Transactions__c> allTxnInsert = new List<Promotion_Account_Transactions__c>();
        Map<Id, Promotion_Account_Transactions__c> allTxnUpdateMap = new Map<Id, Promotion_Account_Transactions__c>();
        Map<Id, SObject> logsToUpdateMap = new Map<Id,SObject>();
        
        for (PromotionDataSyncService svc : processors) {
            svc.buildTransactions();
            if(svc.txnToInsert != null){
            allTxnInsert.addAll(svc.txnToInsert);
            }
            
            if(svc.txnToUpdate != null){
                allTxnUpdateMap.putAll(svc.txnToUpdate);
            }
            
        }
        if(!allTxnInsert.isEmpty()){
            insert allTxnInsert;
        }
        if(!allTxnUpdateMap.isEmpty()){
            update allTxnUpdateMap.values();
        }
        if(logRecsToUpdate != null && !logRecsToUpdate.isEmpty()){
            logsToUpdateMap.putAll(logsToUpdateMap);
            update logsToUpdateMap.values();
        } 
    }

    private static BulkData fetchAll(Set<String> logIds, Set<Id> caseIds) {

        BulkData bd = new BulkData();
 
        for (API_RADS_Transaction_Log__c rec : [

            SELECT Id, RADS_Last_Update__c, Error_Code__c, Error_Message__c
            FROM API_RADS_Transaction_Log__c WHERE Id IN :logIds

        ]) { bd.logById.put(rec.Id, rec); }
 
        for (API_Promotion_Enrollment__c rec : [
            SELECT Id, API_RADS_Transaction_Log__c, Account_Last_4__c, Account_Type__c, CIF__c,
                   Enroll_Teammate_Id__c, Enrollment_Channel__c, Enrollment_Date__c, Enrollment_Flag__c,
                   Force_Enroll_Case_Number__c, Offer_Code__c, Offer_Description__c, Offer_Name__c,
                   Offer_Status__c, Offer_Type__c, Promo_Code__c, Promo_End_Date__c, Promo_Key__c,
                   Promo_Start_Date__c, T_C_Client_Accepted_Timestamp__c, T_C_PDF_link__c
            FROM API_Promotion_Enrollment__c WHERE API_RADS_Transaction_Log__c IN :logIds

        ]) { addToMap(bd.apiEnrollByLogId, rec.API_RADS_Transaction_Log__c, rec); }
 
        for (API_Promotion_Rewards__c rec : [

            SELECT Id, API_Promotion_Enrollment__c, API_RADS_Transaction_Log__c, Force_Payout_Flag__c,
                   Reverse_Notes__c, Reward_Account__c, Reward_Code__c, Reward_Description__c,
                   Reward_Mailing_Date__c, Reward_Name__c, Reward_Payment_Amount__c, Reward_Payment_Date__c,
                   Reward_Reversal_Flag__c, Reward_Status__c, Reward_Total_Amount_Paid__c,
                   Reward_Type__c, Reward_Value_Type__c
            FROM API_Promotion_Rewards__c WHERE API_RADS_Transaction_Log__c IN :logIds

        ]) { addToMap(bd.apiRewardByLogId, rec.API_RADS_Transaction_Log__c, rec); }
 
        for (API_Account__c rec : [

            SELECT Id, API_Promotion_Rewards__c, API_RADS_Transaction_Log__c, Account_Type__c, Last_4__c
            FROM API_Account__c WHERE API_RADS_Transaction_Log__c IN :logIds

        ]) { addToMap(bd.apiAccountByLogId, rec.API_RADS_Transaction_Log__c, rec); }
 
        for (API_Promotion_Conditions__c rec : [

            SELECT Id, API_Account__c, API_RADS_Transaction_Log__c, Condition_Code__c,
                   Condition_Description__c, Condition_Met__c, Condition_Name__c
            FROM API_Promotion_Conditions__c WHERE API_RADS_Transaction_Log__c IN :logIds

        ]) { addToMap(bd.apiConditionByLogId, rec.API_RADS_Transaction_Log__c, rec); }
 
        for (API_Promotion_Rule_Set__c rec : [
            SELECT Id, API_Promotion_Conditions__c, API_RADS_Transaction_Log__c, Rule_Set_Code__c
            FROM API_Promotion_Rule_Set__c WHERE API_RADS_Transaction_Log__c IN :logIds

        ]) { addToMap(bd.apiRuleSetByLogId, rec.API_RADS_Transaction_Log__c, rec); }
 
        for (API_Promotion_Rules__c rec : [

            SELECT Id, API_Promotion_Rule_Set__c, API_RADS_Transaction_Log__c, Progress_Type__c,
                   Rule_Code__c, Rule_Description__c, Rule_Name__c, Target_Value__c
            FROM API_Promotion_Rules__c WHERE API_RADS_Transaction_Log__c IN :logIds

        ]) { addToMap(bd.apiRuleByLogId, rec.API_RADS_Transaction_Log__c, rec); }
 
        for (API_Promotion_Rule_Progress__c rec : [

            SELECT Id, Actual_Value__c, API_RADS_Transaction_Log__c, API_Promotion_Rules__c,
                   Evaluation_End_Date__c, Evaluation_Start_Date__c, Rule_Details__c,
                   Rule_Pass_Flag__c, Rule_Passed_Date__c
            FROM API_Promotion_Rule_Progress__c WHERE API_RADS_Transaction_Log__c IN :logIds

        ]) { addToMap(bd.apiRuleProgByLogId, rec.API_RADS_Transaction_Log__c, rec); }
 
        for (API_Promotion_Account_Transactions__c rec : [

            SELECT Id, Transaction_Reference_Id__c, API_Promotion_Rule_progress__c,
                   Transaction_Amount__c, API_RADS_Transaction_Log__c, Transaction_Channel__c,
                   Transaction_Code__c, Transaction_Currency__c, Transaction_Date__c,
                   Transaction_Reference_Id_2__c, Transaction_Debit_Credit_Code__c
            FROM API_Promotion_Account_Transactions__c WHERE API_RADS_Transaction_Log__c IN :logIds

        ]) { addToMap(bd.apiTxnByLogId, rec.API_RADS_Transaction_Log__c, rec); }
 
        for (Promotion_Enrollment__c rec : [
            SELECT Id, Offer_Code__c, Promo_Key__c, Case_Number__c FROM Promotion_Enrollment__c
            WHERE Case_Number__c IN :caseIds

        ]) 
        {  
            System.debug('Promotion_Enrollment__c------> '+rec);
            addToMap(bd.permEnrollByCaseId, rec.Case_Number__c, rec);
         }
         
 
        for (Promotion_Rewards__c rec : [

            SELECT Id, Reward_Code__c, Promotion_Enrollment_Number__c, Case_Number__c
            FROM Promotion_Rewards__c WHERE Case_Number__c IN :caseIds

        ]) { addToMap(bd.permRewardByCaseId, rec.Case_Number__c, rec); }
 
        for (Promotion_Account__c rec : [

            SELECT Id, Promotion_Rewards__c, Last_4__c, Case_Number__c FROM Promotion_Account__c
            WHERE Case_Number__c IN :caseIds

        ]) { addToMap(bd.permAccountByCaseId, rec.Case_Number__c, rec); }
 
        for (Promotion_Condition__c rec : [

            SELECT Id, Condition_Code__c, Promotion_account__c, Case_Number__c
            FROM Promotion_Condition__c WHERE Case_Number__c IN :caseIds

        ]) { addToMap(bd.permCondByCaseId, rec.Case_Number__c, rec); }
 
        for (Promotion_Rule_Set__c rec : [

            SELECT Id, Rule_Set_Code__c, Promotion_Condition__c, Case_Number__c
            FROM Promotion_Rule_Set__c WHERE Case_Number__c IN :caseIds

        ]) { addToMap(bd.permRuleSetByCaseId, rec.Case_Number__c, rec); }
 
        for (Promotion_Rule__c rec : [

            SELECT Id, Rule_Code__c, Promotion_Rule_Set__c, Case_Number__c
            FROM Promotion_Rule__c WHERE Case_Number__c IN :caseIds

        ]) { addToMap(bd.permRuleByCaseId, rec.Case_Number__c, rec); }
 
        for (Promotion_Rule_Progress__c rec : [

            SELECT Id, Promotion_Rule__c, Case_Number__c FROM Promotion_Rule_Progress__c
            WHERE Case_Number__c IN :caseIds

        ]) { addToMap(bd.permRuleProgByCaseId, rec.Case_Number__c, rec); }
 
        for (Promotion_Account_Transactions__c rec : [

            SELECT Id, Transaction_Reference_Id__c, Transaction_Reference_Id_2__c, Case_Number__c
            FROM Promotion_Account_Transactions__c WHERE Case_Number__c IN :caseIds

        ]) { addToMap(bd.permTxnByCaseId, rec.Case_Number__c, rec); }
 
        return bd;

    }
    private void initialize(Case relatedRecord, String logId, BulkData bd) {

        caseNumber        = relatedRecord.Id;
        transactionLogId  = logId;
        apiLog            = bd.logById.containsKey(logId)
                            ? new List<API_RADS_Transaction_Log__c>{ bd.logById.get(logId) }
                            : new List<API_RADS_Transaction_Log__c>();

        apiAccountRecords  = safeGet(bd.apiAccountByLogId, logId);
        apiTransactionList = safeGet(bd.apiTxnByLogId, logId);
        permTransactionList= safeGet(bd.permTxnByCaseId, relatedRecord.Id);
 
        // Collect log record for bulk update — not DMLd here

        if (!apiLog.isEmpty()) {

            logRecToUpdate = new API_RADS_Transaction_Log__c(Id = logId);
            logRecToUpdate.CaseNumber__c = relatedRecord.Id;
        }
 
        // Build dataSet via PromoXTreeCreatorService 

        try {

            dataSet = new PromoXTreeCreatorService().createDataSet(safeGet(bd.apiEnrollByLogId,    logId),
                safeGet(bd.permEnrollByCaseId,  relatedRecord.Id),safeGet(bd.apiRewardByLogId,    logId),
                safeGet(bd.permRewardByCaseId,  relatedRecord.Id),safeGet(bd.apiAccountByLogId,   logId),
                safeGet(bd.permAccountByCaseId, relatedRecord.Id),safeGet(bd.apiConditionByLogId, logId),
                safeGet(bd.permCondByCaseId,    relatedRecord.Id),safeGet(bd.apiRuleSetByLogId,   logId),
                safeGet(bd.permRuleSetByCaseId, relatedRecord.Id),safeGet(bd.apiRuleByLogId,      logId),
                safeGet(bd.permRuleByCaseId,    relatedRecord.Id),safeGet(bd.apiRuleProgByLogId,  logId),
                safeGet(bd.permRuleProgByCaseId,relatedRecord.Id));

        } catch (Exception e) {

            System.debug('PromoXTreeCreatorService failed for case ' + caseNumber
                         + ': ' + e.getMessage() + '\n' + e.getStackTraceString());
            dataSet = null;
            return;

        }
 
        if (dataSet == null) {
            System.debug('Dataset is null for case: ' + caseNumber);
            return;
        }

        for (Promotion_Enrollment__c rec : dataSet.enrollmentRecords) {
            enrollmentUpdates.put(rec.Offer_Code__c, rec);
        }

        for (Promotion_Rewards__c rec : dataSet.rewardRecords) {
            rewardUpdates.put(rec.Reward_Code__c, rec);
        }

        for (Promotion_Account__c rec : dataSet.AccountRecords) {
            accountUpdates.put(rec.Last_4__c, rec);
        }

        for (Promotion_Condition__c rec : dataSet.ConditionRecords) {
            conditionsUpdates.put(rec.Condition_Code__c, rec);
        }

        for (Promotion_Rule_Set__c rec : dataSet.RuleSetRecords) {
            promotionRuleSetUpdates.put(rec.Rule_Set_Code__c, rec);
        }

        for (Promotion_Rule__c rec : dataSet.rulesRecords) {
            ruleCrossUpdates.put(rec.Rule_Code__c, rec);
        }

        for (Promotion_Rule_Progress__c rec : dataSet.ruleProgressRecords) {
            ruleProgressUpdates.put(rec.Promotion_Rule__c, rec);
        }

    }
 
    public Boolean isReady() {

        return dataSet != null;

    }
 
 public void buildEnrollments() {

        if (!isReady()) return;

        for (API_Promotion_Enrollment__c iRecord : dataSet.apiEnrollemtRecords) {

            String existingId = enrollmentUpdates.containsKey(iRecord.Offer_Code__c)
                ? enrollmentUpdates.get(iRecord.Offer_Code__c).Id : null;
            enrollmentCrossRecords.put(iRecord.Id, createEnrollment(iRecord, existingId));

        }

    }
 
    public void buildRewards() {

        if (!isReady()) return;

        for (API_Promotion_Rewards__c iRecord : dataSet.apiRewardRecords) {

            String existingId = rewardUpdates.containsKey(iRecord.Reward_Code__c)
                ? rewardUpdates.get(iRecord.Reward_Code__c).Id : null;
            rewardCrossRecords.put(iRecord.Id, createReward(iRecord, existingId));

        }

       

        for (API_Account__c accRecord : apiAccountRecords) {

            Promotion_Rewards__c reward = rewardCrossRecords.get(accRecord.API_Promotion_Rewards__c);

            if (reward != null) {

                reward.Reward_Account__c = accRecord.Last_4__c;

            } else {

                System.debug('Warning: No reward cross-record for account: ' + accRecord.Id);

            }

        }

    }
 
    public void buildAccounts() {

        if (!isReady()) return;

        for (API_Account__c iRecord : apiAccountRecords) {

            String existingId = accountUpdates.containsKey(iRecord.Last_4__c)
                ? accountUpdates.get(iRecord.Last_4__c).Id : null;
            accountCrossRecords.put(iRecord.Id, createAccount(iRecord, existingId));

        }

    }
 
    public void buildConditions() {

        if (!isReady()) return;

        for (API_Promotion_Conditions__c iRecord : dataSet.apiConditionRecords) {

            String existingId = conditionsUpdates.containsKey(iRecord.Condition_Code__c)
                ? conditionsUpdates.get(iRecord.Condition_Code__c).Id : null;
            conditionsCrossRecords.put(iRecord.Id, createCondition(iRecord, existingId));

        }

    }
 
    public void buildRuleSets() {

        if (!isReady()) return;

        for (API_Promotion_Rule_Set__c iRecord : dataSet.apiRuleSetRecords) {
            String existingId = promotionRuleSetUpdates.containsKey(iRecord.Rule_Set_Code__c)
                ? promotionRuleSetUpdates.get(iRecord.Rule_Set_Code__c).Id : null;
            promotionRuleSetCrossRecords.put(iRecord.Id, createRuleSet(iRecord, existingId));

        }

    }
 
    public void buildRules() {

        if (!isReady()) return;

        for (API_Promotion_Rules__c iRecord : dataSet.apiRrulesRecords) {
            String existingId = ruleCrossUpdates.containsKey(iRecord.Rule_Code__c)
                ? ruleCrossUpdates.get(iRecord.Rule_Code__c).Id : null;
            ruleCrossRecords.put(iRecord.Id, createRuleRecord(iRecord, existingId));

        }

    }
 
    public void buildRuleProgress() {

        if (!isReady()) return;

        for (API_Promotion_Rule_Progress__c iRecord : dataSet.apiRuleProgressRecords) {
            String existingId = ruleCrossUpdates.containsKey(iRecord.API_Promotion_Rules__c)
                ? ruleCrossUpdates.get(iRecord.API_Promotion_Rules__c).Id : null;
            ruleProgressCrossRecords.put(iRecord.Id, createProgressRecord(iRecord, existingId));

        }

    }
 
    public void buildTransactions() {

        if (!isReady()) return;

        Map<String,Promotion_Account_Transactions__c> existingRecordMap =
            new Map<String,Promotion_Account_Transactions__c>();

        for (Promotion_Account_Transactions__c record : permTransactionList) {
            if (record.Transaction_Reference_Id_2__c != null) {
                existingRecordMap.put(record.Transaction_Reference_Id_2__c, record);

            }

        }

        for (API_Promotion_Account_Transactions__c newRecord : apiTransactionList) {

            Promotion_Account_Transactions__c toSave = createTransactionRecord(newRecord);

            if (toSave == null) continue;

            if (existingRecordMap.containsKey(newRecord.Transaction_Reference_Id_2__c)) {
                toSave.Id = existingRecordMap.get(newRecord.Transaction_Reference_Id_2__c).Id;
                txnToUpdate.add(toSave);

            } else {
                txnToInsert.add(toSave);

            }

        }

    }
 

    private Promotion_Enrollment__c createEnrollment(API_Promotion_Enrollment__c apiRecord, String existingRecordId) {

        Promotion_Enrollment__c newRecord = dataSet.apiPermRecordsMap.containsKey(apiRecord.Id)
            ? new Promotion_Enrollment__c(Id = dataSet.apiPermRecordsMap.get(apiRecord.Id))
            : new Promotion_Enrollment__c();
 
        newRecord.Account_Enrolled__c              = apiRecord.Account_Last_4__c;
        newRecord.Account_Type__c                  = apiRecord.Account_Type__c;
        newRecord.API_RADS_Transaction_Log__c      = apiRecord.API_RADS_Transaction_Log__c;
        newRecord.Case_Number__c                   = caseNumber;
        newRecord.CIF__c                           = apiRecord.CIF__c;
        newRecord.Enroll_Teammate_Id__c            = apiRecord.Enroll_Teammate_Id__c;
        newRecord.Enrollment_Channel__c            = apiRecord.Enrollment_Channel__c;
        newRecord.Enrollment_Date__c               = apiRecord.Enrollment_Date__c;
        newRecord.Enrollment_Flag__c               = apiRecord.Enrollment_Flag__c;
        newRecord.Offer_Code__c                    = apiRecord.Offer_Code__c;
        newRecord.Offer_Description__c             = apiRecord.Offer_Description__c;
        newRecord.Offer_Name__c                    = apiRecord.Offer_Name__c;
        newRecord.Offer_Status__c                  = apiRecord.Offer_Status__c;
        newRecord.Offer_Type__c                    = apiRecord.Offer_Type__c;
        newRecord.Promo_Code__c                    = apiRecord.Promo_Code__c;
        newRecord.Promo_End_Date__c                = apiRecord.Promo_End_Date__c;
        newRecord.Promo_Start_Date__c              = apiRecord.Promo_Start_Date__c;
        newRecord.T_C_Client_Accepted_Timestamp__c = apiRecord.T_C_Client_Accepted_Timestamp__c;
        newRecord.T_C_PDF_link__c                  = apiRecord.T_C_PDF_link__c;
        newRecord.Force_Enrollment_Case_Number__c  = apiRecord.Force_Enroll_Case_Number__c;

        if (!apiLog.isEmpty()) {

            newRecord.RADS_Last_Update_Date__c = apiLog[0].RADS_Last_Update__c;
            newRecord.Error_Code__c            = apiLog[0].Error_Code__c;
            newRecord.Error_Message__c         = apiLog[0].Error_Message__c;

        }

        return newRecord;

    }
 
    private Promotion_Rewards__c createReward(API_Promotion_Rewards__c apiRecordpr, String existingRecordId) {
        Promotion_Rewards__c newRecordpr = dataSet.apiPermRecordsMap.containsKey(apiRecordpr.Id)
            ? new Promotion_Rewards__c(Id = dataSet.apiPermRecordsMap.get(apiRecordpr.Id))
            : new Promotion_Rewards__c();
 
        newRecordpr.Case_Number__c              = caseNumber;
        newRecordpr.API_RADS_Transaction_Log__c = apiRecordpr.API_RADS_Transaction_Log__c;
        newRecordpr.Force_Payout_Flag__c        = apiRecordpr.Force_Payout_Flag__c;
        newRecordpr.Reverse_Notes__c            = apiRecordpr.Reverse_Notes__c;
        newRecordpr.Reward_Account__c           = apiRecordpr.Reward_Account__c;
        newRecordpr.Reward_Code__c              = apiRecordpr.Reward_Code__c;
        newRecordpr.Reward_Description__c       = apiRecordpr.Reward_Description__c;
        newRecordpr.Reward_Mailing_Date__c      = apiRecordpr.Reward_Mailing_Date__c;
        newRecordpr.Reward_Name__c              = apiRecordpr.Reward_Name__c;
        newRecordpr.Reward_Payment_Amount__c    = apiRecordpr.Reward_Payment_Amount__c;
        newRecordpr.Reward_Payment_Date__c      = apiRecordpr.Reward_Payment_Date__c;
        newRecordpr.Reward_Reversal_Flag__c     = apiRecordpr.Reward_Reversal_Flag__c;
        newRecordpr.Reward_Status__c            = apiRecordpr.Reward_Status__c;
        newRecordpr.Reward_Total_Amount_Paid__c = apiRecordpr.Reward_Total_Amount_Paid__c;
        newRecordpr.Reward_Type__c              = apiRecordpr.Reward_Type__c;
        newRecordpr.Reward_Value_Type__c        = apiRecordpr.Reward_Value_Type__c;

        

        Promotion_Enrollment__c parentEnrollment = enrollmentCrossRecords.get(apiRecordpr.API_Promotion_Enrollment__c);

        if (parentEnrollment != null) {

            newRecordpr.Promotion_Enrollment_Number__c = parentEnrollment.Id;

        } else {
            System.debug('Warning: No enrollment cross-record for reward: ' + apiRecordpr.Id);
        }

        return newRecordpr;

    }
 
    private Promotion_Account__c createAccount(API_Account__c apiRecord, String existingRecordId) {

        Promotion_Account__c newRecord = dataSet.apiPermRecordsMap.containsKey(apiRecord.Id)

            ? new Promotion_Account__c(Id = dataSet.apiPermRecordsMap.get(apiRecord.Id))

            : new Promotion_Account__c();
 
        newRecord.Case_Number__c              = caseNumber;
        newRecord.Account_Type__c             = apiRecord.Account_Type__c;
        newRecord.API_RADS_Transaction_Log__c = apiRecord.API_RADS_Transaction_Log__c;
        newRecord.Last_4__c                   = apiRecord.Last_4__c;

      

        Promotion_Rewards__c parentReward = rewardCrossRecords.get(apiRecord.API_Promotion_Rewards__c);

        if (parentReward != null) {

            newRecord.Promotion_Rewards__c = parentReward.Id;

        } else {
            System.debug('Warning: No reward cross-record for account: ' + apiRecord.Id);
        }

        return newRecord;

    }
 
    private Promotion_Condition__c createCondition(API_Promotion_Conditions__c apiRecord, String existingRecordId) {

        Promotion_Condition__c newRecord = dataSet.apiPermRecordsMap.containsKey(apiRecord.Id)

            ? new Promotion_Condition__c(Id = dataSet.apiPermRecordsMap.get(apiRecord.Id))

            : new Promotion_Condition__c();
 
        newRecord.API_RADS_Transaction_Log__c = apiRecord.API_RADS_Transaction_Log__c;

        newRecord.Case_Number__c              = caseNumber;
        newRecord.Condition_Code__c           = apiRecord.Condition_Code__c;
        newRecord.Condition_Description__c    = apiRecord.Condition_Description__c;
        newRecord.Condition_Met__c            = apiRecord.Condition_Met__c;
        newRecord.Condition_Name__c           = apiRecord.Condition_Name__c;

    

        Promotion_Account__c parentAccount = accountCrossRecords.get(apiRecord.API_Account__c);

        if (parentAccount != null) {

            newRecord.Promotion_account__c = parentAccount.Id;

        } else {
            System.debug('Warning: No account cross-record for condition: ' + apiRecord.Id);
        }

        return newRecord;

    }
 
    private Promotion_Rule_Set__c createRuleSet(API_Promotion_Rule_Set__c apiRecord, String existingRecordId) {

        Promotion_Rule_Set__c newRecord = dataSet.apiPermRecordsMap.containsKey(apiRecord.Id)

            ? new Promotion_Rule_Set__c(Id = dataSet.apiPermRecordsMap.get(apiRecord.Id))

            : new Promotion_Rule_Set__c();
 
        newRecord.Case_Number__c              = caseNumber;

        newRecord.API_RADS_Transaction_Log__c = apiRecord.API_RADS_Transaction_Log__c;

        newRecord.Rule_Set_Code__c            = apiRecord.Rule_Set_Code__c;

        // Parent condition ID — available because Phase 4 upsert has already fired

        Promotion_Condition__c parentCondition = conditionsCrossRecords.get(apiRecord.API_Promotion_Conditions__c);

        if (parentCondition != null) {

            newRecord.Promotion_Condition__c = parentCondition.Id;

        } else {

            System.debug('Warning: No condition cross-record for rule set: ' + apiRecord.Id);

        }

        return newRecord;

    }
 
    private Promotion_Rule__c createRuleRecord(API_Promotion_Rules__c apiRecord, String existingRecordId) {

        Promotion_Rule__c newRecord = dataSet.apiPermRecordsMap.containsKey(apiRecord.Id)

            ? new Promotion_Rule__c(Id = dataSet.apiPermRecordsMap.get(apiRecord.Id))

            : new Promotion_Rule__c();
 
        newRecord.Case_Number__c              = caseNumber;
        newRecord.API_RADS_Transaction_Log__c = apiRecord.API_RADS_Transaction_Log__c;
        newRecord.Progress_Type__c            = apiRecord.Progress_Type__c;
        newRecord.Rule_Code__c                = apiRecord.Rule_Code__c;
        newRecord.Rule_Description__c         = apiRecord.Rule_Description__c;
        newRecord.Rule_Name__c                = apiRecord.Rule_Name__c;
        newRecord.Target_Value__c             = apiRecord.Target_Value__c;

        // Parent rule set ID — available because Phase 5 upsert has already fired

        Promotion_Rule_Set__c parentRuleSet = promotionRuleSetCrossRecords.get(apiRecord.API_Promotion_Rule_Set__c);

        if (parentRuleSet != null) {

            newRecord.Promotion_Rule_Set__c = parentRuleSet.Id;

        } else {

            System.debug('Warning: No rule set cross-record for rule: ' + apiRecord.Id);

        }

        return newRecord;

    }
 
    private Promotion_Rule_Progress__c createProgressRecord(API_Promotion_Rule_Progress__c apiRecord, String existingRecordId) {

        Promotion_Rule_Progress__c newRecord = dataSet.apiPermRecordsMap.containsKey(apiRecord.Id)

            ? new Promotion_Rule_Progress__c(Id = dataSet.apiPermRecordsMap.get(apiRecord.Id))

            : new Promotion_Rule_Progress__c();
 
        newRecord.Actual_Value__c             = apiRecord.Actual_Value__c;
        newRecord.Case_Number__c              = caseNumber;
        newRecord.Evaluation_End_Date__c      = apiRecord.Evaluation_End_Date__c;
        newRecord.Evaluation_Start_Date__c    = apiRecord.Evaluation_Start_Date__c;
        newRecord.Rule_Details__c             = apiRecord.Rule_Details__c;
        newRecord.Rule_Pass_Flag__c           = apiRecord.Rule_Pass_Flag__c;
        newRecord.Rule_Passed_Date__c         = apiRecord.Rule_Passed_Date__c;
        newRecord.API_RADS_Transaction_Log__c = apiRecord.API_RADS_Transaction_Log__c;

        // Parent rule ID — available because Phase 6 upsert has already fired

        Promotion_Rule__c parentRule = ruleCrossRecords.get(apiRecord.API_Promotion_Rules__c);

        if (parentRule != null) {

            newRecord.Promotion_Rule__c = parentRule.Id;

        } else {

            System.debug('Warning: No rule cross-record for rule progress: ' + apiRecord.Id);

        }

        return newRecord;

    }
 
    private Promotion_Account_Transactions__c createTransactionRecord(API_Promotion_Account_Transactions__c iRecord) {

        // Parent rule progress ID — available because Phase 7 upsert has already fired

        Promotion_Rule_Progress__c ruleProgress = ruleProgressCrossRecords.get(iRecord.API_Promotion_Rule_progress__c);

        if (ruleProgress == null) {

            System.debug('Warning: No rule progress cross-record for transaction: ' + iRecord.Id + '. Skipping.');

            return null;

        }

        Promotion_Account_Transactions__c resultRecord = new Promotion_Account_Transactions__c();

        resultRecord.API_RADS_Transaction_Log__c       = iRecord.API_RADS_Transaction_Log__c;
        resultRecord.Case_Number__c                    = caseNumber;
        resultRecord.Promotion_Rule_Progress__c        = ruleProgress.Id;
        resultRecord.Transaction_Amount__c             = iRecord.Transaction_Amount__c;
        resultRecord.Transaction_Channel__c            = iRecord.Transaction_Channel__c;
        resultRecord.Transaction_Code__c               = iRecord.Transaction_Code__c;
        resultRecord.Transaction_Currency__c           = iRecord.Transaction_Currency__c;
        resultRecord.Transaction_Date__c               = iRecord.Transaction_Date__c;
        resultRecord.Transaction_Debit_Credit_Code__c  = iRecord.Transaction_Debit_Credit_Code__c;
        resultRecord.Transaction_Reference_Id__c       = iRecord.Transaction_Reference_Id__c;
        resultRecord.Transaction_Reference_Id_2__c     = iRecord.Transaction_Reference_Id_2__c;
        return resultRecord;

    }
 
// addToMap
    private static void addToMap(Map<String,List<API_Promotion_Enrollment__c>> m, String k, API_Promotion_Enrollment__c r) {
        if (!m.containsKey(k)) m.put(k, new List<API_Promotion_Enrollment__c>()); m.get(k).add(r);
    }
    private static void addToMap(Map<String,List<API_Promotion_Rewards__c>> m, String k, API_Promotion_Rewards__c r) {
        if (!m.containsKey(k)) m.put(k, new List<API_Promotion_Rewards__c>()); m.get(k).add(r);
    }
    private static void addToMap(Map<String,List<API_Account__c>> m, String k, API_Account__c r) {
        if (!m.containsKey(k)) m.put(k, new List<API_Account__c>()); m.get(k).add(r);
    }
    private static void addToMap(Map<String,List<API_Promotion_Conditions__c>> m, String k, API_Promotion_Conditions__c r) {
        if (!m.containsKey(k)) m.put(k, new List<API_Promotion_Conditions__c>()); m.get(k).add(r);
    }
    private static void addToMap(Map<String,List<API_Promotion_Rule_Set__c>> m, String k, API_Promotion_Rule_Set__c r) {
        if (!m.containsKey(k)) m.put(k, new List<API_Promotion_Rule_Set__c>()); m.get(k).add(r);
    }
    private static void addToMap(Map<String,List<API_Promotion_Rules__c>> m, String k, API_Promotion_Rules__c r) {
        if (!m.containsKey(k)) m.put(k, new List<API_Promotion_Rules__c>()); m.get(k).add(r);
    }
    private static void addToMap(Map<String,List<API_Promotion_Rule_Progress__c>> m, String k, API_Promotion_Rule_Progress__c r) {
        if (!m.containsKey(k)) m.put(k, new List<API_Promotion_Rule_Progress__c>()); m.get(k).add(r);
    }
    private static void addToMap(Map<String,List<API_Promotion_Account_Transactions__c>> m, String k, API_Promotion_Account_Transactions__c r) {
        if (!m.containsKey(k)) m.put(k, new List<API_Promotion_Account_Transactions__c>()); m.get(k).add(r);
    }
    private static void addToMap(Map<Id,List<Promotion_Enrollment__c>> m, Id k, Promotion_Enrollment__c r) {
        if (!m.containsKey(k)) m.put(k, new List<Promotion_Enrollment__c>()); m.get(k).add(r);
    }
    private static void addToMap(Map<Id,List<Promotion_Rewards__c>> m, Id k, Promotion_Rewards__c r) {
        if (!m.containsKey(k)) m.put(k, new List<Promotion_Rewards__c>()); m.get(k).add(r);
    }
    private static void addToMap(Map<Id,List<Promotion_Account__c>> m, Id k, Promotion_Account__c r) {
        if (!m.containsKey(k)) m.put(k, new List<Promotion_Account__c>()); m.get(k).add(r);
    }
    private static void addToMap(Map<Id,List<Promotion_Condition__c>> m, Id k, Promotion_Condition__c r) {
        if (!m.containsKey(k)) m.put(k, new List<Promotion_Condition__c>()); m.get(k).add(r);
    }
    private static void addToMap(Map<Id,List<Promotion_Rule_Set__c>> m, Id k, Promotion_Rule_Set__c r) {
        if (!m.containsKey(k)) m.put(k, new List<Promotion_Rule_Set__c>()); m.get(k).add(r);
    }
    private static void addToMap(Map<Id,List<Promotion_Rule__c>> m, Id k, Promotion_Rule__c r) {
        if (!m.containsKey(k)) m.put(k, new List<Promotion_Rule__c>()); m.get(k).add(r);
    }
    private static void addToMap(Map<Id,List<Promotion_Rule_Progress__c>> m, Id k, Promotion_Rule_Progress__c r) {
        if (!m.containsKey(k)) m.put(k, new List<Promotion_Rule_Progress__c>()); m.get(k).add(r);
    }
    private static void addToMap(Map<Id,List<Promotion_Account_Transactions__c>> m, Id k, Promotion_Account_Transactions__c r) {
        if (!m.containsKey(k)) m.put(k, new List<Promotion_Account_Transactions__c>()); m.get(k).add(r);
    }
 
    // safeGet
    private static List<API_Promotion_Enrollment__c> safeGet(Map<String,List<API_Promotion_Enrollment__c>> m, String k) {
        return m.containsKey(k) ? m.get(k) : new List<API_Promotion_Enrollment__c>();
    }

    private static List<API_Promotion_Rewards__c> safeGet(Map<String,List<API_Promotion_Rewards__c>> m, String k) {
        return m.containsKey(k) ? m.get(k) : new List<API_Promotion_Rewards__c>();
    }
    private static List<API_Account__c> safeGet(Map<String,List<API_Account__c>> m, String k) {
        return m.containsKey(k) ? m.get(k) : new List<API_Account__c>();
    }
    private static List<API_Promotion_Conditions__c> safeGet(Map<String,List<API_Promotion_Conditions__c>> m, String k) {
        return m.containsKey(k) ? m.get(k) : new List<API_Promotion_Conditions__c>();
    }
    private static List<API_Promotion_Rule_Set__c> safeGet(Map<String,List<API_Promotion_Rule_Set__c>> m, String k) {
        return m.containsKey(k) ? m.get(k) : new List<API_Promotion_Rule_Set__c>();
    }
    private static List<API_Promotion_Rules__c> safeGet(Map<String,List<API_Promotion_Rules__c>> m, String k) {

        return m.containsKey(k) ? m.get(k) : new List<API_Promotion_Rules__c>();
    }

    private static List<API_Promotion_Rule_Progress__c> safeGet(Map<String,List<API_Promotion_Rule_Progress__c>> m, String k) {
        return m.containsKey(k) ? m.get(k) : new List<API_Promotion_Rule_Progress__c>();
    }

    private static List<API_Promotion_Account_Transactions__c> safeGet(Map<String,List<API_Promotion_Account_Transactions__c>> m, String k) {
        return m.containsKey(k) ? m.get(k) : new List<API_Promotion_Account_Transactions__c>();
    }

    private static List<Promotion_Enrollment__c> safeGet(Map<Id,List<Promotion_Enrollment__c>> m, Id k) {
        return m.containsKey(k) ? m.get(k) : new List<Promotion_Enrollment__c>();

    }
    private static List<Promotion_Rewards__c> safeGet(Map<Id,List<Promotion_Rewards__c>> m, Id k) {
        return m.containsKey(k) ? m.get(k) : new List<Promotion_Rewards__c>();
    }

    private static List<Promotion_Account__c> safeGet(Map<Id,List<Promotion_Account__c>> m, Id k) {
        return m.containsKey(k) ? m.get(k) : new List<Promotion_Account__c>();
    }

    private static List<Promotion_Condition__c> safeGet(Map<Id,List<Promotion_Condition__c>> m, Id k) {
        return m.containsKey(k) ? m.get(k) : new List<Promotion_Condition__c>();
    }

    private static List<Promotion_Rule_Set__c> safeGet(Map<Id,List<Promotion_Rule_Set__c>> m, Id k) {
        return m.containsKey(k) ? m.get(k) : new List<Promotion_Rule_Set__c>();
    }

    private static List<Promotion_Rule__c> safeGet(Map<Id,List<Promotion_Rule__c>> m, Id k) {
        return m.containsKey(k) ? m.get(k) : new List<Promotion_Rule__c>();
    }

    private static List<Promotion_Rule_Progress__c> safeGet(Map<Id,List<Promotion_Rule_Progress__c>> m, Id k) {
        return m.containsKey(k) ? m.get(k) : new List<Promotion_Rule_Progress__c>();
    }

    private static List<Promotion_Account_Transactions__c> safeGet(Map<Id,List<Promotion_Account_Transactions__c>> m, Id k) {
        return m.containsKey(k) ? m.get(k) : new List<Promotion_Account_Transactions__c>();
    }

}