@IsTest
global class ResolvePrimaryCifMock implements WebServiceMock {

    global void doInvoke(
        Object stub,
        Object request,
        Map<String, Object> response,
        String endpoint,
        String soapAction,
        String requestName,
        String responseNamespace,
        String responseName,
        String responseType
    ) {

        // -----------------------------
        // SOAP Response #1 – Account Search
        // -----------------------------
        if (responseType != null &&
            responseType.contains('AccountSearchResponse_element')) {

            CIFAccountSearchDefine.AccountSearchResponse_element searchResponse =
                new CIFAccountSearchDefine.AccountSearchResponse_element();

            CIFAccountSearchDefine.AccountDetails_element acct =
                new CIFAccountSearchDefine.AccountDetails_element();

            acct.CIFStaticKey = 'TEST-CIF-001';

            searchResponse.AccountDetails =
                new List<CIFAccountSearchDefine.AccountDetails_element>{ acct };

            response.put('response_x', searchResponse);
        }

        // -----------------------------
        // SOAP Response #2 – Account List
        // -----------------------------
        else if (responseType != null &&
                 responseType.contains('CIFAccountListReply_element')) {

            CIFClientAccountListSchema.CIFAccountListReply_element listResponse =
                new CIFClientAccountListSchema.CIFAccountListReply_element();

            CIFClientAccountListSchema.AccountDetail_element detail =
                new CIFClientAccountListSchema.AccountDetail_element();

            detail.AccountNumber = '00000000123456789';
            detail.Relationship = 'PRI';
            detail.AccountStatusDesc = 'ACTIVE';
            detail.ProductCD = 'CHK';
            detail.OpenDate = '01/15/2020'; // ✅ Required format

            listResponse.AccountDetail =
                new List<CIFClientAccountListSchema.AccountDetail_element>{ detail };

            response.put('response_x', listResponse);
        }
    }
}