/**
* @author Unknown
* @date Unknown
* @description
#############Change Log#############
Modified by     Version     Change Date
Wiktor Czykin   	1.1 	02/03/2015  //modified setupSub()
Cristina Popescu	1.2		11/06/2015	//increase test coverage and create new method to test calculateEntitlements method
Cristina Popescu	1.3		21/06/2015	//fix recently lapsed entitlement assignment
Wiktor Czykin		1.4		14/10/2015	//modified testCalculateEntitlements(),testCalculateInRenewalEntitlements(), testEntitlementState()
Michal Szewczyk 	1.5		21/01/2016	//added Product_c and Digital_Product_Type__c to SOQL queries in  testCalculateEntitlements(),testCalculateInRenewalEntitlements()
Wiktor Czykin		1.6		24/02/2016	//modified testCalculateEntitlements()
Michal Szewczyk		1.7		01/03/2016	// start using createDigitalSubscribers() / createIndividualSubscribers() in testCalculateEntitlementsNWTransP()
Pawel Chrzanowski	1.9		24/03/2016	//added testCalculateRegistrantEntitlements()
Michal Szewczyk 	1.8		20/04/2016	//added setEntitlemetMapping invocation in some methods
Michal Szewczyk 	1.9     11/05/2016  //removed Subscription_Product__c from code
Wiktor Czykin 		2.0		12/05/2016	//fixed testCalculateRegistrantEntitlements()
Mantas Grigaliunas	2.1		08/08/2016	//removed ipad related code
Wiktor Czykin       2.2     28/09/2016  //splitted getSubscriberEachEntitlement() method to avoid limits, no time for proper refactoring
Wiktor Czykin       2.3     21/03/2017  //modified so that it does not fail with duplicate email validation on Account
**/
@isTest(SeeAllData=false)

private class SubscriberPortalTest {

    private static testMethod void testHasNull1(){
        Map<String, String> m = new Map<String,String>{'one'=>null,'two'=>'','three'=>'a'};

        List<String> results = SubscriberPortal.hasNull(m);
        System.assert(results.size() == 2);
        System.assert(results[0].contains('0001'));
        System.assert(results[1].contains('0001'));
    }

    private static testMethod void testHasNull2(){
        SubscriberPortal.Subscriber sub1 = null;
        SubscriberPortal.Subscriber sub2 = new SubscriberPortal.Subscriber();

        List<String> res1 = SubscriberPortal.hasNull(sub1);
        List<String> res2 = SubscriberPortal.hasNull(sub2);

        System.assert(res1.size()==1);
        System.assert(res1[0].contains('0001'));
        System.assert(res2.size()==0);
    }

    private static testMethod void testTranslateAttr(){
        SubscriberPortal.KeyValuePair kvpReverseDummyVal = new SubscriberPortal.KeyValuePair('DUMMY','TRUE');
        SubscriberPortal.KeyValuePair kvpReverseVal = new SubscriberPortal.KeyValuePair('CONTACT_BY_EMAIL','FALSE');
        SubscriberPortal.KeyValuePair kvpKeepVal = new SubscriberPortal.KeyValuePair('CONTACT_BY_SMS','1');

        //SLP-64 - SB 18/05 - change attr test
        System.assertEquals('FALSE',SubscriberPortal.translateAttr(kvpReverseDummyVal));
        System.assertEquals('0',SubscriberPortal.translateAttr(kvpReverseVal)); // Value should be reversed as defined by mappings
        System.assertEquals('TRUE',SubscriberPortal.translateAttr(kvpKeepVal)); // Value should remain the same
    }

    private static testMethod void testgetSubscriberIncorrectParms(){
        setupCustomSettings();
        SubscriberPortal.Subscriber sub = SubscriberPortal.getSubscriber('TS998889999_C', 'N1');
        System.assert(sub.errors.size()==1, sub);
    }

    private static testMethod void testSubscriberAccountInformation(){
        init();
        Account a = new Account(lastname='lastname', PersonMailingPostalCode='NW9 3GH', RecordTypeId=Constants.DigitalSubscriberRecordType(), Subscriber_Digital_Status__c='Inactive', Digital_Product_Type__c=Constants.DIGITAL_PRODUCT_ALLDEVICES);
        try{
            insert a;
        }catch(Exception ex){}
        a = [SELECT Id, Subscriber_Number_Static__c FROM Account WHERE Id = :a.id];
        System.assertNotEquals(null, a);

        Account subscriber = [SELECT id, Subscriber_Number_Static__c, PersonMailingPostalCode FROM Account a WHERE Id = :a.Id];
        Account sub = SubscriberPortal.getSubscriberAccountInformation(a.subscriber_number_static__c, 'NW9 3GH',null);
        System.assertEquals(sub.Subscriber_Number_Static__c,subscriber.Subscriber_Number_Static__c);
    }

    private static testMethod void testGetSubscriberNoEntitlements(){
        setupCustomSettings();
        Account subscriber = new Account(lastname='Test', personmailingPostalCode='T1');
        try{
            insert subscriber;
        }catch(Exception ex){}

        subscriber = [SELECT id, lastname, personmailingpostalcode, subscriber_number_static__c FROM Account WHERE id = :subscriber.id];
        SubscriberPortal.Subscriber sub = SubscriberPortal.getSubscriber(subscriber.subscriber_number_static__c, subscriber.personmailingPostalCode);
        System.assert(sub.known == true, sub);
        System.assert(sub.entitlements.size()==0);

        // Ensure attributes are correctly initialised
        for(SubscriberPortal.KeyValuePair kvp: sub.attributes){
            if(kvp.key=='LAST_NAME'){
                System.assert(kvp.value=='Test');
            }
        }
    }

    private static testMethod void GetSubscribers(){
        setupCustomSettings();

        Account a1 = setupAccount('ACTIVEA', 'ZZZ');
        Account a2 = setupAccount('ACTIVEB', 'XXX');

        Subscription__c sub1 = setupSub(a1, a1.lastName);
        sub1.Subscription_Status__c = Constants.SSTATUS_LAPSED;
        update sub1;

        Subscription__c sub2 = setupSub(a2, a2.lastName);
        sub2.Subscription_Status__c = Constants.SSTATUS_LAPSED;
        update sub2;

        Subscription__c sub3 = setupSub(a2, a2.lastName);
        sub3.Subscription_Status__c = Constants.SSTATUS_OFFERED;
        sub3.Previous_Subscription__c = sub2.Id;
        update sub3;

        Set<Id> ids = new Set<Id>{a1.Id,a2.Id};

        List<SubscriberPortal.Subscriber> subs = SubscriberPortal.getSubscribers(ids);

        System.assertEquals(2, subs.size());
        System.assertEquals(SubscriberPortal.SEVENDAY_ENT_PREFIX + 'LAPSED', subs[0].entitlements[0]);
        System.assertEquals(SubscriberPortal.SEVENDAY_ENT_PREFIX + 'RECENTLY_LAPSED', subs[1].entitlements[0]);
    }

