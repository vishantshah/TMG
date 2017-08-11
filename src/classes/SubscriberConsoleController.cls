/* ------------------------------------------------------------------------------
   Name:        SubscriberConsoleController.cls
   Description: Controller class for SubscriberConsole.page  

   Date         Version Author                      Summary of Changes 
   -----------  ------- -----------------   -------------------------------------
   18/11/2013       1.0    Chris Yorkston   Intial Release
   13/05/2015       1.1    Wiktor Czykin    Added fixTSNumberInMPP() action method, modified constructor, some other minor changes 
   17/07/2015       1.2    Wiktor Czykin    Added fixGuidInMPP() action method 
   29/07/2015       1.3    Cristina Anghenie Fix diagnostic console issue for digital subscriber   
   22/09/2015		1.4	   Cristina Anghenie Display a custom error message if email doest exist in SAM	 
   04/11/2015		1.5	   Wiktor Czykin	Modified doGUIDFix() - error visibility 
--------------------------------------------------------------------------------- */
public class SubscriberConsoleController {
	
    public Account subscriber {get;set;}
    public Account subscriberAccount {get;set;}   
    public String tsNumber {get;set;}
    
    public Boolean dataInSF {get;set;}
    public Boolean dataInMPP {get;set;}
    public Boolean dataInSAM {get;set;}
    public Boolean showConsole {
    	get {
    		if (showConsole == null) {
    			showConsole = true;
    		}
    		return showConsole;
    	}
    	set;
    }
    public Boolean problemFixed {
    	get {
    		if (problemFixed == null) {
    			problemFixed = false;
    		}
    		return problemFixed;
    	}
    	set;
    }
    public String fixProblemReloaded {
    	get {
    		if (fixProblemReloaded == null) {
    			fixProblemReloaded = Label.FixProblemButton;
    		}
    		if (reloading) {
    			fixProblemReloaded = Label.SuccessReloadingButton;
    		}
    		return fixProblemReloaded;
    	}
    	set;
    }
    public Boolean reloading {
    	get {
    		if (reloading == null) {
    			reloading = false;
    		}
    		return reloading;
    	}
    	set;
    }
    public String fixRuleLabel {
    	get {
    		//Add else if for future fixes
    		if (fixRule == Fixes.GUID) {
    			fixRuleLabel = Label.FixGUIDError;
    		}
    		else {
    			fixRuleLabel = Label.FixProblemDefaultDialog;
    		}
    		return fixRuleLabel;
    	}
    	set;
    }
    public String alternateFixLabel {
    	get {
    		//Add else if for future fixes
    		if (fixRule == Fixes.GUID && alternateFixNeeded) {
    			alternateFixLabel = Label.alternateFixGUID;
    		}
    		else {
    			alternateFixLabel = Label.AlternateFixDefaultDialog;
    		}
    		return alternateFixLabel;
    	}
    	set;
    }
    public Boolean alternateFixNeeded {
    	get {
    		if (alternateFixNeeded == null) {
    			alternateFixNeeded = false;
    		}
    		return alternateFixNeeded;
    	}
    	set;
    }
    public Fixes fixRule {get;set;}
    public String mppGuid {get;set;}
    public String SAMGuid {get;set;}
    public String mppSAMGuid {get;set;}
    public String mppTSNumber {get;set;}
    public String email {get;set;}
    public String ErrorLabel {get;set;}
    public String EntitlementErrorLabel {get;set;}
    public String confirmMessage {get;set;}
    public String orderIdToFix {get;set;}
    public String paymentDateToFix {get;set;}
    public String netAmount {get;set;}
	public String newEntitlementForFix {get;set;}
    public String ruleName {get;set;}
    public String ruleUserMessage {get;set;}
    public String ruleCode {get;set;}
    public String ruleResultCode {get;set;}
    public String ruleData {get;set;}
    
    public SamWrapper samUserWrapper {get;set;}
    public MppUserWrapper mppUserWrapper {get;set;}
    public List<Task> reportedTasks {get;set;}
    
    public List<OrderHistoryItemWrapper> orderHistoryItemWrappers {get;set;}
    public String mppTotalNumberOfOrders {get;set;}
    
