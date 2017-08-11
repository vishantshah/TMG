/************************************************************************************
Class Name   : NewslettersUtils
Author       : Mantas Grigaliunas
Created Date : 28/09/2016
Function     : Class to hold Newsletter controllers common functionality
Change Log:
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
* Developer             Date         Description
* Vishant Shah          23/02/2017   Added DEFAULT_ACCESS
* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
*************************************************************************************/
public class NewslettersUtils {

	public static final String REC_ID = 'recId';
	public static final String NAME = 'name';
	public static final String CATEGORY = 'cat';
	public static final String FREQUENCY = 'fre';
	public static final String IMAGE_URL = 'imageUrl';
	public static final String SAMPLE_URL = 'sampleUrl';
	public static final String FACING_URL = 'facingUrl';
	public static final String DESCRIPTION = 'des';
	public static final String HIDE_SAMPLE = 'hideSample';
	public static final String RETIRED = 'ret';
	public static final String RET_URL = 'retUrl';
  public static final String DEFAULT_ACCESS = 'defaultAccess';

	@TestVisible private static HttpResponse testResponse;

    /************************************************************************************
    Method Name  : getResponse
    Author       : Mantas Grigaliunas
    Created Date : 28/09/2016
    Function     : Generic method to send request to server and return the response
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
	public static HttpResponse getResponse(String method, String endPointName, String requestBody){

		HttpRequest req = new HttpRequest();
        Http http = new Http();
        // Create callout request
        req.setMethod(method);
        req.setHeader(Constants.CORE_API_APP_ID_KEY_NAME, Constants.CORE_API_APP_ID_VALUE);
        req.setHeader(Constants.CORE_API_APP_KEY_NAME, Constants.CORE_API_APP_VALUE);
         req.setHeader(Constants.CORE_API_CONTENT_TYPE_KEY_VALUE, Constants.CORE_API_JSON_CONTENT_TYPE_VALUE);
        req.setEndpoint(endPointName);
        if(requestBody != null) req.setBody(requestBody);
        //get server response
        HttpResponse response = new HttpResponse();
        if(!Test.isRunningTest())response = http.send(req);
        else response = testResponse;
        return response;
	}

    /************************************************************************************
    Method Name  : generateUrl
    Author       : Mantas Grigaliunas
    Created Date : 28/09/2016
    Function     : Generic method to generate the url with parameters from Newsletters record
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer    Date         Description
    * Vishant Shah 23/02/2017   Added defaultAccess
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
	public static PageReference generateUrl(PageReference pageRef, Boolean isEditMode, String retUrl, 
												NewslettersController.NewsletterWrapper nw){
		if(isEditMode) pageRef.getParameters().put('mode', 'edit');
		pageRef.getParameters().put(RET_URL, retUrl);
		pageRef.getParameters().put(NAME, nw.name);
		pageRef.getParameters().put(REC_ID, nw.id);
		pageRef.getParameters().put(CATEGORY, nw.category);
		pageRef.getParameters().put(FREQUENCY, nw.frequency);
		pageRef.getParameters().put(IMAGE_URL, nw.imageUrl);
		pageRef.getParameters().put(SAMPLE_URL, nw.sampleUrl);
		pageRef.getParameters().put(FACING_URL, nw.publicFacingUrl);
		pageRef.getParameters().put(DESCRIPTION, nw.description);
		pageRef.getParameters().put(HIDE_SAMPLE, convertFlag(nw.hideSample));
		pageRef.getParameters().put(RETIRED, convertFlag(nw.retired));
    pageRef.getParameters().put(DEFAULT_ACCESS, nw.defaultAccess == null ? 'No' : convertFlag(nw.defaultAccess));
		return pageRef;
	}

    /************************************************************************************
    Method Name  : convertFlag
    Author       : Mantas Grigaliunas
    Created Date : 28/09/2016
    Function     : Function to convert true/false to Yes/No
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
	public static String convertFlag(Boolean flag){
		return (flag ? Label.Newsletter_Picklist_Value_Label_Yes : Label.Newsletter_Picklist_Value_Label_No);
	}

    /************************************************************************************
    Method Name  : convertFlag
    Author       : Mantas Grigaliunas
    Created Date : 28/09/2016
    Function     : Function to convert Yes/No to true/false
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
	public static Boolean convertFlag(String flag){
		return (flag.equals(Label.Newsletter_Picklist_Value_Label_Yes) ? true : false);
	}

    /************************************************************************************
    Method Name  : getNewsletterFromUrlParams
    Author       : Mantas Grigaliunas
    Created Date : 28/09/2016
    Function     : Returns newsletter record from parameters pased in page url
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer    Date         Description
    * Vishant Shah 23/02/2017   Added defaultAccess
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
	public static NewslettersController.NewsletterWrapper getNewsletterFromUrlParams(PageReference pageRef){
		Map<String, String> params = pageRef.getParameters();
        if(params.get(REC_ID) == null) return null;
        else return new NewslettersController.NewsletterWrapper(
    			params.get(REC_ID),
    			params.get(CATEGORY),
    			params.get(NAME),
    			params.get(FREQUENCY),
    			params.get(IMAGE_URL),
    			params.get(SAMPLE_URL),
    			params.get(FACING_URL),
    			params.get(DESCRIPTION),
    			convertFlag(params.get(HIDE_SAMPLE)),
    			convertFlag(params.get(RETIRED)),
          params.get(DEFAULT_ACCESS) == null ? false : convertFlag(params.get(DEFAULT_ACCESS))
      		);
	}

    /************************************************************************************
    Method Name  : getSetting
    Author       : Mantas Grigaliunas
    Created Date : 28/09/2016
    Function     : Returns value from Application Setting custom setting
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer    Date         Description
    * Vishant Shah 23/02/2017   Change method name to make more generic.
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
	public static String getSetting(String settingName){
		Application_Settings__c setting = Application_Settings__c.getInstance(settingName);
		if(setting != null){
			return setting.Value__c;
		} else {
			return null;
		}
	}



	/************************************************************************************
    Method Name  : redirectToMainPage
    Author       : Mantas Grigaliunas
    Created Date : 28/09/2016
    Function     : Returns value from Application Setting custom setting
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
	public static PageReference redirectToMainPage(){
        PageReference pageRef = Page.Newsletters;
        pageRef.setRedirect(true);
		return pageRef;
	}

	/************************************************************************************
  	Method Name  : getExpectedTestUrl
  	Author       : Mantas Grigaliunas
  	Created Date : 28/09/2016
  	Function 	 : Generates the url from given test data
  	Change Log:
  	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
  	* Developer    Date         Description
    * Vishant Shah 23/02/2017   Added defAcc
  	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
  	*************************************************************************************/
	@TestVisible
	private static String generateTestUrl(String pageName, 
											NewslettersController.NewsletterWrapper testNw, Boolean isEdit){

		return '/apex/' + pageName + '?'
				  + CATEGORY 	+ '=' + encode(testNw.category)
          + '&defaultAccess=Yes'
			+ '&' + DESCRIPTION + '=' + encode(testNw.description)
            + '&' + FACING_URL  + '=' + encode(testNw.publicFacingUrl)
			+ '&' + FREQUENCY 	+ '=' + encode(testNw.frequency)
			+ '&' + HIDE_SAMPLE + '=' + NewslettersUtils.convertFlag(testNw.hideSample)
			+ '&' + IMAGE_URL 	+ '=' + encode(testNw.imageUrl)
			+ (isEdit ? '&mode=edit' : '')
			+ '&' + NAME 		 + '=' + encode(testNw.name)
      
      + '&' + REC_ID       + '=' + testNw.id
			+ '&' + RETIRED 	 + '=' + NewslettersUtils.convertFlag(testNw.retired)
			+ '&' + RET_URL 	 + '=' + encode(NewslettersController.RETURN_URL)
			+ '&' + SAMPLE_URL 	 + '=' + encode(testNw.sampleUrl);
	}

	/************************************************************************************
  	Method Name  : encode
  	Author       : Mantas Grigaliunas
  	Created Date : 28/09/2016
  	Function 	 : Used to encode string passed as url parameters
  	Change Log:
  	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
  	* Developer    Date         Description
  	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
  	*************************************************************************************/
  	@TestVisible
	private static String encode(String value){
		return EncodingUtil.urlEncode(value, 'UTF-8');
	}

	/************************************************************************************
  	Method Name  : createTestNewsletter
  	Author       : Mantas Grigaliunas
  	Created Date : 29/09/2016
  	Change Log:
  	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
  	* Developer    Date         Description
  	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
  	*************************************************************************************/
	@TestVisible
	private static NewslettersController.NewsletterWrapper createTestNewsletter(){
		String value = 'Test';
		NewslettersController.NewsletterWrapper nw = new NewslettersController.NewsletterWrapper();
		nw.id = value;
		nw.category = value;
		nw.name = value;
		nw.frequency = value;
		nw.imageUrl = value;
		nw.sampleUrl = value;
		nw.publicFacingUrl = value;
		nw.description = value;
		nw.hideSample = false;
		nw.retired = false;
    nw.defaultAccess = true;
		return nw;
	}
}