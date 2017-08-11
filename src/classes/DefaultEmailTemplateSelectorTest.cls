/**
* @author Wiktor Czykin
* @date 23/03/2016
* @description test class for DefaultEmailTemplateSelector
* #############Change Log#############
* Modified by     Version     Change Date
**/
@isTest
private class DefaultEmailTemplateSelectorTest {
	
	public static final String FOLDERTYPE_EMAILTEMPLATE = 'Email';

	/*************************************************************************************** 
	Developer - Wiktor Czykin
	Date - 23/03/2016
	Version - 1.0
	Function - test positive teplate identification based on custom setting name
	#############Change Log#############
	Modified by     Version     Change Date
	****************************************************************************************/
	private static testMethod void testTemplateFetchingPositiveScenario(){
		TestDataUtility td = new TestDataUtility(1);
		td.loadGeneral();
		General__c template = General__c.getInstance(DefaultEmailTemplateSelector.TEMPLATE_KEY);
		System.assertNotEquals(null, template);
		template.Value__c = 'somethingelse';
		update template;

		List<Folder> lstEmailFolder = [select Id from Folder where Type = :FOLDERTYPE_EMAILTEMPLATE limit 1];
		System.assert(!lstEmailFolder.isEmpty());

		EmailTemplate et = TestDataUtility.newTextEmailTemplate(lstEmailFolder[0].Id, template.Value__c);
		insert et;

		Test.startTest();
			DefaultEmailTemplateSelector dets = new DefaultEmailTemplateSelector();
			System.assertEquals(et.Id, dets.getDefaultEmailTemplateId(null));
		Test.stopTest();

	}

	/*************************************************************************************** 
	Developer - Wiktor Czykin
	Date - 23/03/2016
	Version - 1.0
	Function - test no template returned where there is no template specified in settings
	#############Change Log#############
	Modified by     Version     Change Date
	****************************************************************************************/
	private static testMethod void testTemplateFetchingNegativeScenarioNoSetting(){
		Test.startTest();
			DefaultEmailTemplateSelector dets = new DefaultEmailTemplateSelector();
			System.assertEquals(null, dets.getDefaultEmailTemplateId(null));
		Test.stopTest();
	}

	/*************************************************************************************** 
	Developer - Wiktor Czykin
	Date - 23/03/2016
	Version - 1.0
	Function - test no template returned where there is no template found based on settings
	#############Change Log#############
	Modified by     Version     Change Date
	****************************************************************************************/
	private static testMethod void testTemplateFetchingNegativeScenarioNoTemplate(){
		TestDataUtility td = new TestDataUtility(1);
		td.loadGeneral();
		General__c template = General__c.getInstance(DefaultEmailTemplateSelector.TEMPLATE_KEY);
		System.assertNotEquals(null, template);
		System.assert(String.isNotBlank(template.Value__c));
		List<EmailTemplate> lstToDelete = [select Id from EmailTemplate where DeveloperName = :template.Value__c];
		delete lstToDelete;

		List<Folder> lstEmailFolder = [select Id from Folder where Type = :FOLDERTYPE_EMAILTEMPLATE limit 1];
		System.assert(!lstEmailFolder.isEmpty());
		EmailTemplate et = TestDataUtility.newTextEmailTemplate(lstEmailFolder[0].Id, null);
		insert et;

		Test.startTest();
			DefaultEmailTemplateSelector dets = new DefaultEmailTemplateSelector();
			System.assertEquals(null, dets.getDefaultEmailTemplateId(null));
		Test.stopTest();
	}
}