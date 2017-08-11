/**
* Author:       Sally ElGhoul (Accenture)
* Date:         06/01/2016
* Description:  this class is a utility class for Getting the billing details preview from zuora
*
* ******************* Change Log *******************
* Modified by       Change Date     
Sally ElGhoul		12/02/2016 update the preview using subscription to select the fixed price discount rate plan
Sally ElGhoul		15/02/2016 Passing to billing preview the service activation date instead of subscription Start date    
Sally ElGhoul		25/02/2016 add a function to convert billing details from zuora to Zuora_BillingPreviewInvoiceItems List 
Michal Szewczyk		04/03/2016 added createSubsDiscretionaryDiscount()
Pawel Chrzanowski	11/05/2016 modified getRatePlanData() to supply zqu__EffectivePrice__c to every RatePlan
Mantas Grigaliunas	02/11/2016 amendmentDate change in createSubsDiscretionaryDiscount()
Mantas Grigaliunas	30/06/2017 refund discount name change in createSubsDiscretionaryDiscount()
**/
public class Zuora_BillingPreviewUtility {
	
	//////////////////////////////////////////////////////////////////////////////////////////////
 	////////////////// New subscription section //////////////////////////////////////////////////
 	//////////////////////////////////////////////////////////////////////////////////////////////
 	
	/*************************************************************************************** 
    Developer   Sally ElGhoul (Accenture)
    Date        06/01/2016
    Function    this function is called to get the billing preview details of new subscription
    ******************* Change Log *******************
    Modified by         Version     Change Date
    Sally ElGhoul		1.1			15/2/2016 set the contract effective date value to be the service activation date instead of the start date if the service activation date is not null
    ****************************************************************************************/
	public static list<Zuora.zObject> previewNewSubBillingDetails(Zuora.zApi zApiInstance,zqu__Quote__c quoteObj){
		// zApiInstance should be instantiated and the login() method must
		// have been invoked prior to invoking any other method on the
		// object
		try {
			
			Zuora.zObject zuoraAccount;
			Zuora.zObject billToContact;
			
			//account and bill to contact
			if(quoteObj.zqu__Account__c!=null){
				list<account> lstAccount=[select id,firstName,lastName,personHomePhone,personMobilePhone,personMailingPostalcode,personMailingStreet,personMailingCity,personMailingCountry,personMailingState from account where id=:quoteObj.zqu__Account__c];
				if(lstAccount!=null && lstAccount.size()>0){
					zuoraAccount = Zuora_Utility.CreateZuoraAccountInstance(lstAccount[0]);
					
					//bill to contact
					billToContact = Zuora_Utility.CreateZuoraContactInstance(lstAccount[0]);
				}
			}
			
			
			//get the rate plan Data for this new subsctiption
			list<Zuora.zObject> lstRatePlanData=getRatePlanData(quoteObj);
			
			//subscription
			Zuora.zObject zuoraSubscriptionObj = new Zuora.zObject('Subscription');
			zuoraSubscriptionObj.setValue('Name', 'subscription - SubscriptionName'); //dummy name
			
			//contract effective date, same value as the quote start date if the service activation is empty
			datetime contractEffectiveDateTime=datetime.newInstance(quoteObj.zqu__StartDate__c.year(),quoteObj.zqu__StartDate__c.month(),quoteObj.zqu__StartDate__c.day());
	 		
			//customer acceptance date and service activation date values
			if(quoteObj.zqu__Service_Activation_Date__c!=null){
 				datetime serviceActivationDateTime=datetime.newInstance(quoteObj.zqu__Service_Activation_Date__c.year(),quoteObj.zqu__Service_Activation_Date__c.month(),quoteObj.zqu__Service_Activation_Date__c.day());
 				zuoraSubscriptionObj.setValue('ServiceActivationDate', serviceActivationDateTime.format('YYYY-MM-dd'));
				
				//will be use to se the contract effective date to be the service activation date
				contractEffectiveDateTime=serviceActivationDateTime;
			}else{
 				zuoraSubscriptionObj.setValue('ServiceActivationDate', contractEffectiveDateTime.format('YYYY-MM-dd'));
			}
			
			//set the contract effective date value it will be the quote start date if service activation is null otherwise it will be the service activation value
			zuoraSubscriptionObj.setValue('ContractEffectiveDate', contractEffectiveDateTime.format('YYYY-MM-dd'));
			    
		   if(quoteObj.zqu__Customer_Acceptance_Date__c!=null){
			    datetime customerAcceptanceDateTime=datetime.newInstance(quoteObj.zqu__Customer_Acceptance_Date__c.year(),quoteObj.zqu__Customer_Acceptance_Date__c.month(),quoteObj.zqu__Customer_Acceptance_Date__c.day());
 				zuoraSubscriptionObj.setValue('ContractAcceptanceDate', customerAcceptanceDateTime.format('YYYY-MM-dd'));
		   }else{
			    zuoraSubscriptionObj.setValue('ContractAcceptanceDate', contractEffectiveDateTime.format('YYYY-MM-dd'));
		   	}
		   	
			//initial term and renewal term
			zuoraSubscriptionObj.setValue('InitialTerm', constants.INITIAL_TERM_VALUE_DEFAULT);
			zuoraSubscriptionObj.setValue('RenewalTerm', constants.RENEWAL_TERM_VALUE_DEFAULT);
			
			//subscription data
			Zuora.zApi.SubscriptionData subscriptionDataObj = new Zuora.zApi.SubscriptionData();
			subscriptionDataObj.Subscription = zuoraSubscriptionObj;
			subscriptionDataObj.RatePlanData = lstRatePlanData;
			
			//subscribe request
			Zuora.zApi.SubscribeRequest subscribeRequestObj = new Zuora.zApi.SubscribeRequest();
			subscribeRequestObj.ZAccount = zuoraAccount;
			subscribeRequestObj.BillToContact = billToContact;
			subscribeRequestObj.SubscriptionData = subscriptionDataObj;
			subscribeRequestObj.PreviewOptions = getPreviewOptions();
			
			//the subscription request list
			List<Zuora.zApi.SubscribeRequest> subsRequestLists = new List<Zuora.zApi.SubscribeRequest>{subscribeRequestObj};
			
			if(!Test.isRunningTest()){
				//call the zsubscribe function
				List<Zuora.zApi.SubscribeResult> subscribeResults = zApiInstance.zsubscribe(subsRequestLists);
			
				//check the zsubscribe results
				for (Zuora.zApi.SubscribeResult result : subscribeResults) {
					
					system.debug('check result: '+result);
					//if successfull check that the invoice data is not empty and return it
					if (result.Success) {
						system.debug('check result.InvoiceDatas: '+result.InvoiceDatas);
						if (result.InvoiceDatas != null) {
					  		return result.InvoiceDatas;
					  	}
					} else {
						//failure
						//get the errors
						Zuora.zObject[] errors = result.errors;
						string ErrorMessage='';
						system.debug('Zsubcsribe errors: '+errors);
						for (Zuora.zObject error : errors) {
							String errorCode = (String)error.getValue('Code');
							String message = (String)error.getValue('Message');
							ErrorMessage+=' '+errorCode+':'+message+';';
						}
						throw new TMGUtil.GenericException(ErrorMessage);
					}
				}
			}else{
				list<Zuora.zObject> lstinvoiceDatasValues=new list<Zuora.zObject>();
				
				Zuora.ZObject invoiceDatasValue=new Zuora.zObject('InvoiceData');	
				list<Zuora.zObject> lstInvoices=new list<Zuora.zObject>();
				
				Zuora.zObject invoiceItem1=new Zuora.zObject('InvoiceItem');	
				invoiceItem1.setValue('ChargeAmount',9.5);
				invoiceItem1.setValue('TaxAmount',0.5);
				invoiceItem1.setValue('ServiceStartDate',Date.today());
				lstInvoices.add(invoiceItem1);
				
				Zuora.zObject invoiceItemDiscount=new Zuora.zObject('InvoiceItem');	
				invoiceItemDiscount.setValue('ChargeAmount',-0.5);
				invoiceItemDiscount.setValue('TaxAmount',-0.5);
				invoiceItemDiscount.setValue('ServiceStartDate',Date.today());
				lstInvoices.add(invoiceItemDiscount);
				
				invoiceDatasValue.setValue('InvoiceItem',lstInvoices);
				
				//invoice
				zuora.zobject invoiceObj=new zuora.zobject('Invoice');
				invoiceDatasValue.setValue('Invoice',invoiceObj);
				
				lstinvoiceDatasValues.add(invoiceDatasValue);
				return lstinvoiceDatasValues;
			}
		}catch(exception ex){throw new TMGUtil.GenericException(Label.New_Digital_Platform_Generic_Error_Message); system.debug('check exception  previewNewSubBillingDetails: '+ex.getMessage());}
		
		return null;
	}
	
