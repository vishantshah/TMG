public class FulfillmentPlanManagerController {

    private set<string> AvailableEntitlements;
    public list<SelectOption> AvailableEntitlementsForDisplay{
        get{
            list<SelectOption> displayData = new list<SelectOption>();
            
            for(string entitlement : AvailableEntitlements){
                displayData.add(new SelectOption(entitlement, entitlement));
            }
            
            //Sort alphabetically as it's output
            return SelectOptionSort.SortOptionList(displayData);
        }
    }
    public string[] AvailableSelected {get; set;}
    
    public set<string> CurrentEntitlements;
    public list<SelectOption> CurrentEntitlementsForDisplay{
        get{
            list<SelectOption> displayData = new list<SelectOption>();
            
            for(string entitlement : CurrentEntitlements){
                displayData.add(new SelectOption(entitlement, entitlement));
            }
            
            //Sort alphabetically as it's output
            return SelectOptionSort.SortOptionList(displayData);
        }
    }
    public string[] CurrentSelected {get; set;}
    
    private FulfillmentPlan__c FulfillmentPlan;
    

    public FulfillmentPlanManagerController(ApexPages.StandardController controller) {
        FulfillmentPlan = (FulfillmentPlan__c)controller.getRecord();
        
        AvailableSelected = new String[]{};
        CurrentSelected = new String[]{};
        
        loadCurrentEntitlements();
        loadAvailableEntitlementsPickListData();
    }
   
    private void loadCurrentEntitlements(){
        
        CurrentEntitlements = new set<string>();
        if(FulfillmentPlan != null && FulfillmentPlan.Entitlements__c != null){
            
            for(string entitlement : FulfillmentPlan.Entitlements__c.split(';')){
                CurrentEntitlements.add(entitlement);
            }
            
        }
        
    }
   
    private void loadAvailableEntitlementsPickListData(){
        
        AvailableEntitlements = new set<string>();
        for (SAM_Entitlement__c dataItem : SAM_Entitlement__c.getAll().values()) {
            
            string entitlement = dataItem.Name;
            
            if(!CurrentEntitlements.contains(entitlement)){
                AvailableEntitlements.add(entitlement);
            }

        }
    }
    
    public Pagereference Save(){
        system.debug('***CurrentEntitlements: ' + CurrentEntitlements);

        try{
            
            if(!CurrentEntitlements.isEmpty()){
                
                string tempEntitlements = '';
                
                for(string entitlement : CurrentEntitlements){
                    tempEntitlements += entitlement + ';';
                }
                
                FulfillmentPlan.Entitlements__c = tempEntitlements;  

                //Save the result (upsert as this may be new)
                upsert FulfillmentPlan;
                
                //Now clean the selected lists
                resetSelections();            
            }
            else{
                ApexPages.Message errMsg = new ApexPages.Message(ApexPages.Severity.INFO,'You must select at least one entitlement');
                ApexPages.addMessage(errMsg);
            }
        }
        catch(Exception ex){
            ApexPages.Message errMsg = new ApexPages.Message(ApexPages.Severity.FATAL,'Error: ' + ex.getMessage());
            ApexPages.addMessage(errMsg);
        }
        
        return null;
    }
    
    public Pagereference AddItems(){
        for(string selected : AvailableSelected){
            AvailableEntitlements.remove(selected);
            CurrentEntitlements.add(selected);
        }
        resetSelections();
        
        return null;
    }
    
    public Pagereference RemoveItems(){
        for(string selected : CurrentSelected){
            CurrentEntitlements.remove(selected);
            AvailableEntitlements.add(selected);
        }
        resetSelections();
        
        return null;
    }
    
    private void resetSelections(){
    	AvailableSelected = new string[]{};
        CurrentSelected = new string[]{};
    }
    
    public Pagereference Back(){
        Pagereference pr = new Pagereference('/' + string.valueOf(FulfillmentPlan.Id).left(3) + '/o');
        
        return pr;
    }
}