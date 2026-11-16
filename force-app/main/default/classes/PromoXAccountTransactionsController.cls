/**
 * PromoXAccountTransactionsController
 *
 * DR-4350-7 (US2245842), DR-4350-8 (US2245878), DR-4350-9 (US2245844)
 * Data for the reward selector and table on The Account Transactions Tab.
 *
 * Rewards and their hierarchy come from PromoXRewardsController.CreateRewardStructure, so the
 * reward list, the order, the labels and the Reward > Account > Condition > Rule Set > Rule > Progress
 * links are the same as on The Rewards Tab. A transaction belongs to a reward when its
 * Promotion Rule Progress is under that reward. The direct Account link on the transaction is not used.
 */
public with sharing class PromoXAccountTransactionsController {

    @AuraEnabled(cacheable=true)
    public static List<RewardTransactions> getRewardTransactions(String caseId) {
        List<RewardTransactions> result = new List<RewardTransactions>();
        if (String.isBlank(caseId)) return result;

        PromoXRewardsController.RewardData tree = PromoXRewardsController.CreateRewardStructure(caseId);
        if (tree == null || tree.rewardList == null) return result;

        // Progress records under each reward -> last 4 of the account above them
        Map<Id, Map<Id, String>> last4ByProgressByReward = new Map<Id, Map<Id, String>>();
        Set<Id> allProgressIds = new Set<Id>();

        for (PromoXRewardsController.RewardAccountGroupingData rag : tree.rewardList) {
            if (rag == null || rag.reward == null || rag.reward.Id == null) continue;

            // DR-4350-8: Reward Name, or the Promotion Reward record number when Reward Name is blank
            RewardTransactions rt = new RewardTransactions();
            rt.rewardId = rag.reward.Id;
            rt.label = String.isNotBlank(rag.reward.Reward_Name__c) ? rag.reward.Reward_Name__c : rag.reward.Name;
            result.add(rt);

            Map<Id, String> last4ByProgress = new Map<Id, String>();
            for (PromoXRewardsController.AccountGroupingData grp : rag.accountList) {
                Map<Id, String> last4ByAccount = new Map<Id, String>();
                for (Promotion_Account__c acc : grp.accountList) {
                    last4ByAccount.put(acc.Id, acc.Last_4__c);
                }
                for (PromoXRewardsController.ConditionGroupingData cg : grp.conditionList) {
                    String last4 = last4ByAccount.get(cg.condition.Promotion_Account__c);
                    for (PromoXRewardsController.RuleSet rs : cg.ruleSetList) {
                        for (PromoXRewardsController.Rule rl : rs.rulesList) {
                            for (PromoXRewardsController.RuleProgress pg : rl.progressList) {
                                if (pg.progress != null && pg.progress.Id != null) {
                                    last4ByProgress.put(pg.progress.Id, last4);
                                }
                            }
                        }
                    }
                }
            }
            last4ByProgressByReward.put(rt.rewardId, last4ByProgress);
            allProgressIds.addAll(last4ByProgress.keySet());
        }
        if (allProgressIds.isEmpty()) return result;

        List<Promotion_Account_Transactions__c> transactions = [
            SELECT Id, Name, Promotion_Rule_Progress__c, Transaction_Reference_Id__c, Transaction_Date__c,
                   Transaction_Amount__c, Transaction_Debit_Credit_Code__c, Transaction_Code__c
            FROM Promotion_Account_Transactions__c
            WHERE Promotion_Rule_Progress__c IN :allProgressIds
            ORDER BY Transaction_Date__c DESC NULLS LAST
        ];

        for (RewardTransactions rt : result) {
            Map<Id, String> last4ByProgress = last4ByProgressByReward.get(rt.rewardId);
            if (last4ByProgress == null || last4ByProgress.isEmpty()) continue;

            // DR-4350-7: the same RADS transReferenceId is shown only once within the reward
            Set<String> seenReferenceIds = new Set<String>();
            for (Promotion_Account_Transactions__c t : transactions) {
                if (!last4ByProgress.containsKey(t.Promotion_Rule_Progress__c)) continue;
                String refKey = String.isNotBlank(t.Transaction_Reference_Id__c) ? t.Transaction_Reference_Id__c : t.Id;
                if (seenReferenceIds.contains(refKey)) continue;
                seenReferenceIds.add(refKey);

                TransactionRow row = new TransactionRow();
                row.record = t;
                row.accountNumber = formatLast4(last4ByProgress.get(t.Promotion_Rule_Progress__c));
                rt.rows.add(row);
            }
        }
        return result;
    }

    // DR-4350-9: Account Number = acctLastFour as supplied; fewer than 4 digits get leading zeros
    @TestVisible
    private static String formatLast4(String last4) {
        if (String.isBlank(last4)) return null;
        return last4.trim().leftPad(4, '0');
    }

    public class RewardTransactions {
        @AuraEnabled public String rewardId;
        @AuraEnabled public String label;
        @AuraEnabled public List<TransactionRow> rows = new List<TransactionRow>();
    }

    public class TransactionRow {
        @AuraEnabled public Promotion_Account_Transactions__c record;
        @AuraEnabled public String accountNumber;
    }
}