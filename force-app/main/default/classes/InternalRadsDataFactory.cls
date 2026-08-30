@isTest
public class InternalRadsDataFactory {
 
  /// replace with case object  public static API_RADS_Transaction_Log__c log;
    public static Promotion_Enrollment__c enrollment;
    public static Promotion_Rewards__c rewards;
    public static Promotion_account__c promoAccount;
    public static Promotion_Condition__c conditions;
    public static Promotion_Rule_Set__c ruleSet;
    public static Promotion_Rule__c rules;
	public static Promotion_Rule_progress__c progress;
    public static Promotion_Account_Transactions__c transactions;
    public static Id relatedCaseId;
    public static void cleardata(){
    // should be case obj    list<API_RADS_Transaction_Log__c> logs = new List<API_RADS_Transaction_Log__c>();
        list<Promotion_Enrollment__c> enrolment = new List<Promotion_Enrollment__c>();
        list<Promotion_Rewards__c> rewards = new List<Promotion_Rewards__c>();
        list<Promotion_account__c> promoAccount = new List<Promotion_account__c>();
        list<Promotion_Condition__c> conditions = new List<Promotion_Condition__c>();
        list<Promotion_Rule_Set__c> reuleSets = new List<Promotion_Rule_Set__c>();
        list<Promotion_Rule__c> rules = new List<Promotion_Rule__c>();
        list<Promotion_Rule_progress__c> progress = new List<Promotion_Rule_progress__c>();
        list<Promotion_Account_Transactions__c> transactions = new List<Promotion_Account_Transactions__c>();
        
     // change to case   logs = [Select Id from API_RADS_Transaction_Log__c];
        enrolment = [Select Id from Promotion_Enrollment__c];
		rewards = [Select Id from Promotion_Rewards__c];
		promoAccount = [Select Id from Promotion_account__c];
		conditions = [Select Id from Promotion_Condition__c];
        reuleSets = [Select Id from Promotion_Rule_Set__c];
		rules = [Select Id from Promotion_Rule__c];
		progress = [Select Id from Promotion_Rule_progress__c];
		transactions = [Select Id from Promotion_Account_Transactions__c];
//        delete (logs);
        delete (enrolment);
        delete (rewards);
        delete (conditions);
        delete (promoAccount);
        delete (reuleSets);
        delete (rules);
        delete (progress);
        delete (transactions);
    }
    public static void createPromoRecordSet(String recNumber,Id caseId){
        recNumber = recNumber;
        relatedCaseId = caseId;
     //   log = createLog(recNumber);
      //  insert log;
        enrollment = createEnrollment(recNumber,null);
        insert enrollment;
        rewards = createReward(recNumber,enrollment);
        insert rewards;
        promoAccount = createAccount(rewards,recNumber); // flip prams in method to match others
        insert promoAccount; 
        conditions = createCondition(promoAccount,recNumber);  
        insert conditions; 
        ruleset = createRuleSet(conditions,recNumber); 
        insert ruleset; 
        rules = createRule(ruleset,recNumber);
        insert rules; 
		progress = createPRogressRecord(rules,recNumber);
        insert progress; 
		transactions = createTransaction(progress);
        insert transactions;
    }
    
    public static API_RADS_Transaction_Log__c createLog(String recordNumber){
        API_RADS_Transaction_Log__c tempLog = new API_RADS_Transaction_Log__c();
        tempLog.CIF__c = 'test' + recordNumber;
        tempLog.Error_Code__c = 'success';
        tempLog.RADS_Last_Update__c = date.today();
        return tempLog;
     }

