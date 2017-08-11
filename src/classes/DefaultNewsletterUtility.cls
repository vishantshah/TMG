public class DefaultNewsletterUtility {
	
	private static String noPostcode = 'NOPOSTCODE';
    private static Map<String, Object> jsonMap;
	private static List<String> newsletters;

	/************************************************************************************
    Method Name  : getDefaultNewsletters
    Author       : Vishant Shah
    Created Date : 28/02/2017
    Description  : get default newsletters, called from constructor. resuing existing NewslettersController to fetch newsletters. 

    Change Log   :
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    private static List<String> getDefaultNewsletters(){

        if (newsletters == null || newsletters.size() == 0){
            List<String> defaultNL             = new List<String>();
            NewslettersController nlController = new NewslettersController();
            
            if (Test.isRunningTest()){
                nlController.setTestResponse(setTestResponseForNewsletterController());
            }

            nlController.getNewsletters();
            
            for (NewslettersController.NewsletterWrapper  nl : nlController.lstNewsletters){
                if (nl.defaultAccess != null && nl.defaultAccess){
                    defaultNL.add(nl.id);
                }
            }
            newsletters = defaultNL;
        }
        return newsletters;
    }

	/************************************************************************************
    Method Name  : addDefaultNewsletter
    Author       : Vishant Shah
    Created Date : 28/02/2017
    Description  : add default news letter, called from execute method. reusing existing utility to add premium newsletters
    Change Log   :
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    public static void addDefaultNewsletter(Id accId){
    	Account acc = [SELECT Subscriber_Number__c, PersonMailingPostalCode FROM Account where id = :accId];
    	processNewsletterRequest(acc);
    }

    public static void addDefaultNewsletter(Account acc){
        processNewsletterRequest(acc);
    }

    private static void processNewsletterRequest(Account acc){
        getDefaultNewsletters();

        generateIdentityMap(acc.Subscriber_Number__c, acc.PersonMailingPostalCode == null ? noPostcode : acc.PersonMailingPostalCode); 
        CoreAPICalloutUtility calloutUtility = new CoreAPICalloutUtility();

        IdentityWrapper myIdentity;
        
        if (Test.isRunningTest()){
            Test.setMock(HttpCalloutMock.class, new MockResponseGenerator(201, 'created', IdentityUtilityTest.IDENTITY_RESPONSE_JSON, new Map<String, String>()));
        }
        
        myIdentity = calloutUtility.getIdentity(jsonMap, MyNewslettersUtility.headerMap);

        if (Test.isRunningTest()){
            Test.setMock(HttpCalloutMock.class, new MockResponseGenerator(MyNewslettersUtilityTest.generateMockNewsletters(), IdentityUtilityTest.HEADER_MAP));
        } 
        
        for (String newsletterId : newsletters){
            try{
                system.debug(newsletterId);
                String returnBody = MyNewslettersUtility.processMyNewsletters('POST', newsletterId, myIdentity);

                if (Test.isRunningTest()){
                    MyNewsletterWrapper myNL = (MyNewsletterWrapper)System.JSON.deserialize(returnBody, MyNewsletterWrapper.Class);
                    for (MyNewsletterWrapper.Newsletters nl : myNL.newsletters){
                        System.assertEquals(true, nl.defaultAccess, 'Default Newsletters should be added for account');
                    } 
                }
            } catch (Exception e){
                System.debug('Unable to add ' + newsletterId + ' Exception: ' + e.getStackTraceString() + ' Message: ' + e.getMessage());
            }
        }
    }



    /************************************************************************************
    Method Name  : generateIdentityMap
    Author       : Vishant Shah
    Created Date : 28/02/2017
    Description  : build json map to pass to authenticate against identity endpoint.
    Change Log   :
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    private static void generateIdentityMap(String tsNumber, String postCode){
        jsonMap = new Map<String, Object>();
        jsonMap.put('grant_type', 'password');
        jsonMap.put('credential_type', 'TS_NUMBER');
        jsonMap.put('identifier', tsNumber);
        jsonMap.put('auth_key', postCode);
        jsonMap.put('client_id', 'tcuk');
        jsonMap.put('remember_me', true);
    }

    private static HttpResponse setTestResponseForNewsletterController(){
        HttpResponse newslettersResponse = new HttpResponse();
        newslettersResponse.setHeader('Test', 'Header');
        newslettersResponse.setStatusCode(200);
        newslettersResponse.setBody(NewslettersControllerTest.testNewslettersBody);
        return newslettersResponse;
    }

}