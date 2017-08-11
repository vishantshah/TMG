/**
* @author Unknown
* @date Unknown
* @description MPP related methods - eg. sending of CreateSession request
#############Change Log#############
Modified by         Change Date
Wiktor Czykin       10/07/2015  //modified goToMppPayment()
Cristina Anghenie   09/09/2015  //create back method to return to OAPSubscriptionTMG page
Wiktor Czykin       14/09/2015  //modified back();
Cristina A          29/09/2015  //modified getPaymentDetails();
Wiktor Czykin       05/09/2015  //added low start parameters to support summary page
Wiktor Czykin       20/10/2015  //added extra param passing from and back to OapSubscriptionTMG and modified offset for low start schedule preparation for CC payment method
Wiktor Czykin       21/10/2015  //modified default constructor
Wiktor Czykin       22/10/2015  //modified constructor
Wiktor Czykin       11/11/2015  //added support for restart flow
Wiktor Czykin       11/2015       //added createSessionCallout(), modidified goToMppPayment()
Wiktor Czykin       15/12/2015  //replaced string with constant in createSessionCallout()
Wiktor Czykin       15/02/2016  //modified getRequestValues(), generatePaymentScheduleForLowStart() and goToPremiumContinuousPayment(), back(), added new class attributes
Wiktor Czykin       08/02/2016  //added generatePaymentSchedule()
Michal Szewczyk     05/05/2016  //changed goToPremiumContinuousPayment()
Wiktor Czykin       10/05/2016  //modified paymentPage(), added productId to parameter fetching, modified goToPremiumContinuousPayment()
Wiktor Czykin       27/05/2016  //modified goToPremiumContinuousPayment()
Pawel Chrzanowski   22/09/2016  //added isOCRS parameter
Michal Szewczyk     19/10/2016  //added oneOffPayment reason
Vishant Shah        03/11/2016  //Added check for One time payment reason for SubscriptionOneOffPaymentAmount vfp 5943
Wiktor Czykin       16/01/2017  //Modified getRequestValues()
Wiktor Czykin       03/03/2017  //Modified goToPremiumContinuousPayment()
Pawel Chrzanowski   13/04/2017  //Added tcodeName
Wiktor Czykin       15/07/2017  //Added tcodeName population for digital acquisition
Konrad Czykin       20/04/2017  //modified goToMppPayment()
Mantas G.           09/06/2017  //added parameter if the payment is from OC DDCX 

Vishant Shah        10/08/2017  //added subscriptionName
**/
public with sharing class MppUtil {

    public static final String CREATESESSION_RESULT_WLOG_KEY = 'wlog';
    public static final String CREATESESSION_RESULT_MPPRESULT_KEY = 'mppresponse';

    public static final String PAYMENTMETHOD_CC = 'CC';
    public static final String PAYMENTMETHOD_DD = 'DD';

    private static final String MPP_URL;
    private static final String BASE_MPP_URL;
    private static final Integer MPP_LOGIN;
    private static final String MPP_PASSWORD;
    private static final String DIGITAL_MONTHLY;
    private static final String DIGITAL_ANNUALLY;
    private static final String PREMIUM_CONTINUOUS;

    static{
        PlaneURL__c customSetting = PlaneURL__c.getInstance('MPP');
        if(customSetting == null || String.isBlank(customSetting.URL__c) ||  String.isBlank(customSetting.baseURL__c) || String.isBlank(customSetting.login__c) || String.isBlank(customSetting.password__c)) throw new TelegraphApplicationException('Could not initialize payment. Settings missing in SFDC.');

        MPP_URL = customSetting.URL__c;
        BASE_MPP_URL = customSetting.baseURL__c;
        MPP_LOGIN = Integer.valueOf(customSetting.login__c);
        MPP_PASSWORD = customSetting.password__c;
        DIGITAL_ANNUALLY = customSetting.Digital_Annually_ID__c;
        DIGITAL_MONTHLY = customSetting.Digital_Monthly_ID__c;
        PREMIUM_CONTINUOUS = customSetting.Premium_Continuous_ID__c;
    }

    //holidays offset calculation vars
    private static List<HolidayRange> lstHolidays;
    private static Boolean bScope = false;

    public String resultString{get;set;}
    public PageReference prMpp {get;set;}
    public ConfirmationDetails confirmationDetails{get;set;}
    public String AccId {get;set;}
    public String PaymentMethod;
    public String PaymentFrequency{get; set;}
    public String retailerId;
    public String sDuration;
    public String sRestart;
    public String oneOffProductType;
    public String oneOffAmount {get; set;}
    public String oneOffPaymentReason {get; set;}
    public String tcodeName {get;set;}
    public String subscriptionName { get; set; }

    public MPPInterfaceHTTP.PaymentDetailResult paymentDetails {get; private set;}
    public String tsNumberDisplay {get; set;}
    public String incentiveMsg {get; private set;}
    public Boolean isOneOffPayment {get; private set;}
    public String paymentDateText {get; private set;}
    public String subscriberProductType {get; set;}
    public PaymentSetupWrapper paymentSetup{get;set;}
    public Boolean isOCDDCX {get;set;}


    private String selectedProduct;
    private String selectedOffer;
    private String TSNumber;
    private String email;
    private String title;
    private String otherTitle;
    private String firstName;
    private String lastName;
    private Decimal price;
    private String subscriptionType;
    private String POC;
    private String TCode;
    private String IncentiveId;
    private String IncentiveDescription;
    private String Guid;
    private Decimal forcedLowStartWeeklyPrice;
    private Decimal forcedWeeklyPrice;
    private String paymentStartDate;
    private String productId;
    private Boolean isRenew;
    private Boolean isOutbound;
    private Boolean isOCRS;
    private String ocrsCase;
    private OrderTakenDetails fieldMap = new OrderTakenDetails();
    private Subscription__c subscription;
    private Account subscriber;
    private ID currentId;
    private String subId;

    /***************************************************************************************
    * @author Unknown
    * @date Unknown
    * @description Constructor
    #############Change Log#############
    Modified by         Change Date
    Wiktor Czykin       06/09/2015  //cleaned up a bit
    Wiktor Czykin       21/10/2015  //modified payment details to also set paymentDateText value for CC
    Wiktor Czykin       22/10/2015  //added if in payment details fetching to prevent exceptions
    Pawel Chrzanowski   13/04/2017  //added tcodeName
    Wiktor Czykin       15/06/2017  //added tcodeName setting based on Account Wave Id for digital sub
    Mantas G.           09/06/2017  //added parameter if the payment is from OC DDCX 
    Vishant Shah        10/08/2017  //added subscriptionName
***************************************************************************************/
    public MppUtil(){
        Map<String, String> mapParams = ApexPages.currentPage().getParameters();
        System.debug('TMGLOG::MPPUtil:Constructor:PARAMS: '+ JSON.serialize(mapParams));
        String accId = mapParams.get('accId');
        String incentiveMsg = mapParams.get('incentiveMsg');
        if(TMGUtil.isDataValid(incentiveMsg)){
            this.incentiveMsg = EncodingUtil.urlDecode(incentiveMsg, 'UTF-8');
        }
        this.isOneOffPayment = (mapParams.get('isOneOffPayment') == 'true');
        this.isOCDDCX = (mapParams.get('isOCDDCX') == null ? false : mapParams.get('isOCDDCX') == 'true');

        Subscription__c currentSub = null;
        Account acc = null;
        Id digitalRecordTypeId = RecordTypeUtility.getRecordTypeId(Account.SObjectType, Constants.RECTYPE_DIGISUB, Account.class.getName());

        if(accId != null){
            List<Account> lstAccount = [SELECT  email_sent__c,
                                                Subscriber_Number_Static__c,
                                                Digital_Product_Type__c,
                                                PersonMailingStreet,
                                                IsPersonAccount,
                                                RecordTypeId,
                                                PersonEmail,
                                                Wave_ID__c,
                                                (SELECT Id,
                                                        Name,
                                                        Payment_Type__c,
                                                        PaymentDate__c,
                                                        Subscription_Duration_Picklist__c,
                                                        Total_Price__c,
                                                        isContinuous__c,
                                                        Start_Date__c,
                                                        End_Date__c,
                                                        MPP_Irregular_Payment_Schedule__c,
                                                        Low_Start_Period__c,
                                                        RecordTypeId, 
                                                        Tcode__r.Name 
                                                    FROM Subscriptions1__r
                                                    ORDER BY LastModifiedDate DESC LIMIT 1)
                                            FROM Account WHERE Id = :accId];

            if(lstAccount.isEmpty()) return;

            acc = lstAccount[0];
            if(!acc.Subscriptions1__r.isEmpty()){
                currentSub = acc.Subscriptions1__r[0];
                System.debug('TMGLOG::MPPUtil:Constructor:Current Subcription id is: '+currentSub.Id);
            }

            tsNumberDisplay = acc.Subscriber_Number_static__c;
            if(acc.RecordTypeId == digitalRecordTypeId){
                this.oneOffProductType = Constants.PRODUCT_DIGITAL;
                this.subscriberProductType = Constants.PRODUCT_DIGITAL;
            }else if(acc.RecordTypeId == RecordTypeUtility.getRecordTypeId(Account.SObjectType, Constants.RECTYPE_INDIVSUB, Account.class.getName())){
                this.oneOffProductType = Constants.PRODUCT_PREMIUM;
                this.subscriberProductType = Constants.PRODUCT_PREMIUM;
            }
        }

        if (currentSub != null){
            this.confirmationDetails = new ConfirmationDetails();
            this.confirmationDetails.duration = currentSub.Subscription_Duration_Picklist__c;
            this.confirmationDetails.price = currentSub.Total_Price__c;
            this.confirmationDetails.paymentType = currentSub.Payment_Type__c;
            this.confirmationDetails.isContinuous = currentSub.isContinuous__c;
            this.confirmationDetails.startDate = currentSub.Start_Date__c.format() ;
            this.confirmationDetails.endDate = currentSub.End_Date__c.format() ;
            this.tcodeName = currentSub.Tcode__r.Name;
            this.subscriptionName = currentSub.Name;
        }
        if(String.isBlank(this.tcodeName) && acc != null && acc.RecordTypeId == digitalRecordTypeId){
            this.tcodeName = acc.Wave_ID__c;
        }

        if(!isOneOffPayment){
            try{
                PaymentSetupWrapper psw;
                if(currentSub.RecordTypeId == RecordTypeUtility.getRecordTypeId(Subscription__c.SObjectType, Constants.RECTYPE_SUBSCRIPTION_LOWSTART, Subscription__c.class.getName()) && String.isNotBlank(currentSub.MPP_Irregular_Payment_Schedule__c)){
                    psw = (PaymentSetupWrapper)JSON.deserialize(currentSub.MPP_Irregular_Payment_Schedule__c, PaymentSetupWrapper.class);
                    this.paymentSetup = psw;
                }
                this.paymentDetails = this.getPaymentDetails(mapParams.get('PaymentStatus'), acc, currentSub, mapParams.get('paymentFrequency'), psw);
                if(this.paymentDetails != null){
                    if(oneOffProductType == Constants.PRODUCT_PREMIUM && currentSub != null && currentSub.PaymentDate__c != null){
                        this.paymentDateText = currentSub.PaymentDate__c + TMGDateExtension.GetDayOfMonthSuffix(Integer.valueOf(currentSub.PaymentDate__c));
                    }
                    if(oneOffProductType == Constants.PRODUCT_DIGITAL && paymentDetails.payerRef != null && paymentDetails.payerRef.length() > 0 && paymentDetails.firstCollectionDate != null){
                        this.paymentDetails.firstCollectionDate = TMGDateExtension.GetNextWorkingDate(Date.today(), 8, TMGDateExtension.GetHolidayMap()).format();
                    }
                    if(String.isNotBlank(this.paymentDetails.collectionDate)){
                        this.paymentDetails.collectionDate = paymentDetails.collectionDate + TMGDateExtension.GetDayOfMonthSuffix(Integer.valueOf(paymentDetails.collectionDate));
                    }
                    if(paymentDetails.firstCollectionDate == '01/01/0001'){
                        this.paymentDetails = null;
                    }
                }
            }catch(System.Exception e){
                System.debug('TMGLOG::MPPUtil:Constructor:Error in getPaymentDetails MPPUtil: ' + e);
            }
        }
    }

    /***************************************************************************************
    * @author Unknown
    * @date Unknown
    * @description Constructor supporting standard controller
    #############Change Log#############
    Modified by         Version     Change Date
    Wiktor Czykin   1.1         20/11/2015  //removed init call
    ***************************************************************************************/
    public MppUtil(ApexPages.StandardController controller){
        if(controller.getRecord().getSobjectType() == Subscription__c.sObjectType){
            this.subscription = (Subscription__c)controller.getRecord();
            this.currentId = this.subscription.Id;
            this.oneOffProductType = Constants.PRODUCT_PREMIUM;
        }
        if(controller.getRecord().getSobjectType() == Account.sObjectType){
            this.subscriber = (Account)controller.getRecord();
            this.currentId = this.subscriber.Id;
            if(this.subscriber.RecordTypeId == RecordTypeUtility.getRecordTypeId(Account.SObjectType, Constants.RECTYPE_DIGISUB, Account.class.getName())){
                this.oneOffProductType = Constants.PRODUCT_DIGITAL;
            }else if(this.subscriber.RecordTypeId == RecordTypeUtility.getRecordTypeId(Account.SObjectType, Constants.RECTYPE_INDIVSUB, Account.class.getName())){
                this.oneOffProductType = Constants.PRODUCT_PREMIUM;
            }
        }
    }

    /***************************************************************************************
    * @author Unknown
    * @date Unknown
    * @description Method to return details about payment success info on recent subscription
    #############Change Log#############
    Modified by         Version     Change Date
    Cristina Anghenie   1.1         17/08/2015  //use constants and update method to get info using UserOrderHistoryResult
    Cristina Anghenie   1.2         29/09/2015  //add TS number to getUserOrderHistoryResult method to fix payment details if there is no email address
    Wiktor Czykin       1.3         06/09/2015  //changed method signature - removed refetching of data
                                                //added low start fields population
    ***************************************************************************************/
    private MPPInterfaceHTTP.PaymentDetailResult getPaymentDetails(String paymentStatus, Account acc, Subscription__c sub, String sFrequency, PaymentSetupWrapper psw){
        MPPInterfaceHTTP.PaymentDetailResult paymentDetails = new MPPInterfaceHTTP.PaymentDetailResult();
        if(String.isBlank(paymentStatus) || acc == null || sub == null) return null;

        try{
            if(paymentStatus.contains(Constants.ORDER_SUCCESS_STATUS_VALUE)){
                MPPInterfaceHTTP mppRest = new MPPInterfaceHTTP();
                MPPInterfaceHTTP.UserOrderHistoryResult mppOrderHistory = mppRest.getUserOrderHistoryResult(acc.PersonEmail, acc.Subscriber_Number_Static__c, String.ValueOf(Date.ValueOf(System.today())), String.ValueOf(Date.ValueOf(sub.End_Date__c)), true);
                Integer iFirstIndex = 0;
                if(psw != null){
                    paymentDetails.lowStartFirstCollectionAmount = String.valueOf(Decimal.valueOf(mppOrderHistory.OrderHistoryItems[iFirstIndex].GrossAmount).setScale(2));
                    paymentDetails.lowStartFirstCollectionDate = String.valueOf(MPPLetterExtractData.getDate(mppOrderHistory.OrderHistoryItems[iFirstIndex].OrderDate));
                    if(psw.iNumberOfPaymentsLowStart > 1){
                        paymentDetails.lowStartOngoingCollectionAmount = String.valueOf(Decimal.valueOf(mppOrderHistory.OrderHistoryItems[iFirstIndex+1].GrossAmount).setScale(2));
                    }
                    iFirstIndex = psw.iSwitchOrderIndex;
                }

                paymentDetails.firstCollectionAmount = String.valueOf(Decimal.valueOf(mppOrderHistory.OrderHistoryItems[iFirstIndex].GrossAmount).setScale(2));
                paymentDetails.firstCollectionDate = String.valueOf(MPPLetterExtractData.getDate(mppOrderHistory.OrderHistoryItems[iFirstIndex].OrderDate));
                if(mppOrderHistory.OrderHistoryItems.size() > (iFirstIndex+1)){
                    paymentDetails.ongoingCollectionAmount = String.valueOf(Decimal.valueOf(mppOrderHistory.OrderHistoryItems[iFirstIndex+1].GrossAmount).setScale(2));
                }
                paymentDetails.collectionFreq = sFrequency;
            }
        }catch(MPPInterfaceHTTP.MPPInterfaceHTTPException e){
            System.debug('TMGLOG::MPPUtil:getPaymentDetails:Error in GetPaymentDetails: ' + e);
            paymentDetails = null;
        }
        System.debug('TMGLOG::MPPUtil:getPaymentDetails:PAYMENT DETAILS: ' + paymentDetails);
        return paymentDetails;
    }


    /*
    *   Initialization of the values needed by Mpp from the Subscription
    */
    private void getRequestValuesFromSub(Double transactionPrice){
        this.subscription = [SELECT id, subscriber__r.Subscriber_Number_static__c, subscriber__r.Salutation, subscriber__r.FirstName,
                                    subscriber__r.LastName, subscriber__r.personEmail, TCode__r.name,
                                    subscriber__r.Guid__c, Order_Taken_Date__c, Order_Taken_Wave__c, Order_Taken_Method__c,
                                    Order_Taken_By_Company__c, Order_Taken_By_User_Department__c
                                    FROM Subscription__c
                                    WHERE id=:this.subscription.id];

        selectedProduct =       Constants.PRODUCT_PREMIUM;
        TSNumber =              this.subscription.subscriber__r.Subscriber_Number_static__c;
        email =                 this.subscription.subscriber__r.personEmail;
        title =                 this.subscription.subscriber__r.Salutation;
        firstName =             this.subscription.subscriber__r.FirstName;
        lastName =              this.subscription.subscriber__r.LastName;
        price =                 transactionPrice;
        POC =                   null;
        TCode =                 this.subscription.TCode__r.name;
        IncentiveId =           null;
        IncentiveDescription =  null;
        Guid =                  this.subscription.subscriber__r.Guid__c;
        AccId =                 this.subscription.subscriber__r.id;
        subId =                 this.subscription.Id;
    }

    private void getRequestValuesFromSub(String recordId, Double transactionPrice){
        this.subscription = [SELECT id, subscriber__r.Subscriber_Number_static__c, subscriber__r.Salutation, subscriber__r.FirstName,
                                    subscriber__r.LastName, subscriber__r.personEmail, TCode__r.name,
                                    subscriber__r.Guid__c, Order_Taken_Date__c, Order_Taken_Wave__c, Order_Taken_Method__c,
                                    Order_Taken_By_Company__c, Order_Taken_By_User_Department__c, Total_Price__c
                                    FROM Subscription__c
                                    WHERE id = :recordId];

        selectedProduct =       Constants.PRODUCT_PREMIUM;
        TSNumber =              this.subscription.subscriber__r.Subscriber_Number_static__c;
        email =                 this.subscription.subscriber__r.personEmail;
        title =                 this.subscription.subscriber__r.Salutation;
        firstName =             this.subscription.subscriber__r.FirstName;
        lastName =              this.subscription.subscriber__r.LastName;
        price =                 transactionPrice;
        POC =                   null;
        TCode =                 this.subscription.TCode__r.name;
        IncentiveId =           null;
        IncentiveDescription =  null;
        Guid =                  this.subscription.subscriber__r.Guid__c;
        AccId =                 this.subscription.subscriber__r.id;
        subId =                 this.subscription.Id;
    }

    private void getRequestValuesFromAccount(String recordId, Double transactionPrice, String productType){
        this.subscriber = [SELECT Id, Subscriber_Number_static__c, Salutation, FirstName, LastName,
                                  PersonEmail, PersonMailingStreet, IsPersonAccount, Guid__c, Wave_ID__c,
                                  RecordTypeId FROM Account WHERE Id = :recordId];

        selectedProduct =       productType;//'Digital';
        TSNumber =              this.subscriber.Subscriber_Number_static__c;
        email =                 this.subscriber.personEmail;
        title =                 this.subscriber.Salutation;
        firstName =             this.subscriber.FirstName;
        lastName =              this.subscriber.LastName;
        price =                 transactionPrice;
        POC =                   null;
        TCode =                 null;//this.subscriber.Wave_ID__c;
        IncentiveId =           null;
        IncentiveDescription =  null;
        Guid =                  this.subscriber.Guid__c;
        AccId =                 this.subscriber.Id;
    }

    /***************************************************************************************
    * @author Unknown
    * @date Unknown
    * @description Method to fetch all params and map them to vars
    #############Change Log#############
    Modified by         Version     Change Date
    Wiktor Czykin       1.1         11/11/2015  //added restart
    Wiktor Czykin       1.2         15/12/2016  //added price overrides parameters
    Wiktor Czykin       1.3         16/01/2017  //wrapped up price parsing into trycatch (to prevent random failures with unknown error)
    ***************************************************************************************/
    @TestVisible private void getRequestValues(){
        Map<String, String> mapParams = ApexPages.currentPage().getParameters();
        selectedProduct =       mapParams.get('selectedProduct');
        selectedOffer =         mapParams.get('selectedOffer');
        TSNumber =              mapParams.get('TSNumber');
        email =                 mapParams.get('email');
        title =                 mapParams.get('title');
        otherTitle =            mapParams.get('otherTitle');
        firstName =             mapParams.get('firstName');
        lastName =              mapParams.get('lastName');
        subscriptionType =      mapParams.get('subscriptionType');
        TCode =                 mapParams.get('tCode');
        POC =                   mapParams.get('POC');
        IncentiveId =           mapParams.get('incentiveId');
        IncentiveDescription =  mapParams.get('incentiveDescription');
        Guid =                  mapParams.get('guid');
        AccId =                 mapParams.get('accId');
        subId =                 mapParams.get('subId');
        productId =             mapParams.get('productId');
        PaymentMethod =         mapParams.get('PaymentMethod');
        PaymentFrequency =      mapParams.get('PaymentFrequency');
        paymentStartDate =      mapParams.get('paymentStartDate');
        retailerId =            mapParams.get('retailerId');
        sDuration =             mapParams.get('duration');
        //Below field was added to different next link navigation (for Acquisition and Renewal)
        isOutbound =            (mapParams.get('isOutbound')!=null);
        isOCRS =                (mapParams.get('isOCRS')!=null);
        isRenew =               (mapParams.get('isRenew')!=null);
        ocrsCase =              mapParams.get('ocrsCase');
        sRestart =              mapParams.get('restart');
        fieldMap.orderMethod = mapParams.get('orderTakenMethod');
        fieldMap.byCompany = mapParams.get('orderTakenByCompany');
        fieldMap.byUser = mapParams.get('orderTakenByUser');
        try{
            price = Decimal.valueOf(mapParams.get('price'));
        }catch(Exception e){
            throw new TelegraphApplicationException(Label.MPP_Error_Price_parameter_error);
        }
        try{
            String sForcedPrice = mapParams.get('forcedPrice');
            String sForcedLowStartPrice = mapParams.get('forcedLowStartPrice');
            if(String.isNotBlank(sForcedPrice)){
                forcedWeeklyPrice = Decimal.valueOf(sForcedPrice);
            }
            if(String.isNotBlank(sForcedLowStartPrice)){
                forcedLowStartWeeklyPrice = Decimal.valueOf(sForcedLowStartPrice);
            }
            //fail silently - if wrong dont use
        }catch(Exception e){}

        try{
            Incentive__c incentive = [SELECT Id, Name, Incentive_Description__c FROM Incentive__c WHERE Id = :IncentiveId];
            incentiveMsg = '<br/>Selected incentive: ' + incentive.Name;
        }catch(System.Exception e){
            incentiveMsg = null;
        }
        System.debug('TMG::MPPUtil:object dump:'+JSON.serialize(this));
    }

    /***************************************************************************************
    * @author Unknown
    * @date Unknown
    * @description Method to fetch all params and map them to vars
    #############Change Log#############
    Modified by         Version     Change Date
    Vishant Shah        2.9         03/11/2016   Added check for One time payment reason for SubscriptionOneOffPaymentAmount vfp
    ***************************************************************************************/
    public Boolean isValidOneOffPayment(){
        Pattern numericPattern = Pattern.compile('\\d+(\\.\\d{1,2})?');
        Matcher matcher;

        String pageWithReasonField = 'SubscriptionOneOffPaymentAmount';
        String currentVFPage = ApexPages.currentPage().getParameters().get('currentPageName');

        /* This is submitOneOffPaymentAmount is called from 2 VFP.
           SubscriptionOneOffPaymentAmount & SubscriberOneOffPaymentAmount
           Doing a check on page as theres no other way of getting the page name */
        if ( currentVFPage != null && currentVFPage.toLowerCase() == pageWithReasonField.toLowerCase() ){
            if (oneOffPaymentReason == Constants.NONE_PICKLIST_VALUE){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, Label.One_Time_Payment_Reason_Not_Selected));
                return false;
            }
        }

        if(!TMGUtil.isDataValid(this.oneOffAmount)){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Please enter a value for Amount.'));
            return false;
        }

        matcher = numericPattern.matcher(this.oneOffAmount);
        if(!matcher.matches()){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'You can only enter a valid numeric value in Amount.'));
            return false;
        }

        if(!(Decimal.valueOf(this.oneOffAmount) > 0)){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Please enter a value for Amount.'));
            return false;
        }

        if(this.oneOffProductType.toLowerCase().equals('premium')){
            if(Decimal.valueOf(this.oneOffAmount) > this.subscription.Total_Price__c){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'You cannot enter a value higher than the subscription total price. £' + this.subscription.Total_Price__c.setScale(2)));
                return false;
            }
        }else{
            try{
                TCodeManagement__c openOffer = [SELECT Id, Name, Type__c, Digital_Yearly_Price__c, Digital_Monthly_Price__c FROM TCodeManagement__c WHERE Type__c = 'Open Offer' LIMIT 1];
                Decimal maxPrice = openOffer.Digital_Yearly_Price__c;
                if(Decimal.valueOf(this.oneOffAmount) > maxPrice){
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'You cannot enter a value higher than the subscription total price. £' + maxPrice.setScale(2)));
                    return false;
                }
            }catch(System.QueryException e){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Cannot find Open Offer TCode to compare price. Please contact the system administrator.'));
                return false;
            }
        }

        return true;
    }

    public PageReference submitOneOffPaymentAmount(){
        PageReference url = null;
        if(isValidOneOffPayment()){
            url = new PageReference('/apex/oneoffpaymentprocessor?productType=' + this.oneOffProductType + '&recordId=' + this.currentId + '&oneOffPaymentReason=' +  this.oneOffPaymentReason  + '&oneOffAmount=' + Decimal.valueOf(this.oneOffAmount).setScale(2));
        }
        return url;
    }

    //Offline - one off payments for digital and premium.
    public void checkOneOffPayment(){
        String productType = ApexPages.currentPage().getParameters().get('productType');
        String recordId = ApexPages.currentPage().getParameters().get('recordId');
        String amount = ApexPages.currentPage().getParameters().get('oneOffAmount');
        String reason = ApexPages.currentPage().getParameters().get('oneOffPaymentReason');

        System.debug('### PRODUCT TYPE: ' + productType);
        System.debug('### RECORDID: ' + recordID);
        System.debug('### AMOUNT: ' + amount);
        System.debug('### REASON: ' + reason);

        this.isOneOffPayment = true;
        this.oneOffProductType = productType;
        this.currentId = recordId;
        this.oneOffAmount = amount;
        this.oneOffPaymentReason = reason;


        if(TMGUtil.isDataValid(oneOffAmount)){
            if(this.oneOffProductType.toLowerCase().equals(Constants.PRODUCT_PREMIUM.toLowerCase())){
                getRequestValuesFromSub(this.currentId, Double.valueOf(this.oneOffAmount));
                this.oneOffProductType = 'OneOffPayment';
                prMpp = goToOneOffPayment();
            }else if(this.oneOffProductType.toLowerCase().equals(Constants.PRODUCT_DIGITAL.toLowerCase())){
                getRequestValuesFromAccount(this.currentId, Double.valueOf(this.oneOffAmount), this.oneOffProductType);
                this.oneOffProductType = 'OneOffPayment';
                prMpp = goToOneOffPayment();
            }
        }
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 14.09.2015
    Version - 1.4
    Function - calculates low start payment schedule
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         06/09/2015  //added more fields to PaymentSetupWrapper
    Wiktor Czykin   1.2         20/10/2015  //fixed offset for cc payment method
    Wiktor Czykin   1.3         25/11/2015  //made the method static so that it can be accessed from SubscriptionsWebservices
    Wiktor Czykin   1.4         15/01/2016  //changed method signature - added 2 extra parameters to handle price overrides
    Michal Szewczyk 1.5         04/04/2016  //adjust method to use new data model
    ****************************************************************************************/
    public static PaymentSetupWrapper generatePaymentScheduleForLowStart(TCodeManagement__c tCode,TCode_Product__c tCodeProd, Integer iLowStartLength, Integer iFullLength, String sPaymentStartDate, String sFrequency, String sPaymentMethod, Decimal dForcedLowStartPrice, Decimal dForcedPrice){
        if(tCode == null || iLowStartLength == null || iFullLength == null || String.isBlank(sPaymentStartDate) || String.isBlank(sFrequency)) throw new TelegraphApplicationException(Label.Low_Start_Division_method_error);
        if(Math.mod(iLowStartLength, Constants.WEEKS_IN_QUARTER)>0 || Math.mod(iFullLength, Constants.WEEKS_IN_QUARTER)>0) throw new TelegraphApplicationException(Label.Low_Start_Division_by_13_error);

        List<MppPaymentInterface.PaymentSetup> lstPaymentSetup = new List<MppPaymentInterface.PaymentSetup>();
        PaymentSetupWrapper psw = new PaymentSetupWrapper();
        try{
            Decimal weeklyPrice = tCodeProd.Weekly_Price__c;
            Decimal lowStartWeeklyPrice = tCodeProd.Low_Start_Price__c;
            if(dForcedPrice != null && dForcedPrice > 0){
                weeklyPrice = dForcedPrice;
            }
            if(dForcedLowStartPrice != null && dForcedLowStartPrice > 0){
                lowStartWeeklyPrice = dForcedLowStartPrice;
            }

            Integer iRemainingWeeks = iFullLength - iLowStartLength;
            List<String> lstDateParts = sPaymentStartDate.split('/');
            Date dBuffer = Date.newInstance(Integer.valueOf(lstDateParts[2]), Integer.valueOf(lstDateParts[1]), Integer.valueOf(lstDateParts[0]));
            Decimal dLowStartTotal = lowStartWeeklyPrice * iLowStartLength;
            Decimal dStandardTotal = iRemainingWeeks * weeklyPrice;
            Integer iSplitFactor = (sFrequency == Constants.DD_COL_FREQ_MONTHLY ? 4 : 13);
            Integer iAddMonths = (sFrequency == Constants.DD_COL_FREQ_MONTHLY ? 1 : 3);

            Integer iNumberOfPaymentsLowStart = (Integer)(Math.floor((Decimal)iLowStartLength/(Decimal)iSplitFactor));
            Integer iNumberOfPaymentsStandard = (Integer)(Math.floor((Decimal)iRemainingWeeks/(Decimal)iSplitFactor));
            Decimal dLowStartValue = (dLowStartTotal / iNumberOfPaymentsLowStart).setScale(2, System.RoundingMode.DOWN);
            Decimal dLowStartFirstPayment = dLowStartValue + dLowStartTotal - (dLowStartValue * iNumberOfPaymentsLowStart);
            Decimal dStandardValue = (dStandardTotal / iNumberOfPaymentsStandard).setScale(2, System.RoundingMode.DOWN);
            Decimal dStandardFirstPayment = dStandardValue + dStandardTotal - (dStandardValue * iNumberOfPaymentsStandard);

            Integer iOffset =  Constants.getMppDDOffset();
            if(String.isNotBlank(sPaymentMethod) && sPaymentMethod == Constants.MPP_PAYMENTMETHOD_CC){
                iOffset = 0;
            }

            for(Integer i=1; i<= iNumberOfPaymentsLowStart; i++){
                MppPaymentInterface.PaymentSetup ps = new MppPaymentInterface.PaymentSetup();
                ps.OrderDate = setDateToBeforeHolidaysAndWeekendsCummulative(dBuffer, false, iOffset).format();
                ps.Currency_x = Constants.ORDER_CURRENCY_GBP;
                if(i == 1){
                    ps.GrossAmount = (Integer)(dLowStartFirstPayment*100);
                }else{
                    ps.GrossAmount = (Integer)(dLowStartValue*100);
                }
                dBuffer = dBuffer.addMonths(iAddMonths);
                lstPaymentSetup.add(ps);
            }
            psw.iSwitchOrderIndex = lstPaymentSetup.size();
            for(Integer i=1; i<= iNumberOfPaymentsStandard; i++){
                MppPaymentInterface.PaymentSetup ps = new MppPaymentInterface.PaymentSetup();
                Date dtProcessed = setDateToBeforeHolidaysAndWeekendsCummulative(dBuffer, false, iOffset);
                ps.OrderDate = dtProcessed.format();
                ps.Currency_x = Constants.ORDER_CURRENCY_GBP;
                if(i == 1){
                    psw.dSwitchAmount = dStandardFirstPayment;
                    psw.dtSwitchPaymentDate = dtProcessed;
                    ps.GrossAmount = (Integer)(dStandardFirstPayment*100);
                }else{
                    ps.GrossAmount = (Integer)(dStandardValue*100);
                }
                dBuffer = dBuffer.addMonths(iAddMonths);
                lstPaymentSetup.add(ps);
            }
            psw.iNumberOfPaymentsLowStart = iNumberOfPaymentsLowStart;
            psw.iNumberOfPaymentsStandard = iNumberOfPaymentsStandard;
        }catch(Exception e){
            throw new TelegraphApplicationException(Label.Low_Start_Split_evaluation_error + ' ' + e.getMessage());
        }

        psw.lstPaymentSetup = lstPaymentSetup;
        return psw;
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 08/02/2016
    Version - 1.0
    Function -  Generate payment schedule for non low start subscription.
                Method created to basically retrieve subsequent payment amount for letter extract.
                Not implementing offset as no longer required.
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public static PaymentSetupWrapper generatePaymentSchedule(Decimal dWeeklyPrice, Integer iLength, String sPaymentStartDate, String sFrequency){
        if(dWeeklyPrice == null || iLength == null || String.isBlank(sPaymentStartDate) || String.isBlank(sFrequency)) throw new TelegraphApplicationException(Label.MPP_Util_Wrong_parameters_for_payment_schedule_creation);
        if(Math.mod(iLength, Constants.WEEKS_IN_QUARTER)>0) throw new TelegraphApplicationException(Label.MPP_Util_Subscription_lenght_division_error);

        List<MppPaymentInterface.PaymentSetup> lstPaymentSetup = new List<MppPaymentInterface.PaymentSetup>();
        PaymentSetupWrapper psw = new PaymentSetupWrapper();
        try{
            List<String> lstDateParts = sPaymentStartDate.split('/');
            Date dBuffer = Date.newInstance(Integer.valueOf(lstDateParts[2]), Integer.valueOf(lstDateParts[1]), Integer.valueOf(lstDateParts[0]));
            Decimal dTotal = iLength * dWeeklyPrice;
            Integer iSplitFactor = (sFrequency == Constants.DD_COL_FREQ_MONTHLY ? 4 : 13);
            Integer iAddMonths = (sFrequency == Constants.DD_COL_FREQ_MONTHLY ? 1 : 3);
            Integer iNumberOfPayments = (Integer)(Math.floor((Decimal)iLength/(Decimal)iSplitFactor));
            if(iNumberOfPayments > 12) iNumberOfPayments = 12;

            Decimal dValue = (dTotal / iNumberOfPayments).setScale(2, System.RoundingMode.DOWN);
            Decimal dFirstPayment = dValue + dTotal - (dValue * iNumberOfPayments);
            for(Integer i=1; i<= iNumberOfPayments; i++){
                MppPaymentInterface.PaymentSetup ps = new MppPaymentInterface.PaymentSetup();
                ps.OrderDate = dBuffer.format();
                ps.Currency_x = Constants.ORDER_CURRENCY_GBP;
                if(i == 1){
                    ps.GrossAmount = (Integer)(dFirstPayment*100);
                }else{
                    ps.GrossAmount = (Integer)(dValue*100);
                }
                dBuffer = dBuffer.addMonths(iAddMonths);
                lstPaymentSetup.add(ps);
            }
        }catch(Exception e){
            throw new TelegraphApplicationException(Label.Mpp_Util_Payment_schedule_unknown_exception + ' ' + e.getMessage());
        }
        psw.lstPaymentSetup = lstPaymentSetup;
        return psw;
    }

    /***************************************************************************************
    Developer - Unknown
    Date - Unknown
    Version - 1.3
    Function - called by MPPPaymentFrame page action
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         25/08/2015  //replaced varrs with constants, replaced equals with contains to support new subscription types
    Wiktor Czykin   1.2         08/09/2015  //changed to fetch MPP service information from TCode related PricingOptions or from fixed custom settings specified
    Wiktor Czykin   1.3         10/05/2016  //changed parameter passed to getPricingOptions() to productId
    ****************************************************************************************/
    public void paymentPage(){
        this.getRequestValues();
        Pricing_Options__c po = GlobalQueries.getPricingOptions(this.productId, Constants.PRICINGOPTION_FLOWTYPE_SFDC, this.subscriptionType, this.TCode);
        String sServiceId;
        String sServicePriceId;
        if(po == null){
            po = GlobalQueries.getDigitalPricingOptionBasedOnSetting(this.subscriptionType);
        }

        if(po != null){
            if(po.ServiceId__c != null){
                sServiceId = po.ServiceId__c+'';
            }
            if(po.ServicePriceId__c != null){
                sServicePriceId = po.ServicePriceId__c+'';
            }
        }

        if(this.selectedProduct == Constants.PRODUCT_PREMIUM){
            if(!this.subscriptionType.containsIgnoreCase(Constants.KEY_CONTINUOUS)){
                prMpp = goToOneOffPayment();
            }else{
                if(String.isBlank(sServiceId)){
                    sServiceId = PREMIUM_CONTINUOUS;
                }
                prMpp = goToPremiumContinuousPayment(sServiceId);
            }
        }else{
            if(String.isBlank(sServiceId)){
                if(this.subscriptionType.toLowerCase() == Constants.SUBSCRIPTIONTYPE_MONTHLY){
                    sServiceId = DIGITAL_MONTHLY;
                }else{
                    sServiceId = DIGITAL_ANNUALLY;
                }
            }
            prMpp = goToDigitalContinuousPayment(sServiceId, sServicePriceId);
        }
    }

    /***************************************************************************************
    Developer - Unknown
    Date - Unknown
    Version - 1.7
    Function - called if premium subscription is sold via payment gateway
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         09/2015     //added low start payment schedule creation
    Wiktor Czykin   1.2         15/01/2016  //changed call to generatePaymentScheduleForLowStart() signature changed
    Michal Szewczyk 1.3         04/04/2016  //adjust method to use new data model
    Michal Szewczyk 1.4         05/06/2016  //added missing field in SOQL
    Wiktor Czykin   1.5         12/05/2016  //changed how default product is retrieved
    Wiktor Czykin   1.6         27/05/2016  //added default product constant
    Wiktor Czykin   1.7         02/03/2017  //added record type Id filter for tcodeproduct
    ****************************************************************************************/
    public PageReference goToPremiumContinuousPayment(String sServiceId){
        List<TCodeManagement__c> lstTCode = GlobalQueries.getTCodeBasedOnName(this.TCode);
        List<TCode_Product__c> lstTCodeProd;
        if(lstTCode.isEmpty()) throw new TelegraphApplicationException(Label.Payment_Page_Missing_tcode);
        Id offerRecordTypeId = RecordTypeUtility.getRecordTypeId(TCode_Product__c.SObjectType, Constants.RECTYPE_TCODEPRODUCT_OFFER, TCode_Product__c.class.getName());

        PaymentSetupWrapper paymentSetup;
        if(lstTCode[0].Type__c == Constants.TCODE_TYPE_LOWSTART && String.isNotBlank(lstTCode[0].Low_Start_Period__c) && lstTCode[0].Low_Start_Period__c.isNumeric()){
            Id pId = this.productId;
            if(pId == null){
                General__c defaultProduct = General__c.getInstance(Constants.GENERAL_DEFAULT_PRODUCT_ID);
                if(defaultProduct != null && String.isNotBlank(defaultProduct.Value__c)){
                    pId = defaultProduct.Value__c;
                }

            }
            if(pId == null) throw new TelegraphApplicationException(Label.Payment_Page_Missing_tcode_prod);

            lstTCodeProd = [select Id, Weekly_Price__c, Low_Start_Price__c from TCode_Product__c where Product__c =:pId and TCodeManagement__c =:lstTCode[0].Id and RecordTypeId =: offerRecordTypeId];
            if(lstTCodeProd.isEmpty()) throw new TelegraphApplicationException(Label.Payment_Page_Missing_tcode_prod);

            Integer iDuration;
            if(String.isNotBlank(this.sDuration) && this.sDuration.isNumeric()){
                iDuration = Integer.valueOf(this.sDuration);
            }else{
                throw new TelegraphApplicationException(Label.Low_Start_Missing_duration);
            }
            paymentSetup = generatePaymentScheduleForLowStart(lstTCode[0],lstTCodeProd[0], Integer.valueOf(lstTCode[0].Low_Start_Period__c), iDuration, this.paymentStartDate, this.PaymentFrequency, this.PaymentMethod, this.forcedLowStartWeeklyPrice, this.forcedWeeklyPrice);
        }
        PageReference pr = goToMppPayment(Constants.MPP_FUNCTION_ADDPAYMENTSCHEDULE, sServiceId, null, PaymentMethod, PaymentFrequency, paymentStartDate, TSNumber, email, title,  firstName, lastName, price, null, TCode, IncentiveId, IncentiveDescription, Guid, AccId, this.fieldMap, paymentSetup!=null?paymentSetup.lstPaymentSetup:null);
        if(paymentSetup != null){
            try{
                SubscriptionTriggerHandler.getInstance().bRunAPI = false;
                update new Subscription__c(Id = this.subId, MPP_Irregular_Payment_Schedule__c = JSON.serialize(paymentSetup));
                SubscriptionTriggerHandler.getInstance().bRunAPI = true;
            }catch(Exception e){
                throw new TelegraphApplicationException('Failed to update Payment Schedule field.');
            }
        }
        return pr;

    }

    public PageReference goToDigitalContinuousPayment(String sServiceId, String sServicePriceId){
        return goToMppPayment(Constants.MPP_FUNCTION_ADDSUBSCRIPTION, sServiceId, sServicePriceId, PaymentMethod, null, null, TSNumber, email, title,  firstName, lastName, price, null, TCode, IncentiveId, IncentiveDescription, Guid, AccId, this.fieldMap, null);
    }

    public PageReference goToOneOffPayment(){
        return goToMppPayment(Constants.MPP_FUNCTION_PROCESSPAYMENT, '', null, Constants.MPP_PAYMENTMETHOD_CC, null, null, TSNumber, email, title,  firstName, lastName, price, null, TCode, IncentiveId, IncentiveDescription, Guid, AccId, this.fieldMap, null);
    }

    /***************************************************************************************
    Developer - Unknown
    Date - Unknown
    Version - 1.3
    Function -  Prepares payload and does callout with CreateSession method as an initial step to take iframe payment
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         10/07/2015  //changed offset to be parametrized
    Wiktor Czykin   1.2         10/09/2015  //added support for fixed digital mpp service, added support for irregular payment schedule
    Cristina A      1.3         25/09/2015  //add TSNumber to defaultEmail address to make it uniques when user doesnt have a email address
    Wiktor Czykin   1.4         11/2015     //methods' purpose changed - no longer responsible for CreateSession generation.
                                                Now request itself is made in createSessionCallout(). Here we only prepare or pass through parameters.
    Pawel Chrzanowski 1.5       22/09/2016  //added isOCRS parameter
    Michal Szewczyk 1.6         19/10/2016  //added oneOffPayment reason
    Konrad Czykin   1.7         20/04/2017  //modified pagereference return url string for mppResult.ErrorNumber != 0,
                                                added if condition for isOCRS = null
    ****************************************************************************************/
    public PageReference goToMppPayment(String mppFunctionId,
                                        String serviceId,
                                        String servicePriceId,
                                        String paymentMethod,
                                        String paymentFrequency,
                                        String paymentStartDate,
                                        String tsNumber,
                                        String email,
                                        String title,
                                        String firstName,
                                        String lastName,
                                        Decimal price,
                                        String POC,
                                        String tCode,
                                        String incentiveId,
                                        String incentiveDescription,
                                        String guid,
                                        String accId,
                                        OrderTakenDetails fieldMap,
                                        List<MppPaymentInterface.PaymentSetup> lstPaymentSetup
                                        ){

        String sRetUrl = URL.getSalesforceBaseUrl().toExternalForm() + '/apex/MppPaymentConfirm?action=OFFLINE_MPP&accId='+accId+ (TMGUtil.isDataValid(subId) ? '&subId=' + subId : '')
            + '&incentiveMsg=' + (TMGUtil.isDataValid(this.incentiveMsg) ? EncodingUtil.urlEncode(this.incentiveMsg, 'UTF-8') : '')
            + (this.isOneOffPayment == true ? '&isOneOffPayment=true' + '&oneOffAmount=' + this.oneOffAmount : '&isOneOffPayment=false'
            // Below field was added to different next link navigation(for Acquisition and Renewal).
            +'&isRenew='+this.isRenew+'&isOutbound='+this.isOutbound+'&isOCRS='+this.isOCRS+'&ocrsCase='+this.ocrsCase+'&paymentFrequency='+paymentFrequency
            +'&isOCDDCX='+this.isOCDDCX);

        String subscriptionId;
        if (this.subscription != null && this.subscription.Id != null){
            subscriptionId = this.subscription.Id;
        }else if(this.subId != null){
            subscriptionId = this.subId;
        }
        Map<String,String> paramsMap = new Map<String,String>();
        if(String.isNotEmpty(this.oneOffPaymentReason)){
            paramsMap.put('PaymentReason',this.oneOffPaymentReason);
        }
        Map<String, Object> result = createSessionCallout(  'Salesforce',
                                                            sRetUrl,
                                                            mppFunctionId,
                                                            serviceId,
                                                            servicePriceId,
                                                            paymentMethod,
                                                            paymentFrequency,
                                                            paymentStartDate,
                                                            tsNumber,
                                                            email,
                                                            title,
                                                            firstName,
                                                            lastName,
                                                            price,
                                                            null,
                                                            POC,
                                                            tCode,
                                                            incentiveId,
                                                            incentiveDescription,
                                                            guid,
                                                            accId,
                                                            subscriptionId,
                                                            fieldMap,
                                                            lstPaymentSetup,
                                                            this.oneOffProductType,
                                                            this.subscriptionType,
                                                            paramsMap
                                                            );

        System.debug('### MppUtil.goToMppPayment result: ' + result);
        MppPaymentInterface.CreateSessionResult mppResult = (MppPaymentInterface.CreateSessionResult) result.get(CREATESESSION_RESULT_MPPRESULT_KEY);
        this.resultString = mppResult.Guid + ' - '+mppResult.ErrorNumber+ ' - '+mppResult.ErrorMessage;

        try{
            if(result.containsKey(CREATESESSION_RESULT_WLOG_KEY) && result.get(CREATESESSION_RESULT_WLOG_KEY) != null){
                insert (WebService_Log__c) result.get(CREATESESSION_RESULT_WLOG_KEY);
            }
        }catch(Exception e){
            System.debug('silently fail webservice log insert');
        }

        if(mppResult.ErrorNumber != 0){
            return new PageReference(Page.MppPaymentConfirm.getUrl()+'?accId='+accId+'&action=ERROR'+((this.isOCRS != null) ? (this.isOCRS ? '&isOCRS='+this.isOCRS : '') : '')+(this.ocrsCase!=null?'&ocrsCase='+this.ocrsCase:'')+'&msg='+mppResult.ErrorMessage);
        }
        return new PageReference(BASE_MPP_URL + 'ishop/435/SF_iPayPaymentPage.aspx?Guid='+mppResult.Guid);
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 11/2015
    Version - 1.1
    Function - new common method to generate CreateSession request. Logic bit simplified. Originally in goToMppPayment().
                Returns a map of result :
                CREATESESSION_RESULT_WLOG_KEY - webservice log based on parameters send to MPP - we cannot just insert it here as we do not know if another call is made after this method completes its execution
                CREATESESSION_RESULT_MPPRESULT_KEY - results object from MPP
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         15/12/2015  //replaced string with constant
    ****************************************************************************************/
    public static Map<String, Object> createSessionCallout( String originator,
                                                            String returnUrl,
                                                            String mppfunctionId,
                                                            String serviceId,
                                                            String servicePriceId,
                                                            String paymentMethod,
                                                            String paymentFrequency,
                                                            String paymentStartDate,
                                                            String tsNumber,
                                                            String email,
                                                            String title,
                                                            String firstName,
                                                            String lastName,
                                                            Decimal price,
                                                            String paymentCurrency,
                                                            String POC,
                                                            String tCode,
                                                            String incentiveId,
                                                            String incentiveDescription,
                                                            String guid,
                                                            String accId,
                                                            String subscriptionId,
                                                            OrderTakenDetails fieldMap,
                                                            List<MppPaymentInterface.PaymentSetup> lstPaymentSetup,
                                                            String oneOffProductType,
                                                            String sSubscriptionType,
                                                            Map<String, String> mapCustomParameters
                                                            ){
        //response map should contain list of webservice logs related to this request, and actual response from MPP

        Boolean bLowStartIrregular = (lstPaymentSetup != null);
        MppPaymentInterface.iPayPaymentPagesSoap paymentInterface = new MppPaymentInterface.iPayPaymentPagesSoap();
        MppPaymentInterface.ArrayOfParameterPair parameterPairs = new MppPaymentInterface.ArrayOfParameterPair();
        parameterPairs.ParameterPair = new MppPaymentInterface.ParameterPair[]{};

        if(String.isBlank(email)){
            email = Constants.DEFAULT_EMAIL_ADDRESS;
            if(String.isNotBlank(tsNumber)){
                email = Constants.DEFAULT_EMAIL_ADDRESS.substringBefore('@') + '+' + tsNumber +'@'+ Constants.DEFAULT_EMAIL_ADDRESS.substringAfter('@');
            }
        }
        parameterPairs.ParameterPair.add(new MppPaymentInterface.ParameterPair('FunctionId', mppfunctionId));
        parameterPairs.ParameterPair.add(new MppPaymentInterface.ParameterPair('Email', email));
        parameterPairs.ParameterPair.add(new MppPaymentInterface.ParameterPair('UserPasswordHidden', 'GenerateRandom'));
        parameterPairs.ParameterPair.add(new MppPaymentInterface.ParameterPair('ReturnUrl', returnUrl));
        parameterPairs.ParameterPair.add(new MppPaymentInterface.ParameterPair('CancelPaymentOnProcessUpdateFailure', 'true'));
        parameterPairs.ParameterPair.add(new MppPaymentInterface.ParameterPair('BypassConfirmationPage', 'true'));

        // ONLY for Premium Continuous
        if(mppfunctionId == Constants.MPP_FUNCTION_ADDPAYMENTSCHEDULE){
            // Payment frequency - irregular if low start
            parameterPairs.ParameterPair.add(new MppPaymentInterface.ParameterPair('PaymentScheduleFrequency', (bLowStartIrregular?Constants.DD_COL_FREQ_IRREGULAR:paymentFrequency)));
            if(!bLowStartIrregular){
                parameterPairs.ParameterPair.add(new MppPaymentInterface.ParameterPair('StartDate', paymentStartDate));
            }
            if(String.isNotBlank(oneOffProductType) && oneOffProductType.toLowerCase() == Constants.PRODUCT_PREMIUM.toLowerCase() && paymentMethod == Constants.MPP_PAYMENTMETHOD_DD){
                parameterPairs.ParameterPair.add(new MppPaymentInterface.ParameterPair('PaymentDateOffset', Constants.getMppDDOffsetNegative()+''));
            }
        }

        // Both Continuous Digital and Premium Continuous
        if(mppfunctionId == Constants.MPP_FUNCTION_ADDSUBSCRIPTION || mppfunctionId == Constants.MPP_FUNCTION_ADDPAYMENTSCHEDULE){
            parameterPairs.ParameterPair.add(new MppPaymentInterface.ParameterPair('ServiceId', serviceId));
            parameterPairs.ParameterPair.add(new MppPaymentInterface.ParameterPair('PaymentMethod', paymentMethod));
            if(String.isNotBlank(servicePriceId)){
                parameterPairs.ParameterPair.add(new MppPaymentInterface.ParameterPair('ServicePriceId', servicePriceId));
            }
        }

        // Both One OFF Premium and Continuous Premium
        if(mppfunctionId == Constants.MPP_FUNCTION_PROCESSPAYMENT || mppfunctionId == Constants.MPP_FUNCTION_ADDPAYMENTSCHEDULE){
            if(String.isNotBlank(oneOffProductType) && oneOffProductType == 'OneOffPayment' && mppfunctionId == Constants.MPP_FUNCTION_PROCESSPAYMENT) {
                parameterPairs.ParameterPair.add(new MppPaymentInterface.ParameterPair('EmailReceipt', 'false'));
            }

            if(!bLowStartIrregular){
                parameterPairs.ParameterPair.add(new MppPaymentInterface.ParameterPair('GrossAmount', String.valueOf(price * 100)));
                parameterPairs.ParameterPair.add(new MppPaymentInterface.ParameterPair('Currency', String.isNotBlank(paymentCurrency)?paymentCurrency:'GBP'));
            }

            String sProductDescription = 'Premium Subscription. ';
            sProductDescription+= '<div style="font-size:14px;">';
            if(price != null){
                sProductDescription += ' Subscription Price: £' + String.valueOf(price.setScale(2)) + '<br/>';
            }
            if(String.isNotBlank(sSubscriptionType)){
                sProductDescription += ' Subscription Duration: ' + sSubscriptionType + '<br/>';
            }
            sProductDescription += ' Incentive: ' + (String.isBlank(incentiveDescription)? 'No incentive selected.' : incentiveDescription);
            sProductDescription += '</div>';
            parameterPairs.ParameterPair.add(new MppPaymentInterface.ParameterPair('ProductDescription', sProductDescription));
        }

        parameterPairs.ParameterPair.add(new MppPaymentInterface.ParameterPair('Title', title));
        parameterPairs.ParameterPair.add(new MppPaymentInterface.ParameterPair('FirstName', firstName));
        parameterPairs.ParameterPair.add(new MppPaymentInterface.ParameterPair('Surname', lastName));
        parameterPairs.ParameterPair.add(new MppPaymentInterface.ParameterPair('IsMoto', 'true'));

        /* Custom ORDER Parameters */
        MppPaymentInterface.ArrayOfOrderParameter customOrderParameters = new MppPaymentInterface.ArrayOfOrderParameter();
        customOrderParameters.OrderParameter = new MppPaymentInterface.OrderParameter[]{new MppPaymentInterface.OrderParameter('Originator', originator)};

        /* CLIENT Custom Parameters */
        MppPaymentInterface.ArrayOfClientCustomParameter clientCustomParameters = new MppPaymentInterface.ArrayOfClientCustomParameter();
        clientCustomParameters.ClientCustomParameter = new MppPaymentInterface.ClientCustomParameter[]{};

        if(mapCustomParameters != null && !mapCustomParameters.isEmpty()){
            for(String sKey : mapCustomParameters.keySet()){
                if(String.isNotEmpty(mapCustomParameters.get(sKey))){
                    clientCustomParameters.ClientCustomParameter.add(new MppPaymentInterface.ClientCustomParameter(sKey, mapCustomParameters.get(sKey)));
                }
            }
        }


        if(String.isNotBlank(incentiveId)){
            clientCustomParameters.ClientCustomParameter.add(new MppPaymentInterface.ClientCustomParameter('IncentiveId', 'You selected '+IncentiveDescription));
        }

        if(String.isNotBlank(subscriptionId)){
            clientCustomParameters.ClientCustomParameter.add(new MppPaymentInterface.ClientCustomParameter('SubscriptionId', subscriptionId));
        }

        if(String.isNotBlank(oneOffProductType)){
            clientCustomParameters.ClientCustomParameter.add(new MppPaymentInterface.ClientCustomParameter('ProductName', oneOffProductType));
        }

        MppPaymentInterface.SubscriptionPriceItems subscriptionPriceItems = new MppPaymentInterface.SubscriptionPriceItems();
        subscriptionPriceItems.Items = new MppPaymentInterface.ArrayOfSubscriptionPriceItem();
        subscriptionPriceItems.Items.SubscriptionPriceItem = new MppPaymentInterface.SubscriptionPriceItem[]{};

        MppPaymentInterface.ArrayOfSubscriptionParameter customSubscriptionParameters = new MppPaymentInterface.ArrayOfSubscriptionParameter();
        customSubscriptionParameters.SubscriptionParameter = new MppPaymentInterface.SubscriptionParameter[]{};

        if(mppfunctionId != Constants.MPP_FUNCTION_PROCESSPAYMENT){
            // Only for Digital Continuous
            if(mppfunctionId == Constants.MPP_FUNCTION_ADDSUBSCRIPTION){
                subscriptionPriceItems.Items.SubscriptionPriceItem.add( new MppPaymentInterface.SubscriptionPriceItem(null, 0, price, 'Digital Subscription'));
            }
            /* Custom SUBSCRIPTION Parameters */
            customSubscriptionParameters.SubscriptionParameter.add(new MppPaymentInterface.SubscriptionParameter('TCode', TCode));

            // Pass in the order taken fields OrderTakenMethod, OrderTakenCompany, OrderTakenByUser. These should be passed for digital and premium subscriptions to MPP.
            if(TMGUtil.isDataValid(fieldMap)){
                if(TMGUtil.isDataValid(fieldMap.orderMethod)){
                    customSubscriptionParameters.SubscriptionParameter.add(new MppPaymentInterface.SubscriptionParameter('OrderTakenMethod', fieldMap.orderMethod));
                }
                if(TMGUtil.isDataValid(fieldMap.byCompany)){
                    customSubscriptionParameters.SubscriptionParameter.add(new MppPaymentInterface.SubscriptionParameter('OrderTakenCompany', fieldMap.byCompany));
                }
                if(TMGUtil.isDataValid(fieldMap.byUser)){
                    customSubscriptionParameters.SubscriptionParameter.add(new MppPaymentInterface.SubscriptionParameter('OrderTakenByUser', fieldMap.byUser));
                }
            }


            // Incentives
            if(String.isNotBlank(incentiveId)){
                customSubscriptionParameters.SubscriptionParameter.add( new MppPaymentInterface.SubscriptionParameter('IncentiveId', incentiveId));
                customSubscriptionParameters.SubscriptionParameter.add( new MppPaymentInterface.SubscriptionParameter('IncentiveDescription', incentiveDescription));
            }
        }else{
            /* ADD TO Custom ORDER Parameters */
            if(TMGUtil.isDataValid(TCode)){
                customOrderParameters.OrderParameter.add(new MppPaymentInterface.OrderParameter('TCode', TCode));
            }

            //Pass in the order taken fields OrderTakenMethod, OrderTakenCompany, OrderTakenByUser - these params should be passed for digital and premium subscriptions to MPP.
            if(TMGUtil.isDataValid(fieldMap)){
                if(TMGUtil.isDataValid(fieldMap.orderMethod)){
                    customOrderParameters.OrderParameter.add(new MppPaymentInterface.OrderParameter('OrderTakenMethod', fieldMap.orderMethod));
                }
                if(TMGUtil.isDataValid(fieldMap.byCompany)){
                    customOrderParameters.OrderParameter.add(new MppPaymentInterface.OrderParameter('OrderTakenCompany', fieldMap.byCompany));
                }
                if(TMGUtil.isDataValid(fieldMap.byUser)){
                    customOrderParameters.OrderParameter.add( new MppPaymentInterface.OrderParameter('OrderTakenByUser', fieldMap.byUser));
                }
            }

            if(String.isNotBlank(incentiveId)){
                customOrderParameters.OrderParameter.add(new MppPaymentInterface.OrderParameter('IncentiveId', incentiveId));
                customOrderParameters.OrderParameter.add( new MppPaymentInterface.OrderParameter('IncentiveDescription', incentiveDescription));
            }
        }

        // Custom ACCOUNT Parameters
        // Ts number
        MppPaymentInterface.ArrayOfAccountParameter customAccountParameters = new MppPaymentInterface.ArrayOfAccountParameter();
        customAccountParameters.AccountParameter = new MppPaymentInterface.AccountParameter[]{new MppPaymentInterface.AccountParameter('TSNumber', TSNumber)};

        //POC
        if(String.isNotBlank(POC)){
            customAccountParameters.AccountParameter.add(new MppPaymentInterface.AccountParameter('POC', POC));
        }

        // We get the GUID from the Acquisition page
        if(String.isNotBlank(Guid)){
            customAccountParameters.AccountParameter.add(new MppPaymentInterface.AccountParameter('SAM_GUID', Guid));
        }

        //IMPORTANT: setting up the endpoint - else will go to hardcoded production endpoint
        paymentInterface.endpoint_x = MPP_URL;
        //if servicePriceId exists, means that service in MPP is a fixed service, so no subscriptionPriceItems can exist for CreateSession callout
        if(String.isNotBlank(servicePriceId)){
            subscriptionPriceItems = null;
        }

        // Calling Web Service
        MppPaymentInterface.ArrayOfPaymentSetup arrayOfPayment;
        if(lstPaymentSetup != null){
            arrayOfPayment = new MppPaymentInterface.ArrayOfPaymentSetup();
            arrayOfPayment.PaymentSetup = lstPaymentSetup;
        }

        MppPaymentInterface.CreateSessionResult result = paymentInterface.CreateSession(MPP_LOGIN, MPP_PASSWORD, parameterPairs, clientCustomParameters, subscriptionPriceItems, arrayOfPayment, customOrderParameters, customAccountParameters, customSubscriptionParameters);
        // Logging call
        WebService_Log__c log = TMGUtil.newLogWebServiceRequestSerialized(  Constants.DIRECTION_OUTBOUND,
                                                                            MPP_URL,
                                                                            Constants.LOG_CREATE_SESSION,
                                                                            new Map<String, Object>{    'parameterPairs' => parameterPairs,
                                                                                                        'clientCustomParameters' => clientCustomParameters,
                                                                                                        'subscriptionPriceItems' => subscriptionPriceItems,
                                                                                                        'customOrderParameters' => customOrderParameters,
                                                                                                        'customAccountParameters' =>customAccountParameters,
                                                                                                        'customSubscriptionParameters' => customSubscriptionParameters,
                                                                                                        'ArrayOfPaymentSetup' => lstPaymentSetup
                                                                                                        },
                                                                            null,
                                                                            null,
                                                                            null
                                                                        );
        log.Response_Content__c = JSON.serialize(result);
        log.Response_Time__c = Datetime.now();

        return new Map<String, Object>{
            CREATESESSION_RESULT_WLOG_KEY => log,
            CREATESESSION_RESULT_MPPRESULT_KEY => result
        };
    }

    //Prepare the URL to Access a record directly in Salesforce
    public String getlinkToAccount(){
        return URL.getSalesforceBaseUrl().toExternalForm() + '/' ;
    }

    /*
    *   Called from Subscription object
    *   One Off CC payement for a Premium Failed DD
    */
    public void failedDDPremiumOneOffPayment(){
        try{
            MPP_Transaction_History__c lastTransaction = [SELECT Payment_Date__c,Payment_status__c,Payment_Type__c,Subscriber__c,Total_Price__c FROM MPP_Transaction_History__c WHERE Subscription__c=:this.subscription.id AND Product_name__c='Print' ORDER BY Payment_Date__c DESC LIMIT 1];
            if(lastTransaction.Payment_status__c != 'Failed' || lastTransaction.Payment_Type__c!='DirectDebit'){
                System.debug(LoggingLevel.ERROR,'No Failed DD payment');
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'No Failed DD payment for this Subscription'));
                return;
            }else{
                getRequestValuesFromSub(Double.valueOf(lastTransaction.Total_Price__c));
                this.oneOffProductType = 'OneOffPayment';
                prMpp = goToOneOffPayment();
            }
        }catch(QueryException qe){
            System.debug(LoggingLevel.ERROR,'No Failed DD payment');
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'No Failed DD payment for this Subscription'));
            return;
        }
    }

    /***************************************************************************************
    Developer - Cristina Anghenie
    Date - 09/09/2015
    Version - 1.5
    Function -  Return to the OAPSubscriptionTMG page from the MPPPaymentIframe
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         14/09/2015  //added !null check and extra param
    Wiktor Czykin   1.2         20/10/2015  //added extra param passing
    Wiktor Czykin   1.3         20/10/2015  //added extra param passing - restart
    Wiktor Czykin   1.4         18/01/2016  //added extra forced prices parameters
    Wiktor Czykin   1.5         10/05/2016  //changed parameters reference - for some for now
    ****************************************************************************************/
    public PageReference back(){
        PageReference pagRef = new PageReference('/apex/OAPSubscriptionTMG');
        pagRef.getParameters().put(OapSubscriptionTMG.PARAM_AGENCYID, Constants.AGENT_TMG);
        pagRef.getParameters().put(OapSubscriptionTMG.PARAM_AGENT_USERID, UserInfo.getUserId());
        pagRef.getParameters().put('accId', accId);
        pagRef.getParameters().put(OapSubscriptionTMG.PARAM_TSNUMBER, TSNumber);
        pagRef.getParameters().put(OapSubscriptionTMG.PARAM_SELECTED_PRODUCT, selectedProduct);
        pagRef.getParameters().put(OapSubscriptionTMG.PARAM_SELECTED_OFFER, selectedOffer);
        pagRef.getParameters().put('email', email);
        pagRef.getParameters().put('title', title);
        pagRef.getParameters().put(OapSubscriptionTMG.PARAM_OTHER_TITLE, otherTitle);
        pagRef.getParameters().put('firstName', firstName);
        pagRef.getParameters().put('lastName', lastName);
        pagRef.getParameters().put('price', String.ValueOf(price));
        pagRef.getParameters().put(OapSubscriptionTMG.PARAM_SUBSCRIPTION_TYPE,subscriptionType);
        pagRef.getParameters().put(OapSubscriptionTMG.PARAM_TCODE, TCode);
        pagRef.getParameters().put(OapSubscriptionTMG.PARAM_INCENTIVEID,IncentiveId);
        pagRef.getParameters().put('IncentiveDescription',IncentiveDescription);
        pagRef.getParameters().put('Guid', Guid);
        pagRef.getParameters().put('subId',subId);
        pagRef.getParameters().put(OapSubscriptionTMG.PARAM_PAYMENT_TYPE, (paymentMethod == 'CreditCard' ? PAYMENTMETHOD_CC : PAYMENTMETHOD_DD));
        pagRef.getParameters().put('PaymentMethod',PaymentMethod);
        pagRef.getParameters().put(OapSubscriptionTMG.PARAM_PAYMENT_FREQUENCY, PaymentFrequency);
        pagRef.getParameters().put(OapSubscriptionTMG.PARAM_PAYMENT_START_DATE, paymentStartDate);
        pagRef.getParameters().put(OapSubscriptionTMG.PARAM_HASBACK, 'true');
        pagRef.getParameters().put(OapSubscriptionTMG.PARAM_SFDC_RETAILERID, String.isNotBlank(retailerId) ? retailerId : '');
        if(this.fieldMap != null && !String.isBlank(this.fieldMap.orderMethod)){
            pagRef.getParameters().put('orderMethod',fieldMap.orderMethod);
        }
        if(selectedProduct == Constants.PRODUCT_DIGITAL){
            pagRef.getParameters().put('isActive', 'false');
        }
        if(sRestart != null){
            pagRef.getParameters().put(OapSubscriptionTMG.PARAM_RESTART, sRestart);
        }
        if(this.forcedWeeklyPrice != null){
            pagRef.getParameters().put(OapSubscriptionTMG.PARAM_FORCED_PRICE, this.forcedWeeklyPrice+'');
        }
        if(this.forcedLowStartWeeklyPrice != null){
            pagRef.getParameters().put(OapSubscriptionTMG.PARAM_FORCED_LOWSTART_PRICE, this.forcedLowStartWeeklyPrice+'');
        }
        if(String.isNotBlank(this.productId)){
            pagRef.getParameters().put(OapSubscriptionTMG.PARAM_PRODUCTID, this.productId);
        }

        pagRef.setRedirect(true);
        return pagRef;
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 13/10/2015
    Version - 1.0
    Function -  Method that checks to make sure a date doesn't fall on a weekend or holiday.
                Logic is to find the iOffset working day from target date.
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public static Date setDateToBeforeHolidaysAndWeekendsCummulative(Date target, Boolean bWithPast, Integer iOffset) {
        if(iOffset == null || iOffset <= 0){
            return target;
        }
        // Fetch holidays as list of ranges if not already done so
        if (lstHolidays == null || bWithPast != bScope){
            if(bWithPast){
                lstHolidays = getHolidayRangesList([select Id, Name, ActivityDate from Holiday where ActivityDate >= :Date.today() order by ActivityDate asc]);
            }else{
                lstHolidays = getHolidayRangesList([select Id, Name, ActivityDate from Holiday order by ActivityDate asc]);
            }
            bScope = bWithPast;
        }

        // Create a new instance of target so logic doesn't change actual calculated date //start check from a day before
        Date current = Date.newInstance(target.year(), target.month(), target.day()).addDays(-1);

        Integer iDayOffset = 0;
        Integer iWorkingDaysToSkip = iOffset;
        // Loop until X non-working day is reached where X is passed in offset
        while (iWorkingDaysToSkip > 0) {
            DateTime dt = DateTime.newInstanceGMT(current, Time.newInstance(9, 0, 0, 0));
            String dayOfWeek = dt.formatGmt('EEEE');

            if (dayOfWeek == 'Sunday') {
                iDayOffset = 2;
            } else if (dayOfWeek == 'Saturday') {
                iDayOffset = 1;
            } else {
                // Calculate holiday
                for (HolidayRange hr : lstHolidays) {
                    if (hr.isBetween(current)) {
                        iDayOffset = hr.startDate.daysBetween(current) + 1;
                        break;
                    }
                }
            }
            // Apply offset
            if (iDayOffset > 0) {
                current = current.addDays(-iDayOffset);
                iDayOffset = 0;
                continue;
            }
            iWorkingDaysToSkip -= 1;
            //continue skipping if still something to skip
            if(iWorkingDaysToSkip > 0){
                current = current.addDays(-1);
            }
        }
        return current;
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 09/2015
    Version - 1.0
    Function -  Method that checks to make sure a date doesn't fall on a weekend or holiday.
                Logic is to use the offset, and then go and find the first working day if that offset date falls on holiday or weekend.
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public static Date setDateToBeforeHolidaysAndWeekends(Date target, Boolean bWithPast, Integer iOffset) {
        // Fetch holidays as list of ranges if not already done so
        if (lstHolidays == null || bWithPast != bScope){
            if(bWithPast){
                lstHolidays = getHolidayRangesList([select Id, Name, ActivityDate from Holiday where ActivityDate >= :Date.today() order by ActivityDate asc]);
            }else{
                lstHolidays = getHolidayRangesList([select Id, Name, ActivityDate from Holiday order by ActivityDate asc]);
            }
            bScope = bWithPast;
        }

        // Create a new instance of target so logic doesn't change actual calculated date
        Date current = Date.newInstance(target.year(), target.month(), target.day());
        current = current.addDays(iOffset);

        Integer iDayOffset = 0;
        while (iDayOffset != -1) {
            DateTime dt = DateTime.newInstanceGMT(current, Time.newInstance(9, 0, 0, 0));
            String dayOfWeek = dt.formatGmt('EEEE');

            if (dayOfWeek == 'Sunday') {
                iDayOffset = 2;
            } else if (dayOfWeek == 'Saturday') {
                iDayOffset = 1;
            } else {
                // Calculate holiday
                for (HolidayRange hr : lstHolidays) {
                    if (hr.isBetween(current)) {
                        iDayOffset = hr.startDate.daysBetween(current) + 1;
                        break;
                    }
                }
            }
            // Apply offset
            if (iDayOffset > 0) {
                current = current.addDays(-iDayOffset);
                iDayOffset = 0;
                continue;
            }
            iDayOffset = -1;
        }
        return current;
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 09/2015
    Version - 1.1
    Function - Generates HolidayRange-s list based on holidays
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private static List<HolidayRange> getHolidayRangesList(List<Holiday> lstRecords) {
        List<HolidayRange> output = new List<HolidayRange>();
        if (lstRecords != null && !lstRecords.isEmpty()) {
            // Get initial holiday and add as first range
            Holiday hd = lstRecords.remove(0);
            HolidayRange current = new HolidayRange(hd.ActivityDate);

            for (Holiday h : lstRecords) {
                // If this holiday falls in the current range, extend end date to this holiday
                if (current.endDate.daysBetween(h.ActivityDate) == 1) {
                    current.endDate = h.ActivityDate;
                // If this holiday doesn't fall in the current range, add current range to list, and start a fresh range
                } else if (current.endDate.daysBetween(h.ActivityDate) > 1){
                    output.add(current);
                    current = new HolidayRange(h.ActivityDate);
                }
            }
            // Store the last range
            output.add(current);
        }
        return output;
    }

    /***************************************************************************************
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Function - Method that retrieves order taken details based on settings.
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         19/11/2015  //Method moved here from the individual flows as was copy pasted in 3 different
    ****************************************************************************************/
    public static MppUtil.OrderTakenDetails getOrderTakenFieldMap(String agentUserId, String orderTakenCompany, String orderMethod){
        MppUtil.OrderTakenDetails orderTakenInfo = new MppUtil.OrderTakenDetails();
        orderTakenInfo.orderMethod = orderMethod;
        orderTakenInfo.byCompany = Constants.CONST_DSOSOrderTakenCompany;
        orderTakenInfo.byUser = UserInfo.getName();

        //Enter OrderTakenCompany as ID in SubManagementDefaults Default will be the area eg: UK, South Africa etc
        list<SubManagementDefaults__c> lstOrderTakenDepartmentList = [Select DefaultValue__c From SubManagementDefaults__c Where ID__c = :orderTakenCompany];

        if (!lstOrderTakenDepartmentList.isEmpty()){
            orderTakenInfo.byCompany = lstOrderTakenDepartmentList[0].DefaultValue__c;
        }else{
            orderTakenInfo.byCompany = orderTakenCompany;
        }

        if(orderTakenCompany != 'TMG'){
            if (agentUserId != null){
                try{
                    orderTakenInfo.byUser = [select Name From User where id = :agentUserId].Name;
                }catch(System.Exception e){
                    orderTakenInfo.byUser = agentUserId;
                }
            }else{
                orderTakenInfo.byUser = 'Not Provided';
            }
        }
        return orderTakenInfo;
    }

    /***************************************************************************************
    Developer - Michal Szewczyk
    Date - 20/10/2016
    Version - 1.0
    Function - Method that retrieves values for One Time PaymentReason picklist on page
    #############Change Log#############
    Modified by     Version     Change Date
    Vishant Shah    2.9         03/11/2006  changed null first val to --None-- as per SUB-5493
    ****************************************************************************************/
    public List<SelectOption> getPaymentReasons(){
        sObject s = new MPP_Transaction_History__c();
        return Utilities.getPickValues(s , 'One_Time_Payment_Reason__c', Constants.NONE_PICKLIST_VALUE);
    }


    /**
    * @author Wiktor Czykin
    * @date 06/10/2015
    * @description Wrapper class for irregular payment schedule details - to be stored in a json format
    #############Change Log#############
    Modified by     Version     Change Date
    **/
    public class PaymentSetupWrapper{
        public List<MppPaymentInterface.PaymentSetup> lstPaymentSetup{get;set;}
        public Decimal dSwitchAmount{get;set;}
        public Date dtSwitchPaymentDate{get;set;}
        public Integer iSwitchOrderIndex{get;set;}
        public Integer iNumberOfPaymentsLowStart{get;set;}
        public Integer iNumberOfPaymentsStandard{get;set;}
    }

    /**
    * @author Wiktor Czykin
    * @date 25/09/2015
    * @description //Stores holidays as ranges in case a user has set up consecutive holidays
    #############Change Log#############
    Modified by     Version     Change Date
    **/
    public class HolidayRange {
        public Date startDate;
        public Date endDate;

        public HolidayRange(Date target) {
            this.startDate = target;
            this.endDate = target;
        }

        public Boolean isBetween(Date target) {
            return (target >= this.startDate && target <= this.endDate);
        }
    }

    public class OrderTakenDetails{
        public String orderDate;
        public String orderWave;
        public String orderMethod;
        public String byCompany;
        public String byUser;
    }

    //PP-1500 Inner class to store the details to be displayed in payment confirmation page
    public class ConfirmationDetails {
        public String duration{get;set;}
        public String paymentType{get;set;}
        public Double price{get;set;}
        public boolean isContinuous{get;set;}
        public String startDate{get;set;}
        //added changes as part of PP-2565
        public String endDate{get;set;}
        //ended part of PP-2565
    }
}