    private static testMethod void getSubscriberEachEntitlement(){
        setupCustomSettings();
        Account lapsed = setupAccount('LAPSED','ZZZ');
        Account recentlyLapsed = setupAccount('RECENTLYLAPSED','ZZZ');
        Account active = setupAccount('ACTIVE', 'ZZZ');
        Account renewal = setupAccount('IN RENEWAL', 'ZZZ');
        Account pending = setupAccount('PENDING', 'ZZZ');
        Account offered = setupAccount('OFFERED', 'ZZZ');

        Test.startTest();
            Subscription__c subLapsed = setupSub(lapsed,lapsed.lastName);
            Subscription__c subRecentlyLapsed = setupSub(recentlyLapsed,lapsed.lastName);
            Subscription__c subOfferedLinkedToLapsed = setupSub(recentlyLapsed,offered.lastName);
            subOfferedLinkedToLapsed.Previous_Subscription__c = subRecentlyLapsed.Id;
            update subOfferedLinkedToLapsed;
            Subscription__c subActive = setupSub(active, active.lastName);
            Subscription__c subRenewal = setupSub(renewal, renewal.lastName);
            Subscription__c subPending = setupSub(pending, pending.lastName);
            Subscription__c subOffered = setupSub(offered, offered.lastName);
            SubscriberPortal.checkForLinkedSubscriptions(new List<Subscription__c>{subLapsed,subRecentlyLapsed,subOfferedLinkedToLapsed,subActive,subRenewal,subPending,subOffered});
        Test.stopTest();

        SubscriberPortal.Subscriber spLapsed = SubscriberPortal.getSubscriber(lapsed.subscriber_number_static__c, lapsed.personmailingPostalCode);
        SubscriberPortal.Subscriber spRecentlyLapsed = SubscriberPortal.getSubscribers(new set<Id>{recentlyLapsed.Id})[0];
        SubscriberPortal.Subscriber spActive = SubscriberPortal.getSubscriber(active.subscriber_number_static__c, active.personmailingPostalCode);
        SubscriberPortal.Subscriber spRenewal = SubscriberPortal.getSubscriber(renewal.subscriber_number_static__c, renewal.personmailingPostalCode);
        SubscriberPortal.Subscriber spPending = SubscriberPortal.getSubscriber(pending.subscriber_number_static__c, pending.personmailingPostalCode);
        SubscriberPortal.Subscriber spOffered = SubscriberPortal.getSubscriber(offered.subscriber_number_static__c, offered.personmailingPostalCode);

        System.assert(spLapsed.entitlements[0] == SubscriberPortal.SEVENDAY_ENT_PREFIX + lapsed.lastName, spLapsed.entitlements[0]);
        System.assert(spRecentlyLapsed.entitlements[0]== SubscriberPortal.SEVENDAY_ENT_PREFIX + 'RECENTLY_LAPSED', spRecentlyLapsed.entitlements[0]);
        System.assert(spActive.entitlements[0]== SubscriberPortal.SEVENDAY_ENT_PREFIX + active.lastName, spActive.entitlements[0]);
        System.assert(spRenewal.entitlements[0]== SubscriberPortal.SEVENDAY_ENT_PREFIX + renewal.lastName.replace(' ','_'), spRenewal.entitlements[0]);
        System.assert(spPending.entitlements[0]== SubscriberPortal.SEVENDAY_ENT_PREFIX + pending.lastName, spPending.entitlements[0]);
        System.assert(spOffered.entitlements[0]== SubscriberPortal.SEVENDAY_ENT_PREFIX + lapsed.lastName, spOffered.entitlements[0]);
    }

    private static testMethod void getSubscriberEachEntitlementV2(){
        System.debug('start GetSubscriberEachEntitlement');
        setupCustomSettings();

        Account cancelled = setupAccount('acca', 'ZZZ');
        Account pCancelled = setupAccount('accb', 'ZZZ');
        Account recentlyPCancelled = setupAccount('accc', 'ZZZ');

        Test.startTest();
            Subscription__c subCancelled = setupSub(cancelled, cancelled.lastName);
            Subscription__c subPCancelled = setupSub(pCancelled, pCancelled.lastName);
            Subscription__c subPRecentlyCancelled = setupSub(recentlyPCancelled, recentlyPCancelled.lastName);

            SubscriberPortal.checkForLinkedSubscriptions(new List<Subscription__c>{subCancelled,subPCancelled,subPRecentlyCancelled});
            subCancelled.Subscription_Status__c = Constants.SSTATUS_CANX;
            subCancelled.Cancellation_Date__c = Date.Today().addDays(21);
            subCancelled.Subscription_Status__c = cancelled.lastname;
            subCancelled.Cancellation_Method__c = 'Somehow';
            subCancelled.Cancellation_Reason__c = 'Dunno';

            subPCancelled.Subscription_Status__c = Constants.SSTATUS_CANX;
            subPCancelled.Cancellation_Date__c = Date.Today().addDays(21);
            subPCancelled.Subscription_Status__c = pCancelled.lastname;
            subPCancelled.Cancellation_Method__c = 'Somehow';
            subPCancelled.Cancellation_Reason__c = 'Dunno';

            Date CurrentStartDate = subPRecentlyCancelled.Start_Date__c;
            CurrentStartDate = CurrentStartDate.addDays(2);
            subPRecentlyCancelled.Subscription_Status__c = Constants.SSTATUS_PENDING_CANX;
            subPRecentlyCancelled.Cancellation_Date__c = CurrentStartDate;
            subPRecentlyCancelled.Subscription_Status__c = recentlyPCancelled.lastname;
            subPRecentlyCancelled.Cancellation_Method__c = 'Somehow';
            subPRecentlyCancelled.Cancellation_Reason__c = 'Dunno';

            update subCancelled;
            update subPCancelled;
            update subPRecentlyCancelled;
        Test.stopTest();

        SubscriberPortal.Subscriber spCancelled = SubscriberPortal.getSubscriber(cancelled.subscriber_number_static__c, cancelled.personmailingPostalCode);
        SubscriberPortal.Subscriber spPCancelled = SubscriberPortal.getSubscriber(pCancelled.subscriber_number_static__c, pCancelled.personmailingPostalCode);
        SubscriberPortal.Subscriber spRecentlyPCancelled = SubscriberPortal.getSubscriber(recentlyPCancelled.subscriber_number_static__c, recentlyPCancelled.personmailingPostalCode);
    }

    private static testMethod void GetSubscriberFaultyEntitlement(){
        setupCustomSettings();
        Account fail = setupAccount('MERK','ZZZ');

        Subscription__c subfail = setupSub(fail,fail.lastName);

        SubscriberPortal.Subscriber spfail = SubscriberPortal.getSubscriber(fail.subscriber_number_static__c, fail.personmailingPostalCode);

        System.assert(spfail.entitlements.size() == 0);
        System.assert(spfail.errors.size() == 1);
    }

    private static testMethod void getSubscriberMoreThanOneSub(){
        setupCustomSettings();
        Account acc = setupAccount('SEVERALSUBS','ZZZ');

        //sms-473
        Date stDate = UtilitySelectOptionsSubscriptions.getFirstStartDate(5);

        Subscription__c sub1 = setupSub(acc,'LAPSED', Date.Today().toStartOfWeek().addDays(33*7));
        Subscription__c sub2 = setupSub(acc,'ACTIVE', stDate);
        Subscription__c sub3 = setupSub(acc,'PENDING', Date.Today().toStartOfWeek().addDays(66*7));

        SubscriberPortal.checkForLinkedSubscriptions(new List<Subscription__c>{sub1,sub2,sub3});
        SubscriberPortal.Subscriber sub = SubscriberPortal.getSubscriber(acc.subscriber_number_static__c, acc.personmailingPostalCode);

        System.assert(sub.entitlements.size() == 1);
        System.assert(sub.entitlements[0] == SubscriberPortal.SEVENDAY_ENT_PREFIX + 'ACTIVE'); // the active sub has the highest priority
    }

    private static testMethod void GetSubscriberWasActiveNowLapsed(){
        setupCustomSettings();
        Account acc = setupAccount(Constants.SSTATUS_ACTIVE.toUpperCase(),'ZZZ');
        acc.PersonMailingCountry = 'gb';
        update acc;

        Subscription__c sub1 = setupSub(acc, acc.lastName);
        sub1.Subscription_Status__c = Constants.SSTATUS_LAPSED.toUpperCase();
        update sub1;

        SubscriberPortal.checkForLinkedSubscriptions(new List<Subscription__c>{sub1});
        SubscriberPortal.Subscriber sub = SubscriberPortal.getSubscriber(acc.subscriber_number_static__c, acc.personmailingPostalCode);

        System.assert(sub.entitlements.size() == 1);
        System.assert(sub.entitlements[0] == SubscriberPortal.SEVENDAY_ENT_PREFIX  + 'LAPSED',sub.entitlements[0]); // the active sub has the highest priority

    }

    private static testMethod void testSimpleSubscriberConstructors(){
        SubscriberPortal.Subscriber sub = new SubscriberPortal.Subscriber(new List<String>{'Error'});
        SubscriberPortal.Subscriber sub1 = new SubscriberPortal.Subscriber(null, 'guid', 'pid', 'TSNUM', true, false, null, null, null);
    }


    private static testMethod void testUpdateSubscriberFaultyParms(){
        SubscriberPortal.Response resp = SubscriberPortal.updateSubscriber(null); // null subscrier parm
        System.assert(resp.errors.size() == 1);
        System.assert(resp.status == 'FAILURE');
        System.assert(resp.errors[0].contains('9999'), resp);

        resp = SubscriberPortal.updateSubscriber(new SubscriberPortal.Subscriber(null, null, null, null)); // non-nil sub but with no values
        System.assert(resp.errors.size() == 1);
        System.assert(resp.status == 'FAILURE');
        System.assert(resp.errors[0].contains('0001'), resp);

        Account a = new Account(lastName='test');
        try{
            insert a;
        }catch(Exception ex){}

        resp = SubscriberPortal.updateSubscriber(new SubscriberPortal.Subscriber(new SubscriberPortal.Application('id'), a, new List<Subscription__c>(), null)); // pass account with invalid subscriber no
        System.assert(resp.errors.size() == 1);
        System.assert(resp.status == 'FAILURE');
        System.assert(resp.errors[0].contains('0001'), resp);
    }

