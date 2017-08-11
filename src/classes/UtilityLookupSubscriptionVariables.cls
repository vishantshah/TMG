public class UtilityLookupSubscriptionVariables {

public static String getMainIncentives(){
    String incentive;
    try{
        incentive = String.valueOf([Select DefaultValue__c From SubManagementDefaults__c Where ID__c='Incentive'].DefaultValue__c);
    }catch(Exception e){system.debug('GetMainIncentives ' +e);}    
    
    return incentive;
}

public static String getEmailIncentives(){
    String EmailIncentive;
    try{
        emailIncentive = String.valueOf([Select DefaultValue__c From SubManagementDefaults__c Where ID__c='EmailIncentive'].DefaultValue__c);
    }catch(Exception e){system.debug('GetEmailIncentives ' +e);}  
    
    return emailIncentive;
}

public static ID getRecordType(String recType){
    list<RecordType> rTypeList = [Select Id From RecordType Where Name=:recType];
    if (rTypeList.size() > 0){
        Id rType = rTypeList[0].Id;         
        return rType;
    }
    else 
        return null;  
}

public static String getRecordTypeNameById(ID id){

    list<RecordType> rTypeList = [Select Name From RecordType Where ID=:id];
    if (rTypeList.size() > 0){
        String rType = rTypeList[0].Name;        
        return rType;
    }
    else
    return null; 
}

public static String getTSNumber(Id accID){
    
    String returnVal;
    //lookup accID
    list<Account> acc = [Select Subscriber_Number_static__c From Account where Id=:accID];
    //if not found workflow hasn't updated Subscriber_Number_static__c so look up Subscriber_Number__c but this should never happen
    if (acc.size() > 0 && acc[0].Subscriber_Number_static__c != null  && acc[0].Subscriber_Number_static__c != '')
        returnVal = acc[0].Subscriber_Number_static__c;
    else{
        acc = [Select Subscriber_Number__c From Account where Id=:accID];
        if (acc.size() == 0 || acc[0].Subscriber_Number__c == null || acc[0].Subscriber_Number__c == '')
            return null;
        else
            returnVal = acc[0].Subscriber_Number__c;
    }
    
    return returnVal;
}

}