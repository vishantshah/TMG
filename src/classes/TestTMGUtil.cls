/**
* @author Unknown
* @date Unknown
* @description Test class for TMGUtil class
* #############Change Log#############
* Modified by          Version  Change Date
* Wiktor Czykin         1.1     03/06/2015  //added coverage for new logging methods in TMGUtil
* Wiktor Czykin         1.2     27/10/2015  //removed PrpertiesUtil wrapper class tests
* Wiktor Czykin	        1.3	    15/12/2015	//added coverage for upsertRecordWithJson();
* Pawel Chrzanowski     1.4     23/05/2016  //added missing coverage for new methods
* Wiktor Czykin         1.5     29/09/2016  //added productPriceValidationNegativeTest()
* Manatas Grigaliunas   1.6     12/10/2016  //added new test methods testNewZuoraLogWebServiceRequestSerialized(),
*                                             testinsertZuoraWebServiceLogSuccess(), testinsertZuoraWebServiceLogError()
* Pawel Chrzanowski     1.7     18/01/2017  //added createRestrictedOfferUsageTest()
* Mantas Grigaliunas    1.8     20/01/2017  //fixed testinsertZuoraWebServiceLogSuccess(), testinsertZuoraWebServiceLogError()
* Mantas Grigaliunas    1.9     08/05/2017  //updated zuora web service loging related tests
**/
@isTest(SeeAllData=false)
private class TestTMGUtil {

	//test method for EmailUtil class
    static testMethod void emailUtilTest() {
        List<String> toAddresses = new List<String> {'anup.jadhav@telegraph.co.uk'};
        String replyToAddress = 'anup.jadhav@telegraph.co.uk';
		//use the new util class to send an email
		TMGUtil.EmailUtil emailUtil = new TMGUtil.EmailUtil(toAddresses);
		Messaging.SingleEmailMessage a = emailUtil.getEmailMessage();
		//send plain text body
		emailUtil.plainTextBody('Bilbo Bagginses has stolen our Precious!!')
				 .senderDisplayName('Gollum Gollum')
				 .replyTo(replyToAddress)
                 .documentAttach('01524000000T85aAAC')
				 .build().sendEmail();
		//send html body
		emailUtil.htmlBody('I want my Ring back Frodo Baggins.')
				 .senderDisplayName('Saurons Eye')
				 .subject('One Ring to Rule them all')
				 .useSignature(true)
				 .replyTo(replyToAddress)
				 .build().sendEmail();

		//send attachments
		List<Messaging.Emailfileattachment> fileAttachments = new List<Messaging.Emailfileattachment>();
		Messaging.Emailfileattachment fileAttachment = new Messaging.Emailfileattachment();
		Blob testBlob = Blob.valueOf('A thesis on the horticultural fondness of Hobbits, by Bilbo Baggins');
		fileAttachment.setBody(testBlob);
		fileAttachment.setContentType('text/html');
		fileAttachment.setFileName('hobbits.pdf');

		fileAttachments.add(fileAttachment);

		emailUtil.htmlBody('Urukhai, I am attaching a jpeg image of the hobbits you need to abduct from the Fellowship.<b> Do not fail me </b>')
				 .senderDisplayName('Saruman The White')
				 .subject('Urgent: Capture Hobbits')
				 .fileAttachments(fileAttachments)
				 .useSignature(true)
				 .replyTo(replyToAddress)
				 .build().sendEmail();

		// Setup test data // This code runs as the system user
		Profile p = [select id from profile where name='Standard User'];
		User u = new User(alias = 'testuser', email='testuser@telegraph.co.uk',
			emailencodingkey='UTF-8', lastname='Testing', languagelocalekey='en_US', localesidkey='en_US', profileid = p.Id, timezonesidkey='America/Los_Angeles', username='testuser@telegraph.co.uk');

		System.runas(u) {
			TMGUtil.EmailUtil emailUtil2 = new TMGUtil.EmailUtil(toAddresses);
			//System.assertEquals(emailUtil2.senderDisplayName, 'Testing');
			//System.assertEquals(emailUtil2.replyTo, 'standarduser@testorg.com');
			//send html body but without explicitly setting the replyTo and senderDisplayName
			emailUtil2.htmlBody('I want my Ring back Frodo Baggins.')
				 .subject('One Ring to Rule them all')
				 .useSignature(true)
				 .build().sendEmail();
		}

		try {
		//this will fail cause I ain't calling build() before sendMail()
		emailUtil.htmlBody('I am gonna take a stroll to Mordor and destroy the Ring.')
				 .senderDisplayName('Frodo Baggins')
				 .subject('To my Fellowship')
				 .replyTo(replyToAddress)
				 .sendEmail();
		} catch(Exception ex) {
			System.debug('Exception: '+ex);
		}

    }

    //test method for generate18CharacterId
    static testMethod void generate18CharacterTest() {
    	String testFifteenCharId = '0013000000K7WW2';
    	try{
    		String testEighteenCharId = TMGUtil.generate18CharacterID(testFifteenCharId);

    		System.assertEquals( '0013000000K7WW2AAN', testEighteenCharId);

    		//make this fail
    		testFifteenCharId = 'haX0r';
    		testEighteenCharId = TMGUtil.generate18CharacterID(testFifteenCharId);

    	} catch(Exception ex) {

    		System.assertEquals('There was a problem while converting your 15 char id to 18 char id.', ex.getMessage());
    	}
    }