    /***************************************************************************************
    Developer   Unknown
    Date        Unknown
    Function
    ******************* Change Log *******************
    Modified by         Version     Change Date
    Wiktor Czykin		1.1			14/04/2016	//all marketing flags to false
    ****************************************************************************************/
    private static testMethod void testUpdateSubscriberPostive(){
        setupCustomSettings();
        Account acc = setupAccount('TESTING','ZZZ');
        acc.PersonMailingStreet = '1 Lindsay Street';
        update acc;
        System.assertEquals(null, acc.TMG_Promo_Post__c);
        Subscription__c sub = setupSub(acc,Constants.SSTATUS_ACTIVE);
        System.debug('acc before: '+acc);
        SubscriberPortal.Subscriber spSub = SubscriberPortal.getSubscriber(acc.subscriber_number_static__c, acc.personMailingPostalCode);
        System.debug('spsub b4: '+spSub);

        List<SubscriberPortal.KeyValuePair> kvps = spSub.attributes;
        System.debug('kvps before: '+kvps);

        // Assert the setup
        //SLP-64 - SB 18/05 - change the permissions assertions
        for(SubscriberPortal.KeyValuePair kvp : kvps ){
            if(kvp.key == 'CONTACT_BY_PHONE'){
                System.assert(kvp.value == 'FALSE',kvp.value);
            }else if( kvp.key == 'FIRST_NAME'){
                System.assert(kvp.value == null,kvp.value);
            }else if( kvp.key == 'CONTACT_BY_POST'){
                System.assert(kvp.value == 'FALSE',kvp);
            }else if( kvp.key == 'MARKETING_OPT_IN_3RD'){
                System.assert(kvp.value == 'FALSE',kvp.value);
            }else if( kvp.key == 'EMAIL_ADDRESS'){
                System.assertEquals(kvp.value, acc.PersonEmail, kvp.value);
            }else if( kvp.key == 'LAST_NAME'){
                System.assert(kvp.value == 'TESTING',kvp.value);
            }else if( kvp.key == 'CONTACT_BY_EMAIL'){
                System.assert(kvp.value == 'FALSE',kvp.value);
            }
        }

        System.assert(spSub.guid == null);

        // Change the data
        for(SubscriberPortal.KeyValuePair kvp : kvps ){
            if(kvp.key == 'CONTACT_BY_PHONE'){
                kvp.value = 'FALSE';
            }else if( kvp.key == 'FIRST_NAME'){
                kvp.value = 'MAHFIRSTNAME';
            }else if( kvp.key == 'CONTACT_BY_POST'){
                kvp.value = 'FALSE';
            }else if( kvp.key == 'MARKETING_OPT_IN_3RD'){
                kvp.value = 'TRUE';
            }else if( kvp.key == 'LAST_NAME'){
                kvp.value = 'MAHLASTNAME';
            }else if( kvp.key == 'CONTACT_BY_EMAIL'){
                kvp.value = 'FALSE';
            }else if( kvp.key == 'STREET' ){
                kvp.value = '25 All Saints Road';
            }else if( kvp.key == 'CITY' ){
                kvp.value = 'Bristol';
            }else if( kvp.key == 'POSTCODE' ){
                kvp.value = 'BS8 2JL';
            }else if( kvp.key == 'COUNTRY' ){
                kvp.value = 'Bristol';
            }
        }
        spSub.guid = 'RIGHTONBUSTA';

        SubscriberPortal.Response resp = SubscriberPortal.updateSubscriber(spSub);

        // Check all the updates worked
        Account acc1 = [SELECT id, guid__c, subscriber_number_static__c, personMailingPostalCode, firstName, lastName, personEmail,personHasOptedOutOfEmail, Do_Not_Mail__pc, PersonDoNotCall, X3rd_Party_Email_Offers__pc, TMG_Promo_SMS__c, TMG_Loyalty_Email__c, TMG_Promo_Email__c, TMG_Promo_Post__c, TMG_Promo_Phone__c, TMG_Partner_Promo_Email__c
             FROM Account a WHERE subscriber_number_static__c = :acc.subscriber_number_static__c];
        SubscriberPortal.Subscriber spSub1 = SubscriberPortal.getSubscriber(acc1.subscriber_number_static__c, acc1.personMailingPostalCode);
        List<SubscriberPortal.KeyValuePair> kvps1 = spSub1.attributes;
        System.debug('asserting kvps: '+kvps1);
        System.debug(' account: '+acc1);

        for(SubscriberPortal.KeyValuePair kvp : kvps1 ){
            if(kvp.key == 'CONTACT_BY_PHONE'){
                System.assert(kvp.value == 'FALSE','asserting kvps: '+kvps1 + ' account: '+acc1 + ' response: '+resp);
            }else if( kvp.key == 'FIRST_NAME'){
                System.assert(kvp.value == 'MAHFIRSTNAME',kvp.value);
            }else if( kvp.key == 'CONTACT_BY_POST'){
                System.assert(kvp.value == 'FALSE',kvp.value);
            }else if( kvp.key == 'MARKETING_OPT_IN_3RD'){
                System.assert(kvp.value == 'TRUE',kvp.value);
            }else if( kvp.key == 'LAST_NAME'){
                System.assert(kvp.value == 'MAHLASTNAME',kvp.value);
            }else if( kvp.key == 'CONTACT_BY_EMAIL'){
                System.assert(kvp.value == 'FALSE',kvp.value);
            }else if( kvp.key == 'STREET' ){
                System.assert(kvp.value == '25 All Saints Road',kvp.value);
            }else if( kvp.key == 'CITY' ){
                System.assert(kvp.value == 'Bristol',kvp.value);
            }else if( kvp.key == 'POSTCODE' ){
                System.assert(kvp.value == 'BS8 2JL',kvp.value);
            }else if( kvp.key == 'COUNTRY' ){
                System.assert(kvp.value == 'Bristol',kvp.value);
            }
        }
        System.assert(spSub1.guid == 'RIGHTONBUSTA');
    }

    public static testMethod void testTrigger_Account_beforeUpd_clearDoNotContact(){
        init();
        Account acc = setupAccount('Luhoosuher','N8');

        // Set the record flags - Changes are internal so trigger should leave record untouched
        acc.Do_Not_Contact__pc = true;
        acc.TMG_Loyalty_Email__c = 1;
        acc.Do_Not_Mail__pc = true;

        update acc;
        acc = [SELECT id, firstname, lastname, do_not_contact__pc, tmg_loyalty_email__c, do_not_mail__pc, persondonotcall, PersonHasOptedOutOfEmail FROM Account WHERE id = :acc.id];

        System.assert(acc.Do_Not_Contact__pc, 'do not contact: '+acc.Do_Not_Contact__pc); // trigger has done nothing - as expected

        // Test 1 - Set Do Not Mail = false. Do not contact should still be true
        acc.Do_Not_Mail__pc = false;
        update acc;

        acc = [SELECT id, firstname, lastname, do_not_contact__pc, tmg_loyalty_email__c, do_not_mail__pc, persondonotcall, PersonHasOptedOutOfEmail FROM Account WHERE id = :acc.id];
        System.assert(acc.Do_Not_Contact__pc, 'do not contact: '+acc.Do_Not_Contact__pc); // trigger has done nothing - as expected

        // Test 2 - update some of the other relevant fields but leave donotcontact in tact
        acc.PersonDoNotCall = false;
        acc.PersonHasOptedOutOfEmail = false;
        update acc;

        acc = [SELECT id, firstname, lastname, do_not_contact__pc, tmg_loyalty_email__c, do_not_mail__pc, persondonotcall, PersonHasOptedOutOfEmail FROM Account WHERE id = :acc.id];
        System.assert(acc.Do_Not_Contact__pc, 'do not contact: '+acc.Do_Not_Contact__pc); // trigger has done nothing - as expected
    }

