/************************************************************************************
Class Name   : NewslettersCreateNewController
Author       : Mantas Grigaliunas
Created Date : 28/09/2016
Function     : Controller class for NewslettersCreateNew page
Change Log:
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
* Developer             Date         Description
* Vishant Shah          23/02/2017   Added DEFAULT_ACCESS
* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
*************************************************************************************/
public with sharing class NewslettersCreateNewController {

	public NewslettersController.NewsletterWrapper nw { get; set; }
	public String mode { get; set; }
	public Boolean isEditMode { get; set; }
	public String hideSampleAsString { get; set; }
	public String retiredAsString { get; set; }
    public String defaultAccessAsString { get; set; }

    public String allowChangeToDefaultAccess {
        get{
            return NewslettersUtils.getSetting('NewsletterChangeToDefaultAccessBy');
        }
    }

	@TestVisible private HttpResponse testResponse;
	@TestVisible private static final Integer OK = 200;
	@TestVisible private static final Integer BAD_REQUEST = 400; 
	@TestVisible private static final String ALREADY_EXISTS = 'Newsletter already exists';//record with same id
	private static final String POST = 'POST';
	private static final String PUT = 'PUT';
	private List<Newsletter_Configuration__c> lstConfigs;

    /************************************************************************************
    Method Name  : NewslettersCreateNewController (Constructor)
    Author       : Mantas Grigaliunas
    Created Date : 28/09/2016
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer    Date         Description
    * Vishant Shah 23/02/2017   Added DEFAULT_ACCESS
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
	public NewslettersCreateNewController(){

		try{
			lstConfigs = new List<Newsletter_Configuration__c>(
				[ SELECT Id, Name, Active__c, RecordTypeId FROM Newsletter_Configuration__c WHERE Active__c = true ORDER BY Name ASC ]
			);
			
			if(isEditMode()){
				nw = NewslettersUtils.getNewsletterFromUrlParams(ApexPages.currentPage());
				if(nw == null) NewslettersUtils.redirectToMainPage();
				hideSampleAsString = NewslettersUtils.convertFlag(nw.hideSample);
				retiredAsString = NewslettersUtils.convertFlag(nw.retired);
                defaultAccessAsString = NewslettersUtils.convertFlag(nw.defaultAccess);
			} else {
				nw = new NewslettersController.NewsletterWrapper();
			}
		} catch(Exception e){
			NewslettersUtils.redirectToMainPage();
			System.debug('TMGLOG::NewslettersCreateNewController:'+e.getMessage());
		}
	}

   /************************************************************************************
    Method Name  : validateParameters
    Author       : Mantas Grigaliunas
    Created Date : 28/09/2016
    Function     : Method used on page load to handle blank values or exception if parameters are not passed.
                   This usually happen when signing in back from timed out session
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    public PageReference validateParameters(){
        if(ApexPages.currentPage().getParameters().size() == 0)
            return NewslettersUtils.redirectToMainPage();
        else return null;
    }

    /************************************************************************************
    Method Name  : getYesNoOptions
    Author       : Mantas Grigaliunas
    Created Date : 28/09/2016
    Function     : Method used in visualforce page to show picklist values defined in controller
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
	public List<SelectOption> getYesNoOptions(){
		List<SelectOption> options = new List<SelectOption>();
		String NO = Label.Newsletter_Picklist_Value_Label_No;
		String YES = Label.Newsletter_Picklist_Value_Label_Yes;
		options.add(new SelectOption(NO, NO));
		options.add(new SelectOption(YES, YES));
		return options;
	}

    /************************************************************************************
    Method Name  : getCategoryOptions
    Author       : Mantas Grigaliunas
    Created Date : 28/09/2016
    Function     : Method used in visualforce page to show picklist values defined in custom setting
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
	 public List<SelectOption> getCategoryOptions(){
        List<SelectOption> categoryOptions = new List<SelectOption>();
        String categoryRecTypeId = RecordTypeUtility.getRecordTypeId(Newsletter_Configuration__c.sObjectType, 
                                Constants.NEWSLETTER_CATEGORY_RECORD_TYPE_NAME, Newsletter_Configuration__c.class.getName());
        for(Newsletter_Configuration__c config : lstConfigs){
            if(config.RecordTypeId.equals(categoryRecTypeId)){
                categoryOptions.add(new SelectOption(config.Name, config.Name));
            }       
        }
        return categoryOptions;
    }

    /************************************************************************************
    Method Name  : getFrequencyOptions
    Author       : Mantas Grigaliunas
    Created Date : 28/09/2016
    Function     : Method used in visualforce page to show picklist values defined in custom setting
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    public List<SelectOption> getFrequencyOptions(){
        List<SelectOption> frequencyOptions = new List<SelectOption>();
        String frequencyRecTypeId = RecordTypeUtility.getRecordTypeId(Newsletter_Configuration__c.sObjectType, 
                                Constants.NEWSLETTER_FREQUENCY_RECORD_TYPE_NAME, Newsletter_Configuration__c.class.getName());
        for(Newsletter_Configuration__c config : lstConfigs){
            if(config.RecordTypeId.equals(frequencyRecTypeId)){
                frequencyOptions.add(new SelectOption(config.Name, config.Name));
            }       
        }
        return frequencyOptions;
    }

    /************************************************************************************
    Method Name  : saveRecord
    Author       : Mantas Grigaliunas
    Created Date : 28/09/2016
    Function     : Save button actyion to save the new newsletter record to server
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
	public PageReference saveRecord(){
		//Checking that id is valid
        Pattern MyPattern = Pattern.compile('[A-Za-z_0-9]+');
        Matcher MyMatcher = MyPattern.matcher(nw.id);
        if(!MyMatcher.matches()){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 
            	String.format(Label.Newsletters_Id_Validation_Error, new List<String>{Label.Newsletter_Id})));
            return null;
        }

		try{
	        //get server response
	        HttpResponse response = new HttpResponse();
	        if(!Test.isRunningTest()) 
	        	response = NewslettersUtils.getResponse(POST, 
	        		NewslettersUtils.getSetting(Constants.NEWSLETTERS_POST_END_POINT), setRequestBody());
	        else response = testResponse;
	        if(response.getStatusCode() == OK){
	        	PageReference pageRef = Page.NewslettersView;
	        	return NewslettersUtils.generateUrl(Page.NewslettersView, false, NewslettersController.RETURN_URL, nw);
	        } else if(response.getStatusCode() == BAD_REQUEST && response.getBody().contains(ALREADY_EXISTS)){
	        	ApexPages.addMessage(new ApexPages.Message(
	        		ApexPages.Severity.ERROR, 
	        		String.format(Label.Newsletter_Already_Exists_Error, new List<String>{Label.Newsletter_Id, nw.Id})));
	        	return null;
	        } else {
	        	TMGUtil.displayServerError(response);
	        	return null;
	        }
	  	} catch (Exception e){
	  		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, e.getMessage()));
	  		return null;
	  	}
	}

    /************************************************************************************
    Method Name  : updateRecord
    Author       : Mantas Grigaliunas
    Created Date : 28/09/2016
    Function     :  Update button action to update existing newsletter record to server
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
	public PageReference updateRecord(){

		try{
			HttpResponse response = new HttpResponse();
	        if(!Test.isRunningTest()) 
	        	response = NewslettersUtils.getResponse(PUT, 
	        		String.format(NewslettersUtils.getSetting(Constants.NEWSLETTERS_PUT_END_POINT), 
	        			new List<String>{nw.id}), 
	        		setRequestBody()
	        	);
	        else response = testResponse;
	        if(response.getStatusCode() == OK){
	        	PageReference pageRef = Page.NewslettersView;
	        	return NewslettersUtils.generateUrl(Page.NewslettersView, false, NewslettersController.RETURN_URL, nw);
	        } else {
	        	TMGUtil.displayServerError(response);
	        	return null;
	        }
   		} catch(Exception e){
   			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, e.getMessage()));
   			return null;
   		}
	}

    /************************************************************************************
    Method Name  : cancel
    Author       : Mantas Grigaliunas
    Created Date : 28/09/2016
    Function     : Cancel button action to redirect to the page set in url parameter
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
	public PageReference cancel(){
		Map<String, String> paramsMap = ApexPages.currentPage().getParameters();
		if(paramsMap.containsKey('retUrl'))
			return new PageReference(paramsMap.get('retUrl'));
		else return new PageReference(NewslettersController.RETURN_URL);
	}

    /************************************************************************************
    Method Name  : isEditMode
    Author       : Mantas Grigaliunas
    Created Date : 28/09/2016
    Function     : Returns boolean based on there url paramter is edit or not
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
	public Boolean isEditMode(){
		isEditMode = false;
		String mode = ApexPages.currentPage().getParameters().get('mode');
		if(mode != null)
			isEditMode = (mode.equals('edit') ? true : false);
		return isEditMode;
	}

    /************************************************************************************
    Method Name  : setRequestBody
    Author       : Mantas Grigaliunas
    Created Date : 28/09/2016
    Function     : Method to serialize the newsletter wrapper class instance to JSON
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
	@TestVisible
	private String setRequestBody(){
		nw.hideSample = NewslettersUtils.convertFlag(hideSampleAsString);
		nw.retired = NewslettersUtils.convertFlag(retiredAsString);
        nw.defaultAccess = NewslettersUtils.convertFlag(defaultAccessAsString);
		try{
			return JSON.serialize(nw);
		} catch (JSONException e){
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Failed to parse JSON. ' + e.getMessage()));
			return null;
		}
	}
}