	/*************************************************************************************** 
    Developer   Sally ElGhoul (Accenture)
    Date        06/01/2016
    Function    this function is called to rate plan data for the new subscription
    ******************* Change Log *******************
    Modified by         Version     Change Date
    Pawel Chrzanowski	1.1			11/05/2016 	modified to supply zqu__EffectivePrice__c to every RatePlan
    ****************************************************************************************/
	public static list<Zuora.zObject> getRatePlanData(zqu__Quote__c quoteObj){
 		list<Zuora.zObject> lstRatePlandata=new list<Zuora.zObject>();
 		
 		//get the quote Rate Plans and quote rate plan charges
 		list<zqu__QuoteRatePlan__c> lstQuoteRatePlans=ZuoraQuote_Utility.getQuoteAllRatePlans(quoteObj.id);
 		map<id,list<zqu__QuoteRatePlanCharge__c>> mapQuoteRatePlanCharges=ZuoraQuote_Utility.getQuoteRatePlanCharges(lstQuoteRatePlans);
 		
 		if(lstQuoteRatePlans!=null && lstQuoteRatePlans.size()>0){
 			for(zqu__QuoteRatePlan__c quoteRatePlanObj : lstQuoteRatePlans){
 				
 				//Rate Plan Object
 				Zuora.zObject ratePlanObj = new Zuora.zObject('RatePlan');
				ratePlanObj.setValue('ProductRatePlanId', quoteRatePlanObj.zqu__ProductRatePlanZuoraId__c);	
				
				//reate Plan Data Object 
				Zuora.zObject ratePlanDataObj = new Zuora.zObject('RatePlanData');
				ratePlanDataObj.setValue('RatePlan', ratePlanObj);
				
				list<zqu__QuoteRatePlanCharge__c> lstQuoteRatePlanCharges=mapQuoteRatePlanCharges.get(quoteRatePlanObj.id);
				
				if(lstQuoteRatePlanCharges!=null && lstQuoteRatePlanCharges.size()>0){
					for(zqu__QuoteRatePlanCharge__c quoteRatePlanChargeObj : lstQuoteRatePlanCharges){
						
						//rate plan charge object
						Zuora.zObject ratePlanChargeObj = new Zuora.zObject('RatePlanCharge');
						ratePlanChargeObj.setValue('ProductRatePlanChargeId', quoteRatePlanChargeObj.zqu__ProductRatePlanChargeZuoraId__c);
						ratePlanChargeObj.setValue('Price',quoteRatePlanChargeObj.zqu__EffectivePrice__c);
						
						if(quoteRatePlanChargeObj.name==constants.DISCOUNT_RATE_PLAN_NAME){
							ratePlanChargeObj.setValue('BillingPeriod',quoteRatePlanChargeObj.zqu__Period__c);
							ratePlanChargeObj.setValue('UpToPeriodsType','Billing Periods');
							ratePlanChargeObj.setValue('UpToPeriods',quoteRatePlanChargeObj.zqu__Upto_How_Many_Periods__c);
							ratePlanChargeObj.setValue('EndDateCondition','FixedPeriod');
						}
		
						//rate plan charge data object
						Zuora.zObject ratePlanChargeDataObj = new Zuora.zObject('RatePlanChargeData');
						ratePlanChargeDataObj.setValue('RatePlanCharge', ratePlanChargeObj);
						
						//add the rate plan charge data to the rate plan data
						ratePlanDataObj.setValue('RatePlanChargeData', new List<Zuora.zObject>{ratePlanChargeDataObj});
					}
				}
				lstRatePlandata.add(ratePlanDataObj);
 			}
 		}
 		return lstRatePlandata;
 	}
 	
