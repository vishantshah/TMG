public class SubscriberPortalRest {
    private static final String PREFIX1 = 'tns';
    private static final String NS1 = 'http://www.evolok.com/api/notifications';
    
    private static final String PREFIX2 = 'tns1';
    private static final String NS2 = 'http://www.evolok.com/api/types';    
    
    private static final String CODE_SUCCESS = 'SUCCESS';
    public static Dom.Document getSubChangeNotificationXml(SubscriberPortal.Subscriber spSub){
        List<SubscriberPortal.Subscriber> spSubs = new List<SubscriberPortal.Subscriber>();
        spSubs.add(spSub);
        
        return getSubChangeNotificationXml(spSubs);
    }
    
    public static void parseSubChangeNotificationXml(String xml, String req){
        try{
        	Boolean isSuccess = xml.toUpperCase().contains(CODE_SUCCESS);
            if(!isSuccess){
                sendEmail('The transaction with SAM has failed: \n Request XML: '+ req +'\n Response Xml: ' + xml);
            }
        }catch (System.Exception e){
            System.debug(e);
            sendEmail('An error has occured parsing the reponse from SAM: \n Request XML: '+ req +'\n Response Xml: ' + xml);
        }
    }
    
    public static Dom.Document getSubChangeNotificationXml(List<SubscriberPortal.Subscriber> spSubs){
        Dom.Document doc = new Dom.Document(); 
        
        Dom.XmlNode root = doc.createRootElement('userModificationNotifications',NS1,PREFIX1);
        root.setAttribute('serviceKey',cleanData(spSubs[0].application.serviceId));
        root.setAttribute('timestamp',DateTime.now().format('yyyy-MM-dd HH:mm:ss').replace(' ','T'));
        root.setAttribute('version','1.1.0');
        root.setNamespace(PREFIX2, NS2);
        
        for(SubscriberPortal.Subscriber s: spSubs){
        
            // Add the notifications node
            Dom.XmlNode notificationsNode = addChildElement(root, 'notifications');
            notificationsNode.setAttribute('serviceKey',cleanData(s.application.serviceId));
            notificationsNode.setAttribute('timestamp',DateTime.now().format('yyyy-MM-dd HH:mm:ss').replace(' ','T'));
            notificationsNode.setAttribute('version','1.1.0');
        
            // Add the GUID node
            Dom.XmlNode guidNode = addChildElement(notificationsNode, 'guid');
            guidNode.addTextNode(cleanData(s.guid));
                    
            // Add the PID node
            Dom.XmlNode pidNode = addChildElement(notificationsNode,'pid'); 
            pidNode.addTextNode(cleanData(s.pid));
            
            // Add the attributes node
            for(SubscriberPortal.KeyValuePair kvp: s.attributes){
                if(cleanData(kvp.key)<>'EMAIL_ADDRESS' && kvp.value <> null){
                    Dom.XmlNode attrNode = addChildElement(notificationsNode, 'attributes');
                    attrNode.setAttribute('attributeType','text');              
                    
                    Dom.XmlNode nameNode = attrNode.addChildElement('name', NS2, PREFIX2);
                    nameNode.addTextNode(cleanData(kvp.key));
                    
                    Dom.XmlNode valueNode = attrNode.addChildElement('value', NS2, PREFIX2);
                    valueNode.addTextNode(cleanData(kvp.value));
                }
            }
            
            // Add the entitlements
            for(String ent: s.entitlements){
                Dom.XmlNode entNode = addChildElement(notificationsNode, 'entitlements');
                entNode.addTextNode(cleanData(ent));            
            }
            
        }
        // Add entitlements to attribute node
        System.debug('Doc: '+doc.toXmlString());
        
        
        return doc;
    }
    
    @future(callout=true)
    public static void sendSubChangeNotification(Set<Id> accIds){
        HttpResponse res;
        HttpRequest req;
        Dom.Document doc;
        
        try{
            List<SubscriberPortal.Subscriber> subs = getSubscribers(accIds);
            
            if(subs.size()>0){
                SAMHTTPSettings__c sp = SAMHTTPSettings__c.getInstance('ModifyUsersEndpoint');
                
                String url = sp.Value__c; 
        
                // Instantiate a new http object            
                Http h = new Http();
                
                // Instantiate a new HTTP request, specify the method (GET) as well as the endpoint
                req = new HttpRequest();
                req.setEndpoint(url);
                req.setHeader('Content-Type', 'application/xml');
                req.setHeader('Content-Length', '0');
                req.setMethod('POST');
                
                //Dom.Document doc = new Dom.Document();
                //doc.load('<?xml version="1.0" encoding="UTF-8"?> <tns:userModificationNotifications serviceKey="" timestamp="2001-12-31T12:00:00" xmlns:tns="http://www.evolok.com/api/notifications" xmlns:tns1="http://www.evolok.com/api/types" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.evolok.com/api/notifications notifications.xsd ">  <tns:notifications serviceKey="8wefh3-208fuf" timestamp="2001-12-31T12:00:00" >    <tns:guid>guid1</tns:guid>    <tns:attributes attributeType="text">      <tns1:name>name</tns1:name>      <tns1:value>value</tns1:value>    </tns:attributes>    <tns:entitlements>entitlement1</tns:entitlements>    <tns:entitlements>entitlement2</tns:entitlements>  </tns:notifications> </tns:userModificationNotifications> ');
                //req.setBodyDocument(doc);
                
                System.debug(subs);
                doc = getSubChangeNotificationXml(subs);
		
                req.setBodyDocument(doc);
                
                String stringResponse;
                if (!Test.isRunningTest()){
                	// Send the request, and return a response              
                	stringResponse = h.send(req).getBody();
                }
                else{
                	// Dummy response
                	stringResponse = '<xml>SUCCESS</xml>';
                }
                
                // Logging call
        		ID logId = TMGUtil.logWebServiceRequest('Outbound', sp.Value__c, 'userModificationNotifications', new Map<String,Object>{'XML' => doc.toXmlString()});
        		// Logging the Response
				TMGUtil.logWebServiceResponse(logId, stringResponse);	
				
                System.debug('response: '+stringResponse);
                
                // Check the response
                parseSubChangeNotificationXml(stringResponse, doc.toXmlString());
            }
                
        } catch (System.exception e){
            String msg;
            try{
                msg = 'Exception: '+ e + '\n Request Doc: ' + doc.toXmlString() + '\n Response: '+ res.getBody();               
            }catch (System.Nullpointerexception n){
                System.debug(n);
                
                System.debug('Response: ' +res +'\nRequest: '+req);
                msg = 'Exception: '+ e + '\n Request Doc: ' + doc + '\n Response is empty.';
            }finally{
                sendEmail(msg);
            }
        }
    }
    
    public static List<SubscriberPortal.Subscriber> getSubscribers(Set<Id> accIds){

        // Only premium subscribers who have been linked to SAM should be updated
        Id recType = Constants.IndivSubscriberRecordType();
        List<Account> accs = [SELECT id, guid__c, subscriber_number_static__c, firstName, lastName, salutation, personEmail, PersonHomePhone, PersonMobilePhone, personHasOptedOutOfEmail, Do_Not_Mail__pc, PersonDoNotCall, X3rd_Party_Email_Offers__pc, TMG_Promo_SMS__c, TMG_Loyalty_Email__c, TMG_Promo_Email__c, TMG_Promo_Post__c, TMG_Promo_Phone__c, TMG_Partner_Promo_Email__c, PersonMailingStreet, PersonMailingCity, PersonMailingPostalCode, PersonMailingCountry, PersonMailingState, Subscriber_Digital_Status__c, RecordTypeId
                 FROM Account a WHERE id IN :accIds AND guid__c <> null AND recordTypeId = :recType]; 
                 
        Map<Id,List<Subscription__c>> subsPerAcc = new Map<Id,List<Subscription__c>>();
        
        for(List<Subscription__c> subs: [SELECT id, subscriber__c, Subscription_Status__c,Start_Date__c, Subscription_Duration_Number__c, createdDate, Cancellation_Date__c,Product__c FROM Subscription__c WHERE subscriber__c IN :accIds]){
            for(Subscription__c s: subs){
                List<Subscription__c> accSubs;
                
                if(subsPerAcc.containsKey(s.subscriber__c)){
                    accSubs = subsPerAcc.get(s.subscriber__c);               
                }else{
                    accSubs = new List<Subscription__c>();
                }
                
                accSubs.add(s);
                subsPerAcc.put(s.subscriber__c, accSubs);
            }
        }
        
        List<SubscriberPortal.Subscriber> subscribers = new List<SubscriberPortal.Subscriber>();
        
        SAMHTTPSettings__c sp = SAMHTTPSettings__c.getInstance('ServiceKey');
        SubscriberPortal.Application app = new SubscriberPortal.Application(sp.Value__c);
        
        for(Account a: accs){
            List<Subscription__c> accSubs = subsPerAcc.get(a.id);
            
            subscribers.add( new SubscriberPortal.Subscriber(app,a,accSubs, null));
        }
        
        System.debug('Accs: '+accs);
        SYstem.debug('spSubs: '+subscribers);
    
        return subscribers;
    }
    
    private static Dom.XmlNode addChildElement(Dom.XmlNode el, String name){
        return el.addChildElement(name,NS1,PREFIX1);
    }
    
    
    
    private static String cleanData(String value){
        if (value==null)
            return '';
        else if (value.toUpperCase() == 'TRUE' || value.toUpperCase() == 'FALSE')
            value = value.toUpperCase();
            
        return value;
    }
    
    /* Utility Methods */
    private static void sendEmail(String msg){
        // Create a new single email message object  
        General__c sp = General__c.getInstance('Batch Subscription Failure User Email');
        
        List<String> emailAddresses = sp.Value__c.split(';');  
            
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        
        // Strings to hold the email addresses to which you are sending the email.  
            
        String[] toAddresses = emailAddresses;    
        mail.setToAddresses(toAddresses);       
        
        // Specify the name used as the display name.  
            
        mail.setSenderDisplayName('Salesforce Support');            
        mail.setSubject('Error: Salesforce outbound messages to SAM');      
        mail.setUseSignature(false);
        
        // Specify the text content of the email.  
            
        mail.setPlainTextBody('This outbound call sends update requests to SAM (from Salesforce) in bulk (of 1 or greater). A bulk update will' +
                                ' fail if 1 or more records in the bulk don\'t update for whatever reason. The error message details all records that '+
                                'have failed (as well as the cause of the failure) and details records that would\'ve been successfully parsed otherwise. \nThe error message follows: \n' + msg);
        //mail.setHtmlBody('Error message follows: <p> <pre> <code> '+ msg +'</code> </pre> </p>');
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }
    
       
    
}