    /***************************************************************************************
    Developer - Pawel Chrzanowski
    Date - 20/05/2016
    Function - test for retriving server name
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    static testMethod void RetrieveSalesforceServerNameTest(){
        ApexPages.currentPage().getHeaders().put('Referer', 'https://cs99.salesforce.com');
        TMGUtil tmgUtil = new TMGUtil();
        tmgUtil.RetrieveSalesforceServerName();
    }

    //test method for post code validator
    static testMethod void postCodeTest() {
    	System.assertEquals(true, TMGUtil.isValidPostCode('RG1 7JX'));
    	System.assertEquals(true, TMGUtil.isValidPostCode('SW1W 0DT'));
    	System.assertEquals(false, TMGUtil.isValidPostCode('impo ster'));
    }

    //Log a request and a simple response
    static testMethod void logWebRequestResponse_SimpleResponse( ){

    	String testParam1 = 'simpleTest';

    	ID logId = TMGUtil.logWebServiceRequest('Outbound', 'Endpoint', 'testmethod', new Map<String,Object>{ 'Simple' => testParam1 });

    	System.assert(LogId != null);

    	List<WebService_Log__c> logs = [Select Id, Method_Name__c, Parameters__c From WebService_Log__c Where Id = :logId];
    	System.assertEquals(logs.size(), 1);
    	System.assertEquals(logs[0].Method_Name__c, 'testmethod');
    	System.assertEquals(logs[0].Parameters__c, 'Simple=simpleTest');

    	TMGUtil.logWebServiceResponse(logId, 'someReturnValue');
    	logs = [Select Id, Response_Content__c From WebService_Log__c Where Id = :logId];
    	System.assertEquals(logs.size(), 1);
    	System.assertEquals(logs[0].Response_Content__c, 'someReturnValue');

    }

    /**	Log a request and a more complex response
    	Reponse show a success condition
    */
    static testMethod void logWebRequestResponse_AccountCreateAndTransactionUpdateResult( ){

    	String testParam1 = 'simpleTest';

    	ID logId = TMGUtil.logWebServiceRequest('Outbound', 'Endpoint', 'testmethod', new Map<String,Object>{ 'Simple' => testParam1 });

    	System.assert(LogId != null);

    	List<WebService_Log__c> logs = [Select Id, Method_Name__c, Parameters__c From WebService_Log__c Where Id = :logId];
    	System.assertEquals(logs.size(), 1);
    	System.assertEquals(logs[0].Method_Name__c, 'testmethod');
    	System.assertEquals(logs[0].Parameters__c, 'Simple=simpleTest');

    	SubscriptionsWebservices.CreateSubscriberAndTransactionResult res =
    		new SubscriptionsWebservices.CreateSubscriberAndTransactionResult('test TS Number');

    	TMGUtil.logWebServiceResponse(logId, res);
    	logs = [Select Id, Response_Content__c From WebService_Log__c Where Id = :logId];
    	System.assertEquals(logs.size(), 1);
    	//System.assertEquals(logs[0].Response_Content__c, 'SubscriptionsWebservices.CreateSubscriberAndTransactionResult:[TSNumber=test TS Number, wsError=null]');

    }

    /**	Log a request and a more complex response
    	The response has a couple of embedded classes in it - in this case an error
    */
    static testMethod void logWebRequestResponse_AccountCreateAndTransactionUpdateResult_WithErrors( ){

    	String testParam1 = 'simpleTest';

    	ID logId = TMGUtil.logWebServiceRequest('Outbound', 'Endpoint', 'testmethod', new Map<String,Object>{ 'Simple' => testParam1 });

    	System.assert(LogId != null);

    	List<WebService_Log__c> logs = [Select Id, Method_Name__c, Parameters__c From WebService_Log__c Where Id = :logId];
    	System.assertEquals(logs.size(), 1);
    	System.assertEquals(logs[0].Method_Name__c, 'testmethod');
    	System.assertEquals(logs[0].Parameters__c, 'Simple=simpleTest');

    	WebserviceUtil.WSError err = new WebserviceUtil.WSError( '2', 'An error message' );

    	SubscriptionsWebservices.CreateSubscriberAndTransactionResult res =
    		new SubscriptionsWebservices.CreateSubscriberAndTransactionResult(err);

    	TMGUtil.logWebServiceResponse(logId, res);
    	logs = [Select Id, Response_Content__c From WebService_Log__c Where Id = :logId];
    	System.assertEquals(logs.size(), 1);
    	//System.assertEquals(logs[0].Response_Content__c, 'SubscriptionsWebservices.CreateSubscriberAndTransactionResult:[TSNumber=null, wsError=WebserviceUtil.WSError:[errorCode=2, errorMessage=An error message]]');

    }

	/**	Check that if we don't have an Id when we log the response it still works
	*/
    static testMethod void logWebRequestResponse_ResponseOnly( ){

		ID logId = TMGUtil.logWebServiceResponse(null, 'someReturnValue');

    	List<WebService_Log__c> logs = [Select Id, Method_Name__c, Response_Content__c From WebService_Log__c Where Id = :logId];
    	System.assertEquals(logs.size(), 1);
    	System.assertEquals(logs[0].Response_Content__c, 'someReturnValue');
    	System.assertEquals(logs[0].Method_Name__c, null);

    }

    /**	Add a line of extra detail to the log
    */
    static testMethod void logWebRequestResponse_ExtraDetails( ){

    	String testParam1 = 'simpleTest';

    	ID logId = TMGUtil.logWebServiceRequest('Outbound', 'Endpoint', 'testmethod', new Map<String,Object>{ 'Simple' => testParam1 });

    	System.assert(LogId != null);

    	List<WebService_Log__c> logs = [Select Id, Method_Name__c, Parameters__c From WebService_Log__c Where Id = :logId];
    	System.assertEquals(logs.size(), 1);
    	System.assertEquals(logs[0].Method_Name__c, 'testmethod');
    	System.assertEquals(logs[0].Parameters__c, 'Simple=simpleTest');

    	TMGUtil.logWebServiceDetail(logId, 'Some extra info');
    	logs = [Select Id, Extra_Details__c From WebService_Log__c Where Id = :logId];
    	System.assertEquals(logs.size(), 1);
    	System.assertEquals(logs[0].Extra_Details__c.endsWith('Some extra info'), true);
    	System.Debug(logs[0].Extra_Details__c);

    	TMGUtil.logWebServiceResponse(logId, 'someReturnValue');
    	logs = [Select Id, Response_Content__c From WebService_Log__c Where Id = :logId];
    	System.assertEquals(logs.size(), 1);
    	System.assertEquals(logs[0].Response_Content__c, 'someReturnValue');

    }

