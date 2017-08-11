/**
* @author Wiktor Czykin
* @date 21/01/2016
* @description Wrapper to show individual products against tcodes
#############Change Log#############
Modified by     Version     Change Date
Michal Kwika    1.1         15/03/2016
Wiktor Czykin   1.2         12/06/2016 //added isPrint flag and digital prices
Wiktor Czykin   1.3         30/08/2016 //added voucher delivery type
Wiktor Czykin   1.4         18/10/2016 //added rank and added sorting by it
Wiktor Czykin   1.5         28/10/2016 //added handling of renewal incentives filtering
**/
public class TCodeProductWrapper implements Comparable{
    public String sProductName          {get;set;}
    public Id productId                 {get;set;}
    public Decimal premiumPrice         {get;set;}
    public Decimal digitalMonthlyPrice  {get;set;}
    public Decimal digitalYearlyPrice   {get;set;}
    public Decimal lowStartPrice        {get;set;}
    public String  incentives           {get;set;}
    public Boolean selected             {get;set;}
    public Boolean isPrint              {get;set;}
    public String voucherDeliveryType   {get;set;}
    public Decimal rank                 {get;set;}
    private Boolean bOnlyRenewalIncentives{get;set;}


    public TCodeProductWrapper(TCode_Product__c tcp, Boolean bOnlyRenewalIncentives){
        this.bOnlyRenewalIncentives = bOnlyRenewalIncentives;
        this.initAttributes(tcp);
    }

    public TCodeProductWrapper(TCode_Product__c tcp){
        this.bOnlyRenewalIncentives = false;
        this.initAttributes(tcp);
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 28/10/2016
    Version - 1.0
    Function - extracted common part for constructors - added filtering logic for incentives against product
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private void initAttributes(TCode_Product__c tcp){
        this.sProductName = tcp.Product__r.Name;
        this.productId = tcp.Product__c;
        this.premiumPrice = tcp.Weekly_Price__c;
        this.lowStartPrice = tcp.Low_Start_Price__c;
        this.incentives = Label.Acqusition_Flow_No_Incentive;
        this.digitalMonthlyPrice = tcp.Digital_Monthly_Price__c;
        this.digitalYearlyPrice = tcp.Digital_Yearly_Price__c;
        this.isPrint = tcp.Product__r.Print_Product__c;
        this.voucherDeliveryType = tcp.Product__r.Voucher_Delivery_Type__c;
        if(String.isNotBlank(tcp.Product__r.Rank__c) && tcp.Product__r.Rank__c.isNumeric()){
            this.rank = Integer.valueOf(tcp.Product__r.Rank__c);
        }
        if(tcp.getSObjects('TCode_Product_Incentives__r') != null && !((List<TCode_Product_Incentive__c>)tcp.getSObjects('TCode_Product_Incentives__r')).isEmpty()){
            for(TCode_Product_Incentive__c tcpi : (List<TCode_Product_Incentive__c>)tcp.getSObjects('TCode_Product_Incentives__r')){
                if(tcpi.Incentive_Validity_Status__c){
                    if(this.bOnlyRenewalIncentives && tcpi.Is_Incentive_Valid_For_Renewal__c){
                        this.addIncentive(tcpi.Incentive__r.Name);
                    }else if(!this.bOnlyRenewalIncentives){
                        this.addIncentive(tcpi.Incentive__r.Name);
                    }
                }
            }
        }
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 21/01/2016
    Version - 1.0
    Function - method that concatenates incentive names into singlie string 
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public void addIncentive(String sIncentive){
        if(this.incentives == null || this.incentives == Label.Acqusition_Flow_No_Incentive) this.incentives = '';
        if(String.isNotBlank(this.incentives)){
            this.incentives += ', ';
        }
        this.incentives += sIncentive;
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 20/04/2016
    Version - 1.1
    Function -  Method to sort the wrapper by sProductName
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         18/10/2016  //added sorting by rank
    ****************************************************************************************/
    public Integer compareTo(Object compareTo){
        TCodeProductWrapper compareToCopy = (TCodeProductWrapper)compareTo;
        Integer returnValue = 0;
        if(this.rank == null || compareToCopy.rank == null || this.rank == compareToCopy.rank){
            if (this.sProductName > compareToCopy.sProductName){
                // Set return value to a negative value.
                returnValue = 1;
            } else if (this.sProductName < compareToCopy.sProductName) {
                // Set return value to a positive value.
                returnValue = -1;
            }
        }else if(this.rank > compareToCopy.rank){
            returnValue  = 1;
        }else{
            returnValue = -1;
        }
        return returnValue;
    }
}
