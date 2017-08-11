/**
Name:	WebserviceUtil
* @author Unknown
* @date	Unknown
* @description  holds exception classes for webservices
#############Change Log#############
Modified by		Version 	Change Date
Wiktor Czykin	1.1			03/12/2015	//added error codes vars to be able to assert more easily
*/ 
global class WebserviceUtil {
    
    public static final String UNKNOWN_ERROR_CODE = '1';
    public static final String GUID_ISSUE_CODE = '2';
    public static final String TSNUMBER_ISSUE_CODE = '3';
    public static final String INVALID_FIELD_CODE = '4';
    public static final String NULL_PARAMETER_CODE = '5';
    public static final String SAM_ISSUE_CODE = '6';
    public static final String TOO_MANY_RECORDS_CODE = '7';
    public static final String UNKNOWN_ORDER_CODE = '8';
    public static final String DATABASE_VALIDATION_ISSUE_CODE = '9';
    public static final String NO_ACTIVE_SUBSCRIPTION_CODE = '10';
    public static final String NO_ACTIVE_SUBSCRIVBER_CODE = '11';
    
    global class WSError{
        webservice String errorCode;
        webservice String errorMessage;        
        
        public WSError(String errorCode, String errorMessage){
            this.errorCode = errorCode;
            this.errorMessage = errorMessage;
        }
    }  
    
    public virtual class WSException extends Exception {
    	private WebserviceUtil.WSError error;
    	public virtual WSError getError(){
    		return new WSError(UNKNOWN_ERROR_CODE, 'Unknown Error');
		}
    }
    
   	public class GuidInUseException extends WSException {
    	public override WSError getError(){
    		return new WSError(GUID_ISSUE_CODE, 'GUID already associated with an Account.');
    	}
    }
    
    public class NullGuidException extends WSException {
    	public override WSError getError(){
    		return new WSError(GUID_ISSUE_CODE, 'Please select a GUID for this Account.');
    	}
    }
        
    public class UnknownTSNumberException extends WSException {
    	
    	public UnknownTSNumberException(String errorCode,String tsNumber){
    		error= new WSError(errorCode, 'Unknown TSNumber "'+tsNumber+'"');
    	}
    	
    	public override WSError getError(){
    		if(error==null)
    			return new WSError(TSNUMBER_ISSUE_CODE, 'Unknown TSNumber');
    		else
    			return error;
    	}
    }
        
    public class InvalidFieldException extends WSException{
    
    	private String messageDetails = '';
    	
    	public InvalidFieldException(String name, String value, String posibilities){
    		setMessageDetails(name, value, posibilities);
    	}
    	
    	public void setMessageDetails(String name, String value, String posibilities){
    		if( name != null ){
    			messageDetails = ' Field name: [' + name.replace('__c', '').replace('_','').toLowerCase() + ']';
    		}
    		
    		if( value != null ){
    			messageDetails += ' Value detected: [' + value + ']';
    		}
    		
    		if( posibilities != null ){
    			messageDetails += ' Allowed values: ' + posibilities + '';
    		}
    	}
    	
    	public override WSError getError(){
    		return new WSError(INVALID_FIELD_CODE, 'Invalid field found.' + messageDetails);
    	}
    }
    
        
    public class NullParameterException extends WSException{
    
    	private String messageDetails = '';
    	
    	public NullParameterException(String parameterName, String dummy){
    		setMessageDetails(parameterName);
    	}
    	
    	public void setMessageDetails(String parameterName){
    		if( parameterName != null ){
    			messageDetails = ' Paramater: ' + parameterName + ' cannot be null.';
    		}else{
    			messageDetails = 'Parameter cannot be null but cannot identify which.';
    		}
    	}
    	
    	public override WSError getError(){
    		return new WSError(NULL_PARAMETER_CODE, messageDetails);
    	}
    }    
	
	public class SamException extends WSException{
    
    	private String messageDetails = '';
    	
    	public SamException(String messageDetails, String dummy){
    		this.messageDetails = messageDetails;
    	}
    	
    	public override WSError getError(){
    		return new WSError(SAM_ISSUE_CODE, 'SAM Exception: '+messageDetails);
    	}
    }
    
    public class TooManyRecordsException extends WSException {
    	public override WSError getError(){
    		return new WSError(TOO_MANY_RECORDS_CODE, 'Too many records submitted');
    	}
    } 
    
    public class UnknownOrderIdException extends WSException {
     	private String orderId = '';
    	
    	public UnknownOrderIdException(String orderId, String dummy){
    		this.orderId = orderId;
    	}
    	
    	public override WSError getError(){
    		return new WSError(UNKNOWN_ORDER_CODE, 'Unknown MPP Transaction History Order Id: '+ orderId);
    	}   	
    }

    public class DatabaseValidationException extends WSException {
     	private String validationMessage = '';
    	
    	public DatabaseValidationException(String validationMessage, String dummy){
    		this.validationMessage = validationMessage;
    	}
    	
    	public override WSError getError(){
    		return new WSError(DATABASE_VALIDATION_ISSUE_CODE, 'A database validation error occured: '+ validationMessage);
    	}   	
    }
    
    public class NoActiveSubscriptionException extends WSException{
    	public override WSError getError(){
    		return new WSError(NO_ACTIVE_SUBSCRIPTION_CODE, 'No active subscription found');
    	}
    }
    
    public class UnknownSubscriberException extends WSException{
    	private string subscriberId = '';
    	
    	public UnknownSubscriberException(string subscriberId, string doNotUse){
    		this.subscriberId = subscriberId;
    	}
    	
    	public override WSError getError(){
    		return new WSError(NO_ACTIVE_SUBSCRIVBER_CODE, 'No subscriber found with these credentials: ' + subscriberId);
    	}
    }
        
    public class GenericWSException extends WSException{
		private WSError ws;
    	
    	public GenericWSException(String errorCode, String errorMessage){
    		this(errorMessage);
    		ws = new WSError(errorCode, errorMessage);
    	}
    	
    	public override WSError getError(){
    		return ws;
    	}
    }
}