/**
* @author Unknown
* @date Unknown
* @description test class for UtilitiesForSubscriptions
#############Change Log#############
Modified by     Version     Change Date
Wiktor Czykin   1.1         04/11/2016  //cleaned-up a bit, uncommented assertions, added one method
**/
@isTest(SeeAllData=false)
private class UtilitiesForSubscriptionsTest {

    private static testmethod void testcreateEmailAttachment(){
        List<Messaging.Emailfileattachment> testattach = UtilitiesForSubscriptions.createEmailAttachment('this is a test','test.csv');
        System.assertNotEquals(null,testattach.size());
        System.assertEquals(null,UtilitiesForSubscriptions.createEmailAttachment(null,'test.csv'));
    }

    private static testmethod void testgenerateUniqueFileName(){
        String fl = UtilitiesForSubscriptions.generateUniqueFileName('test','csv');
        System.assertEquals(true,fl.contains('test'));
        System.assertEquals(true,fl.contains('csv'));
    }

    private static testmethod void testUtilitiesForSubscriptions(){
        String secureVal = UtilitiesForSubscriptions.CreateSecureValue('abcdefg');
        System.assertEquals('abcdefg',UtilitiesForSubscriptions.GetSecureValue(secureVal));
        System.assertEquals('',UtilitiesForSubscriptions.GetSecureValue(null));
        System.assertEquals('',UtilitiesForSubscriptions.CreateSecureValue(null));
    }

    private static testmethod void testGetRetailer(){
        Id retailerID = UtilityLookupSubscriptionVariables.getRecordType('Retailer Account');
        Account testPersonAccount = new Account(Home_Delivery_Accepted__c = true,Name='testPersonAccount',Price_Plan__c='B');    
        Account testRetailAccount = new Account(Home_Delivery_Accepted__c = true,Name='testRetailAccount',BillingStreet='1 TEST RD',BillingCity='TEST CITY',BillingPostalCode='SW23 4RFXX',RecordTypeID=retailerID, Retailer_Active_Sub_Count__c=1);
        Account [] testAccounts = new Account []{testPersonAccount, testRetailAccount};
        try{ 
            insert testAccounts;
        }catch(Exception ex){}
        Date stDate = UtilitySelectOptionsSubscriptions.getFirstStartDate(5);//didnt use SubscriptionPaymentUtils because it requires to send a created subscription to the constructor which then creates a DD attached to the Sub
        
        Subscription__c testSubFullDD = new Subscription__c(Subscriber__c=testPersonAccount.ID, Retailer__c=testRetailAccount.ID,  Weekly_Price__c=219.11, Subscription_Status__c='Offered', Subscription_Duration_Picklist__c='52', Start_Date__c=stDate, Pricing_Error__c=false, Delivery_Type__c='HND', Payment_Details_Received__c=true, Payment_Type__c='Direct Debit', Voucher_Pack_Duration__c=13, Asset_Calc__c=0, Liab_Calc__c = 0);
        try{ 
            insert testSubFullDD;
        }catch(Exception ex){}
        
        testSubFullDD.Subscription_Status__c='Active';
        update testSubFullDD;
            
        UtilitiesForSubscriptions subUtils = new UtilitiesForSubscriptions();
        subUtils.getRetailer('SW23 4RFX',true);
        System.assertEquals(1,subUtils.activeRetailerAccounts.size());
        System.assertEquals('1 TEST RD',subUtils.activeRetailerAccounts[0].BillingStreet);
        
        subUtils.activeRetailerAccounts.clear();
        subUtils.RetrieveRetailers('SW23 4RFX',true);
        System.assertEquals(1,subUtils.allActiveRetailers.size());
        System.assertEquals('1 TEST RD',subUtils.activeRetailerAccounts[0].BillingStreet);
        
        subUtils.activeRetailerAccounts.clear();
        subUtils.getRetailer('',true);
        System.assertEquals(0,subUtils.activeRetailerAccounts.size());

        subUtils.activeRetailerAccounts.clear();
        subUtils.getRetailer(null,true);
        System.assertEquals(0,subUtils.activeRetailerAccounts.size());

        subUtils.getRetailer('SW23 4RFX',false);
    }  
        
