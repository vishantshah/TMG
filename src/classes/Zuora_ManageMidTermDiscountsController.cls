/**
* Author:       Sally ElGhoul (Accenture)
* Date:         22/10/2015
* Description:  this class is the controller for Zuora_ManageMidTermDiscounts page
*
* ******************* Change Log *******************
* Modified by       	Change Date     
* Sally ELGhoul			25/02/2016 Change how mid term discounts is working
* Sally ElGhoul			07/03/2016 modify future mid term discounts (effective date in the future)
* Mantas Grigaliunas	02/05/2017 isRefundAllowed() validation added on constructor
* Wiktor Czykin     17/05/2017 Changed constant to label for error message 
**/
public class Zuora_ManageMidTermDiscountsController {
	
	public Zqu.NotificationOptions notificationOptions 				{get;set;}
	public zqu__Quote__c quoteObj									{get;set;}
	public Zuora__Subscription__c currentSubscriptionObj			{get;set;}
	public Decimal accountBalance									{get;set;} //the account credit balance to do right calcultion for billing preview
	
	//the mid term discount product rate plan and product rate plan charge zuora ids
	public String discountProductRatePlanId							{get;set;}
	public String discountProductRatePlanChargeId					{get;set;}
	
	//Agent selection fields for the new discount to be added
	public String	selectedEffectiveDate							{get;set;}
	public String	selectedNumberOfPeriods							{get;set;}
	public Decimal  discountAmount									{get;set;}
	
	//the new discounts added by the agent (this List may be different from the discounts sent finally to zuora based on the logic checking if possible to add this discount with this amount to all period or no)
	public List<OfferDetails> lstNewMidTermDiscounts				{get;set;}
	
	//this list will contain the old discounts already applied and that the agen would like to delete (future discounts)
	public List<OfferDetails> lstDeleteMidTermDiscounts				{get;set;} 
	
	private Zuora.zApi api = new Zuora.zApi();
	
	//get from custom setting if we still need to calculate the credit balance with billing preview manually or zuora fixed this issue and we should not calculate it manually anymore
	private Boolean isCalculateCreditBalance{
  		get{
  			if(Application_Settings__c.getInstance(Constants.CALCULATE_CREDIT_BALANCE_FOR_BILLING_PREVIEW)!=null){
  				return Boolean.valueOf(Application_Settings__c.getInstance(Constants.CALCULATE_CREDIT_BALANCE_FOR_BILLING_PREVIEW).value__c);
  			}else{
  				return true;
  			}
  		}
  	}
  	
  	//get the minimum amount that the users should be paying monthly which will limit the amount of discounts to be added for user
  	private Decimal monthlyMinimumPaymentAmount{
  		get{
  			if(Application_Settings__c.getInstance(Constants.MONTHLY_MINIMUM_PAYMENT_AMOUNT)!=null){
  				return Decimal.valueOf(Application_Settings__c.getInstance(Constants.MONTHLY_MINIMUM_PAYMENT_AMOUNT).value__c);
  			}else{
  				return 0;
  			}
  		}
  	}
  	
  	private Id subscriptionID{
  		get{
  			if(subscriptionID==null && ApexPages.currentPage().getParameters().containsKey(Constants.SUBSCRIPTION_ID_QUERY_STRING) && !String.isEmpty(ApexPages.currentPage().getParameters().get(Constants.SUBSCRIPTION_ID_QUERY_STRING))){
  				subscriptionID= Id.valueOf(ApexPages.currentPage().getParameters().get(Constants.SUBSCRIPTION_ID_QUERY_STRING));
  			}
  			return subscriptionID;
  		}
  		private set;
  	}
  	
  	/*************************************************************************************** 
    Developer   Sally ElGhoul (Accenture)
    Date        10/03/2016
    Function    get either to show the mid term reason or no
    			we show the reason if :
    			- There is a new discount added by agent 
    			- or there is available effective date values
  	******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
	public Boolean getIsRenderMidTermReason(){
		Boolean isNewDiscountAdded=false;
		//check if a new discount is added
		for(OfferDetails newDiscountObj : lstNewMidTermDiscounts){
			if(!newDiscountObj.isOldDiscount){
				isNewDiscountAdded=true;
				break;
			}	
		}
		
		if(getPossibleEffectiveDates().size()>1 || isNewDiscountAdded ){
			return true;
		}else{
			return false;
		}
	}
  	
  	/*************************************************************************************** 
    Developer   Sally ElGhoul (Accenture)
    Date        25/02/2016
    Function    get the List of invoice items to show on the UI
  	******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
	public List<Zuora_BillingPreviewInvoiceItems> lstInvoiceItems{
  		get{
  			
  			//if the List invoice is null call the load billing preview details
  			if(lstInvoiceItems==null){
  				
  				if(!Test.isRunningTest()){api.zlogin();}
  				lstInvoiceItems=new List<Zuora_BillingPreviewInvoiceItems>();
		      	List<Zuora.zObject> lstBillingDetails=new List<Zuora.zObject>();
		      	
		      	//get the billing details by calling zuora
		      	if(currentSubscriptionObj!=null){
		      		lstBillingDetails=Zuora_BillingPreviewUtility.previewSubscriptionBillingDetails(api,currentSubscriptionObj);
    			}
    			
    			//fill the invoice List from the billing details return from zuora
    			if(lstBillingDetails!=null && lstBillingDetails.size()>0){
	    			lstInvoiceItems=Zuora_BillingPreviewUtility.fillInvoiceItemsList(lstBillingDetails,true,isCalculateCreditBalance,accountBalance);
	    		}
		    }
  			
  			return lstInvoiceItems;
  		}
  		private set;
  	}
  	
  	/*************************************************************************************** 
    Developer   Sally ElGhoul (Accenture)
    Date        25/02/2016
    Function    get the total invoice amount value
  				the total amount should take the invoice value of discounted amount if a discount is applied
  				if no discount is applied we should use the original invoice amount
  	******************* Change Log *******************
    Modified by         Version     Change Date
    Sally ElGhoul		1.1			10/3/2016 change the isDiscountApplied to isNewDiscountApplied
    ****************************************************************************************/
	public Decimal getTotalInvoices(){
  		Decimal totalInvoiceAmount=0;
  		
  		for(Zuora_BillingPreviewInvoiceItems invoiceItem : lstInvoiceItems){
  			
  			//if discount applied, add the value after applying discount
  			if(invoiceItem.isNewDiscountApplied){
  				totalInvoiceAmount+=invoiceItem.discountedInvoiceItemAmount;
  			}else{ //if no discount is added, use the original invoice amount
  				totalInvoiceAmount+=invoiceItem.invoiceItemAmount;
  			}
  		}
  		return totalInvoiceAmount;
  	}

