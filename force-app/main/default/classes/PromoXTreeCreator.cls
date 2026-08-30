public with sharing class PromoXTreeCreator {
   
	//todo:
	//GOAL: match the recods from API to Perm(if they exist)
	//promoCode,all related Id's used for both perm and api?
	//used to track promo key by record Id used for both perm and api
	public static Map<String,String> locatePromoKeyAPI = new MAP<String,String>();
	public static Map<String,String> locatePromoKeyPerm = new MAP<String,String>();
	public static map<String,String> promoLinkKeyMap = new MAP<String,String>();
    public static map<String,String> promoLinkEnrollment = new MAP<String,String>();
    public static map<String,String> promoLinkRewards = new MAP<String,String>();
	public static dataSet  data = new dataSet();
    Public Static String transactionLogId; //will gewt back from lexi code
    Public Static String caseNumber; //get from launch screen or trigger context 
    Public Static String operation = '';
    Public Static Map<String,Promotion_Enrollment__c> enrollmentCrossRecords = new MAP<String,Promotion_Enrollment__c>();
    Public Static Map<String,Promotion_Rewards__c> rewardCrossRecords = new MAP<String,Promotion_Rewards__c>();
    Public Static Map<String,Promotion_Account__c> accountCrossRecords = new MAP<String,Promotion_Account__c>();
    Public Static Map<String,Promotion_Condition__c> conditionsCrossRecords = new MAP<String,Promotion_Condition__c>();
    Public Static Map<String,Promotion_Rule_Set__c> promotionRuleSetCrossRecords = new MAP<String,Promotion_Rule_Set__c>(); 
    Public Static Map<String,Promotion_Rule__c> ruleCrossRecords = new MAP<String,Promotion_Rule__c>();
    Public Static Map<String,Promotion_Rule_Progress__c> ruleProgressCrossRecords = new MAP<String,Promotion_Rule_Progress__c>();
    Public Static Map<String,Promotion_Enrollment__c> enrollmentUpdates = new MAP<String,Promotion_Enrollment__c>(); 
    Public Static Map<String,Promotion_Rewards__c> rewardUpdates = new MAP<String,Promotion_Rewards__c>();
    Public Static Map<String,Promotion_Account__c> accountUpdates = new MAP<String,Promotion_Account__c>();
    Public Static Map<String,Promotion_Condition__c> conditionsUpdates = new MAP<String,Promotion_Condition__c>();
    Public Static Map<String,Promotion_Rule_Set__c> promotionRuleSetUpdates = new MAP<String,Promotion_Rule_Set__c>();
    Public Static Map<String,Promotion_Rule__c> ruleCrossUpdates = new MAP<String,Promotion_Rule__c>();
    Public Static Map<String,Promotion_Rule_Progress__c> ruleProgressUpdates = new MAP<String,Promotion_Rule_Progress__c>();
    Public Static List<API_Account__c> apiAccountRecords = new List<API_Account__c>();
	Public Static Map<String,API_Account__c> relatedAccountRecords = new MAP<String,API_Account__c>();

    public static dataSet createDataSet(Id CaseID, Id logId){
        caseNumber = caseID;
        transactionLogId = logid;
        enrollment();
        rewards();
        accounts();
        conditions();
        ruleSets();
        rules();
        ruleProgress();
        data.apiPermRecordsMap = promoLinkKeyMap;
        return data;
    }

    public static void enrollment(){ //fix this!
        List<API_Promotion_Enrollment__c> apiRecords = new List<API_Promotion_Enrollment__c>();
        List<Promotion_Enrollment__c> permRecords = new List<Promotion_Enrollment__c>();
        Map<String,API_Promotion_Enrollment__c> apiMap = new Map<String,API_Promotion_Enrollment__c>();
        Map<String,Promotion_Enrollment__c> permMap = new Map<String,Promotion_Enrollment__c>();
        
	    permRecords = [SELECT id,Offer_Code__c,Promo_Key__c FROM Promotion_Enrollment__c WHERE Case_Number__c =: caseNumber];
    	apiRecords = [SELECT Id,API_RADS_Transaction_Log__c,Account_Last_4__c,Account_Type__c,CIF__c,
                    Enroll_Teammate_Id__c,Enrollment_Channel__c,Enrollment_Date__c,Enrollment_Flag__c,Force_Enroll_Case_Number__c,Offer_Code__c,
                    Offer_Description__c,Offer_Name__c,Offer_Status__c,Offer_Type__c,Promo_Code__c,Promo_End_Date__c,Promo_Key__c,Promo_Start_Date__c,
                    T_C_Client_Accepted_Timestamp__c,T_C_PDF_link__c
                    FROM API_Promotion_Enrollment__c WHERE API_RADS_Transaction_Log__c =: transactionLogId]; 
    	data.apiEnrollemtRecords = apiRecords;
    	data.enrollmentRecords = permRecords;
	    for(API_Promotion_Enrollment__c rec :apiRecords ){
            apiMap.put(rec.Id,rec);
        }
    	for(Promotion_Enrollment__c rec :permRecords ){
            permMap.put(rec.Id,rec);
        }
    	String pKey;
    	for(Promotion_Enrollment__c pRecord: permRecords){
            locatePromoKeyPerm.put(pRecord.Id,pRecord.Promo_Key__c); //add to keySet
       	}
	    for(API_Promotion_Enrollment__c apiRecord: apiRecords){
    	    locatePromoKeyAPI.put(apiRecord.Id,apiRecord.Promo_Key__c);
        }

		for (API_Promotion_Enrollment__c apiRec : apiRecords) {
    		Id apiId = apiRec.Id;
		    for (Promotion_Enrollment__c permRec : permRecords) {
        		Id permId = permRec.Id;
		        Boolean promoMatch = locatePromoKeyAPI.get(apiId) == locatePromoKeyPerm.get(permId);
        		Boolean codeMatch  = apiRec.Offer_Code__c   == permRec.Offer_Code__c;
                system.debug('showpromoMatch    ' +promoMatch);
                system.debug('showcodeMatch     ' + codeMatch);

		        if (promoMatch && codeMatch) {
        		    system.debug('enrollment found');
            		promoLinkKeyMap.put(apiId, permId);
            		break;
        		}
    		}
		}
        for(Id helper :promoLinkKeyMap.keySet()){
        	id tester = promoLinkKeyMap.get(helper);
            system.debug('show rec matching for enrollment : ' + helper.getSObjectType() + ' **** ' + tester.getSObjectType());
        }
	}

    public static void rewards(){
    	List<API_Promotion_Rewards__c> apiRecords = new List<API_Promotion_Rewards__c>();
        List<Promotion_Rewards__c> permRecords = new List<Promotion_Rewards__c>();
        Map<String,API_Promotion_Rewards__c> apiMap = new Map<String,API_Promotion_Rewards__c>();
        Map<String,Promotion_Rewards__c> permMap = new Map<String,Promotion_Rewards__c>();
        
         //what is Reward_Account__c field is this lookup to account?
		 permRecords = [SELECT Id,Reward_Code__c,Promotion_Enrollment_Number__c FROM Promotion_Rewards__c where Case_Number__c =: caseNumber];
         apiRecords = [SELECT Id,API_Promotion_Enrollment__c,API_RADS_Transaction_Log__c,Force_Payout_Flag__c,Reverse_Notes__c,Reward_Account__c,
                       Reward_Code__c,Reward_Description__c,Reward_Mailing_Date__c,Reward_Name__c,Reward_Payment_Amount__c,Reward_Payment_Date__c,
                       Reward_Reversal_Flag__c,Reward_Status__c,Reward_Total_Amount_Paid__c,Reward_Type__c,Reward_Value_Type__c
                       FROM API_Promotion_Rewards__c WHERE API_RADS_Transaction_Log__c =: transactionLogId]; 
    
        data.apiRewardRecords = apiRecords;
        data.rewardRecords = permRecords;
        for(API_Promotion_Rewards__c rec :apiRecords ){
            apiMap.put(rec.Id,rec);
        }
        for(Promotion_Rewards__c rec :permRecords ){
            permMap.put(rec.Id,rec);
        }
        String pKey;
        for(Promotion_Rewards__c pRecord: permRecords){
            pKey = locatePromoKeyPerm.get(pRecord.Promotion_Enrollment_Number__c);
            locatePromoKeyPerm.put(pRecord.Id,pKey); //add to keySet
        }
        for(API_Promotion_Rewards__c apiRecord: apiRecords){
            pKey = locatePromoKeyAPI.get(apiRecord.API_Promotion_Enrollment__c);
            locatePromoKeyAPI.put(apiRecord.Id,pKey);
        }
		for (API_Promotion_Rewards__c apiRec : apiRecords) {
    		Id apiId = apiRec.Id;
		    for (Promotion_Rewards__c permRec : permRecords) {
        		Id permId = permRec.Id;
		        Boolean promoMatch  = locatePromoKeyAPI.get(apiId) == locatePromoKeyPerm.get(permId);
        		Boolean rewardMatch = apiRec.Reward_Code__c == permRec.Reward_Code__c;
		        if (promoMatch && rewardMatch) {
        		    system.debug('reward record match found');
            		promoLinkKeyMap.put(apiId, permId);
    				break;
        		}
    		}
		}

 		for(Id helper :promoLinkKeyMap.keySet()){
        	id tester = promoLinkKeyMap.get(helper);
            system.debug('show rec matching for enrollment : ' + helper.getSObjectType() + ' **** ' + tester.getSObjectType());
        }
	}
//account type add this
    public static void accounts(){
    	List<Promotion_Account__c> permRecords = new List<Promotion_Account__c>();
        List<API_Account__c> apiRecords = new List<API_Account__c>();
        Map<String,API_Account__c> apiMap = new Map<String,API_Account__c>();
        Map<String,Promotion_Account__c> permMap = new Map<String,Promotion_Account__c>();
    
        permRecords = [SELECT Id,Promotion_Rewards__c,Last_4__c FROM Promotion_Account__c where Case_Number__c =: caseNumber];
        apiRecords = [SELECT Id,API_Promotion_Rewards__c,API_RADS_Transaction_Log__c,Account_Type__c,Last_4__c
                      FROM API_Account__c WHERE API_RADS_Transaction_Log__c =: transactionLogId]; 
        
        data.apiAccountRecords = apiRecords;
        data.AccountRecords = permRecords;

        for(API_Account__c rec :apiRecords ){
            apiMap.put(rec.Id,rec);
        }
        for(Promotion_Account__c rec :permRecords ){
            permMap.put(rec.Id,rec);
        }
        String pKey;
        for(API_Account__c apiRecord: apiRecords){
            pKey = locatePromoKeyAPI.get(apiRecord.API_Promotion_Rewards__c);
            locatePromoKeyAPI.put(apiRecord.Id,pKey);
        }
        for(Promotion_Account__c pRecord: permRecords){
            pKey = locatePromoKeyPerm.get(pRecord.Promotion_Rewards__c);
            locatePromoKeyPerm.put(pRecord.Id,pKey); //add to keySet
        }
		for (API_Account__c apiRec : apiRecords) {
    		Id apiId = apiRec.Id;
		    for (Promotion_Account__c permRec : permRecords) {
        		Id permId = permRec.Id;
		        Boolean promoMatch = locatePromoKeyAPI.get(apiId) == locatePromoKeyPerm.get(permId);
        		Boolean last4Match = apiRec.Last_4__c            == permRec.Last_4__c;
		        if (promoMatch && last4Match) {
        		    promoLinkKeyMap.put(apiId, permId);
            		break;
        		}
    		}
		}
 		for(Id helper :promoLinkKeyMap.keySet()){
        	 id tester = promoLinkKeyMap.get(helper);
             system.debug('show rec matching for enrollment : ' + helper.getSObjectType() + ' **** ' + tester.getSObjectType());
        }
    }

	public static void conditions(){
    	List<API_Promotion_Conditions__c> apiRecords = new List<API_Promotion_Conditions__c>();
    	List<Promotion_Condition__c> permRecords = new List<Promotion_Condition__c>();
        Map<String,API_Promotion_Conditions__c> apiMap = new Map<String,API_Promotion_Conditions__c>();
        Map<String,Promotion_Condition__c> permMap = new Map<String,Promotion_Condition__c>();
        
        permRecords = [SELECT Id,Condition_Code__c,Promotion_account__c FROM Promotion_Condition__c WHERE case_Number__c =: caseNumber];    
        apiRecords = [SELECT Id,API_Account__c,API_RADS_Transaction_Log__c,Condition_Code__c,Condition_Description__c,Condition_Met__c,
                      Condition_Name__c FROM API_Promotion_Conditions__c WHERE API_RADS_Transaction_Log__c =: transactionLogId]; 
        data.apiConditionRecords = apiRecords;
        data.ConditionRecords = permRecords;
        for(API_Promotion_Conditions__c rec :apiRecords ){
            apiMap.put(rec.Id,rec);
        }
        for(Promotion_Condition__c rec :permRecords ){
            permMap.put(rec.Id,rec);
        }
        String pKey;
        for(API_Promotion_Conditions__c apiRecord: apiRecords){
            pKey = locatePromoKeyAPI.get(apiRecord.API_Account__c);
            locatePromoKeyAPI.put(apiRecord.Id,pKey);
        }
        for(Promotion_Condition__c pRecord: permRecords){
            pKey = locatePromoKeyPerm.get(pRecord.Promotion_account__c);
            locatePromoKeyPerm.put(pRecord.Id,pKey); //add to keySet
        }
        for(Id helper :promoLinkKeyMap.keySet()){
	    	id tester = promoLinkKeyMap.get(helper);
            system.debug('show rec matching for enrollment : ' + helper.getSObjectType() + ' **** ' + tester.getSObjectType());
        }
		for (API_Promotion_Conditions__c apiRec : apiRecords) {
    		Id apiId = apiRec.Id;
	    	for (Promotion_Condition__c permRec : permRecords) {
    	    	Id permId = permRec.Id;
	    	    Boolean promoMatch = locatePromoKeyAPI.get(apiId) == locatePromoKeyPerm.get(permId);
    	    	Boolean condMatch  = apiRec.Condition_Code__c     == permRec.Condition_Code__c;
	        	if (promoMatch && condMatch) {
    	        	promoLinkKeyMap.put(apiId, permId);
        	    	break;
        		}
    		}
		}
		for(Id helper :promoLinkKeyMap.keySet()){
        	 id tester = promoLinkKeyMap.get(helper);
         	system.debug('show rec matching for enrollment : ' + helper.getSObjectType() + ' **** ' + tester.getSObjectType());
    	}
	}

    public static void ruleSets(){
        List<API_Promotion_Rule_Set__c> apiRecords = new List<API_Promotion_Rule_Set__c>();
		List<Promotion_Rule_Set__c> permRecords = new List<Promotion_Rule_Set__c>();
        Map<String,API_Promotion_Rule_Set__c> apiMap = new Map<String,API_Promotion_Rule_Set__c>();
        Map<String,Promotion_Rule_Set__c> permMap = new Map<String,Promotion_Rule_Set__c>();
       
		permRecords = [SELECT Id,Rule_Set_Code__c,Promotion_Condition__c FROM Promotion_Rule_Set__c WHERE case_Number__c =: caseNumber ];
        apiRecords = [SELECT Id,API_Promotion_Conditions__c,API_RADS_Transaction_Log__c,Rule_Set_Code__c
                      FROM API_Promotion_Rule_Set__c WHERE API_RADS_Transaction_Log__c =: transactionLogId]; 
        data.apiRuleSetRecords = apiRecords;
        data.RuleSetRecords = permRecords;
        for(API_Promotion_Rule_Set__c rec :apiRecords ){
            apiMap.put(rec.Id,rec);
        }
        for(Promotion_Rule_Set__c rec :permRecords ){
            permMap.put(rec.Id,rec);
        }
        String pKey;
        for(API_Promotion_Rule_Set__c apiRecord: apiRecords){
            pKey = locatePromoKeyAPI.get(apiRecord.API_Promotion_Conditions__c);
            locatePromoKeyAPI.put(apiRecord.Id,pKey);
        }
       for(Promotion_Rule_Set__c pRecord: permRecords){
            pKey = locatePromoKeyPerm.get(pRecord.Promotion_Condition__c);
            locatePromoKeyPerm.put(pRecord.Id,pKey); //add to keySet
        }
		for (API_Promotion_Rule_Set__c apiRec : apiRecords) {
    		Id apiId = apiRec.Id;
    		for (Promotion_Rule_Set__c permRec : permRecords) {
        		Id permId = permRec.Id;
        		Boolean promoMatch     = locatePromoKeyAPI.get(apiId) == locatePromoKeyPerm.get(permId);
        		Boolean ruleSetCodeMatch = apiRec.Rule_Set_Code__c   == permRec.Rule_Set_Code__c;
        		if (promoMatch && ruleSetCodeMatch) {
            		promoLinkKeyMap.put(apiId, permId);
            		break;
        		}
    		}
		}
        for(Id helper :promoLinkKeyMap.keySet()){
    	id tester = promoLinkKeyMap.get(helper);
        system.debug('show rec matching for enrollment : ' + helper.getSObjectType() + ' **** ' + tester.getSObjectType());
    	}
    }

	public static void rules(){
    	List<API_Promotion_Rules__c> apiRecords = new List<API_Promotion_Rules__c>();
		List<Promotion_Rule__c> permRecords = new List<Promotion_Rule__c>();
        Map<String,API_Promotion_Rules__c> apiMap = new Map<String,API_Promotion_Rules__c>();
        Map<String,Promotion_Rule__c> permMap = new Map<String,Promotion_Rule__c>();
       
		permRecords = [SELECT Id,Rule_Code__c,Promotion_Rule_Set__c From Promotion_Rule__c where case_Number__c =: caseNumber];
        apiRecords = [SELECT Id,API_Promotion_Rule_Set__c,API_RADS_Transaction_Log__c,Progress_Type__c,Rule_Code__c,
                      Rule_Description__c,Rule_Name__c,Target_Value__c FROM API_Promotion_Rules__c 
                      WHERE API_RADS_Transaction_Log__c =: transactionLogId]; 
        data.apiRrulesRecords = apiRecords;
        data.rulesRecords = permRecords;
        
        for(API_Promotion_Rules__c rec :apiRecords ){
            apiMap.put(rec.Id,rec);
        }
        for(Promotion_Rule__c rec :permRecords ){
            permMap.put(rec.Id,rec);
        }
        String pKey;
        for(API_Promotion_Rules__c apiRecord: apiRecords){
            pKey = locatePromoKeyAPI.get(apiRecord.API_Promotion_Rule_Set__c);
            locatePromoKeyAPI.put(apiRecord.Id,pKey);
        }
        for(Promotion_Rule__c pRecord: permRecords){
            pKey = locatePromoKeyPerm.get(pRecord.Promotion_Rule_Set__c);
            locatePromoKeyPerm.put(pRecord.Id,pKey); //add to keySet
        }
		for (API_Promotion_Rules__c apiRec : apiRecords) {
    		Id apiId = apiRec.Id;
	    	for (Promotion_Rule__c permRec : permRecords) {
    	    	Id permId = permRec.Id;
        		Boolean promoMatch  = locatePromoKeyAPI.get(apiId) == locatePromoKeyPerm.get(permId);
        		Boolean ruleMatch   = apiRec.Rule_Code__c          == permRec.Rule_Code__c;
	        	if (promoMatch && ruleMatch) {
    	        	promoLinkKeyMap.put(apiId, permId);
        	    	break;
        		}
    		}
  		}
		for(Id helper :promoLinkKeyMap.keySet()){
        	 id tester = promoLinkKeyMap.get(helper);
         	system.debug('show rec matching for enrollment : ' + helper.getSObjectType() + ' **** ' + tester.getSObjectType());
        }    
    }
// add date ranges as part of check
    public static void ruleProgress(){
        List<API_Promotion_Rule_Progress__c> apiRecords = new List<API_Promotion_Rule_Progress__c>();
  		List<Promotion_Rule_Progress__c> permRecords = new List<Promotion_Rule_Progress__c>();
       
		permRecords = [SELECT Id,Promotion_Rule__c FROM Promotion_Rule_Progress__c WHERE case_Number__c =: caseNumber];
        apiRecords = [SELECT Id,Actual_Value__c,API_RADS_Transaction_Log__c,API_Promotion_Rules__c,Evaluation_End_Date__c,Evaluation_Start_Date__c,
                      Rule_Details__c,Rule_Pass_Flag__c,Rule_Passed_Date__c
                      FROM API_Promotion_Rule_Progress__c where API_RADS_Transaction_Log__c =: transactionLogId];
        data.apiRuleProgressRecords = apiRecords;
        data.ruleProgressRecords = permRecords;
        String pKey;

        for(API_Promotion_Rule_Progress__c apiRecord: apiRecords){
            pKey = locatePromoKeyAPI.get(apiRecord.API_Promotion_Rules__c);
            locatePromoKeyAPI.put(apiRecord.Id,pKey);
        }
        for(Promotion_Rule_Progress__c pRecord: permRecords){
            pKey = locatePromoKeyPerm.get(pRecord.Promotion_Rule__c);
            locatePromoKeyPerm.put(pRecord.Id,pKey); //add to keySet
        }

	for (API_Promotion_Rule_Progress__c apiRec : apiRecords) {
		Id apiRuleId = apiRec.API_Promotion_Rules__c;
    	Id permRuleId = promoLinkKeyMap.get(apiRuleId);
    	if (permRuleId == null) continue;
        for (Promotion_Rule_Progress__c permRec : permRecords) {
	        if (permRec.Promotion_Rule__c == permRuleId) {
                promoLinkKeyMap.put(apiRec.Id, permRec.Id);
            	break;
        }
    }
}
        
 for(Id helper :promoLinkKeyMap.keySet()){
         id tester = promoLinkKeyMap.get(helper);
            system.debug('show rec matching for enrollment : ' + helper.getSObjectType() + ' **** ' + tester.getSObjectType());
        }
    }

    Public class dataSet{
	    Public Map<String,String> apiPermRecordsMap = new Map<String,String>();
        Public List<API_Promotion_Enrollment__c> apiEnrollemtRecords = new List<API_Promotion_Enrollment__c>();
        Public List<Promotion_Enrollment__c> enrollmentRecords = new List<Promotion_Enrollment__c>();
        Public List<API_Promotion_Rewards__c> apiRewardRecords = new List<API_Promotion_Rewards__c>();
        Public List<Promotion_Rewards__c> rewardRecords = new List<Promotion_Rewards__c>();
        Public List<Promotion_Account__c> accountRecords = new List<Promotion_Account__c>();
        Public List<API_Account__c> apiAccountRecords = new List<API_Account__c>();
        Public List<API_Promotion_Conditions__c> apiConditionRecords = new List<API_Promotion_Conditions__c>();
    	Public List<Promotion_Condition__c> conditionRecords = new List<Promotion_Condition__c>();
        Public List<API_Promotion_Rule_Set__c> apiRuleSetRecords = new List<API_Promotion_Rule_Set__c>();
		Public List<Promotion_Rule_Set__c> RuleSetRecords = new List<Promotion_Rule_Set__c>();
        Public List<API_Promotion_Rules__c> apiRrulesRecords = new List<API_Promotion_Rules__c>();
	    Public List<Promotion_Rule__c> rulesRecords = new List<Promotion_Rule__c>();
        Public List<API_Promotion_Rule_Progress__c> apiRuleProgressRecords = new List<API_Promotion_Rule_Progress__c>();
	    Public List<Promotion_Rule_Progress__c> ruleProgressRecords = new List<Promotion_Rule_Progress__c>();
        }
    }