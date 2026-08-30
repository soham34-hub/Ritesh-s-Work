trigger Enrollment_Activity_Trigger on Enrollment_Activity__c (before insert, before update
) {
    if (Trigger.isBefore) {
        Enrollment_Activity_Handler.copyCaseFields(Trigger.new);
    }
}