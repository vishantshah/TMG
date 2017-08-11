/**
* @author Wiktor Czykin
* @date 18/09/2015
* @description  Voucher_Adjustment__c trigger handler
*				Created to merge 3 triggers and old helper
* #############Change Log#############
* Modified by           Version     Change Date
* Michal Szewczyk       1.1         13/10/2016  - added generateDateCalc() method with wrapper class CalculationWrapper
* Mantas Grigaliunas    1.2         09/12/2016 - added updateRefundStatus() method, executed after update
* Mantas Grigaliunas    1.3         12/12/2016  - added updateChequeAmount() method, executed after update
* Mantas Grigaliunas    1.4         19/12/2016  - updated updateDeferredAssetValue() method
* Mantas Grigaliunas    1.5         08/02/2017  - added preventMultipleSameDateVoucherCreation()
* Wiktor Czykin         1.6         21/02/2017  - added populateDefaultValues()
* Wiktor Czykin         1.7         05/04/2017  - modified populateDefaultValues()
* Vishant Shah          1.8         19/04/2017  - added hasOverlapWithOtherVoucherActivity()
* Konrad Czykin         1.9         14/05/2017  - added condition to hasOverlapWithOtherVoucherActivity method to exclude Pre-notification of holiday in calculation
**/
public without sharing class VoucherAdjustmentTriggerHandler {
	
	private static VoucherAdjustmentTriggerHandler instance;

    public Boolean isExecuting = false;
    @TestVisible private Boolean bTriggerError = false;

    public static VoucherAdjustmentTriggerHandler getInstance() {
        if (instance == null) instance = new VoucherAdjustmentTriggerHandler();
        return instance; 
    }

    
    public void OnBeforeInsert(List<Voucher_Adjustment__c> newVoucherAdjustments){
        if (!this.isExecuting) {
            this.isExecuting = true;

            this.populateDefaultValues(newVoucherAdjustments);
            this.voucherRefundAdjustment(newVoucherAdjustments);
            this.hasOverlapWithOtherVoucherActivity(newVoucherAdjustments);

            this.isExecuting = false;        
        }
    } 
    
    public void OnAfterInsert(List<Voucher_Adjustment__c> newVoucherAdjustments, 
                              Map<Id, Voucher_Adjustment__c> mapNewVoucherAdjustments){
    	if (!this.isExecuting) {
            this.isExecuting = true;
            this.updateDeferredAssetValue(mapNewVoucherAdjustments);
            this.voucherAdjust(newVoucherAdjustments);	
            this.deferredCalculation(null, newVoucherAdjustments);
            this.preventMultipleSameDateVoucherCreation(newVoucherAdjustments);
            this.isExecuting = false;        
        }
    }
    
    public void OnBeforeUpdate(	List<Voucher_Adjustment__c> oldVoucherAdjustments, 
    							List<Voucher_Adjustment__c> newVoucherAdjustments, 
    							Map<Id, Voucher_Adjustment__c> mapOldVoucherAdjustments){
        if (!this.isExecuting) {
            this.isExecuting = true;
            
            this.populateDefaultValues(newVoucherAdjustments);
            this.voucherRefundAdjustment(newVoucherAdjustments);
            this.hasOverlapWithOtherVoucherActivity(newVoucherAdjustments);

            this.isExecuting = false;        
        }       
    }
    
    public void OnAfterUpdate(	List<Voucher_Adjustment__c> oldVoucherAdjustments, 
    							List<Voucher_Adjustment__c> newVoucherAdjustments, 
    							Map<Id, Voucher_Adjustment__c> mapOldVoucherAdjustments, 
    							Map<Id, Voucher_Adjustment__c> mapNewVoucherAdjustments){
        if (!this.isExecuting) {
            this.isExecuting = true;

            this.updateDeferredAssetValue(mapNewVoucherAdjustments);
            this.deferredCalculation(oldVoucherAdjustments, newVoucherAdjustments);
            this.updateRefundStatus(newVoucherAdjustments, mapOldVoucherAdjustments);
            this.updateChequeAmount(mapNewVoucherAdjustments, mapOldVoucherAdjustments);
            this.preventMultipleSameDateVoucherCreation(newVoucherAdjustments);

            this.isExecuting = false;        
        }
    }
    
    public void OnBeforeDelete(List<Voucher_Adjustment__c> oldVoucherAdjustments, Map<Id, Voucher_Adjustment__c> mapOldVoucherAdjustments){}
    
    public void OnAfterDelete(List<Voucher_Adjustment__c> oldVoucherAdjustments, Map<Id, Voucher_Adjustment__c> mapOldVoucherAdjustments){
    	if (!this.isExecuting) {
            this.isExecuting = true;

    		this.deferredCalculation(oldVoucherAdjustments, null);

    		this.isExecuting = false;        
        }
    }
    
    public void OnUndelete(List<Voucher_Adjustment__c> newVoucherAdjustments){
    	if (!this.isExecuting) {
            this.isExecuting = true;

    		this.deferredCalculation(null, newVoucherAdjustments);

    		this.isExecuting = false;        
        }
    }

    /*************************************************************************************** 
    Developer - Wiktor Czykin
    Date - 21/02/2017
    Version - 1.1
    Function - prepopulates record on insert
    #############Change Log#############
    Modified by         Version     Change Date
    Wiktor Czykin       1.1         05/04/2017  //added default date for Voucher Return 
    ****************************************************************************************/
    private void populateDefaultValues(List<Voucher_Adjustment__c> lstNew){
        for(Voucher_Adjustment__c va : lstNew){
            if(va.Adjustment_Type__c == Constants.VOUCHERADJUSTMENT_ACTIVITYTYPE_HOLIDAYRETURN){
                if(va.Date_Vouchers_Received__c == null){
                    va.Date_Vouchers_Received__c = Date.today();
                }
                if(String.isBlank(va.Refund_Status__c)){
                    va.Refund_Status__c = Constants.VOUCHERADJUSTMENT_REFUND_STATUS_PENDING;
                }
            }else if(va.Adjustment_Type__c == Constants.VOUCHERADJUSTMENT_ACTIVITYTYPE_VOUCHERRETURN){
                if(va.Date_Vouchers_Received__c == null){
                    va.Date_Vouchers_Received__c = Date.today();
                }
            }
        }
    }

    /*************************************************************************************** 
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Function - updates Deferred Asset Value based on Voucher_Value__c formula field 
    #############Change Log#############
    Modified by         Version     Change Date
    Wiktor Czykin       1.1         18/09/2015  //moved here from Voucher_beforeInsUpd_DefValue trigger
    Mantas Grigaliunas  1.2         19/12/2016  //updated the functionality to be executed After Insert/Update
    ****************************************************************************************/
    public void updateDeferredAssetValue(Map<Id, Voucher_Adjustment__c> mapNew){

        //get all Voucher Activities
        List<Voucher_Adjustment__c> vouchersList = new List<Voucher_Adjustment__c>(
            [ SELECT Id, Deferred_Asset_Value__c, End_Date__c, Voucher_Value__c 
              FROM Voucher_Adjustment__c WHERE Id IN :mapNew.keySet()]);

        //update voucher activities with deferred asset value
        List<Voucher_Adjustment__c> vouchersToUpdate = new List<Voucher_Adjustment__c>();
		for (Voucher_Adjustment__c v : vouchersList){
            Voucher_Adjustment__c voucher = new Voucher_Adjustment__c(Id = v.Id);
			if(v.End_Date__c > Date.today()) voucher.Deferred_Asset_Value__c = v.Voucher_Value__c;
            else voucher.Deferred_Asset_Value__c = 0; 
            vouchersToUpdate.add(voucher);
        }
        try{
            update vouchersToUpdate;
        } catch (DMLException e) {
            for (Voucher_Adjustment__c va : mapNew.values()) {
                va.addError(e.getDmlMessage(0));
            }
        }catch (Exception e) {
            for (Voucher_Adjustment__c va : mapNew.values()) {
                va.addError(e.getMessage());
            }
        }
    }

    /*************************************************************************************** 
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Function - 	Updates related subscription fields. 
    			If two voucher activities for the same subscription are processed, the latter values are used.
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         18/09/2015  //Moved here from voucherAdjustmentTrigger.class
    ****************************************************************************************/
    public void voucherAdjust(List<Voucher_Adjustment__c> lstNew){
        Map<Id, Subscription__c> mapUpdatedSubs = new Map<Id, Subscription__c>();        
        
        //Update subscription values for each voucher adjustment created
        for(Voucher_Adjustment__c voucher : lstNew){
            Subscription__c updateSub = new Subscription__c(Id = voucher.Subscription__c, 
                                                            Voucher_Adjustment_Reason__c = voucher.Adjustment_Type__c,
                                                            Voucher_Resend_Number__c = voucher.Number_of_Vouchers__c
                                                            );
            
            //Set resend date                                               
            if(voucher.Adjustment_Type__c == Constants.VOUCHER_ADJUSTMENTTYPE_FULLPACK) { 
                updateSub.Voucher_Resend_Date__c = Date.today();
                updateSub.Voucher_Adjustment_Start_Date__c = voucher.Start_Date__c;
                if(this.bTriggerError && Test.isRunningTest()){
                	updateSub.Start_Date__c = null;
                }
            }
            mapUpdatedSubs.put(updateSub.Id, updateSub);
        }
        //Update subscriptions      
        if(!mapUpdatedSubs.isEmpty()){                                               
	    	List<Subscription__c> lstToUpdate = mapUpdatedSubs.values();
	        List<Database.SaveResult> lstResult = Database.update(lstToUpdate, false);          
	        for(Database.SaveResult sr : lstResult){
	            Integer i = 0;                           
	            if(!sr.isSuccess()){
	                // Get the problem voucher adjustment and add error
	                Database.Error err = sr.getErrors()[0];
	                lstToUpdate[i].addError(Label.Voucher_Activity_Error_updating_related_subscription + err.getMessage());                                                         
	            }
	        	i++;                                                              
	        }  
	    }
    }
    /*************************************************************************************** 
    Developer - Michal Szewczyk
    Date - 12/10/2016
    Version - 1.1
    Function -  Updates related voucher fields.
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public void voucherRefundAdjustment(List<Voucher_Adjustment__c> lstNew){
        Map<Id, Subscription__c> vouchersSubs;
        Map<Id,String> prodIdToActConfig = new Map<Id,String>();
        Set<Id> vouchersSubId = new Set<Id>(); 
        Set<Id> vochersProductSubId = new Set<Id>();     
        
        for(Voucher_Adjustment__c voucher : lstNew){
            vouchersSubId.add(voucher.Subscription__c);
        }

        vouchersSubs = new Map<Id, Subscription__c>([SELECT Id,Product__c,RecordTypeId,RecordType.Name,Start_Date__c,End_Date__c,Weekly_Price__c,Low_Start_Weekly_Price__c,Low_Start_End_Date__c FROM Subscription__c WHERE Product__c != null AND Id IN :vouchersSubId]);
        for(Subscription__c sub : vouchersSubs.values()) {
            vochersProductSubId.add(sub.Product__c);
        }

        for(zqu__ZProductFeature__c tmpProdJunction : [SELECT zqu__ZFeature__r.zqu__Code__c ,zqu__ZFeature__r.Active_Days__c , zqu__ZProduct__c FROM zqu__ZProductFeature__c WHERE zqu__ZFeature__r.zqu__Code__c LIKE '%_PRINT_VOUCHER' AND zqu__ZProduct__c IN :vochersProductSubId]){
            prodIdToActConfig.put(tmpProdJunction.zqu__ZProduct__c,tmpProdJunction.zqu__ZFeature__r.Active_Days__c);
        }
        for(Voucher_Adjustment__c voucher : lstNew) {

            Subscription__c voucherSub = vouchersSubs.get(voucher.Subscription__c);
            if(voucherSub != null && voucherSub.Product__c != null ){
                String subProdActiveDays = prodIdToActConfig.get(voucherSub.Product__c);
                if(voucherSub.RecordType.Name != Constants.RECTYPE_SUBSCRIPTION_LOWSTART) {
                        CalculationWrapper calculatedDays = generateDateCalc(voucher.Start_Date__c,voucher.End_Date__c,subProdActiveDays);
                        voucher.Voucher_Validity_in_Weeks_Calc__c = (Double) calculatedDays.numOfValidDays / (Double)  calculatedDays.numOfProdDays ;
                        voucher.Voucher_Value_Calc__c = ((Double) calculatedDays.numOfValidDays / (Double) calculatedDays.numOfProdDays) * voucherSub.Weekly_Price__c;
                        voucher.Number_of_Vouchers_Calc__c = calculatedDays.numOfValidDays;
                } else {
                        
                        if(voucher.End_Date__c <= voucherSub.Low_Start_End_Date__c) {
                            CalculationWrapper calculatedDaysLowStart = generateDateCalc(voucher.Start_Date__c,voucher.End_Date__c,subProdActiveDays);
                            voucher.Voucher_Validity_in_Weeks_Calc__c = (Double) calculatedDaysLowStart.numOfValidDays / (Double)  calculatedDaysLowStart.numOfProdDays ;
                            voucher.Voucher_Value_Calc__c = ((Double) calculatedDaysLowStart.numOfValidDays / (Double) calculatedDaysLowStart.numOfProdDays) * voucherSub.Low_Start_Weekly_Price__c;
                            voucher.Number_of_Vouchers_Calc__c = calculatedDaysLowStart.numOfValidDays;
                        } else if (voucher.Start_Date__c >= voucherSub.Low_Start_End_Date__c) {
                            CalculationWrapper calculatedDaysNormal = generateDateCalc(voucher.Start_Date__c,voucher.End_Date__c,subProdActiveDays);
                            voucher.Voucher_Validity_in_Weeks_Calc__c = (Double) calculatedDaysNormal.numOfValidDays / (Double)  calculatedDaysNormal.numOfProdDays ;
                            voucher.Voucher_Value_Calc__c = ((Double) calculatedDaysNormal.numOfValidDays / (Double) calculatedDaysNormal.numOfProdDays) * voucherSub.Weekly_Price__c;
                            voucher.Number_of_Vouchers_Calc__c = calculatedDaysNormal.numOfValidDays;
                        } else {
                            CalculationWrapper calculatedDaysLowStart = generateDateCalc(voucher.Start_Date__c,voucherSub.Low_Start_End_Date__c,subProdActiveDays);
                            CalculationWrapper calculatedDaysNormal = generateDateCalc(voucherSub.Low_Start_End_Date__c.addDays(1),voucher.End_Date__c,subProdActiveDays);
                            Integer sumPeriodDays = calculatedDaysLowStart.numOfValidDays + calculatedDaysNormal.numOfValidDays;

                            voucher.Voucher_Validity_in_Weeks_Calc__c = (Double) sumPeriodDays / (Double)  calculatedDaysLowStart.numOfProdDays;
                            voucher.Number_of_Vouchers_Calc__c = sumPeriodDays;
                            voucher.Voucher_Value_Calc__c = ((Double) calculatedDaysLowStart.numOfValidDays / (Double) calculatedDaysLowStart.numOfProdDays) * voucherSub.Low_Start_Weekly_Price__c + ((Double) calculatedDaysNormal.numOfValidDays / (Double) calculatedDaysNormal.numOfProdDays) * voucherSub.Weekly_Price__c;
                        }
                }

                if (voucher.Voucher_Validity_in_Weeks_Calc__c == 0 && voucher.Voucher_Value_Calc__c == 0){
                    String message = String.format(Label.Invalid_Voucher_Activity_Period, new List<String>{voucher.Start_Date__c.format(), voucher.End_Date__c.format(), subProdActiveDays});
                    voucher.addError(message);
                }
            }
        }
    }

    /*************************************************************************************** 
    Developer - Michal Szewczyk
    Date - 13/10/2016
    Version - 1.1
    Function -  Helper class stores numer of valid voucher days and number of product days
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private class CalculationWrapper {
        Integer numOfValidDays;
        Integer numOfProdDays;

        public calculationWrapper(Integer numValDays,Integer numProdDays){
            numOfValidDays = numValDays;
            numOfProdDays = numProdDays;
        }
    }

    /*************************************************************************************** 
    Developer - Michal Szewczyk
    Date - 13/10/2016
    Version - 1.1
    Function - Calculate voucher days 
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public CalculationWrapper generateDateCalc (Date startDate, Date endDate,String voucherDays){

        if (startDate == null || endDate == null || voucherDays == null || voucherDays == '') {
            throw new TelegraphApplicationException('generateDateCalc method error : One of method param is null or empty'); 
        }
        if(!voucherDays.contains('-')) {
            throw new TelegraphApplicationException('generateDateCalc method error : voucherDays param is in wrong format'); 
        }

        Map<String,Integer> countDaysMap = new Map<String,Integer>{'MON'=> 0,'TUE'=>0,'WED'=>0,'THU'=>0,'FRI'=>0,'SAT'=>0,'SUN'=>0};
        Set<String> uniqueDays = new Set<String>();
        Integer countedDays = 0;

        for(String tmp : voucherDays.split('-')){
            uniqueDays.add(tmp.toUpperCase());
        }
        for(Integer i = 0 ; i <= startDate.daysBetween(endDate); i++){
            DateTime myDateTime = (DateTime) startDate.addDays(i);
            String dayOfWeek = myDateTime.format('E').toUpperCase();
            if(uniqueDays.contains(dayOfWeek)) {
                countDaysMap.put(dayOfWeek,countDaysMap.get(dayOfWeek)+1);
            }
        }
        
        for(Integer val : countDaysMap.values()){
            countedDays = countedDays+ val;
        }
        return new CalculationWrapper(countedDays,uniqueDays.size());
    }

    /*************************************************************************************** 
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Function - 	
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         18/09/2015  //Moved here from Voucher_afterInsUpd_deferredCalcs
    ****************************************************************************************/
    public void deferredCalculation(List<Voucher_Adjustment__c> lstOld, List<Voucher_Adjustment__c> lstNew){
    	if (DeferredCalculation.isTestScenario == null) {DeferredCalculation.isTestScenario = false;}
		if (DeferredCalculation.inDeferredCalc == null) {DeferredCalculation.inDeferredCalc = false;}
		
		if (!DeferredCalculation.isTestScenario && !DeferredCalculation.inDeferredCalc) {
		
			DeferredCalculation.inDeferredCalc = true;
		
			List<Voucher_Adjustment__c> lstVoucherAdjustments = new List<Voucher_Adjustment__c>();
			if (lstOld != null && lstNew == null) {
				lstVoucherAdjustments = lstOld;
			}else if (lstNew != null){
				lstVoucherAdjustments = lstNew;
			}
	
			Set<Id> setSubscriptionIds = new Set<Id>();
			for(Voucher_Adjustment__c va : lstVoucherAdjustments){
				setSubscriptionIds.add(va.Subscription__c);
			}

			DeferredCalculation.DeferredVoucherCalc calc = new DeferredCalculation.DeferredVoucherCalc();
			calc.addSubsForProcessing(setSubscriptionIds);
			calc.GetSubData();
			calc.Calculate();
			calc.UpdateValues();
			
			DeferredCalculation.inDeferredCalc = false;
		}
    }

    /*************************************************************************************** 
    Developer - Mantas Grigaliunas
    Date - 09/12/2016
    Version - 1.1
    Function -  Update VA of type Holiday Return Refund status to 'Pending' if Refund Amount Changed and is less the Threshold Value
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public void updateRefundStatus(List<Voucher_Adjustment__c> lstNew, Map<Id, Voucher_Adjustment__c> mapOld){
        List<Voucher_Adjustment__c> vouchersToUpdate = new List<Voucher_Adjustment__c>();
        Double thresholdAmount = (Configuration__c.getOrgDefaults().Voucher_Refund_Threshold_Amount__c == null 
            ? 0 : Configuration__c.getOrgDefaults().Voucher_Refund_Threshold_Amount__c);
        for(Voucher_Adjustment__c va : lstNew){
            if(va.Refund_Status__c == Constants.VOUCHERADJUSTMENT_REFUND_STATUS_WAITING_FOR_APPROVAL
                && va.Refund_Amount__c != mapOld.get(va.Id).Refund_Amount__c 
                && va.Refund_Amount__c <= thresholdAmount){
                vouchersToUpdate.add(new Voucher_Adjustment__c(Id = va.Id, 
                    Refund_Status__c = Constants.VOUCHERADJUSTMENT_REFUND_STATUS_PENDING));
            }
        }
        if(vouchersToUpdate.size() > 0){
            update vouchersToUpdate;
        }
    }

    /*************************************************************************************** 
    Developer - Mantas Grigaliunas
    Date - 09/12/2016
    Version - 1.1
    Function -  Update related Cheque Amount if Refund Amount was amended on VA with Refund Amount 'Pending' and Refund Method 'Manual created cheque'
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public void updateChequeAmount(Map<Id, Voucher_Adjustment__c> mapNew, Map<Id, Voucher_Adjustment__c> mapOld){
        Set<Id> voucherIds = new Set<Id>();
        for(Voucher_Adjustment__c va : mapNew.values()){
            if(va.Refund_Status__c == Constants.VOUCHERADJUSTMENT_REFUND_STATUS_PENDING
                && va.Refund_Method__c == Constants.VOUCHERADJUSTMENT_REFUND_METHOD_MANUAL_CHEQUE
                && va.Refund_Amount__c != mapOld.get(va.Id).Refund_Amount__c){
                voucherIds.add(va.Id);
            }
        }

        if(voucherIds.size() > 0){
             List<Cheque__c> chequesToUpdate = new List<Cheque__c>([ SELECT Id, Cheque_Amount__c, Voucher_Activity__c FROM Cheque__c 
                WHERE Voucher_Activity__c IN :voucherIds]);
            if(chequesToUpdate.size() > 0){
                for(Cheque__c c : chequesToUpdate){
                    c.Cheque_Amount__c = mapNew.get(c.Voucher_Activity__c).Refund_Amount__c;
                }
            }
            update chequesToUpdate;
        }

    }

    /*************************************************************************************** 
    Developer - Mantas Grigaliunas
    Date - 08/02/2017
    Version - 1.1
    Function -  Prevent form creating Holiday Return Voucher for the same or conflicting dates
    #############Change Log#############
    Modified by     Version     Change Date
    Vishant Shah    1.6         10/03/2016      added logic to bypass check if the VA is a old record, 
    ****************************************************************************************/
    public void preventMultipleSameDateVoucherCreation(List<Voucher_Adjustment__c> newVoucherAdjustments){

        Set<Id> subscriptionIds = new Set<Id>();
        Set<Id> conflictingVouchers = new Set<Id>();

        //get set of subscription that has related holiday return vouchers
        for(Voucher_Adjustment__c va : newVoucherAdjustments){
            if(va.Voucher_Activity_Action__c == Constants.VOUCHERADJUSTMENT_ACTIVITYACTION_VOUCHERSRECEIVED
                && va.Adjustment_Type__c == Constants.VOUCHERADJUSTMENT_ACTIVITYTYPE_HOLIDAYRETURN
                && va.ExecuteValidationRules__c == true){
                    subscriptionIds.add(va.Subscription__c);
            }
        }

        if(subscriptionIds.size() > 0){
            //retrieve map of subscriptions with related holiday return vouchera
            Map<Id, Subscription__c> relatedSubscriptionsMap = new Map<Id, Subscription__c>([SELECT Id, 
                (SELECT Id, Start_Date__c, End_Date__c, Subscription__c FROM Voucher_Activities__r 
                 WHERE Voucher_Activity_Action__c = :Constants.VOUCHERADJUSTMENT_ACTIVITYACTION_VOUCHERSRECEIVED
                 AND Adjustment_Type__c = :Constants.VOUCHERADJUSTMENT_ACTIVITYTYPE_HOLIDAYRETURN) FROM Subscription__c WHERE Id IN :subscriptionIds ]);

            //loop through each subscription, as it need to check dates only per subscription
            for(Id subId : relatedSubscriptionsMap.keySet()){
                Map<Id, Voucher_Adjustment__c> voucherActivitiesMap = new Map<Id, Voucher_Adjustment__c>(relatedSubscriptionsMap.get(subId).Voucher_Activities__r);
                
                //loop through all vouchers and check if there are any date conflicts
                for(Voucher_Adjustment__c newVa : newVoucherAdjustments){
                    for(String vaId : voucherActivitiesMap.keySet()){
                        Voucher_Adjustment__c existingVA = voucherActivitiesMap.get(vaId);
                        //avoid checking record from different subscriptions and checking against itself
                        if(vaId != newVa.Id && existingVA.Subscription__c == newVa.Subscription__c){ 
                            if((newVa.Start_Date__c >= existingVA.Start_Date__c && newVa.Start_Date__c <= existingVA.End_Date__c)
                                || (newVa.End_Date__c >=  existingVA.Start_Date__c && newVa.End_Date__c <= existingVA.End_Date__c)){
                                newVa.addError(Label.Voucher_Activity_Already_Exist_With_Same_Dates);
                            }
                        }
                    }
                }
            }
        }
    }

    /*************************************************************************************** 
    Developer - Vishant Shah
    Date - 19/04/2017
    Version - 1.1
    Function -  Check if there are any other voucher received / sent activity present. Set the field and use to show notification
    #############Change Log#############
    Modified by     Version     Change Date 
    ****************************************************************************************/

    public void hasOverlapWithOtherVoucherActivity(List<Voucher_Adjustment__c> newVoucherAdjustments){

        Set<Id> subscriptionIds = new Set<Id>();

        //get set of subscription that has related holiday return vouchers
        for(Voucher_Adjustment__c va : newVoucherAdjustments){
            if(va.Voucher_Activity_Action__c == Constants.VOUCHERADJUSTMENT_ACTIVITYACTION_VOUCHERSRECEIVED ||
               va.Voucher_Activity_Action__c == Constants.VOUCHERADJUSTMENT_ACTIVITYACTION_VOUCHERSSENT){
                
                va.Overlaps_Other_Voucher_Activity__c  = null;
                if (va.Adjustment_Type__c != Constants.VOUCHERADJUSTMENT_ACTIVITYTYPE_PRENOTIFICATIONHOLIDAY)
                subscriptionIds.add(va.Subscription__c);
            }
        }

        if(subscriptionIds.size() > 0){
            //retrieve map of subscriptions with related holiday return vouchera
            Map<Id, Subscription__c> relatedSubscriptionsMap = new Map<Id, Subscription__c>([SELECT Id, 
                                                                    (SELECT Id, Start_Date__c, End_Date__c, Subscription__c FROM Voucher_Activities__r 
                                                                     WHERE (Voucher_Activity_Action__c = :Constants.VOUCHERADJUSTMENT_ACTIVITYACTION_VOUCHERSRECEIVED AND 
                                                                     Adjustment_Type__c != :Constants.VOUCHERADJUSTMENT_ACTIVITYTYPE_PRENOTIFICATIONHOLIDAY) OR 
                                                                     Voucher_Activity_Action__c = :Constants.VOUCHERADJUSTMENT_ACTIVITYACTION_VOUCHERSSENT) 
                                                                FROM Subscription__c WHERE Id IN :subscriptionIds ]);

            //loop through each subscription, as it need to check dates only per subscription
            for(Id subId : relatedSubscriptionsMap.keySet()){
                Map<Id, Voucher_Adjustment__c> voucherActivitiesMap = new Map<Id, Voucher_Adjustment__c>(relatedSubscriptionsMap.get(subId).Voucher_Activities__r);
                
                //loop through all vouchers and check if there are any date conflicts
                for(Voucher_Adjustment__c newVa : newVoucherAdjustments){
                    
                    for(String vaId : voucherActivitiesMap.keySet()){
                        Voucher_Adjustment__c existingVA = voucherActivitiesMap.get(vaId);
                        //avoid checking record from different subscriptions and checking against itself
                        if(vaId != newVa.Id && existingVA.Subscription__c == newVa.Subscription__c){ 
                            if((newVa.Start_Date__c >= existingVA.Start_Date__c && newVa.Start_Date__c <= existingVA.End_Date__c) ||
                               (newVa.End_Date__c >= existingVA.Start_Date__c && newVa.End_Date__c <= existingVA.End_Date__c)){
                                
                                newVa.Overlaps_Other_Voucher_Activity__c = Label.Overlap_With_Other_Voucher_Activity;
                            }
                        }
                    }
                }
            }
        }
    }

}
