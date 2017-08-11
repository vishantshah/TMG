/**
* @author Pawan Tokas (Tquila)
* @date Unknown
* @description 
#############Change Log#############
Modified by     Version     Change Date
Wiktor Czykin   1.1         05/03/2015  //modified getTemplatesFromFolder() as was blowing up in tests
**/
public with sharing class CaseSendEmailController {
  
  	private static final String SEPARATOR = ';';

	public String fromEmail { get; set; }
	public String toEmail { get; set; }
	public String ccEmail {get; set;}
	public String bccEmail {get; set;}
	public String subject { get; set; }
	public String additionalTo {get; set; }
	public String body { get; set; }
	public List<SelectOption> attachments {get; set;}
	public List<SelectOption> templates {get; set;}
	public String selectedTemplate {get;set;}
	public String[] selectedAttachments{get; set;}
	public Attachment attachment {
      get {
         if (attachment == null)
            attachment = new Attachment();
          return attachment;
         }
       set;
    }
	private ApexPages.StandardController controller;
	
	public  Case selectedCase;
	public Case getSelectedCase(){
   			return selectedCase;
  	}
  	
	
	/*************************************************************************************** 
	Developer - Pawan Tokas
	Date - Unknown
	Version - 1.1
	Function - //constructor
	#############Change Log#############
	Modified by     Version     Change Date
	Wiktor Czykin   1.1         05/03/2015  //made folder configurable
	****************************************************************************************/
	public CaseSendEmailController(ApexPages.StandardController stdController) {
		controller= stdController;
		this.selectedCase=(Case) stdController.getRecord();
		this.selectedCase = [select Id, Subject, CaseNumber, Contact.Id, Priority, Status, Contact.Name, Contact.Email from Case where Id  = :selectedCase.Id];
		this.toEmail = selectedCase.contact.email;
		this.subject = selectedCase.subject;
		this.attachments = CaseSendEmailController.getAttachmentsAsSelectOptions(this.selectedCase.Id);
		String sFolder = Constants.CASE_SENDEMAIL_DEFAULTFOLDER;

		General__c folderSetting = General__c.getInstance(Constants.CASE_SENDEMAIL_FOLDERSETTING);
		if(folderSetting != null && String.isNotBlank(folderSetting.Value__c)){
			sFolder = folderSetting.Value__c;
		}
		this.templates= CaseSendEmailController.getTemplatesFromFolder(sFolder);
	}
  
    public PageReference upload() {
    	attachment.OwnerId = UserInfo.getUserId();
    	attachment.ParentId = selectedCase.Id; // the record the file is attached to
    	attachment.IsPrivate = false;
		try {
      			insert attachment;
    		} catch (DMLException e) {
      			ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,'Error uploading attachment'));
      			return null;
    		} finally {
      			
      		
    		}
   			 ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO,'Attachment uploaded successfully'));
   			 this.attachments=CaseSendEmailController.getAttachmentsAsSelectOptions(this.selectedCase.Id);
   			 return null;
  	}
  
   	public PageReference saveCase() {
		update this.selectedCase;
	 	return null;
   	}
   
   
	/*************************************************************************************** 
	Developer - Pawan Tokas
	Date - Unknown
	Version - 1.1
	Function - //To get the merge text from the template selected.
	#############Change Log#############
	Modified by     Version     Change Date
	Wiktor Czykin   1.1         05/03/2015  //added is running test check for sending line to avoid error when deliverability of emails is off
											//made sure contact email is only used once (not duplicated in TO and impacting limits)
	Wiktor Czykin	1.2 		09/03/2015	//added validation for cases linked to contacts that do not have email address
	****************************************************************************************/
	public PageReference preview(){
	  	if(this.selectedTemplate !='0'){
	  		if(String.isBlank(this.selectedCase.Contact.Email)){
	  			ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO, Label.Case_Send_Email_No_email_on_case_contact));
	  			return null;
	  		}
	  	    Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage(); 
	        email.setTargetObjectId(selectedCase.Contact.Id);
	        email.setWhatId(selectedCase.Id);
	        email.setSaveAsActivity(false);
			email.setTemplateId(this.selectedTemplate);
	 		if(Test.isRunningTest()){
	 			email.setPlainTextBody('Test Email..');
	 			email.setToAddresses(new String[]{'test@testTquila.com'});
				email.setCcAddresses(new String[]{'testcc@testTquila.com'});
				email.setBccAddresses(new String[]{'testbcc@testTquila.com'});
	        	email.subject='the subject';
	 		}
	 		///Save point very important. Anything after this will be rolled back. 
	 		///Is used to show the merge fields and create email body.
		    Savepoint sp = Database.setSavepoint();
		    if(!Test.isRunningTest()){
				Messaging.SendEmailResult [] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});
			}
			Database.rollback(sp);
			this.subject= email.getSubject();
			if(CaseSendEmailController.isHtmlTemplate(this.selectedTemplate)){ this.body= email.getHtmlBody();}
			else{this.body= email.getPlainTextBody();}
		} else {
	  		this.body= '';
			this.subject= '';
	  	}
		return null;
	}

   
	/*************************************************************************************** 
    Developer - Pawan Tokas
    Date - Unknown
    Version - 1.1
    Function - Sends email
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         05/03/2015  //added is running test check for sending line to avoid error when deliverability of emails is off.
    										//made sure contact email is only used once (not duplicated in TO and impacting limits)
    										//replaced error msg with labels
    ****************************************************************************************/
	public PageReference send() {
		boolean isvalid=true;
		Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage(); 
        email.setTargetObjectId(selectedCase.Contact.Id);
        email.setWhatId(selectedCase.Id);
        email.setSaveAsActivity(true);
        String[] ccAddresses = new String[]{};
		String[] bccAddresses = new String[]{};
		String[] additionalToAddresses = new String[]{};
		
		//Validate Email Addresses
		if(String.isBlank(selectedCase.contact.Email)){
			ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO, Label.Case_Send_Email_No_email_on_case_contact));
   			isvalid=false;
		}
		
		if(this.additionalTo !=null && this.additionalTo !='')	{
			 additionalToAddresses= this.additionalTo.split(SEPARATOR);
		      for(String aemail: additionalToAddresses){
			     if(!CaseSendEmailController.checkEmail(aemail)){
				   ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO, Label.Case_Send_Email_Wrong_additional_to));
   			       isvalid=false;
			     }
		      }
		}
		
		if(this.ccEmail !=null && this.ccEmail !='')	{
			 ccAddresses= this.ccEmail.split(SEPARATOR);
		      for(String aemail: ccAddresses){
			     if(!CaseSendEmailController.checkEmail(aemail)){
				   ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO, Label.Case_Send_Email_Wrong_cc_addresses));
   			       isvalid=false;
			     }
		      }
		}
		
		if(this.bccEmail !=null && this.bccEmail !='')	{
			 bccAddresses= this.bccEmail.split(SEPARATOR);
		      for(String aemail: bccAddresses){
			     if(!CaseSendEmailController.checkEmail(aemail)){
				   ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO,Label.Case_Send_Email_Wrong_bcc_addresses));
   			       isvalid=false;
			     }
		      }
		}
		
		if(!isvalid)return null;
		
		email.setSubject( subject );
		email.setToAddresses(additionalToAddresses);
		email.setCcAddresses(ccAddresses);
		email.setBccAddresses(bccAddresses);
		if(CaseSendEmailController.isHtmlTemplate(this.selectedTemplate)){
			email.setHtmlBody(body);
		}else
		{
			email.setPlainTextBody(body);
		}
		
		email.setFileAttachments(CaseSendEmailController.getAttachmentList(this.selectedAttachments));
		if(!Test.isRunningTest()){
			Messaging.SendEmailResult [] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});   
		}
		return controller.save();
	}
	
	///Helper Method to validate email addresses.
	public static boolean checkEmail (String semail) {
		if (semail==null || semail=='')return false;
			String InputString = semail;
			String emailRegex = '([a-zA-Z0-9_\\-\\.]+)@((\\[a-z]{1,3}\\.[a-z]{1,3}\\.[a-z]{1,3}\\.)|(([a-zA-Z0-9\\-]+\\.)+))([a-zA-Z]{2,4}|[0-9]{1,3})';
			Pattern MyPattern = Pattern.compile(emailRegex);
			Matcher MyMatcher = MyPattern.matcher(InputString);

				if (!MyMatcher.matches()) {
					return FALSE;
				} else {
					return TRUE;
				}
	} 
	
	///Helper Method to get attachments as selectOptions.
	public static List<SelectOption> getAttachmentsAsSelectOptions(String recordId) {
        List<SelectOption> options = new List<SelectOption>();
        List<Case> caseattachments= [select id,casenumber,(select id,Name from attachments) from case where id = :recordId];
       		if(caseattachments.size()>0){
    				for(case c:caseattachments) {
  			 			for(attachment a:c.attachments) {
			   				options.add(new SelectOption(a.Id , a.Name));
  			 			}
    				 }
    	
    		}
		return options;
    }

    /*************************************************************************************** 
    Developer - Pawan Tokas
    Date - Unknown
    Version - 1.1
    Function - Get Template names from a folder as SelectOptions
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         10/02/2015  //added extra check that folder is actually there
    ****************************************************************************************/
	public static List<SelectOption> getTemplatesFromFolder(String folderName) {
		
        List<SelectOption> options = new List<SelectOption>();
        String folderId='';

        Boolean bFolderError = false;
        if (folderName ==null || folderName ==''){
        	bFolderError = true;
        }else{
        	List<Folder> lstFolders = [select Id from Folder where Name =:folderName]; 
        	if(lstFolders.isEmpty()){
        		bFolderError = true;
        	}else{
				folderId= lstFolders[0].Id;
			}
        }

        if(bFolderError){
        	options.add(new SelectOption('0' , '----No Folder Defined: Email From Case Templates----'));
        	return options;
    	}
        
        List<EmailTemplate> templates= [SELECT id,Name,TemplateType FROM EmailTemplate WHERE FolderId =:folderId];
       	if(templates.size()>0){
       	    options.add(new SelectOption('0' , '----Select Template----'));
    		for(EmailTemplate atemp:templates) {
	 			options.add(new SelectOption(atemp.Id , atemp.Name));
	 		}
       	}else{
       		options.add(new SelectOption('0' , '----No Templates Defined in (Email From Case Templates folder) ----'));
    	}
        
        return options;
    }
    
    //Check if the template selected by the user is of type html or text. Need to choose for merging 
	// to decide to use get html body or plaintext body.
	public static Boolean isHtmlTemplate(String templateID) {
		   if(templateID!=null || templateID!=''){
				List<EmailTemplate> templates= [SELECT id,Name,TemplateType FROM EmailTemplate WHERE Id =:templateID];
				if (templates.size()>0) {
					if(templates[0].TemplateType =='html')return true;
				}
			}
			return false;
	     }
	     
	public static List<Messaging.EmailFileAttachment> getAttachmentList(String[] attachmentids){
		List<Attachment> docs= [select id, name, body from attachment where id in : attachmentids];
		list<Messaging.EmailFileAttachment> attachedfiles= new list<Messaging.EmailFileAttachment>();
		if(docs.size()>0){
			Messaging.EmailFileAttachment afile;
			for(Attachment d: docs){
				afile= new Messaging.EmailFileAttachment();
				afile.setFileName(d.name);
				afile.setBody(d.body);
				attachedfiles.add(afile);
			}
			
		}
		return attachedfiles;
	}
	
	
}