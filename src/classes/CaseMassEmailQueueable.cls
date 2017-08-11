/**
* @author Pawel Chrzanowski
* @date 25/08/2016
* @description Queueable to send Case mass emails
#############Change Log#############
Modified by        Version     Change Date
Pawel Chrzanowski  1.1         28/04/2017  modified to give Case Web Email priority over Contact Email
**/
public class CaseMassEmailQueueable implements Queueable {

    public Integer successCount;
    public Integer failCount;
    public List<Case> selectedCases = new List<Case>();
    public List<Case> otherCases = new List<Case>();
    public String emailErrorReport;
    public String selectedOrgEmailId;
    public String selectedEmailBodyType;
    public String emailCustomSubject;
    public String emailCustomBody;
    public String selectedTemplate;
    @testVisible private static final Integer BATCH_SIZE = 200;

    /************************************************************************************
    Developer - Pawel Chrzanowski
    Date - 25/08/2016
    Version - 1.0
    Function - queueable constructor
    #############Change Log#############
    Modified by         Version     Change Date
    *************************************************************************************/
    public CaseMassEmailQueueable(List<Case> lstCases, String emailId, String bodyType, String subject, String body, String templateId, String errorReport, Integer successes, Integer fails){
        if(lstCases.size() > BATCH_SIZE){
            for(Integer i=0; i<BATCH_SIZE; i++) selectedCases.add(lstCases[i]);
            for(Integer i=BATCH_SIZE; i<lstCases.size(); i++) otherCases.add(lstCases[i]);
        }else{
            selectedCases.addAll(lstCases);
        }
        selectedOrgEmailId = emailId;
        selectedEmailBodyType = bodyType;
        emailCustomSubject = subject;
        emailCustomBody = body;
        selectedTemplate = templateId;
        emailErrorReport = errorReport == null ? '' : errorReport;
        successCount = successes == null ? 0 : successes;
        failCount = fails == null ? 0 : fails;
    }

    /************************************************************************************
    Developer - Pawel Chrzanowski
    Date - 25/08/2016
    Version - 1.0
    Function - queueable execute method
    #############Change Log#############
    Modified by         Version     Change Date
    Pawel Chrzanowski   1.1         28/04/2017   modified to give Case Web Email priority over Contact Email
    *************************************************************************************/
    public void execute(QueueableContext context){
        if(String.isBlank(selectedOrgEmailId) || String.isBlank(selectedEmailBodyType) || (selectedEmailBodyType == CaseMassAmendmentController.EMAIL_BODY_TEMPLATE && String.isBlank(selectedTemplate))) return;

        List<Case> lstCases = [SELECT SuppliedEmail, Contact.Email, Contact.FirstName, Contact.LastName FROM Case WHERE Id IN :selectedCases];
        if(lstCases.isEmpty()) return;

        //create a map of temp Contacts with Email copied over from Case Web Email
        Map<Id, Contact> caseContactMap = new Map<Id, Contact>();
        for(Case c : lstCases){
            if(String.isNotBlank(c.SuppliedEmail)){
                caseContactMap.put(c.Id, new Contact(Email = c.SuppliedEmail, FirstName = c.Contact.FirstName, LastName = c.Contact.LastName));
            }
        }
        if(!caseContactMap.isEmpty()){
            insert caseContactMap.values();
        }

        List<Messaging.SingleEmailMessage> lstSingleEmails = new List<Messaging.SingleEmailMessage>();
        for(Integer i=0; i<lstCases.size(); i++){
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setSaveAsActivity(true);
            email.setOrgWideEmailAddressId(selectedOrgEmailId);
            email.setTargetObjectId(String.isNotBlank(lstCases[i].SuppliedEmail) ? caseContactMap.get(lstCases[i].Id).Id : lstCases[i].Contact.Id);
            email.setWhatId(lstCases[i].Id);
            if(selectedEmailBodyType == CaseMassAmendmentController.EMAIL_BODY_CUSTOM){
                email.Subject = emailCustomSubject;
                email.PlainTextBody = emailCustomBody;
            }else{
                email.setTemplateId(selectedTemplate);
            }
            lstSingleEmails.add(email);
        }

        List<Messaging.SendEmailResult> emailResults = new List<Messaging.SendEmailResult>();
        if(!Test.isRunningTest()){
            emailResults = Messaging.sendEmail(lstSingleEmails);
        }

        for(Messaging.SendEmailResult ser : emailResults){
            if(ser.isSuccess()){
                successCount++;
            }else{
                failCount++;
                for(Messaging.SendEmailError see : ser.getErrors()){
                    emailErrorReport += '(' + see.getStatusCode() + ') ' + see.getMessage() + '\r\n' ;
                }
            }
        }
        if(!caseContactMap.isEmpty()){
            delete caseContactMap.values();
        }

        if(!otherCases.isEmpty()){
            System.enqueueJob(new CaseMassEmailQueueable(otherCases, selectedOrgEmailId, selectedEmailBodyType, emailCustomSubject, emailCustomBody, selectedTemplate, emailErrorReport, successCount, failCount));
        }else{
            finish();
        }
    }

    /************************************************************************************
    Developer - Pawel Chrzanowski
    Date - 25/08/2016
    Version - 1.0
    Function - queueable finish method
    #############Change Log#############
    Modified by         Version     Change Date
    *************************************************************************************/
    private void finish(){
        Integer totalCount = successCount + failCount;
        String mailBody = 'Emails queued for delivery: ' + successCount + '/' + totalCount + '\r\n \r\n';
        if(String.isNotBlank(emailErrorReport)){
            mailBody += 'Email error report: \r\n';
            mailBody += emailErrorReport;
        }

        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setSubject('Case Mass Email Report');
        email.setTargetObjectId(System.UserInfo.getUserId());
        email.setHTMLBody(mailBody);
        email.setSaveAsActivity(false);
        if(!Test.isRunningTest()){
            Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{email});
        }
    }
}