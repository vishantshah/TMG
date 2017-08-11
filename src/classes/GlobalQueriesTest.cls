/**
Name: GlobalQueriesTest
* @author Wiktor Czykin (Tquila)
* @date 02/09/2015
* @description Tests GlobalQueries class
##########Change Log##########
Modified by       Change Date
Wiktor Czykin     07/12/2015  //added missing coverage for new methods
Pawel Chrzanowski 24/05/2016  //added missing coverage for new methods
Wiktor Czykin     26/05/2016  //modified getTcodeProductsTest()
Wiktor Czykin     25/10/2016  //added getProductTcodeIncentivesTest2()
Wiktor Czykin     20/03/2017  //modified testIsEmailUnique()
Wiktor Czykin     30/05/2017  //added test coverage
**/
@isTest
private class GlobalQueriesTest {

  /***************************************************************************************
  Developer - Wiktor Czykin
  Date Created - 17/06/2014
  Version - 1.0
  Function - tests basic functions of GlobalQueries class
  #############Change Log#############
  Modified by         Version     Change Date
  ****************************************************************************************/
    private static testMethod void testSampleQuery() {
      TestDataUtility td = new TestDataUtility(1);
      td.loadSAMHTTPSettings();
        td.loadGeneral();
        td.loadPlaneURL();
      td.createIndividualSubscribers();

      Test.startTest();
        List<Account> lstAccount = Database.query('select '+GlobalQueries.generateFieldsListForQuery('Account', new Set<String>{'Owner.CreatedDate'}, null)+' from Account where Id =\''+td.lstIndividualSubscribers[0].Id+'\'');
        System.assertEquals(1, lstAccount.size(), 'Record not retrieved where it should be.');
        //to make sure it is retrieved from cache
        Set<String> setFieldsForAccount = GlobalQueries.getFieldsForObject('Account');
        System.assert(setFieldsForAccount.contains('firstname'));
        System.assertEquals(null, GlobalQueries.generateFieldsListForQuery(null, null, null));
        System.assertEquals(null, GlobalQueries.generateFieldsListForQuery('xxx', new Set<String>(), null));
      Test.stopTest();
    }

  /***************************************************************************************
  Developer - Wiktor Czykin
  Date Created - 17/06/2014
  Version - 1.0
  Function - tests basic functions of GlobalQueries class #2
  #############Change Log#############
  Modified by         Version     Change Date
  ****************************************************************************************/
    private static testMethod void testFetchOfFieldsData(){
      Test.startTest();
        Map<String,Schema.DescribeFieldResult> mapOfFieldsFetchOne =  GlobalQueries.getFieldsNameToMetaDescriptionMappingForObject('Account');
        Map<String,Schema.DescribeFieldResult> mapOfFieldsFetchTwo =  GlobalQueries.getFieldsNameToMetaDescriptionMappingForObject('Account');
        Map<String,Schema.DescribeFieldResult> mapOfFieldsFetchThree =  GlobalQueries.getFieldsNameToMetaDescriptionMappingForObject('Contact');
        System.assertEquals(null, GlobalQueries.getFieldsNameToMetaDescriptionMappingForObject(''));
      Test.stopTest();
    }

  /***************************************************************************************
  Developer - Wiktor Czykin
  Date Created - 07/12/2015
  Version - 1.0
  Function - test getPricingOptions()
  #############Change Log#############
  Modified by         Version     Change Date
  Michal Szewczyk     1.1         06/04/2016   // added TCode Product relation
  ****************************************************************************************/
    private static testMethod void testGetPricingOptions(){
      TestDataUtility td = new TestDataUtility(1);
      td.createZProduct();
      td.createPricingOptions(td.lstZproducts[0].Id);

      Test.startTest();
        System.assertEquals(null, GlobalQueries.getPricingOptions(null, null, null, null));
        System.assertNotEquals(null, GlobalQueries.getPricingOptions(td.lstZproducts[0].Id, Constants.PRICING_FLOW_TYPE_OPENOFFER, td.mapPricingOptions.get(0).get(0).Subscription_Type__c, td.lstTCodeManagement[0].Name), 'pricing option not found');
      Test.stopTest();
    }

