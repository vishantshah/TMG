/**
* Author:       Vishant Shah
* Date:         28/06/2017
* Description:  Controller Extension for CustomCase page: single page to show picklists driven from custom settings to save on admin tasks
*				only Outbound calling recordtypes will show their own standard pages.
* ******************* Change Log *******************
* Modified by 	Change Date
* Vishant Shah  26/07/2017  Setting values for lookup fields on case. and added check for assignment rules.
**/

public with sharing class CustomCaseController {

	Map<String, Map<String, Map<String, Map<String, Map<String, Set<String>>>>>> picklistValues;

	public String selectedReason     { get; set; }
	public String selectedDetail1    { get; set; }
	public String selectedDetail2    { get; set; }
	public String selectedDetail3    { get; set; }
	public String selectedDetail4    { get; set; }
	public String comments           { get; set; }
	public String recordTypeName     { get; set; }
	public Boolean hasError          { get; set; }
	public Boolean isNewCase         { get; set; }
	public Boolean assingmentRules   { get; set; }
	public List<Section> sections    { get; set; }
	public Case thisCase             { get; set; }

	private Id recordTypeId;
	private Boolean showStandardLayout;
	

	/***************************************************************************************
    Developer   Vishant Shah
    Date        28/06/2017
    Description Constructor loads the picklist values from custom settings and 
    			section items from custom metadata which are used to show dynamic sections
    ******************* Change Log *******************
    Modified by 	Change Date
    ****************************************************************************************/
	public CustomCaseController(ApexPages.StandardController controller) {

		hasError           = false;
		isNewCase          = false;
		showStandardLayout = false;
		assingmentRules    = true;
		Set<String> caseFields = Schema.getGlobalDescribe().get('Case').getDescribe().fields.getMap().keySet();		
		
		if (!Test.isRunningTest())
			controller.addFields(new List<String>(caseFields));

		if (ApexPages.currentPage().getParameters().containsKey('RecordType') && !ApexPages.currentPage().getParameters().containsKey('Id')){
			if (controller.getId() == null){
				thisCase              = new Case();
				thisCase.RecordTypeId = (String)ApexPages.currentPage().getParameters().get('RecordType');
				isNewCase             = true;
			} 
		} else {
			thisCase        = (Case)controller.getRecord();

			if (ApexPages.currentPage().getParameters().containsKey('RecordType') )
				thisCase.RecordTypeId = (String)ApexPages.currentPage().getParameters().get('RecordType');

			selectedReason  = String.isBlank(thisCase.Reason) ? '' : thisCase.Reason;
			selectedDetail1 = String.isBlank(thisCase.Type_Of_Issue__c) ? '' : thisCase.Type_Of_Issue__c;
			selectedDetail2 = String.isBlank(thisCase.Digital_Details__c) ? '' : thisCase.Digital_Details__c;
			selectedDetail3 = String.isBlank(thisCase.Digital_Details_2__c) ? '' : thisCase.Digital_Details_2__c;
			selectedDetail4 = String.isBlank(thisCase.Digital_Details_3__c) ? '' : thisCase.Digital_Details_3__c;

			if(OutboundCallingUtils.getOutboundCallingCaseRecordTypesIds().contains(thisCase.RecordTypeId)){
				showStandardLayout = true;
			}
		}

        recordTypeId   = thisCase.RecordTypeId;
        recordTypeName = RecordTypeUtility.getRecordTypeName(Case.SObjectType, recordTypeId, 'Case');

		if(!showStandardLayout){
			populateLookupValues();
			loadPicklistValues();
			loadSections();
		}
	}

	/***************************************************************************************
    Developer   Vishant Shah
    Date        26/07/2017
    Description populate id values from parameter to relevant fields on the case object.
    ******************* Change Log *******************
    Modified by 	Change Date
    ****************************************************************************************/
	public void populateLookupValues(){

		Map<String, String> objectkeyToName = new Map<String, String>();
		Map<String, String> parameterValues = new Map<String, String>();

		for(Schema.SobjectField strFld : Case.SobjectType.getDescribe().fields.getMap().Values()) {
		    if(strFld.getDescribe().getType() == Schema.DisplayType.REFERENCE) {
		        Schema.DescribeFieldResult dfr           = strFld.getDescribe(); 
		        List<Schema.sObjectType> referenceObject = strFld.getDescribe().getReferenceTo();
		        String objectRef                         = referenceObject[0].getDescribe().getKeyPrefix();
		        
		        objectkeyToName.put(objectRef, dfr.getName());
		    } 
		}

		for (String param : ApexPages.currentPage().getParameters().keySet()){
			try{
				Id recordId      = Id.valueOf(ApexPages.currentPage().getParameters().get(param));
				String objectRef = recordId.getSObjectType().getDescribe().getKeyPrefix();

				if (param != 'retURL' && param != 'Id')
					parameterValues.put(objectRef, recordId);

			} catch(Exception e) {

			}
		}

		for (String key : parameterValues.keySet()){

			if (key == Account.SobjectType.getDescribe().getKeyPrefix()){
				// THIS IS BAD .. BUT ASSUMING ONLY 1 ACCOUNT ID PASSED IN QUERY PARAMETERS
				Account acc =  [SELECT PersonContactId FROM Account WHERE Id = :parameterValues.get(key)];
				thisCase.put('ContactId', acc.PersonContactId);
			} else {
				thisCase.put(objectkeyToName.get(key), parameterValues.get(key));
			}
		}
	}

	/***************************************************************************************
    Developer   Vishant Shah
    Date        29/06/2017
    Description redirect to standard layouts if the record type is for Outbound calling.
    ******************* Change Log *******************
    Modified by 	Change Date
    ****************************************************************************************/
	public PageReference redirect(){ 
		PageReference pr;
		
		if(showStandardLayout){
            pr = new PageReference('/' + thisCase.Id + '/e?retURL=' + thiscase.Id);
	        pr.getParameters().put('nooverride', '1');
	        pr.setRedirect(true);
		}

		return pr;
	}

	/***************************************************************************************
    Developer   Vishant Shah
    Date        28/06/2017
    Description Loads picklist values from custom settings.
    ******************* Change Log *******************
    Modified by 	Change Date
    ****************************************************************************************/
	private void loadPicklistValues(){
		picklistValues = CustomValidator.getCustomValidationRules('Case', recordTypeName);

		if (picklistValues == null){
			hasError = true;
			addPageMessage(ApexPages.Severity.FATAL, 'Picklist values need to be set.');
		} else if(!picklistValues.containsKey(recordTypeId)){
			hasError = true;
			addPageMessage(ApexPages.Severity.FATAL, 'Picklist values not found in Custom Validation Rules for ' + recordTypeName);
		}

		if (picklistValues.containsKey(recordTypeId)){
            if (! isBlank(selectedReason) && 
                ! picklistValues.get(recordTypeId).containsKey(selectedReason) ){
                picklistValues.get(recordTypeId).put(selectedReason, new Map<String,Map<String,Map<String,Set<String>>>>() );
            }
            
            if (! ( isBlank(selectedReason) || isBlank(selectedDetail1) ) &&
                ! picklistValues.get(recordTypeId).get(selectedReason).containsKey(selectedDetail1) ){
                picklistValues.get(recordTypeId).get(selectedReason).put(selectedDetail1, new Map<String,Map<String,Set<String>>>() );
            }
            
            if (! ( isBlank(selectedReason) || isBlank(selectedDetail1) || isBlank(selectedDetail2) ) &&
                ! picklistValues.get(recordTypeId).get(selectedReason).get(selectedDetail1).containsKey(selectedDetail2) ){
                picklistValues.get(recordTypeId).get(selectedReason).get(selectedDetail1).put(selectedDetail2, new Map<String,Set<String>>() );
            }
            
            if (! ( isBlank(selectedReason) || isBlank(selectedDetail1) || isBlank(selectedDetail2) || isBlank(selectedDetail3) ) &&
                ! picklistValues.get(recordTypeId).get(selectedReason).get(selectedDetail1).get(selectedDetail2).containsKey(selectedDetail3) ) {
                picklistValues.get(recordTypeId).get(selectedReason).get(selectedDetail1).get(selectedDetail2).put(selectedDetail3, new Set<String>() );
            }
            
            if (! ( isBlank(selectedReason) || isBlank(selectedDetail1) || isBlank(selectedDetail2) || isBlank(selectedDetail3) || isBlank(selectedDetail4) ) &&
                ! picklistValues.get(recordTypeId).get(selectedReason).get(selectedDetail1).get(selectedDetail2).get(selectedDetail3).contains(selectedDetail4) ){
                picklistValues.get(recordTypeId).get(selectedReason).get(selectedDetail1).get(selectedDetail2).get(selectedDetail3).add(selectedDetail4);
            }
            
		}
	}

	/***************************************************************************************
    Developer   Vishant Shah
    Date        28/06/2017
    Description Loads sections from custom metadata.
    ******************* Change Log *******************
    Modified by 	Change Date
    ****************************************************************************************/
	private void loadSections(){
		sections                                           = new List<Section>();
		List<Case_Layout_Definition__mdt> layoutDefinition = [SELECT Section_Properties__c FROM Case_Layout_Definition__mdt WHERE Record_Type_Name__c = :recordTypeName];

		if (layoutDefinition.size() == 0){
			showStandardLayout = true;
		} else if (layoutDefinition.size() > 1){
			hasError = true;
			addPageMessage(ApexPages.Severity.FATAL, 'Multiple Case Layout Definitions set for ' + recordTypeName);
		} else if (layoutDefinition.size() == 1){
			sections = (List<Section>)JSON.deserialize(layoutDefinition[0].Section_Properties__c , List<Section>.class);
		}
		system.debug(sections);
	}

	/***************************************************************************************
    Developer   Vishant Shah
    Date        28/06/2017
    Description Save case and redirect to detail page.
    ******************* Change Log *******************
    Modified by 	Change Date
    ****************************************************************************************/
	public PageReference saveCase(){
		
		if (saveCaseAndComments()){
			PageReference pr = new PageReference('/' + thiscase.Id);
			pr.setRedirect(true);
			return pr;
		} 

		return null;
	}

	/***************************************************************************************
    Developer   Vishant Shah
    Date        28/06/2017
    Description Save case and redirect to close case page
    ******************* Change Log *******************
    Modified by 	Change Date
    ****************************************************************************************/
	public PageReference saveAndClose(){ 

		if(saveCaseAndComments()){
			PageReference pr = new PageReference('/' + thiscase.Id + '/s?retURL=' + thiscase.Id);
			pr.setRedirect(true);
			system.debug(pr.getUrl());
			return pr;
		}

		return null;
	}

	/***************************************************************************************
    Developer   Vishant Shah
    Date        28/06/2017
    Description Save case and redirect to new case recordtype selection page
    ******************* Change Log *******************
    Modified by 	Change Date
    ****************************************************************************************/
	public PageReference saveAndNew(){

		if (saveCaseAndComments()){

	    	String PAGE_RECORDTYPESELECT = '/setup/ui/recordtypeselect.jsp';
	    	String PARAM_ENT = 'ent';
	    	String PARAM_RETURL = 'retURL';
	    	String PARAM_SAVENEWURL = 'save_new_url';

			PageReference pr = new PageReference(PAGE_RECORDTYPESELECT);
	        pr.getParameters().put(PARAM_ENT, Case.class.getName());
	        pr.getParameters().put(PARAM_RETURL, '/' + Case.sObjectType.getDescribe().getKeyPrefix() + '/o');

	        PageReference prSaveNew = Page.NewCaseRedirect;
	        prSaveNew.getParameters().put(PARAM_RETURL, '/' + Case.sObjectType.getDescribe().getKeyPrefix() + '/o');

	        pr.getParameters().put(PARAM_SAVENEWURL, prSaveNew.getUrl());

			return pr;
		}

		return null;
	}

	/***************************************************************************************
    Developer   Vishant Shah
    Date        28/06/2017
    Description Save case and caseComments ( if any entered )
    ******************* Change Log *******************
    Modified by 	Change Date
    ****************************************************************************************/
	private Boolean saveCaseAndComments(){
		Boolean retValue = true;
		try{
			
			thisCase.Reason               = selectedReason;
			thisCase.Type_Of_Issue__c     = selectedDetail1;
			thisCase.Digital_Details__c   = selectedDetail2;
			thisCase.Digital_Details_2__c = selectedDetail3;
			thisCase.Digital_Details_3__c = selectedDetail4;
			
			if (assingmentRules){
				Database.DMLOptions dmo = new Database.DMLOptions();
				dmo.assignmentRuleHeader.useDefaultRule = true;
				thisCase.setOptions(dmo);
			}

			thisCase.AccountID = null;

			upsert thisCase;

			if (!String.isBlank(comments)){
				CaseComment comment = new CaseComment();
				comment.ParentId = thisCase.Id;
				comment.CommentBody = comments;
				insert comment;
			}
		} catch (DmlException e){
			ApexPages.addMessages(e);
			retValue = false;
		} catch (Exception e){
			addPageMessage(ApexPages.Severity.FATAL, e.getMessage());
			retValue = false;
		}

		return retValue;
	}

	/***************************************************************************************
    Developer   Vishant Shah
    Date        28/06/2017
    Description get reason picklist values from custom settings
    ******************* Change Log *******************
    Modified by 	Change Date
    ****************************************************************************************/
	public List<SelectOption> getReasonPicklist(){
		List<SelectOption> reasons = new List<SelectOption>();
		
		reasons.add(new SelectOption('', Constants.NONE_PICKLIST_VALUE));
		
		if (picklistValues.containsKey(recordTypeId)){
			for (String reason : picklistValues.get(recordTypeId).keySet() ){
				reasons.add( new SelectOption(reason, reason) );
			}
		}
		return reasons;
	}

	/***************************************************************************************
    Developer   Vishant Shah
    Date        28/06/2017
    Description get Type_Of_Issue__c picklist values from custom settings
    ******************* Change Log *******************
    Modified by 	Change Date
    ****************************************************************************************/
	public List<SelectOption> getDetail1Picklist(){
		List<SelectOption> listValues = new List<SelectOption>();
		listValues.add(new SelectOption('', Constants.NONE_PICKLIST_VALUE));
		if ( !String.isBlank(selectedReason)){
			for (String listValue : picklistValues.get(recordTypeId).get(selectedReason).keySet() ){
				listValues.add( new SelectOption(listValue, listValue) );
			}
		}

		return listValues;
	}

	/***************************************************************************************
    Developer   Vishant Shah
    Date        28/06/2017
    Description get Digital_Details__c picklist values from custom settings
    ******************* Change Log *******************
    Modified by 	Change Date
    ****************************************************************************************/
	public List<SelectOption> getDetail2Picklist(){
		List<SelectOption> listValues = new List<SelectOption>();
		listValues.add(new SelectOption('', Constants.NONE_PICKLIST_VALUE));
		if ( !String.isBlank(selectedDetail1)){
			for (String listValue : picklistValues.get(recordTypeId).get(selectedReason).get(selectedDetail1).keySet() ){
				listValues.add( new SelectOption(listValue, listValue) );
			}
		}

		return listValues;
	}

	/***************************************************************************************
    Developer   Vishant Shah
    Date        28/06/2017
    Description get Digital_Details_2__c picklist values from custom settings
    ******************* Change Log *******************
    Modified by 	Change Date
    ****************************************************************************************/
	public List<SelectOption> getDetail3Picklist(){
		List<SelectOption> listValues = new List<SelectOption>();
		listValues.add(new SelectOption('', Constants.NONE_PICKLIST_VALUE));
		if ( !String.isBlank(selectedDetail2)){
			for (String listValue : picklistValues.get(recordTypeId).get(selectedReason).get(selectedDetail1).get(selectedDetail2).keySet() ){
				listValues.add( new SelectOption(listValue, listValue) );
			}
		}

		return listValues;
	}

	/***************************************************************************************
    Developer   Vishant Shah
    Date        28/06/2017
    Description get Digital_Details_3__c picklist values from custom settings
    ******************* Change Log *******************
    Modified by 	Change Date
    ****************************************************************************************/
	public List<SelectOption> getDetail4Picklist(){
		List<SelectOption> listValues = new List<SelectOption>();
		listValues.add(new SelectOption('', Constants.NONE_PICKLIST_VALUE));
		if ( !String.isBlank(selectedDetail3)){
			for (String listValue : picklistValues.get(recordTypeId).get(selectedReason).get(selectedDetail1).get(selectedDetail2).get(selectedDetail3) ){
				listValues.add( new SelectOption(listValue, listValue) );
			}
		}

		return listValues;
	}

	/***************************************************************************************
    Developer   Vishant Shah
    Date        28/06/2017
    Description reset picklist values on reason changed
    ******************* Change Log *******************
    Modified by 	Change Date
    ****************************************************************************************/
	public void caseReasonChanged(){
		system.debug('selectedReason ' + selectedReason);
		thisCase.Reason = selectedReason;
		thisCase.Type_Of_Issue__c = null;
		thisCase.Digital_Details__c = null;
		thisCase.Digital_Details_2__c = null;
		thisCase.Digital_Details_3__c = null;
		system.debug('thisCase.Reason ' + thisCase.Reason);

		selectedDetail1 = null;
		selectedDetail2 = null;
		selectedDetail3 = null;
		selectedDetail4 = null;
	}
		

	/***************************************************************************************
    Developer   Vishant Shah
    Date        28/06/2017
    Description reset picklist values on Type_Of_Issue__c changed
    ******************* Change Log *******************
    Modified by 	Change Date
    ****************************************************************************************/
	public void caseDetail1Changed(){
		system.debug('selectedDetail1 ' + selectedDetail1);
		thisCase.Type_Of_Issue__c = selectedDetail1;
		thisCase.Digital_Details__c = null;
		thisCase.Digital_Details_2__c = null;
		thisCase.Digital_Details_3__c = null;
		system.debug('thisCase.Type_Of_Issue__c ' + thisCase.Type_Of_Issue__c);

		selectedDetail2 = null;
		selectedDetail3 = null;
		selectedDetail4 = null;
	}

	/***************************************************************************************
    Developer   Vishant Shah
    Date        28/06/2017
    Description reset picklist values on Digital_Details__c changed
    ******************* Change Log *******************
    Modified by 	Change Date
    ****************************************************************************************/
	public void caseDetail2Changed(){ 
		system.debug('selectedDetail2 ' + selectedDetail2);
		thisCase.Digital_Details__c = selectedDetail2;
		thisCase.Digital_Details_2__c = null;
		thisCase.Digital_Details_3__c = null;
		system.debug('thisCase.Digital_Details__c ' + thisCase.Digital_Details__c);
 
		selectedDetail3 = null;
		selectedDetail4 = null;
	}

	/***************************************************************************************
    Developer   Vishant Shah
    Date        28/06/2017
    Description reset picklist values on Digital_Details_2__c changed
    ******************* Change Log *******************
    Modified by 	Change Date
    ****************************************************************************************/
	public void caseDetail3Changed(){ 
		system.debug('selectedDetail3 ' + selectedDetail3);
		thisCase.Digital_Details_2__c = selectedDetail3;
		thisCase.Digital_Details_3__c = null;
		system.debug('thisCase.Digital_Details_2__c ' + thisCase.Digital_Details_2__c);
 
		selectedDetail4 = null;
	}

	/***************************************************************************************
    Developer   Vishant Shah
    Date        28/06/2017
    Description reset picklist values on Digital_Details_3__c changed
    ******************* Change Log *******************
    Modified by 	Change Date
    ****************************************************************************************/
	public void caseDetail4Changed(){ 
		system.debug('selectedDetail4 ' + selectedDetail4);
		thisCase.Digital_Details_3__c = selectedDetail4;
		system.debug('thisCase.Digital_Details_3__c ' + thisCase.Digital_Details_3__c);

	}

	/***************************************************************************************
    Developer   Vishant Shah
    Date        28/06/2017
    Description addPageMessages
    ******************* Change Log *******************
    Modified by 	Change Date
    ****************************************************************************************/
	private void addPageMessage(ApexPages.Severity severity, String errorMessage){
        ApexPages.addMessage(new ApexPages.Message(severity, errorMessage));
    }
    
    /***************************************************************************************
    Developer   Vishant Shah
    Date        24/07/2017
    Description Is the string value blank?
    ******************* Change Log *******************
    Modified by 	Change Date
    ****************************************************************************************/
	private Boolean isBlank(String value){
        return String.isBlank(value);
    }
}