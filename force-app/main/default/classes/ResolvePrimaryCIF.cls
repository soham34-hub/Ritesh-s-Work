public class ResolvePrimaryCIF {
    //structure 1
	public CIFAccountSearchDefine.AccountSearchResponse_element accountResults = new CIFAccountSearchDefine.AccountSearchResponse_element();
    public String primaryCifResult = 'No Primary CIF located';
    public Boolean primaryBreaker = false;
    public List<user> runningUser = new LIST<user>();
    public Map<String,WMSConfig__c> keyValuesMap = WMSConfig__c.getAll();
    public Map<String,String> mapCIFConfigMetadata1 = Client360Utility.getCIFConfigMetadataMapFields();
    public String CIFAccountSearchService = mapCIFConfigMetadata1.get('CIFAccountSearchService');
    String accountNumber;
   
    public String findPromoCif(String accNumber, case relatedCase){
        findRelatedAccountElements(accNumber);
        return findPrimaryCiff(relatedCase);
    }
   
   public void findRelatedAccountElements(String accNumber){   
        accountNumber = accNumber;
        CIFAccountSearchInvoke.AccountSearchEndpoint1 ast2 = new  CIFAccountSearchInvoke.AccountSearchEndpoint1();
        ast2.endpoint_x='callout:CIFAccountSearch/'+CIFAccountSearchService;
        accountResults = ast2.AccountSearch('SP',accountNumber,'','','','','','');
        system.debug('final endpoint ' +  ast2.endpoint_x);
   }
    
    public String findPrimaryCiff(case relatedCase){   
    	CIFClientAccountListStub.SOAPEventSource listAcctstub =  CIFUtility.getCIFFinancialAccountListService(); //new CIFClientAccountListStub.SOAPEventSource();
        CIFClientAccountListSchema.CIFAccountListReply_element Listresponse = new CIFClientAccountListSchema.CIFAccountListReply_element();
        runningUser = [select truist__Truist_User_ID__c from User where id = :UserInfo.getUserId()];
        System.debug('Account Search Results: Nuber of Accounts returned ' + accountResults);
        for(CIFAccountSearchDefine.AccountDetails_element  element : accountResults.AccountDetails){
            if(primaryBreaker){
                break;
            }
            System.debug('	Process Account Related CIF :' + element.CIFStaticKey);
            Listresponse = listAcctstub.CIFAccountListOperation('SP',runningUser[0].truist__Truist_User_ID__c,'',element.CIFStaticKey,'','','','','');
            System.Debug('		Found ' + Listresponse.AccountDetail.size() + ' Related Accounts for CIF#' + element.CIFStaticKey);
            for( CIFClientAccountListSchema.AccountDetail_element accDetailRec : Listresponse.AccountDetail){
                if(accDetailRec.AccountNumber == accountNumber && accDetailRec.Relationship == 'PRI' ||
                   accDetailRec.AccountNumber == accountNumber && accDetailRec.RelationshipDesc == 'PRIMARY' ){
                       primaryCifResult = dropLeadingZeros(element.CIFStaticKey);
                       system.debug('primaryCifResult' + primaryCifResult);
                       system.debug('cif call returns cif #' + element.CIFStaticKey);
                     //  relatedCase.Promotion_CIF__c = dropLeadingZeros(element.CIFStaticKey); 
                         relatedCase.Promotion_CIF__c = primaryCifResult; //opLeadingZeros(element.CIFStaticKey); 

                       system.debug('promo cif on case before save' + relatedCase.Promotion_CIF__c);

                       relatedCase.Promotion_Account_Status__c = accDetailRec.AccountStatusDesc;
                       relatedCase.Promotion_Account_Product_Code__c = accDetailRec.ProductCD;
                       relatedCase.Promotion_Account_Opening_Date__c = Date.valueOf(fixDate(accDetailRec.OpenDate));
                       primaryBreaker = true;
                       system.debug('Success Located Primary CIF for account# ' +accDetailRec.AccountNumber + '  Cif# ' + primaryCifResult);
                       system.Debug('Search terminated due to Primary CIF located');
                       break;
                   }
                system.debug('No Primary match for Acct: ' + accDetailRec.AccountNumber + ' Cif# ' + element.CIFStaticKey);
            }
        }
        
        	update relatedCase;
            system.debug('promo cif on case after save' + relatedCase.Promotion_CIF__c);
            return primaryCifResult;
    }
    
    private string fixDate(String stringDate){
        list<string> dateComp = new List<String>();
        if(! String.isBlank(stringDate)){
        datecomp = stringDate.split('/');
        }
       return( dateComp[2] + '-' + dateComp[0] + '-' +dateComp[1]);                     
    }


    public static String dropLeadingZeros (String inStr) {
    while ( !String.isBlank(inStr) && inStr.startsWith('0') ) inStr = inStr.removeStart('0');
    if ( String.isBlank(inStr) ) return '0';
    if ( inStr.startsWith('.') ) inStr = '0' + inStr;
    return inStr;
}
}