 	//////////////////////////////////////////////////////////////////////////////////////////////
 	//////////////////End New subscription section //////////////////////////////////////////////
 	//////////////////////////////////////////////////////////////////////////////////////////////
	
	//////////////////////////////////////////////////////////////////////////////////////////////
 	//////////////////Amendment  section /////////////////////////////////////////////////////////
 	//////////////////////////////////////////////////////////////////////////////////////////////
 	
	/*************************************************************************************** 
    Developer   Sally ElGhoul (Accenture)
    Date        06/01/2016
    Function    this function is called to get the billing preview details of Amendments
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
	public static list<Zuora.zObject> previewAmendmentBillingDetails(Zuora.zApi zApiInstance,zqu__Quote__c quoteObj){
		try{
 			
 			//the amendment request
	 		Zuora.zApi.AmendRequest amendRequest = new Zuora.zApi.AmendRequest();
		    
		    //get the subscription amendment for the new quote and assign it to the amendment request
		    list<Zuora.zObject> lstAmendments = getSubscriptionAmendments(quoteObj);
		   	
		   	//this error is thrown as agreed with Jayant on 8 January 2016. because no amendments are added yet to show the billing preview
		   	//the ideal in this case is to call the subscription billing preview but at this point this is not developed yet and we agreed it may not be needed at all.
		   	if(lstAmendments==null || lstAmendments.size()==0){throw new TMGUtil.GenericException(Label.Billing_Preview_No_Amendments_Error_Message);}
		   	amendRequest.amendments = lstAmendments;
			
			//Preview options
			amendRequest.PreviewOptions = getPreviewOptions();
	 		
	 		if(!Test.isRunningTest()){
		 		//call the zuora zamend function
		 		Zuora.zApi.AmendResult result = zApiInstance.zamend(new List < Zuora.zApi.AmendRequest > {amendRequest});
		 		return handleAmendmentResults(result);
		 	}else{
				list<Zuora.zObject> lstinvoiceDatasValues=new list<Zuora.zObject>();
				
				Zuora.ZObject invoiceDatasValue=new Zuora.zObject('InvoiceData');	
				list<Zuora.zObject> lstInvoices=new list<Zuora.zObject>();
				
				Zuora.zObject invoiceItem1=new Zuora.zObject('InvoiceItem');	
				invoiceItem1.setValue('ChargeAmount',9.5);
				invoiceItem1.setValue('TaxAmount',0.5);
				invoiceItem1.setValue('ServiceStartDate',Date.today());
				lstInvoices.add(invoiceItem1);
				
				invoiceDatasValue.setValue('InvoiceItem',lstInvoices);
				
				//invoice
				zuora.zobject invoiceObj=new zuora.zobject('Invoice');
				invoiceDatasValue.setValue('Invoice',invoiceObj);
				
				lstinvoiceDatasValues.add(invoiceDatasValue);
				return lstinvoiceDatasValues;
			}
 		}catch(TMGUtil.GenericException genericExceptionObj){throw new TMGUtil.GenericException(genericExceptionObj.getMessage()); }catch(exception ex){throw new TMGUtil.GenericException(Label.New_Digital_Platform_Generic_Error_Message); system.debug('check exception  previewAmendmentBillingDetails: '+ex.getMessage());}
 		
 		return null;
	}
	
	/*************************************************************************************** 
    Developer   Sally ElGhoul (Accenture)
    Date        06/01/2016
    Function    this function is called to get the subscription amendments in this new quote
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
	public static list<Zuora.zobject> getSubscriptionAmendments(zqu__Quote__c quoteObj){
 		
 		list<Zuora.zObject> lstAmendments=new list<Zuora.zObject>();
 		string subscriptionZuoraId='';
 		
 		//get the subscription ID that we are amending
 		list<Zuora__Subscription__c> lstSubscription=[select id, Zuora__Zuora_Id__c from Zuora__Subscription__c 
 															where Zuora__Account__c=:quoteObj.zqu__Account__c
 																	and Zuora__Status__c='Active' limit 1];
 		if(lstSubscription!=null && lstSubscription.size()>0){
 			subscriptionZuoraId=lstSubscription[0].Zuora__Zuora_Id__c;
 		}
 		
 		//get the quote amendments
 		list<zqu__QuoteAmendment__c> lstQuoteAmendments=ZuoraQuote_Utility.getQuoteAllAmendments(quoteObj.id);
 		
 		if(lstQuoteAmendments!=null){
 			
 			//get the quote amendments rate plan and amendment rate plan charges
 			map<id,list<zqu__QuoteRatePlan__c>> mapQuoteAmendmentRatePlans=ZuoraQuote_Utility.getQuoteAmendmentRatePlans(lstQuoteAmendments);
 			list<zqu__QuoteRatePlan__c> allQuoteAmendmentRatePlans=new list<zqu__QuoteRatePlan__c>();
 			if(mapQuoteAmendmentRatePlans!=null && mapQuoteAmendmentRatePlans.size()>0){
 				for(Id quoteAmendmentId :mapQuoteAmendmentRatePlans.keyset()){
 					allQuoteAmendmentRatePlans.addAll(mapQuoteAmendmentRatePlans.get(quoteAmendmentId));
 				}
 			}
 			map<id,list<zqu__QuoteRatePlanCharge__c>> mapQuoteAmendmentRatePlanCharges = ZuoraQuote_Utility.getQuoteAmendmentRatePlanCharges(allQuoteAmendmentRatePlans); 			
 			
 			//create zuora amendments to the list
 			for(zqu__QuoteAmendment__c quoteAmendObj : lstQuoteAmendments){
 				
 				//create the amendment zuora object
 				Zuora.zObject amendmentObj = new Zuora.zObject('Amendment');
 				
 				datetime amendmentDateTime=datetime.newInstance(quoteObj.zqu__StartDate__c.year(),quoteObj.zqu__StartDate__c.month(),quoteObj.zqu__StartDate__c.day());
 				
 				if(quoteObj.zqu__Service_Activation_Date__c!=null){
 					datetime serviceActivationDateTime=datetime.newInstance(quoteObj.zqu__Service_Activation_Date__c.year(),quoteObj.zqu__Service_Activation_Date__c.month(),quoteObj.zqu__Service_Activation_Date__c.day());
 					amendmentObj.setValue('EffectiveDate', serviceActivationDateTime.format('YYYY-MM-dd'));
 					amendmentObj.setValue('ServiceActivationDate', serviceActivationDateTime.format('YYYY-MM-dd'));
			    
 				}else{
 					amendmentObj.setValue('EffectiveDate', amendmentDateTime.format('YYYY-MM-dd'));
 					amendmentObj.setValue('ServiceActivationDate', amendmentDateTime.format('YYYY-MM-dd'));
			    }
			    
			    if(quoteObj.zqu__Customer_Acceptance_Date__c!=null){
			    	datetime customerAcceptanceDateTime=datetime.newInstance(quoteObj.zqu__Customer_Acceptance_Date__c.year(),quoteObj.zqu__Customer_Acceptance_Date__c.month(),quoteObj.zqu__Customer_Acceptance_Date__c.day());
 					amendmentObj.setValue('CustomerAcceptanceDate', customerAcceptanceDateTime.format('YYYY-MM-dd'));
			    }else{
			    	amendmentObj.setValue('CustomerAcceptanceDate', amendmentDateTime.format('YYYY-MM-dd'));
			    }
 			
			    amendmentObj.setValue('ContractEffectiveDate', amendmentDateTime.format('YYYY-MM-dd'));
			    amendmentObj.setValue('Description', quoteAmendObj.zqu__Description__c );
			    amendmentObj.setValue('Name', quoteAmendObj.Name);
			    amendmentObj.setValue('Status', 'Completed');
			    amendmentObj.setValue('SubscriptionId', subscriptionZuoraId);
			    amendmentObj.setValue('Type', quoteAmendObj.zqu__Type__c);
			    
			    // Set the rateplan Data for the amendment
    			list<zqu__QuoteRatePlan__c> lstQuoteAmendRatePlans=mapQuoteAmendmentRatePlans.get(quoteAmendObj.id);
    			
    			//Rate Plan Object
    			Zuora.zObject ratePlan = new Zuora.zObject('RatePlan');
				ratePlan.setValue('ProductRatePlanId', lstQuoteAmendRatePlans[0].zqu__ProductRatePlanZuoraId__c);
				
				//create Plan Data Object 
    			Zuora.zObject ratePlanData = new Zuora.zObject('RatePlanData');
				ratePlanData.setValue('RatePlan', ratePlan);
			    
			    //the rate plan charges
			    list<zqu__QuoteRatePlanCharge__c> lstAllQuoteRatePlanCharges=mapQuoteAmendmentRatePlanCharges.get(lstQuoteAmendRatePlans[0].id);
			    List < Zuora.zObject > lstZuoraQuoteRatePlanCharges=new List < Zuora.zObject >();
			    for(zqu__QuoteRatePlanCharge__c quoteRatePlanChargeObj : lstAllQuoteRatePlanCharges){
			    	
			    	//rate plan charge object
			    	Zuora.zObject ratePlanCharge = new Zuora.zObject('RatePlanCharge');
				    ratePlanCharge.setValue('ProductRatePlanChargeId',quoteRatePlanChargeObj.zqu__ProductRatePlanChargeZuoraId__c);
				    
				    if(quoteRatePlanChargeObj.name==constants.DISCOUNT_RATE_PLAN_NAME){
						ratePlanCharge.setValue('BillingPeriod',quoteRatePlanChargeObj.zqu__Period__c);
						ratePlanCharge.setValue('UpToPeriodsType','Billing Periods');
						ratePlanCharge.setValue('UpToPeriods',quoteRatePlanChargeObj.zqu__Upto_How_Many_Periods__c);
						ratePlanCharge.setValue('EndDateCondition','FixedPeriod');
						ratePlanCharge.setValue('Price',quoteRatePlanChargeObj.zqu__EffectivePrice__c);
					}
				    
				    //rate plan charge data object
					Zuora.zObject ratePlanChargeDataObj = new Zuora.zObject('RatePlanChargeData');
					ratePlanChargeDataObj.setValue('RatePlanCharge', ratePlanCharge);
			    	lstZuoraQuoteRatePlanCharges.add(ratePlanChargeDataObj);
			    }
			    ratePlanData.setValue('RatePlanChargeData', lstZuoraQuoteRatePlanCharges);
			    
			    amendmentObj.setValue('RatePlanData', ratePlanData);
    			lstAmendments.add(amendmentObj);
 			}
 		}
 		
 		return lstAmendments;
 	}
	
	///////////////////////////////////////////////////////////////////////////////////////////////
 	//////////////////End Amendment  section //////////////////////////////////////////////////////
 	//////////////////////////////////////////////////////////////////////////////////////////////
 	
 	/////////////////////////////////////////////////////////////////////////////////////////////
 	/////////////////////////////////////////Billing Details using Subcription ID////////////////
 	/////////////////////////////////////////////////////////////////////////////////////////////
 	/*************************************************************************************** 
    Developer   Sally ElGhoul (Accenture)
    Date        06/01/2016
    Function    this function is called to get the billing preview details of a Subscription
    ******************* Change Log *******************
    Modified by         Version     Change Date
    Sally ElGhoul		1.1			12/2/2016 update the preview using subscription to select the fixed price discount rate plan
    Sally ElGhoul		1.2			15/2/2016 Passing to billing preview the service activation date instead of subscription Start date    
    ****************************************************************************************/
	public static list<Zuora.zObject> previewSubscriptionBillingDetails(Zuora.zApi zApiInstance,Zuora__Subscription__c subscriptionObj){
		try{
 			
 			//get the product rate plan id in zuora by looping on the subscription product and charge object and getting the product rate plan 
            //as on subscriptiopn a single product is allowed
            //get the subscription product charge
            list<Zuora__SubscriptionProductCharge__c> lstSubscriptionProductCharges=[select id,Zuora__Product__r.Zuora__External_Id__c from  Zuora__SubscriptionProductCharge__c where Zuora__Subscription__c=:subscriptionObj.id limit 1];
           	
           	if(lstSubscriptionProductCharges!=null && lstSubscriptionProductCharges.size()>0){
	           	//get the zprodudct record related to the subscription product charge
	           	list<zqu__ZProduct__c> lstzuoraProduct=[select id from zqu__ZProduct__c where zqu__ZuoraId__c=:lstSubscriptionProductCharges[0].Zuora__Product__r.Zuora__External_Id__c];
	           	
	           	if(lstzuoraProduct!=null && lstzuoraProduct.size()>0){
		           	//get the discount product rate plan for the product
		           	list<zqu__ProductRatePlan__c> lstProductDiscountRatePlan=[select id,zqu__ZuoraId__c from zqu__ProductRatePlan__c 
		           																where zqu__ZProduct__c=:lstzuoraProduct[0].id 
		           																	and name=:constants.EMPTY_DISCOUNT_RATE_PLAN_NAME 
		           																	and zqu__Deleted__c=false 
		           																	and zqu__EffectiveStartDate__c<=:Date.today()
		           																	and zqu__EffectiveEndDate__c>=:Date.today()];
		           																	
		            return previewSubscriptionBillingDetails(zApiInstance,subscriptionObj.Zuora__Zuora_Id__c,lstProductDiscountRatePlan[0].zqu__ZuoraId__c,subscriptionObj.Zuora__ServiceActivationDate__c);
	           	}
           	}
 		}catch(TMGUtil.GenericException genericExceptionObj){throw new TMGUtil.GenericException(genericExceptionObj.getMessage()); }catch(exception ex){throw new TMGUtil.GenericException(Label.New_Digital_Platform_Generic_Error_Message); system.debug('check exception  previewAmendmentBillingDetails: '+ex.getMessage());}
 		
 		return null;
	}
	
