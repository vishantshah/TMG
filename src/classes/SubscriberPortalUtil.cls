public with sharing class SubscriberPortalUtil {

    
    public static void sendEmail(String cls, String msg, String subject){
    	// Create a new single email message object  
        General__c sp = General__c.getInstance('Batch Subscription Failure User Email');
        
        List<String> emailAddresses = sp.Value__c.split(';');  
            
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        
        // Strings to hold the email addresses to which you are sending the email.  
            
        String[] toAddresses = emailAddresses;    
        mail.setToAddresses(toAddresses);       
        
        // Specify the name used as the display name.  
            
        mail.setSenderDisplayName('Salesforce Support: ' + cls);            
        mail.setSubject('Error: ' + subject);      
        mail.setUseSignature(false);
        
        // Specify the text content of the email.  
            
        mail.setPlainTextBody(msg);
        //mail.setHtmlBody('Error message follows: <p> <pre> <code> '+ msg +'</code> </pre> </p>');
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });	
    }
}