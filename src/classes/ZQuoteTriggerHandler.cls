/**
* Author:       Sally ElGhoul (Tquila)
* Date:         8/07/2015
* Description:  Trigger handler for Zuora quote Object
*
* ******************* Change Log *******************
* Modified by       Change Date
* Michal Kwika      06/01/2016
* Michal Kwika      16/01/2016
* Sally ElGhoul		18/02/2016 - set the term start date to be = service activation date whenever the service activation date value is changed
* Michal Kwika      29/02/2016 - fillQuoteExpirationField() method changed
**/
public class ZQuoteTriggerHandler {

    private static ZQuoteTriggerHandler instance;

    /***************************************************************************************
    Developer   Sally ElGhoul (Tquila)
    Date        8/07/2015
    Function    this function is called to return an instance of the trigger handler
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    public static ZQuoteTriggerHandler getInstance() {
        if (instance == null) instance = new ZQuoteTriggerHandler();
        return instance;
    }

    /***************************************************************************************
    Developer   Sally ElGhoul (Tquila)
    Date        20/07/2015
    Function    this function is called to handle on before insert
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    public void OnBeforeInsert(zqu__Quote__c[] newQuotes) {
        fillQuoteExpirationField(newQuotes);
        //copy values for Activation acceptance date
        copyValuesForServiceActivationDate(newQuotes);
    }

    /***************************************************************************************
    Developer   Sally ElGhoul (Accenture)
    Date        21/10/2015
    Function    this function is called to handle on after insert
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    public void OnAfterInsert(zqu__Quote__c[] newQuotes) {

        //copy the offer codes from the previous quote to the new amendment quote
        CopyPreviousQuoteOffers(newQuotes);
    }

    /***************************************************************************************
    Developer   Michal Kwika (Accenture)
    Date        06/01/2016
    Function    this function is called to handle on after update
    ******************* Change Log *******************
    Modified by         Version     Change Date
    Michal Kwika        1.1         16/01/2016
    Sally ElGhoul		1.2			18/02/2016 - set term start date to be = service activation date whenever service activation date value is changed
    ****************************************************************************************/
    public void OnBeforeUpdate(zqu__Quote__c[] newQuotes, Map <Id, zqu__Quote__c> mOldQuotes) {

        //copy values for Activation acceptance date
        copyValuesForServiceActivationDate(newQuotes);
        //extend the quote if flag value has changed
        extendTheQuote(newQuotes, mOldQuotes);
        
        //Update the term start date value to be equals to service activation date
        updateTermStartDate(newQuotes,mOldQuotes);
    }

    /***************************************************************************************
    Developer   Sally ElGhoul (Tquila)
    Date        20/07/2015
    Function    this function is called to fill the quote expiration date/time field
    ******************* Change Log *******************
    Modified by         Version     Change Date
    Michal Kwika        1.1         29/02/2016 - changed approach for setting the datetime
    ****************************************************************************************/
    private void fillQuoteExpirationField(zqu__Quote__c[] newQuotes) {
        for (zqu__Quote__c quoteObj : newQuotes) {
            //set the expiration date to be the next day at 00:00 time
            quoteObj.Expiration_Date_Time__c = Date.today().addDays(1);
        }
    }

    /***************************************************************************************
    Developer   Sally ElGhoul (Accenture)
    Date        21/10/2015
    Function    this function is called to copy the offer code records from previous quote
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    private void CopyPreviousQuoteOffers(zqu__Quote__c[] newQuotes) {

        //set to save the previous quote ids of the new amendment quotes
        set<id> setPreviousQuoteIds = new set<id>();

        //map between the previous quote id and the new quote ids
        map<id, id> mapPreviousQuoteCurrentQuoteIds = new map<id, id>();

        //loop on quote and get their previous quote Ids
        for (zqu__Quote__c quoteObj : newQuotes) {
            if (quoteObj.Previous_Quote__c != null && !setPreviousQuoteIds.contains(quoteObj.Previous_Quote__c)) {
                setPreviousQuoteIds.add(quoteObj.Previous_Quote__c);
                mapPreviousQuoteCurrentQuoteIds.put(quoteObj.Previous_Quote__c, quoteObj.id);
            }
        }

        //clone offer codes from the previous quote to the new amendment quote
        OfferCode_Utility.cloneOfferCodes(setPreviousQuoteIds, mapPreviousQuoteCurrentQuoteIds);
    }

    /***************************************************************************************
    Developer   Michal Kwika (Accenture)
    Date        06/01/2016
    Function    this function is called to copy values from SERVICE ACTIVATION DATE
                to Customer Acceptance Date
    ******************* Change Log *******************
    Modified by         Version     Change Date
    Sally ElGhoul		1.1			18/2/2016	- set the term start date to be euqlas to service activation date
    ****************************************************************************************/
    private void copyValuesForServiceActivationDate(zqu__Quote__c[] newQuotes) {
        for (zqu__Quote__c quoteObj : newQuotes) {
            //set the test first
            quoteObj.zqu__Customer_Acceptance_Date__c = quoteObj.zqu__Service_Activation_Date__c;
            quoteObj.zqu__TermStartDate__c=quoteObj.zqu__Service_Activation_Date__c;
        }
    }

    /***************************************************************************************
    Developer   Michal Kwika (Accenture)
    Date        16/01/2016
    Function    this function is called to set new values of dates based on Flag on on Quote
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    private void extendTheQuote(zqu__Quote__c[] newQuotes, Map <Id, zqu__Quote__c> mOldQuotes) {

        for (zqu__Quote__c quoteObj : newQuotes) {
            if ((quoteObj.Extend_Quote_14_days__c != mOldQuotes.get(quoteObj.Id).Extend_Quote_14_days__c) && quoteObj.zqu__Status__c.equalsIgnoreCase(Constants.QUOTE_STATUS_NEW_VALUE))  {

                if (quoteObj.Extend_Quote_14_days__c) {
                    //set expiration date time and valid until date to date 14 days from now
                    quoteObj.Expiration_Date_Time__c = quoteObj.Expiration_Date_Time__c.addDays(Constants.QUOTE_NUMBER_OF_DAYS_EXTENDED_QUOTE);
                    quoteObj.zqu__ValidUntil__c = quoteObj.zqu__ValidUntil__c.addDays(Constants.QUOTE_NUMBER_OF_DAYS_EXTENDED_QUOTE);
                    
                } else {
                    //set expiration date time and valid until date to today's date
                    quoteObj.Expiration_Date_Time__c = Date.today().addDays(1);
                    quoteObj.zqu__ValidUntil__c = Date.today();
                }
            }
        }
    }
 	
 	/***************************************************************************************
    Developer   Sally ElGhoul (Accenture)
    Date        18/02/2016
    Function    this function is called to set the term start date to be = service activation date
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
 	 private void  updateTermStartDate(zqu__Quote__c[] newQuotes, Map <Id, zqu__Quote__c> mOldQuotes) {
 	 	
 	 	for(zqu__Quote__c newQuoteObj : newQuotes){
 	 		zqu__Quote__c oldQuoteObj = mOldQuotes.get(newQuoteObj.id);
 	 		
 	 		//check that service activation date changed and if so , update the term start date to be equals to service activation date
 	 		if(newQuoteObj.zqu__Service_Activation_Date__c!=oldQuoteObj.zqu__Service_Activation_Date__c){
 	 			newQuoteObj.zqu__TermStartDate__c=newQuoteObj.zqu__Service_Activation_Date__c;
 	 		}
 	 	}
 	 	
 	 } 
}