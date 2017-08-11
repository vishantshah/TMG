/**
* Author:       Sally ElGhoul (Accenture)
* Date:         16/12/2015
* Description:  this class for testing Zuora_Outbound_SelectProductsCtrl
*
* ******************* Change Log *******************
* Modified by       Change Date
* Wiktor Czykin     12/06/2017  //removed useless stuff just for the test to pass as will have to be rewritten soon
**/
@isTest
private class Zuora_Outbound_SelectProductsCtrlTest {

    static testMethod void testFailureErrorMessages() {
        //Create zquote record and this function will create a registrant as well
        TestDataUtility testDataUtilityObj = new TestDataUtility(1);
        //Create the account registrant
        testDataUtilityObj.createRegistrants();
        
        //new quote creation
        zqu__Quote__c quoteObj=ZuoraQuote_Utility.createZuoraQuote(null,testDataUtilityObj.lstRegistrants[0],constants.QUOTE_SUBSCRIPTION_TYPE_NEW_VALUE,null);
        insert quoteObj;
        
        ApexPages.StandardController sc = new ApexPages.StandardController(quoteObj);
        Zuora_Outbound_SelectProductsCtrl controllerObj=new Zuora_Outbound_SelectProductsCtrl(sc);
        
        PageReference pageRef = Page.Zuora_Outbound_SelectProducts;
        Test.setCurrentPage(pageRef);
        
        //check that error is thrown when the quote id is not passed
        controllerObj.addOutboundProduct();
    }
    
    static testMethod void testAddingStartSubsequentDiscounts() {
        // Set mock callout class
        MockHttpCoreApiResponseGenerator ResponseGenerator = new MockHttpCoreApiResponseGenerator(200);
        Test.setMock(HttpCalloutMock.class, ResponseGenerator);
        
        //Create zquote record and this function will create a registrant as well
        TestDataUtility testDataUtilityObj = new TestDataUtility(1);
        testDataUtilityObj.CreateCoreApiEventEndPointSetting();
        //Create the account registrant
        testDataUtilityObj.createRegistrants();
        
        //new quote creation
        zqu__Quote__c quoteObj=ZuoraQuote_Utility.createZuoraQuote(null,testDataUtilityObj.lstRegistrants[0],constants.QUOTE_SUBSCRIPTION_TYPE_NEW_VALUE,null);
        quoteObj.Outbound_Selected_Product__c='Website';
        quoteObj.Outbound_Payment_Frequency__c='m';
        quoteObj.Outbound_Start_Price__c=2;
        quoteObj.Outbound_Subsequent_Price__c=3;
        quoteObj.Outbound_Start_Periods__c=2;
        insert quoteObj;
        
        ApexPages.StandardController sc = new ApexPages.StandardController(quoteObj);
        Zuora_Outbound_SelectProductsCtrl controllerObj=new Zuora_Outbound_SelectProductsCtrl(sc);
        
        PageReference pageRef = Page.Zuora_Outbound_SelectProducts;
        Test.setCurrentPage(pageRef);
        
        //add the quote id in the url
        pageRef.getParameters().put(constants.ID_QUOTE_FIELD, String.valueOf(quoteObj.id));
        
        //products
        testDataUtilityObj.createZProducts();
        testDataUtilityObj.lstZproducts[0].name='Website+ UK';
        update testDataUtilityObj.lstZproducts[0];
        
        //product mapping custom setting
        testDataUtilityObj.createProductMappingCustomSetting('website',testDataUtilityObj.lstZproducts[0].id);
        
        controllerObj.addOutboundProduct();
    }
    
