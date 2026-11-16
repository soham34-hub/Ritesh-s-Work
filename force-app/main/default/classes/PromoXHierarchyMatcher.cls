/**
 * PromoXHierarchyMatcher
 *
 * Matches RADS staging (API_*) records to the existing Promotion records on a Case.
 *
 * Why: the old matching used "promo key + code" at every level. The promo key comes from
 * the enrollment, so it is the same for every reward / tier of an offer. When two tiers use
 * the same account (same last 4), the Tier 2 account and its conditions were matched to the
 * Tier 1 records. Tier 1 then showed all tiers' conditions and Tier 2 was blank.
 *
 * How: each level is matched in two passes, and each existing record can be matched only once.
 *   Pass 1 - same parent record + same code (the correct link).
 *   Pass 2 - same enrollment + same code, for records that were saved under the wrong parent
 *            earlier. The record is reused and the save code moves it to the correct parent,
 *            so existing bad data is repaired on the next refresh.
 * API records with no match get a new record (same as before).
 *
 * Returns: API record Id -> existing record Id (same format as dataSet.apiPermRecordsMap).
 */
public class PromoXHierarchyMatcher {

    private static final String ROOT = 'ROOT';

    private class Node {
        String id;
        String parentId;
        String code;
        String rootId;
        Node(String id, String parentId, String code, String rootId) {
            this.id = id;
            this.parentId = parentId;
            this.code = code;
            this.rootId = rootId;
        }
    }

    public static Map<String,String> match(
        List<API_Promotion_Enrollment__c> apiEnrollments,  List<Promotion_Enrollment__c> permEnrollments,
        List<API_Promotion_Rewards__c> apiRewards,          List<Promotion_Rewards__c> permRewards,
        List<API_Account__c> apiAccounts,                   List<Promotion_Account__c> permAccounts,
        List<API_Promotion_Conditions__c> apiConditions,    List<Promotion_Condition__c> permConditions,
        List<API_Promotion_Rule_Set__c> apiRuleSets,        List<Promotion_Rule_Set__c> permRuleSets,
        List<API_Promotion_Rules__c> apiRules,              List<Promotion_Rule__c> permRules,
        List<API_Promotion_Rule_Progress__c> apiProgress,   List<Promotion_Rule_Progress__c> permProgress
    ) {
        Map<String,String> result = new Map<String,String>();
        result.put(ROOT, ROOT);

        // Root (enrollment) of each record, used by pass 2
        Map<String,String> apiRoot  = new Map<String,String>();
        Map<String,String> permRoot = new Map<String,String>();

        // ---------------- Enrollment: offer code + promo key ----------------
        List<Node> apiNodes  = new List<Node>();
        List<Node> permNodes = new List<Node>();
        if (apiEnrollments != null) {
            for (API_Promotion_Enrollment__c r : apiEnrollments) {
                apiNodes.add(new Node(r.Id, ROOT, normalize(r.Offer_Code__c) + '|' + normalize(r.Promo_Key__c), r.Id));
                apiRoot.put(r.Id, r.Id);
            }
        }
        if (permEnrollments != null) {
            for (Promotion_Enrollment__c r : permEnrollments) {
                permNodes.add(new Node(r.Id, ROOT, normalize(r.Offer_Code__c) + '|' + normalize(r.Promo_Key__c), r.Id));
                permRoot.put(r.Id, r.Id);
            }
        }
        matchLevel(apiNodes, permNodes, result);

        // ---------------- Rewards: parent enrollment + reward code ----------------
        apiNodes  = new List<Node>();
        permNodes = new List<Node>();
        if (apiRewards != null) {
            for (API_Promotion_Rewards__c r : apiRewards) {
                String root = apiRoot.get(r.API_Promotion_Enrollment__c);
                apiNodes.add(new Node(r.Id, r.API_Promotion_Enrollment__c, normalize(r.Reward_Code__c), root));
                apiRoot.put(r.Id, root);
            }
        }
        if (permRewards != null) {
            for (Promotion_Rewards__c r : permRewards) {
                String root = permRoot.get(r.Promotion_Enrollment_Number__c);
                permNodes.add(new Node(r.Id, r.Promotion_Enrollment_Number__c, normalize(r.Reward_Code__c), root));
                permRoot.put(r.Id, root);
            }
        }
        matchLevel(apiNodes, permNodes, result);

        // ---------------- Accounts: parent reward + last 4 ----------------
        apiNodes  = new List<Node>();
        permNodes = new List<Node>();
        if (apiAccounts != null) {
            for (API_Account__c r : apiAccounts) {
                String root = apiRoot.get(r.API_Promotion_Rewards__c);
                apiNodes.add(new Node(r.Id, r.API_Promotion_Rewards__c, normalize(r.Last_4__c), root));
                apiRoot.put(r.Id, root);
            }
        }
        if (permAccounts != null) {
            for (Promotion_Account__c r : permAccounts) {
                String root = permRoot.get(r.Promotion_Rewards__c);
                permNodes.add(new Node(r.Id, r.Promotion_Rewards__c, normalize(r.Last_4__c), root));
                permRoot.put(r.Id, root);
            }
        }
        matchLevel(apiNodes, permNodes, result);

        // ---------------- Conditions: parent account + condition code ----------------
        apiNodes  = new List<Node>();
        permNodes = new List<Node>();
        if (apiConditions != null) {
            for (API_Promotion_Conditions__c r : apiConditions) {
                String root = apiRoot.get(r.API_Account__c);
                apiNodes.add(new Node(r.Id, r.API_Account__c, normalize(r.Condition_Code__c), root));
                apiRoot.put(r.Id, root);
            }
        }
        if (permConditions != null) {
            for (Promotion_Condition__c r : permConditions) {
                String root = permRoot.get(r.Promotion_Account__c);
                permNodes.add(new Node(r.Id, r.Promotion_Account__c, normalize(r.Condition_Code__c), root));
                permRoot.put(r.Id, root);
            }
        }
        matchLevel(apiNodes, permNodes, result);

        // ---------------- Rule Sets: parent condition + rule set code ----------------
        apiNodes  = new List<Node>();
        permNodes = new List<Node>();
        if (apiRuleSets != null) {
            for (API_Promotion_Rule_Set__c r : apiRuleSets) {
                String root = apiRoot.get(r.API_Promotion_Conditions__c);
                apiNodes.add(new Node(r.Id, r.API_Promotion_Conditions__c, normalize(r.Rule_Set_Code__c), root));
                apiRoot.put(r.Id, root);
            }
        }
        if (permRuleSets != null) {
            for (Promotion_Rule_Set__c r : permRuleSets) {
                String root = permRoot.get(r.Promotion_Condition__c);
                permNodes.add(new Node(r.Id, r.Promotion_Condition__c, normalize(r.Rule_Set_Code__c), root));
                permRoot.put(r.Id, root);
            }
        }
        matchLevel(apiNodes, permNodes, result);

        // ---------------- Rules: parent rule set + rule code ----------------
        apiNodes  = new List<Node>();
        permNodes = new List<Node>();
        Map<String,String> apiRuleCode  = new Map<String,String>();
        Map<String,String> permRuleCode = new Map<String,String>();
        if (apiRules != null) {
            for (API_Promotion_Rules__c r : apiRules) {
                String root = apiRoot.get(r.API_Promotion_Rule_Set__c);
                apiNodes.add(new Node(r.Id, r.API_Promotion_Rule_Set__c, normalize(r.Rule_Code__c), root));
                apiRoot.put(r.Id, root);
                apiRuleCode.put(r.Id, normalize(r.Rule_Code__c));
            }
        }
        if (permRules != null) {
            for (Promotion_Rule__c r : permRules) {
                String root = permRoot.get(r.Promotion_Rule_Set__c);
                permNodes.add(new Node(r.Id, r.Promotion_Rule_Set__c, normalize(r.Rule_Code__c), root));
                permRoot.put(r.Id, root);
                permRuleCode.put(r.Id, normalize(r.Rule_Code__c));
            }
        }
        matchLevel(apiNodes, permNodes, result);

        // ---------------- Rule Progress: parent rule (code = parent rule code) ----------------
        apiNodes  = new List<Node>();
        permNodes = new List<Node>();
        if (apiProgress != null) {
            for (API_Promotion_Rule_Progress__c r : apiProgress) {
                String ruleCode = apiRuleCode.containsKey(r.API_Promotion_Rules__c) ? apiRuleCode.get(r.API_Promotion_Rules__c) : '';
                apiNodes.add(new Node(r.Id, r.API_Promotion_Rules__c, ruleCode, apiRoot.get(r.API_Promotion_Rules__c)));
            }
        }
        if (permProgress != null) {
            for (Promotion_Rule_Progress__c r : permProgress) {
                String ruleCode = permRuleCode.containsKey(r.Promotion_Rule__c) ? permRuleCode.get(r.Promotion_Rule__c) : '';
                permNodes.add(new Node(r.Id, r.Promotion_Rule__c, ruleCode, permRoot.get(r.Promotion_Rule__c)));
            }
        }
        matchLevel(apiNodes, permNodes, result);

        result.remove(ROOT);
        return result;
    }