    private static testmethod void testQualifyAgency(){
        List<SubManagementDefaults__c> subs1 = [Select ID__c,DefaultValue__c From SubManagementDefaults__c where ID__c='Agencies'];
        if (subs1.size() == 0){
            SubManagementDefaults__c newSubManagementDefaults = new SubManagementDefaults__c(ID__c='Agencies',DefaultValue__c='TMG,BPS');
            try{ 
                insert newSubManagementDefaults;
            }catch(Exception ex){}
        }
        else{
            subs1[0].DefaultValue__c ='TMG,BPS';
            update subs1;
        }
        System.assertEquals(TRUE,UtilitiesForSubscriptions.qualifyAgency('TMG'));
        System.assertEquals(FALSE,UtilitiesForSubscriptions.qualifyAgency('XYZ'));          
    }

    private static testmethod void testFormatPostCode(){
        System.assertEquals('SW12 3ED',UtilitiesForSubscriptions.formatPostCode('SW123ED'));
        System.assertEquals('SW1 3ED',UtilitiesForSubscriptions.formatPostCode('SW13ED'));
        System.assertEquals('SW12 3ED',UtilitiesForSubscriptions.formatPostCode('S W 1 2 3 E D'));
        System.assertEquals('SW1A 3ED',UtilitiesForSubscriptions.formatPostCode('SW1A3ED'));
        System.assertEquals('',UtilitiesForSubscriptions.formatPostCode(''));
    }

    private static testmethod void testConvertBooleanToInteger(){
        System.assertEquals(1,UtilitiesForSubscriptions.convertBooleanToInteger(true)); 
        System.assertEquals(0,UtilitiesForSubscriptions.convertBooleanToInteger(false));
    }

    private static testmethod void TestgetPositionInList(){
        Id retailerID = UtilityLookupSubscriptionVariables.getRecordType('Retailer Account');
        Account testPersonAccount = new Account(Home_Delivery_Accepted__c = true,Salutation='Mr', FirstName='test',LastName='test this',PersonMailingStreet='1 test street',Price_Plan__c='B');    
        Account testPersonAccount2 = new Account(Home_Delivery_Accepted__c = true,Salutation='Mr', FirstName='test',LastName='test this',PersonMailingStreet='1 test street',Price_Plan__c='B');    
        Account testRetailAccount1 = new Account(Home_Delivery_Accepted__c = true,Name='testRetailAccount1', BillingStreet='1 TEST RD',BillingCity='TEST CITY',BillingPostalCode='SW23 4RF',RecordTypeID=retailerID, Retailer_Active_Sub_Count__c=1);
        Account testRetailAccount2 = new Account(Home_Delivery_Accepted__c = true,Name='testRetailAccount2', BillingStreet='1 TEST RD',BillingCity='TEST CITY',BillingPostalCode='SW23 9RF',RecordTypeID=retailerID, Retailer_Active_Sub_Count__c=1);
        Account [] testAccounts = new Account []{testPersonAccount, testPersonAccount2, testRetailAccount1, testRetailAccount2};
        try{ insert testAccounts;
        }catch(Exception ex){}
        Date stDate = UtilitySelectOptionsSubscriptions.getFirstStartDate(5);//didnt use SubscriptionPaymentUtils because it requires to send a created subscription to the constructor which then creates a DD attached to the Sub
            
        Subscription__c testSubFullDD = new Subscription__c(Subscriber__c=testPersonAccount.ID, Retailer__c=testRetailAccount1.ID,  Weekly_Price__c=219.11, Subscription_Status__c='Offered', Subscription_Duration_Picklist__c='52', Start_Date__c=stDate, Pricing_Error__c=false, Delivery_Type__c='HND', Payment_Details_Received__c=true, Payment_Type__c='Direct Debit', Voucher_Pack_Duration__c=13, Asset_Calc__c=0, Liab_Calc__c = 0);
        try{ 
            insert testSubFullDD;
        }catch(Exception ex){}
            
        Subscription__c testSubFullDD2 = new Subscription__c(Subscriber__c=testPersonAccount2.ID, Retailer__c=testRetailAccount2.ID,  Weekly_Price__c=219.11, Subscription_Status__c='Offered', Subscription_Duration_Picklist__c='52', Start_Date__c=stDate, Pricing_Error__c=false, Delivery_Type__c='HND', Payment_Details_Received__c=true, Payment_Type__c='Direct Debit', Voucher_Pack_Duration__c=13, Asset_Calc__c=0, Liab_Calc__c = 0);
        try{ 
            insert testSubFullDD2;
        }catch(Exception ex){}
            
        testSubFullDD.Subscription_Status__c='Active';
        update testSubFullDD;
            
        testSubFullDD2.Subscription_Status__c='Active';
        update testSubFullDD2;
            
        UtilitiesForSubscriptions subUtils = new UtilitiesForSubscriptions();
        subutils.retrieveRetailers('SW23',true);
        integer pos = subUtils.getPositionInList('SW23 4RF');
        System.assertEquals(0,pos);
        pos = subUtils.getPositionInList('SW23 9RF');
        System.assertEquals(1,pos);
        
    }

