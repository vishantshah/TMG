@isTest(SeeAllData=false)
private class TcodeOnlyOneValidOpenOfferTest {
    private static testmethod void testValidOpenOffer_1(){
        List<TCodeManagement__c> liTcodes = new List<TCodeManagement__c>();//= [select id from TCodeManagement__c];
        //delete liTcodes;
        try{
            delete ([Select Id from TCodeManagement__c where type__c='Open Offer' ]);
        }
        catch(DmlException e){
        }
        TCodeManagement__c tcm1 = new TCodeManagement__c( name='0A5A', Price__c=4.5, Digital_Monthly_Price__c=2.5, Digital_Yearly_Price__c=62.3, Description__c='Something about tcode 1', valid__c=true, type__c='Open Offer' );
        insert tcm1;
        
        TCodeManagement__c tcm2 = new TCodeManagement__c( name='0A5B', Price__c=4.5, Digital_Monthly_Price__c=2.5, Digital_Yearly_Price__c=62.3, Description__c='Something about tcode 1', valid__c=true, type__c='Open Offer' );
        TCodeManagement__c tcm3 = new TCodeManagement__c( name='0A5B', Price__c=4.5, Digital_Monthly_Price__c=2.5, Digital_Yearly_Price__c=62.3, Description__c='Something about tcode 1', valid__c=true, type__c='Open Offer' );
        liTcodes = new List<TCodeManagement__c>{tcm2, tcm3};
        
        System.DmlException dmle;
        try{
            insert liTcodes;
        }
        catch(DmlException e){
             dmle = e;
        }
        System.assert(dmle.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION'));
        System.assert(dmle.getMessage().contains('Cannot have multiple Valid Open Offer Tcode'));
    }
    
    private static testmethod void testValidOpenOffer_2(){
        List<TCodeManagement__c> liTcodes = new List<TCodeManagement__c>();//= [select id from TCodeManagement__c];
        //delete liTcodes;
        try{
            delete ([Select Id from TCodeManagement__c where type__c='Open Offer' ]);
        }
        catch(DmlException e){
        }
        TCodeManagement__c tcm1 = new TCodeManagement__c( name='0A5A', Price__c=4.5, Digital_Monthly_Price__c=2.5, Digital_Yearly_Price__c=62.3, Description__c='Something about tcode 1', valid__c=false, type__c='Open Offer' );
        insert tcm1;
        
        TCodeManagement__c tcm2 = new TCodeManagement__c( name='0A5B', Price__c=4.5, Digital_Monthly_Price__c=2.5, Digital_Yearly_Price__c=62.3, Description__c='Something about tcode 1', valid__c=true, type__c='Open Offer' );
        TCodeManagement__c tcm3 = new TCodeManagement__c( name='0A5B', Price__c=4.5, Digital_Monthly_Price__c=2.5, Digital_Yearly_Price__c=62.3, Description__c='Something about tcode 1', valid__c=false, type__c='Open Offer' );
        liTcodes = new List<TCodeManagement__c>{tcm2, tcm3};
        
        System.DmlException dmle;
        try{
            insert liTcodes;
        }
        catch(DmlException e){
             dmle = e;
        }
        // No exception
        System.assertEquals(null, dmle);
    }
    
    private static testmethod void testValidOpenOffer_3(){
        List<TCodeManagement__c> liTcodes = new List<TCodeManagement__c>();//= [select id from TCodeManagement__c];
        //delete liTcodes;
        try{
            delete ([Select Id from TCodeManagement__c where type__c='Open Offer' ]);
        }
        catch(DmlException e){
        }
        TCodeManagement__c tcm1 = new TCodeManagement__c( name='0A5A', Price__c=4.5, Digital_Monthly_Price__c=2.5, Digital_Yearly_Price__c=62.3, Description__c='Something about tcode 1', valid__c=false, type__c='Open Offer' );
        insert tcm1;
        
        TCodeManagement__c tcm2 = new TCodeManagement__c( name='0A5B', Price__c=4.5, Digital_Monthly_Price__c=2.5, Digital_Yearly_Price__c=62.3, Description__c='Something about tcode 1', valid__c=true, type__c='Open Offer' );
        TCodeManagement__c tcm3 = new TCodeManagement__c( name='0A5B', Price__c=4.5, Digital_Monthly_Price__c=2.5, Digital_Yearly_Price__c=62.3, Description__c='Something about tcode 1', valid__c=true, type__c='Promotional' );
        liTcodes = new List<TCodeManagement__c>{tcm2, tcm3};
        
        System.DmlException dmle;
        try{
            insert liTcodes;
        }
        catch(DmlException e){
             dmle = e;
        }
        // No exception
        System.assertEquals(null, dmle);
    }

    // Check Type__C cannot be ''
    private static testmethod void testTypeRequired_1(){
        List<TCodeManagement__c> liTcodes = new List<TCodeManagement__c>();//= [select id from TCodeManagement__c];
        //delete liTcodes;
        try{
            delete ([Select Id from TCodeManagement__c where type__c='Open Offer' ]);
        }
        catch(DmlException e){
        }
        TCodeManagement__c tcm1 = new TCodeManagement__c( name='0A5A', Price__c=4.5, Digital_Monthly_Price__c=2.5, Digital_Yearly_Price__c=62.3, Description__c='Something about tcode 1', valid__c=false, type__c='Open Offer' );
        insert tcm1;
        
        TCodeManagement__c tcm2 = new TCodeManagement__c( name='0A5B', Price__c=4.5, Digital_Monthly_Price__c=2.5, Digital_Yearly_Price__c=62.3, Description__c='Something about tcode 1', valid__c=true, type__c='' );
        TCodeManagement__c tcm3 = new TCodeManagement__c( name='0A5C', Price__c=4.5, Digital_Monthly_Price__c=2.5, Digital_Yearly_Price__c=62.3, Description__c='Something about tcode 1', valid__c=true, type__c='Promotional' );
        liTcodes = new List<TCodeManagement__c>{tcm2, tcm3};
        
        System.DmlException dmle;
        try{
            insert liTcodes;
        }
        catch(DmlException e){
             dmle = e;
        }
        // Type is required
        System.assert(dmle.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION'));
        System.assert(dmle.getMessage().contains('Type is required'));
    }
    
    // Check Type__C cannot be null
    private static testmethod void testTypeRequired_2(){
        List<TCodeManagement__c> liTcodes = new List<TCodeManagement__c>();//= [select id from TCodeManagement__c];
        //delete liTcodes;
        try{
            delete ([Select Id from TCodeManagement__c where type__c='Open Offer' ]);
        }
        catch(DmlException e){
        }
        TCodeManagement__c tcm1 = new TCodeManagement__c( name='0A5A', Price__c=4.5, Digital_Monthly_Price__c=2.5, Digital_Yearly_Price__c=62.3, Description__c='Something about tcode 1', valid__c=false, type__c='Open Offer' );
        insert tcm1;
        
        TCodeManagement__c tcm2 = new TCodeManagement__c( name='0A5B', Price__c=4.5, Digital_Monthly_Price__c=2.5, Digital_Yearly_Price__c=62.3, Description__c='Something about tcode 1', valid__c=true, type__c=null );
        TCodeManagement__c tcm3 = new TCodeManagement__c( name='0A5C', Price__c=4.5, Digital_Monthly_Price__c=2.5, Digital_Yearly_Price__c=62.3, Description__c='Something about tcode 1', valid__c=true, type__c='Promotional' );
        liTcodes = new List<TCodeManagement__c>{tcm2, tcm3};
        
        System.DmlException dmle;
        try{
            insert liTcodes;
        }
        catch(DmlException e){
             dmle = e;
        }
        // Type is required
        System.assert(dmle.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION'));
        System.assert(dmle.getMessage().contains('Type is required'));
    }
}