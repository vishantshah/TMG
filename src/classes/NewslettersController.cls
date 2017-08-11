/************************************************************************************
Class Name   : NewslettersController
Author       : Mantas Grigaliunas
Created Date : 28/09/2016
Function     : Controller for Newsletters page, includes NewsletterWrapper class to parse JSON from server and sort results list by columns
Change Log:
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
* Developer             Date         Description
* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
*************************************************************************************/
public class NewslettersController {

	public List<NewsletterWrapper> lstNewsletters { get; set; }
	public static String selectedNewsletterId { get; set; }

	@TestVisible private static final Integer OK         = 200;
    @TestVisible private static final Integer NOT_FOUND  = 404;
    @TestVisible private HttpResponse testResponse;
   	@TestVisible private static final String SORT_ORDER = 'asc';
    private static final String GET 	  = 'GET';
    public static final String RETURN_URL = '/apex/Newsletters';
    private Map<String, NewsletterWrapper> mapNewsletters = new Map<String, NewsletterWrapper>();

   	public static String sortField {
    	get { 
    		if(sortField == null) sortField = Label.Newsletter_Category;
    		return sortField; 
    	}
    	set { sortField = value; }
    }

    public static String sortOrder {
    	get {
    		if(sortOrder == null) sortOrder = SORT_ORDER;
    		return sortOrder; 
    	}
    	set { sortOrder = value; }
    }