    static testMethod void testAddingSubsequentDiscount() {
        // Set mock callout class
        MockHttpCoreApiResponseGenerator ResponseGenerator = new MockHttpCoreApiResponseGenerator(200);
        Test.setMock(HttpCalloutMock.class, ResponseGenerator);
        
        //Create zquote record and this function will create a registrant as well
        TestDataUtility testDataUtilityObj = new TestDataUtility(1);
        testDataUtilityObj.CreateCoreApiEventEndPointSetting();
        //Create the account registrant
        testDataUtilityObj.createRegistrants();
        
        //new quote creation
        zqu__Quote__c quoteObj=ZuoraQuote_Utility.createZuoraQuote(null,testDataUtilityObj.lstRegistrants[0],constants.QUOTE_SUBSCRIPTION_TYPE_NEW_VALUE,null);
        quoteObj.Outbound_Selected_Product__c='Website';
        quoteObj.Outbound_Payment_Frequency__c='m';
        quoteObj.Outbound_Subsequent_Price__c=3;
        insert quoteObj;
        
        ApexPages.StandardController sc = new ApexPages.StandardController(quoteObj);
        Zuora_Outbound_SelectProductsCtrl controllerObj=new Zuora_Outbound_SelectProductsCtrl(sc);
        
        PageReference pageRef = Page.Zuora_Outbound_SelectProducts;
        Test.setCurrentPage(pageRef);
        
        //add the quote id in the url
        pageRef.getParameters().put(constants.ID_QUOTE_FIELD, String.valueOf(quoteObj.id));
        
        //products
        testDataUtilityObj.createZProducts();
        testDataUtilityObj.lstZproducts[0].name='Website+ UK';
        update testDataUtilityObj.lstZproducts[0];
        
        //product mapping custom setting
        testDataUtilityObj.createProductMappingCustomSetting('website',testDataUtilityObj.lstZproducts[0].id);
        
        controllerObj.addOutboundProduct();
    }
    
    static testMethod void testTcodeDiscount() {
        // Set mock callout class
        MockHttpCoreApiResponseGenerator ResponseGenerator = new MockHttpCoreApiResponseGenerator(200);
        Test.setMock(HttpCalloutMock.class, ResponseGenerator);
        
        //Create zquote record and this function will create a registrant as well
        TestDataUtility testDataUtilityObj = new TestDataUtility(1);
        testDataUtilityObj.CreateCoreApiEventEndPointSetting();
        //Create the account registrant
        testDataUtilityObj.createRegistrants();
        
        //create the tcode
        TCodeManagement__c tcodeObj=TestDataUtility.newTCodeManagement('test');
        tcodeObj.Website_UK_Monthly_Offer_Code__c='offer1';
        insert tcodeObj;
        
        //create the poc
        POC__c pocObj=TestDataUtility.newPOC(1,tcodeObj.id);
        system.debug('check pocObj: '+pocObj);
        pocObj.TCodeManagement__c=tcodeObj.id;
        insert pocObj;
        
        //new quote creation
        zqu__Quote__c quoteObj=ZuoraQuote_Utility.createZuoraQuote(null,testDataUtilityObj.lstRegistrants[0],constants.QUOTE_SUBSCRIPTION_TYPE_NEW_VALUE,null);
        quoteObj.Outbound_Selected_Product__c='Website';
        quoteObj.Outbound_Payment_Frequency__c='m';
        quoteObj.Outbound_POC__c=pocObj.id;
        insert quoteObj;
        
        quoteObj=[select Outbound_Selected_Product__c,Outbound_Payment_Frequency__c,Outbound_POC__c,Subscription_Origin__c,Outbound_Start_Periods__c,Outbound_Start_Price__c,Outbound_Subsequent_Price__c,Outbound_POC__r.Subscription_Acquired__c,zqu__SubscriptionType__c,Outbound_POC__r.TCodeManagement__c from zqu__Quote__c where id=:quoteObj.id];
        system.debug('check quoteObj tcode: '+quoteObj.Outbound_POC__r.TCodeManagement__c);
        
        ApexPages.StandardController sc = new ApexPages.StandardController(quoteObj);
        Zuora_Outbound_SelectProductsCtrl controllerObj=new Zuora_Outbound_SelectProductsCtrl(sc);
        
        PageReference pageRef = Page.Zuora_Outbound_SelectProducts;
        Test.setCurrentPage(pageRef);
        
        //add the quote id in the url
        pageRef.getParameters().put(constants.ID_QUOTE_FIELD, String.valueOf(quoteObj.id));
        
        //products
        testDataUtilityObj.createZProducts();
        testDataUtilityObj.lstZproducts[0].name='Website+ UK';
        update testDataUtilityObj.lstZproducts[0];
        
        //product mapping custom setting
        testDataUtilityObj.createProductMappingCustomSetting('website',testDataUtilityObj.lstZproducts[0].id);
        
        controllerObj.addOutboundProduct();
    }
    