    public List<MPP_Transaction_History__c> mppTransactionHistory {get;set;}
    public Integer sfTotalNumberOfOrders {get;set;}
    
    public List<ResultWrapper> resultWrappers {get;set;}
    
    //Styles for problem fixing
    public String salesforceGUIDstyle {get;set;}
    public String MPPSAMGUIDstyle {get;set;}
    public String salesforceTSNumberStyle {get;set;}
    public String MPPTSNumberStyle {get;set;}
    public String ErrorStyle {
    	get {
    		return redStyle;
    	}
    }
    public String ConfirmStyle {
    	get {
    		return greenStyle;
    	}
    }
    @TestVisible private static final String greenStyle = 'color:green;font-weight:bold;';
    @TestVisible private static final String orangeStyle = 'color:orange;font-weight:bold;';
    @TestVisible private static final String redStyle = 'color:red;font-weight:bold;';
    
    private User sysAdmin;

    //  Entitlements management tab variables
    @TestVisible private Set<String> setAvailableEntitlements;
    public List<SelectOption> AvailableEntitlementsForDisplay{
        get{
            List<SelectOption> displayData = new List<SelectOption>();
            for(String entitlement : setAvailableEntitlements){
                displayData.add(new SelectOption(entitlement, entitlement));
            }
            displayData.sort();
            return displayData;
        }
    }
    public String[] AvailableSelected {get; set;}
    
    @TestVisible public Set<String> setCurrentEntitlements;
    public List<SelectOption> CurrentEntitlementsForDisplay{
        get{
            List<SelectOption> displayData = new List<SelectOption>();
            
            for(string entitlement : setCurrentEntitlements){
                displayData.add(new SelectOption(entitlement, entitlement));
            }
            displayData.sort();
            return displayData;
        }
    }
    public String[] CurrentSelected {get; set;}
    
    
    public SubscriberConsoleController() {}
    
    /*************************************************************************************** 
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Function - Constructor if extension
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         13/05/2015  //added extra fields to soqls
    ****************************************************************************************/
    public SubscriberConsoleController(ApexPages.StandardController stdController) {
    	SubscriberConsoleSettings__c consoleSettings = SubscriberConsoleSettings__c.getOrgDefaults();
    	List<User> lstUser = [select Id from User where Name = :consoleSettings.Guid_Task_Recipient__c limit 1];
        if(!lstUser.isEmpty()){
            sysAdmin = lstUser[0];
        }else{
            throw new ChangeEntitlementException(Label.Diagnostic_Console_Missing_custom_settings);
        }

        this.subscriber = (Account)stdController.getRecord();
        this.subscriberAccount = [select    Id, 
                                            Name, 
                                            FirstName, 
                                            LastName, 
                                            Subscriber_Number_Static__c, 
                                            Guid__c, 
                                            PersonContactId, 
                                            PersonEmail 
                                        from Account 
                                        where Id = :this.Subscriber.Id];
            
        this.tsNumber = this.subscriberAccount.Subscriber_Number_static__c;
        this.callWebService();
        
        //Set up the data for the entitlements management tab
        this.initialiseEntitlementsTab();
    }
    
    @TestVisible private void initialiseEntitlementsTab(){
    	AvailableSelected = new String[]{};
    	CurrentSelected = new String[]{};
    	
        loadCurrentEntitlements();
        loadAvailableEntitlementsPickListData();
    }
   
    private void loadCurrentEntitlements(){
        this.setCurrentEntitlements = new Set<String>();
        if(samUserWrapper != null && samUserWrapper.samAccountResult != null && samUserWrapper.samAccountResult.entitlements != null){
			this.setCurrentEntitlements.addAll(samUserWrapper.samAccountResult.entitlements);
        }
    }
   
    private void loadAvailableEntitlementsPickListData(){
        this.setAvailableEntitlements = new Set<String>();
        for (SAM_Entitlement__c dataItem : SAM_Entitlement__c.getAll().values()) {
        	String entitlement = dataItem.Name;
            if(!setCurrentEntitlements.contains(entitlement)){
                this.setAvailableEntitlements.add(entitlement);
            }
        }
    }
    
    public PageReference AddEntitlements(){
        UpdateEntitlements(true, false);
        return null;
    }
    
