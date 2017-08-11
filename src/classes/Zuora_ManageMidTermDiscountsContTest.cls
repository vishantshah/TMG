/**
* Author:       Sally ElGhoul (Accenture)
* Date:         30/10/2015
* Description:  this is the testing class for Zuora_ManageMidTermDiscountsController
*
* ******************* Change Log *******************
* Modified by       Change Date     
* Sally ElGhoul     02/03/2016 Apply changes to the test class after changing how mid term discounts is behaving
* Sally ElGhoul     10/03/2016 do code coverage for mid-term discount modification
* Wiktor Czykin     06/06/2017 removed reference to TestDataUtility createZquotesWithProduct() method
**/
@isTest (seeAllData=true)
private class Zuora_ManageMidTermDiscountsContTest {

    /*************************************************************************************** 
    Developer - Sally ElGhoul (Accenture)
    Date - 02/03/2016
    Version - 1.0
    Function - Redirect the user to page manage mid term discount without passing the subscription ID
    #############Change Log#############
    Modified by     Version     Change Date
    Sally ElGhoul   1.1         10/3/2016   test the reset functionality
    ****************************************************************************************/
    static testMethod void testSubscriptionNotPassed() {
        
        //Create zquote record and this function will create a registrant as well
        TestDataUtility testDataUtilityObj = new TestDataUtility(1);
        
        //Create the account registrant
        testDataUtilityObj.createRegistrants();
        
        //create the quote
        testDataUtilityObj.createZquotes();
        
        //Mid Term Discount Page
        PageReference pageRef = Page.Zuora_ManageMidTermDiscounts;
        
        //set the current testing page
        Test.setCurrentPage(pageRef); 
        
        //no query string passed
        Zuora_ManageMidTermDiscountsController controllerObj=new Zuora_ManageMidTermDiscountsController();
        System.assertEquals(true, ApexPages.hasMessages(ApexPages.Severity.ERROR));
    }
    
