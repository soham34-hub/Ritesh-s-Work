public with sharing class PromoXRewardsController {

    @AuraEnabled(cacheable=true)
    public static RewardData CreateRewardStructure(String caseId) {

        system.debug('show id' + caseId);
        // -------------------------------
        // Defensive map initialization
        // -------------------------------
        Map<Id, List<Promotion_Rewards__c>> rewardMap = new Map<Id, List<Promotion_Rewards__c>>();
        Map<Id, List<Promotion_Account__c>> accountMap = new Map<Id, List<Promotion_Account__c>>();
        Map<Id, List<Promotion_Condition__c>> conditionMap = new Map<Id, List<Promotion_Condition__c>>();
        Map<Id, List<Promotion_Rule_Set__c>> ruleSetMap = new Map<Id, List<Promotion_Rule_Set__c>>();
        Map<Id, List<Promotion_Rule__c>> rulesMap = new Map<Id, List<Promotion_Rule__c>>();
        Map<Id, List<Promotion_Rule_Progress__c>> progressMap = new Map<Id, List<Promotion_Rule_Progress__c>>();

        RewardMassData rewardTree = new RewardMassData();

        // ==============================
        // 1) Query all related records
        // ==============================
        rewardTree.rewardList = [
            SELECT Id, Force_Payout_Flag__c, Case_Number__c, Promotion_Enrollment_Number__c, Name, Reverse_Notes__c,
                   Reward_Account__c, Reward_Description__c, Reward_Name__c, Reward_Status__c, Reward_Type__c,
                   Reward_Payment_Date__c, Reward_Code__c, Reward_Total_Amount_Paid__c, Reward_Mailing_Date__c,
                   Reward_Value_Type__c, Reward_Reversal_Flag__c, Reward_Payment_Amount__c
            FROM Promotion_Rewards__c
            WHERE Case_Number__c = :caseId
        ];

        rewardTree.accountList = [
            SELECT Id, Name, Account_Type__c, Case_Number__c, Last_4__c, Promotion_Rewards__c
            FROM Promotion_Account__c
            WHERE Case_Number__c = :caseId
        ];

        rewardTree.conditionList = [
            SELECT Id, Name, Case_Number__c, Condition_Code__c, Condition_Description__c, Condition_Met__c,
                   Condition_Name__c, Promotion_Account__c
            FROM Promotion_Condition__c
            WHERE Case_Number__c = :caseId
        ];

        rewardTree.ruleSetList = [
            SELECT Id, Name, Case_Number__c, Promotion_Condition__c, Rule_Set_Code__c
            FROM Promotion_Rule_Set__c
            WHERE Case_Number__c = :caseId
        ];

        rewardTree.ruleList = [
            SELECT Id, Name, Case_Number__c, Promotion_Rule_Set__c, Progress_Type__c, Rule_Code__c,
                   Rule_Description__c, Rule_Name__c, Target_Value__c
            FROM Promotion_Rule__c
            WHERE Case_Number__c = :caseId
        ];

        rewardTree.progressList = [
            SELECT Id, Name, Case_Number__c, Actual_Value__c, Evaluation_End_Date__c, Evaluation_Start_Date__c,
                   Promotion_Rule__c, Rule_Details__c, Rule_Pass_Flag__c, Rule_Passed_Date__c
            FROM Promotion_Rule_Progress__c
            WHERE Case_Number__c = :caseId
        ];

        // ==============================
        // 2) Build maps with null safety
        // ==============================
        for (Promotion_Rewards__c reward : rewardTree.rewardList) {
            if (reward == null || reward.Promotion_Enrollment_Number__c == null) continue;
            Id key = reward.Promotion_Enrollment_Number__c;
            if (!rewardMap.containsKey(key)) rewardMap.put(key, new List<Promotion_Rewards__c>());
            rewardMap.get(key).add(reward);
        }

        for (Promotion_Account__c acct : rewardTree.accountList) {
            if (acct == null || acct.Promotion_Rewards__c == null) continue;
            Id key = acct.Promotion_Rewards__c;
            if (!accountMap.containsKey(key)) accountMap.put(key, new List<Promotion_Account__c>());
            accountMap.get(key).add(acct);
        }

        for (Promotion_Condition__c cond : rewardTree.conditionList) {
            if (cond == null || cond.Promotion_Account__c == null) continue;
            Id key = cond.Promotion_Account__c;
            if (!conditionMap.containsKey(key)) conditionMap.put(key, new List<Promotion_Condition__c>());
            conditionMap.get(key).add(cond);
        }

        for (Promotion_Rule_Set__c rs : rewardTree.ruleSetList) {
            if (rs == null || rs.Promotion_Condition__c == null) continue;
            Id key = rs.Promotion_Condition__c;
            if (!ruleSetMap.containsKey(key)) ruleSetMap.put(key, new List<Promotion_Rule_Set__c>());
            ruleSetMap.get(key).add(rs);
        }

        for (Promotion_Rule__c rule : rewardTree.ruleList) {
            if (rule == null || rule.Promotion_Rule_Set__c == null) continue;
            Id key = rule.Promotion_Rule_Set__c;
            if (!rulesMap.containsKey(key)) rulesMap.put(key, new List<Promotion_Rule__c>());
            rulesMap.get(key).add(rule);
        }

        for (Promotion_Rule_Progress__c pr : rewardTree.progressList) {
            if (pr == null || pr.Promotion_Rule__c == null) continue;
            Id key = pr.Promotion_Rule__c;
            if (!progressMap.containsKey(key)) progressMap.put(key, new List<Promotion_Rule_Progress__c>());
            progressMap.get(key).add(pr);
        }

        // ==============================
        // 3) Build hierarchical structure (SAFE)
        // ==============================
        RewardData dataBundle = new RewardData();

        for (Id enrollmentId : rewardMap.keySet()) {
            for (Promotion_Rewards__c reward : rewardMap.get(enrollmentId)) {
                dataBundle.enrollmentId = String.valueOf(reward.Promotion_Enrollment_Number__c);

                // Reward wrapper
                RewardAccountGroupingData rag = new RewardAccountGroupingData();
                rag.reward = reward;
                dataBundle.rewardList.add(rag);

                // Accounts (0..n)
                List<Promotion_Account__c> accounts = accountMap.get(reward.Id);
                if (accounts == null) accounts = new List<Promotion_Account__c>();

                AccountGroupingData acctGroup = new AccountGroupingData();
                acctGroup.accountList = accounts;
                rag.accountList.add(acctGroup);

                // For each account, add its conditions (0..n)
                for (Promotion_Account__c acc : accounts) {
                    List<Promotion_Condition__c> conds = conditionMap.get(acc.Id);
                    if (conds == null) continue;

                    for (Promotion_Condition__c cond : conds) {
                        ConditionGroupingData cg = new ConditionGroupingData();
                        cg.condition = cond;
                        acctGroup.conditionList.add(cg);

                        // Rule Sets (0..n)
                        List<Promotion_Rule_Set__c> rsList = ruleSetMap.get(cond.Id);
                        if (rsList == null) continue;

                        for (Promotion_Rule_Set__c rs : rsList) {
                            RuleSet rsWrap = new RuleSet();
                            rsWrap.ruleSet = rs;
                            cg.ruleSetList.add(rsWrap);

                            // Rules (0..n)
                            List<Promotion_Rule__c> ruleList = rulesMap.get(rs.Id);
                            if (ruleList == null) continue;

                            for (Promotion_Rule__c rl : ruleList) {
                                Rule ruleWrap = new Rule();
                                ruleWrap.rule = rl;
                                rsWrap.rulesList.add(ruleWrap);

                                // Progress (0..n)
                                List<Promotion_Rule_Progress__c> plist = progressMap.get(rl.Id);
                                if (plist == null) continue;

                                for (Promotion_Rule_Progress__c pg : plist) {
                                    RuleProgress prog = new RuleProgress();
                                    prog.progress = pg;
                                    ruleWrap.progressList.add(prog);
                                }
                            }
                        }
                    }
                }
            }
        }
        system.debug('Reward RewardAccountGroupingData ' + dataBundle.rewardList);
        //system.debug('Reward RewardAccountGroupingData ' dataBundle.RewardAccountGroupingData);');
       // system.debug('Reward AccountGroupingData ' dataBundle.AccountGroupingData);
//system.debug('Reward ConditionGroupingData ' dataBundle.ConditionGroupingData);

        return dataBundle;
    }

    // =====================================================================
    // Helpers / Data containers (formatted & corrected casing)
    // =====================================================================

    private static void createRewardRecords(RewardMassData rewardTree) {
        Map<Id, Promotion_Rewards__c> rewardMap = new Map<Id, Promotion_Rewards__c>();
        Map<Id, Promotion_Account__c> accountMap = new Map<Id, Promotion_Account__c>();
        Map<Id, Promotion_Condition__c> conditionMap = new Map<Id, Promotion_Condition__c>();
        Map<Id, Promotion_Rule_Set__c> ruleSetMap = new Map<Id, Promotion_Rule_Set__c>();

        for (Promotion_Rewards__c reward : rewardTree.rewardList) {
            rewardMap.put(reward.Id, reward);
        }
        // NOTE: This method was not fully implemented in your original code.
        // Left in place for parity; safe and harmless as-is.
    }

    public class RewardRecordSet {
        @AuraEnabled public List<Promotion_Rewards__c> rewardList = new List<Promotion_Rewards__c>();
        @AuraEnabled public List<Promotion_Account__c> accountList = new List<Promotion_Account__c>();
        @AuraEnabled public List<Promotion_Condition__c> conditionList = new List<Promotion_Condition__c>();
        @AuraEnabled public List<Promotion_Rule_Set__c> ruleSetList = new List<Promotion_Rule_Set__c>();
    }

    public class RewardMassData {
        @AuraEnabled public List<Promotion_Rewards__c> rewardList = new List<Promotion_Rewards__c>();
        @AuraEnabled public List<Promotion_Account__c> accountList = new List<Promotion_Account__c>();
        @AuraEnabled public List<Promotion_Condition__c> conditionList = new List<Promotion_Condition__c>();
        @AuraEnabled public List<Promotion_Rule_Set__c> ruleSetList = new List<Promotion_Rule_Set__c>();
        @AuraEnabled public List<Promotion_Rule__c> ruleList = new List<Promotion_Rule__c>();
        @AuraEnabled public List<Promotion_Rule_Progress__c> progressList = new List<Promotion_Rule_Progress__c>();
    }

    // Top-level DTO returned to LWC
    public class RewardData {
        @AuraEnabled public String enrollmentId;
        @AuraEnabled public List<RewardAccountGroupingData> rewardList = new List<RewardAccountGroupingData>();
    }

    public class RewardAccountGroupingData {
        @AuraEnabled public Promotion_Rewards__c reward = new Promotion_Rewards__c();
        @AuraEnabled public List<AccountGroupingData> accountList = new List<AccountGroupingData>();
    }

    public class AccountGroupingData {
        @AuraEnabled public List<Promotion_Account__c> accountList = new List<Promotion_Account__c>();
        @AuraEnabled public List<ConditionGroupingData> conditionList = new List<ConditionGroupingData>();
    }

    public class ConditionGroupingData {
        @AuraEnabled public Promotion_Condition__c condition = new Promotion_Condition__c();
        @AuraEnabled public List<RuleSet> ruleSetList = new List<RuleSet>();
    }

    public class RuleSet {
        @AuraEnabled public Promotion_Rule_Set__c ruleSet = new Promotion_Rule_Set__c();
        @AuraEnabled public List<Rule> rulesList = new List<Rule>();
    }

    public class Rule {
        @AuraEnabled public Promotion_Rule__c rule = new Promotion_Rule__c();
        @AuraEnabled public List<RuleProgress> progressList = new List<RuleProgress>();
    }

    public class RuleProgress {
        @AuraEnabled public Promotion_Rule_Progress__c progress = new Promotion_Rule_Progress__c();
    }

public Class promOffers{
    @AuraEnabled public Promotion_Enrollment__c enrollmentRecord;
    @AuraEnabled public List<promoReward> rewardList = new List<promoReward>();
}
public Class promoReward{
    @AuraEnabled public Promotion_Rewards__c reward = new Promotion_Rewards__c();

}

}