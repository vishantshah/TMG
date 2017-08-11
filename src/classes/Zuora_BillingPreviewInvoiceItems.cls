/**
* Author:       Sally ElGhoul (Accenture)
* Date:         25/02/2016
* Description:  A class of quote billing preview invoice items
*
* ******************* Change Log *******************
* Modified by       Change Date   
* Sally ElGhoul 	1.1	8/3/2016 add a boolean field to show that the invoice has an old discount and rename isDiscountApplied to be isNewDiscountApplied  
**/
public class Zuora_BillingPreviewInvoiceItems implements Comparable{
	public Date 	invoiceItemDate				{get;set;}
 	public Decimal 	invoiceItemAmount			{get;set;}
 	public Integer 	invoiceItemIndex			{get;set;}
 	
 	//Fields related to mid term discounts implementation
 	public Decimal  discountedInvoiceItemAmount	{get;set;}
 	public Boolean  isNewDiscountApplied		{get;set;}
 	public Decimal  discountAmount				{get;set;}
 	public Boolean 	isOldDiscountApplied		{get;set;}
 	
 	public Zuora_BillingPreviewInvoiceItems(){
 		isNewDiscountApplied=isOldDiscountApplied=false;
 		discountedInvoiceItemAmount=0;
 		discountAmount=0;
 	}
 		
 	/*************************************************************************************** 
    Developer   Sally ElGhoul (Accenture)
    Date        25/02/2016
    Function    Implement the compareTo() method
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/ 
	public Integer compareTo(Object compareTo) {
	    Zuora_BillingPreviewInvoiceItems compareToInvoiceItem = (Zuora_BillingPreviewInvoiceItems)compareTo;
	    if (invoiceItemDate == compareToInvoiceItem.invoiceItemDate) return 0;
	      if (invoiceItemDate > compareToInvoiceItem.invoiceItemDate) return 1;
	       return -1;        
    }
}