    private static testMethod void testInvertDoNotContactFlag(){
        setupCustomSettings();
        Account acc_test = setupAccount('TESTING','ZZZ');
        Subscription__c sub = setupSub(acc_test,Constants.SSTATUS_ACTIVE);
        System.debug('acc before: '+acc_test);

        Account acc = [select Id, PersonMailingPostalCode, LastName, subscriber_number_static__c, Do_Not_Contact__pc from Account where Id = :acc_test.Id];
        acc.Do_Not_Contact__pc = true;
        update acc;

        SubscriberPortal.Subscriber spSub = SubscriberPortal.getSubscriber(acc.subscriber_number_static__c, acc.personMailingPostalCode);
        System.debug('spsub b4: '+spSub);

        List<SubscriberPortal.KeyValuePair> kvps = spSub.attributes;
        System.debug('kvps before: '+kvps);

        System.assert(spSub.guid == null);

        // Change the data
        for(SubscriberPortal.KeyValuePair kvp : kvps ){
            if(kvp.key == 'CONTACT_BY_PHONE'){
                kvp.value = 'TRUE';
            }else if( kvp.key == 'FIRST_NAME'){
                kvp.value = 'MAHFIRSTNAME';
            }else if( kvp.key == 'CONTACT_BY_POST'){
                kvp.value = 'TRUE';
            }else if( kvp.key == 'MARKETING_OPT_IN_3RD'){
                kvp.value = 'FALSE';
            }else if( kvp.key == 'LAST_NAME'){
                kvp.value = 'MAHLASTNAME';
            }else if( kvp.key == 'CONTACT_BY_EMAIL'){
                kvp.value = 'FALSE';
            }
        }

        System.debug('kvps after: '+kvps);

        spSub.guid = 'RIGHTONBUSTA';

        SubscriberPortal.Response resp = SubscriberPortal.updateSubscriber(spSub);

        // Check all the updates worked
        Account acc1 = [SELECT id, do_not_contact__pc, guid__c, subscriber_number_static__c, firstName, lastName, salutation, personEmail, PersonHomePhone, PersonMobilePhone, personHasOptedOutOfEmail, Do_Not_Mail__pc, PersonDoNotCall, X3rd_Party_Email_Offers__pc, TMG_Promo_SMS__c, TMG_Loyalty_Email__c, TMG_Promo_Email__c, TMG_Promo_Post__c, TMG_Promo_Phone__c, TMG_Partner_Promo_Email__c, PersonMailingStreet, PersonMailingCity, PersonMailingPostalCode, PersonMailingCountry, PersonMailingState, Subscriber_Digital_Status__c, Digital_Product_Type__c, RecordTypeId  FROM Account a WHERE subscriber_number_static__c = :acc.subscriber_number_static__c];
        SubscriberPortal.Subscriber spSub1 = SubscriberPortal.getSubscriber(acc1.subscriber_number_static__c, acc1.personMailingPostalCode);
        List<SubscriberPortal.KeyValuePair> kvps1 = spSub1.attributes;
        System.debug('asserting kvps: '+kvps1);
        System.debug(' account: '+acc1);

        System.assert(acc1.do_not_contact__pc == false); //should have been reversed from updateSubscriber call
        System.assert(spSub1.guid == 'RIGHTONBUSTA');

    }

    private static testMethod void testPermissionsLastChangeDate(){
        setupCustomSettings();
        Account acc_test = setupAccount('TESTING','ZZZ');
        Subscription__c sub = setupSub(acc_test,Constants.SSTATUS_ACTIVE);
        System.debug('acc before: '+acc_test);

        Account acc = [select Id, Permissions_Last_Change_Date__c, PersonMailingPostalCode, LastName, subscriber_number_static__c, Do_Not_Contact__pc from Account where Id = :acc_test.Id];
        acc.Do_Not_Contact__pc = true;
        update acc;

        System.assert(acc.Permissions_Last_Change_Date__c == Date.Today());

        SubscriberPortal.Subscriber spSub = SubscriberPortal.getSubscriber(acc.subscriber_number_static__c, acc.personMailingPostalCode);
        System.debug('spsub b4: '+spSub);

        List<SubscriberPortal.KeyValuePair> kvps = spSub.attributes;
        System.debug('kvps before: '+kvps);

        System.assert(spSub.guid == null);

        // Change the data
        for(SubscriberPortal.KeyValuePair kvp : kvps ){
            if(kvp.key == 'CONTACT_BY_PHONE'){
                kvp.value = 'TRUE';
            }else if( kvp.key == 'FIRST_NAME'){
                kvp.value = 'MAHFIRSTNAME';
            }else if( kvp.key == 'CONTACT_BY_POST'){
                kvp.value = 'TRUE';
            }else if( kvp.key == 'MARKETING_OPT_IN_3RD'){
                kvp.value = 'FALSE';
            }else if( kvp.key == 'LAST_NAME'){
                kvp.value = 'MAHLASTNAME';
            }else if( kvp.key == 'CONTACT_BY_EMAIL'){
                kvp.value = 'FALSE';
            }
        }

        System.debug('kvps after: '+kvps);

        spSub.guid = 'RIGHTONBUSTA';

        SubscriberPortal.Response resp = SubscriberPortal.updateSubscriber(spSub);

        // Check all the updates worked
        Account acc1 = [SELECT id, guid__c, permissions_Last_Change_Date__c, subscriber_number_static__c, firstName, lastName, salutation, personEmail, PersonHomePhone, PersonMobilePhone, personHasOptedOutOfEmail, Do_Not_Mail__pc, PersonDoNotCall, X3rd_Party_Email_Offers__pc, TMG_Promo_SMS__c, TMG_Loyalty_Email__c, TMG_Promo_Email__c, TMG_Promo_Post__c, TMG_Promo_Phone__c, TMG_Partner_Promo_Email__c, PersonMailingStreet, PersonMailingCity, PersonMailingPostalCode, PersonMailingCountry, PersonMailingState, Subscriber_Digital_Status__c, Digital_Product_Type__c, RecordTypeId  FROM Account a WHERE subscriber_number_static__c = :acc.subscriber_number_static__c];
        SubscriberPortal.Subscriber spSub1 = SubscriberPortal.getSubscriber(acc1.subscriber_number_static__c, acc1.personMailingPostalCode);
        List<SubscriberPortal.KeyValuePair> kvps1 = spSub1.attributes;
        System.assert(acc1.permissions_Last_Change_Date__c == System.today()); //should have been set based on permissions field changes
        System.assert(spSub1.guid == 'RIGHTONBUSTA');
    }

    /***************************************************************************************
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Function - testGetSubscribers
    #############Change Log#############
    Modified by     	Version     Change Date
    Cristina Anghenie   1.1         22/09/2015  //remove SubscriberPortal__c custom settings
    Michal Szewczyk 	1.2			20/04/2016	//added setEntitlemetMapping invocation
    ****************************************************************************************/
    private static void init(){
        TestDataUtility tdu = new TestDataUtility();
        tdu.loadSAMHTTPSettings();
        tdu.loadGeneral();
        tdu.loadPlaneURL();
        tdu.setEntitlemetMapping();
    }

    private static testMethod void digitalentitlementactive(){
        init();
        Account a = new Account(lastname='lastname', PersonMailingPostalCode='NN4 3ET', RecordTypeId=Constants.DigitalSubscriberRecordType(), Subscriber_Digital_Status__c='Active', Digital_Product_Type__c=Constants.DIGITAL_PRODUCT_ALLDEVICES);
        try{
            insert a;
        }catch(Exception ex){}
        a = [SELECT Id, Subscriber_Number_Static__c FROM Account WHERE Id = :a.id];
        System.assertNotEquals(null, a);

        Account subscriber = [SELECT id, Subscriber_Number_Static__c, PersonMailingPostalCode FROM Account a WHERE Id = :a.Id];
        SubscriberPortal.Subscriber sub = SubscriberPortal.getSubscriber(a.subscriber_number_static__c, 'nn43et');

        System.assertEquals(1, sub.entitlements.size());
        System.assertEquals(Constants.DIGITAL_SUBSCRIBER_ACTIVE, sub.entitlements[0]);
    }

    private static testMethod void digitalentitlementinactive(){
        init();
        Account a = new Account(lastname='lastname', PersonMailingPostalCode='NN4 3ET', RecordTypeId=Constants.DigitalSubscriberRecordType(), Subscriber_Digital_Status__c='Inactive', Digital_Product_Type__c=Constants.DIGITAL_PRODUCT_ALLDEVICES);
        try{
            insert a;
        }catch(Exception ex){}
        a = [SELECT Id, Subscriber_Number_Static__c FROM Account WHERE Id = :a.id];
        System.assertNotEquals(null, a);

        Account subscriber = [SELECT id, Subscriber_Number_Static__c, PersonMailingPostalCode FROM Account a WHERE Id = :a.Id];
        SubscriberPortal.Subscriber sub = SubscriberPortal.getSubscriber(a.subscriber_number_static__c, 'nn43et');

        System.assertEquals(1, sub.entitlements.size());
        System.assertEquals(Constants.DIGITAL_SUBSCRIBER_INACTIVE, sub.entitlements[0]);
    }