    /**	Add two extra lines to the log
    	Lines are added in independant calls
    */
    static testMethod void logWebRequestResponse_ExtraDetails_TwoLines(){

    	String testParam1 = 'simpleTest';

    	ID logId = TMGUtil.logWebServiceRequest('Outbound', 'Endpoint', 'testmethod', new Map<String,Object>{ 'Simple' => testParam1 });

    	System.assert(LogId != null);

    	List<WebService_Log__c> logs = [Select Id, Method_Name__c, Parameters__c From WebService_Log__c Where Id = :logId];
    	System.assertEquals(logs.size(), 1);
    	System.assertEquals(logs[0].Method_Name__c, 'testmethod');
    	System.assertEquals(logs[0].Parameters__c, 'Simple=simpleTest');

    	TMGUtil.logWebServiceDetail(logId, 'Some extra info');
    	logs = [Select Id, Extra_Details__c From WebService_Log__c Where Id = :logId];
    	System.assertEquals(logs.size(), 1);
    	System.assertEquals(logs[0].Extra_Details__c.endsWith('Some extra info'), true);
    	System.Debug(logs[0].Extra_Details__c);

    	TMGUtil.logWebServiceDetail(logId, 'Another line of detail');
    	logs = [Select Id, Extra_Details__c From WebService_Log__c Where Id = :logId];
    	System.assertEquals(logs.size(), 1);
    	System.assertEquals(logs[0].Extra_Details__c.endsWith('Another line of detail'), true);
    	System.Debug(logs[0].Extra_Details__c);

    	TMGUtil.logWebServiceResponse(logId, 'someReturnValue');
    	logs = [Select Id, Response_Content__c From WebService_Log__c Where Id = :logId];
    	System.assertEquals(logs.size(), 1);
    	System.assertEquals(logs[0].Response_Content__c, 'someReturnValue');

    }

    static testMethod void testLogWebServiceAttachment(){
    	Id logWebService;
    	WebService_Log__c log;

    	Test.startTest();
    		logWebService = TMGUtil.logWebServiceAttachment('TEST', 'TEST', 'TEST', 'TEST', 'text/plain', Blob.valueOf('TEST'));
    		TMGUtil.attachToExistingLog(logWebService, 'TEST', 'text/plain', Blob.valueOf('ANOTHER LOG'));
    	Test.stopTest();

    	log = [SELECT Id, (SELECT Id, IsDeleted, ParentId, Name, IsPrivate,
    		ContentType, OwnerId, CreatedDate, CreatedById, LastModifiedDate,
    	 	LastModifiedById, SystemModstamp, Description FROM Attachments) FROM WebService_Log__c
    	 	WHERE Id = :logWebService];

    	System.assertEquals(log.Attachments.size(), 2);
    }

