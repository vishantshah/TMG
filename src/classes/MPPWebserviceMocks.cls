/**
* @author Wiktor Czykin
* @date 14/05/2015
* @description 	webservice mocks for MPP callouts - it still contains hard coded responses as couldnt simulate MPPInterfaceHTTP callouts with mocks
                using static resources as that would require full rebuild of that class. But the first step here is to move out all hard coded xml from 
                MPPInterfaceHTTP class to this test annotated class.
#############Change Log#############
Modified by     	Version     Change Date
Cristina Anghenie	1.1			26/08/2015	//add new variable for the autoRenewal method to make it work for soft cancellation and renewal as well
Cristina Anghenie 	1.2			11/09/2015	//add new method getCancelPaymentScheduleXML())
Wiktor Czykin		1.3			15/12/2015	//added MppCreateSessionMock();
Wiktor Czykin       1.4         09/02/2016  //modified getTestPaymentDetailXML()
**/
@isTest
public class MPPWebserviceMocks {

    public static final String PARAM_FREQUENCY = 'frequency';
    public static final String PARAM_COLLECTION_DATE = 'collectiondate';
    public static final String PARAM_FIRSTCOLLECTION_DATE = 'firstcollectiondate';
    public static final String PARAM_LASTORDER_DATE = 'lastorderdate';
    public static final String PARAM_ISFAILURE = 'isfailure';
    public static final String PARAM_TOTALORDERS = 'totalordersinhistory';
    public static final String PARAM_NEXTPAYMENT_DATE = 'nextpaymentdate';
    public static final String PARAM_IS_RENEWAL = 'isRenewal';
    public static final String PARAM_AMOUNT = 'amount';
    public static final String PARAM_NOSCHEDULES = 'noSchedules';
    public static final String PARAM_CURRENCY = 'currency';
    public static final String PARAM_PAYMENTSCHID = 'paymentScheduleID';
    public static final String PARAM_EMAIL = 'emailAddress';
    public static final String PARAM_FAILUREREASON = 'failureReason';
    public static final String PARAM_ISLIST = 'isList';
    public static final String PARAM_TS1 = 'TSNumber1';
    public static final String PARAM_TS2 = 'TSNumber2';

    public static final String MPPREQUEST_ORDERHISTORY= 'MPPOrderHistoryRESTResponse';
    public static final String MPPREQUEST_BULKPAYMENTDETAILS= 'MPPPaymentDetailsRESTResponse';
    public static final String MPPREQUEST_CHANGEPAYMENTSCHEDULEDATE= 'MPPChangePaymentScheduleDateRESTResponse';
    public static final String MPPREQUEST_EDITPAYMENTSCHEDULE= 'MPPChangePaymentScheduleRESTResponse';
    public static final String MPPREQUEST_SETAUTORENEW = 'MPPSetAutoRenewRESTResponse';
    public static final String MPPREQUEST_CANCELPAYMENTSCHEDULE = 'MPPCancelPaymentSchedule';
	public static final String MPPREQUEST_USERINFO = 'UserInfoResponse';

    public static Map<String, String> MAP_ENDPOINT_RESPONSE;
    