    public PageReference RemoveEntitlements(){
        UpdateEntitlements(false, true);
        return null;
    }
    
    public void UpdateEntitlements(boolean addEntitlements, boolean removeEntitlements){
    
    	//The lists could be updated simultaneously, but,  the client specifcally requested that this did not happen
    	System.debug('***AvailableSelected: ' + AvailableSelected);
    	System.debug('***CurrentSelected: ' + CurrentSelected);

    	try{
			Set<String> entitlements = new Set<String>();
			
	    	if(!AvailableSelected.isEmpty() && addEntitlements){
	    		entitlements.addAll(AvailableSelected);
	    		SAMInterfaceHTTP.bulkUpdateResponse response = SAMInterfaceHTTP.updateSubscriptionEntitlement(subscriberAccount.PersonEmail, SAMGuid, entitlements, SAMInterfaceHTTP.EntitlementUpdateType.ADD);
	    		
	    		if(response.statusCode != SAMInterfaceHTTP.ResponseStatusCodes.SUCCESS){
	    			throw new ChangeEntitlementException(response.message == Label.SubscriberDiagnostic_InvalidCredentials ? Label.SubscriberDiagnostic_NoSAMAccount : response.message);
	    		}
	    		
	    	}
	    	
	    	if(!CurrentSelected.isEmpty() && removeEntitlements){
	    		entitlements.addAll(CurrentSelected);
	    		SAMInterfaceHTTP.bulkUpdateResponse response = SAMInterfaceHTTP.updateSubscriptionEntitlement(subscriberAccount.PersonEmail, SAMGuid, entitlements, SAMInterfaceHTTP.EntitlementUpdateType.REMOVE);
	    		
	    		if(response.statusCode != SAMInterfaceHTTP.ResponseStatusCodes.SUCCESS){
	    			throw new ChangeEntitlementException(response.message == Label.SubscriberDiagnostic_InvalidCredentials ? Label.SubscriberDiagnostic_NoSAMAccount : response.message);
	    		}
	    	}

	    	//Move the list items around
            if(removeEntitlements){
                for(string selected : CurrentSelected){
                    this.setCurrentEntitlements.remove(selected);
                    this.setAvailableEntitlements.add(selected);
                }
            }
            
            if(addEntitlements){
                for(string selected : AvailableSelected){
                    this.setAvailableEntitlements.remove(selected);
                    this.setCurrentEntitlements.add(selected);
                }
            }
	    	
	    	//Now clean the selected lists
	    	AvailableSelected = new string[]{};
	    	CurrentSelected = new string[]{};
    	} catch(Exception ex){
    		ApexPages.Message errMsg = new ApexPages.Message(ApexPages.Severity.FATAL,'Error: ' + ex.getMessage());
    		ApexPages.addMessage(errMsg);
    	}
    }
    
