/************************************************************************************
Class Name   : NotificationBannerController
Author       : Mantas Grigaliunas
Created Date : 25/10/2016
Function     : Controller class for visualforce component 'NotificationBanners'. 
			   This component is used to display custom messages on standard sf record pages
Change Log:
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
* Developer             Date         Description
* Vishant Shah			19/04/2017	 Removed static references. and fixed logic when showing multiple messages.
* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
*************************************************************************************/
public class NotificationBannerController {

	public  Id objectRecordId { get; set; }

	public  Map<String, String> messageMapTemp { get; set;}

	public  Map<String, String> messageMap { 
		get {
			if (messageMapTemp == null)
				messageMapTemp = messagesToDisplay(objectRecordId);

			return messageMapTemp;
		}
		private set;
	}

	public  Set<String> severity = new Set<String>{'error', 'warning', 'info', 'success'};

    /************************************************************************************
    Method Name  : messagesToDisplay
    Created by   : Mantas Grigaliunas
    Change Date  : 25/10/2016
    Function     : The method to define the map of messages and severities to be displayed on the page
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer         Date        Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
	public  Map<String, String> messagesToDisplay(Id recordId){

		Map<String, String> msgMap = new Map<String, String>();
		String sObjectType = recordId.getSobjectType().getDescribe().getName();
		List<String> sObjectFields = new List<String>();
		List<String> conditions = new List<String>();
		//get define messages from custom settings
		List<Notification_Banner_Setting__c> bannerSettingsList = 
			new List<Notification_Banner_Setting__c>(getBannerSettings(sObjectType));

		//decleare the list of fields for the object defined in custom settings
		for (Notification_Banner_Setting__c bannerSetting : bannerSettingsList){
			if(bannerSetting.Fields__c != null){
				List<String> settingFields = bannerSetting.Fields__c.split(',');
				for(String field : settingFields)
	            	sObjectFields.add(field); 
	       	}
        }
        //get values of the fields if any
        Map<String, String> recordValuesMap;
        if(sObjectFields.size() > 0)
	    	recordValuesMap = getRecordValues(recordId, sObjectFields, sObjectType); 

	    //fill up the map with formatted messages and field values if any
        for(Notification_Banner_Setting__c bannerSetting : bannerSettingsList){
        	if(bannerSetting.Fields__c != null && recordValuesMap.size() > 0){
	        	List<String> settingFieldValues = new List<String>();
	        	List<String> settingFields = bannerSetting.Fields__c.split(','); 
	        	
	        	for(String field : settingFields){
	        		if (recordValuesMap.get(field) != null){
	        			settingFieldValues.add(recordValuesMap.get(field));
	        		}
	        	}
	        	if (settingFieldValues.size() > 0)
	        		msgMap.put(String.format(bannerSetting.Message__c, settingFieldValues), getSeverity(bannerSetting.Severity__c));

			} else if(bannerSetting.Fields__c == null){
				msgMap.put(bannerSetting.Message__c, getSeverity(bannerSetting.Severity__c));
			}
		}
		return msgMap;
	}

    /************************************************************************************
    Method Name  : getBannerSettings
    Created by   : Mantas Grigaliunas
    Change Date  : 25/10/2016
    Function     : returns Notification Banner Settings custom settings list
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer         Date        Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
	public  List<Notification_Banner_Setting__c> getBannerSettings(String sObjectType){
        
        List<Notification_Banner_Setting__c> bannerSettings = new List<Notification_Banner_Setting__c>();

        bannerSettings = [ SELECT Name, Fields__c, Active__c, Severity__c, Message__c
						   FROM Notification_Banner_Setting__c 
						   WHERE Object__c = :sObjectType 
						   AND Active__c = true ];
        
        return bannerSettings;
    }

    /************************************************************************************
    Method Name  : getRecordValues
    Created by   : Mantas Grigaliunas
    Change Date  : 25/10/2016
    Function     : returns map of field names with field values to be used in String formatting
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer         Date        Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
   	public  Map<String, String> getRecordValues(Id recordId, List<String> fieldNames, String sObjectType){
        
        final String DOT = '.';
        Map<String, String> fieldValuesMap = new Map<String, String>();
        
        try{
	        String query = 'SELECT Id,';
	        query       += String.join(fieldNames,',');
	        query       += ' FROM ' + sObjectType;
	        query       += ' WHERE Id = :recordId';

	        SObject record =  Database.query(query)[0];
	        
	        for(String field : fieldNames){ 
	        	//get parent record field value
	        	if(field.contains(DOT)){
	        		SObject relObjChild = record.getSObject(field.substringBefore(DOT));
	        		if(relObjChild != null){
	        			String fieldValue = String.valueOf(relObjChild.get(field.substringAfter(DOT)));
	        			if(fieldValue != null)
							fieldValuesMap.put(field, fieldValue);
	        		}
				} else{
					if (record.get(field) != null){
						String fieldValue = String.valueOf(record.get(field));
		            	fieldValuesMap.put(field, fieldValue);
	            	}
	            }

	        }
	    } catch(Exception e){
	    	ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR, e.getMessage()));
	    }
        
        return fieldValuesMap;
    }

    /************************************************************************************
    Method Name  : getSeverity
    Created by   : Mantas Grigaliunas
    Change Date  : 25/10/2016
    Function     : validates if correct severity is specified
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer         Date        Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
	public  String getSeverity(String severityAsString){
		severityAsString = severityAsString.toLowerCase();
		if(!severity.contains(severityAsString)){
			ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR, Label.Notification_Banner_Incorrect_Severity));
		}
		return severityAsString;
	}
}