    /*************************************************************************************** 
    Developer - Wiktor Czykin
    Date - 26/05/2015
    Version - 1.0
    Function - has to be a separate method as have to have replaced base url before value can be used as a key
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public static void initializeEndpoints(String sBaseUrl){
        if(MAP_ENDPOINT_RESPONSE != null) return;
        Map<String, String> mapEndpoints = new Map<String, String>{
            MPPInterfaceHTTP.userOrderHistoryEndpoint.replace(MPPInterfaceHTTP.STRING_BASEURL, sBaseUrl) =>  MPPREQUEST_ORDERHISTORY,
            MPPInterfaceHTTP.bulkPaymentDetailsEndpoint.replace(MPPInterfaceHTTP.STRING_BASEURL, sBaseUrl) => MPPREQUEST_BULKPAYMENTDETAILS,
            MPPInterfaceHTTP.changePaymentScheduleDateEndpointOnly.replace(MPPInterfaceHTTP.STRING_BASEURL, sBaseUrl) => MPPREQUEST_CHANGEPAYMENTSCHEDULEDATE,
            MPPInterfaceHTTP.editPaymentScheduleEnpoint.replace(MPPInterfaceHTTP.STRING_BASEURL, sBaseUrl) => MPPREQUEST_EDITPAYMENTSCHEDULE,
            MPPInterfaceHTTP.autoRenewalEndpoint.replace(MPPInterfaceHTTP.STRING_BASEURL, sBaseUrl) => MPPREQUEST_SETAUTORENEW,
            MPPInterfaceHTTP.cancelPaymentScheduleEndpointOnly.replace(MPPInterfaceHTTP.STRING_BASEURL, sBaseUrl) => MPPREQUEST_CANCELPAYMENTSCHEDULE,
            MPPInterfaceHTTP.userInfoEndpointOnly.replace(MPPInterfaceHTTP.STRING_BASEURL, sBaseUrl) => MPPREQUEST_USERINFO
        };
        MAP_ENDPOINT_RESPONSE = mapEndpoints;
    }

    /*************************************************************************************** 
    Developer - Wiktor Czykin
    Date - 26/05/2015
    Version - 1.1
    Function - GetPaymentDetails MPP request responses
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         09/02/2016  //added tsnumber param for individual response
    ****************************************************************************************/
    public static String getTestPaymentDetailXML(Map<String, String> mapParams){
        String sResponse = '';
        if(mapParams.containsKey(PARAM_ISFAILURE)){
            sResponse +='<?xml version="1.0" encoding="utf-16"?>';
            sResponse +='<PaymentDetailsResult xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">';
            sResponse +='<ErrorNumber>12</ErrorNumber>';
            sResponse +='<ErrorMessage>MPP ERROR</ErrorMessage>';
            sResponse +='</PaymentDetailsResult>';
        }if(mapParams.containsKey(PARAM_ISLIST)){
        	sResponse +='<PaymentDetailsResult xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">';
            sResponse +='<ErrorNumber>0</ErrorNumber><ErrorMessage/>';
            sResponse +='<PaymentDetails><PaymentDetails>';
            sResponse +='<TSNumber>'+ (mapParams.containsKey(PARAM_TS1) && String.isNotBlank(mapParams.get(PARAM_TS1)) ? mapParams.get(PARAM_TS1) : '')+'</TSNumber>';
            sResponse +='<DigitalSubscriptionId>0</DigitalSubscriptionId>';
            sResponse +='<PremiumSubscriptionId>175422</PremiumSubscriptionId>';
            sResponse +='<FirstCollectionDate>2015-12-01T00:00:00</FirstCollectionDate>';
            sResponse +='<CollectionFreqency>Irregular</CollectionFreqency>';
            sResponse +='<CollectionDate>1</CollectionDate>';
            sResponse +='<FirstCollectionAmount>19.5000</FirstCollectionAmount>';
            sResponse +='<OnGoingCollectionAmount>19.5000</OnGoingCollectionAmount>';
            sResponse +='<CreditCardNumberLast4Digits>1111</CreditCardNumberLast4Digits>';
            sResponse +='<CreditCardExpiryDate>09/19</CreditCardExpiryDate>';
            sResponse +='<CreditCardAuthCode>9999</CreditCardAuthCode>';
            sResponse +='</PaymentDetails>';
            sResponse +='<PaymentDetails>';
            sResponse +='<TSNumber>' + (mapParams.containsKey(PARAM_TS2) && String.isNotBlank(mapParams.get(PARAM_TS2)) ? mapParams.get(PARAM_TS2) : '')+'</TSNumber>';
            sResponse +='<DigitalSubscriptionId>0</DigitalSubscriptionId>';
            sResponse +='<PremiumSubscriptionId>175422</PremiumSubscriptionId>';
            sResponse +='<FirstCollectionDate>2015-12-01T00:00:00</FirstCollectionDate>';
            sResponse +='<CollectionFreqency>Irregular</CollectionFreqency>';
            sResponse +='<CollectionDate>1</CollectionDate>';
            sResponse +='<FirstCollectionAmount>19.5000</FirstCollectionAmount>';
            sResponse +='<OnGoingCollectionAmount>19.5000</OnGoingCollectionAmount>';
            sResponse +='<CreditCardNumberLast4Digits>1111</CreditCardNumberLast4Digits>';
            sResponse +='<CreditCardExpiryDate>09/18</CreditCardExpiryDate>';
            sResponse +='<CreditCardAuthCode>9999</CreditCardAuthCode>';
            sResponse +='</PaymentDetails></PaymentDetails></PaymentDetailsResult>';
        }else{
            sResponse +='<PaymentDetailsResult xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">';
            sResponse += '<ErrorNumber>0</ErrorNumber><ErrorMessage/>';
            sResponse += '<PaymentDetails><PaymentDetails>';
            sResponse += '<TSNumber>'+(mapParams.containsKey(PARAM_TS1) && String.isNotBlank(mapParams.get(PARAM_TS1)) ? mapParams.get(PARAM_TS1) : 'TS1972835')+'</TSNumber>';
            sResponse += '<DigitalSubscriptionId>0</DigitalSubscriptionId>';
            sResponse += '<PremiumSubscriptionId>174764</PremiumSubscriptionId>';
            sResponse += '<PayerReference>D225523</PayerReference>';
            sResponse += '<AccountNumber>****2222</AccountNumber>';
            sResponse += '<SortCode>000000</SortCode>';
            sResponse += '<FirstCollectionDate>' + (mapParams.containsKey(PARAM_FIRSTCOLLECTION_DATE) && String.isNotBlank(mapParams.get(PARAM_FIRSTCOLLECTION_DATE)) ? mapParams.get(PARAM_FIRSTCOLLECTION_DATE) : '2015-06-01T00:00:00')+'</FirstCollectionDate>';
            sResponse += '<CollectionFreqency>'+(mapParams.containsKey(PARAM_FREQUENCY) && String.isNotBlank(mapParams.get(PARAM_FREQUENCY)) ? mapParams.get(PARAM_FREQUENCY) : 'Monthly')+'</CollectionFreqency>';
            sResponse += '<CollectionDate>'+(mapParams.containsKey(PARAM_COLLECTION_DATE) && String.isNotBlank(mapParams.get(PARAM_COLLECTION_DATE)) ? mapParams.get(PARAM_COLLECTION_DATE) : '1')+'</CollectionDate>';
            sResponse += '<FirstCollectionAmount>39.0000</FirstCollectionAmount>';
            sResponse += '<OnGoingCollectionAmount>39.0000</OnGoingCollectionAmount>';
            sResponse +='<CreditCardNumberLast4Digits>1111</CreditCardNumberLast4Digits>';
            sResponse +='<CreditCardExpiryDate>09/18</CreditCardExpiryDate>';
            sResponse +='<CreditCardAuthCode>9999</CreditCardAuthCode>';
            sResponse += '</PaymentDetails></PaymentDetails></PaymentDetailsResult>';
        }
        return sResponse;
    }   

