public class SubscriptionRenewalUtils {

	public static String getSubscriptionType(Subscription__c sub){
		String sType;
		
		if(sub<>null){
			
			stype = sub.Subscription_Duration_Picklist__c + ' Week';
		}
		
		return sType;
	}
	
	public static boolean getShowStartDate(Subscription__c sub){
		/* Start date is shown for non-DD subs; or for DD-subs if status is pending and start-date is in future */
		if(sub <> null){
			
			if(sub.Subscription_Status__c == CONSTANTS.SSTATUS_PENDING &&
			   sub.Start_Date__c > date.today()){
			   	return true;
			}else if(sub.Subscription_Status__c == CONSTANTS.SSTATUS_IN_RENEWAL ||
						sub.Subscription_status__c == CONSTANTS.SSTATUS_ACTIVE){
				return true;
			}else{
				return false;
			}
		}
		
		return null;
	}	
	
	public static boolean getShowEndDate(Subscription__c sub){
		/* End date are shown if sub status is (active or pending) and payment method is not DD */		
		if(sub <> null){
			
			if((sub.subscription_status__c == CONSTANTS.SSTATUS_ACTIVE ||
				sub.subscription_status__c == CONSTANTS.SSTATUS_PENDING ||
				sub.subscription_status__c == CONSTANTS.SSTATUS_IN_RENEWAL ||
				sub.subscription_status__c == CONSTANTS.SSTATUS_PENDING_CANX ||
				sub.subscription_status__c == CONSTANTS.SSTATUS_CANX) ){
				return true;	
			}else{
				return false;
			}
			
		}
		
		return null;
	}	
	
	public static boolean getAllowRenewal(Subscription__c sub, Boolean hasOfferedSub){
		
		if(sub <> null){
			
			if( (sub.subscription_status__c == CONSTANTS.SSTATUS_IN_RENEWAL ||
					( (sub.subscription_status__c == CONSTANTS.SSTATUS_CANX || 
						sub.subscription_status__c == CONSTANTS.SSTATUS_PENDING_CANX) && 
						Date.today() <= sub.cancellation_date__c
					 )
			     )&&
			     hasOfferedSub
			   ){
				return true;
			}else{
				return false;
			}
			
		}
		
		return null;
	}  	
}