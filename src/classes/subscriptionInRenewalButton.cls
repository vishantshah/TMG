/**
* @author Unknown
* @date Unknown
* @description  Class and method called by new subscription button on a Subscription page. Creates a new 'Offered'
                subscription with fields populated with values from the current subscription in view.
#############Change Log#############
Modified by     Version     Change Date
Wiktor Czykin   1.1         30/07/2015  //removed useless comments
Cristina Anghenie 1.2		19/08/2015	//pre-populate PaymentDate and Frequence when new subscription is created
Wiktor Czykin   1.3         16/09/2015  //Low start related field added to soql
Pawel Chrzanowski   1.4     04/04/2016  //added fields to the query string: Renewal_Product_Override__c, Plan__c, Product__c
Michal Szewczyk 1.5         11/05/2016  //removed Subscription_Product__c from code
**/
global class subscriptionInRenewalButton{

    webservice static String subInRenewal(Id currentSubID){
        //Return values of the current subscription in view using ID passed in
        //Added the field RecordTypeId in the query below to identify the record type of the subs as well
        Map<ID, Subscription__c> currentSub = new Map<Id, Subscription__c>([select  Subscription_Start_Calc__c,
                                                                                    Price_Plan__c, 
                                                                                    New_Sub_Duration__c, 
                                                                                    Subscription_Status__c, 
                                                                                    Subscriber__c,
                                                                                    Subscriber__r.RecordTypeId, 
                                                                                    Start_Date__c, 
                                                                                    End_Date__c, 
                                                                                    Previous_Subscription__c, 
                                                                                    Retailer__c, 
                                                                                    Delivery_Type__c,
                                                                                    Subscription_Duration_Picklist__c,
                                                                                    Subscription_Duration_Number__c, 
                                                                                    Weekly_Price__c, 
                                                                                    Previous_Price__c, 
                                                                                    Discount__c, 
                                                                                    payment_type__c, 
                                                                                    isContinuous__c,
                                                                                    MPP_CC_Frequency__c, 
                                                                                    RecordTypeId, 
                                                                                    PaymentDate__c,
                                                                                    MPP_DD_Frequency__c,
                                                                                    Renewal_Price_Override__c,
                                                                                    Renewal_Product_Override__c,
                                                                                    Plan__c,
                                                                                    Product__c
        																	from Subscription__c 
                                                                            where Id = :currentSubID]);       
        //Inialise Redirect string 
        String redirectToID = 'Error';  
                                
        //Create new offered subscriptions for 'In Renewal' subscriptions           
        if(currentSub != null){                    
            //create new subscriptions array with the copied parameters
            String source = 'button';
            Map<Id,Id> curSubNewSubMap = subscriptionInRenewalCreation.handleRenewedSubscriptions(currentSub, source); 
            if (curSubNewSubMap.size()!=1) {
                return 'Error';                                                                                                                                                     
            } else {
                return curSubNewSubMap.get(currentSub.values()[0].Id);
            }                                    
        }
        //return ID value for page redirect, or 'Error' string if sub not created       
        return redirectToID;
    }       
}