/**
* @author Unknown
* @date Unknown
* @description Wrapper class for retailers search result
#############Change Log#############
Modified by     Version     Change Date
**/
public class ActiveRetailers {
	public Integer ValidSubsCount{get;set;}
	public Account Retailer{get;set;}
	
	public ActiveRetailers(){
		Retailer = new Account();
	}
	
}