    /*************************************************************************************** 
    Developer - Wiktor Czykin
    Date - 26/05/2015
    Version - 1.0
    Function - UserOrderHistory MPP request responses
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public static String getTestOrderDetailXML(Map<String,String> mapParams){
        String sResponse = '';
        if(mapParams.containsKey(PARAM_ISFAILURE)){
            sResponse +='<?xml version="1.0" encoding="utf-16"?>';
            sResponse +='<UserOrderHistoryResult xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">';
            sResponse +='<ErrorNumber>12</ErrorNumber>';
            sResponse +='<ErrorMessage>MPP ERROR</ErrorMessage>';
            sResponse +='</UserOrderHistoryResult>';
        }else{
            sResponse +='<UserOrderHistoryResult xmlns="MppGlobal.WCFServices.DataContract.Public.v7_15" xmlns:i="http://www.w3.org/2001/XMLSchema-instance">';
            sResponse +='<ErrorMessage xmlns="MppGlobal.iShop.BusinessObjects.iPayDeveloper.DataContract.v4"/><ErrorNumber xmlns="MppGlobal.iShop.BusinessObjects.iPayDeveloper.DataContract.v4">0</ErrorNumber>';
            sResponse +='<OrderHistoryItems><OrderHistoryItem><Currency>GBP</Currency>';
            sResponse +='<OrderDateUTC>'+(mapParams.containsKey(PARAM_LASTORDER_DATE) && String.isNotBlank(mapParams.get(PARAM_LASTORDER_DATE)) ? mapParams.get(PARAM_LASTORDER_DATE) : '2016-05-13T00:00:00')+'</OrderDateUTC>';
            sResponse +='<OrderDescription>Premium Subscription&lt;div style="font-size:12px;">&lt;br/>Subscription Duration: Continuous&lt;br/>Incentive: &lt;/div></OrderDescription>';
            sResponse +='<OrderId>9474503</OrderId>';
            sResponse +='<PaymentType>DirectDebit</PaymentType>';
            sResponse +='<TaxResult><GrossAmount>39.0000</GrossAmount><NetAmount>33.9130</NetAmount><TaxRegions/><TotalTaxAmount>5.0870</TotalTaxAmount><TotalTaxPercentage>15.00000</TotalTaxPercentage></TaxResult>';
            sResponse +='</OrderHistoryItem></OrderHistoryItems><TotalNumberOfOrders>'+(mapParams.containsKey(PARAM_TOTALORDERS) && String.isNotBlank(mapParams.get(PARAM_TOTALORDERS)) ? mapParams.get(PARAM_TOTALORDERS) : '1')+'</TotalNumberOfOrders></UserOrderHistoryResult>';
        }
        return sResponse;
    }

    /*************************************************************************************** 
    Developer - Wiktor Czykin
    Date - 26/05/2015
    Version - 1.0
    Function - ChangePaymentSchedulePaymentDate MPP request responses
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public static String getTestPaymentScheduleDateChangeXML(Map<String,String> mapParams){
        String sResponse = '';
        if(mapParams.containsKey(PARAM_ISFAILURE)){
            sResponse += '<ChangePaymentSchedulePaymentDateResult xmlns="http://schemas.datacontract.org/2004/07/MppGlobal.iShop.BusinessObjects.iPayDeveloper" xmlns:i="http://www.w3.org/2001/XMLSchema-instance"><ErrorMessage>MPP ERROR</ErrorMessage><ErrorNumber>1000</ErrorNumber></ChangePaymentSchedulePaymentDateResult>';
        }else{
            sResponse += '<ChangePaymentSchedulePaymentDateResult xmlns="http://schemas.datacontract.org/2004/07/MppGlobal.iShop.BusinessObjects.iPayDeveloper" xmlns:i="http://www.w3.org/2001/XMLSchema-instance">';
            sResponse += '<ErrorMessage xmlns="MppGlobal.iShop.BusinessObjects.iPayDeveloper.DataContract.v4"/>';
            sResponse += '<ErrorNumber xmlns="MppGlobal.iShop.BusinessObjects.iPayDeveloper.DataContract.v4">0</ErrorNumber>';
            sResponse += '<ClientReference xmlns="MppGlobal.iShop.BusinessObjects.iPayDeveloper.DataContract.v4"/>';
            sResponse += '<NextPaymentDate xmlns="MppGlobal.iShop.BusinessObjects.iPayDeveloper.DataContract.v4">'+(mapParams.containsKey(PARAM_NEXTPAYMENT_DATE) && String.isNotBlank(mapParams.get(PARAM_NEXTPAYMENT_DATE)) ? mapParams.get(PARAM_NEXTPAYMENT_DATE) : '2016-05-15T00:00:00')+'</NextPaymentDate>';
            sResponse += '<PaymentScheduleId xmlns="MppGlobal.iShop.BusinessObjects.iPayDeveloper.DataContract.v4">12345</PaymentScheduleId>';
            sResponse += '</ChangePaymentSchedulePaymentDateResult>';
        }
        return sResponse;
    }

    /*************************************************************************************** 
    Developer - Wiktor Czykin
    Date - 26/05/2015
    Version - 1.0
    Function - EditPaymentSchedule MPP request responses
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public static String getTestEditPaymentScheduleXML(Map<String,String> mapParams){
        String sResponse = '';
        if(mapParams.containsKey(PARAM_ISFAILURE)){
            sResponse += '<EditPaymentScheduleResult xmlns:a="http://schemas.datacontract.org/2004/07/MppGlobal.iShop.BusinessObjects.iPayDeveloper" xmlns:i="http://www.w3.org/2001/XMLSchema-instance">';
            sResponse += '<ErrorMessage xmlns="MppGlobal.iShop.BusinessObjects.iPayDeveloper.DataContract.v4">MPP ERROR</ErrorMessage>';
            sResponse += '<ErrorNumber xmlns="MppGlobal.iShop.BusinessObjects.iPayDeveloper.DataContract.v4">1000</ErrorNumber>';
            sResponse += '</EditPaymentScheduleResult>';
        }else{
            sResponse += '<EditPaymentScheduleResult xmlns:a="http://schemas.datacontract.org/2004/07/MppGlobal.iShop.BusinessObjects.iPayDeveloper" xmlns:i="http://www.w3.org/2001/XMLSchema-instance">';
            sResponse += '<ErrorMessage xmlns="MppGlobal.iShop.BusinessObjects.iPayDeveloper.DataContract.v4"/>';
            sResponse += '<ErrorNumber xmlns="MppGlobal.iShop.BusinessObjects.iPayDeveloper.DataContract.v4">0</ErrorNumber>';
            sResponse += '<AmountOwedToCustomer xmlns="MppGlobal.iShop.BusinessObjects.iPayDeveloper.DataContract.v4">0</AmountOwedToCustomer>';
            sResponse += '<ClientReference xmlns="MppGlobal.iShop.BusinessObjects.iPayDeveloper.DataContract.v4"/>';
            sResponse += '<PaymentScheduleId xmlns="MppGlobal.iShop.BusinessObjects.iPayDeveloper.DataContract.v4">1101</PaymentScheduleId>';
            sResponse += '<Payments xmlns="MppGlobal.iShop.BusinessObjects.iPayDeveloper.DataContract.v4" xmlns:b="MppGlobal.iPay.BusinessObjects.DataContract.v4">';
            sResponse += '<b:DatedPayment><b:Amount>125.0000</b:Amount><b:Currency>GBP</b:Currency><b:OrderDate>2011-11-30T00:00:00</b:OrderDate></b:DatedPayment>';
            sResponse += '<b:DatedPayment><b:Amount>125</b:Amount><b:Currency>GBP</b:Currency><b:OrderDate>2012-02-29T00:00:00</b:OrderDate></b:DatedPayment>';
            sResponse += '<b:DatedPayment><b:Amount>125</b:Amount><b:Currency>GBP</b:Currency><b:OrderDate>2012-05-29T00:00:00</b:OrderDate></b:DatedPayment>';
            sResponse += '</Payments>';
            sResponse += ' </EditPaymentScheduleResult>';
        }
        return sResponse;
    }

	/*************************************************************************************** 
    Developer - Cristina Popescu
    Date - 17/06/2015
    Version - 1.0
    Function - Digital subscription cancellation MPP request responses
    #############Change Log#############
    Modified by     	Version     Change Date
    Cristina Anghenie	1.1			26/08/2015	//update method to display AutoRenewEnabled based on the method used
    ****************************************************************************************/
    public static String getTestDigitalSubscriptionCancellationXML(Map<String,String> mapParams){
        String sResponse = '';
        if(mapParams.containsKey(PARAM_ISFAILURE)){
            sResponse +='<?xml version="1.0" encoding="utf-16"?>';
            sResponse +='<SetAutoRenewResponse xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">';
            sResponse +='<ErrorNumber>12</ErrorNumber>';
            sResponse +='<ErrorMessage>MPP ERROR</ErrorMessage>';
            sResponse +='</SetAutoRenewResponse>';
        }else{
        	sResponse +='<SetAutoRenewResult xmlns="http://schemas.datacontract.org/2004/07/MppGlobal.iShop.BusinessObjects.iPayDeveloper" xmlns:i="http://www.w3.org/2001/XMLSchema-instance">';
   			sResponse +='<ErrorMessage xmlns="MppGlobal.iShop.BusinessObjects.iPayDeveloper.DataContract.v4"/>';
   			sResponse +='<ErrorNumber xmlns="MppGlobal.iShop.BusinessObjects.iPayDeveloper.DataContract.v4">0</ErrorNumber>';
   			sResponse +='<AutoRenewEnabled xmlns="MppGlobal.iShop.BusinessObjects.iPayDeveloper.DataContract.v4">'+mapParams.get(PARAM_IS_RENEWAL)+'</AutoRenewEnabled>';
   			sResponse +='<ServiceId xmlns="MppGlobal.iShop.BusinessObjects.iPayDeveloper.DataContract.v4">11326</ServiceId>';
			sResponse +='</SetAutoRenewResult>';
        }
        return sResponse;
    }
    
