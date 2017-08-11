/************************************************************************************
Class Name   : NewslettersViewController
Author       : Mantas Grigaliunas
Created Date : 28/09/2016
Function     : Controller class for NewslettersView page
Change Log:
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
* Developer             Date         Description
* Vishant Shah          23/02/2017   Added allowChangeToDefaultAccess
* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
*************************************************************************************/
public class NewslettersViewController {

	public NewslettersController.NewsletterWrapper nw { get; set; }
    public String allowChangeToDefaultAccess {
        get{
            return NewslettersUtils.getSetting('NewsletterChangeToDefaultAccessBy');
        }
    }

    /************************************************************************************
    Method Name  : NewslettersViewController (Constructor)
    Author       : Mantas Grigaliunas
    Created Date : 28/09/2016
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
	public NewslettersViewController() {
		nw = NewslettersUtils.getNewsletterFromUrlParams(ApexPages.currentPage());
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
    Method Name  : editRecord
    Author       : Mantas Grigaliunas
    Created Date : 28/09/2016
    Function     : Method to redirect to edit page and pass ret url as current page with newsletter values as url parameters
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
	public PageReference editRecord(){
        try{
    		PageReference retUrl =  NewslettersUtils.generateUrl(Page.NewslettersView, false, NewslettersController.RETURN_URL, nw);
    		return NewslettersUtils.generateUrl(Page.NewslettersCreateNew, true, retUrl.getUrl(), nw);
        } catch(Exception e){
            System.debug('TMGLOG::NewslettersViewController:editRecord:'+e.getMessage());
            return NewslettersUtils.redirectToMainPage();
        }
	}
}