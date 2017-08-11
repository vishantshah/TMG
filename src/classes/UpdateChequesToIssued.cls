public class UpdateChequesToIssued {
//SMS-321 
public Boolean UpdateThisChequeStatus(){
	Boolean Success=false;
	String q;
	list<String> f = new list<String>(); 
	list<String> v=new list<String>(); 
	try {
		q = 'Select id From Cheque__c c where (c.Type__c = \'Refund\' or  c.Type__c = \'Refund - awaiting approval\' or c.Type__c = \'Indemnity Cheque\') ';   

		f.add('Cheque_Banking_Status__c');
		f.add('Cheque_Refund_Reason__c');		
		v.add('Issued');
		v.add('Unknown');
		id batchinstanceid = database.executeBatch(new UpdateChequeStatusBatch(q,f,v)); 		
	}
	catch(Exception e){
		//send email if fails
		String toAddress = 'teamsalesforce@telegraph.co.uk';
		String replyToAddress = 'steven.fouracre@telegraph.co.uk';
		List<String> toAddresses = new List<String> {toAddress};
		    //use the new util class to send an email
		    TMGUtil.EmailUtil emailUtil = new TMGUtil.EmailUtil(toAddresses);
		    emailUtil.plainTextBody('The batch apex is now complete.')
	        .senderDisplayName('Steve Fouracre')
	        .replyTo(replyToAddress)
	        .subject('Update Cheque To Issued Batch Apex Complete')
	        .build()
	        .sendEmail(); 	
	        	
			system.debug(e);
	}
	Success=true;
	return Success;
}

}