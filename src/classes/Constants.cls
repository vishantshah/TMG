/**
* @author Unknown
* @date Unknown
* @description Constants for the app
* #############Change Log#############
* Modified by     Version     Change Date
* Wiktor Czykin   3.8         11/2015     //modified MAP_SUBSCRIPTIONTYPE_LENGTH -> new mappings added, added MPP function strings
* Wiktor Czykin   3.9         30/11/2015  //added new SAM payment schedule related vars and getSAMPaymentScheduleParam() method
* Wiktor Czykin   4.0         04/12/2015  //added MAP_PAYMENTTYPE_SUBSCRIPTION_TO_MPP mapping of payment types strings, added vat settings key
* Wiktor Czykin 4.1     15/12/2015  //added list of supported subscription types, webservice log type var
* Sally ElGhoul   4.2     12/01/2016  //added constants for the offers search page
* Paweł Chrzanowski 4.3       25/01/2016  //added constants for Case
* Michal Szewczyk 4.4         25/01/2016  //added DateofBirth__c to SOQL query
* Sally ElGhoul   4.5         04/02/2016  //Added constant for SubsequentDiscountDuration custom setting
* Sally ElGhoul   4.6         12/02/2016  //add variables for the flat fee discount change
* Wiktor Czykin   4.7         15/02/2016  //added var for ACH. some allignment changes.
* Sally ElGhoul 4.8     16/2/2016 //add constant for open offer rate plans
* Sally ElGhoul 4.9     19/92/2016  //add constant of selecting tcode's incentives
* Wiktor Czykin   5.0     22/02/2016  //added var for core api
* Pawel Chrzanowski 5.1   23/02/2016  //added GENERAL_FIX_MPP_PAY_SCHEDULE_END_DATE
* Michal Kwika    5.2     24/02/2016  //added field Subscriber_Digital_Status__c to new world query strings
* Sally ElGhoul 5.3   29/02/2016  //add constant for the amendment Mid_term_Discount_Reason__c field name and the new mid term discount rate plan name
* Michal Szewczyk 5.4  09/03/2016  // Added Refund Discount Product Charge
* Michal Szewczyk 5.5  14/03/2016  // added Tcode payment options
* Michal Szewczyk 5.6  22/03/2016  // added Print in Product
* Sally ElGhoul 5.7  31/03/2016  //webservice log constants added
* Pawel Chrzanowski 5.8   26/04/2016  //set COMPLETE_CANCELLATION_STATUS to 'Completed'
* Gavin Palmer  5.9    27/04/2016  // added constants for subscription plan upload status
* Pawel Chrzanowski 6.0 27/04/2016  // added Business Transaction
* Pawel Chrzanowski 6.1   29/04/2016  // added Default Subscription Plan
* Wiktor Czykin   6.2     16/05/2016  //added default product id custom settings identifier
* Gavin Palmer    6.3     27/05/2016  // added constants for the product price type field
* Gavin Palmer    6.4     03/06/2016  //  added system user name custom setting name and the name as a defualt
* Michal Szewczyk 6.5     07/06/2016  //added default product id custom settings identifier for digital old world
* Gavin Palmer    6.6     08/06/2016  // added task picklist values, SAM Constants and some outbound calling constants
* Mantas Grigaliunas  6.7 09/06/2016  //removed DIGITAL_PRODUCT_IPAD constant as it is not used anymore
* Pawel Chrzanowski 6.8   21/06/2016  //added Lite Account status
* Mantas Grigaliunas  6.9 21/06/2016  //added REG_DATE_FORMAT_DD_FSLASH_MM_FSLASH_YYYY for date passed as a string validation
* Mantas Grigaliunas  7.0 18/07/2016  //new OC constants OC_SALES_RECORD_TYPE_DEVELOPER_NAME and OC_MAX_NUMBER_OF_STAGES
* Michal Szewczyk     7.1 21/07/2016  //added CASE_OUTBOUND_CALL_OUTCOME
* Wiktor Czykin       7.2 25/07/2016  //modified SUBSCRIPTION_WITHDRAWAL_CHECK_DAYSBACK
* Pawel Chrzanowski   7.3 25/07/2016  //added Case Outcomes
* Michal Szewczyk     7.4 28/07/2016  //added CASE_OUTBOUND_CALL_REASON and CASE_OUTBOUND_CALL_ORGIN
* Mantas Grigaliunas  7.7 19/08/2016  //renamed constant OC_CALL_STAGE_T2_28DAYS to OC_CALL_STAGE_T2
* Michal Szewczyk     7.8 13/09/2016  //added CASE_STATUS_COMPLETED
* Pawel Chrzanowski   7.9 28/09/2016  //added CASE_OUTCOME_RESCHEDULE
* Vishant Shah        8.0 04/10/2016  //added BUSINESS_TRANSACTION_STATUS_PAYMENT_FAILURE
* Wiktor Czykin       8.1 14/10/2016  //removed constants related to Offer Search - moved to offer search controller as used only there
* Konrad Czykin       8.2 23/05/2017  //added PRENOTIFICATIONHOLIDAY constant
* Konrad Czykin       8.3 14/06/2017  //added new case record type for charter - READER_RELATIONS_RECORD_TYPE_NAME
* Konrad Czykin       8.4 20/06/2017  //added Voucher Adjustments constants for Task creation
**/
public class Constants {

  ////////////////////////////////////////////New Digital Platform Constants////////////////////////
  //Common params
  public static String GET_PARAM_RETURL = 'retURL';
  
  //Lite Account
  public static String LITE_ACCOUNT_DIGITAL_STATUS = 'Registered';

  //Business Transaction
  public static String BUSINESS_TRANSACTION_STATUS_COMPLETE = 'Complete';
  public static String BUSINESS_TRANSACTION_STATUS_PAYMENT_FAILURE = 'Payment Failure';
  public static String OFFER_SWITCH_DATE_IMMEDIATE = 'Immediate';
  public static String OFFER_SWITCH_DATE_END_OF_TERM = 'End of the current Term';
  public static String BUSINESS_TRANSACTION_ALTERNATIVE_OFFERS_PAGE = 'BusinessTransactionAlternativeOffers';
  public static String BUSINESS_TRANSACTION_DISCRETIONARY_PRICE_CHANGE_PAGE = 'BusinessTransactionDiscPriceChange';

  //Outbound Constants
  public static String OUTBOUND_MONTHLY_FREQUENCY_LETTER  ='m';
  public static String OUTBOUND_ANNUAL_FREQUENCY_LETTER   ='a';
  public static String OUTBOUND_MONTHLY_BILLING_PERIOD  ='Month';
  public static String OUTBOUND_ANNUAL_BILLING_PERIOD ='Annual';
  public static String OUTBOUND_PRODUCT_URL_PARAM_VALUE_TABLET = 'tablet';
  public static String OUTBOUND_PRODUCT_URL_PARAM_VALUE_WEBSITE = 'website';

  //Profiles
  public static final String PROFILE_WEB_API = 'Web API';
  public static final String PROFILE_TMG_STANDARD_USER = 'TMG Standard User';

  //offers Search Page constants
  public static final String OFFER_SEARCH_MONTHLY_RATE_PLAN_NAME ='Open Offer - Monthly';
  public static final String OFFER_SEARCH_ANNUAL_RATE_PLAN_NAME ='Open Offer - Annual';
  public static final String OFFER_SEARCH_RECURRING_RATE_PLAN_CHARGE ='Recurring';
  public static final String OFFER_SEARCH_FLAT_FEE_RATE_PLAN_CHARGE ='Flat Fee Pricing';

  //Payment Values in Zuora and Salesforce
  public static final String CREDIT_CARD_PAYMENT_METHOD ='Credit Card';
  public static final String DEBIT_CARD_PAYMENT_METHOD ='Debit Card';
  public static final String DIRECT_DEBIT_PAYMENT_METHOD ='Bank Transfer';
  public static final String PAYMENT_METHOD_CREDIT_CARD_TYPE_LABEL ='Card Payment';
  public static final String PAYMENT_METHOD_DIRECT_DEBIT_TYPE_LABEL ='Direct Debit';

  public static final String PAYMENT_METHOD_CREDIT_CARD_TYPE  = 'CreditCard';
  public static final String PAYMENT_METHOD_DEBIT_CARD_TYPE   = 'DebitCard';
  public static final String PAYMENT_METHOD_DIRECT_DEBIT_TYPE = 'BankTransfer';
  public static final String PAYMENT_METHOD_ACH_TYPE          = 'ACH';
  public static final String PAYMENT_METHOD_PAYPAL_TYPE       = 'PayPal';

  //Offer Code Types
  public static final String OFFER_CODE_ACQUISITION_DISCOUNT_TYPE ='Acquisition Discount';
  public static final String OFFER_CODE_MID_TERM_DISCOUNT_TYPE ='Mid Term Discount';
  public static final String OFFER_CODE_DEFAULT_RATE_PLAN_DISCOUNT_TYPE ='Default Offer Code';

  //Zuora Amendments Constant Values and Fieldsse
  public static final String ZUORA_AMENDMENT_TYPE_FIELD_NAME ='Type';
  public static final String ZUORA_AMENDMENT_EFFECTIVE_DATE_FIELD_NAME ='EffectiveDate';
  public static final String ZUORA_AMENDMENT_DESCRIPTION_FIELD_NAME ='Description';
  public static final String ZUORA_AMENDMENT_ID_FIELD_NAME ='Id';
  public static final String ZUORA_AMENDMENT_NAME_FIELD_NAME ='Name';
  public static final String ZUORA_AMENDMENT_STATUS_FIELD_NAME ='Status';
  public static final String ZUORA_AMENDMENT_TYPE_OWNER_TRANSFER_VALUE ='OwnerTransfer';
  public static final String ZUORA_AMENDMENT_TYPE_TERMS_AND_CONDITIONS_VALUE ='TermsAndConditions';
  public static final String ZUORA_AMENDMENT_SUBSCRIPTION_START_DATE_FIELD_NAME = 'SubscriptionStartDate';
  public static final String ZUORA_AMENDMENT_MID_TERM_DISCOUNT_REASON_FIELD_NAME= 'Mid_term_Discount_Reason__c';

  //Subscription constant values
  public static final String DEFAULT_SUBSCRIPTION_PLAN = 'Default Subscription Plan';
  public static final String SUBSCRIPTION_CANCELLED_STATUS ='Cancelled';
  public static final String SUBSCRIPTION_PENDING_CANCELLATION_STATUS ='Pending Cancellation';
  public static final String SUBSCRIPTION_TYPE_AMENDMENT = 'Amended Subscription';
  public static final String SUBSCRIPTION_TYPE_AMENDMENT_CANCELLATION_ZUORA = 'Cancellation Amendement';
  public static final String SUBSCRIPTION_AMENDMENT_ZUORA_OBJECT_NAME = 'Amendment';
  public static final String SUBSCRIPTION_AMENDMENT_CANCELLATION_TYPE = 'Cancellation';

  //Subscription Product Charge Constant Values
  public static final String SUBSCRIPTION_PRODUCTCHARGE_FLAT_FEE_PRICING_VALUE ='flat fee pricing';
  public static final String SUBSCRIPTION_PRODUCTCHARGE_DISCOUNT_VALUE ='discount';

  //subscriber Digital status Values
  public static final String SUBSCRIBER_ACTIVE_STATUS ='Active';
  public static final String SUBSCRIBER_PENDING_CANCELLATION_STATUS ='Pending Cancellation';
  public static final String SUBSCRIBER_INACTIVE_STATUS ='Inactive';

  public static final String SUBSCRIPTION_ACTIVE_STATUS ='Active';
  public static final String SUBSCRIPTION_INACTIVE_STATUS ='Inactive';
  //Sub-665
  public static final String SUBSCRIPTION_PENDING_ACTIVATION_STATUS ='Pending Activation';
  public static final String SUBSCRIBER_PENDING_ACTIVATION_STATUS ='Pending Activation';

  //Quote Constant Values
  public static final String QUOTE_STATUS_NEW_VALUE ='New';
  public static final Integer QUOTE_NUMBER_OF_DAYS_EXTENDED_QUOTE = 14;

  //Zuora object names
  public static final String ZUORA_ACCOUNT_OBJECT_NAME      ='Account';
  public static final String ZUORA_CONTACT_OBJECT_NAME      ='Contact';
  public static final String ZUORA_ERROR_OBJECT_NAME        ='Error';

  //Zuora Notfication Strings
  public static final String ZUORA_NOTIFICATION_ERROR       ='ERROR!';
  public static final String ZUORA_NOTIFICATION_SUCCESS     ='SUCCESS!';

