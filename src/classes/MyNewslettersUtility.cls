/************************************************************************************
Class Name   : MyNewslettersUtility
Author       : Vishant Shah
Created Date : 02/12/2016
Function     : Utility Class to process actions from MyNewsletters class.
Change Log:
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
* Developer             Date         Description
* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
*************************************************************************************/
public class MyNewslettersUtility {

    static String idToken       = 'id_token';
    static String accessToken   = 'access_token';
    static String myNewsletters = ' My Newsletters'; //starting space is intentional, when sorting My Newletters appears will be first

    public static Map<String, String> headerMap = new Map<String, String>{
        Constants.CORE_API_APP_ID_KEY_NAME => Constants.CORE_API_APP_ID_VALUE,
        Constants.CORE_API_APP_KEY_NAME => Constants.CORE_API_APP_VALUE,
        Constants.CORE_API_CONTENT_TYPE_KEY_VALUE => Constants.CORE_API_JSON_CONTENT_TYPE_VALUE
    };
    
    /************************************************************************************
    Method Name  : processMyNewsletters
    Author       : Vishant Shah
    Created Date : 02/12/2016
    Function     : Processes add/remove/get newsletters based on newsletterId. to add / remove newsletter id is required.
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    public static String processMyNewsletters(String method, String newsletterId, IdentityWrapper myIdentity){
        
        String responseBody = '';
        String endPoint = Application_Settings__c.getinstance(Constants.MY_NEWSLETTER_ENDPOINT).Value__c;

        try{
            HttpRequest req = new HttpRequest();
            Http http = new Http();

            if (myIdentity != null ){
                headerMap.put(idToken, myIdentity.id_token);
                headerMap.put(accessToken, myIdentity.access_token);
            }
            
            req.setMethod(method); 
            
            for (String key : headerMap.keySet()){
                req.setHeader(key, headerMap.get(key));
            }
            
            if (String.isNotEmpty(newsletterId))
                endPoint = endPoint + '/' + newsletterId;
            
            req.setEndpoint(endPoint);
            
            HttpResponse response = http.send(req);
            if (response.getStatusCode() == 200){
                responseBody = response.getBody();
            }
            else {
                responseBody = 'Status code: ' + response.getStatusCode() + ': ' + response.getStatus(); 
                throw new TelegraphApplicationException(responseBody);
            }
        } catch (Exception ex) {
            throw new TelegraphApplicationException(ex.getMessage() + ' Endpoint: ' + endPoint);
        }

        return responseBody;
    }
    
    /************************************************************************************
    Method Name  : getMyNewsletters
    Author       : Vishant Shah
    Created Date : 02/12/2016
    Function     : gets newsletters an account has subscribed to.
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    public static Map<String, List<MyNewsletterWrapper.Newsletters>> getMyNewsletters(IdentityWrapper myIdentity){
        
        String returnBody = processMyNewsletters('GET', null, myIdentity);
        
        MyNewsletterWrapper myNL = (MyNewsletterWrapper)System.JSON.deserialize(returnBody, MyNewsletterWrapper.Class);
        Map<String, List<MyNewsletterWrapper.Newsletters>> categoryNewsletterMap = new Map<String, List<MyNewsletterWrapper.Newsletters>>();
        
        categoryNewsletterMap.put(' My Newsletters', new List<MyNewsletterWrapper.Newsletters>());
        
        
        for (MyNewsletterWrapper.Newsletters nl : myNL.newsletters){
            
            if (!categoryNewsletterMap.containsKey(nl.category)){
                categoryNewsletterMap.put(nl.category, new List<MyNewsletterWrapper.Newsletters>());
            }
            
            if (nl.customerStatus == 'Active'){
                categoryNewsletterMap.get(' My Newsletters').add(nl);
            }
            
            if(!nl.retired){
                Integer counter = categoryNewsletterMap.get(nl.category).size();
                nl.counter = counter + 1;
                categoryNewsletterMap.get(nl.category).add(nl);
            }
        } 
        
        for (String s : categoryNewsletterMap.keySet()){
            categoryNewsletterMap.get(s).sort();
        }
            
        return categoryNewsletterMap;
    }
}