    /*************************************************************************************** 
    Developer - Sally ElGhoul (Accenture)
    Date - 02/03/2016
    Function - Redirect the user to page manage mid term discount and pass the subscription ID and do several operations
    #############Change Log#############
    Modified by     Change Date
    Wiktor Czykin   06/06/2017  removed reference to createZquotesWithProduct()
    ****************************************************************************************/
    static testMethod void testSubscriptionPassed() {
       
        //Create zquote record and this function will create a registrant as well
        TestDataUtility testDataUtilityObj = new TestDataUtility(1);
        
        //create the quote
        testDataUtilityObj.createQuoteRatePlanCharges();
        
        //create the discount rate plan for mid term discount and for the empty discount
        List<zqu__ProductRatePlan__c> lstRatePlans=new List<zqu__ProductRatePlan__c>();
        List<zqu__ProductRatePlanCharge__c> lstRatePlanCharges=new List<zqu__ProductRatePlanCharge__c>();
        
        //Mid Term disount
        zqu__ProductRatePlan__c midTermDiscountRatePlanObj=new zqu__ProductRatePlan__c();
        midTermDiscountRatePlanObj.name=Constants.MID_TERM_DISCOUNT_RATE_PLAN_NAME;
        midTermDiscountRatePlanObj.zqu__ZProduct__c=testDataUtilityObj.lstZproducts[0].id;
        midTermDiscountRatePlanObj.zqu__EffectiveStartDate__c=Date.Today();
        midTermDiscountRatePlanObj.zqu__EffectiveEndDate__c=Date.today().addYears(1);
        midTermDiscountRatePlanObj.zqu__ZuoraId__c='3333353';
        lstRatePlans.add(midTermDiscountRatePlanObj);
        
        //empty discount
        zqu__ProductRatePlan__c emptyDiscountRatePlan=new zqu__ProductRatePlan__c();
        emptyDiscountRatePlan.name=Constants.EMPTY_DISCOUNT_RATE_PLAN_NAME;
        emptyDiscountRatePlan.zqu__ZProduct__c=testDataUtilityObj.lstZproducts[0].id;
        emptyDiscountRatePlan.zqu__EffectiveStartDate__c=Date.Today();
        emptyDiscountRatePlan.zqu__EffectiveEndDate__c=Date.today().addYears(1);
        emptyDiscountRatePlan.zqu__ZuoraId__c='3333343';
        lstRatePlans.add(emptyDiscountRatePlan);
        
        insert lstRatePlans;
        
        //add the charges for the discount rate plans
        Integer counter=1;
        for(zqu__ProductRatePlan__c rateplanObj : lstRatePlans){
                zqu__ProductRatePlanCharge__c chargeObj=new zqu__ProductRatePlanCharge__c();
                chargeObj.name=rateplanObj.name;
                chargeObj.zqu__Apply_Discount_To_Recurring_Charges__c=true;
                chargeObj.zqu__Apply_Discount_To_One_Time_Charges__c=false;
                chargeObj.zqu__Apply_Discount_To_Usage_Charges__c=false;
                chargeObj.zqu__DefaultQuantity__c=1;
                chargeObj.zqu__Discount_Level__c='Subscription';
                chargeObj.zqu__Model__c='Flat Fee';
                chargeObj.zqu__ProductRatePlan__c=rateplanObj.id;
                chargeObj.zqu__RecurringPeriod__c='Month';
                chargeObj.zqu__Type__c='Recurring';
                chargeObj.zqu__ZuoraId__c=rateplanObj.zqu__ZuoraId__c+string.valueof(counter);
                lstRatePlanCharges.add(chargeObj);
                counter++;
        }
        insert lstRatePlanCharges;
        
        //create billing account
        testDataUtilityObj.createBillingAccountToRegistrant(testDataUtilityObj.lstRegistrants[0].id,Constants.PAYMENT_METHOD_CREDIT_CARD_TYPE);
        
        //cerate subscription
        testDataUtilityObj.createZuoraSubscriptionToRegistrant(testDataUtilityObj.lstRegistrants[0].id);
        testDataUtilityObj.lstZuoraSubscriptions[0].Zuora__ServiceActivationDate__c=Date.today();
        testDataUtilityObj.lstZuoraSubscriptions[0].Zuora__Zuora_Id__c='12234556';
        update testDataUtilityObj.lstZuoraSubscriptions[0];
        
        //create subscription product charge
        testDataUtilityObj.createSubscriptionProductCharges(testDataUtilityObj.lstZuoraSubscriptions[0].id);
        
        Zuora__Product__c chargeProduct=new Zuora__Product__c(Name=testDataUtilityObj.lstZproducts[0].name,Zuora__External_Id__c=testDataUtilityObj.lstZproducts[0].zqu__ZuoraId__c);
        insert chargeProduct;
        testDataUtilityObj.lstZuoraSubscriptionProductCharges[0].Zuora__Product__c=chargeProduct.id;
        update testDataUtilityObj.lstZuoraSubscriptionProductCharges[0];
        
        //Mid Term Discount Page
        PageReference pageRef = Page.Zuora_ManageMidTermDiscounts;
        
        //set the current testing page
        Test.setCurrentPage(pageRef); 
        
        //pass the subscription id 
        pageRef.getParameters().put(Constants.SUBSCRIPTION_ID_QUERY_STRING, testDataUtilityObj.lstZuoraSubscriptions[0].id);
        
        //check that the subscription is found
        Zuora_ManageMidTermDiscountsController controllerObj=new Zuora_ManageMidTermDiscountsController();
        System.assert(controllerObj.currentSubscriptionObj!=null);
        
        //get the List of possible effective dates
        List<SelectOption> lstEffectiveDates=controllerObj.getPossibleEffectiveDates();
        System.assertEquals(lstEffectiveDates.size(),2);
        
        //try to add a new discount without adding the required fields and check error is thrown
        controllerObj.addNewDiscount();
        System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Mid_Term_Effective_Date_Required));
        
        //choose an effective date and try to add a discount without specifying the number of periods and check the error message
        Datetime invoiceItemDateTime=Datetime.newInstance(Date.today().year(),Date.today().month(),Date.today().day());
        controllerObj.selectedEffectiveDate=invoiceItemDateTime.format('dd/MM/YYYY');
        controllerObj.getNumberOfPeriods();
        controllerObj.addNewDiscount();
        System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Mid_Term_Number_of_Periods_Required));
        
        //choose a value for the number of periods and pass an invalid discount amount and try to add the discount and validate the error message
        controllerObj.selectedNumberOfPeriods='1';
        controllerObj.discountAmount=-1;
        controllerObj.addNewDiscount();
        System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Mid_Term_Discount_Amount_Invalid_Error_Message));
        
        //pass a valid discount amount and make sure that the discount is added successfully
        controllerObj.discountAmount=0.5;
        controllerObj.addNewDiscount();
        System.assertEquals(controllerObj.lstNewMidTermDiscounts.size(),1);
        
        //try to save the discount without entering a mid term disocunt reason and validate an error is thrown
        controllerObj.saveMidTermDiscounts();
        System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Mid_term_Discount_Reason_Error_Message));
        
        //enter a mid term discount reason and save the discount and validate that total invoices will decrease due to discount amount
        controllerObj.quoteObj.Mid_term_Discount_Reason__c='Testing';
        controllerObj.saveMidTermDiscounts();
        Decimal totalInvoices=controllerObj.gettotalInvoices();
        System.assertEquals(totalInvoices,9.5);
        
        //try to remove the mid term discount and validate that the total invoice is increased again and that the discount is removed from the List
        controllerObj.lstNewMidTermDiscounts[0].isDelete=true;
        controllerObj.removeNewDiscount();
        System.assertEquals(controllerObj.lstNewMidTermDiscounts.size(),0);
        totalInvoices=controllerObj.gettotalInvoices();
        System.assertEquals(totalInvoices,10);
        
        controllerObj.reset();
        System.assertEquals(controllerObj.lstNewMidTermDiscounts.size(),0);
        System.assert(String.isEmpty(controllerObj.quoteObj.Mid_term_Discount_Reason__c));
        
        //increase the code coverage by calling the functions that redirect the user to different locations
        System.assert(controllerObj.stayOnPage()==null);
        System.assert(controllerObj.cancel().getUrl().contains('/'+testDataUtilityObj.lstZuoraSubscriptions[0].id));
        System.assertEquals(controllerObj.goToHomePage().getUrl().contains('Zuora_ManageMidTermDiscounts'),false);
    }
    
    /*************************************************************************************** 
    Developer - Sally ElGhoul (Accenture)
    Date - 10/03/2016
    Version - 1.0
    Function - Test that there is already a discount added 
    #############Change Log#############
    Modified by     Change Date
    Wiktor Czykin   06/06/2017  removed reference to createZquotesWithProduct()
    ****************************************************************************************/
    static testMethod void testSubscriptionWithDiscount() {
       
        //Create zquote record and this function will create a registrant as well
        TestDataUtility testDataUtilityObj = new TestDataUtility(1);
        testDataUtilityObj.createQuoteRatePlanCharges();
        
        //create the discount rate plan for mid term discount and for the empty discount
        List<zqu__ProductRatePlan__c> lstRatePlans=new List<zqu__ProductRatePlan__c>();
        List<zqu__ProductRatePlanCharge__c> lstRatePlanCharges=new List<zqu__ProductRatePlanCharge__c>();
        
        //Mid Term disount
        zqu__ProductRatePlan__c midTermDiscountRatePlanObj=new zqu__ProductRatePlan__c();
        midTermDiscountRatePlanObj.name=Constants.MID_TERM_DISCOUNT_RATE_PLAN_NAME;
        midTermDiscountRatePlanObj.zqu__ZProduct__c=testDataUtilityObj.lstZproducts[0].id;
        midTermDiscountRatePlanObj.zqu__EffectiveStartDate__c=Date.Today();
        midTermDiscountRatePlanObj.zqu__EffectiveEndDate__c=Date.today().addYears(1);
        midTermDiscountRatePlanObj.zqu__ZuoraId__c='3333353';
        lstRatePlans.add(midTermDiscountRatePlanObj);
        
        //empty discount
        zqu__ProductRatePlan__c emptyDiscountRatePlan=new zqu__ProductRatePlan__c();
        emptyDiscountRatePlan.name=Constants.EMPTY_DISCOUNT_RATE_PLAN_NAME;
        emptyDiscountRatePlan.zqu__ZProduct__c=testDataUtilityObj.lstZproducts[0].id;
        emptyDiscountRatePlan.zqu__EffectiveStartDate__c=Date.Today();
        emptyDiscountRatePlan.zqu__EffectiveEndDate__c=Date.today().addYears(1);
        emptyDiscountRatePlan.zqu__ZuoraId__c='3333343';
        lstRatePlans.add(emptyDiscountRatePlan);
        
        insert lstRatePlans;
        
        //add the charges for the discount rate plans
        Integer counter=1;
        for(zqu__ProductRatePlan__c rateplanObj : lstRatePlans){
                zqu__ProductRatePlanCharge__c chargeObj=new zqu__ProductRatePlanCharge__c();
                chargeObj.name=rateplanObj.name;
                chargeObj.zqu__Apply_Discount_To_Recurring_Charges__c=true;
                chargeObj.zqu__Apply_Discount_To_One_Time_Charges__c=false;
                chargeObj.zqu__Apply_Discount_To_Usage_Charges__c=false;
                chargeObj.zqu__DefaultQuantity__c=1;
                chargeObj.zqu__Discount_Level__c='Subscription';
                chargeObj.zqu__Model__c='Flat Fee';
                chargeObj.zqu__ProductRatePlan__c=rateplanObj.id;
                chargeObj.zqu__RecurringPeriod__c='Month';
                chargeObj.zqu__Type__c='Recurring';
                chargeObj.zqu__ZuoraId__c=rateplanObj.zqu__ZuoraId__c+string.valueof(counter);
                lstRatePlanCharges.add(chargeObj);
                counter++;
        }
        insert lstRatePlanCharges;
        
        //create billing account
        testDataUtilityObj.createBillingAccountToRegistrant(testDataUtilityObj.lstRegistrants[0].id,Constants.PAYMENT_METHOD_CREDIT_CARD_TYPE);
        
        //cerate subscription
        testDataUtilityObj.createZuoraSubscriptionToRegistrant(testDataUtilityObj.lstRegistrants[0].id);
        testDataUtilityObj.lstZuoraSubscriptions[0].Zuora__ServiceActivationDate__c=Date.today();
        testDataUtilityObj.lstZuoraSubscriptions[0].Zuora__Zuora_Id__c='12234556';
        update testDataUtilityObj.lstZuoraSubscriptions[0];
        
        //create subscription product charge
        testDataUtilityObj.createSubscriptionProductCharges(testDataUtilityObj.lstZuoraSubscriptions[0].id);
        
        Zuora__Product__c chargeProduct=new Zuora__Product__c(Name=testDataUtilityObj.lstZproducts[0].name,Zuora__External_Id__c=testDataUtilityObj.lstZproducts[0].zqu__ZuoraId__c);
        insert chargeProduct;
        testDataUtilityObj.lstZuoraSubscriptionProductCharges[0].Zuora__Product__c=chargeProduct.id;
        update testDataUtilityObj.lstZuoraSubscriptionProductCharges[0];
        
        //Mid Term Discount Page
        PageReference pageRef = Page.Zuora_ManageMidTermDiscounts;
        
        //set the current testing page
        Test.setCurrentPage(pageRef); 
        
        //pass the subscription id 
        pageRef.getParameters().put(Constants.SUBSCRIPTION_ID_QUERY_STRING, testDataUtilityObj.lstZuoraSubscriptions[0].id);
        
        Zuora_ManageMidTermDiscountsController controllerObj=new Zuora_ManageMidTermDiscountsController();
        
        //simulate that the subscription has an old discount
        Zuora_ManageMidTermDiscountsController.OfferDetails offerDiscountObj=new Zuora_ManageMidTermDiscountsController.OfferDetails();
        offerDiscountObj.effectiveDate=Date.today();
        offerDiscountObj.numberOfPeriod=1;
        offerDiscountObj.discountAmount=1;
        offerDiscountObj.chargeZuoraId='22223341';
        offerDiscountObj.isOldDiscount=true;
        controllerObj.lstNewMidTermDiscounts.add(offerDiscountObj);
        
        //add a fake discount and remove it to update the billing preview details
        Datetime invoiceItemDateTime=Datetime.newInstance(Date.today().year(),Date.today().month(),Date.today().day());
        controllerObj.selectedEffectiveDate=invoiceItemDateTime.format('dd/MM/YYYY');
        controllerObj.selectedNumberOfPeriods='1';
        controllerObj.discountAmount=0.5;
        controllerObj.addNewDiscount();
        controllerObj.lstNewMidTermDiscounts[1].isDelete=true;
        controllerObj.removeNewDiscount();
        
        //get the List of possible effective dates
        List<SelectOption> lstEffectiveDates=controllerObj.getPossibleEffectiveDates();
        System.assertEquals(lstEffectiveDates.size(),1);
        
        //delete the old discount
        System.assertEquals(controllerObj.getIsRenderMidTermReason(),false);
        controllerObj.lstNewMidTermDiscounts[0].isDelete=true;
        System.assertEquals(controllerObj.lstInvoiceItems[0].invoiceItemAmount,10);
        controllerObj.removeNewDiscount();
        controllerObj.saveMidTermDiscounts();
        System.assertEquals(controllerObj.lstInvoiceItems[0].invoiceItemAmount,11);
        System.assertEquals(controllerObj.getIsRenderMidTermReason(),true);
        
        //get the List of possible effective dates
        lstEffectiveDates=controllerObj.getPossibleEffectiveDates();
        System.assertEquals(lstEffectiveDates.size(),2);
    }
}