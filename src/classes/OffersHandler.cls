/**
* @author Wiktor Czykin
* @date 27/02/2017
* @description REST apex class providing data about zuora offers prepared in salesforce
#############Change Log#############
Modified by     Change Date
Wiktor Czykin   16/05/2017  //moved the custom metadata retrieval method to global queries
**/
@RestResource(urlMapping='/OffersHandler/v1/*')
global without sharing class OffersHandler {

    private static final String ENDPOINT = 'OffersHandler';
    private static final String PARAM_ID = 'offerId';
    private static final String PARAM_ALL = 'allOffers';

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 27/02/2017
    Version - 1.0
    Function - get rest method to return list of offer or offers depending on the get parameter
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    @HttpGet
    global static  List<OfferBean> getOffers(){
        Map<String, String> mapParams = RestContext.request.params;
        List<OfferBean> lstBeans = new List<OfferBean>();
        String sPayload = RestContext.request.requestBody != null ? RestContext.request.requestBody.toString():'';
        mapParams.put('body', sPayload);

        Webservice_Log__c wl = TMGUtil.newLogWebServiceRequestSerialized(Constants.DIRECTION_INBOUND, ENDPOINT, 'GET OFFER', mapParams, null, null, null);
        try{
            if(mapParams.isEmpty() || (String.isBlank(mapParams.get(PARAM_ID)) && String.isBlank(mapParams.get(PARAM_ALL)))){
                throw new TelegraphApplicationException(String.format(Label.Offers_Missing_parameters_for_offers_retrieval_endpoint, new List<String>{PARAM_ID, PARAM_ALL}));
            }
            Map<String, Offers_Frequency_Rate_Plan_Map__mdt> mapFrequencyRatePlan = GlobalQueries.retrieveFrequencySetting();
            if(mapFrequencyRatePlan.isEmpty()){
                throw new TelegraphApplicationException(Label.Offers_Required_frequency_rate_plan_configuration_missing);
            }

            String sQueryFields = GlobalQueries.generateFieldsListForQuery(Offer__c.class.getName(), null, null);
            String sParamId = mapParams.get(PARAM_ID);

            List<Offer__c> lstOffers = new List<Offer__c>();
            if(String.isNotBlank(sParamId)){
                lstOffers = Database.query('SELECT '+sQueryFields+' FROM Offer__c WHERE Name = : sParamId');
            }else if(String.isNotBlank(mapParams.get(PARAM_ALL))){
                lstOffers = Database.query('SELECT '+sQueryFields+' FROM Offer__c');
            }

            if(lstOffers.isEmpty()) return null;
            Set<Id> setProducts = new Set<Id>();
            for(Offer__c o : lstOffers){
                setProducts.add(o.ZProduct__c);
            }

            Map<Id, zqu__ZProduct__c> mapProductsWithRatePlans = new Map<Id, zqu__ZProduct__c>([SELECT  Id,
                                                                                                        Name,
                                                                                                        zqu__ZuoraId__c,
                                                                                                        Product_Image__c,
                                                                                                        Product_Image_2__c,
                                                                                                        zqu__Description__c,
                                                                                                        ProductFriendlyName__c,
                                                                                                        (SELECT Id,
                                                                                                                Name,
                                                                                                                zqu__ZuoraId__c
                                                                                                            FROM zqu__ProductRatePlan__r
                                                                                                            WHERE zqu__EffectiveEndDate__c >= :Date.today()
                                                                                                            )
                                                                                                    FROM zqu__ZProduct__c
                                                                                                    WHERE Id IN :setProducts]);
            for(Offer__c o : lstOffers){
                zqu__ZProduct__c product = mapProductsWithRatePlans.get(o.ZProduct__c);
                if(product == null || product.zqu__ProductRatePlan__r.isEmpty()) continue;
                zqu__ProductRatePlan__c matchingRatePlan;
                Offers_Frequency_Rate_Plan_Map__mdt mappingObject = mapFrequencyRatePlan.get(o.Frequency__c);

                if(mappingObject == null || String.isBlank(mappingObject.Target_Rate_Plan_Name__c)) continue;
                String sNameToCompare = mappingObject.Target_Rate_Plan_Name__c;
                for(zqu__ProductRatePlan__c prp : product.zqu__ProductRatePlan__r){
                    if(sNameToCompare == prp.Name){
                        matchingRatePlan = prp;
                        break;
                    }
                }

                if(matchingRatePlan != null){
                    OfferBean ob = new OfferBean(o, product, matchingRatePlan);
                    if(String.isNotBlank(mappingObject.API_Frequency__c)){
                        ob.frequency = mappingObject.API_Frequency__c;
                    }
                    if(!ob.discounts.isEmpty()){
                        for(OfferBean.Discount d : ob.discounts){
                            if(String.isNotBlank(mappingObject.API_Frequency__c)){
                                d.billingPeriod = mappingObject.API_Frequency__c;
                            }
                        }
                    }
                    lstBeans.add(ob);
                }
            }
            TMGUtil.populateResponseOnWebServiceRequestSerialized(wl, lstBeans);
        }catch(Exception e){
            String msg = e.getMessage()+'; Line number:'+e.getLineNumber()+'; Cause: '+e.getCause();
            TMGUtil.populateResponseOnWebServiceRequestSerialized(wl, msg);
            insert wl;
            throw new TelegraphApplicationException(msg);
        }
        insert wl;
        OfferBean.encodeVariables(lstBeans, null);
        return lstBeans;
    }
}