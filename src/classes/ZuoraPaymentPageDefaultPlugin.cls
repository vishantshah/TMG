/**
* Author:       Sally ElGhoul (Tquila)
* Date:         09/06/2015
* Description:  this is the plugin to extend the default plugin of payment page component of Zuora
*
* ******************* Change Log *******************
* Modified by       Change Date
* Michal Kwika      20/07/2015
* Michal Kwika      03/08/2015
* Michal Kwika      19/08/2015
* Michal Kwika      24/08/2015
* Lynette Lim       03/03/2016   Modified zuora payment page to populate 1 line or 2 lines of street address and city accordingly
* Lynette Lim       07/03/2016   Replaced all carriage returns in Address Line 2 with space so that separates address lines do not stick together in Zuora Payment Page
**/
global class ZuoraPaymentPageDefaultPlugin implements zqu.PaymentPageController.IHostedPageLitePlugin {

    /***************************************************************************************
    Developer   Sally ElGhoul (Tquila)
    Date        9/06/2015
    Function    this function will be called when the user press go to the payment page to fill the default values
    ******************* Change Log *******************
    Modified by         Version     Change Date
    Michal Kwika        1.1         20/07/2015
    Michal Kwika        1.2         03/08/2015
    Michal Kwika        1.3         19/08/2015
    Michal Kwika        1.4         24/08/2015
    Lynette Lim         1.5         03/03/2016   Modified zuora payment page to populate 1 line or 2 lines of street address and city accordingly
    ****************************************************************************************/
    global Map<String,String> getAdditionalParameters(String paymentMethodType) {
        Map<String,String> defaultValues = new Map<String,String>();

        // Reset the values
        String sId = '';
        String typeOfObject = '';
        String zId = '';

        //temporary apiNames of quote and billing account
        String zquoteApiName = zqu__Quote__c.class.getName();
        String billingAccountApiName = Zuora__CustomerAccount__c.class.getName();

        if (ApexPages.currentPage().getParameters().containsKey('id')) {
            sId = System.currentPageReference().getParameters().get('id');
            typeOfObject = getNameOfObjectBasedOnId(sId);
            zId = System.currentPageReference().getParameters().get('zId');
        }

        if (String.isNotEmpty(typeOfObject)) {
            if (typeOfObject.equalsIgnoreCase(billingAccountApiName)) {

                defaultValues.put('field_accountId', zId);
                // Set the default values for payment method type credit card
                if (paymentMethodType == zqu.PaymentPageController.PAYMENT_METHOD_TYPE_CREDIT_CARD) {

                    defaultValues.put(Constants.CREDIT_CARD_COUNTRY_FIELD_NAME_PAYMENT_PAGE_ZUORA, Constants.UNITED_KINGDOM_COUNTRY_THREE_CODE_VALUE);
                    if (sId != null) {
                        List<Zuora__CustomerAccount__c> lZBillAccs = [select Name, Zuora__Zuora_Id__c, 
                                                                        Zuora__Account__r.FirstName, 
                                                                        Zuora__Account__r.LastName, 
                                                                        Zuora__Account__r.PersonMailingStreet, 
                                                                        Zuora__Account__r.PersonMailingCity, 
                                                                        Zuora__Account__r.PersonMailingPostalCode, 
                                                                        Zuora__Account__r.PersonMailingCountry, 
                                                                        Zuora__Account__r.PersonMailingState
                                                                        from Zuora__CustomerAccount__c
                                                                        where Id = :sId];

                        if (String.isNotEmpty(lZBillAccs[0].Zuora__Account__r.PersonMailingStreet) && lZBillAccs[0].Zuora__Account__r.PersonMailingStreet.contains('\n')) {
                            defaultValues.put(Constants.CREDIT_CARD_ADDRESS1_FIELD_NAME_PAYMENT_PAGE_ZUORA, lZBillAccs[0].Zuora__Account__r.PersonMailingStreet.split('\n',2)[0]);
                            
                            if (String.isNotEmpty(lZBillAccs[0].Zuora__Account__r.PersonMailingStreet.split('\n',2)[1]) && lZBillAccs[0].Zuora__Account__r.PersonMailingStreet.split('\n',2)[1].contains('\n')) {
                                defaultValues.put(Constants.CREDIT_CARD_ADDRESS2_FIELD_NAME_PAYMENT_PAGE_ZUORA, lZBillAccs[0].Zuora__Account__r.PersonMailingStreet.split('\n',2)[1].replace('\n', ' '));
                            } else {
                                defaultValues.put(Constants.CREDIT_CARD_ADDRESS2_FIELD_NAME_PAYMENT_PAGE_ZUORA, lZBillAccs[0].Zuora__Account__r.PersonMailingStreet.split('\n',2)[1]);
                            }
                        } else {
                            defaultValues.put(Constants.CREDIT_CARD_ADDRESS1_FIELD_NAME_PAYMENT_PAGE_ZUORA, lZBillAccs[0].Zuora__Account__r.PersonMailingStreet);
                        }

                        defaultValues.put(Constants.CREDIT_CARD_CITY_FIELD_NAME_PAYMENT_PAGE_ZUORA, lZBillAccs[0].Zuora__Account__r.PersonMailingCity);

                        defaultValues.put(Constants.CREDIT_CARD_POSTAL_CODE_FIELD_NAME_PAYMENT_PAGE_ZUORA, lZBillAccs[0].Zuora__Account__r.PersonMailingPostalCode );

                        defaultValues.put(Constants.CREDIT_CARD_COUNTRY_FIELD_NAME_PAYMENT_PAGE_ZUORA, getThreeLettersCountryCode(lZBillAccs[0].Zuora__Account__r.PersonMailingCountry));
                        defaultValues.put(Constants.CREDIT_CARD_STATE_FIELD_NAME_PAYMENT_PAGE_ZUORA, getStateNameForNorthAmerica(lZBillAccs[0].Zuora__Account__r.PersonMailingCountry, lZBillAccs[0].Zuora__Account__r.PersonMailingState));
                    }

                } else if (paymentMethodType == zqu.PaymentPageController.PAYMENT_METHOD_TYPE_BANK_TRANSFER) { //set the default value field in case of bank transfer (direct debit)
                    if (sId != null) {
                        List<Zuora__CustomerAccount__c> lZBillAccs = [select Name, 
                                                                        Zuora__Zuora_Id__c, 
                                                                        Zuora__Account__r.FirstName, 
                                                                        Zuora__Account__r.LastName, 
                                                                        Zuora__Account__r.PersonMailingStreet, 
                                                                        Zuora__Account__r.PersonMailingPostalCode, 
                                                                        Zuora__Account__r.PersonMailingCountry
                                                                        from Zuora__CustomerAccount__c
                                                                        where Id = :sId];

                        defaultValues.put(Constants.DIRECT_DEBIT_FIRST_NAME_FIELD_NAME_PAYMENT_PAGE_ZUORA, lZBillAccs[0].Zuora__Account__r.FirstName);

                        defaultValues.put(Constants.DIRECT_DEBIT_LAST_NAME_FIELD_NAME_PAYMENT_PAGE_ZUORA, lZBillAccs[0].Zuora__Account__r.LastName);
                    }
                }
            } else {
                // Set the default values for payment method type credit card
                if (paymentMethodType == zqu.PaymentPageController.PAYMENT_METHOD_TYPE_CREDIT_CARD) {
                    //default the country with United Kingdom
                    defaultValues.put(Constants.CREDIT_CARD_COUNTRY_FIELD_NAME_PAYMENT_PAGE_ZUORA, Constants.UNITED_KINGDOM_COUNTRY_THREE_CODE_VALUE);

                    if (ApexPages.currentPage().getParameters().containsKey('id')) {
                        List<zqu__Quote__c> lstQuote = [select zqu__BillToContact__r.MailingStreet, 
                                                        zqu__BillToContact__r.MailingCity,
                                                        zqu__BillToContact__r.MailingPostalCode, 
                                                        zqu__BillToContact__r.MailingCountry, 
                                                        zqu__BillToContact__r.MailingState
                                                        from zqu__Quote__c 
                                                        where id = :ApexPages.currentPage().getParameters().get('id') ];

                        if (String.isNotEmpty(lstQuote[0].zqu__BillToContact__r.MailingStreet) && lstQuote[0].zqu__BillToContact__r.MailingStreet.contains('\n')) {
                            defaultValues.put(Constants.CREDIT_CARD_ADDRESS1_FIELD_NAME_PAYMENT_PAGE_ZUORA, lstQuote[0].zqu__BillToContact__r.MailingStreet.split('\n',2)[0]);

                            if (String.isNotEmpty(lstQuote[0].zqu__BillToContact__r.MailingStreet.split('\n',2)[1]) && lstQuote[0].zqu__BillToContact__r.MailingStreet.split('\n',2)[1].contains('\n')) {
                                defaultValues.put(Constants.CREDIT_CARD_ADDRESS2_FIELD_NAME_PAYMENT_PAGE_ZUORA, lstQuote[0].zqu__BillToContact__r.MailingStreet.split('\n',2)[1].replace('\n', ' '));
                            } else {
                                defaultValues.put(Constants.CREDIT_CARD_ADDRESS2_FIELD_NAME_PAYMENT_PAGE_ZUORA, lstQuote[0].zqu__BillToContact__r.MailingStreet.split('\n',2)[1]);
                            }
                        } else {
                            defaultValues.put(Constants.CREDIT_CARD_ADDRESS1_FIELD_NAME_PAYMENT_PAGE_ZUORA, lstQuote[0].zqu__BillToContact__r.MailingStreet);
                        }

                        defaultValues.put(Constants.CREDIT_CARD_CITY_FIELD_NAME_PAYMENT_PAGE_ZUORA, lstQuote[0].zqu__BillToContact__r.MailingCity);
    
                        defaultValues.put(Constants.CREDIT_CARD_POSTAL_CODE_FIELD_NAME_PAYMENT_PAGE_ZUORA,  lstQuote[0].zqu__BillToContact__r.MailingPostalCode);

                        defaultValues.put(Constants.CREDIT_CARD_COUNTRY_FIELD_NAME_PAYMENT_PAGE_ZUORA, getThreeLettersCountryCode(lstQuote[0].zqu__BillToContact__r.MailingCountry));
                        defaultValues.put(Constants.CREDIT_CARD_STATE_FIELD_NAME_PAYMENT_PAGE_ZUORA, getStateNameForNorthAmerica(lstQuote[0].zqu__BillToContact__r.MailingCountry, lstQuote[0].zqu__BillToContact__r.MailingState));
                    }
                } else if (paymentMethodType == zqu.PaymentPageController.PAYMENT_METHOD_TYPE_BANK_TRANSFER) { //set the default value field in case of bank transfer (direct debit)
                    if (ApexPages.currentPage().getParameters().containsKey('id')) {
                        List<zqu__Quote__c> lstQuote = [select zqu__BillToContact__r.firstname, zqu__BillToContact__r.lastname from zqu__Quote__c where id = :ApexPages.currentPage().getParameters().get('id') ];

                        defaultValues.put(Constants.DIRECT_DEBIT_FIRST_NAME_FIELD_NAME_PAYMENT_PAGE_ZUORA, lstQuote[0].zqu__BillToContact__r.firstname);

                        defaultValues.put(Constants.DIRECT_DEBIT_LAST_NAME_FIELD_NAME_PAYMENT_PAGE_ZUORA, lstQuote[0].zqu__BillToContact__r.lastname);
                    }
                }
            }
        }

        //this line was added to save the values in the form if the validation fails
        defaultValues.put('retainValues', 'true');

        return defaultValues;
    }

    /***************************************************************************************
    Developer   Michal Kwika (Accenture)
    Date        3/08/2015
    Function    this is helper method which gets API name of object based on sfID
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/

    public static String getNameOfObjectBasedOnId(String objectId) {
        String nameOfTheObject = '';

        String myIdPrefix = String.valueOf(objectId).substring(0, 3); //get just the prefix
        Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
        for (Schema.SObjectType stype : gd.values()) {
            Schema.DescribeSObjectResult r = stype.getDescribe();
            String prefix = r.getKeyPrefix();
            if (prefix != null && prefix.equals(myIdPrefix)) {
                nameOfTheObject = r.getName();
                return nameOfTheObject;
            }
        }

        return nameOfTheObject;
    }

    /***************************************************************************************
    Developer   Michal Kwika (Accenture)
    Date        24/08/2015
    Function    this is helper method which gets country ISO-3 code based on ISO-2Code
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    public static String getThreeLettersCountryCode(String twoLettersCountryCode){
        Country_Codes__c ccodes = Country_Codes__c.getInstance(twoLettersCountryCode);
        if(ccodes==null){
            return null;
        }
        return ccodes.Country_Three_Letters_Code__c;
    }

    /***************************************************************************************
    Developer   Michal Kwika (Accenture)
    Date        24/08/2015
    Function    this is helper method which gets State Name for Canada And USA
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    public static String getStateNameForNorthAmerica(String countryString, String twoLettersStateCode){
        if(countryString== Constants.COUNTRY_CANADA_TWO_LETTERS_CODE || countryString==Constants.COUNTRY_UNITED_STATES_TWO_LETTERS_CODE){
            State_Codes__c scodes = State_Codes__c.getInstance(twoLettersStateCode);
            if(scodes==null){
                return null;
            }
            return scodes.State_Name__c;
        }

        return null;
    }

}