    private static void setUpRetailerAccountsAndSubs(){ 
        Account testPersonAccount = new Account(Home_Delivery_Accepted__c = true,LastName='testPersonAccount',Price_Plan__c='B');  
        try{ insert testPersonAccount;
        }catch(Exception ex){}
 
        Id retailerID = UtilityLookupSubscriptionVariables.getRecordType('Retailer Account');
        Account testRetailAccount = new Account(Home_Delivery_Accepted__c = true,name='testRetailAccount',RET_ID__c='99999999',BillingStreet='1 TEST RD',BillingCity='TEST CITY',BillingPostalCode='SW23 4RF',Retailer_Active_Sub_Count__c=1,RecordTypeID=retailerID);
        try{ insert testRetailAccount;
        }catch(Exception ex){}
        Date stDate = UtilitySelectOptionsSubscriptions.getFirstStartDate(5);//didnt use SubscriptionPaymentUtils because it requires to send a created subscription to the constructor which then creates a DD attached to the Sub
        Subscription__c testSubFullDD = new Subscription__c(Subscriber__c=testPersonAccount.ID, Retailer__c=testRetailAccount.ID,  Weekly_Price__c=219.11, Subscription_Status__c='Offered',Subscription_Duration_Picklist__c='52', Start_Date__c=stDate, Pricing_Error__c=false, Delivery_Type__c='HND', Payment_Details_Received__c=true, Payment_Type__c='Direct Debit', Voucher_Pack_Duration__c=13, Asset_Calc__c=0, Liab_Calc__c = 0);
        try{ insert testSubFullDD;
        }catch(Exception ex){}
        testSubFullDD.Subscription_Status__c='Active';
        update testSubFullDD;
    }  

    private static testmethod void testfastRetrieveRetailers(){
        setUpRetailerAccountsAndSubs();
        UtilitiesForSubscriptions subUtils = new UtilitiesForSubscriptions();
        subUtils.fastRetrieveRetailers(null,true);  
        subUtils.fastRetrieveRetailers('SW23',true);
        setUpRetailerAccountsAndSubs();
        subUtils.fastRetrieveRetailers('SW23',false);
    }

    private static testmethod void testRetrieveRetailers(){
        setUpRetailerAccountsAndSubs();
        UtilitiesForSubscriptions subUtils = new UtilitiesForSubscriptions();
        
        subUtils.retrieveRetailers(null,true);
        UtilitiesForSubscriptions subUtils2 = new UtilitiesForSubscriptions();
        subUtils2.retrieveRetailers('SW23',true);
        System.assertEquals(1,subUtils2.allActiveRetailers.size());
        System.assertEquals(true,subUtils2.displayRetailers);
        System.assertEquals('1 TEST RD',subUtils2.activeRetailerAccounts[0].BillingStreet);
    }

