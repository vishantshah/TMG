/**
* @author Pawan Tokas (Tquila)
* @date Unknown
* @description Test class for CaseSendEmailController
#############Change Log#############
Modified by     Version     Change Date
**/
@isTest
private class CaseSendEmailControllerTest {


	static testMethod void testEmailValidator(){
	    String email ='abc.com';
		System.assertEquals(CaseSendEmailController.checkEmail(email), false);
		email ='ptokas@tquila.com';
		System.assertEquals(CaseSendEmailController.checkEmail(email), true);
		email='';
		System.assertEquals(CaseSendEmailController.checkEmail(email), false);
		email=null;
		System.assertEquals(CaseSendEmailController.checkEmail(email), false);
	}
	
	static testMethod void  testTemplatesFromFolder() {
	   	List<Folder> lstFolder = [Select Id,Name From Folder Where AccessType = 'Public' and type='Email' limit 1 ];
  	   
   		EmailTemplate validEmailTemplate = new EmailTemplate();
		validEmailTemplate.isActive = true;
		validEmailTemplate.Name = 'atexttemplatetquila21';
		validEmailTemplate.DeveloperName = 'testingtextemailtemplate';
		validEmailTemplate.TemplateType = 'text';
		validEmailTemplate.FolderId = lstFolder.get(0).Id;
		insert validEmailTemplate;
		Test.startTest();
		    List<SelectOption> templatesAll= CaseSendEmailController.getTemplatesFromFolder(lstFolder.get(0).Name);
		    List<EmailTemplate> templates= [SELECT id,Name,TemplateType FROM EmailTemplate WHERE FolderId =:lstFolder.get(0).Id];
		  	System.assertEquals(templatesAll.size(), templates.size()+1);
			
			System.assertEquals(CaseSendEmailController.isHtmlTemplate(validEmailTemplate.Id),false);
		Test.stopTest();
	}
	

	/*************************************************************************************** 
	Developer - Pawan Tokas
	Date - Unknown
	Version - 1.0
	Function - 
	#############Change Log#############
	Modified by     Version     Change Date
	Wiktor Czykin   1.1         05/03/2015  //added coverage for configurable folder
	****************************************************************************************/
	static testMethod void testSendEmail(){
		TestDataUtility td = new TestDataUtility();
		td.loadGeneral();
		Case c = new Case();
		c.Subject = 'New Test Case';
		insert c;
       	Attachment  a = new Attachment();
       	a.ParentId= c.id;
       	a.IsPrivate = false;
       	a.Name='TestFileTquila';
  
   		a.Body=Blob.valueOf('Testing...Body');
   		
   		ApexPages.StandardController sc = new ApexPages.StandardController(c);
        PageReference pageRef = sc.view();
        CaseSendEmailController extension = new CaseSendEmailController(sc);
        
        extension.attachment=a;
        extension.upload();
       	List<SelectOption> attachments= CaseSendEmailController.getAttachmentsAsSelectOptions(c.Id);
		System.assertEquals(1, attachments.size()); 
		attachments= CaseSendEmailController.getAttachmentsAsSelectOptions(null);
		System.assertEquals(0, attachments.size()); 
		attachments= CaseSendEmailController.getAttachmentsAsSelectOptions('');
		System.assertEquals(0, attachments.size()); 
		
        extension.toEmail= 'test@testTquila.com';
        extension.additionalTo=null;
        extension.ccEmail='abc.xyz@tquilatest.com';
        extension.body='testing email body';
        extension.attachment= a;
        extension.bccEmail='';
        extension.subject='the subject';
        extension.selectedAttachments = new String[]{a.Id};
        List<Messaging.EmailFileAttachment> alist= CaseSendEmailController.getAttachmentList(extension.selectedAttachments);
        Test.startTest();
	        system.assertEquals(1, alist.size());
			PageReference nextPage =extension.send();
			extension.toEmail= 'test@testTquila.com';
	        extension.additionalTo='abctest@tquilabbc.com;abctest2@tquilabbc.com';
	        extension.ccEmail='abc.xyz@tquilatest.com;abc.xyz2@tquilatest.com';
	        extension.body='testing email body';
	        extension.attachment= a;
	        extension.bccEmail='bcc.xyz@tquilatest.com;bcc.xyz2@tquilatest.com';
	        extension.subject='the subject';
	        nextPage =extension.send();
	        PageReference apage= extension.preview();
		Test.stopTest();
	}
}