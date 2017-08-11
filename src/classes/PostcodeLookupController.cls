/* -----------------------------------------------------------------------------------------------------------------------
   Name:        PostcodeLookupController.cls
   Description: Controller class for visualforce component 'PostcodeLookup'. 

   Date         Version Author                      Summary of Changes 
   -----------  ------- -----------------   ------------------------------------------------------------------------------
   07/09/2015		1.0			Cristina Anghenie	disable postcode lookup functionality from the sandboxes
------------------------------------------------------------------------------------------------------------------------ */
public with sharing class PostcodeLookupController {

	public Boolean isOn{
		get{
			if(this.isOn == null){
				this.isOn = false;
				General__c setting = General__c.getInstance(Constants.POSTCODE_LOOKUP_CUSTOMSETTINGS);
				if(setting != null && setting.Value_Boolean__c){
					this.isOn = true;
				}
			}
			return this.isOn;
		}
		set;
	}
}