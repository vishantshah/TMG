/**
* Author:       Sally ElGhoul (Tquila)
* Date:         28/05/2015
* Description:  A class to contain all the core api resources objects for (body,response....)
* ******************* Change Log *******************
* Modified by       Version     Change Date
Pawel Chrzanowski   1.1         28/04/2016  Added Subscription Upgrade and CoreApiOffersByProductAndFrequency
Gavin Palmer        1.2         05/05/2016  Addded a basePrice field to the OfferCodeDetails wrapper class
Wiktor Czykin		1.3			05/09/2016  Added extra fields to CoreApiOfferDetails wrapper
Pawel Chrzanowski   1.4         18/01/2017  Added field to OfferCodeDetails
**/
global class CoreApiResources {

	//Reset Password - Body Wrapper
	public class ResetPasswordResponseWrapper{
		public String http_code;
		public String message;
		public String internal_error_code;
		public String details_url;
	}

	//SendObjectEvent - Body Wrapper
	public class EventCallOutWrapper{
		public String event;
		public String objectType;
		public String id;

		public EventCallOutWrapper(String eventValue, String objectTypeValue, String idValue){
			this.event = eventValue;
			this.objectType	= objectTypeValue;
			this.id = idValue;
		}
	}

	//Upgrade - Body Wrapper
	public class UpgradeCallOutWrapper{
		public String offerCode;
		public String effectiveDate;
		public String priceChangeNumber;

		public UpgradeCallOutWrapper(String offerCodeValue, String effectiveDateValue, String priceChangeNumberValue){
			this.offerCode = offerCodeValue;
			this.effectiveDate	= effectiveDateValue;
			this.priceChangeNumber = priceChangeNumberValue;
		}
	}

	//Put Offer - Body Wrapper
	public class PutOfferCallOutWrapper{
		public String offerCode;
		public String effectiveDate;
		public String priceChangeNumber;

		public PutOfferCallOutWrapper(String offerCodeValue, String effectiveDateValue, String priceChangeNumberValue){
			this.offerCode = offerCodeValue;
			this.effectiveDate	= effectiveDateValue;
			this.priceChangeNumber = priceChangeNumberValue;
		}
	}

	//Offer Code Details - Response Wrapper
	global class OfferCodeDetails{
		public String name {get;set;}
		public String description {get;set;}
		public String longDescription {get;set;}
		public Boolean containsFreeTrial {get;set;}
		public Boolean isRestricted {get;set;}
		public String tmgId	{get;set;}
		public String friendlyName {get;set;}
    	public Decimal basePrice {get;set;}
		public List<DiscountDetails> discounts {get;set;}
	}
	global class DiscountDetails{
		public String  billingPeriod{get;set;}
		public Integer numberOfPeriods{get;set;}
		public Decimal discountAmount{get;set;}
	}

	//Tcode Offer - Response wrapper
	global class CoreApiOffers{
		public List<CoreApiOfferDetails> offers {get;set;}
	}

	global class CoreApiOfferDetails{
		public String name {get;set;}
		public String description {get;set;}
		public String longDescription {get;set;}
		public Boolean containsFreeTrial {get;set;}
		public Boolean isRestricted {get;set;}
		public String friendlyName {get;set;}
		public String tmgId	{get;set;}
		public String frequency	{get;set;}
		public String product {get;set;}
        public Decimal weeklyAdvertisedPrice {get;set;}
        public String subDescription {get;set;}
	}

	//Offers by Product and Frequency - Response Wrapper
	global class CoreApiOffersByProductAndFrequency{
		public List<CoreApiOfferByProductAndFrequencyDetails> offers {get;set;}
	}
	
	global class CoreApiOfferByProductAndFrequencyDetails{
		public String tmgId	{get;set;}
		public String name {get;set;}
		public String description {get;set;}
		public Boolean containsFreeTrial {get;set;}
		public List<DiscountDetails> discounts {get;set;}
		public String friendlyName {get;set;}
		public String frequency	{get;set;}
		public String product {get;set;}
	}
}
