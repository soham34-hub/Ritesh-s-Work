/*
@Author : Poorva & Kajal
@name : CIFUtility 
@Description : This Class serves as a Utility class for making CIF service callout.
@Version <1.0>
@reference calls :CIFClientProfileStub,CIFClientAccountListStub,CIFClientSearchServiceStub
@Covered by - CIFClientSearchServiceStubTest , CIFClientAccountListStubTest
CIF Interim Search M11 2020
*/
public with sharing class CIFUtility {
   Public Static Map<String,String> mapCIFConfigMetadata = Client360Utility.getCIFConfigMetadataMapFields();
    Public Static String CIFClientSearchService = mapCIFConfigMetadata.get('CIFClientSearchService');
    Public Static String CIFClientProfileService = mapCIFConfigMetadata.get('CIFClientProfileService');
    Public Static String CIFAccountListService = mapCIFConfigMetadata.get('CIFAccountListService');
    Public Static String CIFTimeOut =  mapCIFConfigMetadata.get('CIFTimeOut');
    
    /*
* Method name   : getCIFClientSearchService
* Description   : sets endpoint for Search Service
* Return Type   : CIFClientSearchServiceStub.SOAPEventSource 
*/
    public static CIFClientSearchServiceStub.SOAPEventSource getCIFClientSearchService(){
        CIFClientSearchServiceStub.SOAPEventSource CIFClientSearchServices = new CIFClientSearchServiceStub.SOAPEventSource();
        CIFClientSearchServices.endpoint_x ='callout:CIF_Integration_Callout_With_Authentication/' + CIFClientSearchService;
        CIFClientSearchServices.timeout_x = integer.valueOf(CIFTimeOut);
        return CIFClientSearchServices;
    } 
/*
* Method name   : getCIFFinancialAccountListService
* Description   : sets endpoint for FinancialAccountList Service
* Return Type   : CIFClientAccountListStub.SOAPEventSource 
*/     
    public static CIFClientAccountListStub.SOAPEventSource getCIFFinancialAccountListService(){
        CIFClientAccountListStub.SOAPEventSource FinancialAccountService= new CIFClientAccountListStub.SOAPEventSource();
        FinancialAccountService.endpoint_x ='callout:CIF_Integration_Callout_With_Authentication/' + CIFAccountListService;
        FinancialAccountService.timeout_x = integer.valueOf(CIFTimeOut);
        return FinancialAccountService;
    }
	
    //changes for June 2024
/*
* Method name   : getEmailForAccountService
* Description   : sets endpoint for CIFServicesEmail Service
* Return Type   :  
*/ 
   	public static CifservicesEmailupStub.ClientEmailContactsEndpoint1 getEmailForAccountService(){
        CifservicesEmailupStub.ClientEmailContactsEndpoint1 CIFEmailService = new CifservicesEmailupStub.ClientEmailContactsEndpoint1();
        CIFEmailService.endpoint_x ='callout:CIFServicesEmail';
        CIFEmailService.timeout_x = integer.valueOf(CIFTimeOut);
        return CIFEmailService;
    }

/*
* Method name   : getEmailForAccountService
* Description   : sets endpoint for CIFServicesAltAddress Service
* Return Type   : CifservicesAltAddressStub.SOAPEventSource 
*/ 
    public static CifservicesAltAddressStub.SOAPEventSource getAltAddrForAccountService(){
        CifservicesAltAddressStub.SOAPEventSource CIFAltAddressService = new CifservicesAltAddressStub.SOAPEventSource();
        CIFAltAddressService.endpoint_x ='callout:CIFServicesAltAddress';
        CIFAltAddressService.timeout_x = integer.valueOf(CIFTimeOut);
        return CIFAltAddressService;
    }
    //Changes For June 2024
}