    /*************************************************************************************** 
    Developer - Cristina Popescu
    Date - 11/09/2015
    Version - 1.0
    Function - CancelPaymentSchedule MPP Response
    #############Change Log#############
    Modified by     	Version     Change Date
    ****************************************************************************************/
    public static String getCancelPaymentScheduleXML(Map<String,String> mapParams){
        String sResponse = '';
        if(mapParams.containsKey(PARAM_ISFAILURE)){
            sResponse +='<?xml version="1.0" encoding="utf-16"?>';
            sResponse +='<CancelPaymentScheduleResult xmlns:a="http://schemas.datacontract.org/2004/07/MppGlobal.iShop.BusinessObjects.iPayDeveloper" xmlns:i="http://www.w3.org/2001/XMLSchema-instance">';
            sResponse +='<ErrorNumber>77</ErrorNumber>';
            sResponse +='<ErrorMessage>MPP ERROR</ErrorMessage>';
            sResponse +='</CancelPaymentScheduleResult>';
        }else{
        	sResponse +='<CancelPaymentScheduleResult xmlns:a="http://schemas.datacontract.org/2004/07/MppGlobal.iShop.BusinessObjects.iPayDeveloper" xmlns:i="http://www.w3.org/2001/XMLSchema-instance">';
   			sResponse +='<ErrorMessage xmlns="MppGlobal.iShop.BusinessObjects.iPayDeveloper.DataContract.v4"/>';
   			sResponse +='<ErrorNumber xmlns="MppGlobal.iShop.BusinessObjects.iPayDeveloper.DataContract.v4">0</ErrorNumber>';
   			sResponse +='<CurrencyOfCancelledPayments xmlns="MppGlobal.iShop.BusinessObjects.iPayDeveloper.DataContract.v4">'+mapParams.get(PARAM_CURRENCY)+'</CurrencyOfCancelledPayments>';
   			sResponse +='<GrossAmountOfCancelledPayments xmlns="MppGlobal.iShop.BusinessObjects.iPayDeveloper.DataContract.v4">'+mapParams.get(PARAM_AMOUNT)+'</GrossAmountOfCancelledPayments>';
			sResponse +='<NumberOfCancelledPayments xmlns="MppGlobal.iShop.BusinessObjects.iPayDeveloper.DataContract.v4">'+mapParams.get(PARAM_NOSCHEDULES)+'</NumberOfCancelledPayments>';
			sResponse +='<PaymentScheduleId xmlns="MppGlobal.iShop.BusinessObjects.iPayDeveloper.DataContract.v4">'+mapParams.get(PARAM_PAYMENTSCHID)+'</PaymentScheduleId>';
 			sResponse +='</CancelPaymentScheduleResult>';
        }
        return sResponse;
    }
    