    private static testMethod void webpackentitlementactive(){
        init();
        Account a = new Account(lastname='lastname', PersonMailingPostalCode='NN4 3ET', RecordTypeId=Constants.DigitalSubscriberRecordType(), Subscriber_Digital_Status__c='Active', Digital_Product_Type__c=Constants.DIGITAL_PRODUCT_WEBPACK);
        try{
            insert a;
        }catch(Exception ex){}
        a = [SELECT Id, Subscriber_Number_Static__c FROM Account WHERE Id = :a.id];
        System.assertNotEquals(null, a);

        Account subscriber = [SELECT id, Subscriber_Number_Static__c, PersonMailingPostalCode FROM Account a WHERE Id = :a.Id];
        SubscriberPortal.Subscriber sub = SubscriberPortal.getSubscriber(a.subscriber_number_static__c, 'nn43et');

        System.assertEquals(1, sub.entitlements.size());
        System.assertEquals(Constants.WEBPACK_SUBSCRIBER_ACTIVE, sub.entitlements[0]);
    }

    private static testMethod void webpackentitlementinactive(){
        init();
        Account a = new Account(lastname='lastname', PersonMailingPostalCode='NN4 3ET', RecordTypeId=Constants.DigitalSubscriberRecordType(), Subscriber_Digital_Status__c='Inactive', Digital_Product_Type__c=Constants.DIGITAL_PRODUCT_WEBPACK);
        try{
            insert a;
        }catch(Exception ex){}
        a = [SELECT Id, Subscriber_Number_Static__c FROM Account WHERE Id = :a.id];
        System.assertNotEquals(null, a);

        Account subscriber = [SELECT id, Subscriber_Number_Static__c, PersonMailingPostalCode FROM Account a WHERE Id = :a.Id];
        SubscriberPortal.Subscriber sub = SubscriberPortal.getSubscriber(a.subscriber_number_static__c, 'nn43et');

        System.assertEquals(1, sub.entitlements.size());
        System.assertEquals(Constants.WEBPACK_SUBSCRIBER_INACTIVE, sub.entitlements[0]);
    }

    private static testMethod void testReturnAccountAttributes(){
        SubscriberPortal.Subscriber sub = new SubscriberPortal.Subscriber();
        sub.attributes = new List<SubscriberPortal.KeyValuePair>();
        init();
        Account acc = new Account(lastname='lastname', PersonMailingPostalCode='NN4 3ET', RecordTypeId=Constants.DigitalSubscriberRecordType(),
                                Subscriber_Digital_Status__c='Inactive', Digital_Product_Type__c=Constants.DIGITAL_PRODUCT_ALLDEVICES,
                                Guid__c = 'test1234');
        try{
            insert acc;
        }catch(Exception ex){}
        sub  = SubscriberPortal.returnAccountAttributes(acc,sub);
        System.assertEquals(acc.Guid__c,sub.Guid);
        System.assertEquals(acc.Subscriber_Number_Static__c,sub.no);
    }
    /***************************************************************************************
    Developer - Michal Szeczyk
    Date - 21/01/2016
    Version - 1.1
    Function - Test if the entitlement is assign corectly based on the subscription status and account.subscription_status__s
    #############Change Log#############
    Modified by     Version     Change Date
    Michal Szewczyk	1.1			01.03.2016   - replace old methods with createDigitalSubscribers and createIndividualSubscribers
    ****************************************************************************************/
    private static testMethod void testCalculateEntitlementsNWTransP(){
        TestDataUtility tdu = new TestDataUtility(2);
        tdu.loadEntitlementsSettings();
        tdu.loadEntitlementsMappingSettings();
        tdu.loadSAMHTTPSettings();
        tdu.loadGeneral();
        tdu.loadPlaneURL();
        tdu.createRetailers();
        tdu.createZProductFeatures();
        tdu.createDigitalSubscribers();
        tdu.createIndividualSubscribers();
        map<String,Entitlements__c> entCustomSettings = Entitlements__c.getAll();
        SubscriberPortal.Subscriber sub = new SubscriberPortal.Subscriber();
        sub.entitlements = new List<String>();

        //create web-digital account
        Account webDigitalAcc = tdu.lstDigitalSubscribers[0];
        //webDigitalAcc.Digital_Product_Type__c = Constants.DIGITAL_PRODUCT_WEBPACK;
        zqu__ZFeature__c webDigFeature = TestDataUtility.newZFeatureByName('FeatureD1',10);
        insert webDigFeature;
        zqu__ZProductFeature__c prodToFeature = TestDataUtility.newZProductFeature(webDigFeature.id,tdu.lstZproducts[0].id,10);
        insert prodToFeature;
        System.debug('MISZE mapProductNameWithEntitlements:' +EntitlementUtility.mapProductNameWithEntitlements);
        webDigitalAcc.Product__c = tdu.lstZproducts[0].id;
        webDigitalAcc.Subscriber_Digital_Status__c = 'Active';
        webDigitalAcc.Subscriber_Number_Static__c = 'TS9899999';
        update webDigitalAcc;
        //active entitlement assign to active account
        sub = SubscriberPortal.calculateEntitlements(webDigitalAcc,sub);
        System.assertEquals(entCustomSettings.get('DIGITAL_WEBPACK').Active_Entitlement_Value__c,sub.entitlements[0]);

        //Subscriber_Digital_Status__c for account set to inactive
        webDigitalAcc.Subscriber_Digital_Status__c = 'Inactive';
        update webDigitalAcc;
        System.assertEquals(webDigitalAcc.Subscriber_Digital_Status__c,'Inactive');
        sub.entitlements = new List<String>();
        sub = SubscriberPortal.calculateEntitlements(webDigitalAcc,sub);
        System.assertEquals(entCustomSettings.get('DIGITAL_WEBPACK').Inactive_Entitlement_Value__c,sub.entitlements[0]);

        //create premium account
        Account premiumAcc = tdu.lstIndividualSubscribers[0];
        Subscription__c subscription = TestDataUtility.newSubscripiton(1,premiumAcc.Id,tdu.lstRetailers[0].Id,System.today());
        insert subscription;
        //active subscription status
        premiumAcc = [SELECT Id,Subscription_Status__c,RecordTypeId,Product__c,Digital_Product_Type__c FROM Account WHERE Id=: premiumAcc.Id];
        System.assertEquals('Active',premiumAcc.Subscription_Status__c);
        sub.entitlements = new List<String>();
        sub = SubscriberPortal.calculateEntitlements(premiumAcc,sub);
        System.assertEquals(entCustomSettings.get('PRINT_7DAYSTANDARD').Active_Entitlement_Value__c,sub.entitlements[0]);

        //pending subscription status
        subscription.Subscription_Status__c = 'Pending';
        update subscription;
        premiumAcc = [SELECT Id,Subscription_Status__c,RecordTypeId,Product__c,Digital_Product_Type__c FROM Account WHERE Id=: premiumAcc.Id];
        System.assertEquals('Pending',premiumAcc.Subscription_Status__c);
        sub.entitlements = new List<String>();
        sub = SubscriberPortal.calculateEntitlements(premiumAcc,sub);
        System.assertEquals(entCustomSettings.get('PRINT_7DAYSTANDARD').Pending_Entitlement_value__c,sub.entitlements[0]);

        //pending subscription status
        subscription.Subscription_Status__c = 'Lapsed';
        update subscription;
        premiumAcc = [SELECT Id,Subscription_Status__c,RecordTypeId,Product__c,Digital_Product_Type__c FROM Account WHERE Id=: premiumAcc.Id];
        System.assertEquals('Inactive',premiumAcc.Subscription_Status__c);
        Subscription__c newSubscription = TestDataUtility.newSubscripiton(1,premiumAcc.Id,tdu.lstRetailers[0].Id, System.today());
        newSubscription.Subscription_Status__c = 'Offered';
        newSubscription.Previous_Subscription__c = subscription.Id;
        insert newSubscription;
        sub.entitlements = new List<String>();
        sub = SubscriberPortal.calculateEntitlements(premiumAcc,sub);
        System.assertEquals(entCustomSettings.get('PRINT_7DAYSTANDARD').Recently_Inactive_Entitlement_Value__c,sub.entitlements[0]);
    }
    /***************************************************************************************
    Developer - Cristina Popescu (Tquila)
    Date - 11/06/2015
    Version - 1.2
    Function - Test if the entitlement is assign corectly based on the subscription status and account.subscription_status__s
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin	1.1			14/10/2015	//added retailer for subscription creation
    Wiktor Czykin	1.2			24/02/2016	//modifed the accounts creation to not use old methods
    ****************************************************************************************/
    private static testMethod void testCalculateEntitlements(){
        TestDataUtility tdu = new TestDataUtility(4);
        tdu.loadEntitlementsSettings();
        tdu.createRetailers();
        tdu.createIndividualSubscribers();
        tdu.createDigitalSubscribers();

        Map<String, Entitlements__c> entCustomSettings = Entitlements__c.getAll();
        SubscriberPortal.Subscriber sub = new SubscriberPortal.Subscriber();
        sub.entitlements = new List<String>();

        //create web-digital account
        Account webDigitalAcc = tdu.lstDigitalSubscribers[0];
        webDigitalAcc.Subscriber_Digital_Status__c = Constants.SUBSCRIBER_ACTIVE_STATUS;
        webDigitalAcc.Digital_Product_Type__c = Constants.DIGITAL_PRODUCT_WEBPACK;
        update webDigitalAcc;
        //active entitlement assign to active account
        sub = SubscriberPortal.calculateEntitlements(webDigitalAcc,sub);
        System.assertEquals(entCustomSettings.get('DIGITAL_WEBPACK').Active_Entitlement_Value__c,sub.entitlements[0]);

        //Subscriber_Digital_Status__c for account set to inactive
        webDigitalAcc.Subscriber_Digital_Status__c = 'Inactive';
        update webDigitalAcc;
        System.assertEquals(webDigitalAcc.Subscriber_Digital_Status__c,'Inactive');
        sub.entitlements = new List<String>();
        sub = SubscriberPortal.calculateEntitlements(webDigitalAcc,sub);
        System.assertEquals(entCustomSettings.get('DIGITAL_WEBPACK').Inactive_Entitlement_Value__c,sub.entitlements[0]);

        //create premium account
        Account premiumAcc = tdu.lstIndividualSubscribers[0];
        Subscription__c subscription = TestDataUtility.newSubscripiton(1,premiumAcc.Id,tdu.lstRetailers[0].Id,System.today());
        insert subscription;
        //active subscription status
        premiumAcc = [SELECT Id,Subscription_Status__c,RecordTypeId,Product__c,Digital_Product_Type__c FROM Account WHERE Id=: premiumAcc.Id];
        System.assertEquals('Active',premiumAcc.Subscription_Status__c);
        sub.entitlements = new List<String>();
        sub = SubscriberPortal.calculateEntitlements(premiumAcc,sub);
        System.assertEquals(entCustomSettings.get('PRINT_7DAYSTANDARD').Active_Entitlement_Value__c,sub.entitlements[0]);

        //pending subscription status
        subscription.Subscription_Status__c = 'Pending';
        update subscription;
        premiumAcc = [SELECT Id,Subscription_Status__c,RecordTypeId,Product__c,Digital_Product_Type__c FROM Account WHERE Id=: premiumAcc.Id];
        System.assertEquals('Pending',premiumAcc.Subscription_Status__c);
        sub.entitlements = new List<String>();
        sub = SubscriberPortal.calculateEntitlements(premiumAcc,sub);
        System.assertEquals(entCustomSettings.get('PRINT_7DAYSTANDARD').Pending_Entitlement_value__c,sub.entitlements[0]);

        //pending subscription status
        subscription.Subscription_Status__c = 'Lapsed';
        update subscription;
        premiumAcc = [SELECT Id,Subscription_Status__c,RecordTypeId,Product__c,Digital_Product_Type__c FROM Account WHERE Id=: premiumAcc.Id];
        System.assertEquals('Inactive',premiumAcc.Subscription_Status__c);
        Subscription__c newSubscription = TestDataUtility.newSubscripiton(1,premiumAcc.Id,tdu.lstRetailers[0].Id, System.today());
        newSubscription.Subscription_Status__c = 'Offered';
        newSubscription.Previous_Subscription__c = subscription.Id;
        insert newSubscription;
        sub.entitlements = new List<String>();
        sub = SubscriberPortal.calculateEntitlements(premiumAcc,sub);
        System.assertEquals(entCustomSettings.get('PRINT_7DAYSTANDARD').Recently_Inactive_Entitlement_Value__c,sub.entitlements[0]);
    }

