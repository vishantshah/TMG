//Generated by wsdl2apex

public class MPPDataContract2 {
    public class ArrayOfAccountParameter {
        public MPPDataContract2.AccountParameter[] AccountParameter;
        private String[] AccountParameter_type_info = new String[]{'AccountParameter','MppGlobal.iPay.BusinessObjects.DataContract.v4','AccountParameter','0','-1','true'};
        private String[] apex_schema_type_info = new String[]{'MppGlobal.iPay.BusinessObjects.DataContract.v4','true','false'};
        private String[] field_order_type_info = new String[]{'AccountParameter'};
    }
    public class ArrayOfSubscriptionParameter {
        public MPPDataContract2.SubscriptionParameter[] SubscriptionParameter;
        private String[] SubscriptionParameter_type_info = new String[]{'SubscriptionParameter','MppGlobal.iPay.BusinessObjects.DataContract.v4','SubscriptionParameter','0','-1','true'};
        private String[] apex_schema_type_info = new String[]{'MppGlobal.iPay.BusinessObjects.DataContract.v4','true','false'};
        private String[] field_order_type_info = new String[]{'SubscriptionParameter'};
    }
    public class SubscriptionParameter {
        public String ParameterName;
        public String ParameterValue;
        private String[] ParameterName_type_info = new String[]{'ParameterName','http://www.w3.org/2001/XMLSchema','string','0','1','true'};
        private String[] ParameterValue_type_info = new String[]{'ParameterValue','http://www.w3.org/2001/XMLSchema','string','0','1','true'};
        private String[] apex_schema_type_info = new String[]{'MppGlobal.iPay.BusinessObjects.DataContract.v4','true','false'};
        private String[] field_order_type_info = new String[]{'ParameterName','ParameterValue'};
    }
    public class AccountParameter {
        public String ParameterName;
        public String ParameterValue;
        private String[] ParameterName_type_info = new String[]{'ParameterName','http://www.w3.org/2001/XMLSchema','string','0','1','true'};
        private String[] ParameterValue_type_info = new String[]{'ParameterValue','http://www.w3.org/2001/XMLSchema','string','0','1','true'};
        private String[] apex_schema_type_info = new String[]{'MppGlobal.iPay.BusinessObjects.DataContract.v4','true','false'};
        private String[] field_order_type_info = new String[]{'ParameterName','ParameterValue'};
    }
}