  /***************************************************************************************
  Developer - Wiktor Czykin
  Date Created - 07/12/2015
  Version - 1.0
  Function - test getTCodeBasedOnName()
  #############Change Log#############
  Modified by         Version     Change Date
  ****************************************************************************************/
  private static testMethod void testGetTCodeBasedOnName(){
    TestDataUtility td = new TestDataUtility(1);
    td.createTCodeManagement();

    Test.startTest();
      System.assert(GlobalQueries.getTCodeBasedOnName(null).isEmpty(), 'method returned non-empty list');
      System.assert(!GlobalQueries.getTCodeBasedOnName(td.lstTCodeManagement[0].Name).isEmpty(), 'method returned empty list');
    Test.stopTest();
  }

  /***************************************************************************************
  Developer - Wiktor Czykin
  Date Created - 07/12/2015
  Function - test checkIsEmailUnique()
  #############Change Log#############
  Modified by    Change Date
  Wiktor Czykin  20/03/2017  //removed one assertion as email cannot have duplicates any more but method is still used
  ****************************************************************************************/
  private static testMethod void testIsEmailUnique(){
    TestDataUtility td = new TestDataUtility(1);
    td.createIndividualSubscribers();

    Test.startTest();
      //no id check
      try{
        GlobalQueries.checkIsEmailUnique(null, td.lstIndividualSubscribers[0].PersonEmail);
        System.assert(false, 'exception not thrown where should be');
      }catch(Exception e){}
      //no email check
      System.assertEquals(true, GlobalQueries.checkIsEmailUnique(td.lstIndividualSubscribers[0].Id, ''));
      //actual no duplicate check
      System.assertEquals(true, GlobalQueries.checkIsEmailUnique(td.lstIndividualSubscribers[0].Id, td.lstIndividualSubscribers[0].PersonEmail));
    Test.stopTest();
  }

  /***************************************************************************************
  Developer - Wiktor Czykin
  Date Created - 07/12/2015
  Version - 1.0
  Function - test getVATRateForCountry()
  #############Change Log#############
  Modified by         Version     Change Date
  ****************************************************************************************/
  private static testMethod void testGetVATRateForCountry(){
    TestDataUtility td = new TestDataUtility(1);
    td.loadVAT();
    td.loadCountryCodes();
    VAT__c vat = VAT__c.getInstance(Constants.VAT_SETTINGS_VAT);
    Country_Codes__c cc = Country_Codes__c.getInstance(Constants.COUNTRY_CODE_GB);
    Country_Codes__c ccNonUKInEU = Country_Codes__c.getInstance('PL');
    Country_Codes__c ccNonEU = Country_Codes__c.getInstance('NC');

    System.assert(cc != null && ccNonUKInEU != null && ccNonEU != null, 'required options not available');

    Test.startTest();
      System.assertEquals(null, GlobalQueries.getVATRateForCountry(null, null), 'non null value returned');
      System.assertEquals(vat.UK_Standard_VAT_Rate__c, GlobalQueries.getVATRateForCountry(vat, cc), 'null value returned');
      System.assertEquals(vat.EU_Standard_VAT_Rate__c, GlobalQueries.getVATRateForCountry(vat, ccNonUKInEU), 'null value returned');
      System.assertEquals(0, GlobalQueries.getVATRateForCountry(vat, ccNonEU), 'null value returned');
    Test.stopTest();
  }

