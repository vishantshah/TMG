@isTest
private class FulfillmentPlanManagerControllerTest {

    private static testMethod void createNewFulfillmentPlanTest() {
        createEntitlementRecords();
        
        PageReference testPage = Page.FulfillmentPlanManager;
        Test.setCurrentPageReference(testPage);
        
        FulfillmentPlan__c fp = new FulfillmentPlan__c(ProductType__c = 'Test');
        FulfillmentPlanManagerController controller = new FulfillmentPlanManagerController(new ApexPages.Standardcontroller(fp));

        system.assertEquals(5, controller.AvailableEntitlementsForDisplay.size());
        system.assertEquals(0, controller.CurrentEntitlementsForDisplay.size());
        
        //Add items 
        controller.AvailableSelected = new string[]{'Entitlement 1', 'Entitlement 3'};
        controller.AddItems();
        
        system.assertEquals(3, controller.AvailableEntitlementsForDisplay.size());
        system.assertEquals(0, controller.AvailableSelected.size());
        
        system.assertEquals(2, controller.CurrentEntitlementsForDisplay.size());
        system.assertEquals(0, controller.CurrentSelected.size());
        
		//Select these,  but,  don't add - should be ignored on Save
		controller.AvailableSelected = new string[]{'Entitlement 2', 'Entitlement 4'};
		
        controller.Save();
        system.assertEquals(0, controller.AvailableSelected.size());
        system.assertEquals(0, controller.CurrentSelected.size());
        
        fp = [select id, Entitlements__c, ProductType__c from FulfillmentPlan__c];
        system.assert(fp.Entitlements__c.contains('Entitlement 1;'));
        system.assert(fp.Entitlements__c.contains('Entitlement 3;'));
        system.assertEquals(2, fp.Entitlements__c.split(';').size());
        system.assertEquals('Test', fp.ProductType__c);
    }

    private static testMethod void editFulfillmentPlanTest() {
        createEntitlementRecords();
        
        PageReference testPage = Page.FulfillmentPlanManager;
        Test.setCurrentPageReference(testPage);
        
        FulfillmentPlan__c fp = new FulfillmentPlan__c(ProductType__c = 'Test', Entitlements__c = 'Entitlement 1;Entitlement 3;');
        insert fp;
        
        FulfillmentPlanManagerController controller = new FulfillmentPlanManagerController(new ApexPages.Standardcontroller(fp));

        system.assertEquals(3, controller.AvailableEntitlementsForDisplay.size());
        system.assertEquals(0, controller.AvailableSelected.size());
        
        system.assertEquals(2, controller.CurrentEntitlementsForDisplay.size());
        system.assertEquals(0, controller.CurrentSelected.size());
        
        controller.CurrentSelected = new string[]{'Entitlement 3'};
        controller.RemoveItems();
        
        system.assertEquals(4, controller.AvailableEntitlementsForDisplay.size());
        system.assertEquals(1, controller.CurrentEntitlementsForDisplay.size());
        
        //Select this,  but don't hit remove - should be ignored on Save
        controller.CurrentSelected = new string[]{'Entitlement 1'};
        
        controller.Save();
        
        system.assertEquals(0, controller.AvailableSelected.size());
        system.assertEquals(0, controller.CurrentSelected.size());
        
        fp = [select id, Entitlements__c, ProductType__c from FulfillmentPlan__c];
        system.assert(fp.Entitlements__c.contains('Entitlement 1;'));
        system.assertEquals(1, fp.Entitlements__c.split(';').size());
    }

    private static testMethod void noItemSelectedTest() {
        createEntitlementRecords();
        
        PageReference testPage = Page.FulfillmentPlanManager;
        Test.setCurrentPageReference(testPage);
        
        FulfillmentPlan__c fp = new FulfillmentPlan__c(ProductType__c = 'Test');        
        FulfillmentPlanManagerController controller = new FulfillmentPlanManagerController(new ApexPages.Standardcontroller(fp));
    	
    	controller.Save();
    	
    	list<Apexpages.Message> errorMessages = ApexPages.getMessages();
    	system.assertEquals(1, errorMessages.size());
    }
    
    private static testMethod void backLinkTest(){
        createEntitlementRecords();
        
        PageReference testPage = Page.FulfillmentPlanManager;
        Test.setCurrentPageReference(testPage);
        
        FulfillmentPlan__c fp = new FulfillmentPlan__c(ProductType__c = 'Test', Entitlements__c = 'Entitlement 1;Entitlement 3;');
        insert fp;
        
        FulfillmentPlanManagerController controller = new FulfillmentPlanManagerController(new ApexPages.Standardcontroller(fp));
    	Pagereference pr = controller.Back();
    	
    	system.assertEquals('/' + string.valueOf(fp.Id).left(3) + '/o', pr.getURL());
    }

    private static testMethod void fooTest() {
        createEntitlementRecords();
        
        PageReference testPage = Page.FulfillmentPlanManager;
        Test.setCurrentPageReference(testPage);
        
        FulfillmentPlan__c fp = new FulfillmentPlan__c();
        FulfillmentPlanManagerController controller = new FulfillmentPlanManagerController(new ApexPages.Standardcontroller(fp));
        
        controller.AvailableSelected = new string[]{'Entitlement 1', 'Entitlement 3'};
        controller.AddItems();
        
        controller.Save();
    	
    	list<Apexpages.Message> errorMessages = ApexPages.getMessages();
    	system.assertEquals(1, errorMessages.size());
    }
    
    private static void createEntitlementRecords(){
    	
    	list<SAM_Entitlement__c> entitlements = new list<SAM_Entitlement__c>();
    	entitlements.add(new SAM_Entitlement__c(Name = 'Entitlement 1'));
    	entitlements.add(new SAM_Entitlement__c(Name = 'Entitlement 2'));
    	entitlements.add(new SAM_Entitlement__c(Name = 'Entitlement 3'));
    	entitlements.add(new SAM_Entitlement__c(Name = 'Entitlement 4'));
    	entitlements.add(new SAM_Entitlement__c(Name = 'Entitlement 5'));
    	
    	insert entitlements;    	
    }
}