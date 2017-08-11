@isTest
public class POCTriggerTest {

    static testmethod void POCTriggertest1() {
        // test the elements of the trigger
        /* 
        1. poc.Street__c = poc.Street__c + ', ' + poc.Street_Address_Line_2__c;
    
        2. HiddenPrice = poc.HiddenPOCPrice__c;
        poc.POC_Price__c = Decimal.valueOf(HiddenPrice.replaceall('£',''));
  
        3. if(poc.Address_Line_5__c != null)
           poc.State__c = poc.State__c  + ', ' + poc.Address_Line_5__c;
    
    String StateLength = poc.State__c;
       
        4. if (StateLength.length() > 20 )
          poc.State__c =   StateLength.substring(0,20); */
      TCodeManagement__c newtcodePOC = new TCodeManagement__c(Type__c='POC', Valid__c = true,name='799T', Description__c='testPOC', Price__c=6.50, Allow52Week__c=true, Allow26Week__c=true, AllowDD__c=true);
        insert newtcodePOC;
        
      POC__c test1 = new POC__c(TCodeManagement__c=newtcodePOC.id,
            POC_ID__c='TST702346',
                          Country__c='UK',
                          State__c='London',
                          Address_Line_5__c = 'Line 5 is a long line',
                          City__c='lon',
                          Street_Address_Line_2__c='Test 2',
                          HiddenPOCPrice__c='£4.00', 
                          Street__c='Conyers',
                          title__c='Mr',
                          PostalCode__c = 'SW16 6OY', 
                          FirstName__c ='Steve J', 
                          LastName__c = 'Fouracre', 
                          ExpiryDate__c=System.Today().adddays(30));
        insert test1;
        
        
      
    }
    
    static testmethod void POCTriggertest2() {
      TCodeManagement__c newtcodePOC = new TCodeManagement__c(Type__c='POC', Valid__c = true,name='799T', Description__c='testPOC', Price__c=6.50, Allow52Week__c=true, Allow26Week__c=true, AllowDD__c=true);
        insert newtcodePOC;
        
      POC__c test1 = new POC__c(TCodeManagement__c=newtcodePOC.id,POC_ID__c='TST702346',
                          PostalCode__c = 'SW16 6OY', 
                          LastName__c = 'Fouracre' );
        insert test1;
        System.assertNotEquals(test1.id, null);
    }


}