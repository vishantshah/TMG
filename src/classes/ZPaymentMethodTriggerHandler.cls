/**
* Author:       Sally ElGhoul (Accenture)
* Date:         14/10/2015
* Description:  Trigger handler for Zuora Payment Method Object
*
* ******************* Change Log *******************
* Modified by       Change Date     
**/
public class ZPaymentMethodTriggerHandler {
	
	private static ZPaymentMethodTriggerHandler instance;
	
	/*************************************************************************************** 
    Developer   Sally ElGhoul (Accenture)
    Date        14/10/2015
    Function    this function is called to return an instance of the trigger handler
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    public static ZPaymentMethodTriggerHandler getInstance() {
        if (instance == null) instance = new ZPaymentMethodTriggerHandler();
        return instance; 
    }
    
     /*************************************************************************************** 
    Developer   Sally ElGhoul (Accenture)
    Date        13/10/2015
    Function    this function is called to handle on after insert
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    public void OnAfterInsert(Zuora__PaymentMethod__c[] newPaymentMethods,map<id,Zuora__PaymentMethod__c> newPaymentMethodsMap){
    	
		LinkPaymentstoPaymentMethod(newPaymentMethods);
    }
    
     /*************************************************************************************** 
    Developer   Sally ElGhoul (Accenture)
    Date        13/10/2015
    Function    this function is called to handle the logic to link payment methods and payments
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    private void LinkPaymentstoPaymentMethod(Zuora__PaymentMethod__c[] newPaymentMethods){
    	
    	//set of payment method ids in Zuora
    	set<string> setZuoraPaymentMethodIds=new set<string>();
    	
    	//map for payment method Zuora Ids and payment method Salesforce Ids
    	map<string,id> mapPaymentMehotdZuoraIdSalesforceId=new map<string,id>();
    	
    	//loop on the new payment method records 
    	for(Zuora__PaymentMethod__c paymentMethodObj : newPaymentMethods){
    		
    		//fill the set of payment method ids in Zuora
    		if(paymentMethodObj.Zuora__External_Id__c != null && !setZuoraPaymentMethodIds.contains(paymentMethodObj.Zuora__External_Id__c) ){
    			setZuoraPaymentMethodIds.add(paymentMethodObj.Zuora__External_Id__c);
    		}
    		
    		//fill the map betwen payment method ids in Zuora and salesforce
    		if(!mapPaymentMehotdZuoraIdSalesforceId.containskey(paymentMethodObj.Zuora__External_Id__c)){
    			mapPaymentMehotdZuoraIdSalesforceId.put(paymentMethodObj.Zuora__External_Id__c,paymentMethodObj.id);
    		}
    	}
    	
    	if(setZuoraPaymentMethodIds!=null && setZuoraPaymentMethodIds.size() > 0){
	    	
	    	//get list of payments from salesforce using the payment method ids in zuora that is saved in the field ZuoraPaymentMethodId__c
	    	list<Zuora__Payment__c> lstZuoraPayment = [select ZuoraPaymentMethodId__c,Payment_Method__c,id from Zuora__Payment__c where ZuoraPaymentMethodId__c in : setZuoraPaymentMethodIds];
	    	
	    	//loop on payments and link payment method newly added to the payment record
	    	for(Zuora__Payment__c paymentObj : lstZuoraPayment){
	    		if(mapPaymentMehotdZuoraIdSalesforceId.containskey(paymentObj.ZuoraPaymentMethodId__c)){
	    			paymentObj.Payment_Method__c=mapPaymentMehotdZuoraIdSalesforceId.get(paymentObj.ZuoraPaymentMethodId__c);
	    		}
	    	}
	    	
	    	//update payment records
	    	if(lstZuoraPayment!=null && lstZuoraPayment.size()>0){
	    		update lstZuoraPayment;
	    	}
    	}
    }

}