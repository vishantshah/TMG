@isTest
private class CustomValidatorTest
{

	static final String RECORD_TYPE_NAME = 'Reader Relations';

	@testSetup
	static void createTestData(){
		TestDataUtility tdu = new TestDataUtility(10);
		tdu.createCustomValidationRules();

		List<Custom_Validation__c> customvalidations = [SELECT Id FROM Custom_Validation__c];
		System.assertNotEquals(0, customvalidations.size());
	}

	@isTest
	static void caseCreationSuccess(){
		Id caseRecordTypeId = RecordTypeUtility.getRecordTypeId(Case.SObjectType, RECORD_TYPE_NAME, Case.class.getName());
		Case c = new Case();
		c.RecordTypeId = caseRecordTypeId;
		c.Origin = 'Email';
		c.Priority = 'Normal';
		c.Reason = 'Puzzles & Games';
		c.Type_Of_Issue__c = 'Website';
		c.Digital_Details__c = 'Issue';
		c.Digital_Details_2__c = 'Performance';
		c.Digital_Details_3__c = 'No Loading';

		Test.startTest();
		Insert c;
		Test.stopTest();
	}

	@isTest
	static void caseCreationFailDetails3(){
		Id caseRecordTypeId = RecordTypeUtility.getRecordTypeId(Case.SObjectType, RECORD_TYPE_NAME, Case.class.getName());
		Case c = new Case();
		c.RecordTypeId = caseRecordTypeId;
		c.Origin = 'Email';
		c.Priority = 'Normal';
		c.Reason = 'Puzzles & Games';
		c.Type_Of_Issue__c = 'Website';
		c.Digital_Details__c = 'Issue';
		c.Digital_Details_2__c = 'Performance';
		c.Digital_Details_3__c = 'Leaderboard';

		Test.startTest();
		try{
			Insert c;
		} catch (Exception e){
			System.assertEquals(true, e.getMessage().contains(' Allowed values for Case Detail 4 are : {No loading}'));
		}
		Test.stopTest();
	}

	@isTest
	static void caseCreationFailDetails2(){
		Id caseRecordTypeId = RecordTypeUtility.getRecordTypeId(Case.SObjectType, RECORD_TYPE_NAME, Case.class.getName());
		Case c = new Case();
		c.RecordTypeId = caseRecordTypeId;
		c.Origin = 'Email';
		c.Priority = 'Normal';
		c.Reason = 'Puzzles & Games';
		c.Type_Of_Issue__c = 'Website';
		c.Digital_Details__c = 'Issue';
		c.Digital_Details_2__c = 'Printing';

		Test.startTest();
		try{
			Insert c;
		} catch (Exception e){
			System.assertEquals(true, e.getMessage().contains('Allowed values for Case Detail 3 are : {Performance}'));
		}
		Test.stopTest();
	}

	@isTest
	static void caseCreationFailDetails1(){
		Id caseRecordTypeId = RecordTypeUtility.getRecordTypeId(Case.SObjectType, RECORD_TYPE_NAME, Case.class.getName());
		Case c = new Case();
		c.RecordTypeId = caseRecordTypeId;
		c.Origin = 'Email';
		c.Priority = 'Normal';
		c.Reason = 'Puzzles & Games';
		c.Type_Of_Issue__c = 'Website';
		c.Digital_Details__c = 'Feedback';

		Test.startTest();
		try{
			Insert c;
		} catch (Exception e){
			System.assertEquals(true, e.getMessage().contains('Allowed values for Case Detail 2 are : {Issue}'));
		}
		Test.stopTest();
	}

	@isTest
	static void caseCreationFailDetails(){
		Id caseRecordTypeId = RecordTypeUtility.getRecordTypeId(Case.SObjectType, RECORD_TYPE_NAME, Case.class.getName());
		Case c = new Case();
		c.RecordTypeId = caseRecordTypeId;
		c.Origin = 'Email';
		c.Priority = 'Normal';
		c.Reason = 'Puzzles & Games';
		c.Type_Of_Issue__c = 'In-paper';

		Test.startTest();
		try{
			Insert c;
		} catch (Exception e){
			System.assertEquals(true, e.getMessage().contains('Allowed values for Case Detail 1 are : {Website}'));
		}
		Test.stopTest();
	}

	@isTest
	static void caseCreationCaseReason(){
		Id caseRecordTypeId = RecordTypeUtility.getRecordTypeId(Case.SObjectType, RECORD_TYPE_NAME, Case.class.getName());
		Case c = new Case();
		c.RecordTypeId = caseRecordTypeId;
		c.Origin = 'Email';
		c.Priority = 'Normal';
		c.Reason = 'Rewards';

		Test.startTest();
		try{
			Insert c;
		} catch (Exception e){
			System.assertEquals(true, e.getMessage().contains('Allowed values for Case Reason are : {Puzzles & Games}'));
		}
		Test.stopTest();
	}
}