  /***************************************************************************************
  Developer - Pawel Chrzanowski
  Date - 24/05/2016
  Function - test for getTCodeNameWithDescriptionBasedOnName() method
  #############Change Log#############
  Modified by     Version     Change Date
  ****************************************************************************************/
  private static testMethod void getTCodeNameWithDescriptionBasedOnNameTest(){
    TestDataUtility td = new TestDataUtility(1);
    td.createTCodeManagement();
    td.lstTCodeManagement[0].Name = 'test';
    td.lstTCodeManagement[0].Description__c = 'test';
    update td.lstTCodeManagement[0];
    System.assert(String.isBlank(GlobalQueries.getTCodeNameWithDescriptionBasedOnName(null)));
    System.assertEquals('test (test)', GlobalQueries.getTCodeNameWithDescriptionBasedOnName('test'));
  }

  /***************************************************************************************
  Developer - Pawel Chrzanowski
  Date - 24/05/2016
  Function - test for getProductTcodeIncentives() method
  #############Change Log#############
  Modified by     Version     Change Date
  ****************************************************************************************/
  private static testMethod void getProductTcodeIncentivesTest(){
    TestDataUtility td = new TestDataUtility(1);
    td.createTCodeProducts();
    td.createIncentives();

    System.assert(GlobalQueries.getProductTcodeIncentives(null).isEmpty());
    System.assert(GlobalQueries.getProductTcodeIncentives(td.lstTCodeProducts[0].Id).isEmpty());

    TCode_Product_Incentive__c tCodeProductIncentive = new TCode_Product_Incentive__c(Incentive__c=td.lstIncentives[0].Id, TCode_Product__c=td.lstTCodeProducts[0].Id);
    insert tCodeProductIncentive;
    System.assertEquals(tCodeProductIncentive.Id, GlobalQueries.getProductTcodeIncentives(td.lstTCodeProducts[0].Id)[0].Id);
  }

  /***************************************************************************************
  Developer - Wiktor Czykin
  Date - 25/10/2016
  Function - test for getProductTcodeIncentives() method - 2 param version
  #############Change Log#############
  Modified by     Version     Change Date
  ****************************************************************************************/
  private static testMethod void getProductTcodeIncentivesTest2(){
    TestDataUtility td = new TestDataUtility(1);
    td.createTCodeProducts();
    td.createIncentives();

    System.assert(GlobalQueries.getProductTcodeIncentives(null, null).isEmpty());
    System.assert(GlobalQueries.getProductTcodeIncentives(td.lstTCodeManagement[0].Id, td.lstZproducts[0].Id).isEmpty());

    TCode_Product_Incentive__c tCodeProductIncentive = new TCode_Product_Incentive__c(Incentive__c=td.lstIncentives[0].Id, TCode_Product__c=td.lstTCodeProducts[0].Id);
    insert tCodeProductIncentive;
    System.assertEquals(tCodeProductIncentive.Id, GlobalQueries.getProductTcodeIncentives(td.lstTCodeManagement[0].Id,  td.lstZproducts[0].Id)[0].Id);
  }

  /***************************************************************************************
  Developer - Pawel Chrzanowski
  Date - 24/05/2016
  Function - test for getTCodeNameBasedOnId() method
  #############Change Log#############
  Modified by     Change Date
  Wiktor Czykin   30/07/2017  //added coverage for one more condition
  ****************************************************************************************/
  private static testMethod void getTCodeNameBasedOnIdTest(){
    TestDataUtility td = new TestDataUtility(1);
    td.createTCodeManagement();
    td.lstTCodeManagement[0].Name = 'test';
    update td.lstTCodeManagement[0];

    System.assertEquals(null, GlobalQueries.getTCodeNameBasedOnId(null));
    System.assertEquals('test', GlobalQueries.getTCodeNameBasedOnId(td.lstTCodeManagement[0].Id));
    delete td.lstTCodeManagement[0];
    System.assertEquals('', GlobalQueries.getTCodeNameBasedOnId(td.lstTCodeManagement[0].Id));
  }

