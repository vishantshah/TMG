/************************************************************************************
Class Name   : MyNewslettersTest
Author       : Vishant Shah
Created Date : 02/12/2016
Function     : Test Class for MyNewslettersUtility, uses mock response generator
Change Log:
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
* Developer             Date         Description
* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
*************************************************************************************/
@IsTest
public class MyNewslettersUtilityTest {

	private static MyNewsletterWrapper myNLSetup;
	private static final String categoryLifestyle = 'Lifestyle & Entertainment';
	private static final String categoryLuxury    = 'Luxury, Fashion & Beauty';

	@TestSetup private static void setupData(){
        TestDataUtility tdu = new TestDataUtility();
        tdu.CreateCoreApiEndPointSettings();
        tdu.createMyNewslettersEndPointSettings();
    }

	/************************************************************************************
    Method Name  : testGetMyNewsletters
    Author       : Vishant Shah
    Created Date : 02/12/2016
    Function     : Test getting newsletters 
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
	private static testMethod void testGetMyNewsletters(){
        Test.startTest();
        
        IdentityWrapper myIdentity = IdentityUtilityTest.getIdentity();
        
        Test.setMock(HttpCalloutMock.class, new MockResponseGenerator(generateMockNewsletters(), IdentityUtilityTest.HEADER_MAP));
        Map<String, List<MyNewsletterWrapper.Newsletters>> myNL = MyNewslettersUtility.getMyNewsletters(myIdentity);
        
        Integer activeLifestyle = 0, activeLuxury = 0; 
        
        for (MyNewsletterWrapper.Newsletters nl : myNL.get(categoryLifestyle)){
            if (nl.customerStatus == 'Active' )
                activeLifestyle ++;
        }
        
        for (MyNewsletterWrapper.Newsletters nl : myNL.get(categoryLuxury)){
            if (nl.customerStatus == 'Active' )
                activeLuxury ++;
        }
        System.debug(myNL);
        System.assertEquals(3, myNL.size(), 'Size mismatch' );
        System.assertEquals(3, myNL.get(categoryLifestyle).size(), categoryLifestyle);
        System.assertEquals(2, myNL.get(categoryLuxury).size(), categoryLuxury);
        System.assertEquals(2, activeLifestyle, 'active ' + categoryLifestyle);
        System.assertEquals(1, activeLuxury, 'active '  + categoryLuxury);
        
        
        Test.stopTest();
	}

	/************************************************************************************
    Method Name  : generateMockNewsletters
    Author       : Vishant Shah
    Created Date : 02/12/2016
    Function     : generate an array of newsletters
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
	public static String generateMockNewsletters(){
		myNLSetup = new MyNewsletterWrapper();
		myNLSetup.tsNumber = 'TS12346578';
		myNLSetup.newsletters = new List<MyNewsletterWrapper.Newsletters>();
		 
		for (Integer i=0; i < 5; i++){
			MyNewsletterWrapper.Newsletters nl = new MyNewsletterWrapper.Newsletters();

			String id       = i + 'Wine_NL';
			String category = categoryLifestyle;
			String name     = i + 'Wine';

			if (i > 2){
				id       = i + 'BeautyClub_NL';
				category = categoryLuxury;
				name     = i + 'Beauty';
			}

			nl.id             = id;
			nl.category       = category;
			nl.name           = name;
			nl.frequency      = 'Weekly';
			nl.imageUrl       = 'http://www.someimageurl/' + id + '/' + i;
			nl.sampleUrl      = 'http://www.somesampleurl/' + id + '/' + i;
			nl.description    = 'Test Description ' + i;
			nl.hideSample     = false;
			nl.retired        = false;
			nl.customerStatus = Math.mod(i, 2) == 0 ? 'Active' : 'Inactive';
            nl.defaultAccess   = true;
            
			myNLSetup.newsletters.add(nl);
		}

		return JSON.serializePretty(myNLSetup);
	} 
}