/************************************************************************************
Class Name   : ChequeBatchClosureScheduler
Author       : Mantas Grigaliunas
Created Date : 14/12/2016
Function     : Schedulable job class to close Voucher Holiday Returns Cheque Batch by updating Closed Date
Change Log:
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
* Developer             Date         Description
* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
*************************************************************************************/
global class ChequeBatchClosureScheduler implements Schedulable {

	/************************************************************************************
    Method Name  : execute
    Developer    : Mantas Grigaliunas
    Created Date : 14/12/2016
    Function     : Class execution method to update Cheque Batch Closed Date
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer         Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
	global void execute(SchedulableContext sc) {
		
		try{		

			Id chequeBatchRecordTypeId = RecordTypeUtility.getRecordTypeId(Cheque_Batch__c.sObjectType, 
                Constants.VOUCHER_REFUND_CHEQUE_BATCH_RECORD_TYPE_NAME, Cheque_Batch__c.class.getName());

			List<Cheque_Batch__c> chequeBatchList = new List<Cheque_Batch__c>(
													[ SELECT Id, Name FROM Cheque_Batch__c 
											  		  WHERE RecordTypeId = :chequeBatchRecordTypeId 
											  		  AND Batch_Closed_Date__c = NULL ]);

			if(chequeBatchList.size() > 0){

				for(Cheque_Batch__c chequeBatch : chequeBatchList){
		   			chequeBatch.Batch_Closed_Date__c = Date.today();
		   		}
		   		update chequeBatchList;
		   	}
	   	}catch(Exception e){
	   		TMGUtil.EmailUtil emailUtil = new TMGUtil.EmailUtil(new List<String>{Constants.MPP_LETTEREXTRACT_ADMINEMAIL_VALUE});
			emailUtil.plainTextBody('ChequeBatchClosureScheduler job failed.\nError Message: ' + e.getMessage() + '\nStack: ' + e.getStackTraceString())
					.subject('Error in ChequeBatchClosureScheduler')
					.build()
					.sendEmail();
		}
	}
}