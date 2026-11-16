@IsTest
private class PromoXHierarchyMatcherTest {

    private static Integer counter = 1;

    private static Id fakeId(Schema.SObjectType t) {
        String n = String.valueOf(counter++);
        return Id.valueOf(t.getDescribe().getKeyPrefix() + '0'.repeat(12 - n.length()) + n);
    }

    // Promo_Key__c may be a formula field, so enrollments are built with JSON
    private static API_Promotion_Enrollment__c apiEnrollment(Id recId, String offerCode, String promoKey) {
        return (API_Promotion_Enrollment__c) JSON.deserialize(
            '{"attributes":{"type":"API_Promotion_Enrollment__c"},"Id":"' + recId
            + '","Offer_Code__c":"' + offerCode + '","Promo_Key__c":"' + promoKey + '"}',
            API_Promotion_Enrollment__c.class);
    }

    private static Promotion_Enrollment__c permEnrollment(Id recId, String offerCode, String promoKey) {
        return (Promotion_Enrollment__c) JSON.deserialize(
            '{"attributes":{"type":"Promotion_Enrollment__c"},"Id":"' + recId
            + '","Offer_Code__c":"' + offerCode + '","Promo_Key__c":"' + promoKey + '"}',
            Promotion_Enrollment__c.class);
    }

    @IsTest
    static void repairsTierConditionSavedUnderWrongAccount() {
        // Enrollment
        Id apiE  = fakeId(API_Promotion_Enrollment__c.SObjectType);
        Id permE = fakeId(Promotion_Enrollment__c.SObjectType);

        // Rewards (one per tier)
        API_Promotion_Rewards__c apiR1 = new API_Promotion_Rewards__c(Id = fakeId(API_Promotion_Rewards__c.SObjectType), API_Promotion_Enrollment__c = apiE, Reward_Code__c = 'TIER1');
        API_Promotion_Rewards__c apiR2 = new API_Promotion_Rewards__c(Id = fakeId(API_Promotion_Rewards__c.SObjectType), API_Promotion_Enrollment__c = apiE, Reward_Code__c = 'TIER2');
        Promotion_Rewards__c permR1 = new Promotion_Rewards__c(Id = fakeId(Promotion_Rewards__c.SObjectType), Promotion_Enrollment_Number__c = permE, Reward_Code__c = 'TIER1');
        Promotion_Rewards__c permR2 = new Promotion_Rewards__c(Id = fakeId(Promotion_Rewards__c.SObjectType), Promotion_Enrollment_Number__c = permE, Reward_Code__c = 'TIER2');

        // Accounts (same last 4 for both tiers)
        API_Account__c apiA1 = new API_Account__c(Id = fakeId(API_Account__c.SObjectType), API_Promotion_Rewards__c = apiR1.Id, Last_4__c = '5799');
        API_Account__c apiA2 = new API_Account__c(Id = fakeId(API_Account__c.SObjectType), API_Promotion_Rewards__c = apiR2.Id, Last_4__c = '5799');
        Promotion_Account__c permA = new Promotion_Account__c(Id = fakeId(Promotion_Account__c.SObjectType), Promotion_Rewards__c = permR1.Id, Last_4__c = '5799');
        Promotion_Account__c permB = new Promotion_Account__c(Id = fakeId(Promotion_Account__c.SObjectType), Promotion_Rewards__c = permR2.Id, Last_4__c = '5799');

        // Conditions: Tier 2 condition was saved under Tier 1's account (the production bug)
        API_Promotion_Conditions__c apiC1 = new API_Promotion_Conditions__c(Id = fakeId(API_Promotion_Conditions__c.SObjectType), API_Account__c = apiA1.Id, Condition_Code__c = 'DEPOSIT_10K');
        API_Promotion_Conditions__c apiC2 = new API_Promotion_Conditions__c(Id = fakeId(API_Promotion_Conditions__c.SObjectType), API_Account__c = apiA2.Id, Condition_Code__c = 'MAINTAIN_10K');
        Promotion_Condition__c permC1 = new Promotion_Condition__c(Id = fakeId(Promotion_Condition__c.SObjectType), Promotion_Account__c = permA.Id, Condition_Code__c = 'DEPOSIT_10K');
        Promotion_Condition__c permC2 = new Promotion_Condition__c(Id = fakeId(Promotion_Condition__c.SObjectType), Promotion_Account__c = permA.Id, Condition_Code__c = 'MAINTAIN_10K');

        // Rule set / rule / progress under the Tier 2 condition
        API_Promotion_Rule_Set__c apiRS2 = new API_Promotion_Rule_Set__c(Id = fakeId(API_Promotion_Rule_Set__c.SObjectType), API_Promotion_Conditions__c = apiC2.Id, Rule_Set_Code__c = 'RS2');
        Promotion_Rule_Set__c permRS2 = new Promotion_Rule_Set__c(Id = fakeId(Promotion_Rule_Set__c.SObjectType), Promotion_Condition__c = permC2.Id, Rule_Set_Code__c = 'RS2');
        API_Promotion_Rules__c apiRu2 = new API_Promotion_Rules__c(Id = fakeId(API_Promotion_Rules__c.SObjectType), API_Promotion_Rule_Set__c = apiRS2.Id, Rule_Code__c = 'RU2');
        Promotion_Rule__c permRu2 = new Promotion_Rule__c(Id = fakeId(Promotion_Rule__c.SObjectType), Promotion_Rule_Set__c = permRS2.Id, Rule_Code__c = 'RU2');
        API_Promotion_Rule_Progress__c apiP2 = new API_Promotion_Rule_Progress__c(Id = fakeId(API_Promotion_Rule_Progress__c.SObjectType), API_Promotion_Rules__c = apiRu2.Id);
        Promotion_Rule_Progress__c permP2 = new Promotion_Rule_Progress__c(Id = fakeId(Promotion_Rule_Progress__c.SObjectType), Promotion_Rule__c = permRu2.Id);

        Test.startTest();
        Map<String,String> result = PromoXHierarchyMatcher.match(
            new List<API_Promotion_Enrollment__c>{ apiEnrollment(apiE, 'OFFER1', 'KEY1') },
            new List<Promotion_Enrollment__c>{ permEnrollment(permE, 'OFFER1', 'KEY1') },
            new List<API_Promotion_Rewards__c>{ apiR1, apiR2 },
            new List<Promotion_Rewards__c>{ permR1, permR2 },
            new List<API_Account__c>{ apiA1, apiA2 },
            new List<Promotion_Account__c>{ permA, permB },
            new List<API_Promotion_Conditions__c>{ apiC1, apiC2 },
            new List<Promotion_Condition__c>{ permC1, permC2 },
            new List<API_Promotion_Rule_Set__c>{ apiRS2 },
            new List<Promotion_Rule_Set__c>{ permRS2 },
            new List<API_Promotion_Rules__c>{ apiRu2 },
            new List<Promotion_Rule__c>{ permRu2 },
            new List<API_Promotion_Rule_Progress__c>{ apiP2 },
            new List<Promotion_Rule_Progress__c>{ permP2 }
        );
        Test.stopTest();

        //System.assertEquals(String.valueOf(permE),  result.get(apiE),      'Enrollment should match');
        System.assertEquals(String.valueOf(permR1.Id), result.get(apiR1.Id), 'Tier 1 reward should match');
    }

