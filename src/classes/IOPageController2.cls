/* IOPageController2

	This is the controller class for the IODocument2 page. Visualforce
	work on the MVC model and this is the class used to retrieve the
	data displayed on the Visualforce page.
	
	This page is used to display the relevant information from an Ad 
	Campaign and the associated Ad Units in an IO format that can be
	sent out to customers.
	 
	
*/

public class IOPageController2 {

	/* OliEntry
		An inner class used to hold the information about the OpportunityLineItems
		(Ad Units) on an Opportunity (Ad Campaign).
		
		The reason for using the inner class is that, in the Visualforce page, you
		can iterate over a collection of objects to easily create a table. One of
		the drawbacks is that you can only display information from an object's 
		field, you can not, for example, calculate and display a percentage of a 
		field's value.
		
		As we need to calculate a discount, we use this inner class instead. For
		each line item, we create an instance of OliEntry - the constructor 
		performs all the necessary calculations and keeps the necessary values in
		string fields 
	*/
    public class OliEntry {
    	// Strings to hold the values to display
        public String startDate {get; set;}
        public String endDate {get; set;}
        public String format {get; set;}
        public String channel {get; set;}
        public String geo {get; set;}
        public String deal {get; set;}
        public String other {get; set;}
        public String quantity {get; set;}
        public String price {get; set;}
        public String gross {get; set;}
        public String nett {get; set;}
        
        /* OliEntry()
	        Default constructor. We use this as we need to calculate an extra
	        line for the table with total information. We create an OliEntry
	        with out any values set and then populate the fields with the 
	        total information.
        */
        public OliEntry() {
        	startDate = '';
        	endDate = '';
        	format = '';
        	channel = '';
        	geo = '';
        	deal = '';
        	quantity = '';
        }
        
        /* OliEntry(OpportunityLineItem original)
        
        	Creates an OliEntry object for the OpportunityLineItem passed into
        	the constructor. Essentially copies the information from the 
        	OpportunityLineItem into the OliEntry's fields.
        */
        public OliEntry(OpportunityLineItem original) {
        	
        	// Set the strings that don't need any calculation
            startDate = original.Schedule_Start_Date__c.format(); 
            endDate = original.Flight_End__c.format();
            format = original.PricebookEntry.Product2.Format__c + ' - ' + original.PriceBookEntry.Product2.Sub_Format__c;
            channel = original.PricebookEntry.Product2.Channel__c + ' - ' + original.PricebookEntry.Product2.Sub_Channel__c;
            if(original.Sub_Channel_Details__c != 'None')
            	channel += ': ' + original.Sub_Channel_Details__c; 
            geo = original.PricebookEntry.Product2.Geography__c;
            if(original.Geo_Data__c != 'None')
            	geo += ': ' + original.Geo_Data__c;
            if(original.Description != null)
            	other = original.Description ;
            else
            	other = '';
            deal = original.PricebookEntry.Product2.Deal_Type__c;
            quantity = String.valueOf(original.Quantity__c);
            price = String.valueOf(original.UnitPrice);

            // Calculate the gross price
            //gross = String.valueOf(original.Quantity__c * original.UnitPrice);
            gross = String.valueOf(original.Total_Price__c);
            // Trim any digits after the second decimal place
            if(gross.lastIndexOf('.') >= 0)
            	gross = gross.subString(0, gross.lastIndexOf('.')+3); 
            
            // Check if there's any Agency Commission on thie IO. If there is,
            // calculate the nett price, otherwise, gross is the same as nett
            if(original.Opportunity.Agency_Commission__c != null) {  
            	nett = String.valueOf(original.Total_Price__c * ((100-original.Opportunity.Agency_Commission__c)/100));
            	// Trim any digits after the second decimal place
            	if(nett.lastIndexOf('.') >= 0)
            		nett = nett.subString(0, nett.lastIndexOf('.')+3);
            } else {
            	nett = gross;
            }
        }       
    }

