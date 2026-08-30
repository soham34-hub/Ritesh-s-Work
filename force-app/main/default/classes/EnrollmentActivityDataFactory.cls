@isTest
public class EnrollmentActivityDataFactory {
    public static Enrollment_Activity__c newRecord = new Enrollment_Activity__c();
    
    
    public static void createActivityRecord(){
        
        newRecord.Case_Number__c = null;
        newRecord.Req_Account__c = '1234';
        newRecord.Req_Account_Cycle_Type__c = 'test cycle';
        newRecord.Req_Account_Status__c = 'TESTING';
        newRecord.Req_Comments__c = 'THIS IS A TEST';
        newRecord.Req_Effective_Date__c = DATE.TODAY();
        newRecord.Req_First_Financial_Activity_Date__c = DATE.TODAY();
        newRecord.Req_Initiator__c = null; //update later not sure what this is?
        newRecord.Req_Name__c = 'rec test 001';
        newRecord.Req_Offer_Code__c = 'Test code 001';
        newRecord.Req_Opening_Date__c = DATE.TODAY();
        newRecord.Req_Primary_CIF__c = 'test CIF 001';
        newRecord.Req_Product_Code__c = 'test prod 001';
        newRecord.Req_Promo_Code__c = 'promo 001';
        newRecord.Req_Reason_Code__c = ' THIS IS A TEST';
        newRecord.Req_Reward_Code__c = 'Test Reward 001';
        newRecord.Req_Skip_Eligibility_Rules__c = 'No';
        newRecord.Req_Source__c = 'The Testing Abyass';
        newRecord.Req_Value__c = 'One Billion Dollars';
        newRecord.Resp_Account_Id__c = 'test Account 001';
        newRecord.Resp_Action_Date__c = DATE.Today();
        newRecord.Resp_Action__c = 'Failed to get Reward';
        newRecord.Resp_Correlation_Id__c = '3fa85f64-5717-4562-b3fc-2c963f66afa6';
        newRecord.Resp_Customer_Id__c = '0001Test0001';
        newRecord.Resp_Details__c = 'test details';
        newRecord.Resp_End_Date__c = DATE.Today().adddays(35);
        newRecord.Resp_Error__c = 'NO ERRORS IN TEST !';
        newRecord.Resp_Message__c =' THIS IS A TEST';
        newRecord.Resp_Offer_Code__c = ' offers are great';
        newRecord.Resp_Offer_Instance_Id__c = 'test01test02';
        newRecord.Resp_Primary_CIF__c = 'CIF-TESTER 001';
        newRecord.Resp_Promo_Code__c = 'TEST PROMO 001';
        newRecord.Resp_Offer_Instance_Id__c = 'TEST INST 101';
        newRecord.Resp_Primary_CIF__c = ' CIF TESTER 002';
        newRecord.Resp_Promo_End_Date__c = DATE.Today().adddays(35);
        newRecord.Resp_Promo_Offer_Code_1__c = '001';
        newRecord.Resp_Retryable__c = 'no';
        newRecord.Resp_Reward_Code__c = 'test0345r3242Test';
        newRecord.Resp_Reward_Instance_Id__c = 'test inst 001';
        newRecord.Resp_Reward_Status__c = 'failed';
        newRecord.Resp_Reward_Status_Date__c = DATE.Today().addDays(-12);
        newRecord.Resp_Status__c = 'TEST STATUS';
        newRecord.Resp_Status_Date__c = DATE.TODAY();
        newRecord.Resp_Time_Stamp__c = DATE.TODAY();
        newRecord.Resp_Valid__c = 'TRUE';
        newRecord.Zafin_Request__c = 'Not Sent';
        newRecord.Zafin_Request_DateTime__c = DATE.TODAY();
        
        insert newRecord;
    }

}