    public void callWebService() {
        subscriberConsoleWebservice.subscriberIdentifier subIdentifier = new subscriberConsoleWebservice.subscriberIdentifier('TSNUMBER', this.tsNumber);
        
        try {
            subscriberConsoleWebservice.subscriberOverviewResult subscriberOverviewResult = subscriberConsoleWebservice.subscriberOverview(subIdentifier);
        
            
            dataInSF = subscriberOverviewResult.dataAvailableInSF;
            dataInMPP = subscriberOverviewResult.dataAvailableInMPP;
            dataInSAM = subscriberOverviewResult.dataAvailableInSAM;
              
            // misc
            if(subscriberOverviewResult.MPPGuid!=null)
                mppGuid = subscriberOverviewResult.MPPGuid;
               
            if(subscriberOverviewResult.Email!=null)
                email = subscriberOverviewResult.Email;     
            
            // sam
            if(subscriberOverviewResult.SAMGuid !=null) {
            	SAMGuid = subscriberOverviewResult.SAMGuid;
                samUserWrapper = new SamWrapper(subscriberOverviewResult.samAccountAndEntitlementInfo);
            }
 
          
            
            if(subscriberOverviewResult.validateMPPResult != null)
            { 
	            // used for entitlement fixes
	            if(subscriberOverviewResult.validateMPPResult.mppSAMGuid!=null)
	 	           mppSAMGuid = subscriberOverviewResult.validateMPPResult.mppSAMGuid;
	            if(subscriberOverviewResult.validateMPPResult.mppTSNumber!=null)
	               mppTSNumber = subscriberOverviewResult.validateMPPResult.mppTSNumber;
            }
            
            // mpp user
            if(subscriberOverviewResult.MPPGuid != null)
            {
                MPPInterfaceHTTP.AccountDetailParameters tsNumberValues = new MPPInterfaceHTTP.AccountDetailParameters();
                MPPInterfaceHTTP.AccountDetailParameters guidValues = new MPPInterfaceHTTP.AccountDetailParameters();
                                        
                tsNumberValues.ParameterName = 'TSNumber';
                tsNumberValues.ParameterValue = 'Not Found';
                guidValues.ParameterName = 'SAM_Guid';
                guidValues.ParameterValue = 'Not Found';
                
                
                if(subscriberOverviewResult.mppUserInfo.AccountDetailParameters.size() <= 0)
                {                 
                  subscriberOverviewResult.mppUserInfo.AccountDetailParameters.add(tsNumberValues);
                  subscriberOverviewResult.mppUserInfo.AccountDetailParameters.add(guidValues);
                }  
                       
                if(subscriberOverviewResult.mppUserInfo.AccountDetailParameters.size() >= 1)
                {
                    if(subscriberOverviewResult.mppUserInfo.AccountDetailParameters[0].ParameterName == 'TSNumber')
                         subscriberOverviewResult.mppUserInfo.AccountDetailParameters.add(guidValues);             
                
                    if(subscriberOverviewResult.mppUserInfo.AccountDetailParameters[0].ParameterName == 'SAM_Guid')
                         subscriberOverviewResult.mppUserInfo.AccountDetailParameters.add(tsNumberValues);             
                
                }
            
                mppUserWrapper = new MppUserWrapper(subscriberOverviewResult.mppUserInfo);
                
            }
            
            // mpp orders
            if(subscriberOverviewResult.MPPGuid != null)
            {
                orderHistoryItemWrappers = new List<OrderHistoryItemWrapper>();
               
                if(subscriberOverviewResult.mppUserOrderHistory.OrderHistoryItems != null)
                for (MPPInterfaceHTTP.OrderHistoryItem ohi :subscriberOverviewResult.mppUserOrderHistory.OrderHistoryItems) {
                    orderHistoryItemWrappers.add( new OrderHistoryItemWrapper( ohi ) );
                }
            mppTotalNumberOfOrders = subscriberOverviewResult.mppUserOrderHistory.TotalNumberOfOrders;
            }
            
            // sf orders
            if(subscriberOverviewResult.sfOrderInformation != null)
            {
                mppTransactionHistory = subscriberOverviewResult.sfOrderInformation;
	            sfTotalNumberOfOrders = mppTransactionHistory.size();
            }  
            system.debug('*** EVERYTHING OK AFTER SFORDERINFO');      
            // result           
            resultWrappers = new List<ResultWrapper>();
            for (subscriberConsolesWebserviceHandlers.subscriberRuleLog rl :subscriberOverviewResult.subscriberRuleLog) {
                Boolean err = (Integer.valueOf(rl.ruleResultCode) >= 500) ? true : false;
                Boolean rep = (Integer.valueOf(rl.ruleResultCode) == 501) ? true : false;
                resultWrappers.add( new ResultWrapper(rl, err, rep, 'http://www.google.co.uk/') );
            }
            
            // Reported Issues
	  		reportedTasks = [SELECT Id, Subject, Status, WhatId, WhoId, CreatedDate FROM Task WHERE WhatId = :subscriberOverviewResult.sfAccountInformation.Id AND Subject LIKE '%Technical Issue -%'];
            
        }catch (Exception e) {
            System.debug(e);
        }
    }
    
    public void refreshAll() {
        callWebService();
    }
    
    //Added to fix action="{!report}": Unknown method 'AccountStandardController.report()'  error being thrown
    public PageReference report() {
        return null;
    }
    