  /***************************************************************************************
  Developer - Pawel Chrzanowski
  Date - 24/05/2016
  Function - test for getTcodeProducts() method
  #############Change Log#############
  Modified by     Version     Change Date
  Wiktor Czykin   1.1         26/05/2016    //modified because of changed default flag for zProduct in TestDataUtility
  ****************************************************************************************/
  private static testMethod void getTcodeProductsTest(){
    TestDataUtility td = new TestDataUtility(1);
    td.createTCodeProducts();

    System.assertEquals(null, GlobalQueries.getTcodeProducts(null, null));
    System.assertEquals(td.lstTCodeProducts[0].Id, GlobalQueries.getTcodeProducts(td.lstTCodeManagement[0].Id, true)[0].Id);
  }

  /***************************************************************************************
  Developer - Pawel Chrzanowski
  Date - 24/05/2016
  Function - test for getTcodeProduct() method
  #############Change Log#############
  Modified by     Version     Change Date
  ****************************************************************************************/
  private static testMethod void getTcodeProductTest(){
    TestDataUtility td = new TestDataUtility(1);
    td.createTCodeProducts();

    System.assertEquals(null, GlobalQueries.getTcodeProduct(null, null));
    System.assertEquals(td.lstTCodeProducts[0].Id, GlobalQueries.getTcodeProduct(td.lstTCodeManagement[0].Id, td.lstZproducts[0].Id).Id);
  }

  /***************************************************************************************
  Developer - Wiktor Czykin
  Date Created - 07/12/2015
  Version - 1.0
  Function - test getDigitalPricingOptionBasedOnSetting()
  #############Change Log#############
  Modified by         Version     Change Date
  ****************************************************************************************/
    private static testMethod void testGetDigitalPricingOption(){
      TestDataUtility td = new TestDataUtility(2);
      td.createPricingOptions('product');
      General__c yearlyOption = new General__c(Name = Constants.GENERAL_DIGITAL_YEARLY_PRICINGOPTION, Value__c = td.mapPricingOptions.get(0)[0].Id);
      General__c monthlyOption = new General__c(Name = Constants.GENERAL_DIGITAL_MONTHLY_PRICINGOPTION, Value__c = td.mapPricingOptions.get(0)[1].Id);
      insert new List<General__c>{yearlyOption, monthlyOption};

      Test.startTest();
        //check missing param
        System.assertEquals(null, GlobalQueries.getDigitalPricingOptionBasedOnSetting(null), 'non null value returned where should be null');
        //check yearly subscription pricing option
        Pricing_Options__c poYearly = GlobalQueries.getDigitalPricingOptionBasedOnSetting(Constants.SUBSCRIPTIONTYPE_YEARLY);
        System.assertNotEquals(null, poYearly);
        System.assertEquals(td.mapPricingOptions.get(0)[0].Id, poYearly.Id);
        //check monthly subscription pricing option
        Pricing_Options__c poMonthly = GlobalQueries.getDigitalPricingOptionBasedOnSetting(Constants.SUBSCRIPTIONTYPE_MONTHLY);
        System.assertNotEquals(null, poMonthly);
        System.assertEquals(td.mapPricingOptions.get(0)[1].Id, poMonthly.Id);
        //check no option found
      delete poYearly;
      poYearly = GlobalQueries.getDigitalPricingOptionBasedOnSetting(Constants.SUBSCRIPTIONTYPE_YEARLY);
      System.assertEquals(null, poYearly, 'exception not thrown where shoould be');
      Test.stopTest();
    }

  /***************************************************************************************
  Developer - Wiktor Czykin
  Date Created - 30/05/2017
  Function - test getOffer()
  #############Change Log#############
  Modified by         Change Date
  ****************************************************************************************/
  private static testMethod void testGetOffer(){
    TestDataUtility td = new TestDataUtility(1);
    td.createOffers();
    Test.startTest();
      System.assertEquals(null, GlobalQueries.getOffer(null, ''));
      System.assertNotEquals(null, GlobalQueries.getOffer(td.lstOffers[0].Id, null));
      System.assertNotEquals(null, GlobalQueries.getOffer(null, td.lstOffers[0].Name));
      System.assertEquals(null, GlobalQueries.getOffer(null,'someName'));
    Test.stopTest();
  }

