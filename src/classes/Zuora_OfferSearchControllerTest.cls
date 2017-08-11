/**
* Author:       Sally ElGhoul (Accenture)
* Date:         13/01/2016
* Description:  this class for testing Zuora_OfferSearchController
*
* ******************* Change Log *******************
* Modified by       Change Date
* Sally ElGhoul     4/2/2016 updating code coverage code after adding picklist filters
* Sally ElGhoul     19/2/2016 - cover the new properties added in the custom setting
* Wiktor Czykin     05/10/2016 - added only some minor assertions as test class either way needs full rewrite
* Wiktor Czykin     06/06/2017 - rewritten
**/
@isTest
private class Zuora_OfferSearchControllerTest{

    /*************************************************************************************** 
    Developer   Wiktor Czykin
    Date        06/06/2017
    Function    Test constructor init
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/ 
    private static testMethod void testConstructor(){
        Test.startTest();
            Zuora_OfferSearchController zc = new Zuora_OfferSearchController();
            System.assertEquals(Zuora_OfferSearchController.SEARCH_CAMPAIGN_OPTION, zc.strSelectedSearchCriteria);
            System.assertEquals(Zuora_OfferSearchController.SEARCH_CAMPAIGN_OPTION, zc.campaignSearchOptionValue);
            System.assert(!zc.displayFilteredOffers);
            System.assertNotEquals(null, zc.lstAvailableOpenOffers);
            System.assertNotEquals(null, zc.lstAvailablePromotionalOffers);
            System.assertNotEquals(null, zc.lstFilteredPromotionalOffers);
            System.assertNotEquals(null, zc.lstVisiblePromotionalOffers);
            System.assertEquals(Zuora_OfferSearchController.SORT_ASCENDING, Zuora_OfferSearchController.sortOrder);
        Test.stopTest();
    }

    /*************************************************************************************** 
    Developer   Wiktor Czykin
    Date        06/06/2017
    Function    Test retrieval of offers details based on offer id
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/ 
    private static testMethod void testOfferDetailsRetrieval(){
        TestDataUtility td = new TestDataUtility(1);
        td.createOffers();
        Offer__c o = td.lstOffers[0];
        o.Discount__c = 1;
        o.Discount_Duration__c = 1;
        update o;

        Test.startTest();
            Zuora_OfferSearchController zc = new Zuora_OfferSearchController();
            //test offer found
            zc.strSelectedOfferCode = o.Id; 
            zc.getOfferDetails();
            System.assertEquals(o.Frequency__c, zc.strSelectedRatePlan);
            System.assertNotEquals(null, zc.selectedOfferCodeDetailsObj);
            System.assertEquals(o.Name__c, zc.selectedOfferCodeDetailsObj.name);
            System.assertEquals(o.Description__c, zc.selectedOfferCodeDetailsObj.description);
            System.assertEquals(o.Free_Trial__c, zc.selectedOfferCodeDetailsObj.containsFreeTrial);
            System.assertEquals(o.Is_Restricted__c, zc.selectedOfferCodeDetailsObj.isRestricted);
            System.assertEquals(o.Name, zc.selectedOfferCodeDetailsObj.tmgId);
            System.assertEquals(o.Friendly_Name__c, zc.selectedOfferCodeDetailsObj.friendlyName);
            System.assertEquals(o.Base_Price__c, zc.selectedOfferCodeDetailsObj.basePrice);
            System.assertEquals(12, zc.lstInvoices.size());
            System.assertEquals(o.Base_Price__c-o.Discount__c, zc.lstInvoices[0].invoiceAmount);
            System.assertEquals(o.Base_Price__c, zc.lstInvoices[1].invoiceAmount);
            System.assertEquals(o.Base_Price__c, zc.lstInvoices[11].invoiceAmount);
            //test offer not found
            delete o;
            zc.getOfferDetails();
            System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Offer_Search_No_offer_found));

        Test.stopTest();
    }

    /*************************************************************************************** 
    Developer   Wiktor Czykin
    Date        06/06/2017
    Function    Test retrieval of all available offers
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/ 
    private static testMethod void testLoadAvailableOffers(){
        TestDataUtility td = new TestDataUtility(5);
        td.createTCodeProductOffers();
        td.lstTCodeManagement[0].Type__c = Constants.TCODE_TYPE_OPENOFFER;
        update td.lstTCodeManagement[0];

        Test.startTest();
            Zuora_OfferSearchController zc = new Zuora_OfferSearchController();
            zc.loadAllAvailableOffers();
            System.assertEquals(1, zc.lstAvailableOpenOffers.size());
            System.assertEquals(4, zc.lstAvailablePromotionalOffers.size());
            System.assertEquals(4, zc.lstVisiblePromotionalOffers.size());
            System.assertEquals(5, zc.lstPromotionalOfferProducts.size());
            System.assertEquals(1, zc.lstPromotionalOfferFrequencies.size());
            System.assertEquals(5, zc.lstPromotionalOfferCampaignNames.size());
        Test.stopTest();
    }

    /*************************************************************************************** 
    Developer   Wiktor Czykin
    Date        06/06/2017
    Function    Test some getters and setters not covered elsewhere
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/ 
    private static testMethod void testGettersSetters(){
        Test.startTest();
            Zuora_OfferSearchController zc = new Zuora_OfferSearchController();
            //test search options getter
            System.assertEquals(3, zc.getlstSearchOptions().size());
            
            //test sort order switch in setter
            System.assertEquals(zc.ascendingOrderValue, zc.sortDirection);
            zc.sortExpression = zc.sortByTcodeNameValue;
            System.assertEquals(zc.ascendingOrderValue, zc.sortDirection);
            zc.sortExpression = zc.sortByTcodeNameValue;
            System.assertEquals(zc.descendingOrderValue, zc.sortDirection);

            //test getPromotionalOffersSectionLabel();
            System.assertEquals(Label.Offer_Search_Promotional_Offers_Section_Label, zc.getPromotionalOffersSectionLabel());
            zc.displayFilteredOffers = true;
            System.assertEquals(Label.Offer_Search_Promotional_Offers_Search_Result_Section_Label, zc.getPromotionalOffersSectionLabel());

            //test refreshSearchPanel()
            zc.strSearchText = 'blabla';
            zc.strPOCSearchLastName = 'blabla';
            zc.strPOCSearchPostalCode = 'blabla';
            zc.refreshSearchPanel();
            System.assert(String.isBlank(zc.strSearchText) && String.isBlank(zc.strPOCSearchLastName) && String.isBlank(zc.strPOCSearchPostalCode));
        Test.stopTest();
    }

    /*************************************************************************************** 
    Developer   Wiktor Czykin
    Date        06/06/2017
    Function    Test search offer functionality - positive
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/ 
    private static testMethod void testSearchOffers(){
        TestDataUtility td = new TestDataUtility(4);
        td.createTCodeProductOffers();
        td.createPOCs(1);
        td.lstPOCs[3].LastName__c = 'someOtherName3';
        update td.lstPOCs[3];

        td.lstTCodeManagement[0].Type__c = Constants.TCODE_TYPE_OPENOFFER;
        update td.lstTCodeManagement[0];
        Test.startTest();
            Zuora_OfferSearchController zc = new Zuora_OfferSearchController();
            zc.loadAllAvailableOffers();

            //test search offer by tcode name
            System.assertEquals(td.iCounter, zc.lstPromotionalOfferProducts.size());
            zc.strSearchText = td.lstTCodeManagement[1].Name;
            zc.strSelectedSearchCriteria = zc.campaignSearchOptionValue;
            zc.searchOffers();
            System.assertEquals(1, zc.lstFilteredPromotionalOffers.size());
            System.assertEquals(1, zc.lstVisiblePromotionalOffers.size());  
            System.assertEquals(1, zc.lstPromotionalOfferProducts.size());
            System.assertEquals(td.lstTCodeManagement[1].Name, zc.lstFilteredPromotionalOffers[0].tcodeObj.Name);
            
            //test search offer by poc id
            zc.strSelectedSearchCriteria = zc.pocIDSearchOptionValue;
            zc.strSearchText = td.lstPOCs[2].POC_ID__c;
            zc.searchOffers();
            System.assertEquals(td.lstTCodeManagement[2].Name, zc.lstFilteredPromotionalOffers[0].tcodeObj.Name);

            //test search offer by poc last name and post code
            zc.strSearchText = '';
            zc.strPOCSearchLastName = td.lstPOCs[3].LastName__c;
            zc.strPOCSearchPostalCode = td.lstPOCs[3].PostalCode__c;
            zc.strSelectedSearchCriteria = zc.pocLastNamePostalCodeOptionValue;
            zc.searchOffers();
            System.assertEquals(td.lstTCodeManagement[3].Name, zc.lstFilteredPromotionalOffers[0].tcodeObj.Name);
        Test.stopTest();
    }

    /*************************************************************************************** 
    Developer   Wiktor Czykin
    Date        06/06/2017
    Function    Test search offer failures
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/ 
    private static testMethod void testInvalidSearchOffers(){
        Test.startTest();
            Zuora_OfferSearchController zc = new Zuora_OfferSearchController();
            zc.strSelectedSearchCriteria = zc.campaignSearchOptionValue;
            zc.searchOffers();
            System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Offer_Search_Text_Search_Missing_Error_Message));
            
            zc.strSelectedSearchCriteria = zc.pocLastNamePostalCodeOptionValue ;
            zc.searchOffers();
            System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Offer_Search_Last_Name_Postal_Code_Search_Error_Message));
        Test.stopTest();
    }

    /*************************************************************************************** 
    Developer   Wiktor Czykin
    Date        06/06/2017
    Function    Test filtering of offers
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/ 
    private static testMethod void testOffersFilter(){
        TestDataUtility td = new TestDataUtility(3);
        td.createTCodeProductOffers();
        td.lstOffers[1].Frequency__c = Constants.OFFER_FREQUENCY_ANNUALLY;
        update td.lstOffers[1];

        Test.startTest();
            Zuora_OfferSearchController zc = new Zuora_OfferSearchController();
            zc.loadAllAvailableOffers();
            System.assertEquals(3, zc.lstVisiblePromotionalOffers.size());
            //filter
            zc.strSelectedFilterProductName = td.lstZProducts[0].Name;
            zc.filterOffers();
            System.assertEquals(1, zc.lstVisiblePromotionalOffers.size());
            System.assertEquals(td.lstOffers[0].Id, zc.lstVisiblePromotionalOffers[0].offerId);
            //restore
            zc.showAllOffers();
            System.assertEquals(3, zc.lstVisiblePromotionalOffers.size());

            //filter
            zc.strSelectedFilterProductName ='';
            zc.strSelectedFilterCampaignName = td.lstTCodeManagement[1].Description__c;
            zc.filterOffers();
            System.assertEquals(1, zc.lstVisiblePromotionalOffers.size());
            System.assertEquals(td.lstOffers[1].Id, zc.lstVisiblePromotionalOffers[0].offerId);

            //filter
            zc.strSelectedFilterProductName ='';
            zc.strSelectedFilterCampaignName = '';
            zc.strSelectedFilterFrequency = td.lstOffers[0].Frequency__c;
            zc.filterOffers();
            System.assertEquals(2, zc.lstVisiblePromotionalOffers.size());
        Test.stopTest();
    }


    /*************************************************************************************** 
    Developer   Wiktor Czykin
    Date        06/06/2017
    Function    Test sorting - basic - not thorough
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/ 
    private static testMethod void testOffersSorting(){
        TestDataUtility td = new TestDataUtility(3);
        td.createTCodeProductOffers();
        Integer i = 1;
        for(Offer__c o : td.lstOffers){
            o.Weekly_Advertised_Price__c = i;
            i++;
        }
        update td.lstOffers;

        Test.startTest();
            Zuora_OfferSearchController zc = new Zuora_OfferSearchController();
            zc.loadAllAvailableOffers();
            zc.sortExpression = zc.sortByTcodeDescriptionValue;
            zc.sortData();
            zc.sortExpression = zc.sortByTcodeDescriptionValue;
            zc.sortData();

            zc.sortExpression = zc.sortByOfferFriendlyNameValue;
            zc.sortData();
            zc.sortExpression = zc.sortByOfferFriendlyNameValue;
            zc.sortData();

            zc.sortExpression = zc.sortProductNameValue;
            zc.sortData();
            zc.sortExpression = zc.sortProductNameValue;
            zc.sortData();

            zc.sortExpression = zc.sortProductFrequencyValue;
            zc.sortData();
            zc.sortExpression = zc.sortProductFrequencyValue;
            zc.sortData();

            zc.sortExpression = zc.sortProductWeeklyPrice;
            zc.sortData();
            zc.sortExpression = zc.sortProductWeeklyPrice;
            zc.sortData();

            zc.sortExpression = zc.sortBasePrice;
            zc.sortData();
            zc.sortExpression = zc.sortBasePrice;
            zc.sortData();

            zc.sortExpression = zc.sortByTcodeNameValue;
            zc.sortData();
            zc.sortExpression = zc.sortByTcodeNameValue;
            zc.sortData();
        Test.stopTest();
    }
}
