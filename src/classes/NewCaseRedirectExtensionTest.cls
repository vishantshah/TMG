/**
* Author:       Pawel Chrzanowski
* Date:         09/03/2017
* Description:  Test class for NewCaseRedirectExtension
* ******************* Change Log *******************
* Modified by       Version     Change Date
* Pawel Chrzanowski 1.1         04/04/2017  modified tests
**/

@isTest
private class NewCaseRedirectExtensionTest {

    private static final String PARAM_RECORDTYPE = 'RecordType';
    private static final String PARAM_RETURL = 'retURL';
    private static final String PARAM_SAVENEWURL = 'save_new_url';
    private static final String PARAM_ENT = 'ent';
    private static final String PARAM_EXTRA = 'extra';
    private static final String PARAM_EXTRA_VALUE = 'test';
    private static final String PAGE_RECORDTYPESELECT = '/setup/ui/recordtypeselect.jsp';
    private static final String DEFAULT_CASE_TAB = '/apex/CustomCase';
    private static final String HOME = '/home/home.jsp';

    private static final String RECORDTYPE_DIGITALSERVICES = RecordTypeUtility.getRecordTypeId(Case.SObjectType, Constants.CASE_RECORDTYPE_DIGITALSERVICES, Case.class.getName());
    private static final String RECORDTYPE_GENERALENQUIRY = RecordTypeUtility.getRecordTypeId(Case.SObjectType, Constants.CASE_RECORDTYPE_GENERALENQUIRY, Case.class.getName());
    
    /***************************************************************************************
    Developer   Pawel Chrzanowski
    Date        09/03/2017
    Test standard User redirection
    ******************* Change Log *******************
    Modified by         Version     Change Date
    Pawel Chrzanowski   1.1         04/04/2017  added support for extra parameters
    ****************************************************************************************/
    static testMethod void redirectUser_newCase(){
        ApexPages.StandardController stdController = new ApexPages.StandardController(new Case());
        NewCaseRedirectExtension extension = new NewCaseRedirectExtension(stdController);

        PageReference pr = Page.NewCaseRedirect;
        pr.getParameters().put(PARAM_RETURL, HOME);
        pr.getParameters().put(PARAM_EXTRA, PARAM_EXTRA_VALUE);
        Test.setCurrentPage(pr);

        User u = new User(Department = null, Alias = 'standt', Email='test@test.com', UserName = 'testDsUser09032017@test.com', ProfileId = UserInfo.getProfileId(), EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', LocaleSidKey='en_US', TimeZoneSidKey = 'America/Los_Angeles');
        System.runAs(u){
            PageReference nextPage = extension.redirectUser();
            String retUrl = nextPage.getUrl();
            System.assertEquals(PAGE_RECORDTYPESELECT, retUrl.substringBefore('?'));
            System.assertEquals(Case.class.getName(), nextPage.getParameters().get(PARAM_ENT));

            //Check if additional parameters are passed
            PageReference expectedSavePage = Page.NewCaseRedirect;
            expectedSavePage.getParameters().put(PARAM_RETURL, HOME);
            expectedSavePage.getParameters().put(PARAM_EXTRA, PARAM_EXTRA_VALUE);
            System.assertEquals(expectedSavePage.getUrl(), nextPage.getParameters().get(PARAM_SAVENEWURL));
        }
    }

    /***************************************************************************************
    Developer   Pawel Chrzanowski
    Date        09/03/2017
    Test User redirection based on Department
    ******************* Change Log *******************
    Modified by         Version     Change Date
    Pawel Chrzanowski   1.1         04/04/2017  added support for extra parameters
    ****************************************************************************************/
    static testMethod void redirectUser_department(){
        ApexPages.StandardController stdController = new ApexPages.StandardController(new Case());
        NewCaseRedirectExtension extension = new NewCaseRedirectExtension(stdController);
        PageReference nextPage;
        String retUrl;

        PageReference pr = Page.NewCaseRedirect;
        pr.getParameters().put(PARAM_RETURL, HOME);
        Test.setCurrentPage(pr);

        //verify redirection for 'Digital Services' Department
        User dsUser = new User(Department = Constants.USER_DEPARTMENT_DIGITALSERVICES, Alias = 'standt', Email='test@test.com', UserName = 'testDsUser09032017@test.com', ProfileId = UserInfo.getProfileId(), EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', LocaleSidKey='en_US', TimeZoneSidKey = 'America/Los_Angeles');
        System.runAs(dsUser){
            nextPage = extension.redirectUser();
            retUrl = nextPage.getUrl();
            System.assertEquals(DEFAULT_CASE_TAB, retUrl.substringBefore('?'));
            System.assertEquals(HOME, nextPage.getParameters().get(PARAM_RETURL));
            System.assertEquals(Case.class.getName(), nextPage.getParameters().get(PARAM_ENT));
            System.assertEquals(RECORDTYPE_DIGITALSERVICES, nextPage.getParameters().get(PARAM_RECORDTYPE));
        }

        //verify redirection for 'Sales and Customer Experience' Department
        User sceUser = new User(Department = Constants.USER_DEPARTMENT_SALESANDCUSTOMEREXPERIENCE, Alias = 'standt', Email='test@test.com', UserName = 'testSceUser09032017@test.com', ProfileId = UserInfo.getProfileId(), EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', LocaleSidKey='en_US', TimeZoneSidKey = 'America/Los_Angeles');
        System.runAs(sceUser){
            nextPage = extension.redirectUser();
            retUrl = nextPage.getUrl();
            System.assertEquals(DEFAULT_CASE_TAB, retUrl.substringBefore('?'));
            System.assertEquals(HOME, nextPage.getParameters().get(PARAM_RETURL));
            System.assertEquals(Case.class.getName(), nextPage.getParameters().get(PARAM_ENT));
            System.assertEquals(RECORDTYPE_GENERALENQUIRY, nextPage.getParameters().get(PARAM_RECORDTYPE));
        }
    }

    /***************************************************************************************
    Developer   Pawel Chrzanowski
    Date        09/03/2017
    Test User redirection after Record Type selection to verify no redirection loop
    ******************* Change Log *******************
    Modified by         Version     Change Date
    Pawel Chrzanowski   1.1         04/04/2017  added support for extra parameters
    ****************************************************************************************/
    static testMethod void redirectUser_recordType(){
        ApexPages.StandardController stdController = new ApexPages.StandardController(new Case());
        NewCaseRedirectExtension extension = new NewCaseRedirectExtension(stdController);

        PageReference pr = Page.NewCaseRedirect;
        pr.getParameters().put(PARAM_RECORDTYPE, RECORDTYPE_DIGITALSERVICES);
        pr.getParameters().put(PARAM_RETURL, HOME);
        Test.setCurrentPage(pr);

        PageReference nextPage = extension.redirectUser();
        String retUrl = nextPage.getUrl();
        System.assertEquals('/apex/CustomCase', retUrl.substringBefore('?'));
        System.assertEquals(Case.class.getName(), nextPage.getParameters().get(PARAM_ENT));
        System.assertEquals(RECORDTYPE_DIGITALSERVICES, nextPage.getParameters().get(PARAM_RECORDTYPE));
    }
}