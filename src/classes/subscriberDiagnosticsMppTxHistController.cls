public with sharing class subscriberDiagnosticsMppTxHistController {

    private Apexpages.StandardController controller; 

	public String accountName { get; set; }
	public String accountId { get; set; }
	public Account acc {get; set;}

	public subscriberDiagnosticsMppTxHistController() {}
    
    public subscriberDiagnosticsMppTxHistController(ApexPages.StandardController stdController) {
        this.controller = stdController;
        
        accountId = ApexPages.currentPage().getParameters().get('accountId');
        acc = [Select id, Name, Subscriber_Number_Static__c from Account where id=:accountid];       

    }

    public PageReference save() {
        this.controller.save();
        PageReference newPage = New PageReference('/apex/page/SubscriberDiagnostics?id=' + acc.Id);
        newPage.setRedirect(true);
        return newPage;
    }

}