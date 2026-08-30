public with sharing class PromoXTreeCreatorService {

    private Map<String,String> locatePromoKeyAPI  = new Map<String,String>();
    private Map<String,String> locatePromoKeyPerm = new Map<String,String>();
    private Map<String,String> promoLinkKeyMap    = new Map<String,String>();
    private dataSet data = new dataSet();
 
    /**
     * Builds and returns a dataSet for one Case record using pre-fetched data.
     * No SOQLs are issued — all lists come from the caller's bulk fetch.
     * @param apiEnrollments   API_Promotion_Enrollment__c records for this log
     * @param permEnrollments  Promotion_Enrollment__c records for this case
     * @param apiRewards       API_Promotion_Rewards__c records for this log
     * @param permRewards      Promotion_Rewards__c records for this case
     * @param apiAccounts      API_Account__c records for this log
     * @param permAccounts     Promotion_Account__c records for this case
     * @param apiConditions    API_Promotion_Conditions__c records for this log
     * @param permConditions   Promotion_Condition__c records for this case
     * @param apiRuleSets      API_Promotion_Rule_Set__c records for this log
     * @param permRuleSets     Promotion_Rule_Set__c records for this case
     * @param apiRules         API_Promotion_Rules__c records for this log
     * @param permRules        Promotion_Rule__c records for this case
     * @param apiRuleProgress  API_Promotion_Rule_Progress__c records for this log
     * @param permRuleProgress Promotion_Rule_Progress__c records for this case
     */
    public dataSet createDataSet(
        List<API_Promotion_Enrollment__c>  apiEnrollments,
        List<Promotion_Enrollment__c>   permEnrollments,
        List<API_Promotion_Rewards__c>  apiRewards,
        List<Promotion_Rewards__c>   permRewards,
        List<API_Account__c>   apiAccounts,
        List<Promotion_Account__c>  permAccounts,
        List<API_Promotion_Conditions__c>  apiConditions,
        List<Promotion_Condition__c>   permConditions,
        List<API_Promotion_Rule_Set__c>  apiRuleSets,
        List<Promotion_Rule_Set__c>    permRuleSets,
        List<API_Promotion_Rules__c> apiRules,
        List<Promotion_Rule__c>   permRules,
        List<API_Promotion_Rule_Progress__c> apiRuleProgress,
        List<Promotion_Rule_Progress__c>     permRuleProgress
    ) {
        enrollment  (apiEnrollments,  permEnrollments);
        rewards     (apiRewards,      permRewards);
        accounts    (apiAccounts,     permAccounts);
        conditions  (apiConditions,   permConditions);
        ruleSets    (apiRuleSets,     permRuleSets);
        rules       (apiRules,        permRules);
        ruleProgress(apiRuleProgress, permRuleProgress);
 
        data.apiPermRecordsMap = promoLinkKeyMap;
        return data;
    }
 
 
    private void enrollment(
        List<API_Promotion_Enrollment__c> apiRecords,
        List<Promotion_Enrollment__c>     permRecords
    ) {
        data.apiEnrollemtRecords = apiRecords;
        data.enrollmentRecords   = permRecords;
 
        for (Promotion_Enrollment__c rec : permRecords) {
            locatePromoKeyPerm.put(rec.Id, rec.Promo_Key__c);
        }
        for (API_Promotion_Enrollment__c rec : apiRecords) {
            locatePromoKeyAPI.put(rec.Id, rec.Promo_Key__c);
        }
 
        for (API_Promotion_Enrollment__c apiRec : apiRecords) {
            for (Promotion_Enrollment__c permRec : permRecords) {
                Boolean promoMatch = locatePromoKeyAPI.get(apiRec.Id) == locatePromoKeyPerm.get(permRec.Id);
                Boolean codeMatch  = apiRec.Offer_Code__c == permRec.Offer_Code__c;
                if (promoMatch && codeMatch) {
                    System.debug('Enrollment match found: ' + apiRec.Id + ' → ' + permRec.Id);
                    promoLinkKeyMap.put(apiRec.Id, permRec.Id);
                    break;
                }
            }
        }
    }
 
    private void rewards(
        List<API_Promotion_Rewards__c> apiRecords,
        List<Promotion_Rewards__c>     permRecords
    ) {
        data.apiRewardRecords = apiRecords;
        data.rewardRecords    = permRecords;
 
        for (Promotion_Rewards__c rec : permRecords) {
            String pKey = locatePromoKeyPerm.get(rec.Promotion_Enrollment_Number__c);
            locatePromoKeyPerm.put(rec.Id, pKey);
        }
        for (API_Promotion_Rewards__c rec : apiRecords) {
            String pKey = locatePromoKeyAPI.get(rec.API_Promotion_Enrollment__c);
            locatePromoKeyAPI.put(rec.Id, pKey);
        }
 
        for (API_Promotion_Rewards__c apiRec : apiRecords) {
            for (Promotion_Rewards__c permRec : permRecords) {
                Boolean promoMatch  = locatePromoKeyAPI.get(apiRec.Id) == locatePromoKeyPerm.get(permRec.Id);
                Boolean rewardMatch = apiRec.Reward_Code__c == permRec.Reward_Code__c;
                if (promoMatch && rewardMatch) {
                    System.debug('Reward match found: ' + apiRec.Id + ' → ' + permRec.Id);
                    promoLinkKeyMap.put(apiRec.Id, permRec.Id);
                    break;
                }
            }
        }
    }
 
    private void accounts(
        List<API_Account__c>       apiRecords,
        List<Promotion_Account__c> permRecords
    ) {
        data.apiAccountRecords = apiRecords;
        data.AccountRecords    = permRecords;
 
        for (API_Account__c rec : apiRecords) {
            String pKey = locatePromoKeyAPI.get(rec.API_Promotion_Rewards__c);
            locatePromoKeyAPI.put(rec.Id, pKey);
        }
        for (Promotion_Account__c rec : permRecords) {
            String pKey = locatePromoKeyPerm.get(rec.Promotion_Rewards__c);
            locatePromoKeyPerm.put(rec.Id, pKey);
        }
 
        for (API_Account__c apiRec : apiRecords) {
            for (Promotion_Account__c permRec : permRecords) {
                Boolean promoMatch = locatePromoKeyAPI.get(apiRec.Id) == locatePromoKeyPerm.get(permRec.Id);
                Boolean last4Match = apiRec.Last_4__c == permRec.Last_4__c;
                if (promoMatch && last4Match) {
                    promoLinkKeyMap.put(apiRec.Id, permRec.Id);
                    break;
                }
            }
        }
    }
 
    private void conditions(
        List<API_Promotion_Conditions__c> apiRecords,
        List<Promotion_Condition__c>      permRecords
    ) {
        data.apiConditionRecords = apiRecords;
        data.ConditionRecords    = permRecords;
 
        for (API_Promotion_Conditions__c rec : apiRecords) {
            String pKey = locatePromoKeyAPI.get(rec.API_Account__c);
            locatePromoKeyAPI.put(rec.Id, pKey);
        }
        for (Promotion_Condition__c rec : permRecords) {
            String pKey = locatePromoKeyPerm.get(rec.Promotion_account__c);
            locatePromoKeyPerm.put(rec.Id, pKey);
        }
 
        for (API_Promotion_Conditions__c apiRec : apiRecords) {
            for (Promotion_Condition__c permRec : permRecords) {
                Boolean promoMatch = locatePromoKeyAPI.get(apiRec.Id) == locatePromoKeyPerm.get(permRec.Id);
                Boolean condMatch  = apiRec.Condition_Code__c == permRec.Condition_Code__c;
                if (promoMatch && condMatch) {
                    promoLinkKeyMap.put(apiRec.Id, permRec.Id);
                    break;
                }
            }
        }
    }
 
    private void ruleSets(
        List<API_Promotion_Rule_Set__c> apiRecords,
        List<Promotion_Rule_Set__c>     permRecords
    ) {
        data.apiRuleSetRecords = apiRecords;
        data.RuleSetRecords    = permRecords;
 
        for (API_Promotion_Rule_Set__c rec : apiRecords) {
            String pKey = locatePromoKeyAPI.get(rec.API_Promotion_Conditions__c);
            locatePromoKeyAPI.put(rec.Id, pKey);
        }
        for (Promotion_Rule_Set__c rec : permRecords) {
            String pKey = locatePromoKeyPerm.get(rec.Promotion_Condition__c);
            locatePromoKeyPerm.put(rec.Id, pKey);
        }
 
        for (API_Promotion_Rule_Set__c apiRec : apiRecords) {
            for (Promotion_Rule_Set__c permRec : permRecords) {
                Boolean promoMatch       = locatePromoKeyAPI.get(apiRec.Id) == locatePromoKeyPerm.get(permRec.Id);
                Boolean ruleSetCodeMatch = apiRec.Rule_Set_Code__c == permRec.Rule_Set_Code__c;
                if (promoMatch && ruleSetCodeMatch) {
                    promoLinkKeyMap.put(apiRec.Id, permRec.Id);
                    break;
                }
            }
        }
    }
 
    private void rules(
        List<API_Promotion_Rules__c> apiRecords,
        List<Promotion_Rule__c>      permRecords
    ) {
        data.apiRrulesRecords = apiRecords;
        data.rulesRecords     = permRecords;
 
        for (API_Promotion_Rules__c rec : apiRecords) {
            String pKey = locatePromoKeyAPI.get(rec.API_Promotion_Rule_Set__c);
            locatePromoKeyAPI.put(rec.Id, pKey);
        }
        for (Promotion_Rule__c rec : permRecords) {
            String pKey = locatePromoKeyPerm.get(rec.Promotion_Rule_Set__c);
            locatePromoKeyPerm.put(rec.Id, pKey);
        }
 
        for (API_Promotion_Rules__c apiRec : apiRecords) {
            for (Promotion_Rule__c permRec : permRecords) {
                Boolean promoMatch = locatePromoKeyAPI.get(apiRec.Id) == locatePromoKeyPerm.get(permRec.Id);
                Boolean ruleMatch  = apiRec.Rule_Code__c == permRec.Rule_Code__c;
                if (promoMatch && ruleMatch) {
                    promoLinkKeyMap.put(apiRec.Id, permRec.Id);
                    break;
                }
            }
        }
    }
 
    private void ruleProgress(
        List<API_Promotion_Rule_Progress__c> apiRecords,
        List<Promotion_Rule_Progress__c>     permRecords
    ) {
        data.apiRuleProgressRecords = apiRecords;
        data.ruleProgressRecords    = permRecords;
 
        for (API_Promotion_Rule_Progress__c rec : apiRecords) {
            String pKey = locatePromoKeyAPI.get(rec.API_Promotion_Rules__c);
            locatePromoKeyAPI.put(rec.Id, pKey);
        }
        for (Promotion_Rule_Progress__c rec : permRecords) {
            String pKey = locatePromoKeyPerm.get(rec.Promotion_Rule__c);
            locatePromoKeyPerm.put(rec.Id, pKey);
        }
 
        for (API_Promotion_Rule_Progress__c apiRec : apiRecords) {
            Id permRuleId = promoLinkKeyMap.get(apiRec.API_Promotion_Rules__c);
            if (permRuleId == null) continue;
            for (Promotion_Rule_Progress__c permRec : permRecords) {
                if (permRec.Promotion_Rule__c == permRuleId) {
                    promoLinkKeyMap.put(apiRec.Id, permRec.Id);
                    break;
                }
            }
        }
    }
 

    public class dataSet {
        public Map<String,String>                    apiPermRecordsMap    = new Map<String,String>();
        public List<API_Promotion_Enrollment__c>     apiEnrollemtRecords  = new List<API_Promotion_Enrollment__c>();
        public List<Promotion_Enrollment__c>         enrollmentRecords    = new List<Promotion_Enrollment__c>();
        public List<API_Promotion_Rewards__c>        apiRewardRecords     = new List<API_Promotion_Rewards__c>();
        public List<Promotion_Rewards__c>            rewardRecords        = new List<Promotion_Rewards__c>();
        public List<Promotion_Account__c>            AccountRecords       = new List<Promotion_Account__c>();
        public List<API_Account__c>                  apiAccountRecords    = new List<API_Account__c>();
        public List<API_Promotion_Conditions__c>     apiConditionRecords  = new List<API_Promotion_Conditions__c>();
        public List<Promotion_Condition__c>          ConditionRecords     = new List<Promotion_Condition__c>();
        public List<API_Promotion_Rule_Set__c>       apiRuleSetRecords    = new List<API_Promotion_Rule_Set__c>();
        public List<Promotion_Rule_Set__c>           RuleSetRecords       = new List<Promotion_Rule_Set__c>();
        public List<API_Promotion_Rules__c>          apiRrulesRecords     = new List<API_Promotion_Rules__c>();
        public List<Promotion_Rule__c>               rulesRecords         = new List<Promotion_Rule__c>();
        public List<API_Promotion_Rule_Progress__c>  apiRuleProgressRecords = new List<API_Promotion_Rule_Progress__c>();
        public List<Promotion_Rule_Progress__c>      ruleProgressRecords  = new List<Promotion_Rule_Progress__c>();
    }

}