    /***************************************************************************************
    Developer - Cristina Popescu (Tquila)
    Date - 26/06/2015
    Version - 1.1
    Function - Test if the in renewal subscription status will send in renewal sam entitlement
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin	1.1			14/10/2015	//changed how test records are created
    ****************************************************************************************/
    private static testMethod void testCalculateInRenewalEntitlements(){
        TestDataUtility tdu = new TestDataUtility(1);
        tdu.loadEntitlementsSettings();
        tdu.loadSAMHTTPSettings();
        tdu.loadGeneral();
        tdu.loadPlaneURL();

        map<String,Entitlements__c> entCustomSettings = Entitlements__c.getAll();
        SubscriberPortal.Subscriber sub = new SubscriberPortal.Subscriber();
        sub.entitlements = new List<String>();

        //create premium account
        tdu.checkSubscriptionDependencies();
        Subscription__c subscription = TestDataUtility.newSubscripiton(1, tdu.lstIndividualSubscribers[0].Id, tdu.lstRetailers[0].Id, System.today());
        subscription.Subscription_Status__c = 'In Renewal';
        insert subscription;
        //in renewal subscription status
        Test.startTest();
            Account premiumAcc = [SELECT Id,Subscription_Status__c,RecordTypeId,Product__c,Digital_Product_Type__c FROM Account WHERE Id=:tdu.lstIndividualSubscribers[0].Id];
            sub.entitlements = new List<String>();
            sub = SubscriberPortal.calculateEntitlements(premiumAcc,sub);
        Test.stopTest();
        System.assertEquals('Active',premiumAcc.Subscription_Status__c);
        System.assertEquals(entCustomSettings.get('PRINT_7DAYSTANDARD').InRenewal_Entitlement_Value__c,sub.entitlements[0]);
    }