  //zuora Account Object Field Names
  public static final String ZUORA_ACCOUNT_NAME_FIELD_NAME    ='Name';
  public static final String ZUORA_ACCOUNT_CRMID_FIELD_NAME   ='CrmId';
  public static final String ZUORA_ACCOUNT_BATCH_FIELD_NAME   ='Batch';
  public static final String ZUORA_ACCOUNT_CURRENCY_FIELD_NAME  ='Currency';
  public static final String ZUORA_ACCOUNT_BILLCYCLEDAY_FIELD_NAME  ='BillCycleDay';
  public static final String ZUORA_ACCOUNT_BCD_SETTING_OPTION_FIELD_NAME='BcdSettingOption';
  public static final String ZUORA_ACCOUNT_PAYMENT_TETM_FIELD_NAME  ='PaymentTerm';
  public static final String ZUORA_ACCOUNT_STATUS_FIELD_NAME      ='Status';
  public static final String ZUORA_ACCOUNT_BILLTO_ID_FIELD_NAME   ='BillToId';
  public static final String ZUORA_ACCOUNT_SOLDTO_ID_FIELD_NAME   ='SoldToId';

  //Zuora account object field setting constants
  public static final String ZUORA_ACCOUNT_BATCH_FIELD_VALUE    ='Batch1';
  public static final String ZUORA_ACCOUNT_CURRENCY_FIELD_VALUE ='GBP';
  public static final Integer ZUORA_ACCOUNT_BILLCYCLEDAY_FIELD_VALUE= 0;
  public static final String ZUORA_ACCOUNT_BCD_SETTING_OPTION_FIELD_VALUE='AutoSet';
  public static final String ZUORA_ACCOUNT_PAYMENT_TERM_FIELD_VALUE ='Due Upon Receipt';
  public static final String ZUORA_ACCOUNT_STATUS_FIELD_DRAFT_VALUE ='Draft';
  public static final String ZUORA_ACCOUNT_STATUS_FIELD_ACTIVE_VALUE  ='Active';

  //Zuora Contact Field Names
  public static final String ZUORA_CONTACT_ACCOUNTID_FIELD_NAME ='AccountId';
  public static final String ZUORA_CONTACT_FIRST_NAME_FIELD_NAME ='FirstName';
  public static final String ZUORA_CONTACT_LAST_NAME_FIELD_NAME ='LastName';
  public static final String ZUORA_CONTACT_HOME_PHONE_FIELD_NAME  ='HomePhone';
  public static final String ZUORA_CONTACT_MOBILE_PHONE_FIELD_NAME='MobilePhone';
  public static final String ZUORA_CONTACT_COUNTRY_FIELD_NAME ='Country';
  public static final String ZUORA_CONTACT_POSTAL_CODE_FIELD_NAME ='PostalCode';
  public static final String ZUORA_CONTACT_ADDRESS1_FIELD_NAME ='Address1';
  public static final String ZUORA_CONTACT_CITY_FIELD_NAME ='City';
  public static final String ZUORA_CONTACT_COUNTY_FIELD_NAME ='County';
  public static final String ZUORA_CONTACT_STATE_FIELD_NAME ='State';

  //Zuora Error Constants
  public static final String ZUORA_ERROR_CODE_ATTRIBUTE_NAME = 'Code';
  public static final String ZUORA_ERROR_MESSAGE_ATTRIBUTE_NAME = 'Message';

  //Zuora Refund Discounts
  public static final String ZUORA_MONTHLY_REFUND_DISCOUNT_NAME = 'Recurring Refund Discount';
  public static final String ZUORA_ANNUAL_REFUND_DISCOUNT_NAME  = 'Annual Refund Discount';

  //Zuora Test Data Constants
  public static final String ZUORA_TEST_STRING = 'ZuoraTest';

  //Quote Fields Name
  public static final String ID_QUOTE_FIELD ='id';
  public static final String VALID_UNTI_DATE_FIELD  ='zqu__ValidUntil__c';
  public static final String SERVICE_ACTIVATION_DATE_FIELD  ='zqu__Service_Activation_Date__c';
  public static final String PAYMENT_METHOD_FIELD ='zqu__PaymentMethod__c';
  public static final String CURRENCY_FIELD ='zqu__Currency__c';
  public static final String START_DATE_FIELD ='zqu__StartDate__c';
  public static final String SUBSCRIPTION_TERM_TYPE_FIELD ='zqu__Subscription_Term_Type__c';
  public static final String ACCOUNT_FIELD ='zqu__Account__c';
  public static final String INITIAL_TERM_FIELD ='zqu__InitialTerm__c';
  public static final String RENEWAL_TERM_FIELD ='zqu__RenewalTerm__c';
  public static final String BILL_TO_CONTACT_FIELD ='zqu__BillToContact__c';
  public static final String SOLD_TO_CONTACT_FIELD ='zqu__SoldToContact__c';
  public static final String ACQUISITION_CHANNEL_FIELD ='Acquisition_Channel__c';
  public static final String QUOTE_PAYMENT_GATEWAY_FIELD ='zqu__PaymentGateway__c';
  public static final String QUOTE_AMENDMENT_NAME_FIELD ='zqu__Amendment_Name__c';
  public static final String QUOTE_SUBSCRIPTION_TYPE_FIELD ='zqu__SubscriptionType__c';
  public static final String QUOTE_PAYMENT_DETAILS_ENTERED_FIELD ='arePaymentDetailsEntered__c';
  public static final String QUOTE_NAME_FIELD ='Name';
  public static final String QUOTE_MASTER_QUOTE_ID_FIELD ='Master_Quote_ID__c';
  public static final String QUOTE_MASTER_QUOTE_FIELD ='Master_Quote__c';
  public static final String QUOTE_PREVIOUS_QUOTE_FIELD ='Previous_Quote__c';
  public static final String QUOTE_RELATED_QUOTE_ID_FIELD ='Related_Quote_ID__c';
  public static final String QUOTE_OFFER_CODE_FIELD ='Offer_Code__c';
  public static final String QUOTE_SUBSCRIPTION_TERM_TYPE_FIELD ='Subscription_Rate_Plan_Term_Type__c';
  public static final String QUOTE_SUBSCRIPTION_TERM_TYPE_BEFORE_AMENDMENT_FIELD ='Previous_Subscription_RatePlan_Term_Type__c';
  public static final String QUOTE_SUBSCRIPTION_NEXT_CHARGE_DATE_FIELD = 'Subscription_Next_Charge_Date__c';
  public static final String QUOTE_NAME_FORMAT ='{0} Quote';
  public static final String QUOTE_AMENDMENT_NAME_FORMAT ='{0} Amendment';
  public static final String QUOTE_OBJECT_NAME ='Quote';
  public static final String QUOTE_SUBSCRIPTION_ORIGIN ='Subscription_Origin__c';

  //Quote Rate Plan Constants
  public static final String RATE_PLAN_NEW_PRODUCT_AMENDMENT_TYPE = 'NewProduct';
  public static final String RATE_PLAN_MONTHLY = 'Monthly';
  public static final String RATE_PLAN_ANNUAL = 'Annual';

  //Product Details
  public static final String TABLET_UK_PRODUCT_NAME ='tablet+ uk';
  public static final String TABLET_INTERNATIONAL_PRODUCT_NAME ='tablet+ international';
  public static final String WEBSITE_UK_PRODUCT_NAME ='website+ uk';
  public static final String WEBSITE_INTERNATIONAL_PRODUCT_NAME ='website+ international';
  public static final String PRODUCT_FREQUENCY_ANNUAL = 'annual';
  public static final String PRODUCT_FREQUENCY_MONTHLY ='month';
  public static final String TCODE_OFFER_CODE_MANAGEMENT_PERMISSION_SET ='Campaign_Offer_Code_Management';

  //Payment Method Fields
  public static final String PAYMENT_METHOD_PAYMENT_DETAILS_FIELD  ='Default_Payment_Details__c';
  public static final String PAYMENT_METHOD_PAYMENT_TYPE_FIELD   ='Default_Payment_Method_Type__c';

  //QUOTE FIELDS CONSTANT VALUES
  public static final String QUOTE_SUBSCRIPTION_TYPE_AMEND_VALUE  ='Amend Subscription';
  public static final String QUOTE_SUBSCRIPTION_TYPE_NEW_VALUE    ='New Subscription';
  public static final String CREDIT_CARD_COUNTRY_FIELD_NAME_PAYMENT_PAGE_ZUORA   = 'creditCardCountry';
  public static final String CREDIT_CARD_ADDRESS1_FIELD_NAME_PAYMENT_PAGE_ZUORA    = 'creditCardAddress1';
  public static final String CREDIT_CARD_ADDRESS2_FIELD_NAME_PAYMENT_PAGE_ZUORA    = 'creditCardAddress2';
  public static final String CREDIT_CARD_CITY_FIELD_NAME_PAYMENT_PAGE_ZUORA   = 'creditCardCity';
  public static final String CREDIT_CARD_POSTAL_CODE_FIELD_NAME_PAYMENT_PAGE_ZUORA = 'creditCardPostalCode';
  public static final String DIRECT_DEBIT_FIRST_NAME_FIELD_NAME_PAYMENT_PAGE_ZUORA = 'firstName';
  public static final String DIRECT_DEBIT_LAST_NAME_FIELD_NAME_PAYMENT_PAGE_ZUORA  = 'lastName';
  public static final String DIRECT_DEBIT_ACCOUNT_NAME_FIELD_NAME_PAYMENT_PAGE_ZUORA  = 'bankAccountName';
  public static final String UNITED_KINGDOM_COUNTRY_THREE_CODE_VALUE     = 'GBR';
  public static final String UNITED_KINGDOM_COUNTRY_TWO_CODE_VALUE       ='GB';
  public static final String UNITED_KINGDOM_COUNTRY_NAME_VALUE      ='United Kingdom';
  public static final String SUBSCRIPTION_STATUS_ACTIVE_VALUE            ='Active';
  public static final String CREDIT_CARD_STATE_FIELD_NAME_PAYMENT_PAGE_ZUORA = 'creditCardState';
  public static final String BILL_CYCLE_DAY_DEFAULT_VALUE       ='Auto-Set';
  public static final String QUOTE_SUBSCRIPTION_TERM_TYPE       ='Termed';
  public static final String ZUORA_SUB_CAMPAIGN_CODE_FIELD_NAME = 'CampaignCode__c';

  //Create Quote Messages
  public static final String QUOTE_ERROR_GET_LATEST_ZUORA_SUBSCRIPTION ='Error has occurred to get the latest zuora subscription';

  //Zuora Credit Balance Adjustment
  public static final String ZUORA_CBA_TYPE_INCREASE = 'Increase';
  public static final String ZUORA_CBA_TYPE_DECREASE = 'Decrease';

  //Zuora Refund
  public static final String ZUORA_REFUND_SOURCE_TYPE_PAYMENT = 'Payment';
  public static final String ZUORA_REFUND_TYPE_ELECTRONIC     = 'Electronic';
  public static final String ZUORA_REFUND_TYPE_EXTERNAL       = 'External';
  public static final String ZUORA_PAYMENT_GATEWAY_STATE_SUBMITTED = 'Submitted';
  public static final String ZUORA_PAYMENT_GATEWAY_STATE_SETTLED   = 'Settled';


  //Default values for quote wizard;
  public static final integer INITIAL_TERM_VALUE_DEFAULT          =12;
  public static final integer RENEWAL_TERM_VALUE_DEFAULT          =12;
  public static final String ACQUISITION_CHANNEL_CALL_CENTER_VALUE    ='Call Centre';
  public static final String RENEWAL_SETTING_VALUE        ='RENEW_WITH_SPECIFIC_TERM';
  public static final String INVOICE_PROCESSING_OPTION_DEFAULT  ='Subscription';
  public static final String CALCULATE_QUOTE_METRICS_DEFAULT    ='EOT';
  public static final String BILLING_METHOD_DEFAULT       ='Print';

  //Registrant Record Type Name
  public static final String ACCOUNT_REGISTRANT_RECORD_TYPE_NAME    ='Registrant';
  public static final String ACCOUNT_INDIVIDUAL_RECORD_TYPE_NAME    ='Individual Subscriber';
  public static final String ACCOUNT_DIGITAL_RECORD_TYPE_NAME       ='Digital Subscriber';
  public static final String QUOTE_AMENDMENT_RECORD_TYPE_NAME   ='Amendment';
  public static final String QUOTE_NEW_SUBSCRIPTION_RECORD_TYPE_NAME='Default';