    public PageReference fixOrderHistoryDataInSFDCFromMPP() {
        Pagereference pr = new Pagereference(
            '/apex/page/subscriberDiagnosticsMppTxHistoryFix?orderId='+orderIdToFix
            +'&accountId='+subscriberAccount.Id
            +'&paymentDate='+paymentDateToFix
            +'&saleType=Success'
            +'&netAmount='+netAmount
            +'&retURL=/apex/page/SubscriberDiagnostics?id='+subscriberAccount.Id
        );
        pr.setRedirect(true);
        return pr;
    }

    /*************************************************************************************** 
    Developer - Wiktor Czykin
    Date - 13/05/2015
    Version - 1.1
    Function - Fix that pushes TSNumber to MPP based on email address. 
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public void fixTSNumberInMPP(){
        MPPInterfaceHTTP mppInterface = new MPPInterfaceHTTP();

        if(String.isBlank(this.subscriberAccount.PersonEmail)){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Diagnostic_Console_TSNumber_fix_email_required));
            return;
        }

        MppInterfaceHTTP.UserInfoResult refetchedAccountFromMPP;
        try{
            refetchedAccountFromMPP = subscriberConsolesWebserviceHandlers.retrieveUserInfoResultForEmailAndDoNotLogWebserviceCall(this.subscriberAccount.PersonEmail);
        }catch(Exception e){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Diagnostic_Console_Unable_to_fetch_account_from_mpp_based_on_email));
            return;
        }
        //get ts number for the retrieved record from MPP
        String sTSNumber;
        if(refetchedAccountFromMPP.AccountDetailParameters != null){
            for(MPPInterfaceHTTP.AccountDetailParameters accDetails : refetchedAccountFromMPP.AccountDetailParameters){ 
                if(accDetails.ParameterName == Constants.MPP_PARAMETER_TSNUMBER){
                    sTSNumber = accDetails.ParameterValue;
                }
            }
        }
        MPPInterfaceHTTP.UserManageResult umr;
        if(sTSNumber != this.subscriberAccount.Subscriber_Number_static__c){
            try{
                umr = mppInterface.userManagePartialAccountBased(this.subscriberAccount, new Set<String>{'PersonEmail', 'Subscriber_Number_static__c'});
            }catch(Exception e){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Diagnostic_Console_Unable_to_update_MPP_based_on_email));
                return;
            }
        }else{
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.Diagnostic_Console_TSNumber_fix_not_applicable));
        	return;
        }


        //check guid and add message if not there
        if(String.isNotBlank(umr.guid)){
            //find the log we are fixing and set it to fixed
            for(ResultWrapper rw : resultWrappers){
                if((rw.subscriberRuleLog.ruleCode == Constants.MPP_RULE_NAME_ID_FIELDS_EXIST && rw.subscriberRuleLog.ruleResultCode == Constants.MPP_RULE_ID_FIELDS_EXIST_TSNUMBER_FAIL) 
                    || (rw.subscriberRuleLog.ruleCode == Constants.MPP_RULE_NAME_ID_FIELDS_INSYNC && rw.subscriberRuleLog.ruleResultCode == Constants.MPP_RULE_ID_FIELDS_INSYNC_TSNUMBER_FAIL)){
                    
                    rw.isError = false;
                    subscriberValidationRuleInfov2__c ruleSetting = subscriberValidationRuleInfov2__c.getInstance(rw.subscriberRuleLog.ruleCode);
                    String sFieldName = 'X'+Constants.MPP_RULE_ID_FIELDS_INSYNC_TSNUMBER_SUCCESS+'__c';
                    if(ruleSetting != null && ruleSetting.get(sFieldName) != null){
                        rw.subscriberRuleLog.ruleUserMessage = (String) ruleSetting.get(sFieldName);
                    }
                }
            }
        }else{
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.Diagnostic_Console_TSNumber_fix_unable_to_update_MPP_unknown_response));
        }
        return;
    }

    /*************************************************************************************** 
    Developer - Wiktor Czykin
    Date - 18/07/2015
    Version - 1.0
    Function - Fix that sets Guid in sfdc (if blank) and pushes the same to MPP -> SAM is the master of Guids ;)
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public void fixGuidInMPP(){
        MPPInterfaceHTTP mppInterface = new MPPInterfaceHTTP();

        if(String.isBlank(this.subscriberAccount.PersonEmail)){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Diagnostic_Console_Guid_fix_email_required));
            return;
        }
        
        MppInterfaceHTTP.UserInfoResult refetchedAccountFromMPP;
        try{
            refetchedAccountFromMPP = subscriberConsolesWebserviceHandlers.retrieveUserInfoResultForEmailAndDoNotLogWebserviceCall(this.subscriberAccount.PersonEmail);
        }catch(Exception e){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Diagnostic_Console_Unable_to_fetch_account_from_mpp_based_on_email));
            return;
        }

        SAMUtil su = new SAMUtil();
        SAMUtil.SAMAccountResult refetchedGuidFromSAM;
        String sGuid;
        Boolean bUpdateAccount = false;

        try{
            refetchedGuidFromSAM = su.getExistingSAMAccount(this.subscriberAccount.PersonEmail);
            if(refetchedGuidFromSAM != null && String.isNotBlank(refetchedGuidFromSAM.guid)){
                sGuid = refetchedGuidFromSAM.guid;
            }  
        }catch(Exception e){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Diagnostic_Console_Error_retrieving_guid_from_sam_based_on_email));
            return;
        }

        if(String.isBlank(sGuid)){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Diagnostic_Console_Empty_GUID_retrieved_from_SAM));
            return;
        }

        if(String.isBlank(this.subscriberAccount.Guid__c) || !this.subscriberAccount.Guid__c.equals(sGuid)){
            bUpdateAccount = true;
        }
        this.subscriberAccount.Guid__c = sGuid; //setting guid on object either way as object is passed to MPP update method

        //get guid number for the retrieved record from MPP
        String sMPPGuid;
        if(refetchedAccountFromMPP.AccountDetailParameters != null){
            for(MPPInterfaceHTTP.AccountDetailParameters accDetails : refetchedAccountFromMPP.AccountDetailParameters){ 
                if(accDetails.ParameterName == Constants.MPP_PARAMETER_SAMGUID){
                    sMPPGuid = accDetails.ParameterValue;
                }
            }
        }

        MPPInterfaceHTTP.UserManageResult umr;
        if(!sGuid.equals(sMPPGuid)){
            try{
                umr = mppInterface.userManagePartialAccountBased(this.subscriberAccount, new Set<String>{'PersonEmail', 'Guid__c'});
            }catch(Exception e){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Diagnostic_Console_Unable_to_update_MPP_based_on_email));
                return;
            }
        }else{
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.Diagnostic_Console_Guid_fix_not_applicable));
        	return;
        }

        if(bUpdateAccount){
            try{
                AccountTriggerHandler ath = AccountTriggerHandler.getInstance();
                ath.bRunApi = false;
                update new Account(Id = this.subscriberAccount.Id, Guid__c = sGuid);
                ath.bRunApi = true;
            }catch(DmlException e){
                ApexPages.addMessages(e);
                return;
            }
        }

        //check guid and add message if not there
        if(String.isNotBlank(umr.guid)){
            //find the log we are fixing and set it to fixed
            for(ResultWrapper rw : resultWrappers){
                if( 
                        (
                            rw.subscriberRuleLog.ruleCode == Constants.MPP_RULE_NAME_ID_FIELDS_EXIST && 
                            (   
                                rw.subscriberRuleLog.ruleResultCode == Constants.MPP_RULE_ID_FIELDS_EXIST_NO_GUID_IN_MPP || 
                                rw.subscriberRuleLog.ruleResultCode == Constants.MPP_RULE_ID_FIELDS_EXIST_NO_GUID_IN_SFDC_MPP
                            )
                        ) || (
                            rw.subscriberRuleLog.ruleCode == Constants.MPP_RULE_NAME_ID_FIELDS_INSYNC && 
                            rw.subscriberRuleLog.ruleResultCode == Constants.MPP_RULE_ID_FIELDS_INSYNC_GUID_FAIL
                        ) || (
                            rw.subscriberRuleLog.ruleCode == Constants.SFDC_RULE_NAME_GUID_VALIDATION && (
                                rw.subscriberRuleLog.ruleResultCode == Constants.SFDC_RULE_GUID_VALIDATION_NOGUID ||
                                rw.subscriberRuleLog.ruleResultCode == Constants.SFDC_RULE_GUID_VALIDATION_NOTMATCHINGGUID
                            )
                        )
                    ){

                    //add rules for non-exising guid in sfdc
                    rw.isError = false;
                    subscriberValidationRuleInfov2__c ruleSetting = subscriberValidationRuleInfov2__c.getInstance(rw.subscriberRuleLog.ruleCode);
                    String sFieldName = 'X'+Constants.MPP_RULE_ID_FIELDS_INSYNC_GUID_SUCCESS+'__c';
                    if(ruleSetting != null && ruleSetting.get(sFieldName) != null){
                        rw.subscriberRuleLog.ruleUserMessage = (String) ruleSetting.get(sFieldName);
                    }
                }
            }
        }else{
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.Diagnostic_Console_GUID_fix_unable_to_update_MPP_unknown_response));
        }
        return;
    }

    //Prepare dialog for GUID fix
    public void fixGUID() {
        showConsole = false;
        reloading = false;
        fixRule = Fixes.GUID;
        alternateFixNeeded = false;
        //If key values are empty, prepare for Task fix
        if (String.isEmpty(mppSAMGUID) && String.isEmpty(mppTSNumber)) {
            MPPSAMGUIDstyle = redStyle;
            salesforceGUIDstyle = redStyle;
            mppSAMGuid = null;
            subscriberAccount.Guid__c = null;
            Integer taskCount = [Select count() 
                            from Task 
                            where
                            WhatId = :subscriberAccount.Id
                            and WhoId = :subscriberAccount.PersonContactId
                            and OwnerId = :sysAdmin.Id
                            and Subject = :Label.FixGUIDTaskSubject]; 
            problemFixed = taskCount > 0;
            alternateFixNeeded = true;
        } else {//Prepare for callout fix
            if (SAMGuid != mppSAMGUID) {
                MPPSAMGUIDstyle = greenStyle;
            }
            if (SAMGuid != subscriberAccount.GUID__c) {
                salesforceGUIDstyle = greenStyle;
            }
            mppSAMGuid = SAMGUID;
            subscriberAccount.Guid__c = SAMGuid;
        }
        
        if (mppTSNumber != subscriberAccount.Subscriber_Number_static__c) {
            salesforceTSNumberStyle = orangeStyle;
            MPPTSNumberStyle = orangeStyle;
        }
    }
    
    //Go back to console
    public void goBackToConsole() {
    	showConsole = true;
    }
    
    //Parent doFix method, to be modified for future fixes
    public void doFix() {
    	if (fixRule == Fixes.GUID) {
    		doGUIDFix();
    	}
    }
    
    
    /*************************************************************************************** 
    Developer - Unknown
    Date -  Unknown
    Version - 1.2
    Function - GUID Fix action - retrieves guid from mpp based on TSNumber and updates the account
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         16/05/2015  //made sure the update actually works, previously was throwing exception as Name field was in list of fields to update (blows up for PersonAccounts)
    Wiktor Czykin	1.2			04/11/2015	//added actual exception message to ErrorLabel so that we do not have to check debug log every time valid failure with weird data setup happens
    ****************************************************************************************/
    public void doGUIDFix() {
        //Check for completion of key values
        if (!String.isEmpty(mppSAMGuid) || (!String.isEmpty(mppTSNumber) && mppTSNumber == subscriberAccount.Subscriber_Number_static__c)) {
            MPPInterfaceHTTP mppCaller = new MPPInterfaceHTTP();
            try {
                //Do the callout and update for the fix
                mppCaller.UserManage(mppTSNumber, null, null, null, null, null, null, null, null, null, null, null, null, SAMGuid);
                update new Account(Id = this.subscriberAccount.Id, Guid__c = SAMGuid);
                problemFixed = true;
                reloading = true;
            }
            //Handle exceptions
            catch (MPPInterfaceHTTP.MPPInterfaceHTTPException MPPex) {
                problemFixed = false;
                ErrorLabel = Label.UnknownError + ' ' + MPPex.getMessage();
            }
            catch (Exception ex) {
                problemFixed = false;
                ErrorLabel = Label.UnknownError + ' ' + ex.getMessage();
            }
        } else {
            try {
                //Insert Task fix
                insert new Task(
                    WhatId = subscriberAccount.Id,
                    WhoId = subscriberAccount.PersonContactId,
                    OwnerId = sysAdmin.Id,
                    Subject = Label.FixGUIDTaskSubject
                );
                problemFixed = true;
                reloading = true;
            }
            catch (Exception ex) {
                problemFixed = false;
                ErrorLabel = Label.UnknownError;
            }
        }
    }
    
