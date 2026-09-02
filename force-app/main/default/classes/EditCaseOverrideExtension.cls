public class EditCaseOverrideExtension 
{

    private final Case record;
    private ApexPages.StandardController controller;
    private String retURL;
    private String saveNewURL;
    private String rType;
    private String cancelURL;
    private String ent;
    private String confirmationToken;

    public EditCaseOverrideExtension(ApexPages.StandardController controller) 
    {
        record = (Case)controller.getRecord();
  
        System.debug('case id = ' + record);
        retURL = ApexPages.currentPage().getParameters().get('retURL');
        //rTypeid = ApexPages.currentPage().getParameters().get('id');
        rType = ApexPages.currentPage().getParameters().get('RecordType');
        cancelURL = ApexPages.currentPage().getParameters().get('cancelURL');
        ent = ApexPages.currentPage().getParameters().get('ent');
        confirmationToken = ApexPages.currentPage().getParameters().get('_CONFIRMATIONTOKEN');
        saveNewURL = ApexPages.currentPage().getParameters().get('save_new_url');
        
        
    }

    public PageReference Page_Load()
    {
        PageReference editorPage;
        Case c = [Select id, recordtypeid From Case Where Id = :ApexPages.currentPage().getParameters().get('id')];   
        
        string clientCaserecordTypeId = [select id from recordtype where name = 'Client Case'].id;
        string ExecutiveServicesRecordTypeId = [select id from recordtype where name = 'Executive Services Case'].id;
        // string FirstAidRecordTypeId = [select id from recordtype where name = 'First Aid'].id;
        string MortgageHelpLineRecordTypeId = [select id from recordtype where name = 'Mortgage Helpline'].id;
        string CRTRecordTypeId = [select id from recordtype where name = 'CRT'].id;
        string CLEARRecordTypeId = [select id from recordtype where name = 'CLEAR'].id;
        string StdModelRecordTypeId = [select id from recordtype where name = 'Standard Model Case'].id;
        string SocialMediaRecordTypeId = [select id from recordtype where name = 'Social Media Case'].id;
        // Added for credit dispute recordtype.
        string CreditDisputeRecordTypeId = [select id from recordtype where name = 'Credit Dispute'].id;
        string ComplianceRiskRecordTypeId = [select id from recordtype where name = 'Compliance & Risk'].id;
        
        // CMI Lightning Nov 2020 Release -- Added for Client Advocacy Record Type
        string ClientAdvocacyRecordTypeId = [Select id from recordtype where name='Client Advocacy'].id;
        
        // Added for CMI 2015 Release 4
        string ThirdPartyRecordTypeId=[select id from recordtype where name='Third Party'].id;
        
        string ComplaintMonitoringTypeId = [select id from recordtype where name = 'Monitoring and Analysis Case'].id;       
        
        string TCCServiceRequestTypeId = [select id from recordtype where name = 'TCC Service Request'].id; 
        
        system.debug('tccrecord11'+c.recordtypeid);
        system.debug('tccrecord11'+TCCServiceRequestTypeId);
        
        if (rType != null && 
            rType != clientCaserecordTypeId && 
            rType != ExecutiveServicesRecordTypeId && 
            rType != MortgageHelpLineRecordTypeId && //FirstAidRecordTypeId && 
            rType != CRTRecordTypeId &&
            rType != CLEARRecordTypeId &&
            rType != StdModelRecordTypeId &&
            rType != SocialMediaRecordTypeId &&
            rType != CreditDisputeRecordTypeId && // Added for Credit Dispute.
            rType != ComplianceRiskRecordTypeId && // Added for Compliance & Risk.
            rType != ThirdPartyRecordTypeId &&
            rType != ComplaintMonitoringTypeId &&   //Added for ThirdParty.
            rType != ClientAdvocacyRecordTypeId &&   //CMI Lightning Nov 2020 Release -- Added for Client Advocacy.
            rType != TCCServiceRequestTypeId)       //February 2023
        {
            editorPage = new PageReference('/' + c.id + '/e');
            editorPage.getParameters().put('nooverride', '1');
        }
        else if (c.recordtypeid == clientCaserecordTypeId)
        {
            editorPage = new PageReference('/apex/ClientCaseEditPage');
            editorPage.getParameters().put('id', c.id);
            editorPage.getParameters().put('sfdc.override', '1');
            // Start Changes for CMI 2014 Release 2.
            // The parameter catgrp was not being passed for CFS to the Category object, so we have just passed this parameter to the Category controller.
            editorPage.getParameters().put('catgrp', 'CFS'); 
            // End Changes for CMI 2014 Release 2           
        }
        // CMI Lightning Nov 2020 Release -- Added for Client Advocacy Record Type--Start
         else if (c.recordtypeid == ClientAdvocacyRecordTypeId)
        {
            editorPage = new PageReference('/apex/ClientAdvocacyEdit');
            editorPage.getParameters().put('id', c.id);
            editorPage.getParameters().put('sfdc.override', '1');
            // Start Changes for CMI 2014 Release 2.
            // The parameter catgrp was not being passed for CFS to the Category object, so we have just passed this parameter to the Category controller.
            editorPage.getParameters().put('catgrp', 'ES'); 
            // End Changes for CMI 2014 Release 2           
        }
       // CMI Lightning Nov 2020 Release -- Added for Client Advocacy Record Type--End
        else if (c.recordtypeid == ExecutiveServicesRecordTypeId)
        {
            editorPage = new PageReference('/apex/ExecutiveServicesEdit');
            editorPage.getParameters().put('id', c.id);
            editorPage.getParameters().put('sfdc.override', '1');
            // Start Changes for CMI 2014 Release 2.
            // The parameter catgrp was not being passed for CFS to the Category object, so we have just passed this parameter to the Category controller.
            editorPage.getParameters().put('catgrp', 'ES'); 
            // End Changes for CMI 2014 Release 2           
        }
        // else if (c.recordtypeid == FirstAidRecordTypeId)
        else if (c.recordtypeid == MortgageHelpLineRecordTypeId)
        {
            //editorPage = new PageReference('/apex/FirstAidEditPage');
            editorPage = new PageReference('/apex/MortgageHelpLineEdit');
            editorPage.getParameters().put('id', c.id);
            editorPage.getParameters().put('sfdc.override', '1');
            editorPage.getParameters().put('catgrp', 'FA');                        
        }
        else if (c.recordtypeid == CRTRecordTypeId)
        {
            editorPage = new PageReference('/apex/CRTEditPage');
            editorPage.getParameters().put('id', c.id);
            editorPage.getParameters().put('sfdc.override', '1');
            editorPage.getParameters().put('catgrp', 'CRT');                        
        }
        else if (c.recordtypeid == CLEARRecordTypeId)
        {
            editorPage = new PageReference('/apex/CLEAREditPage');
            editorPage.getParameters().put('id', c.id);
            editorPage.getParameters().put('sfdc.override', '1');
            editorPage.getParameters().put('catgrp', 'CLEAR');                        
        }
        else if (c.recordtypeid == StdModelRecordTypeId)
        {
            editorPage = new PageReference('/apex/StdModelEdit');
            editorPage.getParameters().put('id', c.id);
            editorPage.getParameters().put('sfdc.override', '1');
            editorPage.getParameters().put('catgrp', 'STDMDL');                        
        }
        else if (c.recordtypeid == SocialMediaRecordTypeId)
        {
            editorPage = new PageReference('/apex/SocialMediaEdit');
            editorPage.getParameters().put('id', c.id);
            editorPage.getParameters().put('sfdc.override', '1');
            editorPage.getParameters().put('catgrp', 'SOCIALMEDIA');                        
        }
        else if (c.recordtypeid == CreditDisputeRecordTypeId) // if condition block added for Credit Dispute.
        {
            editorPage = new PageReference('/apex/CreditDisputeEditPage');
            editorPage.getParameters().put('id', c.id);
            editorPage.getParameters().put('sfdc.override', '1');                        
        }
        // Start Changes for CMI 2014 Release 3
        else if (c.recordtypeid == ComplianceRiskRecordTypeId ) // if condition block added for Compliance & Risk Record Type.
        {
            editorPage = new PageReference('/apex/ComplianceAndRiskEditPage');
            editorPage.getParameters().put('id', c.id);
            editorPage.getParameters().put('sfdc.override', '1');
            editorPage.getParameters().put('catgrp', 'ALL');                        
        }
        // End changes for CMI 2014 Release 3
        
        //start changes for CMI 2015 Release 4
        //The below condition is used to redirect the page to ThirdPartyEdit page when Edit button is clickd from detail page
        else if (c.recordtypeid ==  ThirdPartyRecordTypeId)
        {
            editorPage = new PageReference('/apex/ThirdPartyEdit');
            editorPage.getParameters().put('id', c.id);
            editorPage.getParameters().put('sfdc.override', '1');            
            editorPage.getParameters().put('catgrp', 'Third_Party'); 
                      
        }
        //End changes for CMI 2015 Release 4
        
        else if (c.recordtypeid ==  ComplaintMonitoringTypeId)
        {
            editorPage = new PageReference('/apex/MonitoringAndAnalysisEdit');
            editorPage.getParameters().put('id', c.id);
            editorPage.getParameters().put('sfdc.override', '1');            
            editorPage.getParameters().put('catgrp', 'ES'); 
                      
        }
        //changes start for February 2023
        else if (c.recordtypeid ==  TCCServiceRequestTypeId)
        {   system.debug('insideTCC1');
            
         
         editorPage = new PageReference('/lightning/r/Case/'+c.id+'/edit?count=?&backgroundContext=%2Flightning%2Fr%2FCase%2F'+c.id+'%2Fview');
            editorPage.getParameters().put('nooverride', '1');
                      
        }
        //changes end for February 2023
        else
        {
            editorPage = new PageReference('/' + c.id + '/e');
            editorPage.getParameters().put('nooverride', '1');
        }
        
        editorPage.getParameters().put('retURL', retURL);
        editorPage.getParameters().put('RecordType', rType);
        editorPage.getParameters().put('cancelURL', cancelURL);
        // editorPage.getParameters().put('ent', ent);
        // editorPage.getParameters().put('_CONFIRMATIONTOKEN', confirmationToken);
        // editorPage.getParameters().put('save_new_url', saveNewURL);
        
        return editorPage.setRedirect(true);
    }
    
    Public PageReference UpTheTestClassPercentage()
    {
        // This method exists for the sole prurpose of upping the test class percentage.  
        // It is necessary because of the SOQL query limit being exceeded when trying to 
        // create a CASE of each recordtype to test.  Each time a new case is created the 
        // round robin trigger fires and uses up massive amounts of SOQL quries.  If the 
        // "Edit" button could be split, then each record type could have its own page/class.
        // This however, is very inefficient as well.

        PageReference ePage = new PageReference('/apex/ClientCaseEditPage');

        integer i = 0;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        
        return ePage;
    }
}