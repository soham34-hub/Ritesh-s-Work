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
                   Promotion_Enrollment_Number__r.Net_New_Money__c, Promotion_Enrollment_Number__r.Offer_Prefix__c,
                   API_RADS_Transaction_Log__c, Promotion_Enrollment_Number__r.Offer_Code__c,
                   Reward_Order__c, Bonus_Interest_Indicator__c, Account_Product_Name__c,
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
                   Monitor_End_Date__c,
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
        // Reward-specific conditions: show each condition only under the reward it belongs to
        applyRewardConditionOwnership(dataBundle, rewardTree, accountMap, conditionMap, ruleSetMap, rulesMap, progressMap);

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

    // =====================================================================
    // Reward-specific condition ownership (Multi-Product / Tier fix)
    // When several rewards share one Promotion Account record, all conditions
    // were shown under the first reward and the other rewards were blank.
    // The RADS staging (API_*) records keep the correct reward -> account ->
    // condition link, so they are used to place each condition under its own
    // reward. Single-reward Cases, and Cases without staging data, are not changed.
    // =====================================================================

    private static void applyRewardConditionOwnership(
        RewardData dataBundle,
        RewardMassData rewardTree,
        Map<Id, List<Promotion_Account__c>> accountMap,
        Map<Id, List<Promotion_Condition__c>> conditionMap,
        Map<Id, List<Promotion_Rule_Set__c>> ruleSetMap,
        Map<Id, List<Promotion_Rule__c>> rulesMap,
        Map<Id, List<Promotion_Rule_Progress__c>> progressMap
    ) {
        if (dataBundle == null || dataBundle.rewardList == null || dataBundle.rewardList.size() < 2) return;

        // 1) RADS logs used by the rewards on this Case
        Set<Id> logIds = new Set<Id>();
        for (RewardAccountGroupingData rag : dataBundle.rewardList) {
            if (rag != null && rag.reward != null && rag.reward.API_RADS_Transaction_Log__c != null) {
                logIds.add(rag.reward.API_RADS_Transaction_Log__c);
            }
        }
        if (logIds.isEmpty()) return;

        // 2) Staging keys per log and reward: "last4|conditionCode"
        Map<Id, Map<String, Set<String>>> allowedByLog = loadStagingConditionKeys(logIds);
        if (allowedByLog.isEmpty()) return;

        // 3) Allowed condition keys per permanent reward
        Map<Id, Set<String>> allowedByReward = new Map<Id, Set<String>>();
        for (RewardAccountGroupingData rag : dataBundle.rewardList) {
            if (rag == null || rag.reward == null || rag.reward.Id == null) continue;
            Set<String> keys = getAllowedKeys(rag.reward, allowedByLog);
            if (keys != null) allowedByReward.put(rag.reward.Id, keys);
        }
        if (allowedByReward.isEmpty()) return;

        // 4) Owner reward(s) for each condition
        Map<Id, Promotion_Account__c> accById = new Map<Id, Promotion_Account__c>();
        for (Promotion_Account__c acc : rewardTree.accountList) {
            if (acc != null && acc.Id != null) accById.put(acc.Id, acc);
        }

        Map<Id, Set<Id>> ownersByCondition = new Map<Id, Set<Id>>();
        for (Promotion_Condition__c cond : rewardTree.conditionList) {
            if (cond == null || cond.Promotion_Account__c == null) continue;
            Promotion_Account__c acc = accById.get(cond.Promotion_Account__c);
            if (acc == null) continue;

            String condKey = normalizeKey(acc.Last_4__c) + '|' + normalizeKey(cond.Condition_Code__c);

            Set<Id> candidates = new Set<Id>();
            for (Id rewardId : allowedByReward.keySet()) {
                if (allowedByReward.get(rewardId).contains(condKey)) candidates.add(rewardId);
            }

            Set<Id> owners = new Set<Id>();
            if (acc.Promotion_Rewards__c != null
                    && (candidates.isEmpty() || candidates.contains(acc.Promotion_Rewards__c))) {
                // Direct link is correct (or no staging match): keep it
                owners.add(acc.Promotion_Rewards__c);
            } else {
                // Direct link is wrong: use the reward(s) from RADS staging
                owners.addAll(candidates);
            }
            ownersByCondition.put(cond.Id, owners);
        }

        // 5) Rebuild accounts and conditions for each reward
        for (RewardAccountGroupingData rag : dataBundle.rewardList) {
            if (rag == null || rag.reward == null || rag.reward.Id == null) continue;
            Id rewardId = rag.reward.Id;

            List<Promotion_Account__c> accounts = new List<Promotion_Account__c>();
            Set<Id> seenAccounts = new Set<Id>();

            // Accounts directly linked to this reward
            List<Promotion_Account__c> direct = accountMap.get(rewardId);
            if (direct != null) {
                for (Promotion_Account__c acc : direct) {
                    accounts.add(acc);
                    seenAccounts.add(acc.Id);
                }
            }

            // Accounts that hold a condition owned by this reward
            for (Promotion_Account__c acc : rewardTree.accountList) {
                if (acc == null || seenAccounts.contains(acc.Id)) continue;
                List<Promotion_Condition__c> conds = conditionMap.get(acc.Id);
                if (conds == null) continue;
                for (Promotion_Condition__c cond : conds) {
                    Set<Id> owners = ownersByCondition.get(cond.Id);
                    if (owners != null && owners.contains(rewardId)) {
                        accounts.add(acc);
                        seenAccounts.add(acc.Id);
                        break;
                    }
                }
            }

            AccountGroupingData acctGroup = new AccountGroupingData();
            acctGroup.accountList = accounts;

            for (Promotion_Account__c acc : accounts) {
                List<Promotion_Condition__c> conds = conditionMap.get(acc.Id);
                if (conds == null) continue;
                for (Promotion_Condition__c cond : conds) {
                    Set<Id> owners = ownersByCondition.get(cond.Id);
                    if (owners == null || !owners.contains(rewardId)) continue;
                    acctGroup.conditionList.add(buildConditionGroup(cond, ruleSetMap, rulesMap, progressMap));
                }
            }

            rag.accountList = new List<AccountGroupingData>{ acctGroup };
        }
    }

    private static Map<Id, Map<String, Set<String>>> loadStagingConditionKeys(Set<Id> logIds) {
        Map<Id, Map<String, Set<String>>> result = new Map<Id, Map<String, Set<String>>>();
        try {
            Map<Id, String> offerByApiEnrollment = new Map<Id, String>();
            for (API_Promotion_Enrollment__c enr : [
                SELECT Id, Offer_Code__c
                FROM API_Promotion_Enrollment__c
                WHERE API_RADS_Transaction_Log__c IN :logIds
            ]) {
                offerByApiEnrollment.put(enr.Id, normalizeKey(enr.Offer_Code__c));
            }

            Map<Id, API_Promotion_Rewards__c> apiRewardById = new Map<Id, API_Promotion_Rewards__c>([
                SELECT Id, Reward_Code__c, API_Promotion_Enrollment__c, API_RADS_Transaction_Log__c
                FROM API_Promotion_Rewards__c
                WHERE API_RADS_Transaction_Log__c IN :logIds
            ]);

            Map<Id, API_Account__c> apiAccountById = new Map<Id, API_Account__c>([
                SELECT Id, API_Promotion_Rewards__c, Last_4__c
                FROM API_Account__c
                WHERE API_RADS_Transaction_Log__c IN :logIds
            ]);

            for (API_Promotion_Conditions__c apiCond : [
                SELECT Id, API_Account__c, Condition_Code__c, API_RADS_Transaction_Log__c
                FROM API_Promotion_Conditions__c
                WHERE API_RADS_Transaction_Log__c IN :logIds
            ]) {
                if (apiCond.API_Account__c == null || apiCond.API_RADS_Transaction_Log__c == null) continue;
                API_Account__c apiAcc = apiAccountById.get(apiCond.API_Account__c);
                if (apiAcc == null || apiAcc.API_Promotion_Rewards__c == null) continue;
                API_Promotion_Rewards__c apiRw = apiRewardById.get(apiAcc.API_Promotion_Rewards__c);
                if (apiRw == null) continue;

                String rewardCode = normalizeKey(apiRw.Reward_Code__c);
                if (String.isBlank(rewardCode)) continue;

                String offerCode = apiRw.API_Promotion_Enrollment__c != null
                    && offerByApiEnrollment.containsKey(apiRw.API_Promotion_Enrollment__c)
                    ? offerByApiEnrollment.get(apiRw.API_Promotion_Enrollment__c)
                    : '';

                String condKey = normalizeKey(apiAcc.Last_4__c) + '|' + normalizeKey(apiCond.Condition_Code__c);

                Map<String, Set<String>> byReward = result.get(apiCond.API_RADS_Transaction_Log__c);
                if (byReward == null) {
                    byReward = new Map<String, Set<String>>();
                    result.put(apiCond.API_RADS_Transaction_Log__c, byReward);
                }
                addKey(byReward, 'O:' + offerCode + '|' + rewardCode, condKey);
                addKey(byReward, 'R:' + rewardCode, condKey);
            }
        } catch (Exception e) {
            system.debug('loadStagingConditionKeys failed: ' + e.getMessage());
            return new Map<Id, Map<String, Set<String>>>();
        }
        return result;
    }

    private static Set<String> getAllowedKeys(Promotion_Rewards__c reward, Map<Id, Map<String, Set<String>>> allowedByLog) {
        if (reward == null || reward.API_RADS_Transaction_Log__c == null) return null;
        String rewardCode = normalizeKey(reward.Reward_Code__c);
        if (String.isBlank(rewardCode)) return null;

        Map<String, Set<String>> byReward = allowedByLog.get(reward.API_RADS_Transaction_Log__c);
        if (byReward == null) return null;

        String offerCode = reward.Promotion_Enrollment_Number__r != null
            ? normalizeKey(reward.Promotion_Enrollment_Number__r.Offer_Code__c)
            : '';

        Set<String> keys = byReward.get('O:' + offerCode + '|' + rewardCode);
        if (keys == null) keys = byReward.get('R:' + rewardCode);
        return keys;
    }

    private static void addKey(Map<String, Set<String>> target, String rewardKey, String condKey) {
        if (!target.containsKey(rewardKey)) target.put(rewardKey, new Set<String>());
        target.get(rewardKey).add(condKey);
    }

    private static String normalizeKey(String value) {
        return value == null ? '' : value.trim().toUpperCase();
    }

    private static ConditionGroupingData buildConditionGroup(
        Promotion_Condition__c cond,
        Map<Id, List<Promotion_Rule_Set__c>> ruleSetMap,
        Map<Id, List<Promotion_Rule__c>> rulesMap,
        Map<Id, List<Promotion_Rule_Progress__c>> progressMap
    ) {
        ConditionGroupingData cg = new ConditionGroupingData();
        cg.condition = cond;

        List<Promotion_Rule_Set__c> rsList = ruleSetMap.get(cond.Id);
        if (rsList == null) return cg;

        for (Promotion_Rule_Set__c rs : rsList) {
            RuleSet rsWrap = new RuleSet();
            rsWrap.ruleSet = rs;
            cg.ruleSetList.add(rsWrap);

            List<Promotion_Rule__c> ruleList = rulesMap.get(rs.Id);
            if (ruleList == null) continue;

            for (Promotion_Rule__c rl : ruleList) {
                Rule ruleWrap = new Rule();
                ruleWrap.rule = rl;
                rsWrap.rulesList.add(ruleWrap);

                List<Promotion_Rule_Progress__c> plist = progressMap.get(rl.Id);
                if (plist == null) continue;

                for (Promotion_Rule_Progress__c pg : plist) {
                    RuleProgress prog = new RuleProgress();
                    prog.progress = pg;
                    ruleWrap.progressList.add(prog);
                }
            }
        }
        return cg;
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