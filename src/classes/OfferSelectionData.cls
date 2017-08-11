/**
* @author Wiktor Czykin
* @date 02/2016
* @description Offer Selection data class
* #############Change Log#############
* Modified by 	Version 	Date
* Michal Kwika	1.1			16/03/2016 //added tCodeId
* Wiktor Czykin 1.2			29/04/2016 //removed sPocWeeklyPrice, added pocSfdcId
**/
public class OfferSelectionData {


	public String sSelectedProductType {get; set;}
	public String sSelectedOffer {get; set;}

	public String sTcode {get; set;}
	public Id sTcodeId {get; set;}
	public Decimal dForcedPrice {get; set;}
	public Id pocSfdcId {get; set;}
	public String sPocId {get; set;}
	public Id mgmGiverId {get; set;}
	public String sMgmGiverCode {get; set;}
	public String sStaffName {get; set;}
	public Id productId	{get; set;}
	public Id selectedAccountId {get; set;}

	public Id agentUserId {get; set;}
	public String sOrderMethod {get; set;}
	public String sTsNumber {get; set;}
	public Boolean bIsActive {get; set;}
	public String sGuid {get; set;}
	public String sSurname {get; set;}
	public String sPostCode {get; set;}
	public String sDiscountPrice {get; set;}
}