  //EndPoints
  public static final String CORE_API_EVENT_END_POINT_NAME            ='CoreApiEventEndPoint';
  public static final String CORE_API_RESET_PASSWORD_END_POINT_NAME   ='CoreApiResetPasswordEndPoint';
  public static final String CORE_API_GET_OFFER_DETAILS               ='OfferCodeEndPoint';
  public static final String CORE_API_GET_ALL_OFFERS  ='AllOfferCodesEndPoint';
  public static final String CORE_API_GET_OFFERS_BY_PRODUCT_AND_FREQUENCY = 'OffersByProductAndFrequencyEndPoint';
  public static final String CORE_API_APP_ID_Key_Name                 = DefaultSettings.CORE_API_APP_ID;
  public static final String CORE_API_APP_ID_Value                    = DefaultSettings.CORE_API_APP_ID_VALUE;
  public static final String CORE_API_APP_KEY_NAME                    = DefaultSettings.CORE_API_APP_KEY;
  public static final String CORE_API_APP_VALUE                       = DefaultSettings.CORE_API_APP_KEY_VALUE;
  public static final String CORE_API_CONTENT_TYPE_KEY_VALUE          ='Content-Type';
  public static final String CORE_API_JSON_CONTENT_TYPE_VALUE         ='application/json';
  public static final String CORE_API_UPGRADE_END_POINT_NAME          ='CoreApiUpgradeEndPoint';
  public static final String CORE_API_PUT_OFFER_END_POINT_NAME        ='CoreApiPutOfferEndPoint';
  public static final String GET_OFFER_CODE_ACCEPT_KEY_HEADER         ='Accept';
  public static final String GET_OFFER_CODE_ACCEPT_VALUE_HEADER       ='application/vnd.tcuk.commerce+v0.1.0+json';
  public static final String CORE_API_SAM_USER_SEARCH_BY_EMAIL        ='CoreAPISAMUserSearchByEmail';
  public static final String CORE_API_SAM_USER_GET_PROFILE_BY_ID      ='CoreAPISAMUserGetProfile';
  public static final String CORE_API_SAM_DOUBLE_ENCODING             ='CoreAPIDoubleEncoding';
  public static final String SOCIAL_REGISTRATION_GET_END_POINT        = 'SocialRegistrationGetEndPoint';
  public static final String SOCIAL_REGISTRATION_DELETE_END_POINT     = 'SocialRegistrationDeleteEndPoint';
  public static final String NEWSLETTERS_GET_END_POINT                = 'NewslettersGetEndpoint';
  public static final String NEWSLETTERS_POST_END_POINT               = 'NewslettersPostEndpoint';
  public static final String NEWSLETTERS_PUT_END_POINT                = 'NewslettersPutEndpoint';
  public static final String ZUORA_API_NAME                           = 'Zuora API';

  //Tcode payment options
  public static String  ALLOW_ONE_OFF_13_WEEK = 'Allow One Off 13 Week';
  public static String  ALLOW_ONE_OFF_26_WEEK = 'Allow One Off 26 Week';
  public static String  ALLOW_ONE_OFF_52_WEEK = 'Allow One Off 52 Week';
  public static String  ALLOW_13_WEEK_DD = 'Allow 13 Week DD';
  public static String  ALLOW_13_WEEK_CCA = 'Allow 13 Week CCA';
  public static String  ALLOW_26_WEEK_DD= 'Allow 26 Week DD';
  public static String  ALLOW_26_WEEK_CCA = 'Allow 26 Week CCA';
  public static String  ALLOW_52_WEEK_DD = 'Allow 52 Week DD';
  public static String  ALLOW_52_WEEK_CCA = 'Allow 52 Week CCA';

  public static String  ONE_OFF_13_WEEK_APPLICABLE = 'One Off 13 Week Applicable';
  public static String  ONE_OFF_26_WEEK_APPLICABLE ='One Off 26 Week Applicable';
  public static String  ONE_OFF_52_WEEK_APPLICABLE ='One Off 52 Week Applicable';
  public static String  CONTINUOUS_13_WEEK_APPLICABLE ='Continuous 13 Week Applicable';
  public static String  CONTINUOUS_26_WEEK_APPLICABLE ='Continuous 26 Week Applicable';
  public static String  CONTINUOUS_52_WEEK_APPLICABLE ='Continuous 52 Week Applicable';
  //CoreApiConstant
  public static final String NEW_RECORD_CREATED_ACTION_NAME       ='Created';
  public static final String UPDATED_RECORD_ACTION_NAME           ='Updated';
  public static final String DELETED_RECORD_ACTION_NAME           ='Deleted';
  public static final String CORE_API_CHANGE_DEFAULT_PAYMENT_METHOD_EVENT = 'PaymentMechanismChanged';
  public static final String CARD_DETAILS_CHANGE_ACTION_NAME = 'CardDetailsStoredChanged';

  //Discounts and Offer Codes Constants
  public static final string DISCOUNT_RATE_PLAN_NAME                        = 'Charge Discount';
  public static final string EMPTY_DISCOUNT_RATE_PLAN_NAME          = 'Discount';
  public static final string MID_TERM_DISCOUNT_RATE_PLAN_NAME   = 'Discretionary Discount';
  public static final string DISCOUNT_END_DATE_CONDITION_VALUE        = 'Fixed Period';
  public static final string DISCOUNT_UP_TO_HOW_MANY_PERIODS_TYPE_VALUE   = 'Billing Periods';
  public static final string INVALID_OFFER_CODE_ERROR_MESSAGE               = 'Invalid Offer Code.';
  public static final string OFFER_CODE_REQUIRED_ERROR_MESSAGE              = 'You must enter an offer code first';
  public static final string OFFER_CODE_ONE_PRODUCT_REQUIRED_ERROR_MESSAGE  = 'You must have at least one product to enter an offer Code';
  public static final string OFFER_CODE_NO_DISCOUNT_RATE_PLAN_ERROR_MESSAGE = 'No Discount Rate Plan for this product';
  public static final string INVALID_PAYMENT_METHOD_VALUE_ERROR_MESSAGE     = 'Invalid Payment Method Value';
  public static final string OPEN_OFFER_RATE_PLAN_VALUE                     = 'Open Offer';
  public static final string REFUND_RATE_PLAN_NAME                          = 'Refund Discount';
  public static final String OFFER_TYPE_FREE_TRIAL = 'Free Trial';
  public static final String OFFER_TYPE_INTRODUCTORY = 'Introductory';
  //Visual Force URLS,querty strings
  public static final String PAYMENT_STEP_PAGE_ACTION_QUERY_STRING_KEY    = 'action';
  public static final String PAYMENT_STEP_PAGE_ACTION_ADD                 = 'add';
  public static final String PAYMENT_STEP_PAGE_ACTION_SEND                = 'send';
  public static final String NEW_QUOTE_WIZARD_PAGE_URL                    = 'https://{0}/apex/CreateQuote?crmAccountId={1}&quoteType=Subscription&retUrl=/{2}&stepNumber=1';
  public static final String AMEND_SUBSCRIPTION_WIZARD_PAGE_URL       = 'https://{0}/apex/CreateQuote?billingAccountId={1}&crmAccountId={2}&quoteType=Amendment&retUrl=/{3}&stepNumber=1&subscriptionId={4}';
  public static final String REVOKE_SUBSCRIPTION_CANCELLATION_PAGE_URL    = '/apex/Zuora_RevokeCancellation';
  public static final String QUOTE_ID_QUERY_STRING              = 'quoteId';
  public static final String SF_ACCOUNT_ID_QUERY_STRING           = 'sfAccountId';
  public static final String SUBSCRIPTION_ID_QUERY_STRING     = 'subId';
  public static final String PAYMENT_METHOD_ID_QUERY_STRING         = 'PayMethodId';
  public static final String ID_QUERY_STRING          ='Id';
  public static final String REFERESH_QUOTE_METRICS_QUERY_STRING  ='refreshQMetrics';

  //Regular Expressions strings
  public static final String REG_EXPRESSION_LETTERS_ONLY                    ='^[^0-9!\"#&$%&()*+,./:;<=>?@\\[\\]\\^\\{|}_~]+$';
  public static final String REG_VALID_EMAIL_FORMAT             ='([a-zA-Z0-9_\\-\\.]+)@((\\[a-z]{1,3}\\.[a-z]{1,3}\\.[a-z]{1,3}\\.)|(([a-zA-Z0-9\\-]+\\.)+))([a-zA-Z]{2,4}|[0-9]{1,3})';
  public static final String REG_NEW_EMAIL_FORMAT = '([a-zA-Z0-9_\\-\\.+]+)@((\\[a-z]{1,3}\\.[a-z]{1,3}\\.[a-z]{1,3}\\.)|(([a-zA-Z0-9\\-]+\\.)+))([a-zA-Z]{2,4}|[0-9]{1,3})';
  public static final String REG_UPDATED_EMAIL_FORMAT = '^[a-zA-Z0-9.!#$%&’*+=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\\.[a-zA-Z0-9-]+)*$';
  public static final String REG_GB_POSTCODE_FORMAT = '^(([gG][iI][rR]{0,}0[aA]{2})|((([a-pr-uwyzA-PR-UWYZ][a-hk-yA-HK-Y]?[0-9][0-9]?)|(([a-pr-uwyzA-PR-UWYZ][0-9][a-hjkstuwA-HJKSTUW])|([a-pr-uwyzA-PR-UWYZ][a-hk-yA-HK-Y][0-9][abehmnprv-yABEHMNPRV-Y]))) {0,}[0-9][abd-hjlnp-uw-zABD-HJLNP-UW-Z]{2}))$';
  public static final String REG_DATE_FORMAT_DD_FSLASH_MM_FSLASH_YYYY = '^(0[1-9]|[12][0-9]|3[01])[- /.](0[1-9]|1[012])[- /.](19|20)\\d\\d$';

  //soql statments
  public static final String SEARCH_ACCOUNT_LAST_NAME_CONDITION   = 'LastName={0}';
  public static final String SEARCH_ACCOUNT_POSTAL_CODE_CONDITION = 'PersonMailingPostalCode={0}';
  public static final String SEARCH_ACCOUNT_POSTAL_CODE_CONDITION_EXTENDED = '(PersonMailingPostalCode={0} OR PersonMailingPostalCode={1})';
  public static final String SEARCH_ACCOUNT_EMAIL_CONDITION     = 'PersonEmail={0}';
  public static final String SEARCH_ACCOUNT_EMAIL_CONDITION_WITH_ACC_ID = 'SELECT Id,Name,PersonEmail FROM Account WHERE PersonEmail={0} AND Id!={1}';
  public static final String SEARCH_ACCOUNT_TS_NUMBER_CONDITION   = 'Subscriber_Number_static__c={0}';
  public static final String SEARCH_ACCOUNT_NEW_ACCOUNT_WIZARD      = 'SELECT RecordTypeId,Digital_Status__c,Subscription_Status__c, IsPersonAccount, id, Salutation, FirstName, LastName, PersonEmail, PersonMailingCity, PersonMailingPostalCode, PersonMailingState, PersonMailingStreet, Subscriber_Number_static__c,Country_Name__c,PersonMobilePhone,PersonHomePhone, Digital_Product_Type__c, Subscriber_Digital_Status__c,DateofBirth__c,(Select Zuora__ProductName__c from R00N40000001lGjTEAU__r where Subscription_Status__c ={0} limit 1),(select id from Subscriptions1__r where Subscription_Status__c={1} limit 1) FROM Account WHERE ({2}) ORDER BY CreatedDate DESC';
  public static final String SEARCH_ACCOUNT_NEW_ACCOUNT_WIZARD_NEW      = 'SELECT RecordTypeId,Digital_Status__c,Subscriber_Digital_Status__c,Subscription_Status__c, IsPersonAccount, Title__c, id, Salutation, FirstName, LastName, PersonEmail, PersonMailingCity, PersonMailingPostalCode, PersonMailingState, PersonMailingStreet, PersonMailingCountry, Subscriber_Number_static__c,Country_Name__c,PersonMobilePhone,PersonHomePhone,DateofBirth__c,(Select Zuora__ProductName__c from R00N40000001lGjTEAU__r where Subscription_Status__c ={0} limit 1),(select id from Subscriptions1__r where Subscription_Status__c={1} limit 1) FROM Account WHERE ({2}){3} ORDER BY LastModifiedDate DESC LIMIT 11000';
  public static final String SEARCH_ACCOUNT_NEW_ACCOUNT_WIZARD_NEW_FOR_TEST      = 'SELECT RecordTypeId,Digital_Status__c,Subscriber_Digital_Status__c,Subscription_Status__c,Subscriber_Number__c, IsPersonAccount, Title__c, id, Salutation, FirstName, LastName, PersonEmail, PersonMailingCity, PersonMailingPostalCode, PersonMailingState, PersonMailingStreet, PersonMailingCountry, Subscriber_Number_static__c,Country_Name__c,PersonMobilePhone,PersonHomePhone,DateofBirth__c FROM Account';
  public static final String SEARCH_ACCOUNT_NEW_ACCOUNT_WIZARD_NEW_ORDERBY_LASTNAME_10K     = 'SELECT RecordTypeId,Digital_Status__c,Subscriber_Digital_Status__c,Subscription_Status__c, IsPersonAccount, id, Salutation, FirstName, LastName, PersonEmail, PersonMailingCity, PersonMailingPostalCode, PersonMailingState, PersonMailingStreet, Subscriber_Number_static__c,Country_Name__c,PersonMobilePhone,PersonHomePhone,Title__c,DateofBirth__c,(Select Zuora__ProductName__c from R00N40000001lGjTEAU__r where Subscription_Status__c ={0} limit 1),(select id from Subscriptions1__r where Subscription_Status__c={1} limit 1) FROM Account WHERE ({2}){3}{4} ORDER BY FirstName ASC LIMIT 11000';
  public static final String SEARCH_ACCOUNT_RECORDTYPE_CONDITION   = 'AND RecordTypeId={0}';
  public static final String SEARCH_ACCOUNT_RECORDTYPE_CONDITION_NOT   = 'AND RecordTypeId!={0}';
  public static final String SEARCH_ACCOUNT_FIRST_LETTER_CONDITION  = ' AND FirstName LIKE {0}';
  public static final String OFFER_CODE_ACTIVE_ACQUISITION_DEFAULT_CODES_WHERE_CLAUSE='Quote__c={0} and (Type__c={1} or Type__c={2})';
  //Others
  public static final String NONE_PICKLIST_VALUE  = '--None--';
  public static final String COUNTRY_UNITED_STATES_TWO_LETTERS_CODE = 'US';
  public static final String COUNTRY_CANADA_TWO_LETTERS_CODE = 'CA';
  public static final String ZUORA_NEW_ACCOUNT_STRING_VALUE = 'new';
  public static final String SUBSCRIPTION_CANCELLATION_REASON_PRICE = 'Price';
  public static final String CANCELLATION_GRACE_PERIOD_CUSTOM_SETTING_NAME = 'GracePeriodDuration';
  public static final String ZUORA_REFUND_REASONCODE_PAYMENTREJECTION = 'Payment Rejection';
  public static final String ZUORA_REFUND_REASONCODE_PAYMENTREVERSAL = 'Payment Reversal';
  public static final List<String> BILLING_PERIOD_VALUES_LIST = new List<String>{'Month','Annual'};
  public static final String TEST_QUOTE_CREATION_FAILURE_CUSTOM_SETTING = 'TestQuoteCreationFailure';
  public static final String SUBSCRIPTION_CANCELLATION_REASON_PRODUCTSWITCH = 'Amendment';
  public static final String OPEN_OFFER_TCODE_TYPE ='Open Offer';

