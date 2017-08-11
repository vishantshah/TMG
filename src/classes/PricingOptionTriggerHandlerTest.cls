@isTest
private class PricingOptionTriggerHandlerTest {

    static testMethod void fpOnOptionCreate() {
        //Create a fulfillmentplan
        FulfillmentPlan__c fp = new FulfillmentPlan__c();
        fp.Entitlements__c = 'Entitlement1;Entitlement2';
        fp.ProductType__c = 'Digital';
        insert fp;
        
        //create a pricing option
        Pricing_Options__c po = new Pricing_Options__c();
        po.Product_Type__c = 'digital';
        insert po;
        
        po = [select FulfillmentPlanId__c from Pricing_Options__c];
        system.assertEquals(fp.Id, po.FulfillmentPlanId__c);
    }

    static testMethod void fpOnOptionUpdate() {
        //Create a fulfillmentplan
        FulfillmentPlan__c fp = new FulfillmentPlan__c();
        fp.Entitlements__c = 'Entitlement1;Entitlement2';
        fp.ProductType__c = 'Digital';
        insert fp;
        
        //create a pricing option
        Pricing_Options__c po = new Pricing_Options__c();
        insert po;
        
		Test.startTest();
        po.Product_Type__c = 'digital';
        update po;
        Test.stopTest();
        
        po = [select FulfillmentPlanId__c from Pricing_Options__c];
        system.assertEquals(fp.Id, po.FulfillmentPlanId__c);
    }
}