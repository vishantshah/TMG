/**
Name: MPPRestAJAXService
* @author Unknown
* @date Unknown
* @description     Helper class that is eg called on button clicks from standard layout.
                As a sample -> subscription button MPP_Change_Frequency_to_Monthly
##########Change Log##########
Modified by     Version     Change Date
Wiktor Czykin   1.1         18/05/2015 //modified getChangePaymentDateResult(), getEditPaymentScheduleResult(), updateMPPDetailsOnSub(), added new methods
Wiktor Czykin   1.2         11/06/2015 //removed callout to MPP - getPaymentDetails() - frequency is sfdc based now
Wiktor Czykin   1.3         13/07/2015 //modifications to make offset parametrized
Cristina Anghenie1.4        10/09/2015 //stop MPP_DD_First_Payment_Amount__c,MPP_CC_First_Payment_Amount__c being overwritten by ChangePaymentDay and UpdatePaymentStartDate buttons
Wiktor Czykin   1.5         26/09/2016 //modified getEditPaymentScheduleResult() and getChangePaymentDateResult()
*/
global with sharing class MPPRestAJAXService{

  private static String testXML = null;
  @TestVisible private static Boolean bTestFail = false;

  private static final Set<String> SET_SUPPORTED_FREQUENCIES = new Set<String>{ Constants.DD_COL_FREQ_MONTHLY,
                                                                                Constants.DD_COL_FREQ_QUARTERLY,
                                                                                Constants.DD_COL_FREQ_ANNUAL
  };

  public static void setTestXML(String xmlData){
    MPPRestAJAXService.testXML = xmlData;
  }

  webservice static String getReactivatePaymentResult(String premSubId){
    String result = Label.MPP_Communication_General_error;
    MPPInterfaceHTTP callout = new MPPInterfaceHTTP();

    if(Test.isRunningTest()){
      callout.setTestXML(MPPRestAJAXService.testXML);
    }

        try{
            MPPInterfaceHTTP.ReactivatePaymentScheduleResult payment = callout.reactivatePaymentSchedule(premSubId);
            result = '---------- Message from MPP ----------';
            result += '\nSuccessfully reactivated payment.';
        }catch(MPPInterfaceHTTP.MPPInterfaceHTTPException e){
            result += '\n\n---------- Message from MPP ----------\n';
            result += 'Error code: ' + e.getErrorCode() + '\nError message: ' + e.getErrorMessage();
        }catch(System.Exception e){
            result += '\n\n---------- Message from SFDC ----------\n';
            result += 'Error message: ' + e.getMessage() + ' : ' + e.getStackTraceString();
        }

        return result;
    }

    webservice static String getCancelPaymentResult(String premSubId){
        String result = Label.MPP_Communication_General_error;
        MPPInterfaceHTTP callout = new MPPInterfaceHTTP();

        try{
            MPPInterfaceHTTP.CancelPaymentScheduleResult payment = callout.cancelPaymentSchedule(premSubId);
            result = '---------- Message from MPP ----------';
            result += '\nSuccessfully cancelled payment.';
        }catch(MPPInterfaceHTTP.MPPInterfaceHTTPException e){
            result += '\n\n---------- Message from MPP ----------\n';
            result += 'Error code: ' + e.getErrorCode() + '\nError message: ' + e.getErrorMessage();
        }catch(System.Exception e){
            result += '\n\n---------- Message from SFDC ----------\n';
            result += 'Error message: ' + e.getMessage() + ' : ' + e.getStackTraceString();
        }

    return result;
  }

  /***************************************************************************************
  Developer - Wiktor Czykin
  Date - 21/05/2015
  Version - 1.0
  Function - Extracted subscription record fetching as common across methods
  #############Change Log#############
  Modified by     Version     Change Date
  ****************************************************************************************/
  @TestVisible private static Subscription__c retrieveSubscriptionByMPPSubID(String premSubId){
    if(String.isBlank(premSubId)){
      throw new TelegraphApplicationException(Label.MPP_Communication_Missing_schedule_id_error);
    }
    List<Subscription__c> lstSub = [select Id,
                                           Subscriber__c,
                                           Subscriber__r.Subscriber_Number_Static__c,
                                                     MPP_CC_First_Payment_Amount__c,
                                                     MPP_CC_Frequency__c,
                                                     MPP_CC_Next_Payment_Date__c,
                                                     MPP_DD_First_Payment_Amount__c,
                                                     MPP_DD_Frequency__c,
                                                     MPP_DD_Next_Payment_Date__c,
                                                     PaymentDate__c,
                                                     Payment_Type__c,
                                                     Start_Date__c,
                                                     End_Date__c,
                                                     Subscription_Status__c,
                                                     MPP_Scheduled_First_Payment_Date__c
                                                  from Subscription__c
                                                  where MPP_Premium_Subscription_ID__c != null
                                                  and MPP_Premium_Subscription_ID__c = :premSubId
                                                  limit 1];
    if(lstSub.isEmpty() || lstSub.size()>1){
      throw new TelegraphApplicationException(Label.MPP_Communication_Could_not_retrieve_subscription_based_on_schedule_id);
    }
    return lstSub[0];
  }

  /***************************************************************************************
  Developer - Wiktor Czykin
  Date - 10/06/2015
  Version - 1.0
  Function - get proper frequency from Subscription record, throw exception if none is found
  #############Change Log#############
  Modified by     Version     Change Date
  ****************************************************************************************/
  @TestVisible private static String getFrequency(Subscription__c subscription){
    String sFrequency = '';
    if(subscription.Payment_Type__c.toUpperCase().contains('CARD')){
      sFrequency = subscription.MPP_CC_Frequency__c;
    }else if(subscription.Payment_Type__c.toUpperCase() == Constants.SUB_PMETHOD_DD){
      sFrequency = subscription.MPP_DD_Frequency__c;
    }
    if(String.isBlank(sFrequency) || !SET_SUPPORTED_FREQUENCIES.contains(sFrequency)){
      throw new TelegraphApplicationException(Label.MPP_Communication_Unable_to_retrieve_frequency);
    }
    return sFrequency;
  }

  /***************************************************************************************
  Developer - Wiktor Czykin
  Date - 21/05/2015
  Version - 1.0
  Function - check whether Subscription payment schedule can be updated (for day and frequency changes)
  #############Change Log#############
  Modified by     Version     Change Date
  ****************************************************************************************/
  private static Boolean validateUpdate(Subscription__c subscription){
    Set<String> setApplicableStatuses = new Set<String>{Constants.SSTATUS_ACTIVE, Constants.SSTATUS_PENDING};
    if(!setApplicableStatuses.contains(subscription.Subscription_Status__c)){
      return false;
    }
    return true;
  }

    /***************************************************************************************
  Developer - Wiktor Czykin
  Date - 06/2015
  Version - 1.1
  Function - tries to identify next payment schedule end date based on orders history and frequency
  #############Change Log#############
  Modified by     Version     Change Date
  Wiktor Czykin   1.1         10/07/2015  //as offset is now more dynamic, added resetting DAY to 15th or 1st
  ****************************************************************************************/
    @TestVisible private static Date retrievePaymentScheduleEndDateBasedOnOrders(MPPInterfaceHTTP callout, String sFrequency, Subscription__c subscription){
    // this logic could not be based on subscription start date as that caused discrepancies between SFDC and MPP and ended up in payment failures with next auto renewal
    MPPInterfaceHTTP.UserOrderHistoryResult orders = callout.getUserOrderHistoryFromMPP(null,
                                                                                           subscription.Subscriber__r.Subscriber_Number_Static__c,
                                                                                        Datetime.newInstanceGmt(subscription.Start_Date__c, Time.newInstance(0, 0, 0, 0)).addMonths(-6),
                                                                                        Datetime.newInstanceGmt(subscription.End_Date__c, Time.newInstance(0, 0, 0, 0)).addYears(2),
                                                                                        null,
                                                                                        true);
    if(String.isBlank(sFrequency)){
      throw new MPPInterfaceHTTP.MPPInterfaceHTTPException(Label.MPP_Communication_Missing_frequency_in_payment_details);
    }
    if(String.isBlank(orders.TotalNumberOfOrders) || (orders.TotalNumberOfOrders.isNumeric() && Integer.valueOf(orders.TotalNumberOfOrders)<=0) || orders.OrderHistoryItems == null){
      throw new MPPInterfaceHTTP.MPPInterfaceHTTPException(Label.MPP_Communication_No_orders_in_MPP);
    }

    Date dMppPayScheduleEndDate;
    try{
      MPPInterfaceHTTP.OrderHistoryItem ohi = orders.OrderHistoryItems[0];
      Datetime dt = Datetime.valueOfGmt(ohi.OrderDate.replace('T',' '));
      Date dValue = TMGDateExtension.getPaymentCollectionDate(dt.dateGmt());
      if(bTestFail){
        dValue = dValue.addDays(-1);
      }
      if(sFrequency == Constants.DD_COL_FREQ_MONTHLY){
        dValue = dValue.addMonths(1);
      }else if(sFrequency == Constants.DD_COL_FREQ_QUARTERLY){
        dValue = dValue.addMonths(3);
      }else if(sFrequency == Constants.DD_COL_FREQ_ANNUAL){
        dValue = dValue.addYears(1);
      }
      dMppPayScheduleEndDate = dValue;
      System.debug('TMGLOG::MPPRestAJAXService:retrievePaymentScheduleEndDateBasedOnOrders():Account  MPP Current Pay Schedule End Date updated with - ' + dValue);
    }catch(Exception e){
      throw new MPPInterfaceHTTP.MPPInterfaceHTTPException(Label.MPP_Communication_Date_conversion_error_in_order_fetching);
    }
    return dMppPayScheduleEndDate;
  }

  /***************************************************************************************
  Developer - Unknown
  Date - Unknown
  Version - 1.5
  Function - method called from buttons on subscription object - currently only called from MPPRestAJAXService
  #############Change Log#############
  Modified by     Version    Change Date
  Wiktor Czykin     1.1      27/04/2015 //added comment, extra exception handling, modified the soql so that it doesn't fail with limits hit.
  Wiktor Czykin     1.2      21/05/2015 //modified counting of MPP_CurrentPayScheduleEndDate__c (now retrieved from MPP based on orders)
  Wiktor Czykin     1.3      11/06/2015 //modified the source of frequency var - no longer from payment details from MPP
  Wiktor Czykin     1.4      13/07/2015 //removed offset from method signature, it based on fetched subscription now
  Wiktor Czykin     1.5      26/09/2016  //added extra catch to serve different error
  ****************************************************************************************/
  webservice static String getChangePaymentDateResult(String premSubId, String startDate, String dateOfMonth){
    String result = '';
    String newDate = (dateOfMonth.equals('15') ? '1' : '15');
    MPPInterfaceHTTP callout = new MPPInterfaceHTTP();

    try{
      Subscription__c sub = retrieveSubscriptionByMPPSubID(premSubId);
      if(!validateUpdate(sub)){
        return Label.MPP_Communication_Frequency_and_payment_data_validation;
      }
      sub.PaymentDate__c = newDate;

      String sDateOffset = sub.Payment_Type__c == Constants.SUB_PMETHOD_DD ? Constants.getMppDDOffsetNegative()+'': '0';
      String sFrequency = getFrequency(sub);
      MPPInterfaceHTTP.ChangePaymentScheduleDateResult payment = callout.changePaymentScheduleDate(premSubId, startDate, newDate, sDateOffset);
      Date dMppPayScheduleEndDate = retrievePaymentScheduleEndDateBasedOnOrders(callout, sFrequency, sub);

      // on update of the payment date, populate the MPP Current Pay Schedule End date on the associated Subscriber of the subscription
      if(Constants.MPP_SET_PAYMENTDAYS_VALID.contains(dMppPayScheduleEndDate.day())){
        AccountTriggerHandler ath = AccountTriggerHandler.getInstance();
        ath.bRunAPI = false;
        update new Account(Id = sub.Subscriber__c, MPP_CurrentPayScheduleEndDate__c = dMppPayScheduleEndDate);
        ath.bRunAPI = true;
      }else{
        result += Label.MPP_Communication_Unable_to_update_account_as_wrong_pay_schedule_end_date+'\n\n';
      }

      //REMEMBER:: payment object contain only the value of the next payment date after the modification based on the current position of the subscription in time
        updateMPPDetailsOnSub((!payment.getDatedPaymentsList().isEmpty() ? payment.getDatedPaymentsList()[0] : null), null, sub, (TMGUTil.isDataValid(payment.mppNextPaymentDate) ? Date.valueOf(payment.mppNextPaymentDate) : null), dMppPayScheduleEndDate);
      result += '---------- Message from MPP ----------';
      result += '\nSuccessfully changed payment date.';
      result += '\nNext Payment Date: ' + payment.mppNextPaymentDate;
      result += '\nChanged Date From: ' + dateOfMonth + ' To: ' + newDate;
    }catch(MPPInterfaceHTTP.MPPInterfaceHTTPException e){
      result += Label.MPP_Communication_General_error + '\n\n---------- Message from MPP ----------\n'+'\nError message: ' + e.getMessage();
    }catch(TelegraphApplicationException e){
        result += e.getMessage();
    }catch(System.Exception e){
      result += Label.MPP_Communication_General_error + '\n\n---------- Message from SFDC ----------\n'+'Error message: ' + e.getMessage();
    }
    return result;
    }

    /***************************************************************************************
  Developer - Unknown
  Date - Unknown
  Version - 1.4
  Function - edits PAyment Schedule in MPP - either the total amount or frequency (never both based on the buttons configuration on Subscription__c)
  #############Change Log#############
  Modified by     Version     Change Date
  Wiktor Czykin      1.1      27/04/2015  //added comment, extra exception handling, modified the soql so that it doesn't fail with limits hit.
  Wiktor Czykin      1.2      21/05/2015  //fully refactored, added same updates as for Payment Day change -> might not always be required but at least we are sure
                                            we get fresh data to SFDC
  Wiktor Czykin      1.3      10/06/2015  //made SFDC frequency value privileged (not the MPP retrieved one) - as MPP payment details was returning wrong value for Print subscription
  Wiktor Czykin      1.4      26/09/2016  //added extra catch to serve different error
  ****************************************************************************************/
  webservice static String getEditPaymentScheduleResult(String premSubId, String totalAmount, String frequency){
    String result =  '';
    MPPInterfaceHTTP callout = new MPPInterfaceHTTP();
    try{
      Subscription__c sub = retrieveSubscriptionByMPPSubID(premSubId);
      //if frequency is modified than validate
      if(frequency != Constants.DD_COL_FREQ_NOTSET && !validateUpdate(sub)){
        return Label.MPP_Communication_Frequency_and_payment_data_validation;
      }

      MPPInterfaceHTTP.EditPaymentScheduleResult payment = callout.editPaymentSchedule(premSubId, totalAmount.substring(1, totalAmount.length()), frequency);

      if(frequency == Constants.DD_COL_FREQ_NOTSET){
        frequency =  getFrequency(sub);
      }
      Date dMppPayScheduleEndDate = retrievePaymentScheduleEndDateBasedOnOrders(callout, frequency, sub);
      //On update of the payment date, populate the MPP Current Pay Schedule End date on the associated Subscriber of the subscription.
      //In the way this method is used it shouldn't in theory corrupt MPP_CurrentPayScheduleEndDate__c but re-setting it again just in case.
      if(Constants.MPP_SET_PAYMENTDAYS_VALID.contains(dMppPayScheduleEndDate.day())){
        AccountTriggerHandler ath = AccountTriggerHandler.getInstance();
        ath.bRunAPI = false;
        update new Account(Id = sub.Subscriber__c, MPP_CurrentPayScheduleEndDate__c = dMppPayScheduleEndDate);
        ath.bRunAPI = true;
      }else{
        result += Label.MPP_Communication_Unable_to_update_account_as_wrong_pay_schedule_end_date+'\n\n';
      }
      updateMPPDetailsOnSub((!payment.paymentDateList.isEmpty() ? payment.paymentDateList[0] : null), frequency, sub, null, dMppPayScheduleEndDate);

      result += '---------- Message from MPP ----------';
      result += '\nSuccessfully changed payment details.';
    }catch(MPPInterfaceHTTP.MPPInterfaceHTTPException e){
          result += Label.MPP_Communication_General_error + '\n\n---------- Message from MPP ----------\n'+e.getMessage();
    }catch(TelegraphApplicationException e){
        result += e.getMessage();
    }catch(System.Exception e){
          result += Label.MPP_Communication_General_error + '\n\n---------- Message from SFDC ----------\n'+'Error message: ' + e.getMessage();
    }
    return result;
  }

  /***************************************************************************************
  Developer - Wiktor Czykin
  Date - 21/05/2015
  Version - 1.1
  Function - retrieves payment details based on GetPaymentDetails callout to MPP
  #############Change Log#############
  Modified by     Version     Change Date
  ****************************************************************************************/
  @TestVisible private static MPPInterfaceHTTP.PaymentDetailResult retrievePaymentDetails(MPPInterfaceHTTP callout, String tsNumber){
    if(String.isBlank(tsNumber) || callout == null || !MPPInterfaceHTTP.MAP_ACCOUNT_FIELDS_TO_MPP_PARAMS.containsKey('Subscriber_Number_static__c')){
      throw new MPPInterfaceHTTP.MPPInterfaceHTTPException(Label.MPP_Communication_Missing_parameters_for_payment_details_callout);
    }

    String sParam = MPPInterfaceHTTP.MPP_CUSTOMPARAM_NAME+'01='+
            MPPInterfaceHTTP.MAP_ACCOUNT_FIELDS_TO_MPP_PARAMS.get('Subscriber_Number_static__c')+'&'+
            MPPInterfaceHTTP.MPP_CUSTOMPARAM_VALUE+'01='+tsNumber;
    List<MPPInterfaceHTTP.PaymentDetailResult> lstPaymentDetails = callout.getBulkPaymentDetailResult(sParam);
    if(lstPaymentDetails == null || lstPaymentDetails.isEmpty()){
      throw new TelegraphApplicationException(Label.MPP_Communication_Unable_to_retrieve_payment_details);
    }
    return lstPaymentDetails[0]; //as this mpp method returns list with one record only, never found a sample where 2 records would be returned
  }

  /***************************************************************************************
  Developer - Unknown
  Date - Unknown
  Version - 1.2
  Function - tries to set MPP related fields: First Payment Amount, Frequency, Next Payment Date for respective payment type.
  #############Change Log#############
  Modified by     Version     Change Date
  Wiktor Czykin      1.1           21/05/2015 //moved payment details fetching outside of this method, added setting of MPP_Pay_Schedule_End_Date__c
  Wiktor Czykin   1.2         10/06/2015 //temporarilly removed payment details dependency as it was returning wrong data, we might restore it once we get a fix from MPP.
  Cristina Anghenie 1.3          19/08/2015 //populate MPP_CC_First_Payment_Amount__c and MPP_DD_First_Payment_Amount__c using MPPInterfaceHTTP.DatedPayment
  Cristina Anghenie 1.4          10/09/2015 //dont overwrite MPP_CC_First_Payment_Amount__c,MPP_DD_First_Payment_Amount__c if there is no paymentDetails
  ****************************************************************************************/
  private static void updateMPPDetailsOnSub(MPPInterfaceHTTP.DatedPayment paymentDetails, String sFrequency, Subscription__c sub, Date nextPaymentDate, Date scheduleEndDate){

    if(sub.Payment_Type__c.toUpperCase().contains('CARD')){
          sub.MPP_CC_Frequency__c = (String.isNotBlank(sFrequency) ? sFrequency : sub.MPP_CC_Frequency__c);
        sub.MPP_CC_Next_Payment_Date__c = sub.MPP_Scheduled_First_Payment_Date__c;
        if(paymentDetails!=null){
            sub.MPP_CC_First_Payment_Amount__c =  Decimal.ValueOf(paymentDetails.Amount);
        }
    }else if(sub.Payment_Type__c.toUpperCase() == Constants.SUB_PMETHOD_DD){
        sub.MPP_DD_Frequency__c = (String.isNotBlank(sFrequency) ? sFrequency : sub.MPP_DD_Frequency__c);
        sub.MPP_DD_Next_Payment_Date__c = sub.MPP_Scheduled_First_Payment_Date__c;
        if(paymentDetails!=null){
            sub.MPP_DD_First_Payment_Amount__c = Decimal.ValueOf(paymentDetails.Amount);
        }
    }
    if(scheduleEndDate != null){
        sub.MPP_Pay_Schedule_End_Date__c = Datetime.newInstanceGmt(scheduleEndDate, Time.newInstance(0, 0, 0, 0));
    }
    update sub;
     }
}