    /***************************************************************************************
    Developer - Pawel Chrzanowski
    Date - 24/03/2016
    Version - 1.1
    Function - Test Registrant entitlements
    #############Change Log#############
    Modified by    		Version     Change Date
    Wiktor Czykin		.1.1		12/05/2016	//fixed entitlements mapping (Name -> Entitlement__c)
    ****************************************************************************************/
    private static testMethod void testCalculateRegistrantEntitlements(){
        TestDataUtility tdu = new TestDataUtility(8);
        tdu.loadEntitlementsSettings();
        tdu.loadEntitlementsMappingSettings();
        tdu.createRegistrants();
        tdu.createZProducts();
        tdu.createZProductFeatures();

        tdu.lstZFeature[0].Name = 'Tablet';
        tdu.lstZFeature[0].Entitlement__c = 'Tablet';
        tdu.lstZFeature[1].Name = 'Website';
        tdu.lstZFeature[1].Entitlement__c = 'Website';
        update tdu.lstZFeature;

        tdu.lstZproducts[0].Name = Constants.TABLET_UK_PRODUCT_NAME;
        tdu.lstZproducts[1].Name = Constants.TABLET_INTERNATIONAL_PRODUCT_NAME;
        tdu.lstZproducts[2].Name = Constants.WEBSITE_UK_PRODUCT_NAME;
        tdu.lstZproducts[3].Name = Constants.WEBSITE_INTERNATIONAL_PRODUCT_NAME;
        update tdu.lstZproducts;

        tdu.lstZProductFeature[0].zqu__ZProduct__c = tdu.lstZproducts[0].Id;
        tdu.lstZProductFeature[0].zqu__ZFeature__c = tdu.lstZFeature[0].Id;
        tdu.lstZProductFeature[1].zqu__ZProduct__c = tdu.lstZproducts[1].Id;
        tdu.lstZProductFeature[1].zqu__ZFeature__c = tdu.lstZFeature[0].Id;
        tdu.lstZProductFeature[2].zqu__ZProduct__c = tdu.lstZproducts[2].Id;
        tdu.lstZProductFeature[2].zqu__ZFeature__c = tdu.lstZFeature[1].Id;
        tdu.lstZProductFeature[3].zqu__ZProduct__c = tdu.lstZproducts[3].Id;
        tdu.lstZProductFeature[3].zqu__ZFeature__c = tdu.lstZFeature[1].Id;
        update tdu.lstZProductFeature;

        tdu.lstRegistrants[0].Firstname = 'testname 0';
        tdu.lstRegistrants[0].Replatform_Digital_Status__c = Constants.SSTATUS_ACTIVE;
        tdu.lstRegistrants[0].Product__c = tdu.lstZproducts[0].Id;
        tdu.lstRegistrants[1].Firstname = 'testname 1';
        tdu.lstRegistrants[1].Replatform_Digital_Status__c = Constants.SSTATUS_ACTIVE;
        tdu.lstRegistrants[1].Product__c = tdu.lstZproducts[1].Id;
        tdu.lstRegistrants[2].Firstname = 'testname 2';
        tdu.lstRegistrants[2].Replatform_Digital_Status__c = Constants.SSTATUS_ACTIVE;
        tdu.lstRegistrants[2].Product__c = tdu.lstZproducts[2].Id;
        tdu.lstRegistrants[3].Firstname = 'testname 3';
        tdu.lstRegistrants[3].Replatform_Digital_Status__c = Constants.SSTATUS_ACTIVE;
        tdu.lstRegistrants[3].Product__c = tdu.lstZproducts[3].Id;
        tdu.lstRegistrants[4].Firstname = 'testname 4';
        tdu.lstRegistrants[4].Replatform_Digital_Status__c = 'Inactive';
        tdu.lstRegistrants[4].Product__c = tdu.lstZproducts[0].Id;
        tdu.lstRegistrants[5].Firstname = 'testname 5';
        tdu.lstRegistrants[5].Replatform_Digital_Status__c = 'Inactive';
        tdu.lstRegistrants[5].Product__c = tdu.lstZproducts[1].Id;
        tdu.lstRegistrants[6].Firstname = 'testname 6';
        tdu.lstRegistrants[6].Replatform_Digital_Status__c = 'Inactive';
        tdu.lstRegistrants[6].Product__c = tdu.lstZproducts[2].Id;
        tdu.lstRegistrants[7].Firstname = 'testname 7';
        tdu.lstRegistrants[7].Replatform_Digital_Status__c = 'Inactive';
        tdu.lstRegistrants[7].Product__c = tdu.lstZproducts[3].Id;
        update tdu.lstRegistrants;

        List<Account> lstAccounts = [select Firstname, RecordTypeId, Digital_status__c, Digital_Product_Type__c, Product__c, Product__r.Name from Account];

        String activeDigitalEntitlement;
        if(Entitlements__c.getInstance('DIGITAL_DIGIPACK') != null && Entitlements__c.getInstance('DIGITAL_DIGIPACK').Active_Entitlement_Value__c != null){
            activeDigitalEntitlement = Entitlements__c.getInstance('DIGITAL_DIGIPACK').Active_Entitlement_Value__c;
        }else{
            activeDigitalEntitlement = 'DIGITAL_SUBSCRIBER_ACTIVE';
        }

        String activeWebpackEntitlement;
        if(Entitlements__c.getInstance('DIGITAL_WEBPACK') != null && Entitlements__c.getInstance('DIGITAL_WEBPACK').Active_Entitlement_Value__c != null){
            activeWebpackEntitlement = Entitlements__c.getInstance('DIGITAL_WEBPACK').Active_Entitlement_Value__c;
        }else{
            activeWebpackEntitlement = 'WEBPACK_SUBSCRIBER_ACTIVE';
        }

        SubscriberPortal.Subscriber subscriber;

        Test.startTest();
            for(Account acc : lstAccounts){
                subscriber = new SubscriberPortal.Subscriber();
                subscriber.entitlements = new List<String>();
                subscriber = SubscriberPortal.calculateEntitlements(acc, subscriber);

                if(acc.Firstname == 'testname 0') System.assertEquals(activeDigitalEntitlement, subscriber.entitlements[0]);
                else if(acc.Firstname == 'testname 1') System.assertEquals(activeDigitalEntitlement, subscriber.entitlements[0]);
                else if(acc.Firstname == 'testname 2') System.assertEquals(activeWebpackEntitlement, subscriber.entitlements[0]);
                else if(acc.Firstname == 'testname 3') System.assertEquals(activeWebpackEntitlement, subscriber.entitlements[0]);
                else if(acc.Firstname == 'testname 4') System.assertNotEquals(activeDigitalEntitlement, subscriber.entitlements[0]);
                else if(acc.Firstname == 'testname 5') System.assertNotEquals(activeDigitalEntitlement, subscriber.entitlements[0]);
                else if(acc.Firstname == 'testname 6') System.assertNotEquals(activeWebpackEntitlement, subscriber.entitlements[0]);
                else if(acc.Firstname == 'testname 7') System.assertNotEquals(activeWebpackEntitlement, subscriber.entitlements[0]);
            }
        Test.stopTest();
    }

    /***************************************************************************************
    Developer - Cristina Anghenie (Tquila)
    Date - 21/07/2015
    Version - 1.1
    Function - Test if entitlement is set correctly for all type of products
    #############Change Log#############
    Modified by     Versi`on     Change Date
    Wiktor Czykin	1.1			14/10/2015	//changed record creation
    Michal Szewczyk 	1.2		20/04/2016	//added setEntitlemetMapping invocation
    ****************************************************************************************/
    private static testMethod void testEntitlementState(){
        TestDataUtility tdu = new TestDataUtility(1);
        tdu.loadEntitlementsSettings();
        tdu.loadSAMHTTPSettings();
        tdu.loadGeneral();
        tdu.loadPlaneURL();
        tdu.setEntitlemetMapping();
        List<String> entitlements = new List<String>();
        //create premium account
        tdu.checkSubscriptionDependencies();
        Subscription__c subscription = TestDataUtility.newSubscripiton(1, tdu.lstIndividualSubscribers[0].Id, tdu.lstRetailers[0].Id, System.today());
        insert subscription;

        Test.startTest();
            SubscriberPortal.Subscriber sub = new SubscriberPortal.Subscriber(null,tdu.lstIndividualSubscribers[0],new List<Subscription__c>{subscription},null);
            System.assertEquals('7DAY_SUBSCRIBER_'+Constants.SSTATUS_ACTIVE.toUpperCase(),sub.entitlements[0]);

            entitlements = new List<String>();
            update subscription;
            sub = new SubscriberPortal.Subscriber(null,tdu.lstIndividualSubscribers[0],new List<Subscription__c>{subscription},null);
            System.assertEquals('7DAY_SUBSCRIBER_'+Constants.SSTATUS_ACTIVE.toUpperCase(),sub.entitlements[0]);
        Test.stopTest();

    }

    /* Utility Methods */

    /***************************************************************************************
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Function - testGetSubscribers
    #############Change Log#############
    Modified by     	Version     Change Date
    Cristina Anghenie   1.1         22/09/2015  //remove SubscriberPortal__c custom settings
    Michal Szewczyk 	1.2			20/04/2016	//added setEntitlemetMapping invocation
    ****************************************************************************************/
    public static void setupCustomSettings(){
        TestDataUtility tdu = new TestDataUtility();
        tdu.loadSAMHTTPSettings();
        tdu.loadGeneral();
        tdu.loadPlaneURL();
        tdu.setEntitlemetMapping();
    }

    public static Account setupAccount(String lname, String postcode){
        Account acc = new Account(lastname=lname, personmailingPostalCode=postcode, PersonEmail = (lname.replace(' ', '_'))+'test@test.com');
        insert acc;

        acc = [SELECT Id, LastName, PersonEmail, PersonMailingPostalCode, Subscriber_Number_Static__c FROM Account WHERE Id = :acc.Id];
        return acc;
    }

    public static Subscription__c setupSub(Account acc, String status){
        //sms-473
        Date stDate = UtilitySelectOptionsSubscriptions.getFirstStartDate(5);
        return setupSub(acc, status, stDate);
    }