	/*************************************************************************************** 
    Developer   Sally ElGhoul (Accenture)
    Date        25/02/2016
    Function    get the number of available based on the user selection for the effective mid term date
				and based on the status of each invoice and its amount as we don't allow overlaping discounts
				so Choosing the first month as effective date can lead to no of periods to be from 1 to 11 
				but if a discount is added to second month, in this case the only option available when 
				choosing first month will be 1 period only
  	******************* Change Log *******************
    Modified by         Version     Change Date
    Sally ElGhoul		1.1			8/3/2016 calculating the number of periods should take into consideration if there is an old discount applied or no
    ****************************************************************************************/
	public List<SelectOption> getNumberOfPeriods(){
		
		List<SelectOption> lstNumberOfPeriods=new List<SelectOption>();
		lstNumberOfPeriods.add(new SelectOption('',Constants.NONE_PICKLIST_VALUE));
		selectedNumberOfPeriods='';
		
		if(!String.isEmpty(selectedEffectiveDate)){
			
			Date selectedDateValue=getEffectDateValueFromString(selectedEffectiveDate);
			Integer counter=0;
			
			//loop on invoice items to get the number of periods applicable based on the invoices remaing count and discounts added to stop overlapped discounts
			for(Zuora_BillingPreviewInvoiceItems invoiceItem : lstInvoiceItems){
				
				if(invoiceItem.invoiceItemDate==selectedDateValue){ //set the counter to 1
					counter=1;	
				}else if(counter>0){ //count the remain months after the selected date to get the number of months to which we can apply discount
					if(!invoiceItem.isNewDiscountApplied && !invoiceItem.isOldDiscountApplied && invoiceItem.invoiceItemAmount>monthlyMinimumPaymentAmount){
						counter++;
					}else{
						break;
					}
				}
			}
			
			//fill the List of number of periods
			if(counter>0){
				for(Integer i=1; i<=counter;i++){
					lstNumberOfPeriods.add(new SelectOption(String.valueOf(i),String.valueOf(i)));	
				}
			}
		}
		return lstNumberOfPeriods;
	}
	
	/*************************************************************************************** 
    Developer   Sally ElGhoul (Accenture)
    Date        25/02/2016
    Function    get the mid Term effective dates options
					get the months that don't have a discount applied already
					    AND
					    their invoice amount > monthlyMinimumPaymentAmount
  	******************* Change Log *******************
    Modified by         Version     Change Date
    Sally ElGhoul		1.1			8/3/2016 exclude the months with an existing discount to avoid overlapping discounts
    ****************************************************************************************/
	public List<SelectOption> getPossibleEffectiveDates(){
		
		List<SelectOption> lstEffectiveDateOptions=new List<SelectOption>();
		lstEffectiveDateOptions.add(new SelectOption('',Constants.NONE_PICKLIST_VALUE));
		
		for(Zuora_BillingPreviewInvoiceItems invoiceItem : lstInvoiceItems){
			
			//check that no discount is already applied to this invoice and that the amount is > monthlyMinimumPaymentAmount
			if(!invoiceItem.isNewDiscountApplied && !invoiceItem.isOldDiscountApplied && invoiceItem.invoiceItemAmount>monthlyMinimumPaymentAmount){
				
				//add the invoice date to the List of mid term effective dates
				Datetime invoiceItemDateTime=Datetime.newInstance(invoiceItem.invoiceItemDate.year(),invoiceItem.invoiceItemDate.month(),invoiceItem.invoiceItemDate.day());
	 			lstEffectiveDateOptions.add(new SelectOption(invoiceItemDateTime.format('dd/MM/YYYY'),invoiceItemDateTime.format('dd/MM/YYYY')));
			}
		}
		return lstEffectiveDateOptions;
	}
	