    /***************************************************************************************
    Developer - Pawel Chrzanowski
    Date - 20/05/2016
    Function - test for getting String value
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    static testMethod void getStringValTest(){
        Map<String, String> mapString = new Map<String, String>{'test' => 'test'};
        System.assertEquals('test=test\r\n', TMGUtil.getStringVal(mapString));
    }

    static testMethod void testParenthesizeList(){
    	Test.startTest();
    		System.assertEquals(TMGUtil.parenthesizeList(new List<String>{'AMIR', 'HAFEEZ', 'TELEGRAPH'}), '(\'AMIR\', \'HAFEEZ\', \'TELEGRAPH\')');
    	Test.stopTest();
    }

    /***************************************************************************************
    Developer - Pawel Chrzanowski
    Date - 20/05/2016
    Function - test for data validation
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    static testMethod void isDataValidTest(){
        System.assert(!TMGUtil.isDataValid(null));
        System.assert(TMGUtil.isDataValid('test'));
    }

    /***************************************************************************************
    Developer - Pawel Chrzanowski
    Date - 20/05/2016
    Function - test for record type map
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    static testMethod void recordTypeMapTest(){
        Map<String, RecordType> mapRT = TMGUtil.recordTypeMap;
    }

	static testMethod void CheckReturnTest(){
		system.assertequals(true,TMGUtil.checkSearchEntry(1));
		system.assertequals(false,TMGUtil.checkSearchEntry(0));
	}

	static testMethod void testDecimalRound_nonzero(){
    	system.assertEquals( 1.23, TMGUtil.decimalRound(1.225, 2));
    	system.assertEquals( 1.23, TMGUtil.decimalRound(1.229, 2));
    	system.assertEquals( 1.22, TMGUtil.decimalRound(1.224, 2));
    	system.assertEquals( 1.22, TMGUtil.decimalRound(1.220, 2));
    }

    static testMethod void testDecimalRound_zero(){
    	system.assertEquals( 0, TMGUtil.decimalRound(0, 2));
    }

    static testMethod void testCheckSOQLLimit(){
    	TMGUtil.checkSOQLLimit('Query Exception', 2);
    	TMGUtil.getNumberOfWeekdays(Date.today(), Date.today()+2);
    	TMGUtil.daysOff(Date.today(), Date.today()+2);
    	Id logId = TMGUtil.logWebServiceRequest('xyz', 'xyz', 'xyz', null, 'xyz');
    	TMGUtil.recordDisplayValues(10);
    	TMGUtil.updateWebServiceLog(logId, null, 'abc');
    }

    /***************************************************************************************
    Developer - Pawel Chrzanowski
    Date - 20/05/2016
    Function - test for heap size check
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    static testMethod void checkHeapSizeTest(){
        System.assert(TMGUtil.checkHeapSize('test'));
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 03/06/2015
    Version - 1.0
    Function - test for limitString method()
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private static testMethod void testLimitString(){
        Test.startTest();
            String myText ='';
            for(Integer i =0; i<=255; i++){
                myText+='a';
            }
            System.assertEquals(256, myText.length());
            myText = TMGUtil.limitString(myText, 255);
            System.assertEquals(255, myText.length());
            System.assertEquals(null, TMGUtil.limitString(null, 2));
        Test.stopTest();
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 03/06/2015
    Version - 1.0
    Function - test for logWebServiceRequestSerialized() method without Parent_Log__c
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private static testMethod void testLogWebServiceRequestSerializedWithoutParent(){
        Test.startTest();
            WebService_Log__c wl = TMGUtil.logWebServiceRequestSerialized(   Constants.DIRECTION_OUTBOUND,
                                                                            'http://telegraph.co.uk',
                                                                            'MN',
                                                                            new Map<String, String>{'test1'=>'test2'},
                                                                            'someDetails',
                                                                            'abc',
                                                                            null
                                                                        );
        Test.stopTest();
        List<WebService_Log__c> lstLog = [select       Id,
                                                        Parameters__c,
                                                        Request_Time__c,
                                                        Method_Name__c,
                                                        Event_Name__c,
                                                        Direction__c,
                                                        Extra_Details__c,
                                                        Endpoint__c,
                                                        Related_Record_Id__c,
                                                        Parent_Log__c
                                                    from WebService_Log__c];

        System.assertEquals(1, lstLog.size());
        WebService_Log__c wlog = lstLog[0];
        System.assertEquals('http://telegraph.co.uk', wlog.Endpoint__c);
        System.assertEquals(Constants.DIRECTION_OUTBOUND, wlog.Direction__c);
        System.assertEquals('MN', wlog.Method_Name__c);
        System.assertEquals('MN', wlog.Event_Name__c);
        System.assertEquals('someDetails', wlog.Extra_Details__c);
        System.assertEquals('abc', wlog.Related_Record_Id__c);
        System.assertEquals(null, wlog.Parent_Log__c);
        System.assertNotEquals(null, wlog.Parameters__c);
        try{
            Map<String, String> mapDeserialised = (Map<String, String>)JSON.deserialize(wlog.Parameters__c, Map<String, String>.class);
            System.assert(mapDeserialised.containsKey('test1'));
            System.assertEquals('test2', mapDeserialised.get('test1'));
        }catch(Exception e){
            System.assert(false, 'failed where shouldnt');
        }
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 03/06/2015
    Version - 1.0
    Function - test for logWebServiceRequestSerialized() method with Parent_Log__c
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private static testMethod void testLogWebServiceRequestSerializedWithParent(){
        Test.startTest();
            WebService_Log__c wlInitial = new WebService_Log__c();
            insert wlInitial;

            WebService_Log__c wl = TMGUtil.logWebServiceRequestSerialized(  Constants.DIRECTION_OUTBOUND,
                                                                            'http://telegraph.co.uk',
                                                                            'MN',
                                                                            new Map<String, String>{'test1'=>'test2'},
                                                                            'someDetails',
                                                                            'abc',
                                                                            wlInitial.Id
                                                                        );
        Test.stopTest();
        List<WebService_Log__c> lstLog = [select Id, Parent_Log__c from WebService_Log__c where Id =:wl.Id];
        System.assertEquals(1, lstLog.size());
        System.assertEquals(wlInitial.Id, lstLog[0].Parent_Log__c);
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 03/06/2015
    Version - 1.0
    Function - test for gogWebServiceRequestSerialized() overloaded method
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private static testMethod void testLogWebServiceRequestSerializedOverloaded(){
        Test.startTest();
            WebService_Log__c wl = TMGUtil.logWebServiceRequestSerialized(  Constants.DIRECTION_OUTBOUND,
                                                                            'http://telegraph.co.uk',
                                                                            'MN',
                                                                            new Map<String, String>{'test1'=>'test2'});
        Test.stopTest();
        List<WebService_Log__c> lstLog = [select       Id,
                                                        Parameters__c,
                                                        Request_Time__c,
                                                        Method_Name__c,
                                                        Event_Name__c,
                                                        Direction__c,
                                                        Extra_Details__c,
                                                        Endpoint__c,
                                                        Related_Record_Id__c,
                                                        Parent_Log__c
                                                    from WebService_Log__c];

        System.assertEquals(1, lstLog.size());
        WebService_Log__c wlog = lstLog[0];
        System.assertEquals('http://telegraph.co.uk', wlog.Endpoint__c);
        System.assertEquals(Constants.DIRECTION_OUTBOUND, wlog.Direction__c);
        System.assertEquals('MN', wlog.Method_Name__c);
        System.assertEquals('MN', wlog.Event_Name__c);
        System.assertEquals(null, wlog.Extra_Details__c);
        System.assertEquals(null, wlog.Related_Record_Id__c);
        System.assertEquals(null, wlog.Parent_Log__c);
        System.assertNotEquals(null, wlog.Parameters__c);
        try{
            Map<String, String> mapDeserialised = (Map<String, String>)JSON.deserialize(wlog.Parameters__c, Map<String, String>.class);
            System.assert(mapDeserialised.containsKey('test1'));
            System.assertEquals('test2', mapDeserialised.get('test1'));
        }catch(Exception e){
            System.assert(false, 'failed where shouldnt');
        }
    }

    /***************************************************************************************
    Developer - Pawel Chrzanowski
    Date - 23/05/2016
    Function - test for logWebServiceRequestSerialized() method
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    static testMethod void testLogWebServiceRequestSerializedOverloaded2(){
        WebService_Log__c log = new WebService_Log__c();
        System.assert(String.isNotBlank(TMGUtil.logWebServiceRequestSerialized(log)));
    }

    /***************************************************************************************
    Developer - Pawel Chrzanowski
    Date - 23/05/2016
    Function - test for populateResponseOnWebServiceRequestSerialized() method
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    static testMethod void populateResponseOnWebServiceRequestSerializedTest(){
        WebService_Log__c log = new WebService_Log__c();
        System.assertEquals(Datetime.now(), TMGUtil.populateResponseOnWebServiceRequestSerialized(log, '201').Response_Time__c);
    }

    /***************************************************************************************
    Developer - Pawel Chrzanowski
    Date - 23/05/2016
    Function - test for populateExtraDetailsOnWebServiceRequestSerialized() method
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    static testMethod void populateExtraDetailsOnWebServiceRequestSerializedTest(){
        WebService_Log__c log = new WebService_Log__c();
        System.assertEquals('201', TMGUtil.populateExtraDetailsOnWebServiceRequestSerialized(log, '201').Extra_Details__c);
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 03/06/2015
    Version - 1.0
    Function - test for logIndividualLogsForParent() method
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private static testMethod void testLogIndividualLogsForParent(){
        TestDataUtility td = new TestDataUtility(2);
        td.createIndividualSubscribers();

        WebService_Log__c wl = TMGUtil.logWebServiceRequestSerialized(  Constants.DIRECTION_OUTBOUND,
                                                                            'http://telegraph.co.uk',
                                                                            'MN',
                                                                            new Map<String, String>{'test1'=>'test2'});
        Test.startTest();
            Map<Id, Account> mapIdToObject = new Map<Id, Account>([select Id, Subscriber_Number__c from Account where Id in :td.lstIndividualSubscribers]);
            Map<Id, String> mapRecordIdToTSNumber = new Map<Id, String>();
            for(Account acc : mapIdToObject.values()){
                mapRecordIdToTSNumber.put(acc.Id, acc.Subscriber_Number__c);
            }
            TMGUtil.logIndividualLogsForParent(wl, mapIdToObject, mapRecordIdToTSNumber);
        Test.stopTest();
        List<WebService_Log__c> lstLogs = [select       Id,
                                                        Parameters__c,
                                                        Request_Time__c,
                                                        Method_Name__c,
                                                        Event_Name__c,
                                                        Direction__c,
                                                        Extra_Details__c,
                                                        Endpoint__c,
                                                        Related_Record_Id__c,
                                                        Parent_Log__c
                                                    from WebService_Log__c
                                                    where Parent_Log__c =: wl.Id];
        System.assertEquals(td.iCounter, lstLogs.size());
        for(WebService_Log__c wlog : lstLogs){
            System.assertEquals(wl.Event_Name__c+Constants.LOG_CHILD_RECORD_SUFFIX, wlog.Event_Name__c);
            System.assertEquals(wl.Direction__c, wlog.Direction__c);
            System.assertNotEquals(null, wlog.Request_Time__c);
            System.assertNotEquals(null, wlog.Parameters__c);
        }
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 03/06/2015
    Version - 1.0
    Function - test for logIndividualLogsForParent() overloaded method
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private static testMethod void testLogIndividualLogsForParentOverloaded(){
        TestDataUtility td = new TestDataUtility(2);
        td.createIndividualSubscribers();

        WebService_Log__c wl = TMGUtil.logWebServiceRequestSerialized(  Constants.DIRECTION_OUTBOUND,
                                                                            'http://telegraph.co.uk',
                                                                            'MN',
                                                                            new Map<String, String>{'test1'=>'test2'});
        Test.startTest();
            Map<Id, Account> mapIdToObject = new Map<Id, Account>([select Id, Subscriber_Number__c from Account where Id in :td.lstIndividualSubscribers]);
            Map<Id, String> mapRecordIdToTSNumber = new Map<Id, String>();
            for(Account acc : mapIdToObject.values()){
                mapRecordIdToTSNumber.put(acc.Id, acc.Subscriber_Number__c);
            }
            TMGUtil.logIndividualLogsForParent(wl.Id, mapIdToObject, mapRecordIdToTSNumber);
        Test.stopTest();
        List<WebService_Log__c> lstLogs = [select       Id,
                                                        Parameters__c,
                                                        Request_Time__c,
                                                        Method_Name__c,
                                                        Event_Name__c,
                                                        Direction__c,
                                                        Extra_Details__c,
                                                        Endpoint__c,
                                                        Related_Record_Id__c,
                                                        Parent_Log__c
                                                    from WebService_Log__c
                                                    where Parent_Log__c =: wl.Id];
        System.assertEquals(td.iCounter, lstLogs.size());
        for(WebService_Log__c wlog : lstLogs){
            System.assertEquals(wl.Event_Name__c+Constants.LOG_CHILD_RECORD_SUFFIX, wlog.Event_Name__c);
            System.assertEquals(wl.Direction__c, wlog.Direction__c);
            System.assertNotEquals(null, wlog.Request_Time__c);
            System.assertNotEquals(null, wlog.Parameters__c);
        }
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 03/06/2015
    Version - 1.0
    Function - test for logIndividualLogsForParent() method - negative
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private static testMethod void testLogIndividualLogsForParentNegative(){
        WebService_Log__c wl;
        Test.startTest();
            TMGUtil.logIndividualLogsForParent(wl, null, null);
        Test.stopTest();
        List<WebService_Log__c> lstLog = [select Id, Parent_Log__c from WebService_Log__c];
        System.assert(lstLog.isEmpty());
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 03/06/2015
    Version - 1.0
    Function - test for logIndividualResponsesForIndividualRequests() method
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private static testMethod void testLogIndividualResponsesForIndividualRequests(){
        TestDataUtility td = new TestDataUtility(2);
        td.createIndividualSubscribers();

        WebService_Log__c wl = TMGUtil.logWebServiceRequestSerialized(  Constants.DIRECTION_OUTBOUND,
                                                                            'http://telegraph.co.uk',
                                                                            'MN',
                                                                            new Map<String, String>{'test1'=>'test2'});

        Map<Id, Account> mapIdToObject = new Map<Id, Account>([select Id, Subscriber_Number__c from Account where Id in :td.lstIndividualSubscribers]);
        Map<Id, String> mapRecordIdToTSNumber = new Map<Id, String>();
        for(Account acc : mapIdToObject.values()){
            mapRecordIdToTSNumber.put(acc.Id, acc.Subscriber_Number__c);
        }
        TMGUtil.logIndividualLogsForParent(wl, mapIdToObject, mapRecordIdToTSNumber);

        Test.startTest();
            Boolean b = TMGUtil.logIndividualResponsesForIndividualRequests(mapIdToObject, mapRecordIdToTSNumber, 'response', null);
            System.assert(b);
        Test.stopTest();
        Map<Id, WebService_Log__c> mapChildRequestLogs = new Map<Id, WebService_Log__c>([select Id from WebService_Log__c where Direction__c = :Constants.DIRECTION_OUTBOUND and Parent_Log__c =: wl.Id]);
        List<WebService_Log__c> lstLog = [select Id, Related_Record_Id__c, TS_Number__c, Parent_Log__c from WebService_Log__c where Direction__c = :Constants.DIRECTION_INBOUND];
        System.assert(!lstLog.isEmpty());
        System.assertEquals(2, lstLog.size());
        for(WebService_Log__c logCheck : lstLog){
            System.assertNotEquals(null, logCheck.Parent_Log__c);
            System.assert(mapChildRequestLogs.containsKey(logCheck.Parent_Log__c));
            System.assert(mapIdToObject.containsKey(logCheck.Related_Record_Id__c));
            System.assertEquals(mapIdToObject.get(logCheck.Related_Record_Id__c).Subscriber_Number__c, logCheck.TS_Number__c);
        }

    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 03/06/2015
    Version - 1.0
    Function - test for logIndividualResponsesForIndividualRequests() method - fallback logging
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private static testMethod void testLogIndividualResponsesForIndividualRequestsFallback(){
        TestDataUtility td = new TestDataUtility(2);
        td.createIndividualSubscribers();

        WebService_Log__c wl = TMGUtil.logWebServiceRequestSerialized(  Constants.DIRECTION_OUTBOUND,
                                                                            'http://telegraph.co.uk',
                                                                            'MN',
                                                                            new Map<String, String>{'test1'=>'test2'});

        Map<Id, Account> mapIdToObject = new Map<Id, Account>([select Id, Subscriber_Number__c from Account where Id in :td.lstIndividualSubscribers]);
        Map<Id, String> mapRecordIdToTSNumber = new Map<Id, String>();
        for(Account acc : mapIdToObject.values()){
            mapRecordIdToTSNumber.put(acc.Id, acc.Subscriber_Number__c);
        }
        Test.startTest();
            Boolean b = TMGUtil.logIndividualResponsesForIndividualRequests(mapIdToObject, mapRecordIdToTSNumber, 'response', wl.Id);
            System.assert(b);
        Test.stopTest();
        List<WebService_Log__c> lstLog = [select Id, Related_Record_Id__c, TS_Number__c, Parent_Log__c from WebService_Log__c where Direction__c = :Constants.DIRECTION_INBOUND];
        System.assert(!lstLog.isEmpty());
        System.assertEquals(2, lstLog.size());
        for(WebService_Log__c logCheck : lstLog){
            System.assertNotEquals(null, logCheck.Parent_Log__c);
            System.assertEquals(wl.Id, logCheck.Parent_Log__c);
            System.assert(mapIdToObject.containsKey(logCheck.Related_Record_Id__c));
            System.assertEquals(mapIdToObject.get(logCheck.Related_Record_Id__c).Subscriber_Number__c, logCheck.TS_Number__c);
        }
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 03/06/2015
    Version - 1.0
    Function - test for logIndividualResponsesForIndividualRequests() method - negative
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private static testMethod void testLogIndividualResponsesForIndividualRequestsNegative(){
        Test.startTest();
            TMGUtil.logIndividualResponsesForIndividualRequests(null, null, null, null);
        Test.stopTest();
        List<WebService_Log__c> lstLog = [select Id, Parent_Log__c from WebService_Log__c];
        System.assert(lstLog.isEmpty());
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 15/12/2015
    Version - 1.0
    Function - test for upsertRecordWithJson() method
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private static testMethod void testUpsertRecordWithJson(){
    	WebService_Log__c wl =  TMGUtil.newLogWebServiceRequestSerialized(	Constants.DIRECTION_OUTBOUND,
																			null,
																			'methodname',
																			null,
																			null,
																			null,
																			null);
    	Test.startTest();
    		TMGUtil.upsertRecordWithJson(wl, new List<String>{'test'});
    	Test.stopTest();
    	System.assert(wl.Id != null);
    	List<WebService_Log__c> lstLog = [select Id from WebService_Log__c];
    	System.assertEquals(1, lstLog.size());
    }

    /***************************************************************************************
    Developer - Pawel Chrzanowski
    Date - 23/05/2016
    Function - test for relateWebserviceLogToObject() method
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    static testMethod void relateWebserviceLogToObjectTest(){
        WebService_Log__c log = new WebService_Log__c();
        insert log;
        List<WebService_Log__c> lstLogs = new List<WebService_Log__c>{new WebService_Log__c()};
        TMGUtil.relateWebserviceLogToObject('Related_Record_Id__c', lstLogs, log.Id);
        System.assertEquals(log.Id, lstLogs[0].get('Related_Record_Id__c'));
    }

    /***************************************************************************************
    Developer - Pawel Chrzanowski
    Date - 23/05/2016
    Function - test for generateLogRecordsFromWebserviceLog() method
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    static testMethod void generateLogRecordsFromWebserviceLogTest(){
        System.assertEquals(null, TMGUtil.generateLogRecordsFromWebserviceLog(null));
        List<TMGUtil.WebserviceLog> lstWSL = new List<TMGUtil.WebserviceLog>{new TMGUtil.WebserviceLog('GET', new Map<String, Object>())};
        lstWSL[0].response = '200';
        lstWSL[0].ErrorMessage = 'error';
        Boolean error = lstWSL[0].error;
        System.assertEquals('GET', TMGUtil.generateLogRecordsFromWebserviceLog(lstWSL)[0].Method_Name__c);
    }

    /***************************************************************************************
    Developer - Pawel Chrzanowski
    Date - 23/05/2016
    Function - test for validateCheque() method
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    static testMethod void validateChequeTest(){
        System.assertEquals('Please enter  a valid Account Number and a valid Sort Code', TMGUtil.validateCheque(null, null));
        System.assertEquals('Please enter  a valid Account Number, a valid Sort Code', TMGUtil.validateCheque('123', '123'));
    }

    /***************************************************************************************
    Developer - Pawel Chrzanowski
    Date - 20/05/2016
    Function - test for create cheque batch
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
   static testMethod void createChequeBatchTest(){
        System.assert(String.isNotBlank(String.valueOf(TMGUtil.createChequeBatch())));
   }

    /***************************************************************************************
    Developer - Pawel Chrzanowski
    Date - 23/05/2016
    Function - test for processChequePayment() method
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    static testMethod void processChequePaymentTest(){
        Cheque__c cheque = new Cheque__c();
        cheque.Account_Number__c = '123';
        cheque.Sort_Code__c = '123';

        TestDataUtility tdu = new TestDataUtility(1);
        tdu.createSubscriptions();

        try{
            TMGUtil.processChequePayment(tdu.lstSubscriptions[0].Id, null, null, 52, cheque, 10.00);
        }catch(Exception e){
            System.assertEquals('An error occurred processing the cheque. ' + Label.Offline_Acquisition_Cheque_batch_selection_error, e.getMessage());
        }

        try{
            TMGUtil.processChequePayment(tdu.lstSubscriptions[0].Id, 'cheque', true, 52, cheque, 10.00);
        }catch(Exception e){
            System.assertEquals('An error occurred processing the cheque. ' + 'Please enter  a valid Account Number, a valid Sort Code', e.getMessage());
        }

        cheque.Account_Number__c = '12345678';
        cheque.Sort_Code__c = '123456';
        Cheque_Batch__c batch = new Cheque_Batch__c();
        insert batch;
        String chequeBatchName = [select Name from Cheque_Batch__c].Name;
        TMGUtil.processChequePayment(tdu.lstSubscriptions[0].Id, chequeBatchName, true, 52, cheque, 10.00);
        TMGUtil.processChequePayment(tdu.lstSubscriptions[0].Id, chequeBatchName, false, 52, cheque, 10.00);

        List<Cheque__c> lstCheque = [select Cheque_Amount__c from Cheque__c];
        System.assertEquals(1, lstCheque.size());
        System.assertEquals(520.00, lstCheque[0].Cheque_Amount__c);
    }

    /***************************************************************************************
    Developer - Pawel Chrzanowski
    Date - 23/05/2016
    Function - test for multiPickListSelectionCheck() method
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    static testMethod void multiPickListSelectionCheckTest(){
        System.assert(!TMGUtil.multiPickListSelectionCheck(null, null));
        System.assert(TMGUtil.multiPickListSelectionCheck('selectedValues', 'selected'));
    }

    /***************************************************************************************
    Developer - Pawel Chrzanowski
    Date - 23/05/2016
    Function - test for getProductIdFromCatalog() method
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    static testMethod void getProductIdFromCatalogTest(){
        TestDataUtility tdu = new TestDataUtility(1);
        tdu.createZProduct();
        tdu.lstZproducts[0].Name = 'product';
        update tdu.lstZproducts[0];

        System.assertEquals(tdu.lstZproducts[0].Id, TMGUtil.getProductIdFromCatalog('product'));
    }

    /***************************************************************************************
    Developer - Pawel Chrzanowski
    Date - 23/05/2016
    Function - test for productIsPrint() method
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    static testMethod void productIsPrintTest(){
        TestDataUtility tdu = new TestDataUtility(1);
        tdu.createZProduct();
        tdu.lstZproducts[0].Name = 'product';
        tdu.lstZproducts[0].Print_Product__c = true;
        update tdu.lstZproducts[0];

        System.assert(TMGUtil.productIsPrint(tdu.lstZproducts[0].Id));
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 29/09/2016
    Function - test for validateAgainstProductPrice() method
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    static testMethod void productPriceValidationNegativeTest(){
        TestDataUtility.enableProductPriceValidationSetting();
        Test.startTest();
            try{
                TMGUtil.validateAgainstProductPrice(null, null, null, 'whatever');
                System.assert(false, 'exception not thrown where should be');
            }catch(Exception e){}
        Test.stopTest();
    }

    /*************************************************************************************** 
    Developer - Mantas Grigaliunas
    Date - 12/10/2016
    Function - test for newZuoraLogWebServiceRequestSerialized() method
    #############Change Log#############
    Modified by         Change Date
    Mantas Grigaliunas  08/05/2017  //updated test after method change
    ****************************************************************************************/
    @isTest
    private static void testNewZuoraWebServiceLog(){
        final String TEST_PARAM = 'Test Parameter';
        final String TEST_METHOD = 'Test Method';
        Map<String, String> testParameters = new Map<String, String>{ TEST_PARAM => TEST_PARAM };

        Test.startTest();
        String log = TMGUtil.newZuoraWebServiceLog(TEST_METHOD, TEST_METHOD, testParameters);
        WebService_Log__c testLog = (WebService_Log__c)JSON.deserialize(log, WebService_Log__c.class);
        Test.stopTest();

        System.assert(testLog.Parameters__c.contains(TEST_PARAM), testLog.Parameters__c);
        System.assertEquals(TEST_METHOD, testLog.Method_Name__c);
    }