    /***************************************************************************************
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Function - generate data for tests
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         02/03/2015  //modified record type fetching as was throwing exceptions on deployment
    ****************************************************************************************/
    public static Subscription__c setupSub(Account acc, String status, Date startDate){
        Id rt = RecordTypeUtility.getRecordTypeId(Subscription__c.SObjectType, Constants.RECTYPE_SUBSCRIPTION_DEFAULT, Subscription__c.class.getName());
        System.assertNotEquals(null, rt);
        Integer price;

        if(status.toUpperCase() == 'OFFERED')
            price = null;
        else
            price = 5;

        Subscription__c sub = new Subscription__c(Voucher_Pack_Duration__c=1,Cancellation_Date__c=null,Cancellation_Method__c=null, Cancellation_Reason__c=null, start_date__c = startDate , Payment_Type__c = 'Cheque', Delivery_Type__c = 'OTC', Weekly_Price__c=price, Subscription_Status__c=status, Subscription_Duration_Picklist__c='26', Subscriber__c=acc.id, RecordTypeId=rt, Payment_Details_Received__c=true);
            insert sub;
        return sub;
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 16/09/2016
    Version - 1.0
    Function - test unbundling identify method - active individual subscriber / old/new
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private static testMethod void testIdentifyMethodActiveIndividual(){
        TestDataUtility td = new TestDataUtility(1);
        td.loadEntitlementsSettings();
        td.createSubscriptions();
        zqu__ZFeature__c zf2 = TestDataUtility.newZFeature(10);
        insert zf2;
        insert TestDataUtility.newZProductFeature(zf2.Id, td.lstZProducts[0].Id, 10);
        List<Account> lstAccount = [select Id, Subscriber_Number__c, PersonMailingPostalCode from Account where Id = :td.lstIndividualSubscribers[0].Id];
        System.assert(!lstAccount.isEmpty());

        Test.startTest();
            SubscriberPortal.Subscriber subWrapper = SubscriberPortal.identify(lstAccount[0].Subscriber_Number__c, lstAccount[0].PersonMailingPostalCode);
            System.assertEquals(2, subWrapper.entitlements.size());
            General__c g = new General__c(Name=SubscriberPortal.GENERAL_LEGACY_IDENTIFY_ENTITLEMENTS, Value_Boolean__c = true);
            insert g;
            subWrapper = SubscriberPortal.identify(lstAccount[0].Subscriber_Number__c, lstAccount[0].PersonMailingPostalCode);
            System.assertEquals(1, subWrapper.entitlements.size());
        Test.stopTest();
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 16/09/2016
    Version - 1.0
    Function - test unbundling identify method - pending individual subscriber / old/new
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private static testMethod void testIdentifyMethodPendingIndividual(){
        TestDataUtility td = new TestDataUtility(1);
        td.loadEntitlementsSettings();
        td.createSubscriptions();
        zqu__ZFeature__c zf2 = TestDataUtility.newZFeature(10);
        insert zf2;
        insert TestDataUtility.newZProductFeature(zf2.Id, td.lstZProducts[0].Id, 10);
        List<Account> lstAccount = [select Id, Subscriber_Number__c, PersonMailingPostalCode from Account where Id = :td.lstIndividualSubscribers[0].Id];
        System.assert(!lstAccount.isEmpty());
        td.lstSubscriptions[0].Subscription_Status__c = Constants.SSTATUS_PENDING;
        update td.lstSubscriptions[0];
        Test.startTest();
            SubscriberPortal.Subscriber subWrapper = SubscriberPortal.identify(lstAccount[0].Subscriber_Number__c, lstAccount[0].PersonMailingPostalCode);
            System.assertEquals(2, subWrapper.entitlements.size());
            General__c g = new General__c(Name=SubscriberPortal.GENERAL_LEGACY_IDENTIFY_ENTITLEMENTS, Value_Boolean__c = true);
            insert g;
            subWrapper = SubscriberPortal.identify(lstAccount[0].Subscriber_Number__c, lstAccount[0].PersonMailingPostalCode);
            System.assertEquals(1, subWrapper.entitlements.size());
        Test.stopTest();
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 16/09/2016
    Version - 1.0
    Function - test unbundling identify method - in renewal individual subscriber / old/new
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private static testMethod void testIdentifyMethodInRenewalIndividual(){
        TestDataUtility td = new TestDataUtility(1);
        td.loadEntitlementsSettings();
        td.createSubscriptions();
        zqu__ZFeature__c zf2 = TestDataUtility.newZFeature(10);
        insert zf2;
        insert TestDataUtility.newZProductFeature(zf2.Id, td.lstZProducts[0].Id, 10);
        List<Account> lstAccount = [select Id, Subscriber_Number__c, PersonMailingPostalCode from Account where Id = :td.lstIndividualSubscribers[0].Id];
        System.assert(!lstAccount.isEmpty());
        td.lstSubscriptions[0].Subscription_Status__c = Constants.SSTATUS_IN_RENEWAL;
        update td.lstSubscriptions[0];
        Test.startTest();
            SubscriberPortal.Subscriber subWrapper = SubscriberPortal.identify(lstAccount[0].Subscriber_Number__c, lstAccount[0].PersonMailingPostalCode);
            System.assertEquals(2, subWrapper.entitlements.size());
            General__c g = new General__c(Name=SubscriberPortal.GENERAL_LEGACY_IDENTIFY_ENTITLEMENTS, Value_Boolean__c = true);
            insert g;
            subWrapper = SubscriberPortal.identify(lstAccount[0].Subscriber_Number__c, lstAccount[0].PersonMailingPostalCode);
            System.assertEquals(1, subWrapper.entitlements.size());
        Test.stopTest();
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 16/09/2016
    Version - 1.0
    Function - test unbundling identify method - in pending cancellation individual subscriber / old/new
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private static testMethod void testIdentifyMethodPendingCancellationIndividual(){
        TestDataUtility td = new TestDataUtility(1);
        td.loadEntitlementsSettings();
        td.createSubscriptions();
        zqu__ZFeature__c zf2 = TestDataUtility.newZFeature(10);
        insert zf2;
        insert TestDataUtility.newZProductFeature(zf2.Id, td.lstZProducts[0].Id, 10);
        List<Account> lstAccount = [select Id, Subscriber_Number__c, PersonMailingPostalCode from Account where Id = :td.lstIndividualSubscribers[0].Id];
        System.assert(!lstAccount.isEmpty());
        td.lstSubscriptions[0].Cancellation_Method__c = 'SOMETHING';
        td.lstSubscriptions[0].Subscription_Status__c = Constants.SSTATUS_PENDING_CANX;
        td.lstSubscriptions[0].Cancellation_Date__c = Date.today().addDays(40);
        td.lstSubscriptions[0].Cancellation_Reason__c = 'Something wrong';
        update td.lstSubscriptions[0];
        Test.startTest();
            SubscriberPortal.Subscriber subWrapper = SubscriberPortal.identify(lstAccount[0].Subscriber_Number__c, lstAccount[0].PersonMailingPostalCode);
            System.assertEquals(2, subWrapper.entitlements.size());
            General__c g = new General__c(Name=SubscriberPortal.GENERAL_LEGACY_IDENTIFY_ENTITLEMENTS, Value_Boolean__c = true);
            insert g;
            subWrapper = SubscriberPortal.identify(lstAccount[0].Subscriber_Number__c, lstAccount[0].PersonMailingPostalCode);
            System.assertEquals(1, subWrapper.entitlements.size());
        Test.stopTest();
    }


    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 16/09/2016
    Version - 1.0
    Function - test unbundling identify method - active registrant / old/new
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private static testMethod void testIdentifyMethodActiveRegistrant(){
        TestDataUtility td = new TestDataUtility(1);
        td.loadSAMHTTPSettings();
        td.createZProductFeatures();
        td.createRegistrants();
        td.lstRegistrants[0].Replatform_Digital_Status__c = Constants.ZUORA_ACCOUNT_STATUS_FIELD_ACTIVE_VALUE;
        td.lstRegistrants[0].Product__c = td.lstZProducts[0].Id;
        update td.lstRegistrants;
        zqu__ZFeature__c zf2 = TestDataUtility.newZFeature(10);
        insert zf2;
        insert TestDataUtility.newZProductFeature(zf2.Id, td.lstZProducts[0].Id, 10);

        List<Account> lstAccount = [select Id, Subscriber_Number__c, PersonMailingPostalCode, Product__c from Account where Id = :td.lstRegistrants[0].Id];

        System.assert(!lstAccount.isEmpty());
        System.assertEquals(td.lstRegistrants[0].Product__c, lstAccount[0].Product__c);
        Test.startTest();
            SubscriberPortal.Subscriber subWrapper = SubscriberPortal.identify(lstAccount[0].Subscriber_Number__c, lstAccount[0].PersonMailingPostalCode);
            System.assertEquals(2, subWrapper.entitlements.size());
            General__c g = new General__c(Name=SubscriberPortal.GENERAL_LEGACY_IDENTIFY_ENTITLEMENTS, Value_Boolean__c = true);
            insert g;
            subWrapper = SubscriberPortal.identify(lstAccount[0].Subscriber_Number__c, lstAccount[0].PersonMailingPostalCode);
            System.assertEquals(0, subWrapper.entitlements.size());
        Test.stopTest();
    }
}