  //Error Messages
  public static final String ERROR_INVALID_SALESFORCE_ACCOUNT_ID  ='Invalid Salesforce Account. Please contact your administrator.';

  //Gateway Names Custom Settings
  public static final String DIRECT_DEBIT_GATEWAY_NAME              = 'DirectDebitGatewayName';
  public static final String UK_CREDIT_CARD_GATEWAY_NAME            = 'UKCreditCardGatewayName';
  public static final String INTERNATIONAL_CREDIT_CARD_GATEWAY_NAME = 'InternationalCreditCardGatewayName';
  public static final String PAYPAL_GATEWAY_NAME                    = 'PaypalGatewayName';
  public static final String MONTHLY_MINIMUM_PAYMENT_AMOUNT         = 'Monthly Minimum Payment Amount';

  //Custom Setting Values
  public static final String FIRE_CORE_API_OFFERS_CALLOUT = 'CallCoreApiForOfferSync';
  public static final String FIRE_CORE_API_CALL_FOR_ACCOUNT_CREATION ='CallCoreApiForAccountCreation';
  public static final String FIRE_CORE_API_CALL_FOR_SAM_KNOWN_USER_CONVERSION = 'EnableKnownUserFromSAMfetching';
  public static final String DEFAULT_OFFER_CODE_TMG_IDS                       = 'DefaultOfferCodeIds';
  public static final String TCODE_OFFER_FIELDS_UK_PRODUCTS                   = 'Tcode Offers UK Fields';
  public static final String TCODE_OFFER_FIELDS_INTERNATIONAL_PRODUCTS        = 'Tcode Offers International Fields';
  public static final String CALCULATE_CREDIT_BALANCE_FOR_BILLING_PREVIEW   = 'CalculateCreditBalanceBillingPreview';
  public static final String SUBSEQUENT_DISCOUNT_DURATION_VALUE         = 'SubsequentDiscountDuration';

  //Send to Zbilling
  public static final String ZUORA_SEND_TO_ZBILLING_SUCCESS_MESSAGE             = 'The quote has been successfully sent to Z-Billing';
  public static final String ZUORA_SEND_TO_ZBILLING_SUCCESS_MESSAGE_SUB_SETUP   = 'Subscription has been successfully set up';
  public static final String ZUORA_SEND_TO_ZBILLING_SUCCESS_MESSAGE_ACCESS      = 'Access to content available from Subscription Start Date';
  public static final String ZUORA_SEND_TO_ZBILLING_SUCCESS_MESSAGE_REVIEW      = 'Please review Subscription, Payment, Invoice detail from the Account page (click OK button to be directed there!)';
  public static final String ZUORA_SEND_TO_ZBILLING_SUCCESS_MESSAGE_THANK       = 'Please thank Subscriber';
  public static final String ZUORA_OK_BUTTON_TEXT                     = 'Ok';
  public static final String ZUORA_ZBILLING_ACCOUNT_OBJECT_NAME               = 'Account';
  public static final String ZUORA_ZBILLING_ACCOUNT_ID_FIELD_NAME             = 'Id';
  public static final String ZUORA_ZBILLING_ACCOUNT_DEFAULT_PAYMENT_FIELD_NAME        = 'DefaultPaymentMethodId';
  public static final String ZUORA_ZBILLING_ACCOUNT_AUTO_PAY_FIELD_NAME           = 'AutoPay';
  public static final String ZUORA_ZBILLING_ACCOUNT_PAYMENT_GATEWAY             = 'PaymentGateway';
  public static final String ZUORA_ZBILLING_MISSING_QUERY_STRING_ERROR_MESSAGE        = 'Missing query String for send to zbilling';
  public static final String ZUORA_ZBILLING_SUBSCRIPTION_OBJECT_NAME            = 'Subscription';
  public static final String ZUORA_ZBILLING_SUBSCRIPTION_CANCELLATION_REASON_FIELD_NAME   = 'Cancellation_Reason__c';
  public static final String ZUORA_ZBILLING_SUBSCRIPTION_SUB_CANCELLATION_REASON_FIELD_NAME = 'Sub_Cancellation_Reason__c';
  public static final String ZUORA_ZBILLING_SUBSCRIPTION_EFFECTIVE_CANCELLATION_FIELD_NAME  = 'Cancellation_Effective_Date_Time_String__c';
  public static final String ZUORA_ZBILLING_SUBSCRIPTION_PROCESS_CANCELLATION_FIELD_NAME  = 'Cancellation_Process_Date_Time_String__c';
  public static final String ZUORA_ZBILLING_SUBSCRIPTION_ID_FIELD_NAME            = 'Id';
  //////////////////////////////////////////////////////////////////////////////////////////////////
  //Profiles
  public static final String PROFILE_TMGSYSTEM = 'TMG System';
  public static final String PROFILE_SYSTEMADMINISTRATOR = 'System Administrator';

  //Settings
  public static final String GENERAL_SUBSCRIPTION_STARTDATEVALIDATION = 'Subscription Start Date Validation';
  public static final String SUBSCRIPTION_STARTDATEVALIDATION_SPLIT = ';';
  public static final String GENERAL_DAYS_CC_EXPIRY_DATE = 'No of Days CC Expiry Date';
  public static final String VAT_SETTINGS_VAT = 'VAT';
  public static final String GENERAL_FIX_MPP_PAY_SCHEDULE_END_DATE = 'fixMPPPayScheduleEndDate';

  //FISCAL MONTHS
  public static List<String> listFiscalMonths = new List<String>{'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November','December'};
  public static List<Integer> listFiscalMonthsNbWeeks = new List<Integer>{4,4,5,4,4,5,4,4,5,4,4,5};
  /* Subscriber Constants */

  //Subscriber Constants
  public static final String SUBSCRIBER_ORIGIN_FLOW_OFFLINE = 'Offline';
  public static Map<String,boolean> debugMessage;

  public static final String DIGITAL_RECORDTYPE = '01220000000AIQp';
  public static final String PREMIUM_RECORDTYPE = '01220000000DCSr';

  //Subscriber Status
  public static String DIGITAL_SUBSCRIBER_STATUS_ACTIVE = 'Active';
  public static String DIGITAL_SUBSCRIBER_STATUS_INACTIVE = 'Inactive';

  // Subscription Status
  public static String SSTATUS_ACTIVE = 'Active';
  public static String SSTATUS_INACTIVE = 'Inactive';
  public static String SSTATUS_IN_RENEWAL = 'In Renewal';
  public static String SSTATUS_OFFERED = 'Offered';
  public static String SSTATUS_PENDING = 'Pending';
  public static String SSTATUS_WITHDRAWN = 'Withdrawn';
  public static String SSTATUS_DECLINED = 'Declined';
  public static String SSTATUS_LAPSED = 'Lapsed';
  public static String SSTATUS_PENDING_CANX = 'Pending Cancellation';
  public static String SSTATUS_CANX = 'Cancelled';
  public static String SSTATUS_TEMP_SUSPENSION = 'Temporary Suspension';

  //Subscription TBW Status change
  public static Integer SUBSCRIPTION_ENDDATE_CHECK_DAYSBACK = 1;
  public static String SUBSCRIPTION_ENDDATE_CHECK_DAYSBACK_SETTING = 'Batch Subscription End Date Check';
  public static Integer SUBSCRIPTION_WITHDRAWAL_CHECK_DAYSBACK = 90;
  public static String SUBSCRIPTION_WITHDRAWAL_CHECK_DAYSBACK_SETTING = 'Batch Subscription Withdrawal Check';
  public static String SUBSCRIPTION_STATUS_BATCH_ERROR_USERID = 'Batch Subscription Failure User Email';
  public static String SUBSCRIPTION_STATUS_BATCH_ERROR_EMAILS = 'Batch Renewal Failure Emails';

  //Task Status and Outcomes
  public static final String TSTATUS_OFFERED = 'Offered';
  public static final String TSTATUS_COMPLETED = 'Completed';
  public static final String TSTATUS_INPROGRESS = 'In Progress';
  public static final String TSTATUS_NOTSTARTED = 'Not Started';
  public static final String TOUTCOME_SALE = 'Sale';
  public static final String TOUTCOME_NOSALE = 'No Sale';
  public static final String TOUTCOME_AUTOCOMPLETED = 'Auto Completed';
  public static final String TOUTCOME_BUSY = 'Busy';
  public static final String TOUTCOME_NOANSWER = 'No Answer';
  public static final String TOUTCOME_ANSWERPHONE = 'Answerphone';

  public static final String TASK_PRIORITY_NORMAL = 'Normal';
  public static final String TASK_TYPE_CALL = 'Call';

  public static final String TAST_REASON_ACQUISITION ='Acquisition';
  public static final String TAST_REASON_CASHPOSTING = 'Cashposting';

  // Subscription Products
  public static String SPRODUCT_7DAY = '7 Day - Standard';
  public static String SPRODUCT_7DAY_SUB = '7 days Subs';
  public static String SPRODUCT_7DAY_GIFT = '7 Day - Gift';
  public static String SPRODUCT_SPECIAL156 = 'Special 156 Subs';
  public static String SPRODUCT_13WEEK = '7 Day - 13 weeks';

  // Subscription Payment Methods
  public static String SUB_PMETHOD_DD = 'Direct Debit';
  public static String SUB_PMETHOD_CC = 'Credit Card';
  public static String SUB_PMETHOD_DEBIT_CARD = 'Debit Card';
  public static String SUB_PMETHOD_CHARGE_CARD = 'Charge Card';
  public static String SUB_PMETHOD_CHEQUE = 'Cheque';

  public static String SUB_ACQUISITION_PAYMENT_CC = 'CC';
  public static String SUB_ACQUISITION_PAYMENT_DD = 'DD';

  //Subscription 23 days
  public static final String SUBSCRIPTION_RENEWAL_FIRST_CLASS_FEATURE = 'Renewal First Class Feature';
  public static final String SUBSCRIPTION_RENEWAL_FIRST_CLASS_CUTOFF = 'Renewal First Class Cutoff';
  public static final String SUBSCRIPTION_RENEWAL_FIRST_CLASS_LEAD_TIME = 'Renew First Class Lead Time';
  public static final String SUBSCRIPTION_RENEWAL_EXTRACT_TIME = 'Renewal First Class Extract Time';
  public static final String SUBSCRIPTION_RENEWAL_EXTRACT_TIME_SPLIT = ':';

