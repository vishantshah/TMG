/**
* Author:       Michal Kwika (Accenture)
* Date:         12/10/2015
* Description:  this class for testing CreditToInvoiceControllerExt
*
* ******************* Change Log *******************
* Modified by       Change Date
**/
@isTest (SeeAllData=true)
private class CreditToInvoiceControllerExtTest {

	static testmethod void test_Main() {
		// Implement test code
		//Test.setCurrentPage();
		Test.startTest();

		ApexPages.Standardcontroller controller = new ApexPages.Standardcontroller(new Zuora__CustomerAccount__c());
		CreditToInvoiceControllerExt ext = new CreditToInvoiceControllerExt(controller);

		ext.amountInvoiceTransfer = -20;
		ext.selectedInvoiceBalance = 199;
		ext.validateAmount();
		ext.amountInvoiceTransfer = 0;
		ext.validateAmount();
		ext.amountInvoiceTransfer = 200;
		ext.validateAmount();
		ext.amountInvoiceTransfer = 50;
		ext.transferFundsFromCreditBalance();
		//other
		ext.RefreshUI();
		ext.ShowPrompt = true;
		ext.confirmError();
		ext.cancel();

	}
	
}