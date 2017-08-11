/************************************************************************************
Class Name   : MyNewsletters
Author       : Vishant Shah
Created Date : 02/12/2016
Function     : Controller extension for MyNewsletter apex page.
Change Log:
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
* Developer             Date         Description
* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
*************************************************************************************/
public class MyNewsletters {
    
    @TestVisible private Map<String, Object> jsonMap;
    @TestVisible private IdentityWrapper myIdentity;
    @TestVisible private String noPostcode = 'NOPOSTCODE';
    
    public Map<String, List<MyNewsletterWrapper.Newsletters>> categoryNewsletterMap { get; set; } 
    
    public Account acc                  { get; set; }
    public String newsletterIdAction    { get; set; }
    public String newsletterId          { get; set; }
    public String startTableRow         { get { return '<tr width="100%">'; } }
    public String endTableRow           { get { return '</tr>'; } }
    public boolean hasEmail				{ get; set; }

    /************************************************************************************
    Method Name  : MyNewsletters (Constructor)
    Author       : Vishant Shah
    Created Date : 02/12/2016
    Function     : gets newsletter subscribed to by an account by passing get id and access token and then requesting list of newsletters
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    public MyNewsletters(ApexPages.StandardController controller){
        acc = (Account)controller.getRecord();
		
        hasEmail = true;
        
        if(acc.Guid__c != null && acc.Email__c != null){

            try{
                generateIdentityMap(acc.Subscriber_Number__c, acc.PersonMailingPostalCode == null ? noPostcode : acc.PersonMailingPostalCode); 
                CoreAPICalloutUtility calloutUtility = new CoreAPICalloutUtility();
                myIdentity = calloutUtility.getIdentity(jsonMap, MyNewslettersUtility.headerMap);
                
                if (!Test.isRunningTest()) getMyNewsletters();
                
            } catch (Exception e){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, e.getMessage() )) ;
            }
			
        } else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, Label.Missing_Email_On_Account));
            hasEmail = false;
        }
    }

    /************************************************************************************
    Method Name  : getMyNewsLetters
    Author       : Vishant Shah
    Created Date : 02/12/2016
    Function     : gets list of newsletters
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/    
    public void getMyNewsLetters(){
        try{
            categoryNewsletterMap = MyNewslettersUtility.getMyNewsletters(myIdentity);
        } catch (Exception ex) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, ex.getMessage()));
        }
    }
    
    /************************************************************************************
    Method Name  : newsletterAction
    Author       : Vishant Shah
    Created Date : 02/12/2016
    Function     : add or remove newsletter by passing the id and then refresh list of newsletters
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/ 
    public void newsletterAction(){
        try{
            if (newsletterIdAction == 'Add'){
                MyNewslettersUtility.processMyNewsletters('POST', newsletterId, myIdentity);
            }
            
            if (newsletterIdAction == 'Remove'){
                MyNewslettersUtility.processMyNewsletters('DELETE', newsletterId, myIdentity);
            }
            
            if (!Test.isRunningTest()){
                getmyNewsLetters();
            }
        } catch (Exception ex) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, ex.getMessage()));
        }
    }

    /************************************************************************************
    Method Name  : generateIdentityMap
    Author       : Vishant Shah
    Created Date : 02/12/2016
    Function     : Map used to generate Id and Access token from tsnumber and postcode. passed as JSON in body
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/ 
    private void generateIdentityMap(String tsNumber, String postCode){
        jsonMap = new Map<String, Object>();
        jsonMap.put('grant_type', 'password');
        jsonMap.put('credential_type', 'TS_NUMBER');
        jsonMap.put('identifier', tsNumber);
        jsonMap.put('auth_key', postCode);
        jsonMap.put('client_id', 'tcuk');
        jsonMap.put('remember_me', true);
    }

}