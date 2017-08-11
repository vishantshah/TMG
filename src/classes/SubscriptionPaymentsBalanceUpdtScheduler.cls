/************************************************************************************
Class Name   : SubscriptionPaymentsBalanceUpdtScheduler
Author       : Mantas Grigaliunas
Created Date : 16/01/2016
Function     : Schedulable class to execute SubscriptionPaymentsBalanceUpdateBatch batch job class
Change Log:
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
* Developer             Date         Description
* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
*************************************************************************************/
global class SubscriptionPaymentsBalanceUpdtScheduler implements Schedulable {

	/************************************************************************************
    Method Name  : execute
    Developer    : Mantas Grigaliunas
    Created Date : 16/01/2016
    Function     : Class execute method to call SubscriptionPaymentsBalanceUpdateBatch for execution
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer         Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
	global void execute(SchedulableContext sc) {
		SubscriptionPaymentsBalanceUpdateBatch b = new SubscriptionPaymentsBalanceUpdateBatch();
		Database.executeBatch(b);
	}
}