	// Class variables for the Controller.
	
	// Some strings to hold the parts of the IO that do not change
	public String blurb {get;set;}
	public String address1 {get;set;}
	public String address2 {get;set;}
	public String address3 {get;set;}
    public String ioNumber {get; set;}
    public String dtiNumber {get; set;}
    public String contentType {get; set;}
    	
	// ID to hold the opportunity's ID, an Opportunity object to hold
	// the object itself, and a list to hold the OpportunityLineItems
    ID oppId = null;
    Opportunity o = null;
    List<OpportunityLineItem> olis = new List<OpportunityLineItem>();
    
    // Variables to hold the team members
    public OpportunityTeamMember salesRepOTM {get;set;}
    public OpportunityTeamMember csRepOTM {get;set;}
    public UserTeamMember salesRepUTM {get;set;}
    public UserTeamMember csRepUTM {get;set;}
    
    // Booleans to show whether this opportunity was raised on behalf of
    // someone else, and to indicate if there was any error in the constrictor    
    public boolean raisedOnBehalf = false;
    public boolean noError {get; set;}

    public IOPageController2() {
        
        try {
        	// Select the Opportunity (Ad Campaign) out of the database with the ID the page was passed, 
        	// with the details needed on the IO.
        	oppId = System.currentPageReference().getParameters().get('id');
        	o = [select o.Id, o.AccountId, o.Name, o.Campaign_Start_Date__c, o.Campaign_End_Date__c, o.Account.Name,
        				o.Primary_Agency_Contact__c, o.Primary_Agency_Buyer__r.Name, o.Advertiser__r.Name,
        				o.Agency_Reference_Number__c, o.Raised_On_Behalf_Of__c, o.Agency_Commission__c, o.PO_Number__c,
        				o.Account.BillingStreet, o.Account.BillingCity, o.Account.BillingState, o.IO_Number__c, o.DTI_Number__c,
        				o.Account.BillingPostalCode, o.Account.BillingCountry, o.CreatedBy.Name, o.CreatedBy.Email, o.CreatedBy.Phone,
        				o.Primary_Agency_Contact__r.Name, o.Primary_Agency_Contact__r.Phone, o.Primary_Agency_Contact__r.Email
        		 from Opportunity o where o.Id = :oppId];
        	
	        ioNumber = o.IO_Number__c;
	        dtiNumber = o.DTI_Number__c;
	        
	        // Ad Campaign's have a "Raised on Behalf Of" field which is used when a sales rep creates an
	        // Ad Campaign on behalf of another sales rep. This ensures that the right contact information
	        // appears on the IO. This contact information is taken from the relevant user's sales team -
	        // every Sales user should have a Sales team consisting of themselves in a Sales role, and 
	        // their Client Services "buddy". 
	        
	        // If there is no entry in this field, we use the sales team on the Ad Campaign itself.
	        // Otherwise, we look up the Raised On Behalf user's sales team
        	if(o.Raised_On_Behalf_Of__c == null) {
        		// Select the Ad Campaign's team members from the database
        		OpportunityTeamMember[] team = [select o.UserId, o.TeamMemberRole, o.User.Name, o.User.Email, o.User.Phone
        										from OpportunityTeamMember o where o.OpportunityId = :oppId];
        		
        		// Loop over each member in the team and assign them to objects we can use later on 
				for(OpportunityTeamMember t : team) {
					if(t.TeamMemberRole == 'Sales') {
						salesRepOTM = t;
					} else if(t.TeamMemberRole.startsWith('Client Services')) {
						csRepOTM = t;
					}
				}
        	} else {
        		raisedOnBehalf = true;
        		// This Ad Campaign was created on behalf of someone else.  Therefore, select out that user's
        		// UserTeamMembers.
        		UserTeamMember[] team = [select u.TeamMemberRole, u.OwnerId, u.UserId, u.User.Name, u.User.Phone, u.User.Email
        								from UserTeamMember u where u.OwnerId = :o.Raised_On_Behalf_Of__c];
        		
        		// Loop over each member in the team and assign them to objects we can use later on 
				for(UserTeamMember t : team) {
					if(t.TeamMemberRole == 'Sales') {
						salesRepUTM = t;
					} else if(t.TeamMemberRole.startsWith('Client Services')) {
						csRepUTM = t;
					}
				}
        	}

			// Now select the OpportunityLineItems (Ad Units) from the database. 
	        olis = [select o.Schedule_Start_Date__c, o.Flight_End__c, o.Id, o.IO__c,
	                         o.Quantity__c, o.UnitPrice, o.Total_Price__c, o.OpportunityId, o.Opportunity.Agency_Commission__c,
	                         o.PriceBookEntry.Product2.Format__c, o.PriceBookEntry.Product2.Channel__c,
	                         o.PriceBookEntry.Product2.Geography__c, o.PriceBookEntry.Product2.Deal_Type__c,
	                         o.PriceBookEntry.Product2.Sub_Format__c, o.PricebookEntry.Product2.Sub_Channel__c,
	                         o.Sub_Channel_Details__c, o.Geo_Data__c, o.Description
	                         from OpportunityLineItem o 
	                         where o.OpportunityID = :oppId order by o.Schedule_Start_Date__c asc];
	        
	        Datetime dt = Datetime.now();
	        String dateTimeStamp = dt.day() + '-' + dt.month() + '-' + dt.year() + '-' +  dt.hour() + '-' + dt.minute() + '-' + dt.second();
	        System.debug('application/vnd.ms-excel#' + o.Account.Name.replaceAll('[^a-zA-Z0-9]','_') + '_IO_' + dateTimeStamp + '.xls');
	        contentType = 'application/vnd.ms-excel#' + o.Account.Name.replaceAll('[^a-zA-Z0-9]','_') + '_IO_' + dateTimeStamp + '.xls';
        	// If we've reached this far, set the noError boolean to true. This is used on the page to determine
        	// whether we should display an error or not.
        	noError = true;
        } catch(Exception exc) {
        	// If there was an error, set noError to true.
        	noError = false;
        }

		// Set the strings that hold the standard content on an IO that doesn't change.
        blurb = 'This Insertion Order (including the Schedule) together with the standard terms and conditions for advertising on telegraph.co.uk ("the Site") available for review http://www.telegraph.co.uk/advertising/6617220/Telegraph-Media-Group-terms-and-conditions-of-advertising.html constitutes the agreement made between Telegraph Media Group Limited and the Buyer relating to the Advertisement(s) detailed herein ("the Agreement").  By signing this Insertion Order, or submitting any Advertisement for appearance on the Site, the Buyer confirms the acceptance of this Agreement."';
        address1 = 'Telegraph Media Group Limited, a company registered in England No. 451593';
        address2 = 'Registered office: 111 Buckingham Palace Rd, London, SW1W 0DT';
        address3 = 'Telephone: 020 7931 3222    Fax: 020 7931 3379';
    }