	/*************************************************************************************** 
    Developer   Sally ElGhoul (Accenture)
    Date        06/01/2016
    Function    this function is called to get the billing preview details of a Subscription
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
	public static list<Zuora.zObject> previewSubscriptionBillingDetails(Zuora.zApi zApiInstance,string zuoraSubscriptionID,string productRatePlanID,date subscriptionStartDate){
		try{
				
 			//the amendment request
	 		Zuora.zApi.AmendRequest amendRequest = new Zuora.zApi.AmendRequest();
		    
		    //get the subscription amendment for the new quote and assign it to the amendment request
		    list<Zuora.zObject> lstAmendments = new list<Zuora.zObject>();
		   	
		   	//create the amendment zuora object
            Zuora.zObject amendmentObj = new Zuora.zObject('Amendment');
            
		   	datetime amendmentDateTime=datetime.newInstance(subscriptionStartDate.year(),subscriptionStartDate.month(),subscriptionStartDate.day());
		   	amendmentObj.setValue('EffectiveDate', amendmentDateTime.format('YYYY-MM-dd'));
            amendmentObj.setValue('ServiceActivationDate', amendmentDateTime.format('YYYY-MM-dd'));
		   	amendmentObj.setValue('CustomerAcceptanceDate', amendmentDateTime.format('YYYY-MM-dd'));
		   	
		   	amendmentObj.setValue('ContractEffectiveDate', amendmentDateTime.format('YYYY-MM-dd'));
	        amendmentObj.setValue('Description', 'Empty Amendment' );
	        amendmentObj.setValue('Name', 'Empty Amendment');
	        amendmentObj.setValue('Status', 'Completed');
	        amendmentObj.setValue('SubscriptionId', zuoraSubscriptionID);
	        amendmentObj.setValue('Type', 'NewProduct');
            
            //Rate Plan Object
            Zuora.zObject ratePlan = new Zuora.zObject('RatePlan');
            ratePlan.setValue('ProductRatePlanId', productRatePlanID);
	        Zuora.zObject ratePlanData = new Zuora.zObject('RatePlanData');
            ratePlanData.setValue('RatePlan', ratePlan);
            amendmentObj.setValue('RatePlanData', ratePlanData);
            lstAmendments.add(amendmentObj);          
		   	amendRequest.amendments = lstAmendments;
			
			//Preview options
			amendRequest.PreviewOptions = getPreviewOptions();
	 		
	 		if(!Test.isRunningTest()){
		 		//call the zuora zamend function
		 		Zuora.zApi.AmendResult result = zApiInstance.zamend(new List < Zuora.zApi.AmendRequest > {amendRequest});
		 		return handleAmendmentResults(result);
			}else{
				list<Zuora.zObject> lstinvoiceDatasValues=new list<Zuora.zObject>();
				
				Zuora.ZObject invoiceDatasValue=new Zuora.zObject('InvoiceData');	
				list<Zuora.zObject> lstInvoices=new list<Zuora.zObject>();
				
				Zuora.zObject invoiceItem1=new Zuora.zObject('InvoiceItem');	
				invoiceItem1.setValue('ChargeAmount',9.5);
				invoiceItem1.setValue('TaxAmount',0.5);
				invoiceItem1.setValue('ServiceStartDate',Date.today());
				lstInvoices.add(invoiceItem1);
				
				invoiceDatasValue.setValue('InvoiceItem',lstInvoices);
				
				//invoice
				zuora.zobject invoiceObj=new zuora.zobject('Invoice');
				invoiceDatasValue.setValue('Invoice',invoiceObj);
				
				lstinvoiceDatasValues.add(invoiceDatasValue);
				return lstinvoiceDatasValues;
			}
 		}catch(TMGUtil.GenericException genericExceptionObj){throw new TMGUtil.GenericException(genericExceptionObj.getMessage()); }catch(exception ex){throw new TMGUtil.GenericException(Label.New_Digital_Platform_Generic_Error_Message); system.debug('check exception  previewAmendmentBillingDetails: '+ex.getMessage());}
 		
 		return null;	
	}
	
	/*************************************************************************************** 
    Developer   Michal Szewczyk
    Date        04/03/2016
    Function    this function is called to create amendment for Sub for Discretionary Discount
    ******************* Change Log *******************
    Modified by         Change Date
    Mantas Grigaliunas	02/11/2016 //changed amendmentDate to be set to serviceDate instead of today's date
    Mantas Grigaliunas	30/06/2017 refund discount name change after annual charge plan added
    ****************************************************************************************/
	public static String createSubsDiscretionaryDiscount(Zuora.zApi zApiInstance,string invoiceId,Decimal refundAmount){
		try{
			String refundInvoiceId ='';
			if (!Test.isRunningTest()){
				zApiInstance.zlogin();
			}
			String zuoraSubscriptionID = '';
			String zuoraProductId = '';
			Date   serviceDate;
			String subscriptionNumber;
 			//the amendment request
	 		Zuora.zApi.AmendRequest amendRequest = new Zuora.zApi.AmendRequest();
		    
		    //get the subscription amendment for the new quote and assign it to the amendment request
		    list<Zuora.zObject> lstAmendments = new list<Zuora.zObject>();
		   	
		    //fetch Invoice 
			List<Zuora.zObject> invoicesItems;

			String zoql = 'SELECT Id,ServiceStartDate,SubscriptionId,ProductId, SubscriptionNumber FROM InvoiceItem WHERE ChargeName != \'' + Constants.DISCOUNT_RATE_PLAN_NAME + '\' AND ChargeName !=\''+ Constants.EMPTY_DISCOUNT_RATE_PLAN_NAME + '\'  AND InvoiceId = \'' + invoiceId + '\'' ;
			invoicesItems = zApiInstance.zquery(zoql);
				
			for(Zuora.zObject tmpInvoiceItem: invoicesItems){
					
					zuoraSubscriptionID = String.valueOf(tmpInvoiceItem.getValue('SubscriptionId'));
					serviceDate         = Date.valueOf(String.valueOf(tmpInvoiceItem.getValue('ServiceStartDate')));
					zuoraProductId      = String.valueOf(tmpInvoiceItem.getValue('ProductId'));
					subscriptionNumber  = String.valueOf(tmpInvoiceItem.getValue('SubscriptionNumber'));
					break;
			}

			List<Zuora__Subscription__c> zSubscription = [SELECT Id, Subscription_Rate_Plan_Term_Type__c FROM Zuora__Subscription__c WHERE Name  = :subscriptionNumber LIMIT 1];
			String refundDiscountName = (zSubscription[0].Subscription_Rate_Plan_Term_Type__c.equalsIgnoreCase(Constants.SUBSCRIPTIONTYPE_MONTHLY) ? 
										 Constants.ZUORA_MONTHLY_REFUND_DISCOUNT_NAME :  Constants.ZUORA_ANNUAL_REFUND_DISCOUNT_NAME);

			List<Zuora.zObject> ratePlanItems;
			List<Zuora.zObject> ratePlanChargeItems;

			String zoql1 = 'SELECT Id,ProductId,Name FROM ProductRatePlan WHERE Name = \'Refund Discount\' AND ProductId = \'' + zuoraProductId + '\'' ;
			ratePlanItems = zApiInstance.zquery(zoql1);
			String productRatePlanID = String.valueOf(ratePlanItems[0].getValue('Id'));
		   	
		   	String zoql2 = 'SELECT Id FROM ProductRatePlanCharge WHERE ProductRatePlanId = \'' + productRatePlanID + '\' AND Name = \'' + refundDiscountName + '\'';
			ratePlanChargeItems = zApiInstance.zquery(zoql2);
			String productRatePlanChargeID = String.valueOf(ratePlanChargeItems[0].getValue('Id'));		

		   	//create the amendment zuora object
            Zuora.zObject amendmentObj = new Zuora.zObject('Amendment');
            
		   	Datetime amendmentDateTime = serviceDate;
		   	String formattedDate = amendmentDateTime.format('YYYY-MM-dd');

		   	amendmentObj.setValue('EffectiveDate', formattedDate );
            amendmentObj.setValue('ServiceActivationDate',formattedDate);
		   	amendmentObj.setValue('CustomerAcceptanceDate',formattedDate);
		   	
		   	amendmentObj.setValue('ContractEffectiveDate',formattedDate);
	        amendmentObj.setValue('Description', 'DiscretionaryDiscount');
	        amendmentObj.setValue('Name', 'DiscretionaryDiscount');
	        amendmentObj.setValue('Status', 'Completed');
	        amendmentObj.setValue('SubscriptionId', zuoraSubscriptionID);
	        amendmentObj.setValue('Type', 'NewProduct');

            //Rate Plan Object
            Zuora.zObject ratePlanDataObj = new Zuora.zObject('RatePlanData');
    		Zuora.zObject ratePlanObj = new Zuora.zObject('RatePlan');
				ratePlanObj.setValue('ProductRatePlanId', productRatePlanID);
				ratePlanDataObj.setValue('RatePlan', ratePlanObj);
	            // set RatePlanCharge
			Zuora.zObject ratePlanChargeDataObj = new Zuora.zObject('RatePlanChargeData');
			Zuora.zObject ratePlanChargeObj = new Zuora.zObject('RatePlanCharge');	
				ratePlanChargeObj.setValue('ProductRatePlanChargeId', productRatePlanChargeID);
				ratePlanChargeObj.setValue('Price',-refundAmount);
				ratePlanChargeDataObj.setValue('RatePlanCharge',ratePlanChargeObj);	
    			ratePlanDataObj.setValue('RatePlanChargeData',new List<Zuora.zObject>{ratePlanChargeDataObj});

            amendmentObj.setValue('RatePlanData', ratePlanDataObj);

            lstAmendments.add(amendmentObj);          
		   	amendRequest.amendments = lstAmendments;

	 		Zuora.zApi.AmendOptions amendOpt = new Zuora.zApi.AmendOptions();
			amendOpt.GenerateInvoice = true;
		
	 		amendRequest.AmendOptions  = amendOpt;

	 		if(!Test.isRunningTest()){
		 		//call the zuora zamend function
		 		Zuora.zApi.AmendResult result = zApiInstance.zamend(new List < Zuora.zApi.AmendRequest > {amendRequest});
		 		
		 		if (result.Success) {
					if (result.InvoiceId != null) {
				  		refundInvoiceId =  result.InvoiceId;
				  	}
				} else {
					// if we have an error display it to the user
					String errorString = '';
					for(Zuora.zObject error : result.errors){
						errorString += (String)error.getValue('Code') + ': ';
						errorString += (String)error.getValue('Message') + '\n';
					}
					ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR, Label.Zuora_Refund_Error + errorString));
					// also create a WebService log record to store the detail to aid a developer with fixing the issue
					TMGUtil.logWebServiceRequestSerialized(
						Constants.DIRECTION_OUTBOUND, 
						'',
						'Zuora_BillingPreviewUtility.createSubsDiscretionaryDiscount',
						new Map<String, String>{'invoiceId' => invoiceId, 'refundAmount' => String.valueOf(refundAmount)},
						errorString,
						invoiceId,
						null
					);
				}
		 		return refundInvoiceId;
			}
 		} catch(TMGUtil.GenericException genericExceptionObj){
 			throw new TMGUtil.GenericException(genericExceptionObj.getMessage());
		} catch(Exception ex){
			System.debug('TMGLOG:Zuora_BillingPreviewUtility:createSubsDiscretionaryDiscount: check exception: '+ex.getMessage());
	 		throw new TMGUtil.GenericException(Label.New_Digital_Platform_Generic_Error_Message);
		}	
 		
 		return null;	
	}

	/////////////////////////////////////////////////////////////////////////////////////////////
 	/////////////////////////////////////////End Billing Details using Subcription ID////////////
 	/////////////////////////////////////////////////////////////////////////////////////////////
 	
 	/////////////////////////////////////////////////////////////////////////////////////////////
 	//////////////////////////// Common Functions //////////////////////////////////////////////
 	////////////////////////////////////////////////////////////////////////////////////////////
 	/*************************************************************************************** 
    Developer   Sally ElGhoul (Accenture)
    Date        02/02/2016
    Function    this function is called to get the billing preview options
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
	public static Zuora.zApi.PreviewOptions getPreviewOptions(){
 		
 		Zuora.zApi.PreviewOptions previewOpt = new Zuora.zApi.PreviewOptions();
		previewOpt.EnablePreviewMode = true;
		previewOpt.NumberOfPeriods = 12;
		
		return previewOpt;
 	}
 	
 	/*************************************************************************************** 
    Developer   Sally ElGhoul (Accenture)
    Date        06/01/2016
    Function    this function is called to get handle the amendment result preview response (result)
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
	public static list<Zuora.zObject> handleAmendmentResults(Zuora.zApi.AmendResult result){
 			//if successfull and invoice data is not empty return it
 			if (result.Success) {
				//Handle with the invoice data returned by previewing subscriptions
			 	if (result.InvoiceDatas != null) {
			  		return result.InvoiceDatas;
			  	}
			} else {
				//failure
				//get the errors
				Zuora.zObject[] errors = result.errors;
				string ErrorMessage='';
				system.debug('check zamend errors: '+result.errors);
				for (Zuora.zObject error : errors) {
					String errorCode = (String)error.getValue('Code');
					String message = (String)error.getValue('Message');
					ErrorMessage+=' '+errorCode+':'+message+';';
				}
				throw new TMGUtil.GenericException(ErrorMessage);
			}
			return null;
 	}
 	
 	/*************************************************************************************** 
    Developer   Sally ElGhoul (Accenture)
    Date        25/02/2016
    Function    this function is called to fill the list of invoice item data from the zuora object list
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    public static list<Zuora_BillingPreviewInvoiceItems> fillInvoiceItemsList(list<Zuora.zObject> lstInvoideDatas,Boolean isMonthly,Boolean isCalculateCreditBalance,Decimal zuoraAccountCreditBalance){
    	map<Date,Decimal> mapInvoiceItemsAmountsByDate=new map<Date,Decimal>();
 		list<Zuora_BillingPreviewInvoiceItems> lstInvoiceItems=new list<Zuora_BillingPreviewInvoiceItems>();
 		
    	for (Zuora.zObject invData: lstInvoideDatas) {
    	 //in Preview mode, handle with the invoice data
	      Zuora.zObject invoice = (Zuora.zObject) invData.getValue( 'Invoice' );
	      
	      List<Object> invoiceItems = invData.getArrayValue( 'InvoiceItem' );
	      
	      if( invoiceItems != null ){
	        for( Object invoiceItem : invoiceItems ){
	        system.debug('Check invoiceItem: '+invoiceItem);
	      
	          Zuora.zObject zInvoiceItem = ( Zuora.zObject ) invoiceItem;
	          Decimal totalAmount=(Decimal)zInvoiceItem.getValue( 'ChargeAmount' );
	          totalAmount+=(Decimal)zInvoiceItem.getValue( 'TaxAmount' );
	          
	          //add the invoice line item
	          if(mapInvoiceItemsAmountsByDate.containskey(date.valueof(zInvoiceItem.getValue( 'ServiceStartDate' )))){
	          	mapInvoiceItemsAmountsByDate.put(date.valueof(zInvoiceItem.getValue( 'ServiceStartDate' )),mapInvoiceItemsAmountsByDate.get(date.valueof(zInvoiceItem.getValue( 'ServiceStartDate' )))+totalAmount);
	          }else{
		        mapInvoiceItemsAmountsByDate.put(date.valueof(zInvoiceItem.getValue( 'ServiceStartDate' )),totalAmount);
	          }
	        }
	      }
	    }
	    
	    if(mapInvoiceItemsAmountsByDate!=null && mapInvoiceItemsAmountsByDate.size()>0){
			for(date dateKey : mapInvoiceItemsAmountsByDate.keySet()){
				Zuora_BillingPreviewInvoiceItems invoiceItemObj=new Zuora_BillingPreviewInvoiceItems();
				invoiceItemObj.invoiceItemDate=dateKey;
				invoiceItemObj.invoiceItemAmount=mapInvoiceItemsAmountsByDate.get(dateKey);
				
				
				//add the invoice item only if the date is >= than today's date
				if(invoiceItemObj.invoiceItemDate>=date.today()){
					lstInvoiceItems.add(invoiceItemObj);
				}
			}
			
			//sort the invoice items by date asc
			lstInvoiceItems.sort();
			
			Integer index;
	        if(isMonthly){
	       		 index = 13 - lstInvoiceItems.size();
	      	} else {
	       		 index =1 ;
	      	}
			
			for(Zuora_BillingPreviewInvoiceItems itemObj : lstInvoiceItems){
				
				//use the credit balance
				if(isCalculateCreditBalance){
					if(zuoraAccountCreditBalance>0){
						
						//this is the case when say credit balance is 150 and the invoice amount is 15
						if(zuoraAccountCreditBalance>=itemObj.invoiceItemAmount){
							zuoraAccountCreditBalance=zuoraAccountCreditBalance-itemObj.invoiceItemAmount;
							itemObj.invoiceItemAmount=0;
						}else{ //this is the case where credit balance is say 2 and the invoice amount is 15
							itemObj.invoiceItemAmount=itemObj.invoiceItemAmount-zuoraAccountCreditBalance;
							zuoraAccountCreditBalance=0;
						}
					}
				}
				itemObj.InvoiceItemIndex=index;
				index++;
			}
		}
		
		return lstInvoiceItems;
    }
}