/**
* Author:       Sally ElGhoul (Tquila)
* Date:         28/04/2015
* Description:  Class to mock up the http response for Core API callouts
*
* ******************* Change Log *******************
* Modified by       Change Date    
* Michal Kwika		05/08/2015 
* Michal Kwika		27/01/2016
* Pawel Chrzanowski 19/05/2016  Added 'GetOffersByProductAndFrequency' to generateResponseBasedOnName()
**/
@isTest
global class MockHttpCoreApiResponseGenerator implements HttpCalloutMock {
	
	protected Integer code;
	protected Integer counterSAMemail;
	protected String mockMode;
	
	global MockHttpCoreApiResponseGenerator(integer codeValue){
		this.code=codeValue;
	}

	//Michal Kwika SUB156 05/08/2015
	//sample resopnse for sam searching
	global MockHttpCoreApiResponseGenerator(Integer codeValue, Integer emailAmount){
		this.code=codeValue;
		this.counterSAMemail = emailAmount;
	}

	global MockHttpCoreApiResponseGenerator(Integer codeValue, String chosenMode){
		this.code=codeValue;
		this.mockMode = chosenMode;
	}
	
	// Implement this interface method
    global HTTPResponse respond(HTTPRequest req) {
    	
    	// Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setStatusCode(code);

        //Michal Kwika SUB156 05/08/2015
        //add totalresults field if this is SAM email search 
        if(this.counterSAMemail != null){
        	String body = '{"totalResults" : '+this.counterSAMemail+'}';
        	res.setBody(body);
        }

        else if(String.isNotBlank(this.mockMode)){
        	Boolean isErrorType = (this.code>=300) ? true : false;
        	String body = generateResponseBasedOnName(this.mockMode, isErrorType);
        	res.setBody(body);
        }

        return res;
    }

    /*************************************************************************************** 
    Developer   Michal Kwika (Accenture)
    Date        27/01/2016
    Function    Generate sample JSON response
    ******************* Change Log *******************
    Modified by         Version     Change Date
    Pawel Chrzanowski   1.1         19/05/2016  Added GetOffersByProductAndFrequency
    ****************************************************************************************/
    private String generateResponseBasedOnName(String mode, Boolean isFailed){
    	String response = '';

    	JSONGenerator gen = JSON.createGenerator(true);
    	//start and decide about content
    	
    	if(mode.equalsIgnoreCase('GetOfferCode') || mode.equalsIgnoreCase('GetAllOfferCodes')){
    		gen.writeStartObject();
    		gen.writeStringField('name', '15 per month');
    		gen.writeStringField('description', '15 per month');
    		gen.writeStringField('longDescription', '15 per month');
    		gen.writeStringField('frequency', Constants.OUTBOUND_MONTHLY_BILLING_PERIOD);
            gen.writeStringField('product', Constants.OUTBOUND_PRODUCT_URL_PARAM_VALUE_TABLET); 
            gen.writeStringField('friendlyName', 'Unit Testing Offer'); 
            gen.writeStringField('tmgId', 'UnitTest-001');  
    		gen.writeNumberField('basePrice', 5.0);	
            gen.writeStartArray();
            gen.writeStringField('billingPeriod', 'Month');  
            gen.writeNumberField('numberOfPeriods', 12);   
            gen.writeNumberField('discountAmount', 1);   
            gen.writeEndArray();
    		gen.writeEndObject();
    		
    	}

    	if(mode.equalsIgnoreCase('getProfileFromSAM')){
    		gen.writeStartObject();
    		gen.writeStringField('publicId', 'baaaa1234254234321-3-21313-1231');
    		gen.writeStringField('email', 'sample@email.com');
    		gen.writeStringField('firstName', 'user');
    		gen.writeStringField('lastName', 'user');
    		gen.writeStringField('title', 'Lord');
    		gen.writeStringField('profileStatus', 'ACTIVE');
    		gen.writeStringField('addressLine1', 'null');
    		gen.writeStringField('addressLine2', '1 Bond Street');
    		gen.writeStringField('city', 'London');
    		gen.writeStringField('county', 'City of London');
    		gen.writeStringField('postCode', 'cr42bb');
    		gen.writeStringField('country', 'UK');
    		gen.writeStringField('phoneNumber', 'null');
    		gen.writeEndObject();
    	}

    	if(mode.equalsIgnoreCase('ResetPassword')){
    		gen.writeStartObject();
    		if(!isFailed){
    			gen.writeStringField('http_code', '200');
    			gen.writeStringField('message', 'Success');
    			
    		} 
    		else {
    			gen.writeStringField('http_code', '404');
    			gen.writeStringField('message', 'Profile not found');
    		}
    		gen.writeEndObject();
    	}

        if(mode.equalsIgnoreCase('GetOffersByProductAndFrequency')){
            gen.writeStartObject();
            gen.writeFieldName('offers');
            gen.writeStartArray();
            gen.writeStartObject();
            gen.writeStringField('tmgId','website-monthly-YK765');
            gen.writeStringField('friendlyName','Website Monthly &#163;10');
            gen.writeEndObject();
            gen.writeEndArray();
            gen.writeEndObject();
        }

    	response = gen.getAsString();
    	
        System.debug('### MockHttpCoreApiResponseGenerator.generateResponseBasedOnName -> response: ' +response);
    	return response;
    } 
}