    /*************************************************************************************** 
    Developer - Cristina Popescu
    Date - 07/10/2015
    Version - 1.0
    Function - UserInfo MPP Response
    #############Change Log#############
    Modified by     	Version     Change Date
    ****************************************************************************************/
    public static String getUserInfoXML(Map<String,String> mapParams){
        String sResponse = '';
        if(mapParams.containsKey(PARAM_ISFAILURE)){
            sResponse +='<?xml version="1.0" encoding="utf-16"?>';
            sResponse +='<UserInfoResult xmlns:a="http://schemas.datacontract.org/2004/07/MppGlobal.iShop.BusinessObjects.iPayDeveloper" xmlns:i="http://www.w3.org/2001/XMLSchema-instance">';
            sResponse +='<ErrorNumber>77</ErrorNumber>';
            sResponse +='<ErrorMessage>'+mapParams.get(PARAM_FAILUREREASON)+'</ErrorMessage>';
            sResponse +='</UserInfoResult>';
        }else{
        	sResponse +='<UserInfoResult xmlns:a="http://schemas.datacontract.org/2004/07/MppGlobal.iShop.BusinessObjects.iPayDeveloper" xmlns:i="http://www.w3.org/2001/XMLSchema-instance">';
   			sResponse +='<ErrorMessage xmlns="MppGlobal.iShop.BusinessObjects.iPayDeveloper.DataContract.v4"/>';
   			sResponse +='<ErrorNumber xmlns="MppGlobal.iShop.BusinessObjects.iPayDeveloper.DataContract.v4">0</ErrorNumber>';
   			sResponse +='<AccountDetailParameters>';
   			sResponse +='<AccountParameter><ParameterName>SAM_GUID</ParameterName><ParameterValue>7d7a3c51-019c-405a-934b-fb9b728e1eec</ParameterValue></AccountParameter>';
			sResponse +='<AccountParameter><ParameterName>TSNumber</ParameterName><ParameterValue>TS9899999</ParameterValue></AccountParameter>';
			sResponse +='</AccountDetailParameters>';
 			sResponse +='<AccountStatus>Active</AccountStatus>';
 			sResponse +='<AccountType>Unspecified</AccountType>';
 			sResponse +='<Address><City/><Country/><District/><HouseFlatNumber/><HouseName/><PostCode/><Street/></Address><ClientUserId/>';
 			sResponse +='<CreditCard xmlns:b="MppGlobal.iShop.BusinessObjects.iPayDeveloper.DataContract.v4">';
 			sResponse +='<CreditCardType>Visa</CreditCardType><DateValidated>2013-09-16T11:40:57.787</DateValidated><ExpiryDate>04/15</ExpiryDate><IsValidated>true</IsValidated><LastFourDigits>1111</LastFourDigits></CreditCard>';
        	sResponse +='<CreditsOnAccount xmlns:b="MppGlobal.iShop.BusinessObjects.iPayDeveloper.DataContract.v4"><CreditAmounts/></CreditsOnAccount>';
        	sResponse +='<DateOfBirth>0001-01-01T00:00:00</DateOfBirth><AccountStatus>Active</AccountStatus>';
        	sResponse +='<EmailAddress>'+mapParams.get(PARAM_EMAIL)+'</EmailAddress>';
	        sResponse +='<FirstName>d</FirstName>';
	        sResponse +='<Gender>Male</Gender>';
	        sResponse +='<Guid>9496a3c9d32b4374ba89fb51df637d03</Guid>';
	        sResponse +='<HasFailedPostPayOrders>false</HasFailedPostPayOrders>';
	        sResponse +='<Nickname>d</Nickname>';
	        sResponse +='<PhoneNumbers xmlns:b="MppGlobal.iShop.BusinessObjects.iPayDeveloper.DataContract.v4"/>';
	        sResponse +='<PreferredCurrency>GBP</PreferredCurrency>';
	        sResponse +='<RequiresUserPassword>false</RequiresUserPassword>';
	        sResponse +='<Surname>morris</Surname>';
	        sResponse +='<UnpaidPostPayOrderBalance>0.0000</UnpaidPostPayOrderBalance>';
	        sResponse +='<UserPassword>3y&amp;NzQ8?2}</UserPassword>';
	        sResponse +='</UserInfoResult>';
        }
        return sResponse;
    }

