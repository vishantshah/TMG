trigger TcodeOnlyOneValidOpenOffer on TCodeManagement__c (before insert) {
	
	// We put all existing Tcode that are Valid and OpenOffer
	List<TCodeManagement__c> liOpenOfferTcodes = new List<TCodeManagement__c>();
	for (TCodeManagement__c tcode : [select id from TCodeManagement__c where type__c ='Open Offer' AND valid__c=true]) {
		liOpenOfferTcodes.add(tcode);
	}
	for (TCodeManagement__c tcode : Trigger.new) {
		// We put all inserted Tcode that are Valid and OpenOffer
		if(tcode.type__c == 'Open Offer' && tcode.Valid__c == true){
			liOpenOfferTcodes.add(tcode);
		}
		// We check that Type__c is set
		if(tcode.Type__c == null || tcode.Type__c == ''){
			tcode.addError('Type is required');
		}
	}
	// We can't have more than one
	if(liOpenOfferTcodes.size() > 1){
		// We then put an error on each valid OpenOffer Tcode
		for (TCodeManagement__c tcode : liOpenOfferTcodes) {
			tcode.addError('Cannot have multiple Valid Open Offer Tcode');
		}
	}
	
}