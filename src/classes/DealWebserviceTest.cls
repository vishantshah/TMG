@isTest(SeeAllData=false)
public class DealWebserviceTest {

	private static void insertPricingOptions(String pricingPartnerId) {
		insert new Pricing_Options__c(Partner_Unique_ID__c = pricingPartnerId);
	}
	
	private  static void insertPartnerActionRequests(String requestCode) {
		Partner_Action_Requests__c p = new Partner_Action_Requests__c();
		p.Name = requestCode;
		insert p;
	}
	public static testMethod void testIsActiveToken(){
		DealWebservice.token validTokenValue = new DealWebservice.token('441243124388','vodafone');
		DealWebservice.token invalidTokenValue = new DealWebservice.token('4412431999','vodafone');
		Account a = new Account(Title__c='Mr.', lastname='testIsActiveToken', token_source__c='vodafone', partner_token__c='441243124388');
		insert a;
		
		// test success    
		DealWebservice.IsActiveTokenResult validWebserviceCall = DealWebservice.IsActiveToken(validTokenValue);
		
		// test failure
		DealWebservice.IsActiveTokenResult invalidWebserviceCall = DealWebservice.IsActiveToken(invalidTokenValue);
	}
  
  
 	public static testMethod void testPartnerAction_DN(){
	
		insertPricingOptions('p10346Telegraph');
		insertPartnerActionRequests('DN');
		
		DealWebservice.PartnerActionRequest validPartnerActionRequest_DN = new DealWebservice.PartnerActionRequest('DN','{"oldStatus":"Inactive","oldPackageId":"p10346Telegraph","oldGraceStatus":"GraceExpired","newStatus":"INACTIVE","newPackageId":"p10346Telegraph","newGraceStatus":"GraceExpired"}', 'Change');

		Pricing_Options__c pricingOption = [Select Id, Name, Partner_Unique_Id__c from Pricing_Options__c where Partner_Unique_Id__c = 'p10346Telegraph'];

		// setup a test partner subscriber
		Account a = new Account(Title__c='Mr.', lastname='testPartnerAction', token_source__c='vodafone', partner_token__c='441243124388', Pricing_Option__c = pricingOption.Id);
		insert a;
		
		a = [Select Id, Subscriber_Number_Static__c, Partner_Token__c from Account where Partner_Token__c = :a.Partner_Token__c];
		String TSNumber = a.Subscriber_Number_static__c;

		// subscriberInfo
		DealWebservice.SubscriberInfo subscriberInfo = new DealWebservice.SubscriberInfo(a.Subscriber_Number_Static__c);

		// test success    
		DealWebservice.PartnerActionResponse DNWebserviceCall = DealWebservice.PartnerAction(validPartnerActionRequest_DN, subscriberInfo);
  	}
  
 	public static testMethod void testPartnerAction_SG(){
	
		insertPricingOptions('p10346Telegraph');
		insertPartnerActionRequests('SG');
		
		DealWebservice.PartnerActionRequest validPartnerActionRequest_SG = new DealWebservice.PartnerActionRequest('SG', '{"oldStatus":"active","oldPackageId":"p10346Telegraph","oldGraceStatus":"GraceExpired","newStatus":"INACTIVE","newPackageId":"p10346Telegraph","newGraceStatus":"InGrace"}', 'Change');

		Pricing_Options__c pricingOption = [Select Id, Name, Partner_Unique_Id__c from Pricing_Options__c where Partner_Unique_Id__c = 'p10346Telegraph'];

		// setup a test partner subscriber
		Account a = new Account(Title__c='Mr.', lastname='testPartnerAction', token_source__c='vodafone', partner_token__c='441243124388', Pricing_Option__c = pricingOption.Id);
		insert a;
		
		a = [Select Id, Subscriber_Number_Static__c, Partner_Token__c from Account where Partner_Token__c = :a.Partner_Token__c];
		String TSNumber = a.Subscriber_Number_static__c;

		// subscriberInfo
		DealWebservice.SubscriberInfo subscriberInfo = new DealWebservice.SubscriberInfo(a.Subscriber_Number_Static__c);

		DealWebservice.PartnerActionResponse SGWebserviceCall = DealWebservice.PartnerAction(validPartnerActionRequest_SG, subscriberInfo); 
	}
	