    //Method to change the entitlement for a subscriber in SAM
    public void changeEntitlement(String SAMGuid, String newEntitlement) {
    	try {
    		UpdateSamUserDetailsBatch.callSamToUpdateEntitlement(new Set<String>{SAMGuid},newEntitlement,new Set<Id>(), false);
    	}
    	catch (Exception ex) {
    		throw new ChangeEntitlementException('The entitlement couldn\'t be changed correctly, a problem occurred communicating to SAM');
    	}
    }
    
    //Populate the picklist of values of the available entitlements to set
    public List<SelectOption> getEntitlementsFromSettings() {
    	List<SelectOption> options = new List<SelectOption>();
    	options.add(new SelectOption('',''));
    	Map<String, Entitlements__c> entitlements = Entitlements__c.getAll();
    	for (String entitlement : entitlements.keySet()) {
        	options.add(new SelectOption(entitlements.get(entitlement).Active_Entitlement_Value__c,entitlements.get(entitlement).Active_Entitlement_Value__c));
        	options.add(new SelectOption(entitlements.get(entitlement).Inactive_Entitlement_Value__c,entitlements.get(entitlement).Inactive_Entitlement_Value__c));
    	}
        return options;
    }
    
    public void doEntitlementFix() {
        if (!String.isEmpty(subscriberAccount.Guid__c)) {
            if (!String.isEmpty(newEntitlementForFix)) {
                try {
                    changeEntitlement(subscriberAccount.Guid__c, newEntitlementForFix);
                    confirmMessage = String.format(Label.EntitlementChangeConfirm, new List<String>{newEntitlementForFix});
                    newEntitlementForFix = '';
                }   
                catch (ChangeEntitlementException CHEx) {
                    EntitlementErrorLabel = CHEx.getMessage();
                }
                catch (Exception ex) {
                    EntitlementErrorLabel = Label.EntitlementChangeSAMError;
                }
            }
            else {
                EntitlementErrorLabel = Label.EntitlementChangeSelectError;
            }
        }
        else {
            EntitlementErrorLabel = Label.EntitlementChangeGUIDError;
        }
    }
    
