/** Webservice to provide a method to allow the last access date to be updated
*	This is provided as a seperate service as it will be accessed from user's devices
*	and providing the entire SubscriptionsWebservices to them could pose a security issue
*/
global class DigitalUpdateWebservices {
	
	global class DeviceInfo {

Webservice String deviceid;
Webservice String deviceName;
Webservice String deviceType;
Webservice String deviceOS;
Webservice List<AppInfo> apps;


}


global class EntitlementDetails
{
Webservice String entitlementIdentifier ;
Webservice String entitlementType ;	
}

global class AppInfo {

Webservice String appVersion;
Webservice String appName;
}

global class VendorId {

Webservice String idType;
Webservice String id;
}

global class SubscriptionDetails {

Webservice String mobilePlatformSubscriptionId;
Webservice String subscriptionType;
Webservice Date createdDate;
Webservice String frequency;
Webservice Boolean autoRenewing;
Webservice PaymentDetails paymentDetails;
Webservice String subscriptionProduct;
Webservice String campaignCode;
}

global class PaymentDetails {

Webservice String paymentIdentifier;
Webservice Date firstPaymentDate;
Webservice Date mostRecentPaymentDate;
Webservice Date nextPaymentDate;
Webservice Decimal paymentAmount;
Webservice String paymentType;
}

	/** Update the date and time at which a user last accessed a particular device
	*/
	webservice static SubscriptionsWebservices.GeneralSubscriptionsWebserviceResult UpdateLastAccessedData(String TSNumber, String device, DateTime lastAccessed){

		Exception ex;
		SubscriptionsWebservices.GeneralSubscriptionsWebserviceResult result;
		ID logId;

		logId = TMGUtil.logWebServiceRequest('Inbound', null, 'DigitalUpdateWebservices.UpdateLastAccessedDetails', new Map<String,Object>{'TSNumber' => TSNumber, 'device' => device, 'lastAccessed' => lastAccessed});
			
		try{

			SubscriptionsWebservicesHandlers.updateLastAccessedData(TSNumber, device, lastAccessed);
			// PP-1693 - empty result should be returned in case of success
			result = new SubscriptionsWebservices.GeneralSubscriptionsWebserviceResult();
		} catch (Exception e){ 
			result = new SubscriptionsWebservices.GeneralSubscriptionsWebserviceResult(new WebserviceUtil.WSException().getError());
			TMGUtil.logWebServiceDetail(logId, string.valueOf(e));
			ex = e;
		} 
		
		if(result != null && result.wsError != null){
			SubscriptionsWebservicesHandlers.sendErrorEmail('DigitalUpdateWebservices.UpdateLastAccessedDetails', logId, result.wsError.errorMessage, ex);
		}

		TMGUtil.logWebServiceResponse(logId, result);
		return result;		
	}	
	
	
	/** Update the date and time at which a user last accessed a particular device
	*/
	webservice static SubscriptionsWebservices.GeneralSubscriptionsWebserviceResult UpdateUsage(VendorId vendorId, SubscriptionDetails subscriptionDetails, DeviceInfo device, DateTime lastAccessed){

		Exception ex;
		SubscriptionsWebservices.GeneralSubscriptionsWebserviceResult result;
		ID logId;

		logId = TMGUtil.logWebServiceRequest('Inbound', null, 'DigitalUpdateWebservices.UpdateUsage', new Map<String,Object>{'VendorId' => vendorId, 'SubscriptionDetails' => subscriptionDetails, 'DeviceInfo' => device,'lastAccessed' => lastAccessed });
			
		try{
			if(vendorId.idType=='print')
			{
				SubscriptionsWebservicesHandlers.updateLastAccessedData(vendorId.id, device.deviceType, lastAccessed);
			
			}
			// PP-1693 - empty result should be returned in case of success
			result = new SubscriptionsWebservices.GeneralSubscriptionsWebserviceResult();
		} catch (Exception e){ 
			result = new SubscriptionsWebservices.GeneralSubscriptionsWebserviceResult(new WebserviceUtil.WSException().getError());
			TMGUtil.logWebServiceDetail(logId, string.valueOf(e));
			ex = e;
		} 
		
		if(result != null && result.wsError != null){
			SubscriptionsWebservicesHandlers.sendErrorEmail('DigitalUpdateWebservices.UpdateLastAccessedDetails', logId, result.wsError.errorMessage, ex);
		}

		TMGUtil.logWebServiceResponse(logId, result);
		return result;		
	}	
	/** Remove all digital entitlements for the accounts denoted 
		by the list of GUIDs
	*/
	webservice static SubscriptionsWebservices.GeneralSubscriptionsWebserviceResult ClearDigitalEntitlements(List<string> SAMGuids){
		
		Exception ex;
		SubscriptionsWebservices.GeneralSubscriptionsWebserviceResult result;
		ID logId;

		logId = TMGUtil.logWebServiceRequest('Inbound', null, 'DigitalUpdateWebservices.ClearDigitalEntitlements', new Map<String,Object>{'SAMGuids' => SAMGuids});
			
		try{
			result = new SubscriptionsWebservices.GeneralSubscriptionsWebserviceResult();
			//Currently only iPad app entitlments are maanged this way. This may need to be extended for 
			//Kindle when it's intergated with the Subscription platform
			String newEntitlement='IPAD_SUBSCRIBER_INACTIVE';
			SubscriptionsWebservicesHandlers.clearDigitalEntitlements(SAMGuids, newEntitlement);

		} catch (Exception e){ 
			result = new SubscriptionsWebservices.GeneralSubscriptionsWebserviceResult(new WebserviceUtil.WSException().getError());
			TMGUtil.logWebServiceDetail(logId, string.valueOf(e));
			ex = e;
		} 
		
		if(ex != null){
			SubscriptionsWebservicesHandlers.sendErrorEmail('DigitalUpdateWebservices.ClearDigitalEntitlements', logId, '', ex);
		}
		
		return result;
		
	}
	
	
		
	/** Added New method part of Vodafone
	 ** Update the devices and apps used by customers
	*/
	webservice static SubscriptionsWebservices.GeneralSubscriptionsWebserviceResult UpdateUsageTracking(VendorId vendorId, EntitlementDetails entitlement, DeviceInfo device, DateTime lastAccessed){

		Exception ex;
		SubscriptionsWebservices.GeneralSubscriptionsWebserviceResult result;
		ID logId;

		logId = TMGUtil.logWebServiceRequest('Inbound', null, 'DigitalUpdateWebservices.UpdateUsageTracking', new Map<String,Object>{'VendorId' => vendorId, 'EntitlementDetails' => entitlement, 'DeviceInfo' => device,'lastAccessed' => lastAccessed });
			
		try{
		   SubscriptionsWebservicesHandlers.updateUsageTrackingData(vendorId.id, device,entitlement,lastAccessed); 

			result = new SubscriptionsWebservices.GeneralSubscriptionsWebserviceResult();
		}
		catch(WebserviceUtil.NullParameterException npe){
			result = new SubscriptionsWebservices.GeneralSubscriptionsWebserviceResult(npe.getError());
			TMGUtil.logWebServiceDetail(logId, string.valueOf(npe));
			ex = npe;
		}
		catch(WebserviceUtil.UnknownSubscriberException use){
			result = new SubscriptionsWebservices.GeneralSubscriptionsWebserviceResult(use.getError());
			TMGUtil.logWebServiceDetail(logId, string.valueOf(use));
			ex = use;
		}
		catch (Exception e){ 
			result = new SubscriptionsWebservices.GeneralSubscriptionsWebserviceResult(new WebserviceUtil.WSException().getError());
			TMGUtil.logWebServiceDetail(logId, string.valueOf(e));
			ex = e;
		} 
		
		if(result != null && result.wsError != null){
			SubscriptionsWebservicesHandlers.sendErrorEmail('DigitalUpdateWebservices.UpdateUsageTracking', logId, result.wsError.errorMessage, ex);
		}

		TMGUtil.logWebServiceResponse(logId, result);
		return result;		
	}

}