    private static void matchLevel(List<Node> apiNodes, List<Node> permNodes, Map<String,String> result) {
        Map<String, List<Node>> permByParent = new Map<String, List<Node>>();
        Map<String, List<Node>> permByRoot   = new Map<String, List<Node>>();
        for (Node p : permNodes) {
            addNode(permByParent, p.parentId + '#' + p.code, p);
            if (p.rootId != null) addNode(permByRoot, p.rootId + '#' + p.code, p);
        }

        Set<String> used = new Set<String>();
        List<Node> unmatched = new List<Node>();

        // Pass 1: same parent record + same code
        for (Node a : apiNodes) {
            String permParent = (a.parentId == null) ? null : result.get(a.parentId);
            Node hit = (permParent == null) ? null : takeFirstUnused(permByParent.get(permParent + '#' + a.code), used);
            if (hit != null) {
                result.put(a.id, hit.id);
            } else {
                unmatched.add(a);
            }
        }

        // Pass 2: same enrollment + same code (record was saved under the wrong parent earlier)
        for (Node a : unmatched) {
            String permRootId = (a.rootId == null) ? null : result.get(a.rootId);
            if (permRootId == null) continue;
            Node hit = takeFirstUnused(permByRoot.get(permRootId + '#' + a.code), used);
            if (hit != null) {
                result.put(a.id, hit.id);
            }
        }
    }

    private static Node takeFirstUnused(List<Node> candidates, Set<String> used) {
        if (candidates == null) return null;
        for (Node c : candidates) {
            if (!used.contains(c.id)) {
                used.add(c.id);
                return c;
            }
        }
        return null;
    }

    private static void addNode(Map<String, List<Node>> target, String key, Node n) {
        if (!target.containsKey(key)) target.put(key, new List<Node>());
        target.get(key).add(n);
    }

    private static String normalize(String value) {
        return value == null ? '' : value.trim().toUpperCase();
    }
}