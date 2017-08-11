/**
* @author Unknown
* @date Unknown
* @description 
#############Change Log#############
Modified by     Version     Change Date
Wiktor Czykin   1.1         09/03/2015  //Made sure it does not blow up when payment triggers are off
**/
@isTest(SeeAllData=false) 
private class UpdateChequeStatusBatchTest {

public static list<String> f; 
public static list<String> v; 
public static Account testPersonAccount;
public static Subscription__c testSubBasic;
public static Subscription__c checkSubBasic;
public static Cheque_Batch__c newbatch;
public static Id batchId;
public static Cheque__c chq;
public static String q = 'Select id From Cheque__c c where (c.Type__c = \'Refund\' or  c.Type__c = \'Refund - awaiting approval\' or c.Type__c = \'Indemnity Cheque\') limit 10';

public static void SetupData(){
	f = new list<String>();
	v=new list<String>();
	f.add('Cheque_Banking_Status__c');
    f.add('Cheque_Refund_Reason__c');       
    v.add('Issued');
    v.add('None');

    //add some data to ensure there is at least 1 rec that has a valid rec to change in the batch apex
    testPersonAccount = new Account(Name='testPersonAccount',Price_Plan__c='B'); 
    insert testPersonAccount;
    
	//didnt use SubscriptionPaymentUtils because it requires to send a created subscription to the constructor which then creates a DD attached to the Sub  
	//sms-473
	Date stDate = UtilitySelectOptionsSubscriptions.getFirstStartDate(5);
    testSubBasic = new Subscription__c(	Subscriber__c=testPersonAccount.Id,
    									Start_Date__c=stDate,
    									Payment_Details_Received__c=true, 
    									Payment_Type__c='Cheque', 
    									Voucher_Pack_Duration__c=13, 
    									Weekly_Price__c=259.11, 
    									Delivery_Type__c='HD', 
    									Asset_Calc__c=0, 
    									Liab_Calc__c = 0,
    									Subscription_Status__c = Constants.SSTATUS_PENDING
    									);    
    insert testSubBasic;

    checkSubBasic = [Select Subscription_Status__c From Subscription__c where id=:testSubBasic.id];
    //System.assertequals('Pending',checkSubBasic.Subscription_Status__c);
    
    try{
    	batchId = [Select id From Cheque_Batch__c where Batch_Closed_Date__c = null limit 1].id;
    }
    catch(Exception err){
    	newbatch = new Cheque_Batch__c(Synthesys_Batch_ID__c='Test123456789');
    	insert newbatch;
    	batchId = newbatch.id;    		
    }
            
    chq = new Cheque__c(Subscription__c=testSubBasic.id,Cheque_Refund_Reason__c='None',Cheque_Amount__c=100.00,Ref_Number_on_Cheque__c='123456',Name_on_Cheque__c='Test',Type__c='Refund',Cheque_Banking_Status__c='Issued',Cheque_Batch__c=batchId);
    insert chq;
    	
}   
 
private static testMethod void UpdateChequeStatusTest() {
    if (f == null)
    	SetupData();
    
    UpdateChequeStatusBatch ChequeStatusbatch = new UpdateChequeStatusBatch(q,f,v);    
    
    Id ChequeStatusbatchId = Database.executeBatch(ChequeStatusbatch);
    System.assert(ChequeStatusbatchId != null);
    
   }

	static testMethod void UpdateChequeStatusStart() {
    if (f == null)
    	SetupData();

	    Test.startTest();
				//4th test			
				UpdateChequeStatusBatch batchable2 = new UpdateChequeStatusBatch(q,f,v);					
				Database.BatchableContext bc;
				Database.QueryLocator UpdateChequeStatusList;
				UpdateChequeStatusList = batchable2.start(bc);
		Test.stopTest();   
		system.assert(UpdateChequeStatusList != null);
	}
	      
	static testMethod void UpdateChequeStatusExecute() {
    if (f == null)
    	SetupData();

	    Test.startTest();
				UpdateChequeStatusBatch batchable3 = new UpdateChequeStatusBatch(q,f,v);					
				List<sObject> scope =  Database.query(q);
				System.debug('start UpdateChequeStatusExecute ' + scope);
				Database.BatchableContext bc;
				batchable3.execute(bc,scope);
		Test.stopTest();    
			
	}
	
	static testMethod void UpdateChequeStatusFinish() {
		//nothing entered yet but confirms it runs
		f = new list<String>();
		v=new list<String>();
		f.add('Cheque_Banking_Status__c');
	    f.add('Cheque_Refund_Reason__c');       
	    v.add('Issued');
	    v.add('None');

	    Test.startTest();
			UpdateChequeStatusBatch batchable3 = new UpdateChequeStatusBatch(q,f,v);					
			Database.BatchableContext bc;
			batchable3.finish(bc);
		Test.stopTest();    
	}  
	
	static testMethod void UpdateChequesToIssuedTest() {
	    if (f == null)
	    	SetupData();
		
		Test.startTest();
			UpdateChequesToIssued chqIssue =  new UpdateChequesToIssued();
			chqIssue.UpdateThisChequeStatus();//+ve
		Test.stopTest();  
	}  
}