	/************************************************************************************
    Developer - Wiktor Czykin 
    Date - 15/05/2015
    Version - 1.0
    Function - mock for MPP UserManage request - positive
    #############Change Log#############
    Modified by     Version     Change Date
    *************************************************************************************/
	public static StaticResourceCalloutMock getMPPUserManageSuccessMock(){
		StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('MPPUserManageRESTResponseSuccess');
        mock.setStatusCode(200);
        return mock;
    }

    /************************************************************************************
    Developer - Wiktor Czykin 
    Date - 15/05/2015
    Version - 1.0
    Function - mock for MPP UserManage request - negative
    #############Change Log#############
    Modified by     Version     Change Date
    *************************************************************************************/
	public static StaticResourceCalloutMock getMPPUserManageFailureMock(){
		StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('MPPUserManageRESTResponseFailure');
        mock.setStatusCode(200);
        return mock;
    }

    /************************************************************************************
    Developer - Wiktor Czykin 
    Date - 15/05/2015
    Version - 1.0
    Function - mock for MPP UserManage request - negative
    #############Change Log#############
    Modified by     Version     Change Date
    *************************************************************************************/
    public static StaticResourceCalloutMock getMPPUserManageFailureWithMessageMock(){
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('MPPUserManageRESTResponseFailureWithMessage');
        mock.setStatusCode(200);
        return mock;
    }