    private static testmethod void testGetRetailerFromRETID(){
        Account testRetailAccount = new Account(Home_Delivery_Accepted__c = true,Name='testRetailAccount',BillingStreet='1 TEST RD',BillingCity='TEST CITY',BillingPostalCode='SW23 4RF',ret_id__c='11122');
        try{ insert testRetailAccount;
        }catch(Exception ex){}
        Account accRet = UtilitiesForSubscriptions.getRetailerFromRETID(testRetailAccount.RET_ID__c);
        System.assertEquals('testRetailAccount',accRet.Name);
        accRet = UtilitiesForSubscriptions.getRetailerFromRETID('xxxs');
        System.assertEquals(null, accRet);
    }

    private static testmethod void testReturnSelectedRetailerID(){
        Account testRetailAccount = new Account(Home_Delivery_Accepted__c = true,Name='testRetailAccount',BillingStreet='1 TEST RD',BillingCity='TEST CITY',BillingPostalCode='SW23 4RF',ret_id__c='11122');
        try{ insert testRetailAccount;
    }catch(Exception ex){}
        Account retName = UtilitiesForSubscriptions.returnSelectedRetailerWithoutError('11122');
        list<Account> retailerAccs = [select Name From Account where ret_id__c='44442256']; 
        if (retailerAccs.size() >0)
            delete retailerAccs;
        retName = UtilitiesForSubscriptions.returnSelectedRetailerWithoutError('44442256');
        System.assertEquals(null,retName);
    }

    private static testmethod void testGetRetailerAcc(){
        Account testRetailAccount = new Account(Home_Delivery_Accepted__c = true,Name='testRetailAccount',BillingStreet='1 TEST RD',BillingCity='TEST CITY',BillingPostalCode='SW23 4RF',ret_id__c='11122');
        try{ insert testRetailAccount;
        }catch(Exception ex){}

        Account NameOfAcc = UtilitiesForSubscriptions.getRetailerAcc(String.valueof(testRetailAccount.id));
        System.assertEquals(testRetailAccount.Name,NameOfAcc.Name);
        
        NameOfAcc = UtilitiesForSubscriptions.getRetailerAcc(null);
        System.assertEquals(null,NameOfAcc);
        
    }

    private static testmethod void testCreateSecureValue(){
        String encryptVal = UtilitiesForSubscriptions.createSecureValue('4.00');
        System.assertEquals('4.00',UtilitiesForSubscriptions.getSecureValue(encryptVal));
    }

    private static testmethod void testCopyPOCToAccount(){
        Date EnterDate =  date.today().toStartofWeek().addDays(21);
        POC__c POCTEST1 = new POC__c(POC_ID__c='7013112124',Country__c='UK',State__c='',Street_Address_Line_2__c='Tottenham',HiddenPOCPrice__c='£4.00',City__c='london',Street__c='36 Conyers',title__c='Mr',PostalCode__c = 'SW17 7KQ', FirstName__c ='Steve S', LastName__c = 'Fouracre', ExpiryDate__c=EnterDate);

        Account newAcc = UtilitiesForSubscriptions.copyPOCToAccount(POCTEST1);
        System.assertEquals('7013112124',newAcc.POC__c);    
        System.assertEquals('36 Conyers',newAcc.PersonMailingStreet);   
    }