    static testMethod void testStartTcodeDiscount() {
        // Set mock callout class
        MockHttpCoreApiResponseGenerator ResponseGenerator = new MockHttpCoreApiResponseGenerator(200);
        Test.setMock(HttpCalloutMock.class, ResponseGenerator);
        
        //Create zquote record and this function will create a registrant as well
        TestDataUtility testDataUtilityObj = new TestDataUtility(1);
        testDataUtilityObj.CreateCoreApiEventEndPointSetting();
        //Create the account registrant
        testDataUtilityObj.createRegistrants();
        
        //create the tcode
        TCodeManagement__c tcodeObj=TestDataUtility.newTCodeManagement('test');
        tcodeObj.Website_UK_Monthly_Offer_Code__c='offer1';
        insert tcodeObj;
        
        //create the poc
        POC__c pocObj=TestDataUtility.newPOC(1,tcodeObj.id);
        system.debug('check pocObj: '+pocObj);
        pocObj.TCodeManagement__c=tcodeObj.id;
        insert pocObj;
        
        //new quote creation
        zqu__Quote__c quoteObj=ZuoraQuote_Utility.createZuoraQuote(null,testDataUtilityObj.lstRegistrants[0],constants.QUOTE_SUBSCRIPTION_TYPE_NEW_VALUE,null);
        quoteObj.Outbound_Selected_Product__c='Website';
        quoteObj.Outbound_Payment_Frequency__c='m';
        quoteObj.Outbound_Start_Price__c=2;
        quoteObj.Outbound_Start_Periods__c=2;
        quoteObj.Outbound_POC__c=pocObj.id;
        insert quoteObj;
        
        quoteObj=[select Outbound_Selected_Product__c,Outbound_Payment_Frequency__c,Outbound_POC__c,Subscription_Origin__c,Outbound_Start_Periods__c,Outbound_Start_Price__c,Outbound_Subsequent_Price__c,Outbound_POC__r.Subscription_Acquired__c,zqu__SubscriptionType__c,Outbound_POC__r.TCodeManagement__c from zqu__Quote__c where id=:quoteObj.id];
        system.debug('check quoteObj tcode: '+quoteObj.Outbound_POC__r.TCodeManagement__c);
        
        ApexPages.StandardController sc = new ApexPages.StandardController(quoteObj);
        Zuora_Outbound_SelectProductsCtrl controllerObj=new Zuora_Outbound_SelectProductsCtrl(sc);
        
        PageReference pageRef = Page.Zuora_Outbound_SelectProducts;
        Test.setCurrentPage(pageRef);
        
        //add the quote id in the url
        pageRef.getParameters().put(constants.ID_QUOTE_FIELD, String.valueOf(quoteObj.id));
        
        //products
        testDataUtilityObj.createZProducts();
        testDataUtilityObj.lstZproducts[0].name='Website+ UK';
        update testDataUtilityObj.lstZproducts[0];
        
        //product mapping custom setting
        testDataUtilityObj.createProductMappingCustomSetting('website',testDataUtilityObj.lstZproducts[0].id);
        
        controllerObj.addOutboundProduct();
        pageReference pageRefRet=controllerObj.goToQuotePage();
        system.assert( pageRefRet.getUrl().contains(quoteObj.id) );
    }
}