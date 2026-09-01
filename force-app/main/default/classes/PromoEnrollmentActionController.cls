public with sharing class PromoEnrollmentActionController {

    public class CaseInfo {
        @AuraEnabled public String caseNumber;
        @AuraEnabled public String accountNumber;
        @AuraEnabled public String promoCode; // Case.Promotion_Promo_Code__c
        @AuraEnabled public String servicesChallengingCategory;
        @AuraEnabled public String initiativeTracking;
        @AuraEnabled public String reliefProvided;
        @AuraEnabled public String reliefType;
        @AuraEnabled public Decimal remediation;
    }

    // ----------------- Helpers -----------------
    private static Case getCaseLite(Id caseId) {
        if (caseId == null) throw new AuraHandledException('Missing caseId.');
        return [SELECT Id, CaseNumber, Promotion_Promo_Code__c, Account_Number__c,
                Cat_Level_5__c,Single_Use_Promo_Code__c,Promotion_CIF__c,Promotion_Account_Product_Code__c,Promotion_Account_Status__c,
                Promotion_Account_Opening_Date__c ,Servicing_Challenges_Category__c,Initiative_Tracking__c,Refund__c,Type_of_Refund__c,Remediation__c
                FROM Case WHERE Id = :caseId LIMIT 1]; 
    }


    @AuraEnabled
    public static String basicEARUpdates(Id enrollmentActionRecordId, Id caseId,String offerCode,
                                            String casePromo , String selectedReasonCode, String selectedRewardCode,
                                            String TransactionType,String Comments,String employeId) {
          
         
system.debug('Params: ' +
        'enrollmentActionRecordId=' + enrollmentActionRecordId +
        ', caseId=' + caseId +
        ', offerCode=' + offerCode +
        ', casePromo=' + casePromo +
        ', selectedReasonCode=' + selectedReasonCode +
        ', selectedRewardCode=' + selectedRewardCode +
        ', TransactionType =' + TransactionType

    );
 
              system.debug('running basicEARUpdates');

         enrollment_Activity__c record ;  
        if(enrollmentActionRecordId == null){
                record = new Enrollment_Activity__c();
            }
            else{
                 record = new Enrollment_Activity__c(id= enrollmentActionRecordId);
            }
                 record.case_Number__c =  caseId;

    list<case> caseData =  new List<case>(); ///[SELECT id, Account_Number__c, ];
    caseData = [SELECT id, Account_Number__c, Promotion_Account_Opening_Date__c, Promotion_CIF__c,
                 Promotion_Account_Product_Code__c,caseNumber
                 From case where id =: caseId];

        // ===== Requested Fields =====
        record.Req_Account__c = caseData[0].Account_Number__c; //case obj x
        record.Req_Account_Cycle_Type__c = 'CALENDAR'; //x
        record.Req_Comments__c = 'test'; //\auto fill
        record.Req_Effective_Date__c = Date.today(); //screem TODAY()
        record.Req_First_Financial_Activity_Date__c = caseData[0].Promotion_Account_Opening_Date__c;// Date.today(); //case.promo_account_opening_date//x
        record.Req_Name__c = 'promo code'; // promo code
        record.Req_Offer_Code__c = offerCode;
        record.Req_Opening_Date__c = caseData[0].Promotion_Account_Opening_Date__c; // case.Prom_accout_opening_date //x
        record.Req_Primary_CIF__c =  caseData[0].Promotion_CIF__c; //case // x
        record.Req_Product_Code__c = caseData[0].Promotion_Account_Product_Code__c; // case // promotion_product cif field
        record.Req_Promo_Code__c = casePromo; // screen
        if(selectedReasonCode != null){
            record.Req_Reason_Code__c = selectedReasonCode; //screen
        }
        else{
            record.Req_Reason_Code__c = 'None Selected'; //screen
        }
        record.Req_Reward_Code__c = selectedRewardCode; // screen
        record.Req_Skip_Eligibility_Rules__c = 'TRUE'; //true
        record.Req_Source__c = caseData[0].caseNumber; //human read case number
        record.Req_Value__c = casePromo; // screen req_promo code
        record.Req_Initiator_2__c = getRunningUserTruistId(); // from user
        record.Transaction_Type__c = TransactionType;
        record.Req_Comments__c = Comments;
        record.Req_Initiator_2__c = employeId;
        upsert(record);
        return record.id;
    }

    @AuraEnabled(cacheable=false)
    public static CaseInfo getCaseInfo(Id caseId) {
        System.debug('PromoEnrollmentActionController.getCaseInfo caseId => ' + caseId);
        Case c = getCaseLite(caseId);
        system.debug('checkcasedata' + c.Remediation__c);

        CaseInfo info = new CaseInfo();
        info.caseNumber    = c.CaseNumber;
        info.accountNumber = c.Account_Number__c;       // Case custom field
        info.promoCode     = c.Single_Use_Promo_Code__c; // Case custom field
        info.servicesChallengingCategory = c.Servicing_Challenges_Category__c;
        info.initiativeTracking = c.Initiative_Tracking__c;
        info.reliefProvided = c.Refund__c;
        info.reliefType     = c.Type_of_Refund__c;
        info.remediation     = c.Remediation__c;

        return info;
    }

    @AuraEnabled(cacheable=false)
    public static List<Enrollment_Activity__c> getEnrollmentActivitiesByCase(Id caseId) {
        if (caseId == null) {
            throw new AuraHandledException('caseId is required.');
        }
        List<Enrollment_Activity__c> raw = [
            SELECT Id,Name,OwnerId,Transaction_Type__c,Zafin_Request__c,Zafin_Request_DateTime__c,Req_Effective_Date__c,
                   Req_Initiator__c,Req_Initiator__r.Name,Req_Initiator__r.truist__Truist_User_ID__c,
                   Req_Offer_Code__c,Req_Reward_Code__c,Req_Account__c,Req_Reason_Code__c,Case_Number_Text__c,
                   Req_Promo_Code__c,Resp_Promo_Code__c,Resp_Error__c,Resp_Message__c,Req_Initiator_2__c
            FROM Enrollment_Activity__c
            WHERE Case_Number__c = :caseId
            ORDER BY CreatedDate DESC
            LIMIT 2000
        ];

        SObjectAccessDecision dec = Security.stripInaccessible(AccessType.READABLE, raw);
        return (List<Enrollment_Activity__c>) dec.getRecords();
    }

    @AuraEnabled(cacheable=true)
    public static List<Promotion_Enrollment__c> getPromotionEnrollmentsByCase2(Id caseId) {
        if (caseId == null) throw new AuraHandledException('caseId is required.');

        Case c = getCaseLite(caseId);

        List<Promotion_Enrollment__c> raw = [
            SELECT Id,Name,Offer_Code__c,Offer_Name__c
            FROM Promotion_Enrollment__c
            WHERE case_Number__c = :c.Id
            ORDER BY CreatedDate DESC
            LIMIT 2000
        ];

        SObjectAccessDecision dec = Security.stripInaccessible(AccessType.READABLE, raw);
        return (List<Promotion_Enrollment__c>) dec.getRecords();
    }

    @AuraEnabled(cacheable=false)
    public static List<Promotion_Enrollment__c> getPromotionEnrollmentsByCase(Id caseId) {
        if (caseId == null) throw new AuraHandledException('caseId is required.');

        Case c = getCaseLite(caseId);

        List<Promotion_Enrollment__c> raw = [
            SELECT Id,Name,Offer_Code__c,Offer_Name__c
            FROM Promotion_Enrollment__c
            WHERE case_Number__c = :c.Id
            ORDER BY CreatedDate DESC
            LIMIT 2000
        ];

        SObjectAccessDecision dec = Security.stripInaccessible(AccessType.READABLE, raw);
        return (List<Promotion_Enrollment__c>) dec.getRecords();
    }


    @AuraEnabled(cacheable=true)
    public static List<promOffers> getofferRewardsStructure(Id caseId) {
        if (caseId == null) {
            throw new AuraHandledException('caseId is required.');
        }
        List<promOffers> out = new List<promOffers>();
        Case c = getCaseLite(caseId);
        List<Promotion_Enrollment__c> enrollmentsRaw = [
            SELECT Id,Name,Offer_Code__c,Offer_Name__c
            FROM Promotion_Enrollment__c
            WHERE case_Number__c = :c.Id
            ORDER BY CreatedDate DESC
            LIMIT 2000
        ];
        SObjectAccessDecision eDec = Security.stripInaccessible(AccessType.READABLE, enrollmentsRaw);
        List<Promotion_Enrollment__c> enrollments =
            (List<Promotion_Enrollment__c>) eDec.getRecords();
        if (enrollments.isEmpty()) {
            return out;
        }
        Set<Id> enrollmentIds = new Set<Id>();
        for (Promotion_Enrollment__c e : enrollments) enrollmentIds.add(e.Id);
        List<Promotion_Rewards__c> rewardsRaw = new List<Promotion_Rewards__c>();
         rewardsRaw = [SELECT Id, Name, Promotion_Enrollment_Number__c,Reward_Name__c,Reward_Code__c 
         FROM Promotion_Rewards__c WHERE Promotion_Enrollment_Number__c IN :enrollmentIds ORDER BY CreatedDate DESC LIMIT 5000];
        SObjectAccessDecision rDec = Security.stripInaccessible(AccessType.READABLE, rewardsRaw);
        List<Promotion_Rewards__c> rewards =
            (List<Promotion_Rewards__c>) rDec.getRecords();
        Map<Id, List<Promotion_Rewards__c>> rewardsMap = new Map<Id, List<Promotion_Rewards__c>>();
        for (Promotion_Rewards__c rw : rewards) {
            Id parentId = rw.Promotion_Enrollment_Number__c;
            if (!rewardsMap.containsKey(parentId)) {
                rewardsMap.put(parentId, new List<Promotion_Rewards__c>());
            }
            rewardsMap.get(parentId).add(rw);
        }
        for (Promotion_Enrollment__c eRec : enrollments) {
            promOffers po = new promOffers();
            po.enrollmentRecord = eRec;
            List<Promotion_Rewards__c> children = rewardsMap.get(eRec.Id);
            if (children != null && !children.isEmpty()) {
                for (Promotion_Rewards__c rRec : children) {
                    promoReward pr = new promoReward();
                    pr.reward = rRec;
                    po.rewardList.add(pr);
                }
            }
            out.add(po);
        }
        return out;
    }

    @AuraEnabled(cacheable=true)
    public static List<Promotion_Enrollment__c> getPromotionEnrollmentsByAccount(Id caseId) {
        if (String.isBlank(String.valueOf(caseId))) {
            throw new AuraHandledException('caseId is required.');
        }

        List<Promotion_Enrollment__c> raw =new List<Promotion_Enrollment__c>(); 
        raw = [SELECT Id, Name,Offer_Code__c,Offer_Name__c FROM Promotion_Enrollment__c WHERE Case_Number__c = :caseId
               ORDER BY CreatedDate DESC LIMIT 2000];

        SObjectAccessDecision dec = Security.stripInaccessible(AccessType.READABLE, raw);
        return (List<Promotion_Enrollment__c>) dec.getRecords();
    }

    public class ComboboxOption {
        @AuraEnabled public String label;
        @AuraEnabled public String value;
        @AuraEnabled public String code;
        @AuraEnabled public String name;

        public ComboboxOption(String label, String value) {
            this.label = label;
            this.value = value;
        }
        public ComboboxOption(String label, String value, String code, String name) {
            this.label = label;
            this.value = value;
            this.code  = code;
            this.name  = name;
        }
    }

    public class EnrollmentWithRewards {
        @AuraEnabled public String enrollmentId;
        @AuraEnabled public String enrollmentLabel;
        @AuraEnabled public List<ComboboxOption> rewardOptions = new List<ComboboxOption>();
    }

    @AuraEnabled(cacheable=true)
    public static List<EnrollmentWithRewards> getEnrollmentsWithRewardsByCase(Id caseId) {
        if (caseId == null) {
            throw new AuraHandledException('caseId is required.');
        }

        Case c = getCaseLite(caseId);
        List<Promotion_Enrollment__c> enrollmentsRaw = [SELECT Id,Name,Offer_Code__c,Offer_Name__c FROM Promotion_Enrollment__c           WHERE case_Number__c = :c.Id
                                                        ORDER BY CreatedDate DESC LIMIT 2000];

        SObjectAccessDecision enrollDec = Security.stripInaccessible(AccessType.READABLE, enrollmentsRaw);
        List<Promotion_Enrollment__c> enrollments = (List<Promotion_Enrollment__c>) enrollDec.getRecords();
        if (enrollments.isEmpty()) {
            return new List<EnrollmentWithRewards>();
        }
        Set<Id> enrollmentIds = new Set<Id>();
        for (Promotion_Enrollment__c pe : enrollments) {
            enrollmentIds.add(pe.Id);
        }
        List<Promotion_Rewards__c> rewardsRaw = new List<Promotion_Rewards__c>(); 
        rewardsRaw = [SELECT Id,Reward_Code__c,Reward_Name__c,Promotion_Enrollment_Number__c FROM Promotion_Rewards__c 
                      WHERE Promotion_Enrollment_Number__c IN :enrollmentIds ORDER BY Reward_Name__c NULLS LAST LIMIT 5000];

        SObjectAccessDecision rewardsDec = Security.stripInaccessible(AccessType.READABLE, rewardsRaw);
        List<Promotion_Rewards__c> rewards =
            (List<Promotion_Rewards__c>) rewardsDec.getRecords();

        Map<Id, List<Promotion_Rewards__c>> rewardsByEnrollment = new Map<Id, List<Promotion_Rewards__c>>();
        for (Promotion_Rewards__c r : rewards) {
            Id parentId = r.Promotion_Enrollment_Number__c;
            if (!rewardsByEnrollment.containsKey(parentId)) {
                rewardsByEnrollment.put(parentId, new List<Promotion_Rewards__c>());
            }
            rewardsByEnrollment.get(parentId).add(r);
        }

        List<EnrollmentWithRewards> payload = new List<EnrollmentWithRewards>();
        for (Promotion_Enrollment__c pe : enrollments) {
            EnrollmentWithRewards ewr = new EnrollmentWithRewards();
            ewr.enrollmentId = pe.Id;

            String offerName = pe.Offer_Name__c;
            String offerCode = pe.Offer_Code__c;
            if (!String.isBlank(offerName) && !String.isBlank(offerCode)) {
                ewr.enrollmentLabel = offerName + ' (' + offerCode + ')';
            } else if (!String.isBlank(offerName)) {
                ewr.enrollmentLabel = offerName;
            } else if (!String.isBlank(offerCode)) {
                ewr.enrollmentLabel = offerCode;
            } else {
                ewr.enrollmentLabel = pe.Name;
            }

            List<Promotion_Rewards__c> childRewards = rewardsByEnrollment.get(pe.Id);
            if (childRewards != null && !childRewards.isEmpty()) {
                for (Promotion_Rewards__c r : childRewards) {
                    String rewardLabel =
                        (String.isBlank(r.Reward_Name__c) ? '' : r.Reward_Name__c) +
                        (String.isBlank(r.Reward_Code__c) ? '' : ' (' + r.Reward_Code__c + ')');

                    ewr.rewardOptions.add(
                        new ComboboxOption(
                            String.isBlank(rewardLabel) ? r.Id : rewardLabel,
                            r.Id,
                            r.Reward_Code__c,
                            r.Reward_Name__c
                        )
                    );
                }
            }

            payload.add(ewr);
        }

        return payload;
    }

    @AuraEnabled(cacheable=true)
    public static List<ComboboxOption> getRewardOptionsByEnrollment(Id enrollmentId) {
        System.debug('getRewardOptionsByEnrollment enrollmentId: ' + enrollmentId);

        if (enrollmentId == null) {
            throw new AuraHandledException('enrollmentId is required.');
        }

        List<Promotion_Rewards__c> raw = [
            SELECT Id,
                   Reward_Code__c,
                   Reward_Name__c,
                   Promotion_Enrollment_Number__c
            FROM Promotion_Rewards__c
            WHERE Promotion_Enrollment_Number__c = :enrollmentId
            ORDER BY Reward_Name__c NULLS LAST
            LIMIT 2000
        ];
        System.debug('getRewardOptionsByEnrollment rewards: ' + raw);

        SObjectAccessDecision dec = Security.stripInaccessible(AccessType.READABLE, raw);
        List<Promotion_Rewards__c> rewards = (List<Promotion_Rewards__c>) dec.getRecords();

        List<ComboboxOption> options = new List<ComboboxOption>();
        for (Promotion_Rewards__c r : rewards) {
            String label =
                (String.isBlank(r.Reward_Name__c) ? '' : r.Reward_Name__c) +
                (String.isBlank(r.Reward_Code__c) ? '' : ' (' + r.Reward_Code__c + ')');

            options.add(new ComboboxOption(
                String.isBlank(label) ? r.Id : label,
                r.Id,
                r.Reward_Code__c,
                r.Reward_Name__c
            ));
        }
        return options;
    }

    public class promOffers {
        @AuraEnabled public Promotion_Enrollment__c enrollmentRecord;
        @AuraEnabled public List<promoReward> rewardList = new List<promoReward>();
    }
    public class promoReward {
        @AuraEnabled 
        public Promotion_Rewards__c reward = new Promotion_Rewards__c();
    }


@AuraEnabled(cacheable=true)
   public static userPermissions runingUserProfileAndPermissionSets(){
          
  
 userPermissions perms = new userPermissions();
    Id currentUserId = UserInfo.getUserId();

    // ---- Query User Profile ----
    User u = [
        SELECT Id, Name, Profile.Name
        FROM User
        WHERE Id = :currentUserId
    ];

    System.debug('User Name: ' + u.Name);
    System.debug('Profile Name: ' + u.Profile.Name);

    // ---- SYSTEM ADMIN OVERRIDE ----
    if (u.Profile.Name == 'System Administrator') {
        perms.saveButton           = true;
        perms.submitButton         = true;
        perms.forceEnrollButton    = true;
        perms.forcePayButton       = true;
        perms.rewardReversalButton = true;
        perms.fieldAccess          = true;
        perms.accountStatusOverrideButton = true;

        System.debug('System Administrator detected — full access granted');
        return perms;
    }

    // ---- Gather Permission Set Names ----
    Set<String> permissionSetNames = new Set<String>();
    for (PermissionSetAssignment psa : [
        SELECT PermissionSet.Name
        FROM PermissionSetAssignment
        WHERE AssigneeId = :currentUserId
    ]) {
        permissionSetNames.add(psa.PermissionSet.Name);
    }

    System.debug('Permission Sets: ' + permissionSetNames);

    // ---- Permission Set Constants ----
    String APPROVER = 'Promotion_Escalation_Approver';
    String REVIEWER = 'Promotion_Escalation_Reviewer';
    String ASSIGNOR = 'Promotion_Escalation_Assignor';

    // ---- Defaults (greyed out) ----
    perms.saveButton           = false;
    perms.submitButton         = false;
    perms.forceEnrollButton    = false;
    perms.forcePayButton       = false;
    perms.rewardReversalButton = false;
    perms.fieldAccess          = false;
    perms.accountStatusOverrideButton = false;

    // ---- Apply Chart Logic ----
    if (permissionSetNames.contains(APPROVER)) {

        // ✅ Approver = full access
        perms.saveButton           = true;
        perms.submitButton         = true;
        perms.forceEnrollButton    = true;
        perms.forcePayButton       = true;
        perms.rewardReversalButton = true;
        perms.fieldAccess          = true;
        perms.accountStatusOverrideButton = true;

    } else if (permissionSetNames.contains(REVIEWER)) {

        // ✅ Reviewer = partial access
        perms.saveButton           = true;
        perms.submitButton         = false;
        perms.forceEnrollButton    = true;
        perms.forcePayButton       = true;
        perms.rewardReversalButton = true;
        perms.fieldAccess          = true;

    }

    System.debug('Resolved userPermissions: ' + perms);
    return perms;

    }

@AuraEnabled
public static  zafinReturn sendPromoActionFromLwc(Id enrollmentActivityId) {
    zafinReturn returnPackage = new zafinReturn();
    ZafinOfferService.ZafinResponseDTO response;
        system.debug('show submit activity ID ' + enrollmentActivityId);

    List<Enrollment_Activity__c> eaRecords = new list<Enrollment_Activity__c>();
    eaRecords = [Select Id , Req_Primary_CIF__c FROM Enrollment_Activity__c
      where Id = : enrollmentActivityId];
    system.debug('show pre cif ' + eaRecords[0].Req_Primary_CIF__c);

    eaRecords[0].Req_Primary_CIF__c = dropLeadingZeros(eaRecords[0].Req_Primary_CIF__c);
            system.debug('show post cif ' + eaRecords[0].Req_Primary_CIF__c);

  //  update(eaRecords);
    try {
        system.debug('calling zafin sendPromoActionSync');
        response = ZafinOfferService.sendPromoActionSync(enrollmentActivityId);
        List<Enrollment_Activity__c> eaRecordsAfter = new List<Enrollment_Activity__c>();
        eaRecordsAfter = [Select Id ,name, Resp_Error__c ,Resp_Message__c FROM Enrollment_Activity__c where Id = : enrollmentActivityId];
        system.debug('show submit activity ID ' + enrollmentActivityId);
        if (response.statusCode >= 200 && response.statusCode < 300) {
            update new Enrollment_Activity__c(
                Id = enrollmentActivityId,
                Zafin_Request__c = 'Sent',
                Zafin_Request_DateTime__c = System.now()
            );
        }
        else {
            update new Enrollment_Activity__c(
                Id = enrollmentActivityId,
                Zafin_Request__c = 'Error'
            );
        }
        returnPackage.zafinPackage = response;
        returnPackage.recordName = eaRecordsAfter[0].name;
        returnPackage.zafinError = eaRecordsAfter[0].Resp_Error__c;
        returnPackage.zafinMessage =  eaRecordsAfter[0].Resp_Message__c;
    } catch (Exception e) {
        update new Enrollment_Activity__c(
            Id = enrollmentActivityId,
            Zafin_Request__c = 'Error'
        );
        throw e;
    }
    return returnPackage;
}


    @AuraEnabled
    public static void markZafinSuccess(Id enrollmentActivityId) {
        Enrollment_Activity__c ea = new Enrollment_Activity__c(
            Id = enrollmentActivityId,
            Zafin_Post_Processing__c = true,
            Zafin_Request_DateTime__c = System.now()
        );
        update ea;
    }

    public class userPermissions{
        @AuraEnabled    public boolean  saveButton;  
        @AuraEnabled    public boolean  submitButton;
        @AuraEnabled    public boolean  forcePayButton;  
        @AuraEnabled    public boolean  forceEnrollButton;
        @AuraEnabled    public boolean  rewardReversalButton; 
        @AuraEnabled    public boolean fieldAccess; 
        @AuraEnabled    public boolean accountStatusOverrideButton;
    }
    public class zafinReturn{
     @AuraEnabled public  ZafinOfferService.ZafinResponseDTO zafinPackage;
     @AuraEnabled public  String recordName;
     @AuraEnabled public  String zafinError;
     @AuraEnabled public  String zafinMessage;
    }

  
 

public static String getRunningUserTruistId() {
    User u = [
        SELECT Truist__Truist_User_ID__c
        FROM User
        WHERE Id = :UserInfo.getUserId()
        LIMIT 1
    ];

    return u.Truist__Truist_User_ID__c;
}

public static String dropLeadingZeros (String inStr) {
    while ( !String.isBlank(inStr) && inStr.startsWith('0') ) inStr = inStr.removeStart('0');
    if ( String.isBlank(inStr) ) return '0';
    if ( inStr.startsWith('.') ) inStr = '0' + inStr;
    return inStr;
}
}