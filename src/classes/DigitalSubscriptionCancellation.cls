/**
* @author Cristina Popescu
* @date 16/06/2015
* @description 	Cancellation Reason Tracking for Digital Subs
#############Change Log#############
Modified by     	Version    Change Date
Cristina Anghenie	1.1		   24/08/2015	//stop soft cancellation functionality to create multiple cancellation record for the same subscription
Cristina Anghenie	1.2		   28/09/2015	//update hardCancellation() to display when no amount is refunded
Mantas Grigaliunas  1.3        31/01/2017   //modified processMigratedSubscriptionCancellation() after RefundOrder method change in MppInterfaceHTTP
**/
global class DigitalSubscriptionCancellation {
    public Boolean displayPopUp { get;set; }
    public Boolean wasCancelled { get;set; }
    public Id accountId			{ get;set; }
    public String cancelationType; 
    public String cancelationMsg; 
    public Cancellation__c cancellation;    
    
    public static final String REASON_TYPE_PRICE = 'Price';
    public static final String REASON_TYPE_OTHER = 'Other';
    
    public DigitalSubscriptionCancellation(ApexPages.StandardController ctrl){
        this.cancellation = (Cancellation__c)ctrl.getRecord();

        displayPopUp = true;
        wasCancelled = false;
        try{
	        accountId = ApexPages.CurrentPage().getparameters().get('accId');
	        cancelationType = ApexPages.CurrentPage().getparameters().get('type');
        }catch(System.Exception e){
	         ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, Label.No_Account));
	    }
    }
    
    /************************************************************************************
    Developer - Cristina Popescu
    Date - 16/06/2015
    Version - 1.0
    Function - method that get called after reason for cancellation is selected
    #############Change Log#############
    Modified by     Version     Change Date
    Cristina A		1.1			29/09/2015	//if no refund is given display message as confirmation msg	
    *************************************************************************************/
    public void save(){
        if (accountId!=null){
        	if (cancelationType == Constants.SHORT_SOFT_CANCELLATION){
	            cancelationMsg = softCancellation(accountId);
	            if (cancelationMsg == Label.Subscriptions_Cancelled){
	                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, cancelationMsg));
	            }else ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, cancelationMsg));
        	} else if (cancelationType == Constants.SHORT_HARD_CANCELLATION){
                cancelationMsg = hardCancellation(accountId);
                if (cancelationMsg == Label.Subscriptions_Cancelled){
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, cancelationMsg));
                } else if (cancelationMsg.contains(Label.Subscriptions_Cancelled_With_Refund) || cancelationMsg.contains(Label.Subscriptions_Cancelled_With_NoRefund)) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, cancelationMsg));
                } else ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, cancelationMsg));
            }
        }
    }
    
    /************************************************************************************
    Developer - Cristina Popescu
    Date - 19/06/2015
    Version - 1.0
    Function - return to account page layout
    #############Change Log#############
    Modified by     Version     Change Date
    *************************************************************************************/
    public PageReference back(){
    	displayPopUp = false;
    	PageReference pageRef = new PageReference('/' + accountId);
        pageRef.setRedirect(true);
        return pageRef;
    }
    
    /************************************************************************************
    Developer - Cristina Popescu
    Date - 16/06/2015
    Version - 1.0
    Function - method that cancels the subscription at the end of it
    #############Change Log#############
    Modified by     	Version     Change Date
    Cristina Anghenie 	1.1			24/08/2015	//stop soft cancellation functionality to create multiple cancellation record for the same subscription
    *************************************************************************************/
    public String softCancellation(Id accId){
        MPPInterfaceHTTP mpp = new MPPInterfaceHTTP();
        MPPInterfaceHTTP.AutoRenewResult result;
        set<String> paymentStatus = new set<String>{Constants.ORDER_SUCCESS_STATUS_VALUE, Constants.ORDER_PENDING_STATUS_VALUE};
        
        List<account> acc = [SELECT MPP_Service_Id__c, Subscriber_Number_static__c, Subscriber_Digital_Status__c,
	            				  (SELECT Id, Order_Id__c,Payment_status__c 
	            				   FROM MPP_Transaction_Histories__r 
	            		   		   WHERE Payment_Status__c IN: paymentStatus AND DD_Transaction_Type__c !=: 'AUDDIS'
	            		   		   ORDER BY CreatedDate DESC LIMIT 1) 
	            		     FROM Account 
	            		     WHERE Id =:accId];
	            		     
	    //Check transaction histories, there should be at least one successful.
        if(acc[0].MPP_Transaction_Histories__r.isEmpty()){
            return Label.No_Transaction_History;
        }
        
	    List<Cancellation__c> canxs = [SELECT Id, MPP_Transaction_History__c, Account__c, Cancellation_Status__c
	    							   FROM Cancellation__c 
	    							   WHERE MPP_Transaction_History__c =: acc[0].MPP_Transaction_Histories__r[0].Id 
	    							   AND Account__c =: accId
	    							   AND Cancellation_Status__c =: Constants.COMPLETE_CANCELLATION_STATUS];
	    if(canxs.size()>0){
	    	return Label.Cancellation_AlreadyCreated;
	    }
		//cancellation reason is required
        if (String.IsBlank(cancellation.Cancellation_Reason__c)){
            return Label.Reason_Cancellation;
        }
        //other reason is required when cancellation reason is PRICE
        if (cancellation.Cancellation_Reason__c == REASON_TYPE_PRICE && String.IsBlank(cancellation.Reason_Details__c)){
            return Label.Details_Reason_Cancellation;
        }
        //detail field is required when reason is other
        if (cancellation.Reason_Details__c == REASON_TYPE_OTHER && String.IsBlank(cancellation.Other_Reason__c)){
            return Label.Other_Reason_Details;
        }
        
        if (!acc.isEmpty()){
	        // Check digital status
	        if(acc[0].Subscriber_Digital_Status__c == Constants.SSTATUS_INACTIVE){
	            return Label.Cancel_Inactive_account;
	        }
	        
	        if(String.IsBlank(acc[0].MPP_Service_Id__c)){           
	            return Label.Wrong_Service_ID;
	        }
	            
	        try{
	            result = mpp.AutoRenewSubscriber(acc[0].Subscriber_Number_static__c, acc[0].MPP_Service_Id__c, 'false');
	        } catch(MPPInterfaceHTTP.MPPInterfaceHTTPException mppE){
	            return Label.MPP_Error + ' ' + mppE.getMessage();
	        }catch(System.Exception e){
	            System.debug(e);
	            return Label.Error_Message + e;
	        }
	
	        if (result != null && result.autoRenewEnabled != null && !result.autoRenewEnabled){
	            cancelationMsg = Label.Subscriptions_Cancelled;
	            createUpdateRecordsForCancelation(acc[0],Constants.SOFT_CANCELLATION,acc[0].MPP_Transaction_Histories__r[0].Id,cancellation);
	            wasCancelled = true;
	        }else{
	            cancelationMsg = Label.Error_Message + result;
	        }
        }else cancelationMsg = Label.No_Account;
        return cancelationMsg;      
    }
    
    /************************************************************************************
    Developer - Cristina Popescu
    Date - 16/06/2015
    Version - 1.0
    Function - method that cancels the subscription and does the refund(if any)
    #############Change Log#############
    Modified by         Version     Change Date
    Cristina A.		    1.1			28/09/2015	//update method to display when there is no amount to be refunded
    Mantas Grigaliunas  1.1         31/01/2017  //method name changed from RefundOrder to processRefundOrder and returned result changed to list
    *************************************************************************************/
    public String hardCancellation(Id accId){
        MPPInterfaceHTTP mpp = new MPPInterfaceHTTP(); 
        MPPInterfaceHTTP.CancelSubscriptionResult cancelResult;
        MPPInterfaceHTTP.RefundOrderResult refundResult;
        Boolean updateAccount = false;
        
        set<String> paymentStatus = new set<String>{Constants.ORDER_SUCCESS_STATUS_VALUE, Constants.ORDER_PENDING_STATUS_VALUE};
        
        List<Account> acc = [SELECT MPP_Service_Id__c, Subscriber_Number_static__c, Subscriber_Digital_Status__c,
	            				  (SELECT Id, Order_Id__c,Payment_status__c 
	            				   FROM MPP_Transaction_Histories__r 
	            		   		   WHERE Payment_Status__c IN: paymentStatus AND DD_Transaction_Type__c !=: 'AUDDIS'
	            		   		   ORDER BY CreatedDate DESC LIMIT 1) 
	            		     FROM Account 
	            		     WHERE id =:accId];
	    if (!acc.isEmpty()){    
	        // Check digital status
	        if(acc[0].Subscriber_Digital_Status__c == Constants.SSTATUS_INACTIVE){
	            return Label.Cancel_Inactive_account;
	        }
	        //cancellation reason is required
	        if (String.IsBlank(cancellation.Cancellation_Reason__c)){
	            return Label.Reason_Cancellation;
	        }
	        //other reason is required when cancellation reason is PRICE
	        if (cancellation.Cancellation_Reason__c == REASON_TYPE_PRICE && String.IsBlank(cancellation.Reason_Details__c)){
	            return Label.Details_Reason_Cancellation;
	        }
	        //detail field is required when reason is other
	        if (cancellation.Reason_Details__c == REASON_TYPE_OTHER && String.IsBlank(cancellation.Other_Reason__c)){
	            return Label.Other_Reason_Details;
	        }
	         
	        //Check transaction histories, there should be at least one successful.
	        if(acc[0].MPP_Transaction_Histories__r.isEmpty()){
	            return Label.No_Transaction_History;
	        }
	        
	        String serviceId = acc[0].MPP_Service_Id__c;
	        String orderId = acc[0].MPP_Transaction_Histories__r[0].Order_Id__c;
	        String TSNumber = acc[0].Subscriber_Number_static__c; 
	
			//check for existing serviceID
	        if(!TMGUtil.isDataValid(serviceId)){           
	            return Label.Wrong_Service_ID;
	        }
	        
	        //check for valid orderID
	        if(!TMGUtil.isDataValid(orderId)){
	            return Label.No_Order_ID;
	        }
	                            
	        try{
	            cancelResult = mpp.RemoveSubscription(TSNumber, serviceId);
	        } 
	        catch(MPPInterfaceHTTP.MPPInterfaceHTTPException mppE){
	            if((mppE.getErrorCode().contains('404')||mppE.getErrorCode().contains('503'))){
	                return Label.Remove_Subscription_Error + Label.MPP_404_Error_Message;
	            }else return Label.Remove_Subscription_Error + ' - ' +  mppE.getErrorMessage();
	        }catch(System.Exception e){
	            return Label.Remove_Subscription_Error + ((e.getMessage().contains('404')||e.getMessage().contains('503')) ? Label.MPP_404_Error_Message: e.getMessage());
	        }
	        
	        if(TMGUtil.isDataValid(cancelResult) && cancelResult.status == Constants.CANCELLATION_STATUS_REMOVED){
	            cancelationMsg = Label.Subscriptions_Cancelled;
	            updateAccount = true;
	            //Now try refund if there is deferred revenue.
	            if(TMGUtil.isDataValid(cancelResult.deferredRevenue) 
	                && Decimal.valueOf(cancelResult.deferredRevenue) > 0)
	            {
	                try{
	                    refundResult = mpp.processRefundOrder(TSNumber, orderId, Decimal.valueOf(cancelResult.deferredRevenue));
	                }catch(MPPInterfaceHTTP.MPPInterfaceHTTPException mppE){
	                    return Label.Refund_Error_Msg + ' - ' + mppE.getErrorMessage();
	                }catch(System.Exception e){
	                   return Label.Refund_Error_Msg + e.getMessage();
	                }
	            }else cancelationMsg = Label.Subscriptions_Cancelled_With_NoRefund;   
	        }
	        
	        if(TMGUtil.isDataValid(refundResult)){
	            cancelationMsg = Label.Subscriptions_Cancelled_With_Refund + ' £' + Decimal.valueOf(refundResult.refundAmount).setScale(2);
	            updateAccount = true;
	        }
	        
	        if(updateAccount){
	        	acc[0].Subscriber_Digital_Status__c = Constants.SSTATUS_INACTIVE;
	            createUpdateRecordsForCancelation(acc[0],Constants.HARD_CANCELLATION,acc[0].MPP_Transaction_Histories__r[0].Id,cancellation);
	            wasCancelled = true;
	        }
        } else cancelationMsg = Label.No_Account;
        return cancelationMsg;     
    }
    
    /************************************************************************************
    Developer - Cristina Popescu
    Date - 16/06/2015
    Version - 1.0
    Function - create cancellation record and update account when subscription is cancelled
    #############Change Log#############
    Modified by     Version     Change Date
    *************************************************************************************/
    public void createUpdateRecordsForCancelation(Account acc, String cancellationType, Id transHistoryId, Cancellation__c cancellation){
        try{
            //create cancellation record
            Cancellation__c cancelSub = new Cancellation__c();
            cancelSub.Account__c = acc.Id;
            cancelSub.Cancellation_Type__c = cancellationType;
            cancelSub.Cancelled_By__c = UserInfo.getUserId();
            cancelSub.Cancelled_Date__c = Date.today();
            cancelSub.MPP_Transaction_History__c = transHistoryId;
            cancelSub.Cancellation_Reason__c = cancellation.Cancellation_Reason__c;
            cancelSub.Reason_Details__c = cancellation.Reason_Details__c;
            cancelSub.Other_Reason__c = cancellation.Other_Reason__c;
            cancelSub.Cancellation_Status__c = Constants.COMPLETE_CANCELLATION_STATUS;
            insert cancelSub;
            
            //update account
            acc.Cancellation_Type__c = cancellationType;
            acc.Cancelled_By__c = UserInfo.getUserId();
            acc.Cancelled_Date__c = Date.today();
            update acc;
        }
        catch(System.Exception e){
            System.debug(e);
        }
    }
    
    /************************************************************************************
    Developer - unknown
    Date - unknown
    Version - 1.0
    Function - reactivate digital subscription after was cancelled
    #############Change Log#############
    Modified by     	Version     Change Date
    Cristina Anghenie	1.1			26/08/2015	//move functionality from SubscriptionsAccountManagement and revoke the existing cancellation record
    *************************************************************************************/
    WebService static string ReactivateSubscription(Id accId){
        MPPInterfaceHTTP mpp = new MPPInterfaceHTTP(); 
        MPPInterfaceHTTP.AutoRenewResult result;
        String message;     
        
        Account acc = [SELECT MPP_Service_Id__c, Cancellation_Type__c, Subscriber_Number_static__c, Subscriber_Digital_Status__c 
        			   FROM Account 
        			   WHERE Id =: accId];
        // Check digital status
        if(acc.Cancellation_Type__c != Constants.SOFT_CANCELLATION){
            return Label.Cancellation_ReactivationOnSoft;
        }
        
        List<Cancellation__c> canxs = [SELECT Id, Account__c, CreatedDate, Cancellation_Status__c
	    							   FROM Cancellation__c 
	    							   WHERE Account__c =: accId
	    							   AND Cancellation_Status__c =: Constants.COMPLETE_CANCELLATION_STATUS
	    							   ORDER BY CreatedDate DESC
	    							   LIMIT 1];
	    if(canxs.isEmpty()){
	    	return Label.Cancellation_NoCancellationToRevoke;
	    }
        
        String serviceId = acc.MPP_Service_Id__c;
        String TSNumber = acc.Subscriber_Number_static__c;
        
        if(String.IsBlank(serviceId)){           
            return Label.Wrong_Service_ID;
        }
            
        try{
            result = mpp.AutoRenewSubscriber(TSNumber, serviceId, 'true');
        }catch(MPPInterfaceHTTP.MPPInterfaceHTTPException mppE){
            return Label.MPP_Error + mppE;
        }catch(System.Exception e){
            System.debug(e);
            return Label.Cancellation_SFDC_Error + e;
        }
        
        if(result != null && result.autoRenewEnabled){
            message = Constants.REACTIVATION_SUCCESSFULL;
            //update cancellation status to revoked once subs has been renewed
            canxs[0].Cancellation_Status__c = Constants.REVOKED_CANCELLATION_STATUS;
            update canxs[0];
            //update details on the account
            acc.Cancellation_Type__c = null;
            acc.Cancelled_By__c = null;
            acc.Cancelled_Date__c = null;
            update acc;
        }else{
            message = Label.Error_Message + result;
        }
        return message;      
    }
}