//Generated by wsdl2apex

public class MPPBulkInterface {
    public class BulkChangePaymentSchedulePaymentDateResponse_element {
        public MPPBusinessObjectsIPaydev.BulkUpdateResultData BulkChangePaymentSchedulePaymentDateResult;
        private String[] BulkChangePaymentSchedulePaymentDateResult_type_info = new String[]{'BulkChangePaymentSchedulePaymentDateResult','MppGlobal.iShop.BusinessObjects.iPayDeveloper.DataContract.v4','BulkUpdateResultData','0','1','true'};
        private String[] apex_schema_type_info = new String[]{'https://payments.mppglobal.com/mpp/interface/bulkupdate/v4/bulkupdate.SOAP.svc','true','false'};
        private String[] field_order_type_info = new String[]{'BulkChangePaymentSchedulePaymentDateResult'};
    }
    public class BulkChangePaymentSchedulePaymentDate_element {
        public Integer affiliateId;
        public String password;
        public MPPBusinessObjectsBulkUpdate.ArrayOfChangePaymentSchedulePaymentDateRequest changePaymentSchedulePaymentDateRequests;
        public Boolean failOnFirstError;
        private String[] affiliateId_type_info = new String[]{'affiliateId','http://www.w3.org/2001/XMLSchema','int','0','1','false'};
        private String[] password_type_info = new String[]{'password','http://www.w3.org/2001/XMLSchema','string','0','1','true'};
        private String[] changePaymentSchedulePaymentDateRequests_type_info = new String[]{'changePaymentSchedulePaymentDateRequests','MppGlobal.iShop.BusinessObjects.BulkUpdate.DataContract.v4','ArrayOfChangePaymentSchedulePaymentDateRequest','0','1','true'};
        private String[] failOnFirstError_type_info = new String[]{'failOnFirstError','http://www.w3.org/2001/XMLSchema','boolean','0','1','false'};
        private String[] apex_schema_type_info = new String[]{'https://payments.mppglobal.com/mpp/interface/bulkupdate/v4/bulkupdate.SOAP.svc','true','false'};
        private String[] field_order_type_info = new String[]{'affiliateId','password','changePaymentSchedulePaymentDateRequests','failOnFirstError'};
    }
    public class SOAPEndpoint {
        public String endpoint_x = 'https://localhost/interface/mpp/BulkUpdate/v4/BulkUpdate.SOAP.svc/soap';
        public Map<String,String> inputHttpHeaders_x;
        public Map<String,String> outputHttpHeaders_x;
        public String clientCertName_x;
        public String clientCert_x;
        public String clientCertPasswd_x;
        public Integer timeout_x = 60000;
        private String[] ns_map_type_info = new String[]{'http://schemas.microsoft.com/2003/10/Serialization/', 'MPPSerialization', 'MppGlobal.iShop.BusinessObjects.iPayDeveloper.DataContract.v4', 'MPPBusinessObjectsIPaydev', 'MppGlobal.iShop.BusinessObjects.BulkUpdate.DataContract.v4', 'MPPBusinessObjectsBulkUpdate', 'https://payments.mppglobal.com/mpp/interface/bulkupdate/v4/bulkupdate.SOAP.svc', 'MPPBulkInterface', 'MppGlobal.iPay.BusinessObjects.DataContract.v4', 'MPPDataContract', 'http://schemas.datacontract.org/2004/07/MppGlobal.iShop.BusinessObjects.iPayDeveloper.SharedObjects', 'MPPSharedObjects'};
        
