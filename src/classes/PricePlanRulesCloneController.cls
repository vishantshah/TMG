/**
* Author:       Gavin Palmer (Accenture)
* Date:         21/04/2016
* Description:  The page is designed to override the standard clone functionality
*               so that it also brings back the child records.
* ******************* Change Log *******************
* Modified by       Change Date     Description
* Michal Szewczyk   11/11/2016      Changed saveClonedRecord();
* Michal Szewczyk   14/11/2016      Changed PricePlanRulesCloneController()
* Wiktor Czykin     17/05/2017      Changed saveClonedRecord()
**/
public class PricePlanRulesCloneController {

    private Id originalPlanId;
    public Plan__c planClone {get; set;}
    private Boolean isAllowedFullSave {get; set;}

    /**
    * Author:       Gavin Palmer (Accenture)
    * Date:         21/04/2016
    * Description:  a standard controller is implimented so that we can override 
    *               the standard clone functionality
    * ******************* Change Log *******************
    * Modified by       Change Date     Description
    * Michal Szewczyk   14/11/2016      Added Product__c to soql for clone 
    **/
    public PricePlanRulesCloneController(ApexPages.StandardController controller) {
        
        originalPlanId = controller.getId();
        List<Plan__c> planList = [
            SELECT Id, Name, Days_Before__c, Is_Valid__c, Description__c,Product__c
            FROM Plan__c
            WHERE Id = :originalPlanId
            LIMIT 1
        ];
        if(planList.isEmpty()) throw new TelegraphApplicationException(Label.Price_Plan_Retrieve_Records_Error);

        planClone = planList[0].clone(false, true);
       
        //by default do not allow full save
        isAllowedFullSave = false;
    }

    /**
    * Author:       Gavin Palmer (Accenture)
    * Date:         21/04/2016
    * Description:  Redirect to the original record
    *
    * ******************* Change Log *******************
    * Modified by       Change Date     Description
    **/
    public PageReference returnToOriginalPlanPage(){
        PageReference planRecordPage = new PageReference('/' + originalPlanId);
        planRecordPage.setRedirect(true);
        return planRecordPage;
    }

    /**
    * Author:       Gavin Palmer (Accenture)
    * Date:         21/04/2016
    * Description:  Validate that we can save child records and continue
    * ******************* Change Log *******************
    * Modified by       Change Date     Description
    **/
    public PageReference saveChildRecords(){
        //validate that the logged in user has the campaign offer code management permission set
        //if not, this user can't save the child records
        List<PermissionSetAssignment> lstAssignment = [
            SELECT PermissionSetId 
            FROM PermissionSetAssignment
            WHERE AssigneeId= :UserInfo.getUserId() 
            AND PermissionSet.Name = :Constants.TCODE_OFFER_CODE_MANAGEMENT_PERMISSION_SET
        ];
        
        // if the class is running in a test I want it to ignore the error message part
        if(lstAssignment.isEmpty() && !Test.isRunningTest()){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Price_Plan_Insufficient_Privileges_2));
            return null;
        } else {
            isAllowedFullSave = true;
            return saveClonedRecord();
        }
    }

    /**
    * Author:       Gavin Palmer (Accenture)
    * Date:         21/04/2016
    * Description:  Save the record, and if allowed save the child records
    * ******************* Change Log *******************
    * Modified by       Change Date     Description
    * Michal Szewczyk   11/11/2016      Added cloning for childs Price_Plan_Offers records
    * Wiktor Czykin     17/05/2017      Changed SoqlUtility reference to GlobalQueries 
    **/
    public PageReference saveClonedRecord(){
        PageReference pageDestination;
        // Set a savepoint so that the parent record doesnt save if the children dont
        Savepoint sp = Database.setSavepoint();

        if(isValidPricePlan()){
            try{

                insert planClone;

            } catch (Exception exceptionToHandle){
                System.debug(loggingLevel.Error, 'An error has occured in: ' + exceptionToHandle);
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Price_Plan_Clone_Save_Error));
                return null;
            }
        } else {
            return pageDestination;
        }

        if(isAllowedFullSave){
            try{
                // find the children price plan objects
                String whereClause = 'Plan__c = \'' + originalPlanId + '\'';
                String soqlQueryString = GlobalQueries.queryBuilderSelectAll(Price_Plan__c.class.getName(), null, whereClause, '', '');
                String soqlQueryOffersString = GlobalQueries.queryBuilderSelectAll(Price_Plan_Offer__c.class.getName(), null, '', '', '');
                soqlQueryOffersString = soqlQueryOffersString.replace('Price_Plan_Offer__c', 'Price_Plan_Offers__r');
                String soqlfinalQuery = soqlQueryString.replace('SELECT ', 'SELECT ('+soqlQueryOffersString+'),' );
                List<Price_Plan_Offer__c> pricePlansOffers = new List<Price_Plan_Offer__c>();
                List<Price_Plan__c> childrenPricePlans = Database.query(soqlfinalQuery);
                Price_Plan__c tmp = null;
                // clone the price plan objects and add the cloned plan as the new lookup
                List<Price_Plan__c> clonedPricePlans = new List<Price_Plan__c>();
                Map<Integer,List<Price_Plan_Offer__c>> pricePlanOfferMapping = new Map<Integer,List<Price_Plan_Offer__c>>();
                Integer i = 0;
                for(Price_Plan__c pricePlan : childrenPricePlans){

                    Price_Plan__c pricePlanClone = pricePlan.clone(false, true);
                    pricePlanClone.Plan__c = planClone.Id;
                    clonedPricePlans.add(pricePlanClone);
                    pricePlanOfferMapping.put(i,pricePlan.Price_Plan_Offers__r.deepClone(false,false,false));
                    i++;
                }
               insert clonedPricePlans;
               for(Integer j=0;j < clonedPricePlans.size();j++){
                    for(Price_Plan_Offer__c ppOffer: pricePlanOfferMapping.get(j)){
                        ppOffer.Price_Plan__c = clonedPricePlans[j].Id;
                        pricePlansOffers.add(ppOffer);
                    }
                }
                insert pricePlansOffers;
            } catch (Exception exceptionToHandle){
                Database.rollback(sp);
                // clear id if we roll back the save
                planClone.Id = null;
                System.debug(loggingLevel.Error, 'An error: ' + exceptionToHandle);
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Price_Plan_Clone_Save_Error));
                return null;
            }
            // perhaps the page redirect will be set on the permission set check
            pageDestination = Page.PricePlanRulesSetup;
            pageDestination.getParameters().put('id', planClone.Id);  
        } else {
            pageDestination = new PageReference('/' + planClone.Id);
        }
        
        return pageDestination;
    }

    /**
    * Author:       Gavin Palmer (Accenture)
    * Date:         21/04/2016
    * Description:  Validate the required fields on the page
    *
    * ******************* Change Log *******************
    * Modified by       Change Date     Description
    **/
    private Boolean isValidPricePlan(){
        if(String.isEmpty(planClone.Name)){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Price_Plan_Name_Error));
        }
        if(ApexPages.hasMessages()){
            return false;
        }
        return true;
    }
}