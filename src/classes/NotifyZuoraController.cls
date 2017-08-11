/**
* Author:       Gavin Palmer (Accenture)
* Date:         25/04/2016
* Description:  core api callout from the Subscription plan 
*				upload record
* ******************* Change Log *******************
* Modified by       Change Date     Description
**/
public class NotifyZuoraController {

	public String pageText {get; set;}
	private Boolean exceptionThrownInConstructor;
	private Subscription_Plan_Upload__c subscriptionPlanUpload;
	@TestVisible private Boolean canOverrideValidation;
	// lazy load the chatter files related to the record
	private List<ContentDocumentLink> documentLinks {
		get {
			if(documentLinks == null) {
				documentLinks = [
					SELECT 
						ContentDocument.Title, 
						ContentDocument.FileType, 
						ContentDocument.ContentSize 
					FROM ContentDocumentLink
					WHERE LinkedEntityId = :subscriptionPlanUpload.Id
				];
			}
			return documentLinks;
		}
		set;
	}
	
	/**
	* Author:       Gavin Palmer (Accenture)
	* Date:         28/04/2016
	* Description:  instansiate variables and get the record
	*
	* ******************* Change Log *******************
	* Modified by       Change Date     Description
	**/
	public NotifyZuoraController(ApexPages.StandardController controller) {

		pageText = '';
		exceptionThrownInConstructor = false;
		canOverrideValidation = false;
		try{
			String subscriptionPlanUploadId = controller.getId();
			subscriptionPlanUpload = [
				SELECT Status__c
				FROM Subscription_Plan_Upload__c 
				WHERE Id =:subscriptionPlanUploadId
			];
		} catch (Exception exceptionToHandle) {
			pageText = Label.Notify_Zuora_Error_Getting_Record;
			exceptionThrownInConstructor = true;
			System.debug(loggingLevel.Error, 'Exception: ' + exceptionToHandle);
		}
	}

	/**
	* Author:       Gavin Palmer (Accenture)
	* Date:         26/04/2016
	* Description:  make the callout to core API
	*
	* ******************* Change Log *******************
	* Modified by       Change Date     Description
	**/
	public void calloutToCoreAPI(){
		if(canOverrideValidation || recordIsValidForCallout()) {
			try{
				CoreAPICalloutUtility.SendObjectEvent(
					Constants.NOTIFY_ZUORA_UPLOADED, 
					Constants.NOTIFY_ZUORA_OBJECT_TYPE, 
					subscriptionPlanUpload.Id
				);

				subscriptionPlanUpload.Status__c = Constants.SUBSCRIPTION_PLAN_UPLOAD_STATUS_NOTIFIED;
				update subscriptionPlanUpload;
				pageText = Label.Notify_Zuora_Message_Sent;
			} catch(System.CalloutException calloutExceptionToHandle){
				pageText = Label.Notify_Zuora_Message_Sent_Error;
				System.debug(loggingLevel.Error, 'Exception: ' + calloutExceptionToHandle);
			} catch(System.DmlException dmlExceptionToHandle) {
				pageText = Label.Notify_Zuora_Message_Sent_Update_Error;
				System.debug(loggingLevel.Error, 'Exception: ' + dmlExceptionToHandle);
			}
		}
	}

	/**
	* Author:       Gavin Palmer (Accenture)
	* Date:         25/04/2016
	* Description:  Check that the record is in the correct state to make 
	*				the callout if not dont do the callout and put a message on the page
	* ******************* Change Log *******************
	* Modified by       Change Date     Description
	**/
	private Boolean recordIsValidForCallout(){

		// this will stop the callout from going further
		if(exceptionThrownInConstructor) return false;

		if(subscriptionPlanUpload.Status__c != Constants.SUBSCRIPTION_PLAN_UPLOAD_STATUS_DRAFT) {
			pageText = Label.Notify_Zuora_Validation_Draft;
			return false;
		}

		if(documentLinks.isEmpty()){
			pageText = Label.Notify_Zuora_Validation_No_Attachment;
			return false;
		}

		return true;
	}
}