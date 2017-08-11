/**
* @author Unknown
* @date Unknown
* @description Test class for MarketingPermsPageController
#############Change Log#############
Modified by        Version     Change Date
Wiktor Czykin      1.1         14/04/2016  //changed assertions to fit with the changed code
Pawel Chrzanowski  1.2         19/04/2016  //changed assertions to fit with the changed code
**/
@isTest(SeeAllData=false)
public class MarketingPermsPageControllerTest {
	
	/***************************************************************************************  
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Function - tests almost everything in the controller
    #############Change Log#############
    Modified by        Version     Change Date
    Wiktor Czykin      1.1         14/04/2016    //modified assertions to work with changed code, added few assertions
    Pawel Chrzanowski  1.2         19/04/2016    //modified assertions to work with changed code
    ****************************************************************************************/
	private static testmethod void testMarketingPerms(){
		TestDataUtility tdu = new TestDataUtility();
		tdu.createMarketingPrefSettings();

		Account a = new Account(Firstname='test',Lastname='test');
		insert a;
		
		Account a1sel = [Select a.Id,a.RecordTypeId, a.Permissions_Last_Change_Date__c, a.TMG_Promo_SMS__c, a.TMG_Promo_Post__c, a.TMG_Promo_Phone__c, a.TMG_Promo_Email__c, 
		a.TMG_Partner_Promo_SMS__c, a.TMG_Partner_Promo_Post__c, a.TMG_Partner_Promo_Phone__c, a.TMG_Partner_Promo_Email__c, 
		a.TMG_Loyalty_SMS__c, a.TMG_Loyalty_Phone__c, a.TMG_Loyalty_Mail__c, a.TMG_Loyalty_Email__c, a.Do_Not_Contact__pc From Account a
		where a.Id = :a.Id];
		
		System.assert(a1sel.TMG_Promo_Phone__c==0);
		Account a2 = new Account(Firstname='test',LastName='test',
			TMG_Promo_Email__c=1,
			TMG_Promo_Phone__c=1,
			TMG_Promo_Post__c=1,
			TMG_Promo_SMS__c=1,
			TMG_Partner_Promo_Email__c=0,
			TMG_Partner_Promo_Post__c=0,
			TMG_Partner_Promo_Phone__c=0,
			TMG_Partner_Promo_SMS__c=0,
			TMG_Loyalty_Email__c=0
			);
		insert a2;
		
		Account a2sel = [Select a.Id,a.RecordTypeId, a.Permissions_Last_Change_Date__c, a.TMG_Promo_SMS__c, a.TMG_Promo_Post__c, a.TMG_Promo_Phone__c, a.TMG_Promo_Email__c, 
		a.TMG_Partner_Promo_SMS__c, a.TMG_Partner_Promo_Post__c, a.TMG_Partner_Promo_Phone__c, a.TMG_Partner_Promo_Email__c, 
		a.TMG_Loyalty_SMS__c, a.TMG_Loyalty_Phone__c, a.TMG_Loyalty_Mail__c, a.TMG_Loyalty_Email__c, a.Do_Not_Contact__pc From Account a
		where a.Id = :a.Id];
		
		test.setCurrentPage(Page.MarketingPermsPage);
		Apexpages.Standardcontroller con = new Apexpages.Standardcontroller(a2);
		MarketingPermsPageController ext = new MarketingPermsPageController(con);
		
		System.assert(ext.bShowMarketingPreferences==true);
		System.assert(ext.p2ndemail==true);
		System.assert(ext.p2ndpost==true);
		System.assert(ext.p2ndphone==true);
		System.assert(ext.p2ndSMS==true);
		System.assert(ext.p3rdemail==false);
		System.assert(ext.p3rdpost==false);
		System.assert(ext.p3rdphone==false);
		System.assert(ext.p3rdSMS==false);
		
		//set
		ext.p2ndemail=false;
		ext.p2ndpost=false;
		ext.p2ndphone=false;
		ext.p2ndSMS=false;
		ext.p3rdemail=true;
		ext.p3rdpost=true;
		ext.p3rdphone=true;
		ext.p3rdSMS=true;
		ext.pLoyEmail=true;
		ext.pLoyPhone=true;
		ext.pLoyPost=true;
		ext.pLoySMS=true;
		
		ext.savePerms();
		
		System.assert(ext.p2ndemail==false);
		System.assert(ext.p2ndpost==false);
		System.assert(ext.p2ndphone==false);
		System.assert(ext.p2ndSMS==false);
		System.assert(ext.p3rdemail==true);
		System.assert(ext.p3rdpost==true);
		System.assert(ext.p3rdphone==true);
		System.assert(ext.p3rdSMS==true);
		System.assert(ext.pLoyEmail==true);
		System.assert(ext.pLoyPhone==true);
		System.assert(ext.pLoyPost==true);
		System.assert(ext.pLoySMS==true);
		
		ext.p2ndemail=true;
		ext.p2ndpost=true;
		ext.p2ndphone=true;
		ext.p2ndSMS=true;
		ext.p3rdemail=false;
		ext.p3rdpost=false;
		ext.p3rdphone=false;
		ext.p3rdSMS=false;
		ext.pLoyEmail=false;
		ext.pLoyPhone=false;
		ext.pLoyPost=false;
		ext.pLoySMS=false;
		
		ext.savePerms();
		
		System.assert(ext.p2ndemail==true);
		System.assert(ext.p2ndpost==true);
		System.assert(ext.p2ndphone==true);
		System.assert(ext.p2ndSMS==true);
		System.assert(ext.p3rdemail==false);
		System.assert(ext.p3rdpost==false);
		System.assert(ext.p3rdphone==false);
		System.assert(ext.p3rdSMS==false);
		System.assert(ext.pLoyEmail==false);
		System.assert(ext.pLoyPhone==false);
		System.assert(ext.pLoyPost==false);
		System.assert(ext.pLoySMS==false);
		
		// do not contact
		ext.doNotContact = false;
		ext.doNotContact = true;
		System.assert(ext.doNotContact);
		ext.doNotContact();
		System.assert(ext.doNotContact);
		System.assert(ext.p2ndemail==false);
		
		// no perms - fudge with loyalty email==0
		Account a3 = new Account(Firstname='test',LastName='test',
			TMG_Loyalty_Email__c=0
			);
		insert a3;
		
		con = null;
		ext = null;
		
		con = new Apexpages.Standardcontroller(a3);
		ext = new MarketingPermsPageController(con);
		
		System.assert(ext.p2ndemail==false);
		System.assert(ext.p2ndpost==false);
		System.assert(ext.p2ndphone==false);
		System.assert(ext.p2ndSMS==false);
		System.assert(ext.p3rdemail==false);
		System.assert(ext.p3rdpost==false);
		System.assert(ext.p3rdphone==false);
		System.assert(ext.p3rdSMS==false);

		System.assert(ext.lastUpdateDate!=null);
	}
}