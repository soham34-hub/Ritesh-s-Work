public class cloneCaseforTesting {
    
    
Public static Case cloneCase(Id caseId) {

        // Query the fields you want to clone
        Case originalCase = [
            SELECT Subject,
                   Description,
                   Status,
                   Priority,
                   Origin,
                   RecordTypeId,
                   ContactId,
                   AccountId,
                   OwnerId
            FROM Case
            WHERE Id = :caseId
            LIMIT 1
        ];

        // clone(preserveId, isDeepClone, preserveReadOnlyTimestamps, preserveAutonumber)
        Case clonedCase = originalCase.clone(
            false,   // do not preserve Id
            false,   // shallow clone (no children)
            false,   // reset created/modified date fields
            false    // generate new auto numbers
        );

        insert clonedCase;
        system.debug('show new case Id : ' + clonedCase.Id);
        return clonedCase;
    }


}