/**
* @author Calum Melrose
* @date 15/03/2016
* @description Default Email Template Selector class for Case feed
* #############Change Log#############
* Modified by     Version     Change Date
**/
public class DefaultEmailTemplateSelector implements Support.EmailTemplateSelector {

	public static final String TEMPLATE_KEY = 'Default Email Template for Selector';

	/*************************************************************************************** 
	Developer - Calum Melrose
	Date - 15/03/2016
	Version - 1.0
	Function -  // The main interface method 
	#############Change Log#############
	Modified by     Version     Change Date
	Wiktor Czykin	1.1			23/03/2016	//added custom setting support and IsActive flag check
	****************************************************************************************/
	public Id getDefaultEmailTemplateId(Id caseId) {
		General__c defaultTemplateName = General__c.getInstance(TEMPLATE_KEY);
		if(defaultTemplateName == null || String.isBlank(defaultTemplateName.Value__c)) return null;

		List<EmailTemplate> lstTemplate = [select Id from EmailTemplate where DeveloperName = :defaultTemplateName.Value__c and IsActive = true];
		if(!lstTemplate.isEmpty()) return lstTemplate[0].Id;
		return null;
	}
}