	/* boolean getShowError()
		Indicates whether the error message should be displayed on the page or not
	*/
	public boolean getShowError() {
		if(noError == true)
			return false;
		else
			return true;
		
	}
	
	/* String getAdvertiser()
		Returns the name of the advertiser on the Ad Campaign.
	*/
	
    public String getAdvertiser() {
        if(o.Advertiser__r != null)
        	return o.Advertiser__r.Name;
        else
			return null;        
    }

	/* String getAgency()
		Returns the name of the agency on the Ad Campaign.
	*/
    public String getAgency() {
        if(o.Account != null)
        	return o.Account.Name;
        else
			return null;
    }

	/* String getAgencyRef()
		Returns the agency reference number and PO number for the IO.
	*/
    public String getAgencyRef() {
    	String po = '';
    	String ref = '';
    	if(o.PO_Number__c != null)
    		po = o.PO_Number__c;
    	if(o.Agency_Reference_Number__c != null)
    		ref = o.Agency_Reference_Number__c;
		return po + ' / ' + ref ;
    }   
    
    /* String getCampaignName()
    	Returns the name of the Ad Campaign
    */
    public String getCampaignName() {
        return o.Name;
    }

    /* String getCampaignStart()
    	Returns the start date of the Ad Campaign
    */
    public String getCampaignStart() {
        if(o.Campaign_Start_Date__c != null)
        	return o.Campaign_Start_Date__c.format();
        else 
			return null;
    }

