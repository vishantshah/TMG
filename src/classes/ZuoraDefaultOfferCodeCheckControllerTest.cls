/**
* Author:       Sally ElGhoul (Accenture)
* Date:         12/10/2015
* Description:  this is testing class for ZuoraDefaultOfferCodeCheckController
*
* ******************* Change Log *******************
* Modified by       Change Date 
* Wiktor Czykin		31/05/2017 //rewritten    
**/
@isTest
private class ZuoraDefaultOfferCodeCheckControllerTest {

	/***************************************************************************************
    Developer   Wiktor Czykin
    Date        31/05/2017
    Function    just common method to init page parameter
    ******************* Change Log *******************
    Modified by         Change Date
    ****************************************************************************************/
    private static void setCurrentReference(String qouteId){
        PageReference pr = Page.ZuoraQuoteOfferSelection;
        pr.getParameters().put(Constants.ID_QUERY_STRING, qouteId);
        Test.setCurrentPage(pr);
    }

    /***************************************************************************************
    Developer   Wiktor Czykin
    Date        31/05/2017
    Function    test no id in parameters
    ******************* Change Log *******************
    Modified by         Change Date
    ****************************************************************************************/
    private static testMethod void testConstructorFailureNoId(){
        Test.startTest();
            try{
                ZuoraDefaultOfferCodeCheckController controller = new ZuoraDefaultOfferCodeCheckController();
                System.assert(false, 'exception not thrown where should be');
            }catch(Exception e){
                System.assert(e.getMessage().contains(Label.Offer_Selection_Wrong_id_parameter_passed));
            }
        Test.stopTest();
    }

    /***************************************************************************************
    Developer   Wiktor Czykin
    Date        31/05/2017
    Function    test that passed id parameter is not of an id type
    ******************* Change Log *******************
    Modified by         Change Date
    ****************************************************************************************/
    private static testMethod void testConstructorFailureNotId(){
        setCurrentReference('blahblah');
        Test.startTest();
            try{
                ZuoraDefaultOfferCodeCheckController controller = new ZuoraDefaultOfferCodeCheckController();
                System.assert(false, 'exception not thrown where should be');
            }catch(Exception e){
                System.assert(e.getMessage().contains(Label.Offer_Selection_Wrong_id_parameter_passed));
            }
        Test.stopTest();
    }

    /***************************************************************************************
    Developer   Wiktor Czykin
    Date        31/05/2017
    Function    test passed id is a valid id but not for quote object
    ******************* Change Log *******************
    Modified by         Change Date
    ****************************************************************************************/
    private static testMethod void testConstructorFailureWrongId(){
        TestDataUtility td = new TestDataUtility(1);
        td.createIndividualSubscribers();
        setCurrentReference(td.lstIndividualSubscribers[0].Id);
        Test.startTest();
            try{
                ZuoraDefaultOfferCodeCheckController controller = new ZuoraDefaultOfferCodeCheckController();
                System.assert(false, 'exception not thrown where should be');
            }catch(Exception e){
                System.assert(e.getMessage().contains(Label.Offer_Selection_Wrong_id_parameter_passed));
            }
        Test.stopTest();
    }

    /***************************************************************************************
    Developer   Wiktor Czykin
    Date        31/05/2017
    Function    test error on no quote rate plan record for quote
    ******************* Change Log *******************
    Modified by         Change Date
    ****************************************************************************************/
    private static testMethod void testNoQuoteRatePlan(){
        TestDataUtility td = new TestDataUtility(1);
        td.createZQuotes();
        setCurrentReference(td.lstZQuotes[0].Id);
        Test.startTest();
            ZuoraDefaultOfferCodeCheckController controller = new ZuoraDefaultOfferCodeCheckController();
            controller.insertDefaultOfferCode();
            System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Offer_Selection_No_quote_rate_plan));
        Test.stopTest();
    }

    /***************************************************************************************
    Developer   Wiktor Czykin
    Date        31/05/2017
    Function    test error on no default offer for related product rate plan
    ******************* Change Log *******************
    Modified by         Change Date
    ****************************************************************************************/
    private static testMethod void testNoOffer(){
        TestDataUtility td = new TestDataUtility(1);
        td.createQuoteRatePlans();
        setCurrentReference(td.lstZQuotes[0].Id);
        delete td.lstOffers;
        Test.startTest();
            ZuoraDefaultOfferCodeCheckController controller = new ZuoraDefaultOfferCodeCheckController();
            controller.insertDefaultOfferCode();
            System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Offer_Selection_No_default_offer_code_found_for_rate_plan));
        Test.stopTest();
    }

    /***************************************************************************************
    Developer   Wiktor Czykin
    Date        31/05/2017
    Function    test positive add of offer with a discount 
    ******************* Change Log *******************
    Modified by         Change Date
    ****************************************************************************************/
    private static testMethod void testAddOfferWithDiscount(){
        TestDataUtility td = new TestDataUtility(1);
        td.createQuoteRatePlanCharges();
        
        td.createTCodeManagement();
        td.lstTCodeManagement[0].Type__c = Constants.TCODE_TYPE_OPENOFFER;
        update td.lstTCodeManagement;
       
        td.lstOffers[0].Discount__c = 1;
        td.lstOffers[0].Discount_Duration__c = 1;
        update td.lstOffers;

        td.createQuoteCharges();
		insert TestDataUtility.newProductRatePlan(10, td.lstZProducts[0].Id, Constants.DISCOUNT_RATE_PLAN_NAME, null);
        setCurrentReference(td.lstZQuotes[0].Id);
        Test.startTest();
            ZuoraDefaultOfferCodeCheckController controller = new ZuoraDefaultOfferCodeCheckController();
            controller.insertDefaultOfferCode();
            System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Default_Offer_Code_Addition_Confirm_Message), ApexPages.getMessages());
        Test.stopTest();
    }

    /***************************************************************************************
    Developer   Wiktor Czykin
    Date        31/05/2017
    Function    test positive add of offer without a discount 
    ******************* Change Log *******************
    Modified by         Change Date
    ****************************************************************************************/
    private static testMethod void testAddOfferWithoutDiscount(){
        TestDataUtility td = new TestDataUtility(1);
        td.createQuoteRatePlanCharges();
       
        td.createTCodeManagement();
        td.lstTCodeManagement[0].Type__c = Constants.TCODE_TYPE_OPENOFFER;
        update td.lstTCodeManagement;
       	td.createQuoteCharges();
		insert TestDataUtility.newProductRatePlan(10, td.lstZProducts[0].Id, Constants.DISCOUNT_RATE_PLAN_NAME, null);
        setCurrentReference(td.lstZQuotes[0].Id);
        update td.lstOffers;
        Test.startTest();
            ZuoraDefaultOfferCodeCheckController controller = new ZuoraDefaultOfferCodeCheckController();
            controller.insertDefaultOfferCode();
            System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Default_Offer_Code_Addition_Confirmation_Message_Zero_Discount), ApexPages.getMessages());
        Test.stopTest();
    }
}