    public static Promotion_Enrollment__c createEnrollment(string recordNumber,API_RADS_Transaction_Log__c parent){
        Promotion_Enrollment__c enrollment = new Promotion_Enrollment__c();
    // should be case obj    enrollment.API_RADS_Transaction_Log__c = parent.id;
		enrollment.CIF__c = '';
        
        enrollment.Promo_End_Date__c = date.today().addDays(45);
        enrollment.Account_Enrolled__c = '4532';
        enrollment.T_C_Client_Accepted_Timestamp__c = Datetime.Now();
   //     enrollment.Case_Number__c = relatedCaseId;
		enrollment.Enrollment_Channel__c = 'Test Channel';
        enrollment.Enrollment_Date__c = date.today();
        enrollment.Enrollment_Flag__c = 'true';
        enrollment.Error_Code__c = 'test';
        enrollment.Offer_Code__c = 'ofxtest';
        enrollment.Offer_Name__c = 'test promo';
        enrollment.Offer_Status__c = 'ACTIVE';
        enrollment.Promo_End_Date__c = date.today().adddays(30); 
        enrollment.Promo_Code__c = 'test10000';
    //n writeabnle ??//enrollment.Promo_Key__c = 'xx0000' + recordNumber;
	    enrollment.Promo_Start_Date__c = date.today();
        enrollment.RADS_Last_Update_Date__c = date.today();
        enrollment.T_C_PDF_link__c = 'https://testers.com';
        return enrollment;
    }
    
    public static Promotion_Rewards__c createReward(String recordNumber, Promotion_Enrollment__c parent){
        Promotion_Rewards__c reward = new Promotion_Rewards__c();
		reward.Promotion_Enrollment_Number__c = parent.id; // this should be a look up to the offer which translate into the case obj
     // add this field???   reward.Reward_Code__c = 'test ' + recordNumber;
        reward.Reward_Code__c = '1234';
        reward.Reward_Name__c = 'test';
       // reward.Case_Number__c = relatedCaseId;
        //remove this field hjas own obj reward.Reward_Qualification_Rules__c
       // reward.Reward_Total_Amount_Paid__c = 0;
        return reward;
    }
    public static Promotion_account__c createAccount( Promotion_Rewards__c parent, String caseNumber){
        Promotion_account__c account = new Promotion_account__c();
        account.Account_Type__c = 'test type';
        account.Promotion_Rewards__c = parent.Id;
        account.last_4__c = '0001';
        return account;
        
    }
    
    public static Promotion_Condition__c createCondition(Promotion_account__c parent, String recNumber){
        Promotion_Condition__c condition = new Promotion_Condition__c();
          condition.Promotion_account__c  = parent.Id;
          condition.Condition_Code__c = 'test001';
        condition.Condition_Name__c = 'test condition';
        return condition;
    }
    
    public static Promotion_Rule_Set__c createRuleSet(Promotion_Condition__c parent, String recNumber){
        Promotion_Rule_Set__c ruleSet = new Promotion_Rule_Set__c();
        ruleSet.Promotion_Condition__c = parent.id;
        ruleSet.Rule_Set_Code__c = ' test001';
        return ruleSet;
    }
    
    public static Promotion_Rule__c createRule(Promotion_Rule_Set__c parent, String recNumber){
        Promotion_Rule__c rule = new Promotion_Rule__c();
        rule.Promotion_Rule_Set__c = parent.Id;
        rule.Progress_Type__c = 'standard';
        rule.Rule_Code__c = 'test001';
        rule.Rule_Name__c = 'test';
        return rule;
    }
    
    public static Promotion_Rule_progress__c createPRogressRecord(Promotion_Rule__c parent, String recNumber){
        Promotion_Rule_progress__c progressRecord = new Promotion_Rule_progress__c();
        progressRecord.Actual_Value__c = '100';
        progressRecord.Promotion_Rule__c = parent.id;
        progressRecord.Evaluation_End_Date__c = date.Today().addDays(30);
        progressRecord.Evaluation_Start_Date__c = date.Today();
        progressRecord.Rule_Pass_Flag__c = 'true';
        return progressRecord;
    }
    
    public static Promotion_Account_Transactions__c createTransaction(Promotion_Rule_progress__c parent){
        Promotion_Account_Transactions__c transactionRecord = new Promotion_Account_Transactions__c();
        
        transactionRecord.Promotion_Rule_progress__c = parent.Id;
        transactionRecord.Transaction_Reference_Id__c = 134342;
    //remove this ?    transactionRecord.Promo_Code__c = '0001'; //remove this field??
      //  transactionRecord.Promo_Key__c = '0001'; //remove this field??
        transactionRecord.Transaction_Amount__c = 100.00;
        transactionRecord.Transaction_Date__c = date.today().addDays(-6);
      //   transactionRecord.Case_Number__c = relatedCaseId;
        return transactionRecord;
        
    }

}