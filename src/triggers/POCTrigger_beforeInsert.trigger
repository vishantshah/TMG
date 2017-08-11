trigger POCTrigger_beforeInsert on POC__c (before insert) {

String HiddenPrice;

for (POC__c poc : trigger.new) {
        If (poc.City__c == null){
            if (poc.Street_Address_Line_2__c != null)
                poc.City__c = poc.Street_Address_Line_2__c;
            else 
                poc.City__c = ' ';
        } 
        Else {
            if (poc.Street_Address_Line_2__c != null)
                poc.Street__c = poc.Street__c + '\n' + poc.Street_Address_Line_2__c;
            else 
                poc.Street__c = poc.Street__c;
        }
        
    //     if (poc.HiddenPOCPrice__c != null){
    //        HiddenPrice = poc.HiddenPOCPrice__c;
    //        poc.POC_Price__c = Decimal.valueOf(HiddenPrice.replaceall('£',''));
    //    }
        
        if(poc.Address_Line_5__c != null)
             poc.State__c = poc.State__c  + ', ' + poc.Address_Line_5__c;
        
        String StateLength = poc.State__c;
             
        if (StateLength != null && StateLength.length() > 20 )
            poc.State__c =  StateLength.substring(0,20);

}

}