    /*************************************************************************************** 
    Developer - Mantas Grigaliunas
    Date - 12/10/2016
    Function - test for testinsertZuoraWebServiceLog() method with successfull response
    #############Change Log#############
    Modified by         Change Date
    Mantas Grigaliunas  20/01/2017  //Updated SOQL query to use log id
    Mantas Grigaliunas  08/05/2017  //updated test after method change
    ****************************************************************************************/
    @isTest(SeeAllData=true)
    private static void testInsertZuoraWebServiceLog(){

        final String TEST_PARAM = 'Test Parameter';
        final String TEST_METHOD = 'testinsertZuoraWebServiceLogError';
        Map<String, String> testParameters = new Map<String, String>{ TEST_PARAM => TEST_PARAM };

        Test.startTest();
        String log = TMGUtil.newZuoraWebServiceLog(TEST_METHOD, TEST_METHOD, testParameters);
        TMGUtil.insertZuoraWebServiceLog(log, ZuoraUtilities.analyzeSaveResult(Z_TestFactory.createZuoraTestSaveResultSuccess()));
        Test.stopTest();

        List<WebService_Log__c> lstLog = [ SELECT Id, Response_Content__c, Method_Name__c, Event_Name__c FROM WebService_Log__c WHERE Event_Name__c = :TEST_METHOD ];
        System.assertEquals(1, lstLog.size());
    }
	
