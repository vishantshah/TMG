/**	Scheduleable class to purge the Webservice Logs that are older than 3 weeks 
*/
global class WebserviceLogPurgeScheduler implements Schedulable {
	
	global void execute(SchedulableContext sc) {
		
		String toAddress = 'anup.jadhav@telegraph.co.uk';
		String replyToAddress = 'anup.jadhav@telegraph.co.uk'; 
		
		WebserviceLogPurgeBatch batchable = new WebserviceLogPurgeBatch(toAddress, replyToAddress, 3);		
		try {
			Id webserviceLogPurgeBatchId = Database.executeBatch(batchable);
		} catch(Exception ex) {
			/*new TMGUtil.EmailUtil(new List<String> {'anup.jadhav@telegraph.co.uk'})
									.plainTextBody('The scheduled job has been fubar\'ed.')
									.senderDisplayName('Anup Jadhav')
									.subject('WebserviceLogPurgeBatch Error Error: Don\'t Panic')
									.replyTo(replyToAddress).build().sendEmail();
			*/
		
		}
	}
	
	static testmethod void schedulerTest(){ 
		
		Test.startTest();
		String nextYear = String.valueof(date.Today().addYears(1).year());
		//Schedule the test job 
		String jobId = System.schedule('WebserviceLogPurge', 
			'00 50 16 29 AUG ? '+nextYear, new WebserviceLogPurgeScheduler());
		CronTrigger ct = [Select id, CronExpression, TimesTriggered, NextFireTime from CronTrigger where id = :jobId];
		
		//verify that the expression are the same
		System.assertEquals('00 50 16 29 AUG ? '+nextYear,ct.CronExpression);
		//verify that the job has not run
		System.assertEquals(0, ct.TimesTriggered);
		//Verify the next time the job will run
		System.assertEquals(nextYear+'-08-29 16:50:00', String.valueOf(ct.NextFireTime));
		System.assert(jobId != null);
	 	Test.stopTest();
		 
		System.debug('The Scheduler test works as expected');
		
	} 	

}