 	public static testMethod void testPartnerAction_EG(){
	
		insertPricingOptions('p10346Telegraph');
		insertPartnerActionRequests('EG');
		
		DealWebservice.PartnerActionRequest validPartnerActionRequest_EG = new DealWebservice.PartnerActionRequest('EG','{"oldStatus":"active","oldPackageId":"p10346Telegraph","oldGraceStatus":"InGrace","newStatus":"INACTIVE","newPackageId":"p10346Telegraph","newGraceStatus":"GraceExpired"}', 'Change');

		Pricing_Options__c pricingOption = [Select Id, Name, Partner_Unique_Id__c from Pricing_Options__c where Partner_Unique_Id__c = 'p10346Telegraph'];

		// setup a test partner subscriber
		Account a = new Account(Title__c='Mr.', lastname='testPartnerAction', token_source__c='vodafone', partner_token__c='441243124388', Pricing_Option__c = pricingOption.Id);
		insert a;
		
		a = [Select Id, Subscriber_Number_Static__c, Partner_Token__c from Account where Partner_Token__c = :a.Partner_Token__c];
		String TSNumber = a.Subscriber_Number_static__c;

		// subscriberInfo
		DealWebservice.SubscriberInfo subscriberInfo = new DealWebservice.SubscriberInfo(a.Subscriber_Number_Static__c);

		DealWebservice.PartnerActionResponse EGWebserviceCall = DealWebservice.PartnerAction(validPartnerActionRequest_EG, subscriberInfo);
	}      

 	public static testMethod void testPartnerAction_RG(){
	
		insertPricingOptions('p10346Telegraph');
		insertPartnerActionRequests('RG');
		
		DealWebservice.PartnerActionRequest validPartnerActionRequest_RG = new DealWebservice.PartnerActionRequest('RG','{"oldStatus":"Active","oldPackageId":"p10346Telegraph","oldGraceStatus":"InGrace","newStatus":"ACTIVE","newPackageId":"p10346Telegraph","newGraceStatus":"NotInGrace"}', 'Change');

		Pricing_Options__c pricingOption = [Select Id, Name, Partner_Unique_Id__c from Pricing_Options__c where Partner_Unique_Id__c = 'p10346Telegraph'];

		// setup a test partner subscriber
		Account a = new Account(Title__c='Mr.', lastname='testPartnerAction', token_source__c='vodafone', partner_token__c='441243124388', Pricing_Option__c = pricingOption.Id);
		insert a;
		
		a = [Select Id, Subscriber_Number_Static__c, Partner_Token__c from Account where Partner_Token__c = :a.Partner_Token__c];
		String TSNumber = a.Subscriber_Number_static__c;

		// subscriberInfo
		DealWebservice.SubscriberInfo subscriberInfo = new DealWebservice.SubscriberInfo(a.Subscriber_Number_Static__c);

		DealWebservice.PartnerActionResponse RGWebserviceCall = DealWebservice.PartnerAction(validPartnerActionRequest_RG, subscriberInfo);    
	}
  
 	public static testMethod void testPartnerAction_PC(){
	
		insertPricingOptions('p10346Telegraph');
		insertPartnerActionRequests('PC');
		
		DealWebservice.PartnerActionRequest validPartnerActionRequest_PC = new DealWebservice.PartnerActionRequest('PC','{"oldStatus":"active","oldPackageId":"p10346Telegraph","oldGraceStatus":"NotInGrace","newStatus":"ACTIVE","newPackageId":"p62641Telegraph","newGraceStatus":"NotInGrace"}', 'Change'); 
		Pricing_Options__c pricingOption = [Select Id, Name, Partner_Unique_Id__c from Pricing_Options__c where Partner_Unique_Id__c = 'p10346Telegraph'];

		// setup a test partner subscriber
		Account a = new Account(Title__c='Mr.', lastname='testPartnerAction', token_source__c='vodafone', partner_token__c='441243124388', Pricing_Option__c = pricingOption.Id);
		insert a;
		
		a = [Select Id, Subscriber_Number_Static__c, Partner_Token__c from Account where Partner_Token__c = :a.Partner_Token__c];
		String TSNumber = a.Subscriber_Number_static__c;

		// subscriberInfo
		DealWebservice.SubscriberInfo subscriberInfo = new DealWebservice.SubscriberInfo(a.Subscriber_Number_Static__c);

		DealWebservice.PartnerActionResponse PCWebserviceCall = DealWebservice.PartnerAction(validPartnerActionRequest_PC, subscriberInfo);
	}
  
