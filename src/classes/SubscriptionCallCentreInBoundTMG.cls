/**
* @author Unknown
* @date Unknown
* @description Start page for offline acquisition page
#############Change Log#############
Modified by     Version     Change Date
Wiktor Czykin   1.1         30/06/2015  //clean-up
Wiktor Czykin   1.2         28/08/2015  //modified checkDuplicates(), findCustomerPOC(), findCustomerDirectMail()
Wiktor Czykin   1.3         08-09/2015  //LOW START changes and general clean-up
Wiktor Czykin   1.4         19/01/2016  //product hardcoding removal
Michal Kwika    1.5         15/03/2016  // product hardcoding data model changes - OfferSeelctor operations
Wiktor Czykin   1.6         04/2016     //made sure the methods from parent class are actually overriden,
                                            made sure redirection is made from here (processOfferSelection),
                                            added validation before redirection is made
**/
public with sharing class SubscriptionCallCentreInBoundTMG extends OfferSelector{

    public List<SelectOption> lstProductTypes{get;set;}
    public Boolean bProductSelected{get;set;}

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - Q1/2016
    Version - 1.1
    Function - constructor
    #############Change Log#############
    Modified by     Version     Change Date
    Michal Kwika    1.1         29/03/2016  // redefining constructor
    ****************************************************************************************/
    public SubscriptionCallCentreInBoundTMG() {
        this.lstProductTypes = OfferSelectionController.getProductTypeOptions();
        this.offerSelection = new OfferSelectionData();
        this.offerSelection.sSelectedProductType = Constants.PRODUCT_PREMIUM;
        this.bProductSelected = false;
        this.offerSelection.bIsActive = false;
        this.offerSelection.sOrderMethod = Constants.SUB_ORDER_METHOD_INBOUND;
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - Q1/2016
    Version - 1.0
    Function - setting the value of selecting product
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public void selectProduct(){
        this.bProductSelected = true;
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 26/04/2016
    Version - 1.0
    Function - redirection method - builds page reference based on selections
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public override PageReference processOfferSelection(){
        PageReference newpr;
        try {
            newpr = Page.OapSubscriptionTMG;
            this.offerSelection.agentUserId = UserInfo.getUserId();
            String price;

            if(String.isBlank(this.offerSelection.sTCode) && String.isNotBlank(this.offerSelection.sTcodeId)){
                this.offerSelection.sTCode = GlobalQueries.getTCodeNameBasedOnId(this.offerSelection.sTcodeId);
            }
            this.validateRequestParameters();
            if(ApexPages.hasMessages()){
                return null;
            }

            if(this.offerSelection.sSelectedOffer == Constants.OFFER_OPENOFFER){
                newpr.getParameters().put(OapSubscriptionTMG.PARAM_TCODE, this.offerSelection.sTCode);
            } else if(this.offerSelection.sSelectedOffer == Constants.OFFER_ADHOCPRICE){
                newpr.getParameters().put(OapSubscriptionTMG.PARAM_TCODE, this.offerSelection.sTCode);
                newpr.getParameters().put(OapSubscriptionTMG.PARAM_FORCED_PRICE, String.valueOf(Decimal.valueOf(this.offerSelection.sDiscountPrice).setScale(2)));
            } else if(this.offerSelection.sSelectedOffer == Constants.OFFER_PROMOTION || this.offerSelection.sSelectedOffer == Constants.OFFER_LOWSTART){
                newpr.getParameters().put(OapSubscriptionTMG.PARAM_TCODE, this.offerSelection.sTCode);
            } else if(this.offerSelection.sSelectedOffer == Constants.OFFER_POC || this.offerSelection.sSelectedOffer == Constants.OFFER_DIRECTMAIL){
                newpr.getParameters().put(OapSubscriptionTMG.PARAM_POCID, this.offerSelection.sPocId);
            } else if(this.offerSelection.sSelectedOffer == Constants.OFFER_MGM){
                // We force the price with the MGM giver Subscription price
                newpr.getParameters().put(OapSubscriptionTMG.PARAM_FORCED_PRICE, ''+ this.offerSelection.dForcedPrice);
                newpr.getParameters().put(OapSubscriptionTMG.PARAM_MGM_GIVERID, this.offerSelection.mgmGiverId);
                newpr.getParameters().put(OapSubscriptionTMG.PARAM_TCODE, this.offerSelection.sTCode);
            }
            if(this.offerSelection.sSelectedOffer == Constants.OFFER_STAFF){
                newpr.getParameters().put(OapSubscriptionTMG.PARAM_STAFF_NAME, this.offerSelection.sStaffName);
                newpr.getParameters().put(OapSubscriptionTMG.PARAM_TCODE, this.offerSelection.sTCode);
            }

            newpr.getParameters().put(OapSubscriptionTMG.PARAM_SELECTED_OFFER,this.offerSelection.sSelectedOffer);
            newpr.getParameters().put(OapSubscriptionTMG.PARAM_SELECTED_PRODUCT,this.offerSelection.sSelectedProductType);
            newpr.getParameters().put(OapSubscriptionTMG.PARAM_AGENCYID, Constants.AGENT_TMG);
            newpr.getParameters().put(OapSubscriptionTMG.PARAM_ORDER_METHOD, (TMGUTil.isDataValid(this.offerSelection.sOrderMethod) ? this.offerSelection.sOrderMethod : Constants.DIRECTION_INBOUND));
            newpr.getParameters().put(OapSubscriptionTMG.PARAM_AGENT_USERID, this.offerSelection.agentUserId);
            newpr.getParameters().put(OapSubscriptionTMG.PARAM_TSNUMBER, this.offerSelection.sTsNumber);
            newpr.getParameters().put(OapSubscriptionTMG.PARAM_GUID,this.offerSelection.sGuid);
            newpr.getParameters().put('isActive',''+this.offerSelection.bIsActive);
            newpr.getParameters().put(OapSubscriptionTMG.PARAM_PRODUCTID, this.offerSelection.productId);
            newpr.getParameters().put(OapSubscriptionTMG.PARAM_SURNAME, this.offerSelection.sSurname);
            newpr.getParameters().put(OapSubscriptionTMG.PARAM_POSTCODE,this.offerSelection.sPostCode);
        } catch (Exception errLaunchOAP){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, Label.Offline_Acquisition_OAP_redirection_issue));
            return null;
        }
        return newpr;
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 26/04/2016
    Version - 1.0
    Function - pre-redirection validation
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public void validateRequestParameters(){
        if(String.isBlank(this.offerSelection.sTcode) && String.isBlank(this.offerSelection.sPocId)){
           ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Offline_Acquisition_No_tcode_no_poc_issue_error));
        }
        if(this.offerSelection.productId == null){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,Label.Offline_Acquisition_Product_was_not_selected));
        }
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 26/04/2016
    Version - 1.0
    Function - just returns self
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public override OfferSelector getSelf(){
        return this;
    }
}