  /***************************************************************************************
  Developer - Wiktor Czykin
  Date Created - 30/05/2017
  Function - test getZuoraTcodeProductsBasedOnTCodeOfferType()
  #############Change Log#############
  Modified by         Change Date
  ****************************************************************************************/
  private static testMethod void testGetZuoraTcodeProductsBasedOnTCodeOfferType(){
    TestDataUtility td = new TestDataUtility(1);
    td.createTCodeProductOffers();
    Test.startTest();
      System.assertEquals(null, GlobalQueries.getZuoraTcodeProductsBasedOnTCodeOfferType('',''));
      List<TCode_Product__c> lst = GlobalQueries.getZuoraTcodeProductsBasedOnTCodeOfferType(Constants.TCODE_TYPE_PROMOTIONAL,'');
      System.assertNotEquals(null, lst);
      System.assert(!lst.isEmpty());
      System.assertEquals(1, lst.size());
      lst = GlobalQueries.getZuoraTcodeProductsBasedOnTCodeOfferType(Constants.TCODE_TYPE_PROMOTIONAL,' and TCodeManagement__r.Description__c = \'blahb lahblah\' ');
      System.assert(lst.isEmpty());
    Test.stopTest();
  }

  /***************************************************************************************
  Developer - Wiktor Czykin
  Date Created - 30/05/2017
  Function - test getOpenOfferTcode()
  #############Change Log#############
  Modified by         Change Date
  ****************************************************************************************/
  private static testMethod void testGetOpenOfferTcode(){
    TestDataUtility td = new TestDataUtility(1);
    td.createTCodeManagement();
    td.lstTCodeManagement[0].Type__c = Constants.TCODE_TYPE_OPENOFFER;
    update td.lstTCodeManagement;

    Test.startTest();
      System.assertNotEquals(null, GlobalQueries.getOpenOfferTcode());
      delete td.lstTCodeManagement[0];
      System.assertEquals(null, GlobalQueries.getOpenOfferTcode());
    Test.stopTest();
  }

  /***************************************************************************************
  Developer - Wiktor Czykin
  Date Created - 30/05/2017
  Function - test retrieveFrequencySetting() and replaceOfferFrequencyForApi()
  #############Change Log#############
  Modified by         Change Date
  ****************************************************************************************/
  private static testMethod void testFrequencySetting(){
    Test.startTest();
      System.assertNotEquals(null, GlobalQueries.retrieveFrequencySetting());
      System.assertNotEquals(null, GlobalQueries.mapRatePlanOffersFrequencyMap);
      System.assertNotEquals(null, GlobalQueries.mapOffersFrequencyRatePlanMap);
      System.assertEquals(Constants.OFFER_FREQUENCY_ANNUAL, GlobalQueries.replaceOfferFrequencyForApi(Constants.OFFER_FREQUENCY_ANNUALLY));
    Test.stopTest();
  }

  /***************************************************************************************
  Developer - Wiktor Czykin
  Date Created - 30/05/2017
  Function - test queryBuilderSelectAll()
  #############Change Log#############
  Modified by         Change Date
  ****************************************************************************************/
  private static testMethod void testQueryBuilderSelectAll(){
    TestDataUtility td = new TestDataUtility(1);
    td.createIndividualSubscribers();
    Test.startTest();
      String sQuery = GlobalQueries.queryBuilderSelectAll(Account.class.getName(), null, ' LastName = \''+td.lstIndividualSubscribers[0].LastName+'\'', 'LastName', '100');
      List<Account> lstAccount = Database.query(sQuery);
      System.assert(!lstAccount.isEmpty());
    Test.stopTest();
  }
}