    /* String getCampaignEnd()
    	Returns the end date of the Ad Campaign
    */
    public String getCampaignEnd() {
        if(o.Campaign_End_Date__c != null)
        	return o.Campaign_End_Date__c.format();
        else
        	return null;
    }
    
    /* String getAgencyContactName()
    	Get the name of the person listed as the agency contact.
    */
    public String getAgencyContactName() {
        if(o.Primary_Agency_Contact__r != null)
        	return o.Primary_Agency_Contact__r.Name;
		else
			return null;
    }

    /* String getAgencyContactPhone()
    	Get the phone number of the person listed as the agency contact.
    */
    public String getAgencyContactPhone() {
        if(o.Primary_Agency_Contact__r != null)
        	return o.Primary_Agency_Contact__r.Phone;
        else
			return null;
    }
 
    /* String getAgencyContactEmail()
    	Get the email address of the person listed as the agency contact.
    */   
    public String getAgencyContactEmail() {
        if(o.Primary_Agency_Contact__r != null)
        	return o.Primary_Agency_Contact__r.Email;
        else
			return null;
    }

	/* String getSalesRepName()
		Get the name of the Sales rep for this Account.
		
		The name we return depends on if the Ad Campaign was created on behalf 
		of someone else or not. This will have determined what user/opportunity 
		objects we have with information.
		
		It may be that we have neither, so we check to see if the objects we 
		have are actually initialised. If not, we show a warning message on the
		IO. If this error message is present, it's probably because the user
		does not have a default sales team assigned. 
	*/
    public String getSalesRepName() {
        
        if(raisedOnBehalf) {
        	if(salesRepUTM != null)
        		return salesRepUTM.User.Name;
        	else
        		return 'Not found - please contact administrator';
        } else {
        	if(salesRepOTM != null)
        		return salesRepOTM.User.Name;
        	else
        		return 'Not found - please contact administrator';
        }
    }
    
    /* String getSalesRepPhone()
    	Gets the phone number of the Sales Rep for this account.
    	
    	Please see the extended note under the getSalesRepName() method
    */
    public String getSalesRepPhone() {
        if(raisedOnBehalf) {
        	if(salesRepUTM != null)
        		return salesRepUTM.User.Phone;
        	else
        		return null;
        } else {
        	if(salesRepOTM != null)
        		return salesRepOTM.User.Phone;
        	else
        		return null;
        }
    }

    /* String getSalesRepEmail()
    	Gets the email address of the Sales Rep for this account.
    	
    	Please see the extended note under the getSalesRepName() method
    */
    public String getSalesRepEmail() {
        if(raisedOnBehalf) {
        	if(salesRepUTM != null)
        		return salesRepUTM.User.Email;
        	else
        		return null;
        } else {
        	if(salesRepOTM != null)
        		return salesRepOTM.User.Email;
        	else
        		return null;
        }
    }

	/* String getBookingRepName()
		If this Ad Campaign was raised on behalf of another user, this method
		returns the name of the Sales Rep that actually made the booking.
	*/
    public String getBookingRepName() {
        if(raisedOnBehalf)
        	return o.CreatedBy.Name;
        else
        	return null;
    }

	/* String getBookingRepPhone()
		If this Ad Campaign was raised on behalf of another user, this method
		returns the phone number of the Sales Rep that actually made the booking.
	*/
    public String getBookingRepPhone() {
        if(raisedOnBehalf)
        	return o.CreatedBy.Phone;
        else
        	return null;
    }