    private static testmethod void testCopyLapsedAccountToNewAccount(){
        Account testPersonAccount = new Account(Home_Delivery_Accepted__c = true,Salutation='Mr',FirstName='test',LastName='test this',PersonMailingStreet='1 test street',Price_Plan__c='B');    
        try{ insert testPersonAccount;
        }catch(Exception ex){}
        
        Account acc = [Select Salutation,FirstName,LastName,PersonMailingStreet,Subscriber_Number_static__c From Account where FirstName='test' and LastName='test this' limit 1];
        
        Account newAcc = UtilitiesForSubscriptions.copyLapsedAccountToNewAccount(acc.Subscriber_Number_static__c);
        System.assertEquals('1 test street',newAcc.PersonMailingStreet);    
        System.assertEquals('test this',newAcc.LastName);
        System.assertEquals(null,UtilitiesForSubscriptions.copyLapsedAccountToNewAccount('78667768'));  

    }

    private static testmethod void testConvertToTwoDecimalPlaces(){
        String retval = UtilitiesForSubscriptions.convertToTwoDecimalPlaces(4);
        System.assertEquals('4.00',UtilitiesForSubscriptions.convertToTwoDecimalPlaces(4)); 
        Double sentval = 4.002;
        System.assertEquals('4.00',UtilitiesForSubscriptions.convertToTwoDecimalPlaces(sentval));   
        sentval=4.0022;
        System.assertEquals('4.00',UtilitiesForSubscriptions.convertToTwoDecimalPlaces(sentval));   
        sentval=4.00;
        System.assertEquals('4.00',UtilitiesForSubscriptions.convertToTwoDecimalPlaces(sentval));   
        sentval=4.20;
        System.assertEquals('4.20',UtilitiesForSubscriptions.convertToTwoDecimalPlaces(sentval));   
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 04/11/2016
    Version - 1.0
    Function - test poc mapping onto account instance where existing account is found based on tsnumber
    #############Change Log#############
    Modified by    Version   Change Date
    ****************************************************************************************/
    private static testMethod void testCopyPOCToAccountBasedOnTsNumber(){
        TestDataUtility td = new TestDataUtility(1);
        td.createIndividualSubscribers();
        td.createPocs(1);
        List<Account> lstAcc = [select Id, Subscriber_Number__c from Account where Id in :td.lstIndividualSubscribers];
        System.assert(!lstAcc.isEmpty());
        POC__c p = td.mapTCodeManagementToPOCs.get(td.lstTCodeManagement[0].Id)[0];
        p.Subscriber_Number__c = lstAcc[0].Subscriber_Number__c;
        update p;
        Test.startTest();
            Account acc = UtilitiesForSubscriptions.copyPOCToAccount(p);
            System.assertEquals(td.lstIndividualSubscribers[0].PersonEmail, acc.PersonEmail);
            System.assertEquals(lstAcc[0].Subscriber_Number__c, acc.Subscriber_Number_static__c);
            System.assertEquals(p.PostalCode__c, acc.PersonMailingPostalCode);
        Test.stopTest();
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 04/11/2016
    Version - 1.0
    Function - test poc mapping onto account instance where existing account is found based on email
    #############Change Log#############
    Modified by    Version   Change Date
    ****************************************************************************************/
    private static testMethod void testCopyPOCToAccountBasedOnEmail(){
        TestDataUtility td = new TestDataUtility(1);
        td.createIndividualSubscribers();
        td.createPocs(1);
        List<Account> lstAcc = [select Id, PersonEmail, Subscriber_Number__c from Account where Id in :td.lstIndividualSubscribers];
        System.assert(!lstAcc.isEmpty());
        POC__c p = td.mapTCodeManagementToPOCs.get(td.lstTCodeManagement[0].Id)[0];
        p.Email__c = lstAcc[0].PersonEmail;
        update p;
        Test.startTest();
            Account acc = UtilitiesForSubscriptions.copyPOCToAccount(p);
            System.assertEquals(td.lstIndividualSubscribers[0].PersonEmail, acc.PersonEmail);
            System.assertEquals(lstAcc[0].Subscriber_Number__c, acc.Subscriber_Number_static__c);
            System.assertEquals(p.PostalCode__c, acc.PersonMailingPostalCode);
        Test.stopTest();
    }
}