  //Subscription picklist values
  public static final String SUBSCRIPTION_TASKCREATION_CALL = 'Call';
  public static final String SUBSCRIPTION_TASKCREATION_CASHPOSTING = 'Cashposting';

  //OAP
  public static Boolean SUB_TESTMODE = false;
  public static boolean displayHeaderCustomSinglePayment{get;set;}
  public static boolean displayHeaderMarketingPerms{get;set;}
  public static String SUBSCRIPTION_EMAIL_OFFER = 'Subscription email Offer';
  public static String SUBSCRIPTION_LETTER_OFFER = 'Subscription letter Offer';
  public static String SUBSCRIPTION_EMAIL_AND_LETTER_OFFER = 'Subscription letter and email offer';

  //clean up operations
  public static String LIVE_ORG_ID = '00D2000000093Wf';
  public static String TEAMSALESFORCE_EMAIL = 'teamsalesforce@telegraph.co.uk';

  // Gift SUbscription values
  public static String SUB_WEEKLYPRICE = '7.30';
  public static String SUB_ORDER_METHOD_INBOUND = 'Inbound';
  public static String SUB_ORDER_WAVE_GIFT = '857T';

  // Digital SAM entitlements
  public static String DIGITAL_SUBSCRIBER_ACTIVE = 'DIGITAL_SUBSCRIBER_ACTIVE';

  public static String IPAD_SUBSCRIBER_ACTIVE = 'IPAD_SUBSCRIBER_ACTIVE';
  public static String WEBPACK_SUBSCRIBER_ACTIVE = 'WEBPACK_SUBSCRIBER_ACTIVE';

  public static String DIGITAL_SUBSCRIBER_INACTIVE = 'DIGITAL_SUBSCRIBER_INACTIVE';
  public static String WEBPACK_SUBSCRIBER_INACTIVE = 'WEBPACK_SUBSCRIBER_INACTIVE';

  // Digital product types
  public static final String DIGITAL_PRODUCT_WEBPACK = 'Web pack';
  public static final String DIGITAL_PRODUCT_ALLDEVICES = 'Digital';


  // Subscription Field IDs
  public static String SUB_FIELDID_GIFTDONOR ='00N20000002nECw';
  public static String SUB_FIELDID_PRODUCT ='00N20000001MwJo';
  public static String SUB_FIELDID_SUBSCRIBER ='00N20000001N46F';
  public static String SUB_FIELDID_WEEKDURATION = '00N20000001Mwtw';
  public static String SUB_FIELDID_WEEKLYPRICE = '00N20000001MyiJ';
  public static String SUB_FIELDID_PAYMENT_TYPE = '00N20000001MzPS';
  public static String SUB_FIELDID_ORDER_METHOD = '00N20000001yfOq';
  public static String SUB_FIELDID_ORDER_WAVE = '00N20000001yfOr';

  // Account Field IDs
  public static String ACC_FIELDID_GIFTDONOR = '00N20000002nECu';

  // Opportunity IDs
  public static String OPP_FIELDID_SALESPERSON = '00N20000001e1yr';
  public static String OPP_FIELDID_NAME = 'opp3';
  public static String OPP_FIELDID_ACCOUNT = 'opp4';
  public static String OPP_FIELDID_ADVERTISER = '00N20000001e1xu';
  public static String OPP_FIELDID_BUNIT = '00N20000001e1y8';
  public static String OPP_FIELDID_CLOSEDATE = 'opp9';
  public static String OPP_FIELDID_STARTDATE = '00N20000001e1yF';
  public static String OPP_FIELDID_ENDDATE = '00N20000001e1yD';
  public static String OPP_FIELDID_STAGE = 'opp11';
  public static String OPP_FIELDID_STAGE_PERC = 'opp12';
  public static String OPP_FIELDID_BUDGET = '00N20000001e1yC';
  public static String OPP_STAGE_CLOSEWON = 'Sales - Closed, Won';

  public static String OPP_CLONE_DEFAULTSTAGE = 'Sales - (90%) Agreed, Awaiting IO';
  public static String OPP_CLONE_DEFAULTSTAGESETTING = 'Opportunity Clone Default Stage';

  // Direct Debit Collection frequencies
  public static String DD_COL_FREQ_ANNUAL = 'Annual';
  public static String DD_COL_FREQ_QUARTERLY = 'Quarterly';
  public static String DD_COL_FREQ_MONTHLY = 'Monthly';
  public static String DD_COL_FREQ_NOTSET = 'NotSet';
  public static String DD_COL_FREQ_IRREGULAR = 'Irregular';

  //Pricing option

  // DD Sub Durations
  public static String SUB_DURATION_13 = '13';
  public static String SUB_DURATION_26 = '26';
  public static String SUB_DURATION_52 = '52';

  // Record Types
  public static String RECTYPE_INDIVSUB = 'Individual Subscriber';
  public static String RECTYPE_DIGISUB = 'Digital Subscriber';
  public static String RECTYPE_DEFAULT = 'Default';
  public static String RECTYPE_ACCOUNT_BUSINESSACCOUNT = 'Business Account';
  public static String RECTYPE_ACCOUNT_SCHOOL = 'School';
  public static String RECTYPE_PERSONACCOUNT_INDIVIDUAL_SUBSCRIBER = 'Individual Subscriber';
  public static String RECTYPE_SUBSCRIPTION_DIGITAL = 'Digital';
  public static String RECTYPE_ACCOUNT_RETAILER ='Retailer Account';
  public static String RECTYPE_SUBSCRIPTION_DEFAULT = 'Default';
  public static String RECTYPE_SUBSCRIPTION_SCHOOLS = 'Schools';
  public static String RECTYPE_SUBSCRIPTION_LOWSTART = 'Low Start';
  public static String RECTYPE_TCODEPRODUCT_OFFER = 'Offer';
  public static String RECTYPE_TCODEPRODUCT_ZOFFER = 'Zuora Offer';

  public static Id indivSubRecTypeId;
  public static Id advAccountRecTypeId;
  public static Id defaultSubRecordTypeId;
  public static Id digiSubRecTypeId;
  public static Id regSubRecTypeId;

  //case id
  public static Id failedPaymentRecTypeId;

  // Payonomy Client Ids
  public static String PAYID_EC_RENEWAL = 'EcommerceIdRenewal';
  public static String PAYID_EC_CPC_RENEWAL = 'EcommerceIdCpcRenew';

  // Failure codes from MPP
  public static String DD_CODE_DECEASED = '2';
  public static String DD_CODE_CANCELLED = '1';

  //MPP Related vars
  public static final String MPP_PARAMETER_SAMGUID = 'SAM_GUID';
  public static final String MPP_PARAMETER_TSNUMBER = 'TSNumber';
  public static final String MPP_RULE_NAME_ID_FIELDS_EXIST = 'mppKeyFieldCheck';
  public static final String MPP_RULE_NAME_ID_FIELDS_INSYNC = 'mppKeyFieldValuesCheck';
  public static final String MPP_RULE_EMAILCHECK = 'deriveEmail';

  public static final String MPP_RULE_ID_FIELDS_EXIST_TSNUMBER_FAIL = '500';
  public static final String MPP_RULE_ID_FIELDS_INSYNC_TSNUMBER_FAIL = '500';
  public static final String MPP_RULE_ID_FIELDS_INSYNC_TSNUMBER_SUCCESS = '100';

  public static final String MPP_RULE_ID_FIELDS_INSYNC_GUID_SUCCESS = '200'; //split this variable into 2 if the target field response is to be different for different messages
  public static final String MPP_RULE_ID_FIELDS_EXIST_NO_GUID_IN_MPP = '600'; //MPP does not have a SAM GUID
  public static final String MPP_RULE_ID_FIELDS_EXIST_NO_GUID_IN_SFDC_MPP = '700'; //MPP and Salesforce do not have a SAM GUID
  public static final String MPP_RULE_ID_FIELDS_INSYNC_GUID_FAIL = '600'; //MPP SAM GUID does not match SAM GUID

  public static final Integer MPP_PAYMENTDAY_15 = 15;
  public static final Integer MPP_PAYMENTDAY_1 = 1;
  public static final Set<Integer> MPP_SET_PAYMENTDAYS_VALID = new Set<Integer>{Constants.MPP_PAYMENTDAY_1, Constants.MPP_PAYMENTDAY_15};


  @TestVisible private static Integer MPP_DAYS_OFFSET;
  public static final String GENERAL_MPP_OFFSET_SETTING = 'MPP DD Offset';

  public static final String MPP_DDCALLOUT_STAGE_3 = 'PaymentSchedule';
  public static final String MPP_DDCALLOUT_STAGE_5_FAILED = 'GetPayment-Failed';
  public static final String MPP_DDCALLOUT_STAGE_4 = 'GetPayment';

  public static final String MPP_PAYMENTMETHOD_CC = 'CreditCard';
  public static final String MPP_PAYMENTMETHOD_DD = 'DirectDebit';

  //SAM Diagnostic Rules
  public static final String SAM_ENT_RULE_ACTIVE_ACCOUNT_LAPSED_ENTITLEMENTS = '800';
  public static final String SAM_ENT_RULE_PENDING_ACCOUNT_LAPSED_ENTITLEMENTS = '700';
  public static final String SAM_ENT_RULE_INACTIVE_ACCOUNT_ACTIVE_ENTITLEMENTS = '600';
  public static final String SAM_ENT_RULE_OK = '200';

  //SFDC Diagnostic Rules
  public static final String SFDC_RULE_NAME_GUID_VALIDATION = 'sfAccountGuidValidation';
  public static final String SFDC_RULE_GUID_VALIDATION_NOGUID = '600';
  public static final String SFDC_RULE_GUID_VALIDATION_NOTMATCHINGGUID = '500';

  //General webservices related vars
  public static final String DIRECTION_INBOUND = 'Inbound';
  public static final String DIRECTION_OUTBOUND = 'Outbound';
  public static final String LOGVAR_REQUESTBODY = 'Request Body';
  public static final String LOGVAR_EXCEPTION = 'Exception';
  public static final String LOG_CHILD_RECORD_SUFFIX = 'Sublog';
  public static final String LOG_PAYMENTSCHEDULE_CALLOUT = 'MPPPaymentScheduleBuildRequestAndCallout';
  public static final String LOG_PAYMENTSCHEDULE_CALLOUT_EXCEPTION = 'MPPPaymentScheduleBuildRequestAndCalloutException';
  public static final String LOG_PAYMENTSCHEDULE_DATAISSUES = 'MPPPaymentScheduleBuildRequestOrUpdateDataIssues';
  public static final String LOG_PAYMENTSCHEDULE_DATAISSUES_EXCEPTION = 'MPPPaymentScheduleBuildRequestOrUpdateDataIssuesException';
  public static final String LOG_PAYMENTSCHEDULE_CALLBACK = 'MPPPaymentScheduleCallbackUpdate';
  public static final String LOG_PAYMENTSCHEDULE_CALLBACK_FAILURES = 'MPPPaymentScheduleRequestsProcessFailed';
  public static final String LOG_USERMANAGE_CALLBACK_FAILURES = 'MPPUserManageRequestsProcessFailed';
  public static final String LOG_UPGRADE_FLOW = 'SubscriptionUpgradeFlow';
  public static final String LOG_UPGRADE_ACCOUNT_UPDATE_ERROR = Constants.LOG_UPGRADE_FLOW+'AccountUpdateFailure';
  public static final String LOG_CREATE_SESSION = 'CreateSession';
  public static final String LOG_USERMANAGE = 'UserManage';
  public static final String LOG_UPDATEACCOUNT = 'UpdateAccount';
  public static final String LOG_COREAPI_OBJECT_EVENT = 'Object Event - {0} - {1}';
  public static final String LOG_COREAPI_UPGRADE = 'Upgrade - {0} - {1} - {2}';
  public static final String LOG_COREAPI_PUT_OFFER = 'Put Offer - {0} - {1} - {2}';
  public static final String LOG_RESET_PASSWORD='Password Reset';
  public static final String LOG_GET_OFFER_CODE_DETAILS='Get Offer Code Details';
  public static final String LOG_GET_ALL_OFFER_CODES='Get All Offer Codes';
  public static final String LOG_GET_NUMBER_OF_EMAILS_IN_SAM='Get Number of Emails in SAM';
  public static final String LOG_GET_PROFILE_FROM_SAM='Get Profile From SAM';
  public static final String LOG_GET_CORE_API_UPSERT_ACCOUNT='CORE API {0} account';
  public static final String LOG_TRIGGER_ZUORA_SUBSCRIPTION_ERROR = 'triggerZuoraSubscriptionError';
  public static final String LOG_TRIGGER_ENDPOINT = 'internal-trigger';
  //SAM Authentication Constants
  public static final String SAM_SUCCESS_CODE = 'SUCCESS';
  public static final String SAM_ACCOUNT_NOT_FOUND = 'ACCOUNT_NOT_FOUND';
  public static final String SAM_CREDENTIALS_ERROR_CODE = 'CREDENTIALS_REJECTED';
  public static final String SAMAUTHREQUESTBODY_STATICRESOURCE_NAME = 'SAMAuthRequestXML';
  public static final String SAMAUTHREQUESTBODY2_STATICRESOURCE_NAME = 'SAMAuthRequestXML_ByGUID';
  public static final String SAMBULKUPDATE_ENV_REQUESTBODY_STATICRESOURCE_NAME = 'SAMBulkUpdateEnvelope';
  public static final String SAMBULKUPDATE_NOT_REQUESTBODY_STATICRESOURCE_NAME = 'SAMBulkUpdateNotification';
  public static final String SAMUPDATE_ADD_ENTITLEMENT_REQUESTBODY_STATICRESOURCE_NAME = 'SAMAddEntitlements';
  public static final String SAMUPDATE_REMOVE_ENTITLEMENT_REQUESTBODY_STATICRESOURCE_NAME = 'SAMRemoveEntitlements';
  public static final String SAM_GET_USER_DETAILS_STATICRESOURCE_NAME = 'SAMGetUserDetails';
  public static final String SAM_PASSWORD_RESET = 'SAMPasswordReset';
  public static final String SAM_PASSWORD_FAILURE = 'SAM Password change email not sent';
  public static final String SAM_ENTITLEMENT_STATUS_ACTIVE = 'ACTIVE';
  public static final String SAM_ACCOUNT_LOCKED = 'ACCOUNT_LOCKED';
  public static final String SAM_UPDATE_SAM = 'UPDATE_SAM';
  public static final String SAM_CREATE_SAM = 'CREATE_SAM';

