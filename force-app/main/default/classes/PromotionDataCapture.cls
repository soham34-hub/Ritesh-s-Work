public class PromotionDataCapture {
    Public Static String transactionLogId; //will gewt back from lexi code
    Public Static String caseNumber; //get from launch screen or trigger context 
    Public Static String operation = '';
    Public Static PromoXTreeCreator.dataSet dataSet = new PromoXTreeCreator.dataSet();
    Public Static List<API_RADS_Transaction_Log__c> apiLog = new List<API_RADS_Transaction_Log__c>();
    
    Public Static Map<String,Promotion_Enrollment__c> enrollmentCrossRecords = new MAP<String,Promotion_Enrollment__c>();
    Public Static Map<String,Promotion_Rewards__c> rewardCrossRecords = new MAP<String,Promotion_Rewards__c>();
    Public Static Map<String,Promotion_Account__c> accountCrossRecords = new MAP<String,Promotion_Account__c>();
    Public Static Map<String,Promotion_Condition__c> conditionsCrossRecords = new MAP<String,Promotion_Condition__c>();
    Public Static Map<String,Promotion_Rule_Set__c> promotionRuleSetCrossRecords = new MAP<String,Promotion_Rule_Set__c>(); 
    Public Static Map<String,Promotion_Rule__c> ruleCrossRecords = new MAP<String,Promotion_Rule__c>();
    Public Static Map<String,Promotion_Rule_Progress__c> ruleProgressCrossRecords = new MAP<String,Promotion_Rule_Progress__c>();
    Public Static Map<String,Promotion_Account_Transactions__c> transactionsCrossRecords = new MAP<String,Promotion_Account_Transactions__c>();

    Public Static Map<String,Promotion_Enrollment__c> enrollmentUpdates = new MAP<String,Promotion_Enrollment__c>(); 
    Public Static Map<String,Promotion_Rewards__c> rewardUpdates = new MAP<String,Promotion_Rewards__c>();
    Public Static Map<String,Promotion_Account__c> accountUpdates = new MAP<String,Promotion_Account__c>();
    Public Static Map<String,Promotion_Condition__c> conditionsUpdates = new MAP<String,Promotion_Condition__c>();
    Public Static Map<String,Promotion_Rule_Set__c> promotionRuleSetUpdates = new MAP<String,Promotion_Rule_Set__c>();
    Public Static Map<String,Promotion_Rule__c> ruleCrossUpdates = new MAP<String,Promotion_Rule__c>();
    Public Static Map<String,Promotion_Rule_Progress__c> ruleProgressUpdates = new MAP<String,Promotion_Rule_Progress__c>();
  
    Public Static List<API_Account__c> apiAccountRecords = new List<API_Account__c>();
	Public Static Map<String,API_Account__c> relatedAccountRecords = new MAP<String,API_Account__c>();
    /*
    public static void processRecordsorg(case relatedrecord,String logId){ //List<inputData> caseData){
	    apiLog = [SELECT Id , RADS_Last_Update__c , Error_Code__c, Error_Message__c FROM API_RADS_Transaction_Log__c
                 WHERE id =: logId];
       // system.debug('$$$$$$$$$$$$$$$$$$ show log data : ' + apiLog[0]);
        caseNumber = relatedrecord.Id; //caseData[0].caseData.Id;
        operation = 'Insert'; //caseData[0].operation;
        transactionLogId = logId;//use case data to find related log ? caseData[0].logId;//caseData[0].caseData.API_RADS_Transaction_Log__c;
        system.debug('creating transaction log with id ' + transactionLogId);   
        API_RADS_Transaction_Log__c logRec = new API_RADS_Transaction_Log__c(id =logId );
        logRec.CaseNumber__c = relatedrecord.Id;
        update(logRec);
        apiAccountRecords = getAccounts();
        dataSet = PromoXTreeCreator.createDataSet(caseNumber,transactionLogId);
        system.debug('running promo data   case num   : ' + caseNumber + '       tl id' + transactionLogId);
        enrollment();
        rewards();
        accounts();
        conditions();
        ruleSets();
        rules();
        ruleProgress();
        transactions();
    }*/
// nvk new method
    public static void processRecords(Case relatedrecord, String logId) {
        if (relatedrecord == null) {
            System.debug('Related record is null');
            return;
        }
        if (logId != null) {
            apiLog = [
                SELECT Id , RADS_Last_Update__c , Error_Code__c, Error_Message__c FROM API_RADS_Transaction_Log__c
                WHERE id =:logId
            ];
        }
        caseNumber = relatedrecord.Id; //caseData[0].caseData.Id;
        operation = 'Insert'; //caseData[0].operation;
        transactionLogId = logId;
        System.debug('Processing case: ' + caseNumber + ' | logId: ' + transactionLogId);
        if (!apiLog.isEmpty()) {
            System.debug('Log data: ' + apiLog[0]);
            try {
                API_RADS_Transaction_Log__c logRec = new API_RADS_Transaction_Log__c(id =logId );
                logRec.CaseNumber__c = relatedrecord.Id;
                update(logRec);
            } catch (Exception e) {
                System.debug('Log update failed: ' + e.getMessage());
            }
        }
        try {
        apiAccountRecords = getAccounts();
            dataSet = PromoXTreeCreator.createDataSet(caseNumber,transactionLogId);
            system.debug('running promo data   case num   : ' + caseNumber + '       tl id' + transactionLogId);
            if (dataSet != null) {
            enrollment();
            rewards();
            accounts();
            conditions();
            ruleSets();
            rules();
            ruleProgress();
            transactions();
            } else {
                System.debug('Dataset is null, skipping processing');
                return;
            }
        } catch (Exception e) {
            System.debug('getAccounts failed: ' + e.getMessage());
        }
    }
// end
    
    public static void enrollment(){
       List<API_Promotion_Enrollment__c> apiRecords = new List<API_Promotion_Enrollment__c>();
       List<Promotion_Enrollment__c> permRecords = new List<Promotion_Enrollment__c>();
       permRecords = dataSet.enrollmentRecords;
       apiRecords =  dataSet.apiEnrollemtRecords;
        
        for(Promotion_Enrollment__c record : permRecords){   
            system.debug('Existing enrollment record foud with offer code:' + record.id + ' : ' + record.Offer_Code__c);    
            enrollmentUpdates.put(record.Offer_Code__c,record);
        }
        
        for(API_Promotion_Enrollment__c iRecord : apiRecords){
          system.debug('Existing API enrollment record foud with offer code:' + iRecord.id + ' : ' + iRecord.Offer_Code__c);    		 
    
            if(enrollmentUpdates.containsKey(iRecord.Offer_Code__c)){
            	enrollmentCrossRecords.put(iRecord.Id,createEnrollment(iRecord,enrollmentUpdates.get(iRecord.Offer_Code__c).Id));
            }else{
            	enrollmentCrossRecords.put(iRecord.Id,createEnrollment(iRecord,null));
            }
        upsert enrollmentCrossRecords.values();
    }
}
    public static void rewards(){
    	List<API_Promotion_Rewards__c> apiRecords = new List<API_Promotion_Rewards__c>();
        List<Promotion_Rewards__c> permRecords = new List<Promotion_Rewards__c>();
        permRecords = dataSet.rewardRecords;
        apiRecords = dataSet.apiRewardRecords;
        
        for(Promotion_Rewards__c record : permRecords){   
           //using offer code to controll updates
           system.debug('Existing Reward record foud with reward code:' + record.id + ' : ' + record.Reward_Code__c); 
    		rewardUpdates.put(record.Reward_Code__c,record);
        }
         for(API_Promotion_Rewards__c iRecord : apiRecords){
            if(rewardUpdates.containsKey(iRecord.Reward_Code__c)){
                system.debug('API Reward record foud with reward code:' + iRecord.id + ' : ' + iRecord.Reward_Code__c); 
            	rewardCrossRecords.put(iRecord.Id,createReward(iRecord,rewardUpdates.get(iRecord.Reward_Code__c).Id));
            }else{
            	rewardCrossRecords.put(iRecord.Id,createReward(iRecord,null));
            }
        }
         for(API_Account__c accRecord :apiAccountRecords){ // probably needs to be fixed?
             rewardCrossRecords.get(accRecord.API_Promotion_Rewards__c).Reward_Account__c = accRecord.Last_4__c;
         }
        upsert rewardCrossRecords.values();
    }     
    public static void accounts(){
    	List<Promotion_Account__c> permRecords = new List<Promotion_Account__c>();
        permRecords = dataSet.accountRecords;
        for(Promotion_Account__c record : permRecords){   
    		 accountUpdates.put(record.Last_4__c,record);
        }
        for(API_Account__c iRecord : apiAccountRecords){
            if(accountUpdates.containsKey(iRecord.Last_4__c)){
            	accountCrossRecords.put(iRecord.Id,createAccount(iRecord,accountUpdates.get(iRecord.Last_4__c).Id));
            }else{
            	accountCrossRecords.put(iRecord.Id,createAccount(iRecord,null));
            }
        }
        if(permRecords == null || permRecords.isEmpty()){
           upsert accountCrossRecords.values();
        }
        
    }     
    public static void conditions(){
    	List<API_Promotion_Conditions__c> apiRecords = new List<API_Promotion_Conditions__c>();
    	List<Promotion_Condition__c> permRecords = new List<Promotion_Condition__c>();
        permRecords = dataSet.conditionRecords;
        apiRecords = dataSet.apiConditionRecords;

        for(Promotion_Condition__c record : permRecords){   
        system.debug('Existing Condition record foud with Condition code:' + record.id + ' : ' + record.Condition_Code__c); 

    		 conditionsUpdates.put(record.Condition_Code__c,record);
        }
        
        for(API_Promotion_Conditions__c iRecord : apiRecords){
                 system.debug('API Condition record foud with Condition code:' + iRecord.id + ' : ' + iRecord.Condition_Code__c); 
   
            if(conditionsUpdates.containsKey(iRecord.Condition_Code__c)){
            	conditionsCrossRecords.put(iRecord.Id,createCondition(iRecord,conditionsUpdates.get(iRecord.Condition_Code__c).Id));
            }else{
            	conditionsCrossRecords.put(iRecord.Id,createCondition(iRecord,null));
            }
        }
        upsert conditionsCrossRecords.values();
    }     
    public static void ruleSets(){
    	List<API_Promotion_Rule_Set__c> apiRecords = new List<API_Promotion_Rule_Set__c>();
		List<Promotion_Rule_Set__c> permRecords = new List<Promotion_Rule_Set__c>();
        permRecords = dataSet.RuleSetRecords;
        apiRecords  = dataSet.apiRuleSetRecords;
        for(Promotion_Rule_Set__c record : permRecords){   
          system.debug('Existing Rule Set record foud with ruleset code code:' + record.id + ' : ' + record.Rule_Set_Code__c); 

    		 promotionRuleSetUpdates.put(record.Rule_Set_Code__c,record);
        }
        
        for(API_Promotion_Rule_Set__c iRecord : apiRecords){
            system.debug('API Rule Set record foud with ruleset code code:' +  iRecord.id + ' : ' + iRecord.Rule_Set_Code__c); 
   
            if(promotionRuleSetUpdates.containsKey(iRecord.Rule_Set_Code__c)){
            	promotionRuleSetCrossRecords.put(iRecord.Id,createRuleSet(iRecord,promotionRuleSetUpdates.get(iRecord.Rule_Set_Code__c).Id));
            }else{
            	promotionRuleSetCrossRecords.put(iRecord.Id,createRuleSet(iRecord,null));
            }
        }
        upsert promotionRuleSetCrossRecords.values();
    } 
    public static void rules(){
    	List<API_Promotion_Rules__c> apiRecords = new List<API_Promotion_Rules__c>();
		List<Promotion_Rule__c> permRecords = new List<Promotion_Rule__c>();
        permRecords = dataSet.RulesRecords;
        apiRecords  = dataSet.apiRrulesRecords;
        for(Promotion_Rule__c record : permRecords){   
        	//using Rule_Code__c to controll updates
        	system.debug('Existing Rule record foud with Rule_Code__c code code:' + record.id + ' : ' + record.Rule_Code__c); 

    		 ruleCrossUpdates.put(record.Rule_Code__c,record);
        }
        
        for(API_Promotion_Rules__c iRecord : apiRecords){
                    	system.debug('API Rule record foud with Rule_Code__c code code:' + iRecord.id + ' : ' + iRecord.Rule_Code__c); 

            if(ruleCrossUpdates.containsKey(iRecord.Rule_Code__c)){
            	ruleCrossRecords.put(iRecord.Id,createRuleRecord(iRecord,ruleCrossUpdates.get(iRecord.Rule_Code__c).Id));
            }else{
            	ruleCrossRecords.put(iRecord.Id,createRuleRecord(iRecord,null));
            }
        }
        upsert ruleCrossRecords.values();
    } 
    public static void ruleProgress(){
        List<API_Promotion_Rule_Progress__c> apiRecords = new List<API_Promotion_Rule_Progress__c>();
  		List<Promotion_Rule_Progress__c> permRecords = new List<Promotion_Rule_Progress__c>();
        permRecords = dataSet.RuleProgressRecords;
        apiRecords = dataset.apiRuleProgressRecords;
        for(Promotion_Rule_Progress__c record : permRecords){  
                    	system.debug('Existing Rule Progress record foud with Promotion_Rule__c code code:' + record.id + ' : ' + record.Promotion_Rule__c); 

    		 ruleProgressUpdates.put(record.Promotion_Rule__c,record);
        }
        for(API_Promotion_Rule_Progress__c iRecord : apiRecords){
            	system.debug('API Rule Progress record foud with Promotion_Rule__c code code:' + iRecord.id + ' : ' + iRecord.API_Promotion_Rules__c); 
    
        	if(ruleCrossUpdates.containsKey(iRecord.API_Promotion_Rules__c)){
            	ruleProgressCrossRecords.put(iRecord.Id,createProgressRecord(iRecord,ruleCrossUpdates.get(iRecord.API_Promotion_Rules__c).Id));
              }else{
            	ruleProgressCrossRecords.put(iRecord.Id,createProgressRecord(iRecord,null));
              }
       }
        
        upsert ruleProgressCrossRecords.values();
    }
    public static void transactions(){
        Map<Id,Promotion_Account_Transactions__c> transactionCrossMap = new Map<Id,Promotion_Account_Transactions__c>();
        List<API_Promotion_Account_Transactions__c> apiTransactionList = new List<API_Promotion_Account_Transactions__c>();
        List<Promotion_Account_Transactions__c> transactionList = new List<Promotion_Account_Transactions__c>();
        Set<String> permIdList = new Set<String>();
        List<API_Promotion_Account_Transactions__c> addList = new List<API_Promotion_Account_Transactions__c>();
        
        List<Promotion_Account_Transactions__c> recordsToInsert = new List<Promotion_Account_Transactions__c>();
        List<Promotion_Account_Transactions__c> recordsToUpdate = new List<Promotion_Account_Transactions__c>();
        Map<String,Promotion_Account_Transactions__c> existingRecordMap = new  Map<String,Promotion_Account_Transactions__c>();
        Map<String,Promotion_Account_Transactions__c> currentBatchMap = new Map<String,Promotion_Account_Transactions__c>();

        
       apiTransactionList = [SELECT Id,Transaction_Reference_Id__c,API_Promotion_Rule_progress__c,Transaction_Amount__c,API_RADS_Transaction_Log__c,
                                 Transaction_Channel__c,Transaction_Code__c,Transaction_Currency__c,Transaction_Date__c,Transaction_Reference_Id_2__c,
                                 Transaction_Debit_Credit_Code__c FROM API_Promotion_Account_Transactions__c 
                                 WHERE API_RADS_Transaction_Log__c =: transactionLogId];
        transactionList = [SELECT Id,Transaction_Reference_Id__c,Transaction_Reference_Id_2__c 
                           from Promotion_Account_Transactions__c where Case_Number__c =: caseNumber ]; 

       system.debug('running transactions');
        for(Promotion_Account_Transactions__c record : transactionList){
          	system.debug('Existing transactions record foud with Ext ID:' + record.id + ' : ' + record.Transaction_Reference_Id_2__c); 

            permIdList.add(record.Transaction_Reference_Id_2__c);
            if(record.Transaction_Reference_Id_2__c != null){
               existingRecordMap.put(record.Transaction_Reference_Id_2__c, record); 
            }
	        }
        for(API_Promotion_Account_Transactions__c rec : apiTransactionList){
       	system.debug('API transactions record foud with Ext ID:' + rec.id + ' : ' + rec.Transaction_Reference_Id_2__c); 

            
                addList.add(rec);
           
        }
        for(API_Promotion_Account_Transactions__c newRecord: addList){
            string extKey = newRecord.Transaction_Reference_Id_2__c;
            if(extKey == null){
               continue;
            }
            if(currentBatchMap.containsKey(extKey)){
                System.debug('Duplicate blocked! '); 
                continue;
            }

            Promotion_Account_Transactions__c transactionsToSave = createTransactionRecord(newRecord);
            if(existingRecordMap.containsKey(extKey)){
                transactionsToSave.Id = existingRecordMap.get(extKey).Id;
                recordsToUpdate.add(transactionsToSave);
            }else{
                recordsToInsert.add(transactionsToSave);
            }
        	 currentBatchMap.put(extKey,transactionsToSave);
            system.debug('show transaction record ' + newRecord );
            system.debug('show transaction recordsToInsert ' + recordsToInsert );
            system.debug('show transaction recordsToUpdate ' + recordsToUpdate );

        }
        if(!recordsToInsert.isEmpty()){
            insert recordsToInsert;
        }
        if(!recordsToUpdate.isEmpty()){
            update recordsToUpdate;
        }
    }


///This Section used to create new permenate records an d poplate lookup fields using the Cross Record Maps
    public static Promotion_Enrollment__c createEnrollment(API_Promotion_Enrollment__c apiRecord,String existingRecordId){
        Promotion_Enrollment__c newRecord; 
        if(!dataset.apiPermRecordsMap.containsKey(apiRecord.Id)){
        //if(existingRecordId == null){
        	newRecord = new Promotion_Enrollment__c();
        }
        else{
            system.debug('enrollment updating record based on old record data!!!');
            system.debug('show prime record id for enrollment match    ' + dataset.apiPermRecordsMap.get(apiRecord.Id));
            system.debug('show api record ' + apiRecord);
            system.debug('show api record wnrollment chanell ' + apiRecord.Enrollment_Channel__c);
            newRecord = new Promotion_Enrollment__c(Id = dataset.apiPermRecordsMap.get(apiRecord.Id));
        }
       
        newRecord.Account_Enrolled__c = apiRecord.Account_Last_4__c;
        newRecord.Account_Type__c = apiRecord.Account_Type__c;
        newRecord.API_RADS_Transaction_Log__c = apiRecord.API_RADS_Transaction_Log__c;
        newRecord.Case_Number__c = caseNumber;
        newRecord.CIF__c = apiRecord.CIF__c;
        newRecord.Enroll_Teammate_Id__c = apiRecord.Enroll_Teammate_Id__c; 
        newRecord.Enrollment_Channel__c = apiRecord.Enrollment_Channel__c;
        newRecord.Enrollment_Date__c = apiRecord.Enrollment_Date__c;
        newRecord.Enrollment_Flag__c = apiRecord.Enrollment_Flag__c;
        newRecord.Offer_Code__c = apiRecord.Offer_Code__c;
        newRecord.Offer_Description__c = apiRecord.Offer_Description__c; 
        newRecord.Offer_Name__c = apiRecord.Offer_Name__c;
        newRecord.Offer_Status__c = apiRecord.Offer_Status__c;
        newRecord.Offer_Type__c = apiRecord.Offer_Type__c;
        newRecord.Promo_Code__c = apiRecord.Promo_Code__c;
        newRecord.Promo_End_Date__c = apiRecord.Promo_End_Date__c;
        newRecord.Promo_Start_Date__c = apiRecord.Promo_Start_Date__c;
        newRecord.T_C_Client_Accepted_Timestamp__c = apiRecord.T_C_Client_Accepted_Timestamp__c;
        newRecord.T_C_PDF_link__c = apiRecord.T_C_PDF_link__c;
        newRecord.RADS_Last_Update_Date__c = apiLog[0].RADS_Last_Update__c;
        newRecord.Error_Code__c = apiLog[0].Error_Code__c;
        newRecord.Error_Message__c = apiLog[0].Error_Message__c;
        newRecord.Force_Enrollment_Case_Number__c =  apiRecord.Force_Enroll_Case_Number__c;
        return newRecord;
    }
    public static Promotion_Rewards__c createReward(API_Promotion_Rewards__c apiRecordpr,String existingRecordId) {
    system.debug( 'running rewards for ' + API_Promotion_Rewards__c.id);
        
        Promotion_Rewards__c newRecordpr;
        if(!dataset.apiPermRecordsMap.containsKey(apiRecordpr.Id)){
        	newRecordpr = new Promotion_Rewards__c();
        }
        else{
            system.debug('show bug at 317' + apiRecordpr.Id.getSObjectType());
       
	Id ikik =  dataset.apiPermRecordsMap.get(apiRecordpr.Id);
                        system.debug('show matching rec type ID ' + ikik);

            system.debug('show matching rec type ' + ikik.getSObjectType());
            newRecordpr = new Promotion_Rewards__c(Id = dataset.apiPermRecordsMap.get(apiRecordpr.Id));
        }    
    newRecordpr.Case_Number__c = caseNumber;
    newRecordpr.API_RADS_Transaction_Log__c = apiRecordpr.API_RADS_Transaction_Log__c;
    newRecordpr.Promotion_Enrollment_Number__c  = apiRecordpr.API_Promotion_Enrollment__c; // fix this this is wrong of course
 	newRecordpr.Force_Payout_Flag__c            = apiRecordpr.Force_Payout_Flag__c;
    newRecordpr.Promotion_Enrollment_Number__c  = apiRecordpr.API_Promotion_Enrollment__c;
    newRecordpr.Reverse_Notes__c                = apiRecordpr.Reverse_Notes__c;
    newRecordpr.Reward_Account__c               = apiRecordpr.Reward_Account__c;
    newRecordpr.Reward_Code__c                  = apiRecordpr.Reward_Code__c;
    newRecordpr.Reward_Description__c           = apiRecordpr.Reward_Description__c;
    newRecordpr.Reward_Mailing_Date__c          = apiRecordpr.Reward_Mailing_Date__c;
    newRecordpr.Reward_Name__c                  = apiRecordpr.Reward_Name__c;
    newRecordpr.Reward_Payment_Amount__c        = apiRecordpr.Reward_Payment_Amount__c;
    newRecordpr.Reward_Payment_Date__c          = apiRecordpr.Reward_Payment_Date__c;
    newRecordpr.Reward_Reversal_Flag__c         = apiRecordpr.Reward_Reversal_Flag__c;
    newRecordpr.Reward_Status__c                = apiRecordpr.Reward_Status__c;
    newRecordpr.Reward_Total_Amount_Paid__c     = apiRecordpr.Reward_Total_Amount_Paid__c;
    newRecordpr.Reward_Type__c                  = apiRecordpr.Reward_Type__c;
    newRecordpr.Reward_Value_Type__c            = apiRecordpr.Reward_Value_Type__c;
    //set the parent record 
     newRecordpr.Promotion_Enrollment_Number__c = enrollmentCrossRecords.get(apiRecordpr.API_Promotion_Enrollment__c).id;
    return newRecordpr;
    } 
    public static Promotion_Account__c createAccount(API_Account__c apiRecord,String existingRecordId){
        Promotion_Account__c newRecord;
        if(!dataset.apiPermRecordsMap.containsKey(apiRecord.Id)){
        	newRecord = new Promotion_Account__c();
        }
        else{
            newRecord = new Promotion_Account__c(Id = dataset.apiPermRecordsMap.get(apiRecord.Id));
        }    
        newRecord.Case_Number__c = caseNumber;
        newRecord.Account_Type__c = apiRecord.Account_Type__c;
        newRecord.API_RADS_Transaction_Log__c = apiRecord.API_RADS_Transaction_Log__c;
        newRecord.Last_4__c = apiRecord.Last_4__c;
        //set the parent record 
        newRecord.Promotion_Rewards__c = rewardCrossRecords.get(apiRecord.API_Promotion_Rewards__c).Id;
        return newRecord;
    }
    public static Promotion_Condition__c createCondition(API_Promotion_Conditions__c apiRecord,String existingRecordId){
        Promotion_Condition__c newRecord;
        if(!dataset.apiPermRecordsMap.containsKey(apiRecord.Id)){
        	newRecord = new Promotion_Condition__c();
        }
        else{
            newRecord = new Promotion_Condition__c(Id = dataset.apiPermRecordsMap.get(apiRecord.Id));
        }    
        newRecord.API_RADS_Transaction_Log__c = apiRecord.API_RADS_Transaction_Log__c;
        newRecord.Case_Number__c  = caseNumber;
        newRecord.Condition_Code__c = apiRecord.Condition_Code__c;
        newRecord.Condition_Description__c = apiRecord.Condition_Description__c;
        newRecord.Condition_Met__c = apiRecord.Condition_Met__c;
        newRecord.Condition_Name__c = apiRecord.Condition_Name__c;
        //set lookup to parent
        newRecord.Promotion_account__c =  accountCrossRecords.get(apiRecord.API_Account__c).Id;
        return newRecord;
    }

    public static Promotion_Rule_Set__c createRuleSet(API_Promotion_Rule_Set__c apiRecord,String existingRecordId){
        Promotion_Rule_Set__c newRecord;
        if(!dataset.apiPermRecordsMap.containsKey(apiRecord.Id)){
        	newRecord = new Promotion_Rule_Set__c();
        }
        else{
            newRecord = new Promotion_Rule_Set__c(Id = dataset.apiPermRecordsMap.get(apiRecord.Id));
        }    
        newRecord.Case_Number__c  = caseNumber;
        newRecord.API_RADS_Transaction_Log__c = apiRecord.API_RADS_Transaction_Log__c;
        newRecord.Rule_Set_Code__c = apiRecord.Rule_Set_Code__c;
        //set parent record!
        newRecord.Promotion_Condition__c = conditionsCrossRecords.get(apiRecord.API_Promotion_Conditions__c).Id;
        return newRecord;
    }
    
    public static Promotion_Rule__c createRuleRecord(API_Promotion_Rules__c apiRecord,String existingRecordId){
        Promotion_Rule__c newRecord;
        if(!dataset.apiPermRecordsMap.containsKey(apiRecord.Id)){
        	newRecord = new Promotion_Rule__c();
        }
        else{
            newRecord = new Promotion_Rule__c(Id = dataset.apiPermRecordsMap.get(apiRecord.Id));
        }    
        newRecord.Case_Number__c  = caseNumber;
        newRecord.API_RADS_Transaction_Log__c = apiRecord.API_RADS_Transaction_Log__c;
        newRecord.Progress_Type__c = apiRecord.Progress_Type__c;
        newRecord.Rule_Code__c = apiRecord.Rule_Code__c;
        newRecord.Rule_Description__c = apiRecord.Rule_Description__c;
        newRecord.Rule_Name__c = apiRecord.Rule_Name__c;
        newRecord.Target_Value__c = apiRecord.Target_Value__c;
        //set parent ids!
        newRecord.Promotion_Rule_Set__c = promotionRuleSetCrossRecords.get(apiRecord.API_Promotion_Rule_Set__c).Id;
        return newRecord;
    }
        
    public static Promotion_Rule_Progress__c createProgressRecord(API_Promotion_Rule_Progress__c apiRecord,String existingRecordId){
       system.debug('processing rule progress now!');
        Promotion_Rule_Progress__c newRecord;
        if(!dataset.apiPermRecordsMap.containsKey(apiRecord.Id)){
        	newRecord = new Promotion_Rule_Progress__c();
        }
        else{
             system.debug('Promotion_Rule_Progress__c updating record based on old record data!!!');
            system.debug('show prime record id for Promotion_Rule_Progress__c match    ' + dataset.apiPermRecordsMap.get(apiRecord.Id));
            system.debug('show api record ' + apiRecord);
            newRecord = new Promotion_Rule_Progress__c(Id = dataset.apiPermRecordsMap.get(apiRecord.Id));
        }    
        newRecord.Actual_Value__c = apiRecord.Actual_Value__c;
        newRecord.Case_Number__c = caseNumber;
        newRecord.Evaluation_End_Date__c = apiRecord.Evaluation_End_Date__c;
        newRecord.Evaluation_Start_Date__c = apiRecord.Evaluation_Start_Date__c;
        newRecord.Rule_Details__c = apiRecord.Rule_Details__c;
        newRecord.Rule_Pass_Flag__c = apiRecord.Rule_Pass_Flag__c;
        newRecord.Rule_Passed_Date__c = apiRecord.Rule_Passed_Date__c;
        newRecord.API_RADS_Transaction_Log__c = apiRecord.API_RADS_Transaction_Log__c;
        newRecord.Promotion_Rule__c  = ruleCrossRecords.get(apiRecord.API_Promotion_Rules__c).Id; //Id from from promo rule obj
     	return newRecord;
    }
        public static Promotion_Account_Transactions__c createTransactionRecord(API_Promotion_Account_Transactions__c iRecord){
            string progessId =  iRecord.API_Promotion_Rule_Progress__c;
            Promotion_Account_Transactions__c resultRecord = new Promotion_Account_Transactions__c();
            resultRecord.API_RADS_Transaction_Log__c =  iRecord.API_RADS_Transaction_Log__c;       //transactionLogId;//
            resultRecord.Case_Number__c = caseNumber; //map to case obj/////////////
            resultRecord.Promotion_Rule_Progress__c = ruleProgressCrossRecords.get(iRecord.API_Promotion_Rule_progress__c).Id; //NEEDS TO BE MAPED AFTER CREATION
            resultRecord.Transaction_Amount__c = iRecord.Transaction_Amount__c;
            resultRecord.Transaction_Channel__c = iRecord.Transaction_Channel__c;
            resultRecord.Transaction_Code__c = iRecord.Transaction_Code__c;	
            resultRecord.Transaction_Currency__c = iRecord.Transaction_Currency__c;
            resultRecord.Transaction_Date__c = iRecord.Transaction_Date__c;
            resultRecord.Transaction_Debit_Credit_Code__c = iRecord.Transaction_Debit_Credit_Code__c;
            resultRecord.Transaction_Reference_Id__c = iRecord.Transaction_Reference_Id__c;
            resultRecord.Transaction_Reference_Id_2__c = iRecord.Transaction_Reference_Id_2__c;
            resultRecord.Promotion_Rule_Progress__c  = ruleProgressCrossRecords.get(iRecord.API_Promotion_Rule_progress__c).Id;
            
            return resultRecord;
        }
    public static list<API_Account__c> getAccounts(){
		   return [SELECT Id,API_Promotion_Rewards__c,API_RADS_Transaction_Log__c,Account_Type__c,Last_4__c
                      FROM API_Account__c WHERE API_RADS_Transaction_Log__c =: transactionLogId]; 
     }    
 }