    /***************************************************************************************
    Developer - Pawel Chrzanowski
    Date - 18/01/2017
    Test for createRestrictedOfferUsage method
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    @isTest static void createRestrictedOfferUsageTest(){
        TestDataUtility tdu = new TestDataUtility(5);
        tdu.CreateCoreApiAllOfferCodesEndPointSetting();
        tdu.CreateCoreApiEndPointSettings();
        tdu.createRegistrants();
        tdu.createZProducts();
        tdu.checkZuoraSubscriptionDependancies();

        zqu__Quote__c quote = new zqu__Quote__c(zqu__Account__c = tdu.lstRegistrants[0].Id, zqu__Status__c=Constants.QUOTE_STATUS_NEW_VALUE, zqu__Subscription_Term_Type__c='Termed', zqu__RenewalSetting__c='RENEW_WITH_SPECIFIC_TERM', zqu__ValidUntil__c = Date.today());
        insert quote;

        zqu__QuoteAmendment__c quoteA = new zqu__QuoteAmendment__c(zqu__Quote__c = quote.Id, zqu__Type__c = 'NewProduct');
        insert quoteA;

        zqu__ProductRatePlan__c productRP = [SELECT Id from zqu__ProductRatePlan__c WHERE Name = 'Monthly Open Offer Plan' LIMIT 1];
        zqu__QuoteRatePlan__c quoteRP = new zqu__QuoteRatePlan__c(zqu__Quote__c = quote.Id, zqu__QuoteProductName__c = tdu.lstZproducts[0].Name, zqu__QuoteAmendment__c = quoteA.Id, zqu__ProductRatePlan__c = productRP.Id);
        insert quoteRP;

        List<Zuora__Subscription__c> lstSubs = new List<Zuora__Subscription__c>();
        lstSubs.add(new Zuora__Subscription__c(Zuora__Account__c=tdu.lstRegistrants[0].Id, PromoCode__c='Test TabletUKMonthly', Name='test1', Master_Quote__c=quote.Id, Zuora__External_Id__c='00001', Zuora__Version__c=1, Zuora__Status__c = Constants.SUBSCRIPTION_ACTIVE_STATUS, Zuora__CustomerAccount__c=tdu.lstBillingAccount[0].Id, Zuora__InvoiceOwner__c=tdu.lstBillingAccount[0].Id));
        lstSubs.add(new Zuora__Subscription__c(Zuora__Account__c=tdu.lstRegistrants[1].Id, PromoCode__c='Test TabletUKAnnual', Name='test2', Master_Quote__c=quote.Id, Zuora__External_Id__c='00002', Zuora__Version__c=1, Zuora__Status__c = Constants.SUBSCRIPTION_ACTIVE_STATUS, Zuora__CustomerAccount__c=tdu.lstBillingAccount[1].Id, Zuora__InvoiceOwner__c=tdu.lstBillingAccount[1].Id));
        lstSubs.add(new Zuora__Subscription__c(Zuora__Account__c=tdu.lstRegistrants[2].Id, PromoCode__c='Test TabletInternationaMonthly', Name='test3', Master_Quote__c=quote.Id, Zuora__External_Id__c='00003', Zuora__Version__c=1, Zuora__Status__c = Constants.SUBSCRIPTION_ACTIVE_STATUS, Zuora__CustomerAccount__c=tdu.lstBillingAccount[2].Id, Zuora__InvoiceOwner__c=tdu.lstBillingAccount[2].Id));
        lstSubs.add(new Zuora__Subscription__c(Zuora__Account__c=tdu.lstRegistrants[3].Id, PromoCode__c='Test TabletInternationaMonthly', Name='test4', Master_Quote__c=quote.Id, Zuora__External_Id__c='00004', Zuora__Version__c=1, Zuora__Status__c = Constants.SUBSCRIPTION_ACTIVE_STATUS, Zuora__CustomerAccount__c=tdu.lstBillingAccount[3].Id, Zuora__InvoiceOwner__c=tdu.lstBillingAccount[3].Id));
        lstSubs.add(new Zuora__Subscription__c(Zuora__Account__c=tdu.lstRegistrants[4].Id, PromoCode__c='Test websiteIntAnnualObj', Name='test5', Master_Quote__c=quote.Id, Zuora__External_Id__c='00005', Zuora__Version__c=1, Zuora__Status__c = Constants.SUBSCRIPTION_ACTIVE_STATUS, Zuora__CustomerAccount__c=tdu.lstBillingAccount[4].Id, Zuora__InvoiceOwner__c=tdu.lstBillingAccount[4].Id));

        Test.setMock(HttpCalloutMock.class, new GetAllOfferCodesHTTPResponceMock());
        Test.startTest();
            insert lstSubs;
        Test.stopTest();

        List<Restricted_Offer_Usage__c> lstROU = [SELECT Id from Restricted_Offer_Usage__c];
        System.assertEquals(4, lstROU.size());
    }
}