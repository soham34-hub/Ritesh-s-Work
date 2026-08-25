public with sharing class AccountController {

    @AuraEnabled(cacheable=true)
    public static String getRecordTypeName(Id recordTypeId) {
        try {
            Map<Id, Schema.RecordTypeInfo> rtMap =
                Schema.SObjectType.Account.getRecordTypeInfosById();
            if (rtMap.containsKey(recordTypeId)) {
                return rtMap.get(recordTypeId).getDeveloperName();
            }
            return null;
        } catch (Exception e) {
            throw new AuraHandledException('Record type not found: ' + e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<AccountRecordTypeInfo> getAccountRecordTypes() {
        List<AccountRecordTypeInfo> result = new List<AccountRecordTypeInfo>();
        Map<String, Schema.RecordTypeInfo> rtMap =
            Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName();
        for (String devName : rtMap.keySet()) {
            Schema.RecordTypeInfo rti = rtMap.get(devName);
            if (rti.isAvailable() && !rti.isMaster()) {
                result.add(new AccountRecordTypeInfo(
                    rti.getRecordTypeId(),
                    rti.getDeveloperName(),
                    rti.getName()
                ));
            }
        }
        return result;
    }

    public class AccountRecordTypeInfo {
        @AuraEnabled public String id { get; set; }
        @AuraEnabled public String developerName { get; set; }
        @AuraEnabled public String name { get; set; }
        public AccountRecordTypeInfo(String id, String developerName, String name) {
            this.id = id;
            this.developerName = developerName;
            this.name = name;
        }
    }

    @AuraEnabled
    public static String createAccount(Map<String, Object> accountData) {
        try {
            Account acc = new Account();

            if (accountData.containsKey('Name'))
                acc.Name = (String) accountData.get('Name');
            if (accountData.containsKey('RecordTypeId'))
                acc.RecordTypeId = (Id) accountData.get('RecordTypeId');
            if (accountData.containsKey('Type'))
                acc.Type = (String) accountData.get('Type');
            if (accountData.containsKey('Phone'))
                acc.Phone = (String) accountData.get('Phone');
            if (accountData.containsKey('Fax'))
                acc.Fax = (String) accountData.get('Fax');
            if (accountData.containsKey('Description'))
                acc.Description = (String) accountData.get('Description');
            if (accountData.containsKey('ParentId'))
                acc.ParentId = (Id) accountData.get('ParentId');
            if (accountData.containsKey('Doing_Business_As_DBA__c'))
                acc.Doing_Business_As_DBA__c = (String) accountData.get('Doing_Business_As_DBA__c');
            if (accountData.containsKey('Legal_Entity_Type__c'))
                acc.Legal_Entity_Type__c = (String) accountData.get('Legal_Entity_Type__c');
            if (accountData.containsKey('General_Partnership_Type__c'))
                acc.General_Partnership_Type__c = (String) accountData.get('General_Partnership_Type__c');
            if (accountData.containsKey('Date_Incorporated__c'))
                acc.Date_Incorporated__c = Date.valueOf((String) accountData.get('Date_Incorporated__c'));
            if (accountData.containsKey('Active__c'))
                acc.Active__c = (String) accountData.get('Active__c');
            if (accountData.containsKey('State_of_Incorporation__c'))
                acc.State_of_Incorporation__c = (String) accountData.get('State_of_Incorporation__c');
            if (accountData.containsKey('State_Organization_ID__c'))
                acc.State_Organization_ID__c = (String) accountData.get('State_Organization_ID__c');
            if (accountData.containsKey('Status__c'))
                acc.Status__c = (String) accountData.get('Status__c');
            if (accountData.containsKey('Payment_Method__c'))
                acc.Payment_Method__c = (String) accountData.get('Payment_Method__c');
            if (accountData.containsKey('Source__c'))
                acc.Source__c = (String) accountData.get('Source__c');
            if (accountData.containsKey('Account_Division__c'))
                acc.Account_Division__c = (String) accountData.get('Account_Division__c');
            if (accountData.containsKey('Orig_System_ID__c'))
                acc.Orig_System_ID__c = (String) accountData.get('Orig_System_ID__c');
            if (accountData.containsKey('Oracle_ID__c'))
                acc.Oracle_ID__c = (String) accountData.get('Oracle_ID__c');
            if (accountData.containsKey('CIF__c'))
                acc.CIF__c = (String) accountData.get('CIF__c');
            if (accountData.containsKey('External_Account_Number__c'))
                acc.External_Account_Number__c = (String) accountData.get('External_Account_Number__c');
            if (accountData.containsKey('External_Account_Name__c'))
                acc.External_Account_Name__c = (String) accountData.get('External_Account_Name__c');
            if (accountData.containsKey('CIS_Customer_ID__c'))
                acc.CIS_Customer_ID__c = (String) accountData.get('CIS_Customer_ID__c');
            if (accountData.containsKey('CIS_Sync_Status__c'))
                acc.CIS_Sync_Status__c = (String) accountData.get('CIS_Sync_Status__c');
            if (accountData.containsKey('CIS_Match_Options__c'))
                acc.CIS_Match_Options__c = (String) accountData.get('CIS_Match_Options__c');
            if (accountData.containsKey('Salutation__c'))
                acc.Salutation__c = (String) accountData.get('Salutation__c');
            if (accountData.containsKey('FirstName'))
                acc.FirstName = (String) accountData.get('FirstName');
            if (accountData.containsKey('LastName'))
                acc.LastName = (String) accountData.get('LastName');
            if (accountData.containsKey('First_Name__c'))
                acc.First_Name__c = (String) accountData.get('First_Name__c');
            if (accountData.containsKey('Middle_Name__c'))
                acc.Middle_Name__c = (String) accountData.get('Middle_Name__c');
            if (accountData.containsKey('Last_Name__c'))
                acc.Last_Name__c = (String) accountData.get('Last_Name__c');
            if (accountData.containsKey('Suffix__c'))
                acc.Suffix__c = (String) accountData.get('Suffix__c');
            if (accountData.containsKey('Title__c'))
                acc.Title__c = (String) accountData.get('Title__c');
            if (accountData.containsKey('Birthdate__c'))
                acc.Birthdate__c = Date.valueOf((String) accountData.get('Birthdate__c'));
            if (accountData.containsKey('Tax_ID__c'))
                acc.Tax_ID__c = (String) accountData.get('Tax_ID__c');
            if (accountData.containsKey('Ownership__c'))
                acc.Ownership__c = (String) accountData.get('Ownership__c');
            if (accountData.containsKey('Citizenship_Status__c'))
                acc.Citizenship_Status__c = (String) accountData.get('Citizenship_Status__c');
            if (accountData.containsKey('Email__c'))
                acc.Email__c = (String) accountData.get('Email__c');
            if (accountData.containsKey('Non_Profit__c'))
                acc.Non_Profit__c = (Boolean) accountData.get('Non_Profit__c');
            if (accountData.containsKey('Disregarded_Entity__c'))
                acc.Disregarded_Entity__c = (Boolean) accountData.get('Disregarded_Entity__c');
            if (accountData.containsKey('Publicly_Traded__c'))
                acc.Publicly_Traded__c = (Boolean) accountData.get('Publicly_Traded__c');
            if (accountData.containsKey('Stock_Exchange__c'))
                acc.Stock_Exchange__c = (String) accountData.get('Stock_Exchange__c');
            if (accountData.containsKey('Ticker_Symbol__c'))
                acc.Ticker_Symbol__c = (String) accountData.get('Ticker_Symbol__c');
            if (accountData.containsKey('DUNS_Number__c'))
                acc.DUNS_Number__c = (String) accountData.get('DUNS_Number__c');
            if (accountData.containsKey('Website__c'))
                acc.Website__c = (String) accountData.get('Website__c');
            if (accountData.containsKey('BOCP_Exemption__c'))
                acc.BOCP_Exemption__c = (String) accountData.get('BOCP_Exemption__c');
            if (accountData.containsKey('SIC_Code__c'))
                acc.SIC_Code__c = (String) accountData.get('SIC_Code__c');
            if (accountData.containsKey('SIC_Description__c'))
                acc.SIC_Description__c = (String) accountData.get('SIC_Description__c');
            if (accountData.containsKey('NAICS_Code__c'))
                acc.NAICS_Code__c = (String) accountData.get('NAICS_Code__c');
            if (accountData.containsKey('NAICS_Description__c'))
                acc.NAICS_Description__c = (String) accountData.get('NAICS_Description__c');
            if (accountData.containsKey('Industry_Description__c'))
                acc.Industry_Description__c = (String) accountData.get('Industry_Description__c');

            // Always set CIS Sync Status to Pending on creation
            acc.CIS_Sync_Status__c = 'Pending';

            insert acc;
            return acc.Id;

        } catch (DmlException e) {
            throw new AuraHandledException('Failed to create account: ' + e.getDmlMessage(0));
        } catch (Exception e) {
            throw new AuraHandledException('Unexpected error: ' + e.getMessage());
        }
    }

    // ── Find Account by Name (for Resolve CPID matching) ─────────────────────
    // Added for resolveCpidAction LWC

    @AuraEnabled
    public static AccountLookupResult findAccountByName(String name) {
        try {
            if (String.isBlank(name)) return null;
            List<Account> accounts = [
                SELECT Id, Name
                FROM Account
                WHERE Name = :name.trim()
                LIMIT 1
            ];
            if (accounts.isEmpty()) return null;
            AccountLookupResult res = new AccountLookupResult();
            res.id   = accounts[0].Id;
            res.name = accounts[0].Name;
            return res;
        } catch (Exception e) {
            throw new AuraHandledException('Account lookup failed: ' + e.getMessage());
        }
    }

    public class AccountLookupResult {
        @AuraEnabled public String id   { get; set; }
        @AuraEnabled public String name { get; set; }
    }

    // ── Create Account from CIS result ────────────────────────────────────────
    // Added for resolveCpidAction LWC

    @AuraEnabled
    public static String createAccountFromCis(
        String name, String ssn, String tin, String cisId
    ) {
        try {
            Account acc            = new Account();
            acc.Name               = name;
            acc.CIS_Customer_ID__c     = cisId;
            acc.CIS_Sync_Status__c = 'Synced';
            if (String.isNotBlank(ssn))
                acc.Social_Security_Number__c = ssn;
            if (String.isNotBlank(tin))
                acc.Tax_ID__c = tin;
            insert acc;
            return acc.Id;
        } catch (DmlException e) {
            throw new AuraHandledException('Failed to create account: ' + e.getDmlMessage(0));
        } catch (Exception e) {
            throw new AuraHandledException('Unexpected error: ' + e.getMessage());
        }
    }
}