/**
* Author:       Wiktor Czykin
* Date:         26/10/2016
* Description:  this class is the constructor for the redirection for Account Payment Management flow
* ******************* Change Log *******************
* Modified by       Change Date
**/
public with sharing class SubscriptionProductViewController {

	private Account acc;
	public Subscription__c oldProduct{get;set;}
	public Subscription__c newestProduct{get;set;}

	/***************************************************************************************
    Developer   Wiktor Czykin
    Date        26/10/2016
    Function    Constructor - retrieve last 2 subscriptions and assign to view variables
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
	public SubscriptionProductViewController(ApexPages.StandardController std){
		Id accId = std.getId();
		if(accId == null){
			throw new TelegraphApplicationException(Label.Account_Product_View_No_id_specified_error);
		}
		List<Account> lstAcc = [select Id from Account where  Id =: accId];
		if(lstAcc.isEmpty()){
			throw new TelegraphApplicationException(Label.Account_Product_View_No_account_for_specified_id_error);
		}
		this.acc = lstAcc[0];

		List<Subscription__c> lstSub = [select 	Id, 
												Name, 
												Subscription_Status__c, 
												Product__c, 
												Product__r.Name  
											from Subscription__c 
											where Subscriber__c = : accId 
											order by End_Date__c desc 
											limit 2];
		if(!lstSub.isEmpty()){
			if(lstSub.size() == 2){
				this.oldProduct =  lstSub[1];
			}
			if(lstSub.size() >= 1){
				this.newestProduct = lstSub[0];
			}
		}
	}
}