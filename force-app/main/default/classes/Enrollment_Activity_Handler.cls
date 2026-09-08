public class Enrollment_Activity_Handler {

    public static void copyCaseFields(List<Enrollment_Activity__c> newRecs) {
        List<Enrollment_Activity__c> updates = new List<Enrollment_Activity__c>();

        // Collect Case IDs from Case_Number__c lookup
        Set<Id> caseIds = new Set<Id>();
        for (Enrollment_Activity__c ea : newRecs)
            if (ea.Case_Number__c != null) caseIds.add(ea.Case_Number__c);
		    if (caseIds.isEmpty()) return;
	    Map<Id, Case> caseMap = new Map<Id, Case>(
            [SELECT Id,CaseNumber,Product_Code__c,Cat_Level_5__c, Promotion_Account_Product_Code__c, Promotion_CIF__c, Promotion_Account_Status__c,
             Promotion_Account_Opening_Date__c,Account_Number__c FROM Case WHERE Id IN :caseIds]); 
		User runningUser = [SELECT Truist__Truist_User_ID__c FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        for (Enrollment_Activity__c ea : newRecs) {
            Case c = caseMap.get(ea.Case_Number__c);
      	      if (c == null) continue;
    	ea.Req_Opening_Date__c       = c.Promotion_Account_Opening_Date__c;
		ea.Req_Account_Cycle_Type__c = 'CALENDAR';
		ea.Req_Account_Status__c     = c.Promotion_Account_Status__c;
        ea.Req_Primary_CIF__c = dropLeadingZeros(c.Promotion_CIF__c);
        ea.Req_Source__c =    c.CaseNumber; // may need to be updated to ID?> 
        ea.Req_Account__c =  dropLeadingZeros(c.Account_Number__c);    
		if (ea.Zafin_Request__c != 'Sent') {
    		ea.Req_Initiator_2__c = runningUser.Truist__Truist_User_ID__c;
		}
		}
      }
    
    public static String dropLeadingZeros (String inStr) {
    while ( !String.isBlank(inStr) && inStr.startsWith('0') ) inStr = inStr.removeStart('0');
    if ( String.isBlank(inStr) ) return '0';
    if ( inStr.startsWith('.') ) inStr = '0' + inStr;
    return inStr;
}
   }