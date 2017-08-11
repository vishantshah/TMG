/**
* @author Wiktor Czykin
* @date 22/06/2017
* @description Bean class to store all the sets of paramenters from/to the Deliver My Newspaper API for seamless deserialization
*############Change Log#############
*Modified by     Change Date
**/
public class DeliverNewspaperBean {

    /**
    * @author Wiktor Czykin
    * @date 22/06/2017
    * @description Incoming message structure
    *############Change Log#############
    *Modified by     Change Date
    **/
    public class DeliverNewspaperBeanData{
        public String firstName;
        public String lastName;
        public String addressLineOne;
        public String addressLineTwo;
        public String addressLineThree;
        public String town;
        public String county;
        public String postcode;
        public String email;
        public String subscriberId;
        public String phone;
        public String optInEmail;
        public String optInPhone;
        public String optInPost;
        public String optInText;

        public List<List<String>> deliveryDays;

        public String retailerId;
        public String retailerName;
        public String retailerPhoneNumber;
        public String retailerAddressLineOne;
        public String retailerAddressLineTwo;
        public String retailerTown;
        public String retailerPostcode;
        public String retailerType;

        public DeliverNewspaperBeanData(){}

    }

    /**
    * @author Wiktor Czykin
    * @date 22/06/2017
    * @description Success response message structure
    *############Change Log#############
    *Modified by     Change Date
    **/
    public class DeliverNewspaperSuccessResponseBean{
        public String orderId;

        public DeliverNewspaperSuccessResponseBean(String sOrderId){
            this.orderId = sOrderId;
        }
    }

    /**
    * @author Wiktor Czykin
    * @date 22/06/2017
    * @description Failure response message structure
    *############Change Log#############
    *Modified by     Change Date
    **/
    public class DeliverNewspaperErrorResponseBean{
        public String error;
        public Map<String, String> errors;

        public DeliverNewspaperErrorResponseBean(){
            this.error = '';
            this.errors = new Map<String, String>();
        }
    }
}