	/*************************************************************************************** 
    Developer   Sally ElGhoul (Accenture)
    Date        25/02/2016
    Function    Constructor
    ******************* Change Log *******************
    Modified by         Version     Change Date
    Sally ElGhoul		1.1			8/3/2016 	initialize lstDeleteMidTermDiscounts
    Mantas Grigaliunas	1.2			02/05/2017	isRefundAllowed() validation added
    ****************************************************************************************/
	public Zuora_ManageMidTermDiscountsController(){
		
		try{
			quoteObj=new zqu__Quote__c();
			lstNewMidTermDiscounts=new List<OfferDetails> ();
			lstDeleteMidTermDiscounts=new List<OfferDetails>();
			
			//Init notification options for the notification component
		    notificationOptions = new zqu.NotificationOptions();
		    notificationOptions.backLabel=Constants.ZUORA_OK_BUTTON_TEXT;
		    notificationOptions.isPopup = true;
		    notificationOptions.backAction = 'goToHomePage();';	
		    
		    //make sure that the subscription id is passed
		    if(subscriptionID!=null){

		    	//check if subscription is allowed for refund
            	if(!ZuoraSubscriptionCanceller.isRefundAllowed(subscriptionID)){
                	ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ZuoraSubscriptionCanceller.errorMessage));
                	notificationOptions.backAction = 'goToSubscriptionPage();';
                	return;
            	}

		    	//get the subscription record
		    	getSubscriptionDetails(subscriptionID);
		    			
			}else{
				
				notificationOptions.backAction = 'goToHomePage();';
		        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Manage_Mid_Term_Discounts_Invalid_Query_String_Error));
			}
		}catch(TMGUtil.GenericException genericExceptionObj){
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,genericExceptionObj.getMessage()));
		}catch(Exception ex){ 
			System.debug('Error Occured on page load of Manage Mid Term Discount: '+ex+' Line: '+ex.getLineNumber());
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,Label.General_Contact_administrator_error));
		}
		
	}
	
	/*************************************************************************************** 
    Developer   Sally ElGhoul (Accenture)
    Date        23/10/2015
    Function    This function is called to cancel and go to previous page
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
	public PageReference cancel(){
		
		//when cancel is pressed we need redirect the user to the account page
		if(subscriptionID!=null){
			return goToSubscriptionPage();
		}
		return null;
	}
	
	/*************************************************************************************** 
    Developer   Sally ElGhoul (Accenture)
    Date        10/03/2016
    Function    This function is called to reset the changes the user did
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
	public void reset(){
		
		if(subscriptionID!=null){
			selectedEffectiveDate='';
			quoteObj=new zqu__Quote__c();
			lstNewMidTermDiscounts=new List<OfferDetails> ();
			lstDeleteMidTermDiscounts=new List<OfferDetails>();
			lstInvoiceItems=null;
			
			//get the current subscription mid term discounts 
			getCurrentSubscriptionMidTermDiscounts();
		}
	}
	
	/*************************************************************************************** 
    Developer   Sally ElGhoul (Accenture)
    Date        29/02/2016
    Function    This function is called to when Add discount is pressed to add the discount and refresh the billing preview
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
	public PageReference addNewDiscount(){
		
		try{
			OfferDetails newOffer=new OfferDetails();
			
			//validate that the selected effective date is selected
			if(String.isEmpty(selectedEffectiveDate)){
				
				notificationOptions.backAction = 'stayOnPage();';
		        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Mid_Term_Effective_Date_Required));
				return null;
			}
			
			//validate that number of periods is selected
			if(String.isEmpty(selectedNumberOfPeriods)){
				
				notificationOptions.backAction = 'stayOnPage();';
		        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Mid_Term_Number_of_Periods_Required));
				return null;
			}
			
			//validate that the discount amount is >0
			if(discountAmount<=0){
				
				notificationOptions.backAction = 'stayOnPage();';
		        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Mid_Term_Discount_Amount_Invalid_Error_Message));
				return null;
			}
			
			//set the new offer object fields
			newOffer.effectiveDate=	getEffectDateValueFromString(selectedEffectiveDate);
			newOffer.numberOfPeriod=Integer.valueOf(selectedNumberOfPeriods);
			newOffer.discountAmount=discountAmount;
			lstNewMidTermDiscounts.add(newOffer);
			
			//refresh the billing preview and clear the mid term selection fields
			refreshBillingPreview();
			selectedEffectiveDate=selectedNumberOfPeriods='';
			discountAmount=0;
			
		}catch(TMGUtil.GenericException genericExceptionObj){
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,genericExceptionObj.getMessage()));
		}catch(Exception ex){ 
			System.debug('Error Occured in addNewDiscount method: '+ex+' Line: '+ex.getLineNumber());
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,Label.General_Contact_administrator_error));
		}
		
		return null;
	}
	
	/*************************************************************************************** 
    Developer   Sally ElGhoul (Accenture)
    Date        29/02/2016
    Function    This function is called to save the mid term discounts to zuora by calling zAmend
    ******************* Change Log *******************
    Modified by         Version     Change Date
    Sally ElGhoul		1.1			8/3/2016 handle removing the mid term discounts removed by agent and create remove product amendments for them 
    Sally ElGhoul		1.1			8/3/2016 bypass the mid term reason validation 
    ****************************************************************************************/
	public PageReference saveMidTermDiscounts(){
		
		try{
			
			//the amendment request
		 	Zuora.zApi.AmendRequest amendRequest = new Zuora.zApi.AmendRequest();
			
			//form the amendments that we want to submit to zuora from the mid term discounts added by user
			List<Zuora.zObject> lstAmendments = getMidTermAmendments();    
			
			if(String.isEmpty(quoteObj.Mid_term_Discount_Reason__c) && !lstAmendments.isEmpty()){
				
				notificationOptions.backAction = 'stayOnPage();';
	        	ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Mid_term_Discount_Reason_Error_Message));
				return null;
			}
			
			//get the remove product amendments 
			if(!lstDeleteMidTermDiscounts.isEmpty()){
				List<Zuora.zObject> lstRemoveProductsAmendments=getRemoveProductAmendments();
				if(!lstRemoveProductsAmendments.isEmpty()){
					lstAmendments.addAll(lstRemoveProductsAmendments);	
				}
			}
			
			if(lstAmendments.isEmpty()){
				notificationOptions.backAction = 'stayOnPage();';
	        	ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Mid_Term_Discount_Empty_Amendment_Saving_Error));
				return null;
			}
			amendRequest.amendments = lstAmendments;
			
			if(!Test.isRunningTest()){
		 		//call the zuora zamend function
		 		Zuora.zApi.AmendResult result = api.zamend(new List < Zuora.zApi.AmendRequest > {amendRequest});
		 		
		 		//check the result and give the user the proper message (success or failure)
		 		handleZAmendResults(result);
		 	}else{
				List<Zuora.zObject> lstinvoiceDatasValues=new List<Zuora.zObject>();
				
				Zuora.ZObject invoiceDatasValue=new Zuora.zObject('InvoiceData');	
				List<Zuora.zObject> lstInvoices=new List<Zuora.zObject>();
				
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
			}
		}catch(TMGUtil.GenericException genericExceptionObj){
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,genericExceptionObj.getMessage()));
		}catch(Exception ex){ 
			System.debug('Error Occured in method saveMidTermDiscounts: '+ex+' Line: '+ex.getLineNumber());
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,Label.General_Contact_administrator_error));
		}
		
		return null;
	}
	
	/*************************************************************************************** 
    Developer   Sally ElGhoul (Accenture)
    Date        29/02/2016
    Function    This function is called to Remove a discount from the List of added discounts
    ******************* Change Log *******************
    Modified by         Version     Change Date
    Sally ElGhoul		1.1			8/3/2016 by removing the old discount I add it to the list lstDeleteMidTermDiscounts 
    										 in order to update the billing preview data and create the remove product amendment 
    ****************************************************************************************/
	public PageReference removeNewDiscount(){
		
		try{
			List<OfferDetails> lstRemainingDiscounts=new List<OfferDetails>();
			List<OfferDetails> lstRemoveDiscounts=new List<OfferDetails>();
			
			//loop on the List of discounts and remove the one the user pressed delete on it
			for(OfferDetails newDiscountObj :lstNewMidTermDiscounts){
				if(!newDiscountObj.isDelete){
					lstRemainingDiscounts.add(newDiscountObj);
				}else if(newDiscountObj.isDelete && newDiscountObj.isOldDiscount){
					lstDeleteMidTermDiscounts.add(newDiscountObj);
					lstRemoveDiscounts.add(newDiscountObj);
				}
			}
			
			lstNewMidTermDiscounts=lstRemainingDiscounts;
			
			//Loop on the deleted discounts and update the invoice item amount field
			for(OfferDetails deleteDiscountObj : lstRemoveDiscounts){
				Integer discountNoPeriods=deleteDiscountObj.numberOfPeriod;
				Integer counter=0;
				
				for(Zuora_BillingPreviewInvoiceItems invoiceItemObj : lstInvoiceItems){
					
					//if the first invoice is found that match the start effective date of the discount or it the upcoming invoices that are still covered by the discount , update their invoice details	
					if(invoiceItemObj.invoiceItemDate==deleteDiscountObj.effectiveDate || (counter>=1 && counter<discountNoPeriods)){
						
						//save the discount amount applied 
						invoiceItemObj.invoiceItemAmount=invoiceItemObj.invoiceItemAmount+deleteDiscountObj.discountAmount;
						
						//set ther counter to one if it is the first invoice otherwise increment the counter
						if(invoiceItemObj.invoiceItemDate==deleteDiscountObj.effectiveDate){
							counter=1;
						}else{
							counter++;
						}
					}
				}
			}
			
			//refresh the billing preview
			refreshBillingPreview();
		}catch(TMGUtil.GenericException genericExceptionObj){
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,genericExceptionObj.getMessage()));
		}catch(Exception ex){ 
			System.debug('Error Occured in method removeNewDiscount: '+ex+' Line: '+ex.getLineNumber());
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,Label.General_Contact_administrator_error));
		}
		return null;
	}
	
  	/*************************************************************************************** 
    Developer   Sally ElGhoul (Accenture)
    Date        02/03/2016
    Function    This function is called to get the subscription details
    									   get the discount rate plans to be used and 
    									   get the account credit balance
    ******************* Change Log *******************
    Modified by         Version     Change Date
    Sally ElGhoul		1.1			7/3/2016 - get the current subscription future mid term discounts
    ****************************************************************************************/
	private void getSubscriptionDetails(ID subscriptionID){
		
		//get the subscription details
		List<Zuora__Subscription__c> lstSubscriptions=[select Zuora__Status__c,Zuora__CustomerAccount__r.Zuora__Zuora_Id__c,
																Zuora__Zuora_Id__c,id,Related_Quote__c,Master_Quote__c,
																Zuora__NextChargeDate__c,Original_Zuora_Subscription_ID__c,
																Zuora__ServiceActivationDate__c,Zuora__Account__c,Zuora__Account__r.Name,Zuora__Account__r.Subscriber_Number__c,
																Zuora__SubscriptionStartDate__c,Zuora__SubscriptionEndDate__c,Subscription_Rate_Plan_Term_Type__c,
																(Select id,Zuora__Product__r.Zuora__External_Id__c From Zuora__Subscription_Product_Charges__r limit 1)
																from Zuora__Subscription__c 
																where id=:subscriptionID];
		
		//if no subscription found throw an error that it is an invalid subsciption id
		if(lstSubscriptions==null || lstSubscriptions.size()==0){
			Throw new TMGUtil.GenericException(Label.Mid_Term_Discount_Invalid_Subscription_ID);
		}else{
			//set the currentSubscriptionObj to the subscription found
			currentSubscriptionObj=lstSubscriptions[0];
			
			//get the current subscription mid term discounts 
			getCurrentSubscriptionMidTermDiscounts();
			
			//get the discount product rate plan id and rate plan chare id for the product added to the subscription
			if(!currentSubscriptionObj.Zuora__Subscription_Product_Charges__r.isEmpty()){
				
				//get the zprodudct record related to the subscription product charge
	           	List<zqu__ZProduct__c> lstzuoraProduct=[select id from zqu__ZProduct__c where zqu__ZuoraId__c=:currentSubscriptionObj.Zuora__Subscription_Product_Charges__r[0].Zuora__Product__r.Zuora__External_Id__c];
				
				if(!lstzuoraProduct.isEmpty()){
					
		           	//get the discount product rate plan for the product and its charge to get their zuora Ids
		           	List<zqu__ProductRatePlan__c> lstProductDiscountRatePlan=[select id,zqu__ZuoraId__c, 
		           																	(Select Id,zqu__ZuoraId__c From zqu__R00N40000001mFVKEA2__r where name=:Constants.MID_TERM_DISCOUNT_RATE_PLAN_NAME limit 1) from zqu__ProductRatePlan__c 
			           																where zqu__ZProduct__c=:lstzuoraProduct[0].id 
			           																	and name=:Constants.MID_TERM_DISCOUNT_RATE_PLAN_NAME 
			           																	and zqu__Deleted__c=false ];
		           																	
		        	if(!lstProductDiscountRatePlan.isEmpty()){
		        		
		        		//discount product rate plan Id (Zuora Id)
		        		discountProductRatePlanId=lstProductDiscountRatePlan[0].zqu__ZuoraId__c;
		        		
		        		//discount product rate plan charge Id (Zuora Id)
		        		if(!lstProductDiscountRatePlan[0].zqu__R00N40000001mFVKEA2__r.isEmpty()){
		        			discountProductRatePlanChargeId=lstProductDiscountRatePlan[0].zqu__R00N40000001mFVKEA2__r[0].zqu__ZuoraId__c;
		        		}
		        	}    
		        }
			}
			
			//get the credit balance of the account
			getAccountCreditBalance();
		}
	}
	
	/*************************************************************************************** 
    Developer   Sally ElGhoul (Accenture)
    Date        07/03/2016
    Function    this function is called to get subscription mid term discounts that will start in the future
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    private void getCurrentSubscriptionMidTermDiscounts(){
    	
    	List<Zuora__SubscriptionProductCharge__c> lstSubscriptionMidTermDiscountCharges=[select Zuora__Zuora_Id__c,id,Zuora__Upto_How_Many_Periods__c,Zuora__EffectiveStartDate__c,Zuora__Price__c 
    																							from Zuora__SubscriptionProductCharge__c
    																							where Zuora__Subscription__c=:currentSubscriptionObj.id
    																								and Zuora__EffectiveStartDate__c>:Date.today()
    																								and Name=:Constants.MID_TERM_DISCOUNT_RATE_PLAN_NAME];
        
        for(Zuora__SubscriptionProductCharge__c subscriptionChargeObj :lstSubscriptionMidTermDiscountCharges){
        	
        	OfferDetails offerObj=new OfferDetails();
        	offerObj.effectiveDate=subscriptionChargeObj.Zuora__EffectiveStartDate__c;
        	offerObj.numberOfPeriod=Integer.valueOf(subscriptionChargeObj.Zuora__Upto_How_Many_Periods__c);
        	offerObj.discountAmount=(subscriptionChargeObj.Zuora__Price__c*-1);
        	offerObj.chargeZuoraId=subscriptionChargeObj.Zuora__Zuora_Id__c;
        	offerObj.isOldDiscount=true;
        	lstNewMidTermDiscounts.add(offerObj);
        }
        
        if(lstNewMidTermDiscounts.size()>0){
        	//refresh the billing preview
			refreshBillingPreview();
        }
        
	}
	
	/*************************************************************************************** 
    Developer   Sally ElGhoul (Accenture)
    Date        25/02/2016
    Function    this function is called to get the account credit balance
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    private Decimal getAccountCreditBalance(){
    	
    	accountBalance=0;
    	
    	if(!Test.isRunningTest()){api.zlogin();}
  				
    	//get the zuora account to get the credit balance
    	List <Zuora.zObject> lstZuoraAccount=Zuora_Utility.getZuoraBillingAccounts(api,currentSubscriptionObj.Zuora__Account__c);
    	
    	//if the zuora account List is not empty and the zuora account if found
    	if(lstZuoraAccount!=null && lstZuoraAccount.size()>0){
    		
    		//get the account credit balance if not empty and if it is > zero
    		if(lstZuoraAccount[0].getValue('CreditBalance')!=null && ((Decimal)lstZuoraAccount[0].getValue('CreditBalance'))>0){
    			accountBalance=(Decimal)lstZuoraAccount[0].getValue('CreditBalance');
    		}
    	}
    	return accountBalance;
    }
  	
  	/*************************************************************************************** 
    Developer   Sally ElGhoul (Accenture)
    Date        25/02/2016
    Function    this function is called to refresh the billing preview with the discount amounts
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    private void refreshBillingPreview(){
		
		//reset the invoice item fields to set the discount to zero , applied discount to false because billing preview is called for both adding and removing a discount
		resetInvoiceItems();
		
		//loop the List of new discounts to update the billing preview values
		for(OfferDetails newDiscountObj : lstNewMidTermDiscounts){
			
			Integer discountNoPeriods=newDiscountObj.numberOfPeriod;
			Integer counter=0;
			
			for(Zuora_BillingPreviewInvoiceItems invoiceItemObj : lstInvoiceItems){
				
				//if the first invoice is found that match the start effective date of the discount or it the upcoming invoices that are still covered by the discount , update their invoice details	
				if(invoiceItemObj.invoiceItemDate==newDiscountObj.effectiveDate || (counter>=1 && counter<discountNoPeriods)){
					
					if(newDiscountObj.isOldDiscount){
						invoiceItemObj.isOldDiscountApplied=true;
					}else{
						
						//get the maximum discount amount that we can apply to the invoice 
						//because we control that the user should at least pay a certain amount monthly and
						//because we don't want to apply negative amounts
						Decimal applyDiscountAmount=getDiscountAmountToApply(invoiceItemObj.invoiceItemAmount,newDiscountObj.discountAmount);
						
						//update the invoice amount after applying the discount, we save it in the discounted invoice item amount field
						invoiceItemObj.discountedInvoiceItemAmount=invoiceItemObj.invoiceItemAmount-applyDiscountAmount;
						
						//mark that this invoice has a discount applied to avoid adding another discount at the same month
						invoiceItemObj.isNewDiscountApplied=true;
						
						//save the discount amount applied 
						invoiceItemObj.discountAmount=applyDiscountAmount;
					}
					
					//set ther counter to one if it is the first invoice otherwise increment the counter
					if(invoiceItemObj.invoiceItemDate==newDiscountObj.effectiveDate){
						counter=1;
					}else{
						counter++;
					}
				}
			}
		}
	}
	
	/*************************************************************************************** 
    Developer   Sally ElGhoul (Accenture)
    Date        25/02/2016
    Function    this function is called to reset the invoice items fields that indicate either a discount is applied or no and amount of discount
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    private void resetInvoiceItems(){
    	
    	for(Zuora_BillingPreviewInvoiceItems invoiceItemObj : lstInvoiceItems){
			
			invoiceItemObj.discountedInvoiceItemAmount=discountAmount=0;
			invoiceItemObj.isNewDiscountApplied=invoiceItemObj.isOldDiscountApplied=false;
		}
	}
	
	/*************************************************************************************** 
    Developer   Sally ElGhoul (Accenture)
    Date        25/02/2016
    Function    this function is called to get the maximum the discount that can be applied per invoice
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    private Decimal getDiscountAmountToApply(Decimal invoiceItemAmount,Decimal discountAmount){
		
		//the amount that can be applied
		Decimal discountAmountToApply=0;
		
		//calculate what will be the invoice amount if we apply the discount requested by user
		Decimal invoiceItemAfterDiscount=invoiceItemAmount-discountAmount;
		
		//validate that the invoice amount after applying the discount is not < monthlyMinimumPaymentAmount
		//if the invoice amount will be <monthlyMinimumPaymentAmount so the discount requested can't be applied and we need to calculate the max to be applied
		if(invoiceItemAfterDiscount< monthlyMinimumPaymentAmount){
			discountAmountToApply=InvoiceItemAmount-monthlyMinimumPaymentAmount;
		}else{
			discountAmountToApply=discountAmount;
		}
		
		return discountAmountToApply;
	}
	
	/*************************************************************************************** 
    Developer   Sally ElGhoul (Accenture)
    Date        25/02/2016
    Function    this function is called to convert the mid term discounts added by user to List of zuora amendment to be used by zAmend call
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    private List<Zuora.zObject> getRemoveProductAmendments(){
		
		List<Zuora.zObject> lstRemoveProductAmendments=new List<Zuora.zObject>();
		List<String> 		lstDeleteRatePlanIds	  =new List<String>();
		
		//if not running test class, login to zuora
  		if(!Test.isRunningTest()){api.zlogin();}
  		String ratePlanChargeIdsWhereClause='';
  			
		for(OfferDetails deleteDiscountObj : lstDeleteMidTermDiscounts){
		
			if(String.isEmpty(ratePlanChargeIdsWhereClause)){
				ratePlanChargeIdsWhereClause='Id = \''+deleteDiscountObj.chargeZuoraId+'\'';
			}else {
				ratePlanChargeIdsWhereClause+=' or Id = \''+deleteDiscountObj.chargeZuoraId+'\'';
			}
		}
		
		//form the soql query
		String ratePlanChargeSoql = 'SELECT RatePlanId, Id,Name FROM RatePlanCharge WHERE '+ratePlanChargeIdsWhereClause;
        
        //Query Zuora
        List<Zuora.zObject> lstZuoraRatePlanChagres;
        
        if(!Test.isRunningTest()){
        	lstZuoraRatePlanChagres= api.zquery(ratePlanChargeSoql);
        }else{
        	lstZuoraRatePlanChagres=new List<Zuora.zObject>();
        	Zuora.zObject zuoraRatePlanChargeObj=new Zuora.zObject('RatePlanCharge');
        	zuoraRatePlanChargeObj.setValue('RatePlanId','R12345');
        	zuoraRatePlanChargeObj.setValue('Id','123344456677');
        	lstZuoraRatePlanChagres.add(zuoraRatePlanChargeObj);
        }
        
        for(Zuora.zObject chargeObj: lstZuoraRatePlanChagres){
        	lstDeleteRatePlanIds.add(String.valueOf(chargeObj.getValue('RatePlanId')));
        }
		
		for(String ratePlanId :lstDeleteRatePlanIds){	
			Zuora.zObject amendmentObj = new Zuora.zObject('Amendment');
			amendmentObj.setValue('EffectiveDate', ZuoraUtilities.dateZuoraFormat(Date.today()));
 			amendmentObj.setValue('ServiceActivationDate', ZuoraUtilities.dateZuoraFormat(Date.today()));
 			amendmentObj.setValue('CustomerAcceptanceDate', ZuoraUtilities.dateZuoraFormat(Date.today()));
 			amendmentObj.setValue('ContractEffectiveDate', ZuoraUtilities.dateZuoraFormat(Date.today()));
		    amendmentObj.setValue('Description',String.format(Label.Mid_term_Discount_Amendment_Removal_Name,new List<String>{currentSubscriptionObj.Zuora__Account__r.Subscriber_Number__c}));
		    amendmentObj.setValue('Name', String.format(Label.Mid_term_Discount_Amendment_Removal_Name,new List<String>{currentSubscriptionObj.Zuora__Account__r.Subscriber_Number__c}));
		    amendmentObj.setValue('Status', 'Completed');
		    amendmentObj.setValue('SubscriptionId', currentSubscriptionObj.Zuora__Zuora_Id__c);
		    amendmentObj.setValue('Type', 'RemoveProduct');
		  	
		  	Zuora.zObject ratePlanData = new Zuora.zObject('RatePlanData');
		  	//define the rate plan for rate Plan Data
				Zuora.zObject ratePlan = new Zuora.zObject('RatePlan');
				ratePlan.setValue('AmendmentSubscriptionRatePlanId', ratePlanId); 
			ratePlanData.setValue('RatePlan', ratePlan);
			amendmentObj.setValue('RatePlanData', ratePlanData);
			
		  	lstRemoveProductAmendments.add(amendmentObj);
		}
		
		return lstRemoveProductAmendments;
	}
	
	/*************************************************************************************** 
    Developer   Sally ElGhoul (Accenture)
    Date        25/02/2016
    Function    this function is called to convert the mid term discounts added by user to List of zuora amendment to be used by zAmend call
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    private List<Zuora.zObject> getMidTermAmendments(){
	
		List<Zuora.zObject> lstMidTermAmendments=new List<Zuora.zObject>();
		
		//get the List of mid term discount that should be sent to zuora 
		//we didn't get the List added by user as is directly because we adjust what the maximum discount that can be added per invoice
		List<OfferDetails>  lstInsertMidTermDiscounts=getLatestMidTermDiscounts();
		
		//loop on the List of discounts to be inserted and create the amendment objects
		for(OfferDetails newDiscountObj : lstInsertMidTermDiscounts){
			
			//create the amendment zuora object
 			Zuora.zObject amendmentObj = new Zuora.zObject('Amendment');
			amendmentObj.setValue('EffectiveDate', ZuoraUtilities.dateZuoraFormat(newDiscountObj.effectiveDate));
 			amendmentObj.setValue('ServiceActivationDate', ZuoraUtilities.dateZuoraFormat(newDiscountObj.effectiveDate));
 			amendmentObj.setValue('CustomerAcceptanceDate', ZuoraUtilities.dateZuoraFormat(newDiscountObj.effectiveDate));
 			amendmentObj.setValue('ContractEffectiveDate', ZuoraUtilities.dateZuoraFormat(newDiscountObj.effectiveDate));
		    amendmentObj.setValue('Description', String.format(Label.Mid_term_Discount_Amendment_Name,new List<String>{currentSubscriptionObj.Zuora__Account__r.Subscriber_Number__c}));
		    amendmentObj.setValue('Name', String.format(Label.Mid_term_Discount_Amendment_Name,new List<String>{currentSubscriptionObj.Zuora__Account__r.Subscriber_Number__c}));
		    amendmentObj.setValue('Status', 'Completed');
		    amendmentObj.setValue('SubscriptionId', currentSubscriptionObj.Zuora__Zuora_Id__c);
		    amendmentObj.setValue('Type', 'NewProduct');
		    amendmentObj.setValue('RatePlanData', getRatePlanData(newDiscountObj));
		    amendmentObj.setValue('Mid_term_Discount_Reason__c',quoteObj.Mid_term_Discount_Reason__c);
		    lstMidTermAmendments.add(amendmentObj);	
		}
		
		return lstMidTermAmendments;	
	}
	
	/*************************************************************************************** 
    Developer   Sally ElGhoul (Accenture)
    Date        25/02/2016
    Function    this function is called to convert the mid term discounts to zuora rate plan data
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    private Zuora.zObject getRatePlanData(OfferDetails newDiscountObj){
		//create Plan Data Object 
		Zuora.zObject ratePlanData = new Zuora.zObject('RatePlanData');
		
		//define the rate plan for rate Plan Data
		Zuora.zObject ratePlan = new Zuora.zObject('RatePlan');
		ratePlan.setValue('ProductRatePlanId', discountProductRatePlanId); //Product Rate plan zuora id
		ratePlanData.setValue('RatePlan', ratePlan);
		
		//the rate plan charges
		//rate plan charge object
    	Zuora.zObject ratePlanCharge = new Zuora.zObject('RatePlanCharge');
	    ratePlanCharge.setValue('ProductRatePlanChargeId',discountProductRatePlanChargeId); //product rate plan charge zuora id
		ratePlanCharge.setValue('BillingPeriod','Month');
		ratePlanCharge.setValue('UpToPeriodsType','Billing Periods');
		ratePlanCharge.setValue('UpToPeriods',newDiscountObj.numberOfPeriod);
		ratePlanCharge.setValue('EndDateCondition','FixedPeriod');
		ratePlanCharge.setValue('Price',(newDiscountObj.discountAmount*-1)); //we apply discounts by adding negative charge
		
		//rate plan charge data object
		Zuora.zObject ratePlanChargeDataObj = new Zuora.zObject('RatePlanChargeData');
		ratePlanChargeDataObj.setValue('RatePlanCharge', ratePlanCharge);
    	ratePlanData.setValue('RatePlanChargeData', new List < Zuora.zObject >{ratePlanChargeDataObj});
		 				
		return ratePlanData;
	}
	
	/*************************************************************************************** 
    Developer   Sally ElGhoul (Accenture)
    Date        25/02/2016
    Function    this function is called to loop on invoices and get the latest discounts to be added 
    ******************* Change Log *******************
    Modified by         Version     Change Date
    Sally ElGhoul		1.1			10/3/2016 change isDiscountApplied to isNewDiscountApplied
    ****************************************************************************************/
    private List<OfferDetails> getLatestMidTermDiscounts(){
		
		List<OfferDetails> lstInsertDiscounts=new List<OfferDetails>();
		Boolean newDiscountFound=false;
		Decimal discountAmount=0;
		OfferDetails newDiscountObj=new OfferDetails();
		Integer counter=0;
		
		for(Zuora_BillingPreviewInvoiceItems invoiceItemObj : lstInvoiceItems){
			counter++;
			
			//if the invoice item shows that there is a discount to be applied and it is the first invoice with discount
			//set the number of periods to one and set the effective date to discount to the invoice date
			if(invoiceItemObj.isNewDiscountApplied && !newDiscountFound){
				newDiscountObj=new OfferDetails();
				newDiscountObj.effectiveDate=invoiceItemObj.invoiceItemDate;
				newDiscountObj.numberOfPeriod=1;
				newDiscountObj.discountAmount=invoiceItemObj.discountAmount;
				newDiscountFound=true;
				discountAmount=newDiscountObj.discountAmount;
			}else if(invoiceItemObj.isNewDiscountApplied && newDiscountFound){ //if the invoice has discount to be applied but it is not the first invoice with discount
				
				//if the discount to be applied for this invoice is the same as the previous invoice, increase the number of periods
				if(discountAmount==invoiceItemObj.discountAmount){
					newDiscountObj.numberOfPeriod++;
				}else{
					
					//if the discount to be applied for the invoice is not the same as the previous incvoice
					//insert the previous discount and create a new discount object
					lstInsertDiscounts.add(newDiscountObj);
					newDiscountObj=new OfferDetails();
					newDiscountObj.effectiveDate=invoiceItemObj.invoiceItemDate;
					newDiscountObj.numberOfPeriod=1;
					newDiscountObj.discountAmount=invoiceItemObj.discountAmount;
					newDiscountFound=true;
					discountAmount=newDiscountObj.discountAmount;
				}
			}else if(!invoiceItemObj.isNewDiscountApplied && newDiscountFound){ //if the invoice shows that there is no discount to be added but we have an offer not added to List of discounts yet, insert this offer
				lstInsertDiscounts.add(newDiscountObj);
				newDiscountFound=false;
				discountAmount=0;
			}	
			
			//if the last invoice has a discount
			if(counter==lstInvoiceItems.size() && newDiscountFound){
				lstInsertDiscounts.add(newDiscountObj);
				newDiscountFound=false;
				discountAmount=0;
			}
		}
		return lstInsertDiscounts;
	}
	
	/*************************************************************************************** 
    Developer   Sally ElGhoul (Accenture)
    Date        25/02/2016
    Function    this function is called to loop on the zAmend results and show either a success or failure message to the user
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    private void handleZAmendResults(Zuora.zApi.AmendResult amendResult){
		if(amendResult.success){
			notificationOptions.backAction = 'goToSubscriptionPage();';
	        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Info, Label.Mid_Term_Discount_Success_Message));
		
		}else{
			notificationOptions.backAction = 'stayOnPage();';
	        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Mid_Term_Discount_Failure_Message));
			for(Zuora.zobject errorObj : amendResult.errors){
				System.debug('Error Occured While adding mid term discounts: Code ('+errorObj.getValue('Code')+'), Field ('+errorObj.getValue('Field')+'), Message: '+errorObj.getValue('Message'));
			}
		}
	}
	
	/*************************************************************************************** 
    Developer   Sally ElGhoul (Accenture)
    Date        25/02/2016
    Function    this function is called to convert the date field from the String format to date value
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    private Date getEffectDateValueFromString(String strEffectiveDate){
		
		String[] dateSplitValues=strEffectiveDate.split('/');
		return Date.newInstance(Integer.valueOf(dateSplitValues[2]),Integer.valueOf(dateSplitValues[1]),Integer.valueOf(dateSplitValues[0]));
			
	}
  	
	/*************************************************************************************** 
    Developer   Sally ElGhoul (Accenture)
    Date        25/02/2016
    Function    Redirect user to subscription page
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    public PageReference goToSubscriptionPage() {
	    return new PageReference('/'+subscriptionID);
	  }
	
	/*************************************************************************************** 
    Developer   Sally ElGhoul (Accenture)
    Date        25/02/2016
    Function    Redirect user to Home page
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/ //Return a page reference to the next page to be navigated to
	  public PageReference goToHomePage() {
	    return new PageReference('/');
	  }
	  
	/*************************************************************************************** 
    Developer   Sally ElGhoul (Accenture)
    Date        25/02/2016
    Function   Keep user on same page
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
	public PageReference stayOnPage(){
	  	return null;
	}
	  
	  /**
	  * Author:       Sally ElGhoul (Accenture)
	  * Date:         25/02/2016
	  * Description:  this class is to keep the details of the discount to be added by the user
 	  *
	  * ******************* Change Log *******************
	  * Modified by       Change Date     
	  * Sally ElGhoul 1.1 8/3/2016 save the charge Zuora id for the mid term discounts added from zuora	
	  **/
	  public Class OfferDetails{
	  	 
	  	 public Date effectiveDate		{get;set;}
	  	 public Integer numberOfPeriod	{get;set;}
	  	 public Decimal discountAmount	{get;set;}
	  	 public Boolean isDelete		{get;set;}
	  	 public String 	chargeZuoraId	{get;set;}
	  	 public Boolean isOldDiscount	{get;set;}
	  	
	  	public OfferDetails(){
	  		isDelete=false;
	  		isOldDiscount=false;
	  	}
	  }
}