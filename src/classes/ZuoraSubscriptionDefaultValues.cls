/**
* Author:       Sally ElGhoul (Tquila)
* Date:         20/04/2015
* Description:  Using this class to provide default values for the z-quote new subscription wizard
*
* ******************* Change Log *******************
* Modified by       Change Date
* Michal Kwika      06/01/2016   
* Wiktor Czykin		14/03/2016	//added validation for active subscriptions, record type. Added setting of default date based on print sub cancellation 
* Lynette Lim       27-04-2016   Modified populateDefaultFieldValue() to allow agents to sell digital subscriptions to Customer with existing in-renewal print subscription
* Wiktor Czykin		22-03-2017  Modified populateDefaultFieldValue()
* Vishant Shah		11/08/2017	//added subscription origin.
**/
global class ZuoraSubscriptionDefaultValues extends zqu.CreateQuoteController.PopulateDefaultFieldValuePlugin {

	/*************************************************************************************** 
	Developer   Sally ElGhoul (Tquila)
	Date        12/12/2014
	Function    Set the default values
	******************* Change Log *******************
	Modified by         Change Date
	Michal Kwika        06/01/2016
	Wiktor Czykin		09/03/2016	//added validation and default date changes
	Wiktor Czykin		22/03/2017  //modified so that it does not blow up for subs in the past
	Vishant Shah		11/08/2017	//added subscription origin.
	****************************************************************************************/
	global override void populateDefaultFieldValue (SObject record, zqu.PropertyComponentController.ParentController pcc){ 
		
		if(!Test.isRunningTest()){super.populateDefaultFieldValue(record, pcc);}
			
		/*
		We added this logic because moving from step 3 in the quote wizard to step 2 was throwing an exception that 'SObject row was retrieved via SOQL without querying the requested field: zqu__Quote__c.zqu__SubscriptionType__c'
		so if the quote is created we will query the field (moving from step 3 to 2)
		moving from step 1 to 2 and the quote is not created use the value in the record directly
		*/
		String subscriptionTypeValue='';
		Date dActivationDate = Date.today();

		// Retrieve the account ID from the quote         
		Id accountId = (Id) record.get(Constants.ACCOUNT_FIELD);
		List<Account> lstAccounts = [select Id, Subscriber_Number__c, Subscriber_Digital_Status__c, Subscription_Status__c, RecordTypeId from Account where Id = :accountId];

		Id registrantRecordTypeId = RecordTypeUtility.getRecordTypeId(Account.SObjectType, Constants.ACCOUNT_REGISTRANT_RECORD_TYPE_NAME, Account.class.getName());
		if(lstAccounts[0].RecordTypeId != registrantRecordTypeId){
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Warning, Label.Quote_Flow_Non_registrant_account_error));
		}


		String sStatus = AccountUtility.hasAccountActiveSub(lstAccounts[0]);
		if (String.isBlank(sStatus) || sStatus == AccountUtility.STATUS_ACTIVE) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Warning, Label.Quote_Flow_Active_subscription_error));
        }else if(sStatus == AccountUtility.STATUS_PENDINGCANCELLATION_CONDITIONAL){
        	Date dCancellationSubscription = AccountUtility.isPendingCancellationConversion(lstAccounts[0].Id);
            if(dCancellationSubscription != null){
	            dActivationDate = dCancellationSubscription.addDays(1);
	        }
        }else if(sStatus == AccountUtility.STATUS_INRENEWAL_CONDITIONAL){
        	Date dInRenewalSubscription = AccountUtility.isInRenewalConversion(lstAccounts[0].Id);
            if(dInRenewalSubscription != null){
            	dActivationDate = dInRenewalSubscription.addDays(1);
        	}
        }
		
		if(record.get(Constants.ID_QUOTE_FIELD) != null){
			List<zqu__Quote__c> lstQuote = [select zqu__SubscriptionType__c, zqu__Service_Activation_Date__c from zqu__Quote__c where Id = :String.valueOf(record.get(Constants.ID_QUOTE_FIELD))];

			if(!lstQuote.isEmpty()){
				subscriptionTypeValue = lstQuote[0].zqu__SubscriptionType__c;
				if(lstQuote[0].zqu__Service_Activation_Date__c != null && lstQuote[0].zqu__Service_Activation_Date__c > dActivationDate){
					dActivationDate = lstQuote[0].zqu__Service_Activation_Date__c;
				}
			}
		} else {
			subscriptionTypeValue = String.valueOf(record.get(Constants.QUOTE_SUBSCRIPTION_TYPE_FIELD));
		}
		//populate the payment method in case of new subscription only
		if(!String.isEmpty(subscriptionTypeValue) && subscriptionTypeValue == Constants.QUOTE_SUBSCRIPTION_TYPE_NEW_VALUE){
			record.put(Constants.PAYMENT_METHOD_FIELD,Constants.CREDIT_CARD_PAYMENT_METHOD);	    //Payment Method
		}

		//Populate default values in the quote header   
		record.put(Constants.VALID_UNTI_DATE_FIELD, Date.today());   			//Valid Until Date
		record.put(Constants.START_DATE_FIELD, Date.today());					//Start Date	     				  				 
		record.put(Constants.INITIAL_TERM_FIELD, Constants.INITIAL_TERM_VALUE_DEFAULT);            //Initial Term  
		record.put(Constants.RENEWAL_TERM_FIELD, Constants.RENEWAL_TERM_VALUE_DEFAULT);            //Renewal Term	 
		record.put(Constants.ACQUISITION_CHANNEL_FIELD, Constants.ACQUISITION_CHANNEL_CALL_CENTER_VALUE); //Acquisition channel should be call center
		record.put(Constants.QUOTE_PAYMENT_GATEWAY_FIELD,''); //clear the payment gateway on the quote , to enable the change of gateway and adding new payment method
		record.put(Constants.SERVICE_ACTIVATION_DATE_FIELD, dActivationDate); //set Service Activation date to Today's date by default
		
		if (ApexPages.currentPage().getParameters().containsKey('origin') ){
            String origin = ApexPages.currentPage().getParameters().get('origin'); 
            record.put(Constants.QUOTE_SUBSCRIPTION_ORIGIN, origin); //set subscription origin.
            system.debug('setting origin complete ' + origin);
        }

		//Set the quote name to be "subscription number(Value)"+" Quote"
		record.put(Constants.QUOTE_NAME_FIELD, String.format(Constants.QUOTE_NAME_FORMAT, new List<String>{lstAccounts[0].Subscriber_Number__c})) ;
			
		//Check if the subscrition type is amendment , we need to default the field 'Quote Amendment Name'
		if(!String.isEmpty(subscriptionTypeValue) && subscriptionTypeValue == Constants.QUOTE_SUBSCRIPTION_TYPE_AMEND_VALUE){
			record.put(Constants.QUOTE_AMENDMENT_NAME_FIELD, String.format(Constants.QUOTE_AMENDMENT_NAME_FORMAT, new List<String>{String.valueOf(record.get(Constants.QUOTE_NAME_FIELD))})); //Quote Amendment Name field
			record.put(Constants.QUOTE_PAYMENT_DETAILS_ENTERED_FIELD,true); //mark that the payment details are already entered in case of amendment quote because it is not mandatory that they enter their payment details again

			//fill the fields "Default Payment Method Type" and "Default Payment Details"
			List<Zuora__PaymentMethod__c> lstPayementMethods = [select Zuora__Type__c,Zuora__BankTransferAccountNumber__c, Zuora__CreditCardMaskNumber__c from Zuora__PaymentMethod__c where Zuora__DefaultPaymentMethod__c=true and Zuora__PaymentMethodStatus__c='Active' and Zuora__BillingAccount__c in (select id from Zuora__CustomerAccount__c where Zuora__Account__c=:accountId and Zuora__Status__c='Active')];
			if(!lstPayementMethods.isEmpty()){
				if(lstPayementMethods[0].Zuora__Type__c == Constants.PAYMENT_METHOD_CREDIT_CARD_TYPE){//payment is credit card
					record.put(Constants.PAYMENT_METHOD_PAYMENT_TYPE_FIELD, Constants.PAYMENT_METHOD_CREDIT_CARD_TYPE_LABEL);
					record.put(Constants.PAYMENT_METHOD_PAYMENT_DETAILS_FIELD, lstPayementMethods[0].Zuora__CreditCardMaskNumber__c);
				}else if(lstPayementMethods[0].Zuora__Type__c == Constants.PAYMENT_METHOD_DIRECT_DEBIT_TYPE){//payment is bank tranfer "direct debit"
					record.put(Constants.PAYMENT_METHOD_PAYMENT_TYPE_FIELD, Constants.PAYMENT_METHOD_DIRECT_DEBIT_TYPE_LABEL);
					record.put(Constants.PAYMENT_METHOD_PAYMENT_DETAILS_FIELD, lstPayementMethods[0].Zuora__BankTransferAccountNumber__c);	
				}
			}
					
			//default the value of master quote text field and lookup to relate this quote to the first original quote quote 
			if(ApexPages.currentPage().getParameters().containsKey('subscriptionId')){
				//1. get the subscription record and get the master quote to query 
				List< Zuora__Subscription__c > lstZuoraSubscriptions = [select Id, Related_Quote__c, Master_Quote__c, Zuora__NextChargeDate__c from Zuora__Subscription__c where Zuora__Zuora_Id__c =:ApexPages.currentPage().getParameters().get('subscriptionId')];    
				Id previousQuoteId;
					 
				//2. if the list of subscription is not empty and a subsciption is found we need to fill the master quote id field and lookup
				if(!lstZuoraSubscriptions.isEmpty()){
					//set the new amendment quote master field from the subscription master quote field
					record.put(Constants.QUOTE_MASTER_QUOTE_FIELD, lstZuoraSubscriptions[0].Master_Quote__c);
					
					//set the new amendment quote previous quote field from the subscription related quote field because it is still points to the previous quote
					//the subscription related quote filed will be update after sending the amendment quote to zbilling
					record.put(Constants.QUOTE_PREVIOUS_QUOTE_FIELD,lstZuoraSubscriptions[0].Related_Quote__c);
					previousQuoteId=lstZuoraSubscriptions[0].Related_Quote__c;
					
					//fill the qute QUOTE_SUBSCRIPTION_NEXT_CHARGE_DATE_FIELD with the value of the subscription
					if(lstZuoraSubscriptions[0].Zuora__NextChargeDate__c != null){
						record.put(Constants.QUOTE_SUBSCRIPTION_NEXT_CHARGE_DATE_FIELD,lstZuoraSubscriptions[0].Zuora__NextChargeDate__c);
					}  
				}
						
				//3. fill the amendment quote Subscription_Term_Type__c field to be defaulted as the previous quote
				if(previousQuoteId!=null){
					list<zqu__Quote__c> lstRelatedQuote = [select Subscription_Rate_Plan_Term_Type__c from zqu__Quote__c where Id = :previousQuoteId];
					if(lstRelatedQuote!=null && lstRelatedQuote.size()>0){
						//fill the Subscription_Term_Type__c
						if(!string.isempty(lstRelatedQuote[0].Subscription_Rate_Plan_Term_Type__c)){
							record.put(Constants.QUOTE_SUBSCRIPTION_TERM_TYPE_FIELD,lstRelatedQuote[0].Subscription_Rate_Plan_Term_Type__c);
							//this field is used to keep track the subscription term type before amendment
							record.put(Constants.QUOTE_SUBSCRIPTION_TERM_TYPE_BEFORE_AMENDMENT_FIELD,lstRelatedQuote[0].Subscription_Rate_Plan_Term_Type__c);
						}
					}
				}
			}
			//default the offer code value to be the same as the master quote 
		}
			 
		// Find the contacts associated with the account         
		List<Contact> lstContacts = [SELECT Id, Name FROM Contact WHERE Account.Id = :accountId];         
		
		// Assuming the contacts are present set the billTo and soldTo to the first contact         
		if(lstContacts.size() > 0) {             
			// System.debug('mp: about to add ' + contacts[0].Id + ' as a contact ID');             
			record.put(Constants.BILL_TO_CONTACT_FIELD, lstContacts[0].Id);             
			record.put(Constants.SOLD_TO_CONTACT_FIELD, lstContacts[0].Id);             
		
			// Before retrieving  the lookup  options, needs to populate the map first             
			if(!Test.isRunningTest()){
				super.setLookupOptions(pcc);             
		
				 // Now retrieve the lookup component options             
				zqu.LookupComponentOptions billToOptions = super.getLookupOption(Constants.BILL_TO_CONTACT_FIELD);             
				billToOptions.targetId = lstContacts[0].Id;             
				billToOptions.targetName = lstContacts[0].Name;             
				zqu.LookupComponentOptions soldToOptions  = super.getLookupOption(Constants.SOLD_TO_CONTACT_FIELD);             
				soldToOptions.targetId = lstContacts[0].Id;             
				soldToOptions.targetName = lstContacts[0].Name;  
			}     
		}
	}

}