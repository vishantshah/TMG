/**
* Author:       Sally ElGhoul (Accenture)
* Date:         13/10/2015
* Description:  Trigger handler for Zuora Payment Object
*
* ******************* Change Log *******************
* Modified by       Change Date     
**/
public class ZPaymentTriggerHandler {
	
	private static ZPaymentTriggerHandler instance;
	
	/*************************************************************************************** 
    Developer   Sally ElGhoul (Accenture)
    Date        13/10/2015
    Function    this function is called to return an instance of the trigger handler
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    public static ZPaymentTriggerHandler getInstance() {
        if (instance == null) instance = new ZPaymentTriggerHandler();
        return instance; 
    }
    
    /*************************************************************************************** 
    Developer   Sally ElGhoul (Accenture)
    Date        10/12/2015
    Function    this function is called to handle on before insert
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    public void OnBeforeInsert(Zuora__Payment__c[] newPayments){
        
        //for bank transfers, change the word bank transfer to be direct debit
        ChangeDirectDebitMethodName(newPayments);
    }
    
     /*************************************************************************************** 
    Developer   Sally ElGhoul (Accenture)
    Date        13/10/2015
    Function    this function is called to handle on after insert
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    public void OnAfterInsert(Zuora__Payment__c[] newPayments,map<id,Zuora__Payment__c> newPaymentsMap){
    	
    	//List of the payment ids in Zuora
    	list<string> lstZuoraPaymentIds=new list<string>(); //zuora ids
    	
    	//set of the payment ids in SF
    	set<id> setSFPaymentIds=new set<id>{};  //sf Ids
    	
    	//loop on the new payment records and fill both the list of payment zuora Ids and payment Salesforce Ids
    	for(Zuora__Payment__c paymentObj : newPayments){
    		
    		//Zuora Id
    		lstZuoraPaymentIds.add(paymentObj.Zuora__EXT_ID__c);
    		
    		//Salesforce Id
    		if(!setSFPaymentIds.contains(paymentObj.id)){
    			setSFPaymentIds.add(paymentObj.id);
    		}
    	}
    	
    	if(lstZuoraPaymentIds!=null && lstZuoraPaymentIds.size()>0 && setSFPaymentIds!=null && setSFPaymentIds.size()>0){
        	//call the helper function that will link payments to payment methods
        	fillSFPaytmentMethodId(lstZuoraPaymentIds,setSFPaymentIds);
    	}else{
    		string errorString='Error ZPaymentTrigger After inster. Either the zupra payment Ids are empty:'+lstZuoraPaymentIds+'  or the salesforce payment Ids are empty:'+setSFPaymentIds;
    		system.debug(errorString);
    		throw new TMGUtil.GenericException(errorString);
    	}
    }
    
    /*************************************************************************************** 
    Developer   Sally ElGhoul (Accenture)
    Date        10/12/2015
    Function    this function is called to change the payment method text to replace bank transfer to be direct debit
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    private void ChangeDirectDebitMethodName(list<Zuora__Payment__c> newPayments){
        for(Zuora__Payment__c paymentObj :newPayments){
            if(!string.isempty(paymentObj.Zuora__PaymentMethod__c)){
                paymentObj.Zuora__PaymentMethod__c =paymentObj.Zuora__PaymentMethod__c.replace(constants.DIRECT_DEBIT_PAYMENT_METHOD,constants.PAYMENT_METHOD_DIRECT_DEBIT_TYPE_LABEL);
            }
        }
    }
    
    /*************************************************************************************** 
    Developer   Sally ElGhoul (Accenture)
    Date        14/10/2015
    Function    this function is called to handle the logic needed to link payments to payment methods
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    @Future(callout=true)
    public static void fillSFPaytmentMethodId(list<string> lstZuoraPaymentIds,set<id> setSFPaymentIds){
    	    	
    	set<string> setZPaymentMethodId=new set<string>(); //contains the Payment Method Ids in Zuora
    	map<string,string> mapZuoraPaymentIdZuoraPaymentMethodId=new map<string,string>(); //map for Payment Ids in Zuora and Payment Method Ids in Zuora
    	map<string,id> mapZuoraPaymentMethodIdSFPaymentMethodID=new map<string,id>(); //map for Payment Merthod Ids in Zuora and Payment Method Ids in Salesforce
    	
    	//Zuora.zApi api = new Zuora.zApi();
    	Zuora.zApi api = new Zuora.zApi();
    	
    	//login to the api using the user configured in "Zuora API Login Setup" 
		if ( !Test.isRunningTest() ) {api.zlogin();}
    	
    	//Payment records pulled from zuora
    	list<Zuora.zObject> lstZuoraPayments=Zuora_Utility.getZuoraPaymentRecords(api,lstZuoraPaymentIds);
    	
    	//loop on zuora payment records to get the zuora payment methods ids
    	for(Zuora.zObject zPaymentObj : lstZuoraPayments){
    		if(!setZPaymentMethodId.contains(string.valueof(zPaymentObj.getValue('PaymentMethodId')))){
    			//set of payment method Ids in Zuora
    			setZPaymentMethodId.add(string.valueof(zPaymentObj.getValue('PaymentMethodId')));
    		}
    		
    		if(!mapZuoraPaymentIdZuoraPaymentMethodId.containsKey(string.valueof(zPaymentObj.getValue('Id')))){
    			//fill the map between payment Ids in Zuora and payment Method Ids in Zuora
    			mapZuoraPaymentIdZuoraPaymentMethodId.put(string.valueof(zPaymentObj.getValue('Id')),string.valueof(zPaymentObj.getValue('PaymentMethodId')));
    		}
    	}	
    	
    	//query sf to get the payment method records using zuora ids of payment methods
    	if(setZPaymentMethodId!=null || setZPaymentMethodId.size()>0){
		    	
		    	//list of salesforce payment method records, query using the payment method ids in zuora
		    	list<Zuora__PaymentMethod__c> lstSFPaymentMethod=[select id,Zuora__External_Id__c from Zuora__PaymentMethod__c where Zuora__External_Id__c in :setZPaymentMethodId];
		    	
		    	for(Zuora__PaymentMethod__c sfPaymentMethodObj : lstSFPaymentMethod){
		    		if(!mapZuoraPaymentMethodIdSFPaymentMethodID.containskey(sfPaymentMethodObj.Zuora__External_Id__c)){
		    			//fill the map between payment method Ids in Zuora and payment method Ids in Salesforce
		    			mapZuoraPaymentMethodIdSFPaymentMethodID.put(sfPaymentMethodObj.Zuora__External_Id__c,sfPaymentMethodObj.id);
		    		}
		    	}
		    	
		    	//update zuora payment record to link the payment to the coresspoding sf payment method
		    	list<Zuora__Payment__c> lstSFPayments=[select id,Zuora__EXT_ID__c, Payment_Method__c from Zuora__Payment__c where id=:setSFPaymentIds];
		    	
		    	if(lstSFPayments!=null && lstSFPayments.size()>0){
		    		for(Zuora__Payment__c sfPaymentObj: lstSFPayments){
		    			
		    			//get the Zuora payment method ID used for this payment
		    			string zuoraPaymentMethodId=mapZuoraPaymentIdZuoraPaymentMethodId.get(sfPaymentObj.Zuora__EXT_ID__c);
		    			
		    			//get the SF payment method id using its zuora ID
		    			string sfPaymentMethodId=mapZuoraPaymentMethodIdSFPaymentMethodID.get(zuoraPaymentMethodId);
		    			
		    			//update the payment record to link it to its corresponding payment method id
		    			sfPaymentObj.Payment_Method__c=sfPaymentMethodId;
		    			
		    			//the above linking logic won't work because the payment method record is not yet created so we will link it using the following technique
		    			//we left this just in case Zuora change the order of creation for the records
		    			//1. Update the field ZuoraPaymentMethodId on the payment record
		    			//2. when zuora created the payment method record a trigger handler on after insert will be fired to 
		    			//3. query the payment records using ZuoraPaymentMethodId match the payment method zuora id
		    			//4. update the field Payment_Method__c for the payment record and update the record
		    			sfPaymentObj.ZuoraPaymentMethodId__c=zuoraPaymentMethodId;
		    			
		    		}
		    		if(lstSFPayments!=null && lstSFPayments.size()>0){
		    			update lstSFPayments;
		    		}
    			}
    	} else{
    		throw new TMGUtil.GenericException('Error Payment Method Ids in Zuora is empty....Method: fillSFPaytmentMethodId , class ZPaymentTriggerHandler');
    	}
    }
}