  //Upgrade process Constants
  public static final String UPGRADE_IN_PROGRESS = 'In Progress';
  public static final String UPGRADE_COMPLETED = 'Complete';
  public static final String TCODE_FILTER_PARAM = 'tcode';
  public static final String ORDER_SUCCESS_STATUS_VALUE = 'Success';
  public static final String ORDER_PENDING_STATUS_VALUE = 'Pending';
  public static final String ORDER_PAYMENT_TYPE_DIRECT_DEBIT_VALUE = 'DirectDebit';
  public static final String ORDER_PAYMENT_TYPE_CREDIT_CARD_VALUE = 'CreditDebitCard';
  public static final String ORDER_TYPE_REFUND = 'Refund';
  public static final String ORDER_TYPE_SALE = 'Sale';
  public static final String ORDER_CURRENCY_GBP = 'GBP';
  public static final String API_BLOCK_ALL = 'Block All';
  public static final String API_BLOCK_DD = 'Block DD';
  public static final String API_BLOCK_CC = 'Block CC';
  public static final String PAGE_FILTER_PARAM = 'fltr';
  public static final String PAGE_FILTER_WEBPACK = 'WEBPACK';
  public static final String PAGE_FILTER_TABLET = 'TABLET';
  public static final String PAGE_FILTER_BLANK = 'BLANK';
  public static final String UPGRADE_PAGE_SETTINGS_LANDING_PAGE_CONFIG = 'landingpage';
  public static final String UPGRADE_PAGE_SETTINGS_TABLET_PAGE_CONFIG = 'tabletupgrade';
  public static final String GENERAL_UPGRADEPAGE_IS_WITHOUT_CHARGE = 'Upgrade Pages Is Without Charge';
  public static final String GENERAL_UPGRAGEPAGE_BATCH_SIZE = 'Upgrade Pages Upgrade Batch Size';
  public static final String GENERAL_UPGRAGEPAGE_API_BLOCK_BEHAVIOUR = 'Upgrade Pages API Block Behaviour';
  public static final String GENERAL_UPGRAGEPAGE_FORGOT_URL = 'Upgrade Pages Forgot URL';

  //Diagnostics Batch Status
  public static final String DIAGNOSTICS_EXTRACT_STATUS_SUCCESS = 'Success';
  public static final String DIAGNOSTICS_EXTRACT_STATUS_ERROR = 'Error';

  public static String ExportThisToExcel;
  public static String Filename;

  //Send Case Email feature
  public static final String CASE_SENDEMAIL_DEFAULTFOLDER = 'Email From Case Templates';
  public static final String CASE_SENDEMAIL_FOLDERSETTING = 'Email From Case Template Folder';

  //Case picklists
  public static final String CASE_STATUS_NEW = 'New';
  public static final String CASE_STATUS_CLOSED = 'Closed';
  public static final String CASE_STATUS_COMPLETED = 'Completed';
  public static final String CASE_STATUS_INPROGRESS = 'In Progress';
  public static final String CASE_STATUS_ESCALATED = 'Escalated';
  public static final String CASE_REASON_IPAD = 'iPad';
  public static final String CASE_REASON_WEBSITE = 'Website';
  public static final String CASE_TYPE_OF_ISSUE_IPAD_TROUBLESHOOTING = 'iPad > Troubleshooting';
  public static final String CASE_TYPE_OF_ISSUE_WEBSITE_GENERALINFORMATION = 'Website > General information';
  public static final String CASE_DIGITAL_DETAILS_IPAD_TROUBLESHOOTING_APPFEATURES = 'iPad > Troubleshooting > App Features';
  public static final String CASE_DIGITAL_DETAILS_MODERATION = 'Moderation';
  public static final String CASE_DIGITAL_DETAILS_2_GALLERIES = 'Galleries';
  public static final String CASE_DIGITAL_DETAILS_2_MODERATION_POLICY = 'Moderation policy';
  public static final String CASE_PRIORITY_NORMAL = 'Normal';
  public static final String CASE_PRIORITY_COMPLAINT = 'Complaint';

  //Webservice defaults
  public static String FAILED_USER_REQUEST_SUBJECT = 'Subscriber Update to [SYSTEM] Failed';
  public static String FAILED_USER_REQUEST_DESCRIPTION = 'Subscriber update to [SYSTEM] failed, please retry setting the following: \n';
  public static String FAILED_USER_REQUEST_STATUS = 'Not Started';
  public static Boolean MPP_CALLOUT_DISABLED = false;

  //Outbound Calling
  public static final String OC_CASES_AVAILABILITY_SETTING = 'OC Case Availability';
  public static Integer OC_BACKDATE_DEFAULT_WHEN_NO_SETTINGS = 7;
  public static String OC_BR1 = 'BR1';
  public static String OC_TL1_CALLDUE = 'TL1 Call Due';
  public static String OC_TL01_TCODE = 'TL01';
  public static String OC_TL2_CALLDUE = 'TL2 Call Due';
  public static String OC_TL02_TCODE = 'TL02';
  public static String OC_T2_CALLDUE = 'T2 Call Due';
  public static String OC_T2_TCODE = 'T2T2';
  public static String OC_T2_28DAYS_CALLDUE = 'T2 Call Due 28 Days';
  public static String OC_T2_CATCH_UP = 'T2 Catch Up';
  public static String OC_BACKDATE_SETTINGS_PREFIX = 'OC Days Back';
  public static String OC_BACKDATE_DEFAULT = Constants.OC_BACKDATE_SETTINGS_PREFIX+' Default';

  public static String OC_CALL_STAGE_T2 = 'T2';
  public static Integer OC_MAX_NUMBER_OF_STAGES = 4;

  public static String OC_BALANCE_REVIEW_RECORD_TYPE_NAME = 'Outbound Calling (Balance Review)';
  public static String OC_BALANCE_REVIEW_VF_PAGE_NAME = 'OutboundCallingBalanceReview';
  public static String OC_BALANCE_REVIEW_FLOW_NAME = 'balancereview';

  public static String OC_SALES_RECORD_TYPE_NAME = 'Outbound Calling (Sales)';
  public static String OC_SALES_VF_PAGE_NAME = 'OutboundCallingSales';

  public static String OC_CREDIT_CARD_EXPIRY_RECORD_TYPE_NAME = 'Outbound Calling (Credit Card Expiry)';
  public static String OC_CREDIT_CARD_EXPIRY_VF_PAGE_NAME = 'OutboundCallingCCExpiry';
  public static final String OC_NONE = 'None';
  public static final String OC_PRIORITY_PRICE = 'price';
  public static final String OC_PRIORITY_DEFAULT = 'default';

  public static final String OC_DEFAULT_OUTCOME = 'Not Started';
  public static final String OC_NO_SALE_OUTCOME = 'No Sale';
  public static final String OC_CHEQUE_SALES = 'Cheque Sales';

  public static final String OC_NO_SALE_REASON_ILLNESS = 'Serious Illness';
  public static final String OC_NO_SALE_REASON_DECEASED = 'Main Reader Deceased';

  public static String OC_RETENTION_RECORD_TYPE_NAME = 'Outbound Calling (Retention)';
  public static String OC_RETENTION_STAGE = 'Retention';
  public static String OC_RETENTION_VF_PAGE_NAME = 'RetentionCalling';
  
  //cancellation types
  public static String SOFT_CANCELLATION = 'Soft Cancel';
  public static String HARD_CANCELLATION = 'Hard Cancel';
  public static String SHORT_SOFT_CANCELLATION = 'soft';
  public static String SHORT_HARD_CANCELLATION = 'hard';
  public static String COMPLETE_CANCELLATION_STATUS = 'Completed';
  public static String REVOKED_CANCELLATION_STATUS = 'Revoked';
  public static String REACTIVATION_SUCCESSFULL = 'Subscriptions Reactivated';

  //MPP Transaction History
  public static final String MPPTRANSACTION_PAYMENTSTATUS_SUCCESS = 'Success';
  public static final String MPPTRANSACTION_PAYMENTSTATUS_REFUND = 'Refund';
  public static final String MPPTRANSACTION_PAYMENT_TYPE_SALE = 'Sale';
  public static final String MPPTRANSACTION_PAYMENT_TYPE_REFUND = 'Refund';
  public static final String MPPTRANSACTION_DDTRANSACTIONTYPE_PAYMENT = 'Payment';
  public static final String MPPTRANSACTION_CARDTYPE_VISA = 'Visa';

  //Voucher Adjustment
  public static final String VOUCHERADJUSTMENT_ACTIVITYTYPE_VOUCHERRETURN = 'Voucher Return';
  public static final String VOUCHERADJUSTMENT_ACTIVITYTYPE_HOLIDAYRETURN = 'Holiday Return';
  public static final String VOUCHERADJUSTMENT_ACTIVITYTYPE_PRENOTIFICATIONHOLIDAY = 'Pre-notification of Holiday'; 
  public static final String VOUCHERADJUSTMENT_ACTIVITYTYPE_GOODWILL = 'Goodwill';
  public static final String VOUCHERADJUSTMENT_ACTIVITYACTION_VOUCHERSRECEIVED = 'Vouchers Received';
  public static final String VOUCHERADJUSTMENT_ACTIVITYACTION_VOUCHERSSENT ='Vouchers Sent';
  public static final String VOUCHERADJUSTMENT_REFUND_STATUS_PENDING = 'Pending';
  public static final String VOUCHERADJUSTMENT_REFUND_STATUS_PROCESSED = 'Processed';
  public static final String VOUCHERADJUSTMENT_REFUND_STATUS_PARTIALLY_PROCESSED = 'Partially Processed';
  public static final String VOUCHERADJUSTMENT_REFUND_STATUS_WAITING_FOR_APPROVAL = 'Waiting For Approval';
  public static final String VOUCHERADJUSTMENT_REFUND_METHOD_CARD = 'Refunded to Card';
  public static final String VOUCHERADJUSTMENT_REFUND_METHOD_MANUAL_CHEQUE = 'Manual created cheque';
  public static final String VOUCHERADJUSTMENT_REFUND_METHOD_SYSTEM_CHEQUE = 'System created cheque';
  public static final String VOUCHERADJUSTMENT_APPROVERS_GROUP_DEV_NAME = 'Voucher_Activity_Approvers';
  public static final String VOUCHERADJUSTMENT_APPROVERS_GROUP_NAME = 'Voucher Activity Approvers';
  public static final String HOLIDAY_VOUCHER_REFUND_CHEQUE_REPORT_NAME = 'Holiday_Voucher_Refund_Cheques';
  public static final String MPP_REFUND_EMAIL_TEMPLATE_NAME = 'MPP_Refund_Confirmation';
  public static final String VOUCHER_ADJUSTMENT_TASK_SUBJECT = 'Email: Delayed refund';
  public static final String VOUCHER_ADJUSTMENT_TASK_STATUS = 'Not Started';
  public static final String VOUCHER_ADJUSTMENT_TASK_PRIORITY = 'Normal';