    /*************************************************************************************** 
    Developer - Wiktor Czykin 
    Date - 14/05/2015
    Version - 1.0
    Function - mock for MPPBulkInterface.BulkCancelPaymentSchedule()
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
	public class MPPBulkCancelPaymentScheduleMock implements WebServiceMock{
		public void doInvoke( Object stub, Object request, Map<String, Object> response, String endpoint, String soapAction, String requestName, String responseNS, String responseName, String responseType) {
	        MPPBulkInterface.BulkCancelPaymentScheduleResponse_element responseObj = new MPPBulkInterface.BulkCancelPaymentScheduleResponse_element();
	        MPPBusinessObjectsIPaydev.BulkUpdateResultData innerResponse = new MPPBusinessObjectsIPaydev.BulkUpdateResultData();
	        innerResponse.ErrorMessage = '';
	        innerResponse.BulkUpdateJobId = 1234;
			innerResponse.ErrorNumber = 0;
	        responseObj.BulkCancelPaymentScheduleResult = innerResponse;
	        response.put('response_x', responseObj); 
   		}
	}

	/*************************************************************************************** 
    Developer - Wiktor Czykin 
    Date - 14/05/2015
    Version - 1.0
    Function - mock for MPPBulkInterface.BulkUserManage()
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
	public class MPPBulkChangePaymentSchedulePaymentDateMock implements WebServiceMock{
		public void doInvoke( Object stub, Object request, Map<String, Object> response, String endpoint, String soapAction, String requestName, String responseNS, String responseName, String responseType) {
	        MPPBulkInterface.BulkChangePaymentSchedulePaymentDateResponse_element responseObj = new MPPBulkInterface.BulkChangePaymentSchedulePaymentDateResponse_element();
	        MPPBusinessObjectsIPaydev.BulkUpdateResultData innerResponse = new MPPBusinessObjectsIPaydev.BulkUpdateResultData();
	        innerResponse.ErrorMessage = '';
	        innerResponse.BulkUpdateJobId = 1234;
			innerResponse.ErrorNumber = 0;
	        responseObj.BulkChangePaymentSchedulePaymentDateResult = innerResponse;
	        response.put('response_x', responseObj); 
   		}
	}

	/*************************************************************************************** 
    Developer - Wiktor Czykin 
    Date - 14/05/2015
    Version - 1.0
    Function - mock for MPPBulkInterface.BulkChangePaymentSchedulePaymentDate()
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
	public class MPPBulkUserUpdateMock implements WebServiceMock{
		public void doInvoke( Object stub, Object request, Map<String, Object> response, String endpoint, String soapAction, String requestName, String responseNS, String responseName, String responseType) {
	        MPPBulkInterface.BulkUserManageResponse_element responseObj = new MPPBulkInterface.BulkUserManageResponse_element();
	        MPPBusinessObjectsIPaydev.BulkUpdateResultData innerResponse = new MPPBusinessObjectsIPaydev.BulkUpdateResultData();
	        innerResponse.ErrorMessage = '';
	        innerResponse.BulkUpdateJobId = 1234;
			innerResponse.ErrorNumber = 0;
	        responseObj.BulkUserManageResult = innerResponse;
	        response.put('response_x', responseObj); 
   		}
	}
	
	/*************************************************************************************** 
    Developer - Cristina Anghenie
    Date - 18/08/2015
    Version - 1.0
    Function - mock for MppPaymentInterface.CreateSessionResult()
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
	public class MppPaymentInterfaceMock implements WebServiceMock{
		public void doInvoke( Object stub, Object request, Map<String, Object> response, String endpoint, String soapAction, String requestName, String responseNS, String responseName, String responseType) {
	        MppPaymentInterface.CreateSessionResult responseObj = new MppPaymentInterface.CreateSessionResult();
	        responseObj.Guid = 'testguid123';
	        responseObj.ErrorMessage = '';
			responseObj.ErrorNumber = 0;
	        response.put('response_x', responseObj); 
   		}
	}
	
	/*************************************************************************************** 
    Developer - Wiktor Czykin
    Date - 15/12/2015
    Version - 1.0
    Function - 
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
	public class MppCreateSessionMock implements WebServiceMock{
		public void doInvoke( Object stub, Object request, Map<String, Object> response, String endpoint, String soapAction, String requestName, String responseNS, String responseName, String responseType) {
	        MppPaymentInterface.CreateSessionBySOAPResponse_element responseObject = new MppPaymentInterface.CreateSessionBySOAPResponse_element();
	        MppPaymentInterface.CreateSessionResult createSessionResult = new MppPaymentInterface.CreateSessionResult();
	        createSessionResult.Guid = 'testguid123';
	        createSessionResult.ErrorMessage = '';
			createSessionResult.ErrorNumber = 0;
	        responseObject.CreateSessionBySOAPResult = createSessionResult;
	        response.put('response_x', responseObject); 
   		}
	}

    /**
    * @author Wiktor Czykin
    * @date 26/05/2015
    * @description  HTTP callouts response mock generator
    #############Change Log#############
    Modified by     Version     Change Date
    **/
    public class MPPHttpResponseGenerator implements HttpCalloutMock{
        public Map<String, String> mapParams{get;set;}
        private String sBaseUrl{get;set;}