 	public static testMethod void testPartnerAction_PC_SG(){
	
		insertPricingOptions('p10346Telegraph');
		insertPartnerActionRequests('PC_SG');
		
	   	DealWebservice.PartnerActionRequest validPartnerActionRequest_PC_SG = new DealWebservice.PartnerActionRequest('PC_SG','{"oldStatus":"active","oldPackageId":"p10346Telegraph","oldGraceStatus":"NotInGrace","newStatus":"INACTIVE","newPackageId":"p62641Telegraph","newGraceStatus":"InGrace"}', 'Change');
	 
		Pricing_Options__c pricingOption = [Select Id, Name, Partner_Unique_Id__c from Pricing_Options__c where Partner_Unique_Id__c = 'p10346Telegraph'];

		// setup a test partner subscriber
		Account a = new Account(Title__c='Mr.', lastname='testPartnerAction', token_source__c='vodafone', partner_token__c='441243124388', Pricing_Option__c = pricingOption.Id);
		insert a;
		
		a = [Select Id, Subscriber_Number_Static__c, Partner_Token__c from Account where Partner_Token__c = :a.Partner_Token__c];
		String TSNumber = a.Subscriber_Number_static__c;

		// subscriberInfo
		DealWebservice.SubscriberInfo subscriberInfo = new DealWebservice.SubscriberInfo(a.Subscriber_Number_Static__c);

		DealWebservice.PartnerActionResponse PC_SGWebserviceCall = DealWebservice.PartnerAction(validPartnerActionRequest_PC_SG, subscriberInfo);
	}
  
 	public static testMethod void testPartnerAction_PC_EG(){
	
		insertPricingOptions('p10346Telegraph');
		insertPartnerActionRequests('PC_EG');
		
		DealWebservice.PartnerActionRequest validPartnerActionRequest_PC_EG = new DealWebservice.PartnerActionRequest('PC_EG','{"oldStatus":"active","oldPackageId":"p10346Telegraph","oldGraceStatus":"InGrace","newStatus":"INACTIVE","newPackageId":"p62641Telegraph","newGraceStatus":"GraceExpired"}', 'Change');

		Pricing_Options__c pricingOption = [Select Id, Name, Partner_Unique_Id__c from Pricing_Options__c where Partner_Unique_Id__c = 'p10346Telegraph'];

		// setup a test partner subscriber
		Account a = new Account(Title__c='Mr.', lastname='testPartnerAction', token_source__c='vodafone', partner_token__c='441243124388', Pricing_Option__c = pricingOption.Id);
		insert a;
		
		a = [Select Id, Subscriber_Number_Static__c, Partner_Token__c from Account where Partner_Token__c = :a.Partner_Token__c];
		String TSNumber = a.Subscriber_Number_static__c;

		// subscriberInfo
		DealWebservice.SubscriberInfo subscriberInfo = new DealWebservice.SubscriberInfo(a.Subscriber_Number_Static__c);

		DealWebservice.PartnerActionResponse PC_EGWebserviceCall = DealWebservice.PartnerAction(validPartnerActionRequest_PC_EG, subscriberInfo);            	
  	}

 	public static testMethod void testPartnerAction_PC_RG(){
	
		insertPricingOptions('p10346Telegraph');
		insertPartnerActionRequests('PC_RG');
		
	   	DealWebservice.PartnerActionRequest validPartnerActionRequest_PC_RG = new DealWebservice.PartnerActionRequest('PC_RG','{"oldStatus":"active","oldPackageId":"p10346Telegraph","oldGraceStatus":"InGrace","newStatus":"ACTIVE","newPackageId":"p62641Telegraph","newGraceStatus":"NotInGrace"}', 'Change');    

		Pricing_Options__c pricingOption = [Select Id, Name, Partner_Unique_Id__c from Pricing_Options__c where Partner_Unique_Id__c = 'p10346Telegraph'];

		// setup a test partner subscriber
		Account a = new Account(Title__c='Mr.', lastname='testPartnerAction', token_source__c='vodafone', partner_token__c='441243124388', Pricing_Option__c = pricingOption.Id);
		insert a;
		
		a = [Select Id, Subscriber_Number_Static__c, Partner_Token__c from Account where Partner_Token__c = :a.Partner_Token__c];
		String TSNumber = a.Subscriber_Number_static__c;

		// subscriberInfo
		DealWebservice.SubscriberInfo subscriberInfo = new DealWebservice.SubscriberInfo(a.Subscriber_Number_Static__c);

		DealWebservice.PartnerActionResponse PC_RGWebserviceCall = DealWebservice.PartnerAction(validPartnerActionRequest_PC_RG, subscriberInfo);
  	}
}