  //Cheque
  public static final String CHEQUE_BANKINGSTATUS_BANKED = 'Banked';
  public static final String CHEQUE_BANKINGSTATUS_ISSUED = 'Issued';
  public static final String CHEQUE_TYPE_SUBPAYMENT = 'Sub Payment';
  public static final String CHEQUE_TYPE_REFUND = 'Refund';
  public static final String CHEQUE_REFUND_REASON_HOLIDAY_REFUND = 'Holiday Refund';
  public static final String VOUCHER_REFUND_CHEQUE_RECORD_TYPE_NAME = 'Voucher Refund Cheque';
  public static final String VOUCHER_REFUND_CHEQUE_BATCH_RECORD_TYPE_NAME = 'Voucher Refund Cheque Batch';

  //Case
  public static final String CASE_FAILED_PAYMENT_RT_NAME = 'Failed Payment';
  public static final String CASE_QUEUE_RETENTION_DD_NAME = 'Retention - Direct Debit';
  public static final String CASE_QUEUE_FINANCIAL_PROC_DD = 'Financial Processing - Direct Debit';
  public static final String CASE_ORIGIN_ZUORA_DD = 'Zuora - Direct Debit';
  public static final String CASE_ORIGIN_LETTER = 'Letter';
  public static final String CASE_REASON_PAYMENT_ISSUE = 'Payment Issue';
  public static final String CASE_REASON_VOUCHER_ENQUIRY = 'Voucher Enquiry';
  public static final String CASE_TYPE_PROBLEM = 'Problem';
  public static final String CASE_TYPEOFISSUE_FAILED_DDREC_PAYMENT = 'Failed DD Recurring Payment';
  public static final String CASE_SUBJECT_FAILED_DDREC = 'Failed DD Recurring - ARUDD ref';
  public static final String CASE_SUBJECT_FAILED_DD_DDICA = 'DD Indemnity Claim - DDICA';
  public static final String CASE_SUBJECT_DELAYED_REFUND = 'Delayed Refund';
  public static final String CASE_PAYMENTSTATUS_FAILED_DDPAYMENT = 'Failed DD Payment';
  public static final String CASE_PAYMENTSTATUS_IDEMNITY_DDICA = 'Direct Debit Indemnity Claim';
  public static final String CASE_GATEWAYNAME_GOCARDLESS = 'GoCardless';
  public static final String CASE_REASONCODE_ARUDD = 'ARUDD';
  public static final String CASE_REASONCODE_AUDDIS = 'AUDDIS';
  public static final String CASE_REASONCODE_ADDACS = 'ADDACS';
  public static final String CASE_REASONCODE_DDICA = 'DDICA';
  public static final String CASE_COMMENT_OBJECT_NAME = 'CaseComment';
  public static final String CASE_COMMENT_ORDERBY_DEFAULT_FIELD_NAME = 'CreatedDate';
  public static final String CASE_AUTORESPONSE_EMAIL_ADDRESS_SETTING = 'CaseAutoResponseEmailAddress';
  public static final String CASE_SEND_EMAIL_URL_SETTING = 'CaseSendEmailUrl';
  public static final String CASE_EMAIL_REPLY_URL_SETTING = 'CaseEmailReplyUrl';
  public static final String CASE_EMAIL_GOTOLIST_URL_SETTING = 'CaseEmailGoToListUrl';
  public static final String CASE_EMAIL_FORWARD_URL_SETTING = 'CaseEmailForwardUrl';

  //Case outbound calling
  public static final String CASE_OUTCOME_AUTO_COMPLETED = 'Auto Completed';
  public static final String CASE_OUTBOUND_CALL_OUTCOME = 'Not Started';
  public static final String CASE_OUTCOME_SALE = 'Sale';
  public static final String CASE_OUTCOME_WITHDRAWN = 'Withdrawn';
  public static final String CASE_OUTCOME_DECLINED = 'Declined';
  public static final String CASE_OUTBOUND_CALL_REASON = 'Credit Card Expiry';
  public static final String CASE_OUTBOUND_CALL_ORGIN = 'Internal Records';
  public static final String CASE_OUTCOME_BUSY = 'Busy';
  public static final String CASE_OUTCOME_NOANSWER = 'No Answer';
  public static final String CASE_OUTCOME_ANSWERPHONE = 'Answerphone';
  public static final String CASE_OUTCOME_WEBSITE_PLUS = 'Website+ Sale';
  public static final String CASE_OUTCOME_TABLET_PLUS = 'Tablet+ Sale';
  public static final String CASE_OUTCOME_DECEASED = 'Deceased';
  public static final String CASE_OUTCOME_RESCHEDULE = 'Reschedule';

  public static final String CASE_STATUS_NOT_STARTED = 'Not Started';

  public static final String CASE_RECORDTYPE_DIGITALSERVICES = 'Digital Services';
  public static final String CASE_RECORDTYPE_GENERALENQUIRY = 'General Enquiry';

  //User Departments
  public static final String USER_DEPARTMENT_DIGITALSERVICES = 'Digital Services';
  public static final String USER_DEPARTMENT_SALESANDCUSTOMEREXPERIENCE = 'Sales and Customer Experience';

  //other statuses
  public static final String CANCELLATION_STATUS_REMOVED = 'Removed';

  //Pricing Option Product Type
  public static final String PRICING_PREMIUM_TYPE = 'premium';
  public static final String PRICING_WEBPACK_TYPE = 'webpack';
  public static final String PRICING_DIGITAL_TYPE = 'digital';
  public static final String PRICING_FLOW_TYPE_OPENOFFER = 'openofferflow';
  public static final Map<String, String> MAP_PRODUCTS_PRICINGOPTION_TO_ACCOUNT = new Map<String, String>{
                                                                                    Constants.PRICING_WEBPACK_TYPE => Constants.DIGITAL_PRODUCT_WEBPACK,
                                                                                    Constants.PRICING_DIGITAL_TYPE => Constants.DIGITAL_PRODUCT_ALLDEVICES
  };

  //Decommission SAM Account
  public static final String DECOM_FIRSTNAME = 'Deleted';
  public static final String DECOM_LASTNAME = 'Account';
  public static final String DECOM_EMAIL = '.deleted.' + System.Now().format('yyyy-MM-dd');
  public static final String DECOM_STREET = '111  Buckingham Palace Road';
  public static final String DECOM_CITY = 'London';
  public static final String DECOM_POSTCODE = 'SW1W 0DT';
  public static final String DECOM_DELETED = 'Deleted';
  //Country codes
  public static final String COUNTRY_CODE_GB = 'GB';

  //postcodeLookup
  public static final String POSTCODE_LOOKUP_CUSTOMSETTINGS = 'Post Code Validation Enabled';

  public static final String GENERAL_DIGITAL_YEARLY_PRICINGOPTION = 'Digital Yearly Pricing Option';
  public static final String GENERAL_DIGITAL_MONTHLY_PRICINGOPTION = 'Digital Monthly Pricing Option';

  //TCode
  public static final String TCODE_TYPE_PROMOTIONAL = 'Promotional';
  public static final String TCODE_TYPE_LOWSTART = 'Low Start';
  public static final String TCODE_TYPE_OPENOFFER = 'Open Offer';
  public static final String TCODE_TYPE_STAFFOFFER = 'Staff Offer';
  public static final String TCODE_TYPE_MGM = 'MGM';
  public static final String TCODE_TYPE_RENEWAL = 'Renewal';

  public static final String TCODE_REPORTTYPE_DIGITALONLY = 'Digital Only';
  public static final String TCODE_DEFAULT_RENEWAL_RECORD_NAME = 'RNWL';
  public static final String GENERAL_RENEWAL_TCODE_NAME = 'Renewal TCode Name';

  //Pricing Options
  public static final String PRICINGOPTION_FLOWTYPE_POC = 'pocflow';
  public static final String PRICINGOPTION_FLOWTYPE_SFDC = 'sfdcflow';

  //Products - flows
  public static final String PRODUCT_PREMIUM = 'Premium';
  public static final String PRODUCT_DIGITAL = 'Digital';
  public static final String PRODUCT_PRINT =  'Print';

  public static final String GENERAL_DEFAULT_PRODUCT_ID = 'Default Product Id';
  public static final String DIGITAL_DEFAULT_PRODUCT_ID = 'Default Digital Product Id';
  public static final String WEBPACK_DEFAULT_PRODUCT_ID = 'Default Webpack Product Id';

  public static final String OFFER_PROMOTION = 'Promotion';
  public static final String OFFER_LOWSTART = 'LowStart';
  public static final String OFFER_OPENOFFER = 'OpenOffer';
  public static final String OFFER_STAFF = 'Staff';
  public static final String OFFER_MGM = 'MGM';
  public static final String OFFER_ADHOCPRICE = 'AdHocPrice';
  public static final String OFFER_POC = 'POC';
  public static final String OFFER_DIRECTMAIL = 'DirectMail';

  public static final String ORDER_METHOD_COUPON = 'Coupon';
  public static final String KEY_CONTINUOUS = 'continuous';
  public static final String KEY_ONEOFF= 'weeks';

  public static final String GENERAL_ADHOCPRICE_TCODE = 'AdHocPrice TCode';
  public static final String TCODE_ADHOCPRICE_DEFAULT = '988T';

  //Delivery
  public static final String DELIVERYTYPE_HND = 'HND';
  public static final String DELIVERYTYPE_OTC = 'OTC';
  public static final String DELIVERYTYPE_BOTH = 'OTC & HND';

  //Selected offer options
  public static final String OFFEROPTION_EMAIL = 'Email';
  public static final String OFFEROPTION_COUPON = 'Coupon';
  public static final String OFFEROPTION_BOTH = 'Both';

  //Subscription Type support
  public static final String SUBSCRIPTIONTYPE_13WEEKS = '13weeks';
  public static final String SUBSCRIPTIONTYPE_26WEEKS = '26weeks';
  public static final String SUBSCRIPTIONTYPE_52WEEKS = '52weeks';
  public static final String SUBSCRIPTIONTYPE_MONTHLY = 'monthly';
  public static final String SUBSCRIPTIONTYPE_YEARLY = 'yearly';
  public static final String SUBSCRIPTIONTYPE_CONTINUOUS = 'continuous';
  public static final String SUBSCRIPTIONTYPE_52CONTINUOUS = '52continuous';
  public static final String SUBSCRIPTIONTYPE_26CONTINUOUS = '26continuous';
  public static final String SUBSCRIPTIONTYPE_13CONTINUOUS = '13continuous';

  public static final Map<String, Integer> MAP_SUBSCRIPTIONTYPE_LENGTH = new Map<String, Integer>{    Constants.SUBSCRIPTIONTYPE_13WEEKS => 13,
                                                                                                      Constants.SUBSCRIPTIONTYPE_26WEEKS => 26,
                                                                                                      Constants.SUBSCRIPTIONTYPE_52WEEKS => 52,
                                                                  Constants.SUBSCRIPTIONTYPE_52CONTINUOUS => 52,
                                                                  Constants.SUBSCRIPTIONTYPE_26CONTINUOUS => 26,
                                                                  Constants.SUBSCRIPTIONTYPE_13CONTINUOUS => 13
  };
  public static final Integer SUBSCRIPTION_DEFAULT_LENGTH = 52;
  public static final List<String> LIST_SUPPORTED_SUBSCRIPTIONTYPES = new List<String>{   SUBSCRIPTIONTYPE_13WEEKS,
                                                SUBSCRIPTIONTYPE_26WEEKS,
                                                SUBSCRIPTIONTYPE_52WEEKS,
                                                SUBSCRIPTIONTYPE_13CONTINUOUS,
                                                SUBSCRIPTIONTYPE_26CONTINUOUS,
                                                SUBSCRIPTIONTYPE_52CONTINUOUS,
                                                SUBSCRIPTIONTYPE_MONTHLY,
                                                SUBSCRIPTIONTYPE_YEARLY
  };

  public static final Decimal DEFAULT_13WEEK_PRICE = 30.00;

  public static final String SAM_CREDITDEBITCARD = 'creditdebitcard';
  public static final String SAM_DIRECTDEBIT = 'directdebit';

  public static final String GENERAL_WEBSERVICE_ERROR_NOTIFICATIONS = 'Webservice Error Notifications';
  public static final Boolean WEBSERVICE_ERROR_NOTIFICATIONS_DEFAULT = false;
  public static final String GENERAL_WEBSERVICE_ERROR_EMAIL = 'Webservice Error Email';

  //renewal stages
  public static final String MPP_MANUALRENEWAL_STAGE = 'ManualRenewal';
  //voucher activity
  public static final String VOUCHER_ADJUSTMENTTYPE_FULLPACK = 'Voucher Resend - Full Pack';
  public static final String VOUCHER_ADJUSTMENTTYPE_PARTPACK = 'Voucher Resend - Part Pack';
  //default email address
  public static final String DEFAULT_EMAIL_ADDRESS = 'noemail@telegraph.co.uk';

