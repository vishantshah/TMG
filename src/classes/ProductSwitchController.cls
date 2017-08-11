/**
* @author Wiktor Czykin
* @date 05/05/2016
* @description Class which instance can be injected into ProductSwitch vf component
#############Change Log#############
Modified by     Version     Change Date
Wiktor Czykin   1.1         22/06/2016  //modified constructor, added exception class definition
**/
public with sharing class ProductSwitchController {

    @TestVisible private Boolean bPrintProducts;
    @TestVisible private String sTCodeName;
    @TestVisible private Id tCodeId;
    @TestVisible private ProductSwitchSupport pss;
    @TestVisible private Boolean bFilterRenewalIncentives;

    public Id productId{get;set;}
    public Boolean bProductTCodeMatch{get; private set;}
    public TCodeProductWrapper selectedProduct{get; private set;}
    public Boolean bShowOtherProducts{get;set;}
    public List<TCodeProductWrapper> lstProductsForTCode{get; private set;}
    public Boolean bHideButtonAndSection{get;set;}

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 28/10/2016
    Version - 1.0
    Function - Constructor - new version to handle extra parameter for filtering incentives
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public ProductSwitchController(ProductSwitchSupport pss, Id productId, Id tCodeId, Boolean bPrintProducts, Boolean bFilterRenewal){
        this.initAttributes(pss, productId, tCodeId, bPrintProducts, bFilterRenewal);
        this.loadProductsForTCode();
        this.validateProductInTCode();
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 05/05/2016
    Version - 1.2
    Function - Constructor - initial param check and initialization of variables
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         22/06/2016 //throwing missing product id as different exception
    Wiktor Czykin   1.2         28/10/2016 //added setting of bFilterRenewalIncentives
    ****************************************************************************************/
    public ProductSwitchController(ProductSwitchSupport pss, Id productId, Id tCodeId, Boolean bPrintProducts){
        this.initAttributes(pss, productId, tCodeId, bPrintProducts, null);
        this.loadProductsForTCode();
        this.validateProductInTCode();
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 28/10/2016
    Version - 1.0
    Function - init method to support different types of constructors
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private void initAttributes(ProductSwitchSupport pss, Id productId, Id tCodeId, Boolean bPrintProducts, Boolean bFilterRenewal){
        if(pss == null || tCodeId == null) throw new TelegraphApplicationException(Label.Product_Switch_Wrong_parameters_for_init);
        if(productId == null) throw new ProductSwitchControllerException(Label.Product_Switch_Subscription_without_specified_product);
        this.pss = pss;
        this.productId = productId;
        this.tCodeId = tCodeId;
        this.bPrintProducts = bPrintProducts;
        if(this.bPrintProducts == null){
            this.bPrintProducts = true;
        }
        this.bShowOtherProducts = false;
        this.bProductTCodeMatch = false;
        this.bHideButtonAndSection = false;
        this.sTCodeName = GlobalQueries.getTCodeNameBasedOnId(this.tCodeId);
        this.bFilterRenewalIncentives = false;
        if(bFilterRenewal != null){
            this.bFilterRenewalIncentives = bFilterRenewal;
        }
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 05/05/2016
    Version - 1.1
    Function - just fetches products for tcode
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         28/10/2016 //modified init of TCodeProductWrapper
    ****************************************************************************************/
    private void loadProductsForTCode(){
        List<TCode_Product__c> lstTCodeProducts = GlobalQueries.getTcodeProducts(this.tCodeId, this.bPrintProducts);
        this.lstProductsForTCode = new List<TCodeProductWrapper>();
        for(TCode_Product__c tcp : lstTCodeProducts){
            this.lstProductsForTCode.add(new TCodeProductWrapper(tcp, this.bFilterRenewalIncentives));
        }
        this.pss.prepareProductListBeforeView(this.lstProductsForTCode);
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 05/05/2016
    Version - 1.0
    Function - Validates if the tcode products list contain passed in product and sets correct flags to manipulate the ui
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private void validateProductInTCode(){
        if(this.lstProductsForTCode != null && !this.lstProductsForTCode.isEmpty()){
            for(TCodeProductWrapper tcpw : this.lstProductsForTCode){
                if(tcpw.productId == this.productId){
                    this.bProductTCodeMatch = true;
                    this.selectedProduct = tcpw;
                    break;
                }
            }
            if(this.bProductTCodeMatch && this.lstProductsForTCode.size() == 1){
                this.bHideButtonAndSection = true;
            }else if(!this.bProductTCodeMatch){
                this.bShowOtherProducts = true;
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, String.format(Label.Product_Switch_No_product_match_against_campaign, new List<String>{this.sTCodeName})));
            }
        }else{
            this.bHideButtonAndSection = true; //because in this scenario there is also no point in showing the "show other products" button
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, String.format(Label.Product_Switch_No_products, new List<String>{this.sTCodeName})));
        }
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 05/05/2016
    Version - 1.0
    Function - Loops through tcode products list and adds all products part from selected one.
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public List<TCodeProductWrapper> getProducts(){
        List<TCodeProductWrapper> lstTemp = new List<TCodeProductWrapper>();
        if(this.lstProductsForTCode != null){
            for(TCodeProductWrapper tcpw : this.lstProductsForTCode){
                if(tcpw.productId != this.productId){
                    lstTemp.add(tcpw);
                }
            }
        }
        lstTemp.sort();
        return lstTemp;
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 05/05/2016
    Version - 1.0
    Function - Again validates the product selected (which would reset proper flags) and if the validation was successful it sets product Id on the parent class (ProductSwitchSupport)
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public void changeProduct(){
        this.validateProductInTCode();
        if(this.bProductTCodeMatch){
            this.pss.changeProductId(this.productId);
        }
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 05/05/2016
    Version - 1.0
    Function - Button click to show other products (button only visible if other are not yet shown - executed in happy flow only)
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public void showOtherProducts(){
        this.bShowOtherProducts = true;
    }

    public class ProductSwitchControllerException extends Exception{}
}