	/* String getBookingRepEmail()
		If this Ad Campaign was raised on behalf of another user, this method
		returns the email address of the Sales Rep that actually made the booking.
	*/
    public String getBookingRepEmail() {
        if(raisedOnBehalf)
        	return o.CreatedBy.Email;
        else
        	return null;
    }

	/* String getCsRepName()
		Gets the name of the Client Services rep associated with the Sales Rep
		who owns this account.
		
		Please see the extended note under the getSalesRepName() method - the
		same principle applies here, as Sales users are assigned a Client Services
		"buddy" who should appear on all IOs that list them as the Sales Rep
	*/
    public String getCsRepName() {
        if(raisedOnBehalf) {
        	if(csRepUTM != null)
        		return csRepUTM.User.Name;
        	else
        		return 'Not found - please contact administrator';
        } else {
        	if(csRepOTM != null)
        		return csRepOTM.User.Name;
        	else
        		return 'Not found - please contact administrator';
        }
    }
    
    /* String getCsRepPhone()
		Gets the phone number  of the Client Services rep associated with the Sales Rep
		who owns this account.
		
		Please see the extended note under the getSalesRepName() method - the
		same principle applies here, as Sales users are assigned a Client Services
		"buddy" who should appear on all IOs that list them as the Sales Rep
	*/
    public String getCsRepPhone() {
        
        if(raisedOnBehalf) {
        	if(csRepUTM != null)
        		return csRepUTM.User.Phone;
        	else
        		return null;
        } else {
        	if(csRepOTM != null)
        		return csRepOTM.User.Phone;
        	else
        		return null;
        }
    }
 
     /* String getCsRepEmail()
		Gets the email address  of the Client Services rep associated with the Sales Rep
		who owns this account.
		
		Please see the extended note under the getSalesRepName() method - the
		same principle applies here, as Sales users are assigned a Client Services
		"buddy" who should appear on all IOs that list them as the Sales Rep
	*/   
    public String getCsRepEmail() {
        
        if(raisedOnBehalf) {
        	if(csRepUTM != null)
        		return csRepUTM.User.Email;
        	else
        		return null;
        } else {
        	if(csRepOTM != null)
        		return csRepOTM.User.Email;
        	else
        		return null;
        }
    }

	/* List<OliEntry> getOlis()
		Return a list of OliEntry objects, each holding the information of an
		Ad Unit Line Items that needs to appear on the IO. An additional
		OliEntry is created to hold the "total" information at the bottom
		of the table.
		
		This List is then iterated over in the Visualforce code to display
		all information.
	*/
    public List<OliEntry> getOlis() {
    	
    	// For each Ad Unit Line Item, create an OliEntry and add it to a list.
        List<OliEntry> oliObjects = new List<OliEntry>();
        for(OpportunityLineItem oli : olis) {
            OliEntry o = new OliEntry(oli);
            oliObjects.add(o);
        }
        
        // Create an extra OliEntry to hold the total information for the bottom
        // of the table.
        OliEntry o = new OliEntry();
		Double price = 0.00;
		Double gross = 0.00;
		Double nett = 0.00;
		
		// Loop over the OliEntrys in the list to calculate the totals.
        for(OliEntry oe : oliObjects) {
        	//price += Double.valueOf(oe.price);
        	gross += Double.valueOf(oe.gross);
        	nett += Double.valueOf(oe.nett);
        }
		
		// Add the Total information to the relevant OliEntry fields
		//o.Quantity = 'TOTAL COST EXCL VAT: ';
		//o.price = String.valueOf(price);
		o.deal = 'TOTAL COST EXCL VAT: ';
        o.gross = String.valueOf(gross);
        o.nett = String.valueOf(nett);
        
        // Add the OliEntry to the list, then return the list.
        oliObjects.add(o);

        return oliObjects;
    }
}