  //default low start weeks period - 13 weeks.
  public static final Integer LOW_START_PERIOD = 13;
  public static final Integer WEEKS_IN_QUARTER = 13;

  public static final String MPP_IRREGULAR_PAYMENT_SCHEDULE_FIELD = 'MPP_Irregular_Payment_Schedule__c';

  //MPP Letter Extract
  public static final String PDD_SETTING_CUSTOM_PDD_DATE = 'Custom PDD Date';
  public static final String PDD_SETTING_CUSTOM_DDCCA_DATE = 'Custom MPP DDCCA Date';

  //add change email functionality
  public static final String EMAILCHANGE_SAMPASSPENDING = 'PASSWORD_CHANGE_PENDING';


  public static final String USERNAME_POC_GUEST = 'TMG-POCSignup GuestUser';
  public static final String GENERAL_MPP_LETTEREXTRACT_TARGETEMAIL = 'MPP Letter Extract Target Emails';
  public static final String GENERAL_MPP_LETTEREXTRACT_ADMINEMAIL = 'MPP Letter Extract Admin Email';
  public static final String GENERAL_MPP_LETTEREXTRACT_REPLYTOEMAIL = 'MPP Letter Extract ReplyTo Email';
  public static final String GENERAL_MPP_LETTEREXTRACT_BATCHSIZE = 'MPP Letter Extract Batch Size';

  public static final String MPP_LETTEREXTRACT_TARGETEMAIL_VALUE = 'cscfulfilment@telegraph.co.uk,lloyd.homer@telegraph.co.uk,dominic.ellis@telegraph.co.uk';
  public static final String MPP_LETTEREXTRACT_ADMINEMAIL_VALUE = 'subscription-dev@telegraph.co.uk';
  public static final String MPP_LETTEREXTRACT_REPLYTOEMAIL = 'subscription-dev@telegraph.co.uk';
  public static final Integer MPP_LETTEREXTRACT_BATCHSIZE_VALUE = 20;

  public static final String CONST_DSOSOrderTakenCompany = 'TMG';
  public static final String CONST_DSOS ='Online Subs';

  public static final String MPP_FUNCTION_ADDPAYMENTSCHEDULE = 'AddPaymentSchedule';
  public static final String MPP_FUNCTION_ADDSUBSCRIPTION = 'AddSubscription';
  public static final String MPP_FUNCTION_PROCESSPAYMENT = 'ProcessPayment';

  public static final String GENERAL_SAM_VAR_PAYMENT_SCHEDULE = 'SAM Variable Payment Schedule';
  @TestVisible private static String SAM_VARIABLE_PAYMENT_SCHEDULE;

  public static final Map<String, String> MAP_PAYMENTTYPE_SUBSCRIPTION_TO_MPP = new Map<String, String>{Constants.SUB_PMETHOD_CC => Constants.MPP_PAYMENTMETHOD_CC,
                          Constants.SUB_PMETHOD_DD => Constants.MPP_PAYMENTMETHOD_DD
  };

  // Gavin Palmer 27/04/2016 added constants used in the NotifyZuoraController
  public static final String NOTIFY_ZUORA_UPLOADED = 'uploaded';
  public static final String NOTIFY_ZUORA_OBJECT_TYPE = 'SubscriptionPricingSegmentUpload';
  public static final String SUBSCRIPTION_PLAN_UPLOAD_STATUS_NOTIFIED = 'Notified';
  public static final String SUBSCRIPTION_PLAN_UPLOAD_STATUS_DRAFT = 'Draft';
  public static final String SUBSCRIPTION_PLAN_UPLOAD_STATUS_IN_PROGRESS = 'In Progress';

  public static final String AGENT_TMG = 'TMG';

  public static final String PRODUCT_PRICE_AQUISITION = 'Acquisition';
  public static final String PRODUCT_PRICE_RENEWAL = 'Renewal';

  public static final String ENABLE_PRODUCT_PRICE_VALIDATION = 'Enable Product Price Validation';

  public static final String SYSTEM_USER_NAME_SETTING = 'Balance Review User Name';
  public static final String SYSTEM_USER_NAME = 'System';

  //Price Plan
  public static final String PRICE_PLAN_RECORDTYPE_PRINT = 'Print';
  public static final String PRICE_PLAN_RECORDTYPE_DIGITAL = 'Digital';
  //Newsletter Configuration
  public static final String NEWSLETTER_CATEGORY_RECORD_TYPE_NAME = 'Category';
  public static final String NEWSLETTER_FREQUENCY_RECORD_TYPE_NAME = 'Frequency';
  //Visualforce Pages Names
  public static final String PAGE_ACCOUNT_MANAGE_PAYMENT_METHOD = 'Account_Manage_Payment_Methods';

  //Voucher refund threshold amount
  public static final Double VOUCHER_REFUND_THRESHOLD_CUSTOM_SETTING_AMOUNT = 100;

  //MyNewsletters
  public static final String MY_NEWSLETTER_ENDPOINT  = 'MyNewslettersEndpoint';
  public static final String IDENTITY_TOKEN_ENDPOINT = 'IdentityTokenEndpoint';

  //Organization-Wide Email Addresses
  public static final String ORG_WIDE_NAME_CUSTOMER_SERVICE  = 'Customer Service';
  //Offers
  public static final String OFFER_FREQUENCY_MONTH = 'Month';
  public static final String OFFER_FREQUENCY_MONTHLY = 'Monthly';
  public static final String OFFER_FREQUENCY_ANNUAL = 'Annual';
  public static final String OFFER_FREQUENCY_ANNUALLY = 'Annually';
  public static final String OFFER_FREQUENCY_DAILY = 'Daily';

  //Offer incentive assignment setting
  public static final String GENERAL_AUTO_ASSIGN_INCENTIVE_FOR_DIGITAL = 'Assign Incentives for New Zuora Sub';

  public static final String PROFILES_FOR_MARKETING_PREFERENCES = 'ProfilesForMarketingPreferences';

  public static final String INCENTIVE_REASON_ACQUISITION = 'Acquisition Incentive';

  //home delivery voucher
  public static final String HOMEDELIVERYVOUCHER_DELIVERMYNEWSPAPER_RECORD_TYPE_NAME = 'Deliver My Newspaper';
  public static final String HOMEDELIVERYVOUCHER_HOMEDELIVERYSERVICE_RECORD_TYPE_NAME = 'Home Delivery Service';




  // DD WINBACK
  public static final String OC_DD_WINBACK_RECORD_TYPE_NAME = 'Outbound Calling (DD Winback)'; 
  public static final String OC_DD_WINBACK_VF_PAGE_NAME     = 'OutboundCallingDDWinback'; 
  public static final String OC_DD_OUTCOME_NATC   = 'NATC';
  public static final String OC_DD_OTHER_NATC     = 'Other';


  //Outbound Calling DDCX 
  public static final String OC_DDCX_CASE_RECORD_TYPE_NAME = 'Outbound Calling (DD Cancellation)';
  public static final String OC_DDCX_VF_PAGE_NAME          = 'OutboundCallingDDCancellation';
  public static final String OC_DDCX_URL_PARAM             = 'isOCDDCX';

  //Page message severities
  public static ApexPages.Severity FATAL        = ApexPages.Severity.FATAL; 
  public static ApexPages.Severity INFO         = ApexPages.Severity.INFO; 
  public static ApexPages.Severity ERROR        = ApexPages.Severity.ERROR; 
  public static ApexPages.Severity WARNING      = ApexPages.Severity.WARNING; 
  public static ApexPages.Severity CONFIRM      = ApexPages.Severity.CONFIRM; 

  //oapSubscriptionTMG url parameters
  public static final String PARAM_AGENCYID         = 'agencyid'; 
  public static final String PARAM_AGENT_USERID     = 'agentuserid'; 
  public static final String PARAM_ORDER_METHOD     = 'orderMethod'; 
  public static final String PARAM_PRODUCTID        = 'productId'; 
  public static final String PARAM_SELECTED_OFFER   = 'selectedOffer'; 
  public static final String PARAM_SELECTED_PRODUCT = 'selectedProduct'; 


  //Charter
  public static final String READER_RELATIONS_RECORD_TYPE_NAME ='Reader Relations';

  /***************************************************************************************
  Developer - Wiktor Czykin
  Date - 09/07/2015
  Version - 1.0
  Function - set MPP Offset constant based on custom settings
  #############Change Log#############
  Modified by     Version     Change Date
  ****************************************************************************************/
  public static Integer getMppDDOffset(){
    if(Constants.MPP_DAYS_OFFSET == null){
      General__c offset = General__c.getInstance(Constants.GENERAL_MPP_OFFSET_SETTING);
      if(offset != null && String.isNotBlank(offset.Value__c) && offset.Value__c.isNumeric()){
        Constants.MPP_DAYS_OFFSET = Integer.valueOf(offset.Value__c);
      }else{
        Constants.MPP_DAYS_OFFSET = 2;
      }
    }
    return Constants.MPP_DAYS_OFFSET;
  }

  /***************************************************************************************
  Developer - Wiktor Czykin
  Date - 09/07/2015
  Version - 1.0
  Function - set MPP Offset constant based on custom settings
  #############Change Log#############
  Modified by     Version     Change Date
  ****************************************************************************************/
  public static Integer getMppDDOffsetNegative(){
    return -Constants.getMppDDOffset();
  }

  // Record Type Constants
  public static Id IndivSubscriberRecordType() {
    if (indivSubRecTypeId == null) {
      indivSubRecTypeId = RecordTypeUtility.getRecordTypeId(Account.SObjectType, RECTYPE_INDIVSUB, Account.class.getName());
    }
    return indivSubRecTypeId;
  }

 // Record Type Constants
  public static Id RegSubscriberRecordType() {
    if (regSubRecTypeId == null) {
      regSubRecTypeId = RecordTypeUtility.getRecordTypeId(Account.SObjectType, ACCOUNT_REGISTRANT_RECORD_TYPE_NAME, Account.class.getName());
    }
    return regSubRecTypeId;
  }

  // Returns the DIgital RecordTypeId
  public static Id DigitalSubscriberRecordType() {
    if (digiSubRecTypeId == null) {
      digiSubRecTypeId = RecordTypeUtility.getRecordTypeId(Account.SObjectType, RECTYPE_DIGISUB, Account.class.getName());
    }
    return digiSubRecTypeId;
  }

  public static Id DefaultSubRecordType() {
    if (defaultSubRecordTypeId == null) {
      defaultSubRecordTypeId = RecordTypeUtility.getRecordTypeId(Subscription__c.SObjectType, RECTYPE_DEFAULT, Subscription__c.class.getName());
    }
    return defaultSubRecordTypeId;
  }

  /***************************************************************************************
  Developer - Michal Kwika (Accenture)
  Date - 28/09/2015
  Version - 1.0
  Function - get RT Id from Case
  #############Change Log#############
  Modified by     Version     Change Date
  ****************************************************************************************/
  public static Id getFailedPaymentRT(){
    if (failedPaymentRecTypeId == null) {
      failedPaymentRecTypeId = RecordTypeUtility.getRecordTypeId(Case.SObjectType, CASE_FAILED_PAYMENT_RT_NAME, Case.class.getName());
    }
    return failedPaymentRecTypeId;
  }

  /***************************************************************************************
  Developer - Vishant Shah
  Date - 09/02/2017
  Version - 1.0
  Function - Methods used to get profiles
  #############Change Log#############
  Modified by     Version     Change Date
  ****************************************************************************************/
  public static Map<String, Id> profileNameId = new Map<String, Id>();

  public static Id getTMGStandardUserProfileId() {
    return getProfileIdByName(PROFILE_TMG_STANDARD_USER);
  }

  public static Id getTMGSystemProfileId() {
    return getProfileIdByName(PROFILE_TMGSYSTEM);
  }

  public static Id getTMGWebApiProfileId() {
    return getProfileIdByName(PROFILE_WEB_API);
  }

  public static Id getSystemAdministratorProfileId() {
    return getProfileIdByName(PROFILE_SYSTEMADMINISTRATOR);
  }

  public static Id getProfileIdByName(String profileName){
    return getProfiles().get(profileName);
  }

  public static Map<String, Id> getProfiles(){
    if (profileNameId == null){
      profileNameId = new Map<String, Id>();
    }

    if (profileNameId.isEmpty() && profileNameId.size() == 0){
      for (Profile pr : [SELECT Id, Name FROM Profile]){
        profileNameId.put(pr.Name, pr.Id);
      }
    }
    return profileNameId;
  }

  /**** Function - Methods used to get profiles END ****/
}
