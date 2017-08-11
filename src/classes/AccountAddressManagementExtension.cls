public without sharing class AccountAddressManagementExtension {

	// dave branch test
    private ApexPages.StandardController controller;
    private String currentCountryCode; 
    public Boolean editMode {get;set;}
    public Account acc {get; private set;}
    private String stateCode;
    public String AddrType {get;set;}
    
    
    public AccountAddressManagementExtension(ApexPages.StandardController controller) {
        
        String browserType = Apexpages.currentPage().getHeaders().get('USER-AGENT'); //gets the browser name and detail
        if(browserType != null && browserType.contains('MSIE')){
            Apexpages.currentPage().getHeaders().put('X-UA-Compatible', 'IE=8');
            //sets the type to IE8 for every version of IE browser
        }
        //sets the type to IE8 for every version of IE browser
        
        this.controller = controller;
        
        //MIrfan@Appirio, commented below code to refract as another method as loadAccount();
        /*
        this.acc = [SELECT Id, PersonMailingStreet, PersonMailingCity, PersonMailingState, 
            PersonMailingPostalCode, PersonMailingCountry FROM Account WHERE Id = :controller.getId()];
        this.currentCountryCode = this.Country = this.acc.PersonMailingCountry;
        this.editMode = false;
        */
        
        loadAccount();
    }
    
    //MIrfan@Appirio 100412; Jira:PP-1256
    private void loadAccount()
    {
        
        try{
        this.acc = [SELECT Id,recordTypeId, IsPersonAccount,PersonMailingStreet, PersonMailingCity, PersonMailingState, 
            PersonMailingPostalCode, PersonMailingCountry FROM Account WHERE Id = :controller.getId()];
        this.currentCountryCode = this.Country = this.acc.PersonMailingCountry;
        this.stateCode = this.acc.PersonMailingState;
        this.editMode = false;    
        
            this.AddrType=(this.currentCountryCode=='GB')?'UK':'NONUK';
            //this.isUKSearch =(this.currentCountryCode=='GB')?true:false;
        
        }catch(Exception ex)
        {

            System.debug('Exception in loadAccount'+ex.getMessage());
        }
    }
    
// Variables to store country selected by user  
    public String Country {get; set;}  
    
    public List<SelectOption> getCountries(){
        List<SelectOption> liOptions = new List<SelectOption>();
        liOptions.add(new SelectOption('', '--None--'));
        for(Country_Codes__c country:[SELECT name, Country_Name__c FROM Country_Codes__c ORDER BY Display_Order__c, Country_Name__c ASC]){
            liOptions.add(new SelectOption(country.name, country.Country_Name__c));
        }
        return liOptions;
    }
    
    public PageReference switchToEdit(){
        editMode = true;
        return null;
    }
    
    public PageReference switchToEditAgain(){
        this.acc = [SELECT Id,recordTypeId, PersonMailingStreet, PersonMailingCity, PersonMailingState, 
            PersonMailingPostalCode, PersonMailingCountry FROM Account WHERE Id = :this.acc.Id];
        editMode = false;
        return null;
    }
    
    public String getCountryName(){
        String country = '';
        try{
            country = Country_Codes__c.getInstance(this.currentCountryCode.toUpperCase()).Country_Name__c;
        }catch(System.NullPointerException e){
            System.debug('### No country code custom setting can be found');
        }
        return country;
    }

    public PageReference SaveAddress()
    { 
    	//Sally ElGhoul - Validate that postal code is not empty in case of registrant accounts
    	if(isRegistrantAccount && string.isempty(acc.PersonMailingPostalCode) && acc.PersonMailingCountry != null && acc.PersonMailingCountry.equalsIgnoreCase('GB') ){
    		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, Label.Error_Empty_Postal_Code));    
            return null;
    	}
    	
        //MIrfan@Appirio added country condition to check Postcode only if GB.
        if(!TMGUtil.isDataValid(acc.PersonMailingPostalCode) && acc.PersonMailingCountry != null && acc.PersonMailingCountry.equalsIgnoreCase('GB')){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Please enter a valid postcode.'));    
            return null;
        } 
             
        try{
            update acc;
            
            //editMode = false;
            //MIrfan@Appirio 100412, Jira:PP-1256
            loadAccount();
            
        }catch(System.Exception e){
            ApexPages.addMessages(e);
        }
 
        return null;
    }
    
    /*************************************************************************************** 
    Developer   Sally ElGhoul (Tquila)
    Date        27/07/2015
    Function    this function is called to get the list of countries 
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    public List<SelectOption> getStates(){
        List<SelectOption> liOptions = new List<SelectOption>();
        liOptions.add(new SelectOption('', Constants.NONE_PICKLIST_VALUE));
        for(State_Codes__c stateObj:[SELECT State_Name__c, Name FROM State_Codes__c where Country_Code__c=:acc.PersonMailingCountry ORDER BY Display_Order__c, State_Name__c ASC]){
            liOptions.add(new SelectOption(stateObj.Name, stateObj.State_Name__c));
        }
        return liOptions;
    }
    
   /*************************************************************************************** 
    Developer   Sally ElGhoul (Tquila)
    Date        27/07/2015
    Function    Check if postal code is required 
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
   public boolean isPostalCodeRequired{
      get{
        if(acc.PersonMailingCountry==constants.UNITED_KINGDOM_COUNTRY_TWO_CODE_VALUE){
          return true;
        } 
        return false;
      } set;
   }
   
   /*************************************************************************************** 
    Developer   Sally ElGhoul (Tquila)
    Date        27/07/2015
    Function    Check if State is required 
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
   public boolean isStateRequired{
      get{
        if(acc.PersonMailingCountry==constants.COUNTRY_UNITED_STATES_TWO_LETTERS_CODE || acc.PersonMailingCountry==constants.COUNTRY_CANADA_TWO_LETTERS_CODE){
          return true;
        } 
        return false;
      } set;
   }
   
   /*************************************************************************************** 
    Developer   Sally ElGhoul (Tquila)
    Date        27/07/2015
    Function    Check if account is registrant record type
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
   public boolean isRegistrantAccount{
      get{
        if(acc.recordTypeId==RegistrantRecordTypeId){
          return true;
        } 
        return false;
      } set;
   }
   
   /*************************************************************************************** 
    Developer   Sally ElGhoul (Tquila)
    Date        27/07/2015
    Function    Get the registrant record type id 
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    public string RegistrantRecordTypeId{
        get{
            return RecordTypeUtility.getRecordTypeId(Account.SObjectType, Constants.ACCOUNT_REGISTRANT_RECORD_TYPE_NAME, Account.class.getName()); 
        }
    }
    
     /*************************************************************************************** 
    Developer   Sally ElGhoul (Tquila)
    Date        27/07/2015
    Function    this function is called to refresh the UI
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/  
     public pageReference RefreshUI(){
        
      acc.PersonMailingState='';
      if(this.acc.PersonMailingCountry == 'GB')
      {
        this.AddrType='UK';
      }else{
        this.AddrType='NONUK';
      }
      return null;
    }

     /*************************************************************************************** 
    Developer   Jayan Sande (Tquila)
    Date        19/08/2015
    Function    this function is called to refresh the UI
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/    
    public String getStateName()
    {
        String sname='';
       
             /*if(acc.PersonMailingCountry=='GB')
             {
                sname = this.acc.PersonMailingState;

             }
             else
             {
                sname = State_Codes__c.getInstance(this.stateCode.toUpperCase()).State_Name__c;
             }*/
             if(acc.PersonMailingCountry==constants.COUNTRY_UNITED_STATES_TWO_LETTERS_CODE || acc.PersonMailingCountry==constants.COUNTRY_CANADA_TWO_LETTERS_CODE)
             {
                 Try{
                 sname = State_Codes__c.getInstance(this.stateCode.toUpperCase()).State_Name__c;
                 }catch(NullPointerException nEx){}
                 
                 if(!String.isEmpty(acc.PersonMailingState) && String.isEmpty(sname))
                 {
                    sname =this.acc.PersonMailingState;
                 }
            }else{
                    sname =this.acc.PersonMailingState;

            }
        
            return sname;
    }

     /*************************************************************************************** 
    Developer   Jayan Sande (Tquila)
    Date        19/08/2015
    Function    this function is called to refresh the UI
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/  

    public boolean isUKSearch{

       get{
            return(this.AddrType=='UK')?true:false;
            
        }
        set;
    }

    /*************************************************************************************** 
    Developer   Jayant Sande (Accenture)
    Date        19/08/2015
    Function    this function is rerendering UK/non UK form
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/ 
    public PageReference RenderAddressType()
    {

        System.debug('AddressType#'+this.AddrType);
        if(this.AddrType=='UK')
        {
         
         this.acc.PersonMailingCountry='GB';  
         
         this.acc.PersonMailingState='';
         
        }else
        {
            this.acc.PersonMailingCountry='US';
            
        }
            
        return null;
        
    }
}