        /*************************************************************************************** 
        Developer - Wiktor Czykin
        Date - 26/05/2015
        Version - 1.0
        Function - constructor - needs baseUrl to generate map with mappings and optional map of parameters
        #############Change Log#############
        Modified by     Version     Change Date
        ****************************************************************************************/
        public MPPHttpResponseGenerator(String sBaseUrl, Map<String, String> mapParams){
            this.mapParams = mapParams;
            this.sBaseUrl = sBaseUrl;
            MPPWebserviceMocks.initializeEndpoints(this.sBaseUrl);
        }

        /*************************************************************************************** 
        Developer - Wiktor Czykin
        Date - 26/05/2015
        Version - 1.0
        Function - implemented method that returns response visible in the test flow
        #############Change Log#############
        Modified by     Version     Change Date
        ****************************************************************************************/
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/xml');
            res.setBody(getRequestEndpointData(req));
            res.setStatusCode(200);
            return res;
        }
        
        /*************************************************************************************** 
        Developer - Wiktor Czykin
        Date - 26/05/2015
        Version - 1.0
        Function - method that returns proper xml depending on the enpoint
        #############Change Log#############
        Modified by     Version     Change Date
        ****************************************************************************************/
        private String getRequestEndpointData(HTTPRequest req){
            String sEndpoint = req.getEndpoint();
            sEndpoint = sEndpoint.substringBefore('?');
            if(!MPPWebserviceMocks.MAP_ENDPOINT_RESPONSE.containsKey(sEndpoint)) throw new TelegraphApplicationException('MPP endpoint not handled in test response generation:'+sEndpoint);

            String sResponseType = MPPWebserviceMocks.MAP_ENDPOINT_RESPONSE.get(sEndpoint);
            String sResponse;
            if(sResponseType == MPPREQUEST_BULKPAYMENTDETAILS){
                sResponse = MPPWebserviceMocks.getTestPaymentDetailXML(this.mapParams);
            }else if(sResponseType == MPPREQUEST_ORDERHISTORY){
                sResponse = MPPWebserviceMocks.getTestOrderDetailXML(this.mapParams);
            }else if(sResponseType == MPPREQUEST_CHANGEPAYMENTSCHEDULEDATE){
                sResponse = MPPWebserviceMocks.getTestPaymentScheduleDateChangeXML(this.mapParams);
            }else if(sResponseType == MPPREQUEST_EDITPAYMENTSCHEDULE){
                sResponse = MPPWebserviceMocks.getTestEditPaymentScheduleXML(this.mapParams);
            }else if(sResponseType == MPPREQUEST_SETAUTORENEW){
            	sResponse = MPPWebserviceMocks.getTestDigitalSubscriptionCancellationXML(this.mapParams);
            }else if(sResponseType == MPPREQUEST_CANCELPAYMENTSCHEDULE){
            	sResponse = MPPWebserviceMocks.getCancelPaymentScheduleXML(this.mapParams);
            }else if(sResponseType == MPPREQUEST_USERINFO){
            	sResponse = MPPWebserviceMocks.getUserInfoXML(this.mapParams);
            }   
            return sResponse;
        }
    }
}