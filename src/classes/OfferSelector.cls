/**
* @author Unknown
* @date Unknown
* @description Offer Selector abstract class
* #############Change Log#############
**/
public abstract class OfferSelector{

	public OfferSelectionData offerSelection{get;set;}
	
	public abstract PageReference processOfferSelection();
	public abstract OfferSelector getSelf();

}