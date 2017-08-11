/**
* @author Unknown
* @date Unknown
* @description Test class for ActiveRetailers wrapper - contents moved from the wrapper itself
#############Change Log#############
Modified by     Version     Change Date
**/
@isTest
private class ActiveRetailersTest {
	private static testmethod void TestActiveRetailers(){
		ActiveRetailers actret = new ActiveRetailers();
		system.assertNotEquals(null,actret.Retailer);
	}
}