        public MPPBusinessObjectsIPaydev.BulkUpdateResultData BulkUserManage(Integer affiliateId, String password, MPPBusinessObjectsBulkUpdate.ArrayOfUserManageRequest userManageRequests,Boolean failOnFirstError) {
            MPPBulkInterface.BulkUserManage_element request_x = new MPPBulkInterface.BulkUserManage_element();
            MPPBulkInterface.BulkUserManageResponse_element response_x;
            request_x.affiliateId = affiliateId;
            request_x.password = password;
            request_x.userManageRequests = userManageRequests;
            request_x.failOnFirstError = failOnFirstError;
            Map<String, MPPBulkInterface.BulkUserManageResponse_element> response_map_x = new Map<String, MPPBulkInterface.BulkUserManageResponse_element>();
            response_map_x.put('response_x', response_x);
            WebServiceCallout.invoke(
              this,
              request_x,
              response_map_x,
              new String[]{endpoint_x,
              'https://payments.mppglobal.com/mpp/interface/bulkupdate/v4/bulkupdate.SOAP.svc/BulkUpdate/BulkUserManage',
              'https://payments.mppglobal.com/mpp/interface/bulkupdate/v4/bulkupdate.SOAP.svc',
              'BulkUserManage',
              'https://payments.mppglobal.com/mpp/interface/bulkupdate/v4/bulkupdate.SOAP.svc',
              'BulkUserManageResponse',
              'MPPBulkInterface.BulkUserManageResponse_element'}
            );
            response_x = response_map_x.get('response_x');
            return response_x.BulkUserManageResult;
        }
        public MPPBusinessObjectsIPaydev.BulkUpdateResultData BulkCancelPaymentSchedule(Integer affiliateId, String password, MPPBusinessObjectsBulkUpdate.ArrayOfCancelPaymentScheduleRequest cancelPaymentScheduleRequests,Boolean failOnFirstError) {
            MPPBulkInterface.BulkCancelPaymentSchedule_element request_x = new MPPBulkInterface.BulkCancelPaymentSchedule_element();
            MPPBulkInterface.BulkCancelPaymentScheduleResponse_element response_x;
            request_x.affiliateId = affiliateId;
            request_x.password = password;
            request_x.cancelPaymentScheduleRequests = cancelPaymentScheduleRequests;
            request_x.failOnFirstError = failOnFirstError;
            Map<String, MPPBulkInterface.BulkCancelPaymentScheduleResponse_element> response_map_x = new Map<String, MPPBulkInterface.BulkCancelPaymentScheduleResponse_element>();
            response_map_x.put('response_x', response_x);
            WebServiceCallout.invoke(
              this,
              request_x,
              response_map_x,
              new String[]{endpoint_x,
              'https://payments.mppglobal.com/mpp/interface/bulkupdate/v4/bulkupdate.SOAP.svc/BulkUpdate/BulkCancelPaymentSchedule',
              'https://payments.mppglobal.com/mpp/interface/bulkupdate/v4/bulkupdate.SOAP.svc',
              'BulkCancelPaymentSchedule',
              'https://payments.mppglobal.com/mpp/interface/bulkupdate/v4/bulkupdate.SOAP.svc',
              'BulkCancelPaymentScheduleResponse',
              'MPPBulkInterface.BulkCancelPaymentScheduleResponse_element'}
            );
            response_x = response_map_x.get('response_x');
            return response_x.BulkCancelPaymentScheduleResult;
        }
        public MPPBusinessObjectsIPaydev.BulkUpdateResultData BulkChangePaymentSchedulePaymentDate(Integer affiliateId, String password, MPPBusinessObjectsBulkUpdate.ArrayOfChangePaymentSchedulePaymentDateRequest changePaymentSchedulePaymentDateRequests,Boolean failOnFirstError) {
            MPPBulkInterface.BulkChangePaymentSchedulePaymentDate_element request_x = new MPPBulkInterface.BulkChangePaymentSchedulePaymentDate_element();
            MPPBulkInterface.BulkChangePaymentSchedulePaymentDateResponse_element response_x;
            request_x.affiliateId = affiliateId;
            request_x.password = password;
            request_x.changePaymentSchedulePaymentDateRequests = changePaymentSchedulePaymentDateRequests;
            request_x.failOnFirstError = failOnFirstError;
            Map<String, MPPBulkInterface.BulkChangePaymentSchedulePaymentDateResponse_element> response_map_x = new Map<String, MPPBulkInterface.BulkChangePaymentSchedulePaymentDateResponse_element>();
            response_map_x.put('response_x', response_x);
            WebServiceCallout.invoke(
              this,
              request_x,
              response_map_x,
              new String[]{endpoint_x,
              'https://payments.mppglobal.com/mpp/interface/bulkupdate/v4/bulkupdate.SOAP.svc/BulkUpdate/BulkChangePaymentSchedulePaymentDate',
              'https://payments.mppglobal.com/mpp/interface/bulkupdate/v4/bulkupdate.SOAP.svc',
              'BulkChangePaymentSchedulePaymentDate',
              'https://payments.mppglobal.com/mpp/interface/bulkupdate/v4/bulkupdate.SOAP.svc',
              'BulkChangePaymentSchedulePaymentDateResponse',
              'MPPBulkInterface.BulkChangePaymentSchedulePaymentDateResponse_element'}
            );
            response_x = response_map_x.get('response_x');
            return response_x.BulkChangePaymentSchedulePaymentDateResult;
        }
    }
    public class BulkUserManage_element {
        public Integer affiliateId;
        public String password;
        public MPPBusinessObjectsBulkUpdate.ArrayOfUserManageRequest userManageRequests;
        public Boolean failOnFirstError;
        private String[] affiliateId_type_info = new String[]{'affiliateId','http://www.w3.org/2001/XMLSchema','int','0','1','false'};
        private String[] password_type_info = new String[]{'password','http://www.w3.org/2001/XMLSchema','string','0','1','true'};
        private String[] userManageRequests_type_info = new String[]{'userManageRequests','MppGlobal.iShop.BusinessObjects.BulkUpdate.DataContract.v4','ArrayOfUserManageRequest','0','1','true'};
        private String[] failOnFirstError_type_info = new String[]{'failOnFirstError','http://www.w3.org/2001/XMLSchema','boolean','0','1','false'};
        private String[] apex_schema_type_info = new String[]{'https://payments.mppglobal.com/mpp/interface/bulkupdate/v4/bulkupdate.SOAP.svc','true','false'};
        private String[] field_order_type_info = new String[]{'affiliateId','password','userManageRequests','failOnFirstError'};
    }
    public class BulkCancelPaymentScheduleResponse_element {
        public MPPBusinessObjectsIPaydev.BulkUpdateResultData BulkCancelPaymentScheduleResult;
        private String[] BulkCancelPaymentScheduleResult_type_info = new String[]{'BulkCancelPaymentScheduleResult','MppGlobal.iShop.BusinessObjects.iPayDeveloper.DataContract.v4','BulkUpdateResultData','0','1','true'};
        private String[] apex_schema_type_info = new String[]{'https://payments.mppglobal.com/mpp/interface/bulkupdate/v4/bulkupdate.SOAP.svc','true','false'};
        private String[] field_order_type_info = new String[]{'BulkCancelPaymentScheduleResult'};
    }
    public class BulkUserManageResponse_element {
        public MPPBusinessObjectsIPaydev.BulkUpdateResultData BulkUserManageResult;
        private String[] BulkUserManageResult_type_info = new String[]{'BulkUserManageResult','MppGlobal.iShop.BusinessObjects.iPayDeveloper.DataContract.v4','BulkUpdateResultData','0','1','true'};
        private String[] apex_schema_type_info = new String[]{'https://payments.mppglobal.com/mpp/interface/bulkupdate/v4/bulkupdate.SOAP.svc','true','false'};
        private String[] field_order_type_info = new String[]{'BulkUserManageResult'};
    }
    public class BulkCancelPaymentSchedule_element {
        public Integer affiliateId;
        public String password;
        public MPPBusinessObjectsBulkUpdate.ArrayOfCancelPaymentScheduleRequest cancelPaymentScheduleRequests;
        public Boolean failOnFirstError;
        private String[] affiliateId_type_info = new String[]{'affiliateId','http://www.w3.org/2001/XMLSchema','int','0','1','false'};
        private String[] password_type_info = new String[]{'password','http://www.w3.org/2001/XMLSchema','string','0','1','true'};
        private String[] cancelPaymentScheduleRequests_type_info = new String[]{'cancelPaymentScheduleRequests','MppGlobal.iShop.BusinessObjects.BulkUpdate.DataContract.v4','ArrayOfCancelPaymentScheduleRequest','0','1','true'};
        private String[] failOnFirstError_type_info = new String[]{'failOnFirstError','http://www.w3.org/2001/XMLSchema','boolean','0','1','false'};
        private String[] apex_schema_type_info = new String[]{'https://payments.mppglobal.com/mpp/interface/bulkupdate/v4/bulkupdate.SOAP.svc','true','false'};
        private String[] field_order_type_info = new String[]{'affiliateId','password','cancelPaymentScheduleRequests','failOnFirstError'};
    }
}