    public class OrderHistoryItemWrapper {
        public MPPInterfaceHTTP.OrderHistoryItem orderHistoryItem {get;set;}
        
        public OrderHistoryItemWrapper(MPPInterfaceHTTP.OrderHistoryItem orderHistoryItem) {
            this.orderHistoryItem = orderHistoryItem;
        }
    }
    
    public class MppUserWrapper {
        public MPPInterfaceHTTP.UserInfoResult userInfoResult {get;set;}
        
        public MppUserWrapper(MPPInterfaceHTTP.UserInfoResult userInfoResult) {
            this.userInfoResult = userInfoResult;
        }
    }
    
    public class SamWrapper {
        public SAMUtil.SAMAccountResult samAccountResult {get;set;}
        
        public SamWrapper(SAMUtil.SAMAccountResult samAccountResult) {
            this.samAccountResult = samAccountResult;
        }
    }
    
    public class ResultWrapper {
        public subscriberConsolesWebserviceHandlers.subscriberRuleLog subscriberRuleLog {get;set;}
        public Boolean isError {get;set;}
        public Boolean isReported {get;set;}
        public String fixIssueLink {get;set;}
        
        public resultWrapper(subscriberConsolesWebserviceHandlers.subscriberRuleLog subscriberRuleLog, Boolean isError, Boolean isReported, String fixIssueLink) {
            this.subscriberRuleLog = subscriberRuleLog;
            this.isError = isError;
            this.isReported = isReported;
            this.fixIssueLink = fixIssueLink;
        }
    }
    
    public enum Fixes {GUID, TSNUMBER, ENTITLEMENT, OTHER}
    public class ChangeEntitlementException extends Exception {}
}