    /************************************************************************************
    Method Name  : NewslettersController (Constructor)
    Author       : Mantas Grigaliunas
    Created Date : 28/09/2016
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    public NewslettersController() {}

    /************************************************************************************
    Method Name  : getNewsletters
    Author       : Mantas Grigaliunas
    Created Date : 28/09/2016
    Function     : Retrieves newsletters from commerce server and populates as a list
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
	public void getNewsletters(){

		try{

			lstNewsletters = new List<NewsletterWrapper>();
			String endpoint = NewslettersUtils.getSetting(Constants.NEWSLETTERS_GET_END_POINT);
			if(endpoint == null){
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 
	  				String.format(Label.Newsletter_Custom_Setting_Missing, new List<String>{Constants.NEWSLETTERS_GET_END_POINT})));
			} else {
				
		        //get server response
		        HttpResponse response = new HttpResponse();
		        if(!Test.isRunningTest()) 
		        	response = NewslettersUtils.getResponse(GET, endpoint, null);
		        else response = testResponse;

		        //parse response results
		        if(response.getStatusCode() == OK){
		        	lstNewsletters = parse(response.getBody());
		        	if(lstNewsletters.size() > 0){
		        		for(NewsletterWrapper nw : lstNewsletters){
		        			mapNewsletters.put(nw.id, nw);
		        		}
		        		sort();
		        	}
		        } else if(response.getStatusCode() == NOT_FOUND)
		        	ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, Label.Newsletter_Not_Found));
		        else
		        	TMGUtil.displayServerError(response);
		   	}
	  	} catch(Exception e){
	  		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 
	  								Label.Newsletters_Unexpected_Error + '\n' + e.getMessage()));
	  	}
	}

    /************************************************************************************
    Method Name  : createNew
    Author       : Mantas Grigaliunas
    Created Date : 28/09/2016
    Function     : New button action function to navigate to NewslettersCreateNew page
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
	public PageReference createNew(){
		PageReference pageRef = Page.NewslettersCreateNew;
		pageRef.getParameters().put('retUrl', RETURN_URL);
		return pageRef;
	}

	/************************************************************************************
    Method Name  : editRecord
    Author       : Mantas Grigaliunas
    Created Date : 28/09/2016
    Function     : New button action function to navigate to NewslettersCreateNew page
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
	public PageReference editRecord(){
		return NewslettersUtils.generateUrl(Page.NewslettersCreateNew, true, RETURN_URL, getSelectedNewsletter());
	}

	/************************************************************************************
    Method Name  : viewRecord
    Author       : Mantas Grigaliunas
    Created Date : 28/09/2016
    Function     : View outputlink action function to navigate to NewslettersView page
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
	public PageReference viewRecord(){
		return NewslettersUtils.generateUrl(Page.NewslettersView, false, RETURN_URL, getSelectedNewsletter());
	}

	/************************************************************************************
    Method Name  : getSelectedNewsletter
    Author       : Mantas Grigaliunas
    Created Date : 28/09/2016
    Function     : Return the newsletter record from the list
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
	private NewsletterWrapper getSelectedNewsletter(){
		if(selectedNewsletterId == null) 
			selectedNewsletterId = ApexPages.currentPage().getParameters().get('id');
		return mapNewsletters.get(selectedNewsletterId);
	}

	/************************************************************************************
    Method Name  : sort
    Author       : Mantas Grigaliunas
    Created Date : 28/09/2016
    Function     : Column sort action to call implemented sorting function
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
	public void sort(){
   		lstNewsletters.sort();
   	}

	/************************************************************************************
    Class Name  : NewsletterWrapper
    Author       : Mantas Grigaliunas
    Created Date : 28/09/2016
    Function     : Wrapper class used to parse server results
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer    Date         Description
    * Vishant Shah 23/02/2017   Added defaultAccess
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
	public class NewsletterWrapper implements Comparable {

		public String id { get; set; }
		public String category { get; set; }
		public String name { get; set; }
		public String frequency { get; set; }
		public String imageUrl { get; set; }
		public String sampleUrl { get; set; }
		public String publicFacingUrl { get; set; }
		public String description { get; set; }
		public Boolean hideSample { get; set; }
		public Boolean retired { get; set; }
		public Boolean defaultAccess { get; set; }

		//generic constructor
		public NewsletterWrapper(){}

		public NewsletterWrapper(String id, String category, String name, String frequency, String imageUrl,
								 String sampleUrl, String publicFacingUrl, String description, Boolean hideSample, Boolean retired, Boolean defaultAccess){
			this.id = id;
			this.category = category;
			this.name = name;
			this.frequency = frequency;
			this.imageUrl = imageUrl;
			this.sampleUrl = sampleUrl;
			this.publicFacingUrl = publicFacingUrl;
			this.description = description;
			this.hideSample = hideSample;
			this.retired = retired;
			this.defaultAccess = defaultAccess == null ? false : defaultAccess;
		}

		/************************************************************************************
	    Method Name  : compareTo
	    Author       : Mantas Grigaliunas
	    Created Date : 28/09/2016
	    Function     : Sorting implementation method to sort list by specific column
	    Change Log:
	    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
	    * Developer    Date         Description
	    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	    *************************************************************************************/
		public Integer compareTo(Object compareTo) {
	        NewsletterWrapper compareToNewsletter = (NewsletterWrapper)compareTo;
			Integer value = 0;

	        if(sortField.equals(Label.Newsletter_Category)){
		        if(category == compareToNewsletter.category) value = 0;
				else if(category > compareToNewsletter.category) value = sortOrder.equals(SORT_ORDER) ? 1 : 0;
				else value = sortOrder.equals(SORT_ORDER) ? 0 : 1; 
		   	}
		   	if(sortField.equals(Label.Newsletter_Name)){
		        if(name == compareToNewsletter.name) value = 0;
				else if(name > compareToNewsletter.name) value = sortOrder.equals(SORT_ORDER) ? 1 : 0;
				else value = sortOrder.equals(SORT_ORDER) ? 0 : 1; 
		   	}
		   	if(sortField.equals(Label.Newsletter_Frequency)){
		        if(frequency == compareToNewsletter.frequency) value = 0;
				else if(frequency > compareToNewsletter.frequency) value = sortOrder.equals(SORT_ORDER) ? 1 : 0;
				else value = sortOrder.equals(SORT_ORDER) ? 0 : 1; 
		   	}
		   	if(sortField.equals(Label.Newsletter_Description)){
		        if(description == compareToNewsletter.description) value = 0;
				else if(description > compareToNewsletter.description) value = sortOrder.equals(SORT_ORDER) ? 1 : 0;
				else value = sortOrder.equals(SORT_ORDER) ? 0 : 1; 
		   	}
		   	if(sortField.equals(Label.Newsletter_Retired)){
		        if(retired == compareToNewsletter.retired) value = 0;
				else if(retired && !compareToNewsletter.retired) value = sortOrder.equals(SORT_ORDER) ? 1 : 0;
				else value = sortOrder.equals(SORT_ORDER) ? 0 : 1; 
		   	}
		   	return value;     
	    }
	}

	/************************************************************************************
    Method Name  : parse
    Author       : Mantas Grigaliunas
    Created Date : 28/09/2016
    Function     : JSON to NewsletterWrapper list parses
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
	public static List<NewsletterWrapper> parse(String json){
        return (List<NewsletterWrapper>) System.JSON.deserialize(json, List<NewsletterWrapper>.class);
    }

    /************************************************************************************
    Method Name  : setTestResponse
    Author       : Vishant Shah
    Created Date : 28/09/2016
    Function     : added this to set the testresponse as its marked private and i dont want to break other things.
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    public void setTestResponse(HttpResponse response){
    	testResponse = response;
    }
}