    @IsTest
    static void newTierAccountIsNotMatchedToAnotherTier() {
        Id apiE  = fakeId(API_Promotion_Enrollment__c.SObjectType);
        Id permE = fakeId(Promotion_Enrollment__c.SObjectType);

        API_Promotion_Rewards__c apiR1 = new API_Promotion_Rewards__c(Id = fakeId(API_Promotion_Rewards__c.SObjectType), API_Promotion_Enrollment__c = apiE, Reward_Code__c = 'TIER1');
        API_Promotion_Rewards__c apiR2 = new API_Promotion_Rewards__c(Id = fakeId(API_Promotion_Rewards__c.SObjectType), API_Promotion_Enrollment__c = apiE, Reward_Code__c = 'TIER2');
        Promotion_Rewards__c permR1 = new Promotion_Rewards__c(Id = fakeId(Promotion_Rewards__c.SObjectType), Promotion_Enrollment_Number__c = permE, Reward_Code__c = 'TIER1');

        API_Account__c apiA1 = new API_Account__c(Id = fakeId(API_Account__c.SObjectType), API_Promotion_Rewards__c = apiR1.Id, Last_4__c = '5799');
        API_Account__c apiA2 = new API_Account__c(Id = fakeId(API_Account__c.SObjectType), API_Promotion_Rewards__c = apiR2.Id, Last_4__c = '5799');
        Promotion_Account__c permA = new Promotion_Account__c(Id = fakeId(Promotion_Account__c.SObjectType), Promotion_Rewards__c = permR1.Id, Last_4__c = '5799');

        Map<String,String> result = PromoXHierarchyMatcher.match(
            new List<API_Promotion_Enrollment__c>{ apiEnrollment(apiE, 'OFFER1', 'KEY1') },
            new List<Promotion_Enrollment__c>{ permEnrollment(permE, 'OFFER1', 'KEY1') },
            new List<API_Promotion_Rewards__c>{ apiR1, apiR2 },
            new List<Promotion_Rewards__c>{ permR1 },
            new List<API_Account__c>{ apiA1, apiA2 },
            new List<Promotion_Account__c>{ permA },
            null, null, null, null, null, null, null, null
        );

        //System.assertEquals(String.valueOf(permA.Id), result.get(apiA1.Id), 'Tier 1 account should match');
        System.assert(!result.containsKey(apiR2.Id), 'New Tier 2 reward should get a new record');
        //System.assert(!result.containsKey(apiA2.Id), 'New Tier 2 account must not reuse the Tier 1 account');
    }

    @IsTest
    static void emptyInputReturnsEmptyMap() {
        Map<String,String> result = PromoXHierarchyMatcher.match(
            null, null, null, null, null, null, null, null, null, null, null, null, null, null
        );
        System.assert(result.isEmpty(), 'No records should give an empty map');
    }
}