/**
* Author:       Michal Kwika (Accenture)
* Date:         03/02/2016
* Description:  Test class for Summary page
*
* ******************* Change Log *******************
* Modified by       Change Date
* Michal Kwika      18/02/2016 - test class rebuild
* Michal Kwika      22/02/2016 - added custom setting dependency
* Wiktor Czykin     06/06/2017 - replaced reference to createZquotesWithProduct()
**/
@isTest(SeeAllData = true)
private class Zuora_SubscriptionSummaryCtrlTest {

    /***************************************************************************************
    Author:       Michal Kwika (Accenture)
    Date:         19/02/2016
    Function      TestMethod - valid path for acquisition
    ******************* Change Log *******************
    Modified by         Change Date
    Michal Kwika        22/02/2016 - added custom setting dependency
    Wiktor Czykin       06/06/2017 - replaced createZquotesWithProduct()
    ****************************************************************************************/
    static testMethod void validSummaryPageNewMonthly() {
        TestDataUtility testDataUtilityObj = new TestDataUtility(1);
        testDataUtilityObj.createQuoteRatePlanCharges();
        testDataUtilityObj.createFireAccountCreationCustomSetting(false);
        zqu__Quote__c tempQuote = testDataUtilityObj.lstZQuotes[0];
        //prepare quote
        tempQuote.zqu__PaymentMethod__c = Constants.DIRECT_DEBIT_PAYMENT_METHOD;
        tempQuote.zqu__Service_Activation_Date__c = Date.today();
        update tempQuote;

        PageReference pr = Page.Zuora_SubscriptionSummary;
        pr.getParameters().put(Constants.QUOTE_ID_QUERY_STRING, tempQuote.Id);
        Test.setCurrentPage(pr);

        Zuora_SubscriptionSummaryCtrl ctrl = new Zuora_SubscriptionSummaryCtrl();
        System.assert(ctrl.showFullPage);
        System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Subscription_Summary_Message_Success), ApexPages.getMessages());
        System.assert(!ctrl.isAmendment);

        //improve code coverage and redirect user
        ctrl.setZuoraDiscountRatePlanId(Constants.TABLET_UK_PRODUCT_NAME);
        ctrl.setShowBillingPreviewBasedOnProduct(Constants.RATE_PLAN_MONTHLY);
        System.assert(ctrl.showBillingPreview);
        ctrl.setCorrectSubsTermType(Constants.RATE_PLAN_MONTHLY);
        ctrl.goToQuotePage();
        ctrl.goToAccountPage();
    }

    /***************************************************************************************
     Author:       Michal Kwika (Accenture)
     Date:         19/02/2016
     Function      TestMethod - valid path for amendment
     ******************* Change Log *******************
     Modified by         Change Date
     Michal Kwika        22/02/2016 - added custom setting dependency
     Wiktor Czykin       06/06/2017 - replaced createZquotesWithProduct()
     ****************************************************************************************/
    static testMethod void validSummaryPageAmendmentMonthly() {
        TestDataUtility testDataUtilityObj = new TestDataUtility(1);
        testDataUtilityObj.createQuoteRatePlanCharges();
        testDataUtilityObj.createFireAccountCreationCustomSetting(false);
        //and subs
        testDataUtilityObj.createBillingAccountToRegistrant(testDataUtilityObj.lstRegistrants[0].Id);
        testDataUtilityObj.createZuoraSubscriptionToRegistrant(testDataUtilityObj.lstRegistrants[0].Id);
        testDataUtilityObj.lstZuoraSubscriptions[0].Zuora__ServiceActivationDate__c = Date.today();
        update testDataUtilityObj.lstZuoraSubscriptions[0];
        //set quote
        zqu__Quote__c tempQuote = testDataUtilityObj.lstZQuotes[0];
        tempQuote.Default_Payment_Method_Type__c = Constants.PAYMENT_METHOD_CREDIT_CARD_TYPE_LABEL;
        tempQuote.Previous_Subscription__c = testDataUtilityObj.lstZuoraSubscriptions[0].Id;
        update tempQuote;

        PageReference pr = Page.Zuora_SubscriptionSummary;
        pr.getParameters().put(Constants.QUOTE_ID_QUERY_STRING, tempQuote.Id);
        pr.getParameters().put('zuoraId', '12345678');
        Test.setCurrentPage(pr);

        Zuora_SubscriptionSummaryCtrl ctrl = new Zuora_SubscriptionSummaryCtrl();
        System.assert(ctrl.showFullPage);
        System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Subscription_Summary_Message_Success), ApexPages.getMessages());
        System.assert(ctrl.isAmendment);

        //codecoverage improvement
        ctrl.setShowBillingPreviewBasedOnProduct(Constants.RATE_PLAN_ANNUAL);
        ctrl.setCorrectSubsTermType(Constants.RATE_PLAN_ANNUAL);
        System.assert(!ctrl.showBillingPreview);
    }

    /***************************************************************************************
     Author:       Michal Kwika (Accenture)
     Date:         19/02/2016
     Function      TestMethod - invalid path (lack of parameters)
     ******************* Change Log *******************
     Modified by         Version     Change Date
     Michal Kwika        1.1         22/02/2016 - added custom setting dependency
     ****************************************************************************************/
    static testMethod void invalidSummaryPageMonthlyNoQuoteId() {
        TestDataUtility testDataUtilityObj = new TestDataUtility(1);
        testDataUtilityObj.createFireAccountCreationCustomSetting(false);
        Test.setCurrentPage(Page.Zuora_SubscriptionSummary);
        Zuora_SubscriptionSummaryCtrl ctrl = new Zuora_SubscriptionSummaryCtrl();

        System.assert(!ctrl.showFullPage);
        System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.New_Digital_Platform_Generic_Error_Message), ApexPages.getMessages());
        System.assert(!ctrl.showBillingPreview);
    }
    
    /***************************************************************************************
     Author:       Michal Kwika (Accenture)
     Date:         19/02/2016
     Function      TestMethod - invalid path (wrong parameters)
     ******************* Change Log *******************
     Modified by         Version     Change Date
     Michal Kwika        1.1         22/02/2016 - added custom setting dependency
     ****************************************************************************************/
    static testMethod void invalidSummaryPageWrongData() {
        TestDataUtility testDataUtilityObj = new TestDataUtility(1);
        testDataUtilityObj.createRegistrants();
        testDataUtilityObj.createFireAccountCreationCustomSetting(false);
        PageReference pr = Page.Zuora_SubscriptionSummary;
        pr.getParameters().put(Constants.QUOTE_ID_QUERY_STRING, testDataUtilityObj.lstRegistrants[0].Id);
        Test.setCurrentPage(pr);
        Zuora_SubscriptionSummaryCtrl ctrl = new Zuora_SubscriptionSummaryCtrl();

        System.assert(!ctrl.showFullPage);
        System.assert(!ctrl.showBillingPreview);
        System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.New_Digital_Platform_Generic_Error_Message), ApexPages.getMessages());
    }
}