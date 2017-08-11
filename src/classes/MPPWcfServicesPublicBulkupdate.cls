//Generated by wsdl2apex

public class MPPWcfServicesPublicBulkupdate {
    public class BulkChangePaymentSchedulePaymentDateResponse_element {
        public MPPBusinessObjectsIPaydev.BulkUpdateResultData BulkChangePaymentSchedulePaymentDateResult;
        private String[] BulkChangePaymentSchedulePaymentDateResult_type_info = new String[]{'BulkChangePaymentSchedulePaymentDateResult','MppGlobal.iShop.BusinessObjects.iPayDeveloper.DataContract.v4','BulkUpdateResultData','0','1','true'};
        private String[] apex_schema_type_info = new String[]{'MppGlobal.WCFServices.Public.BulkUpdate.v7','true','false'};
        private String[] field_order_type_info = new String[]{'BulkChangePaymentSchedulePaymentDateResult'};
    }
    public class BulkAddDynamicPaymentScheduleResponse_element {
        public MPPBusinessObjectsIPaydev.BulkUpdateResultData BulkAddDynamicPaymentScheduleResult;
        private String[] BulkAddDynamicPaymentScheduleResult_type_info = new String[]{'BulkAddDynamicPaymentScheduleResult','MppGlobal.iShop.BusinessObjects.iPayDeveloper.DataContract.v4','BulkUpdateResultData','0','1','true'};
        private String[] apex_schema_type_info = new String[]{'MppGlobal.WCFServices.Public.BulkUpdate.v7','true','false'};
        private String[] field_order_type_info = new String[]{'BulkAddDynamicPaymentScheduleResult'};
    }
    public class BulkUserManageDirectDebitResponse_element {
        public MPPBusinessObjectsIPaydev.BulkUpdateResultData BulkUserManageDirectDebitResult;
        private String[] BulkUserManageDirectDebitResult_type_info = new String[]{'BulkUserManageDirectDebitResult','MppGlobal.iShop.BusinessObjects.iPayDeveloper.DataContract.v4','BulkUpdateResultData','0','1','true'};
        private String[] apex_schema_type_info = new String[]{'MppGlobal.WCFServices.Public.BulkUpdate.v7','true','false'};
        private String[] field_order_type_info = new String[]{'BulkUserManageDirectDebitResult'};
    }
    public class BulkChangePaymentSchedulePaymentDate_element {
        public Integer clientId;
        public String apiPassword;
        public MPPBusinessobjectsBulkupdate2.ArrayOfChangePaymentSchedulePaymentDateRequest changePaymentSchedulePaymentDateRequests;
        public Boolean failOnFirstError;
        private String[] clientId_type_info = new String[]{'clientId','http://www.w3.org/2001/XMLSchema','int','0','1','false'};
        private String[] apiPassword_type_info = new String[]{'apiPassword','http://www.w3.org/2001/XMLSchema','string','0','1','true'};
        private String[] changePaymentSchedulePaymentDateRequests_type_info = new String[]{'changePaymentSchedulePaymentDateRequests','MppGlobal.iShop.BusinessObjects.BulkUpdate.DataContract.v4','ArrayOfChangePaymentSchedulePaymentDateRequest','0','1','true'};
        private String[] failOnFirstError_type_info = new String[]{'failOnFirstError','http://www.w3.org/2001/XMLSchema','boolean','0','1','false'};
        private String[] apex_schema_type_info = new String[]{'MppGlobal.WCFServices.Public.BulkUpdate.v7','true','false'};
        private String[] field_order_type_info = new String[]{'clientId','apiPassword','changePaymentSchedulePaymentDateRequests','failOnFirstError'};
    }
    public class SOAPEndpoint {
        public String endpoint_x = 'https://mpp00036.office.mppglobal.com/interface/mpp/BulkUpdate/v7/BulkUpdate.SOAP.svc/soap';
        public Map<String,String> inputHttpHeaders_x;
        public Map<String,String> outputHttpHeaders_x;
        public String clientCertName_x;
        public String clientCert_x;
        public String clientCertPasswd_x;
        public Integer timeout_x;
        private String[] ns_map_type_info = new String[]{'http://schemas.microsoft.com/2003/10/Serialization/', 'MPPSerialization2', 'MppGlobal.iShop.BusinessObjects.iPayDeveloper.DataContract.v4', 'MPPBusinessObjectsIPaydev', 'MppGlobal.iShop.BusinessObjects.BulkUpdate.DataContract.v4', 'MPPBusinessobjectsBulkupdate2', 'MppGlobal.WCFServices.Public.BulkUpdate.v7', 'MPPWcfServicesPublicBulkupdate', 'MppGlobal.BusinessLogic.Core.DataContract.v7', 'MPPGlobalCoreDataContract', 'MppGlobal.iPay.BusinessObjects.DataContract.v4', 'MPPDataContract2', 'http://schemas.datacontract.org/2004/07/MppGlobal.iShop.Interfaces', 'MPPInterfaces', 'http://schemas.datacontract.org/2004/07/MppGlobal.iShop.BusinessObjects.iPayDeveloper.SharedObjects', 'MPPBusinessObjectsIPaydev', 'http://schemas.datacontract.org/2004/07/MppGlobal.iPay.DataObjects', 'MPPDataObjects'};
        public MPPBusinessObjectsIPaydev.BulkUpdateResultData BulkChangePaymentSchedulePaymentDate(Integer clientId,String apiPassword,MPPBusinessobjectsBulkupdate2.ArrayOfChangePaymentSchedulePaymentDateRequest changePaymentSchedulePaymentDateRequests,Boolean failOnFirstError) {
            MPPWcfServicesPublicBulkupdate.BulkChangePaymentSchedulePaymentDate_element request_x = new MPPWcfServicesPublicBulkupdate.BulkChangePaymentSchedulePaymentDate_element();
            MPPWcfServicesPublicBulkupdate.BulkChangePaymentSchedulePaymentDateResponse_element response_x;
            request_x.clientId = clientId;
            request_x.apiPassword = apiPassword;
            request_x.changePaymentSchedulePaymentDateRequests = changePaymentSchedulePaymentDateRequests;
            request_x.failOnFirstError = failOnFirstError;
            Map<String, MPPWcfServicesPublicBulkupdate.BulkChangePaymentSchedulePaymentDateResponse_element> response_map_x = new Map<String, MPPWcfServicesPublicBulkupdate.BulkChangePaymentSchedulePaymentDateResponse_element>();
            response_map_x.put('response_x', response_x);
            WebServiceCallout.invoke(
              this,
              request_x,
              response_map_x,
              new String[]{endpoint_x,
              'MppGlobal.WCFServices.Public.BulkUpdate.v7/BulkUpdate/BulkChangePaymentSchedulePaymentDate',
              'MppGlobal.WCFServices.Public.BulkUpdate.v7',
              'BulkChangePaymentSchedulePaymentDate',
              'MppGlobal.WCFServices.Public.BulkUpdate.v7',
              'BulkChangePaymentSchedulePaymentDateResponse',
              'MPPWcfServicesPublicBulkupdate.BulkChangePaymentSchedulePaymentDateResponse_element'}
            );
            response_x = response_map_x.get('response_x');
            return response_x.BulkChangePaymentSchedulePaymentDateResult;
        }
        public MPPBusinessObjectsIPaydev.BulkUpdateResultData BulkCancelPaymentSchedule(Integer clientId,String apiPassword,MPPBusinessobjectsBulkupdate2.ArrayOfCancelPaymentScheduleRequest cancelPaymentScheduleRequests,Boolean failOnFirstError) {
            MPPWcfServicesPublicBulkupdate.BulkCancelPaymentSchedule_element request_x = new MPPWcfServicesPublicBulkupdate.BulkCancelPaymentSchedule_element();
            MPPWcfServicesPublicBulkupdate.BulkCancelPaymentScheduleResponse_element response_x;
            request_x.clientId = clientId;
            request_x.apiPassword = apiPassword;
            request_x.cancelPaymentScheduleRequests = cancelPaymentScheduleRequests;
            request_x.failOnFirstError = failOnFirstError;
            Map<String, MPPWcfServicesPublicBulkupdate.BulkCancelPaymentScheduleResponse_element> response_map_x = new Map<String, MPPWcfServicesPublicBulkupdate.BulkCancelPaymentScheduleResponse_element>();
            response_map_x.put('response_x', response_x);
            WebServiceCallout.invoke(
              this,
              request_x,
              response_map_x,
              new String[]{endpoint_x,
              'MppGlobal.WCFServices.Public.BulkUpdate.v7/BulkUpdate/BulkCancelPaymentSchedule',
              'MppGlobal.WCFServices.Public.BulkUpdate.v7',
              'BulkCancelPaymentSchedule',
              'MppGlobal.WCFServices.Public.BulkUpdate.v7',
              'BulkCancelPaymentScheduleResponse',
              'MPPWcfServicesPublicBulkupdate.BulkCancelPaymentScheduleResponse_element'}
            );
            response_x = response_map_x.get('response_x');
            return response_x.BulkCancelPaymentScheduleResult;
        }
        public MPPBusinessObjectsIPaydev.BulkUpdateResultData BulkAddDynamicPaymentSchedule(Integer clientId,String apiPassword,MPPGlobalCoreDataContract.ArrayOfAddDynamicPaymentScheduleRequest addDynamicPaymentScheduleRequests,Boolean failOnFirstError) {
            MPPWcfServicesPublicBulkupdate.BulkAddDynamicPaymentSchedule_element request_x = new MPPWcfServicesPublicBulkupdate.BulkAddDynamicPaymentSchedule_element();
            MPPWcfServicesPublicBulkupdate.BulkAddDynamicPaymentScheduleResponse_element response_x;
            request_x.clientId = clientId;
            request_x.apiPassword = apiPassword;
            request_x.addDynamicPaymentScheduleRequests = addDynamicPaymentScheduleRequests;
            request_x.failOnFirstError = failOnFirstError;
            Map<String, MPPWcfServicesPublicBulkupdate.BulkAddDynamicPaymentScheduleResponse_element> response_map_x = new Map<String, MPPWcfServicesPublicBulkupdate.BulkAddDynamicPaymentScheduleResponse_element>();
            response_map_x.put('response_x', response_x);
            WebServiceCallout.invoke(
              this,
              request_x,
              response_map_x,
              new String[]{endpoint_x,
              'MppGlobal.WCFServices.Public.BulkUpdate.v7/BulkUpdate/BulkAddDynamicPaymentSchedule',
              'MppGlobal.WCFServices.Public.BulkUpdate.v7',
              'BulkAddDynamicPaymentSchedule',
              'MppGlobal.WCFServices.Public.BulkUpdate.v7',
              'BulkAddDynamicPaymentScheduleResponse',
              'MPPWcfServicesPublicBulkupdate.BulkAddDynamicPaymentScheduleResponse_element'}
            );
            response_x = response_map_x.get('response_x');
            return response_x.BulkAddDynamicPaymentScheduleResult;
        }
        public MPPBusinessObjectsIPaydev.BulkUpdateResultData BulkUserManageDirectDebit(Integer clientId,String apiPassword,MPPGlobalCoreDataContract.ArrayOfUserManageDirectDebitRequest userManageDirectDebitRequests,Boolean failOnFirstError) {
            MPPWcfServicesPublicBulkupdate.BulkUserManageDirectDebit_element request_x = new MPPWcfServicesPublicBulkupdate.BulkUserManageDirectDebit_element();
            MPPWcfServicesPublicBulkupdate.BulkUserManageDirectDebitResponse_element response_x;
            request_x.clientId = clientId;
            request_x.apiPassword = apiPassword;
            request_x.userManageDirectDebitRequests = userManageDirectDebitRequests;
            request_x.failOnFirstError = failOnFirstError;
            Map<String, MPPWcfServicesPublicBulkupdate.BulkUserManageDirectDebitResponse_element> response_map_x = new Map<String, MPPWcfServicesPublicBulkupdate.BulkUserManageDirectDebitResponse_element>();
            response_map_x.put('response_x', response_x);
            WebServiceCallout.invoke(
              this,
              request_x,
              response_map_x,
              new String[]{endpoint_x,
              'MppGlobal.WCFServices.Public.BulkUpdate.v7/BulkUpdate/BulkUserManageDirectDebit',
              'MppGlobal.WCFServices.Public.BulkUpdate.v7',
              'BulkUserManageDirectDebit',
              'MppGlobal.WCFServices.Public.BulkUpdate.v7',
              'BulkUserManageDirectDebitResponse',
              'MPPWcfServicesPublicBulkupdate.BulkUserManageDirectDebitResponse_element'}
            );
            response_x = response_map_x.get('response_x');
            return response_x.BulkUserManageDirectDebitResult;
        }
        public MPPBusinessObjectsIPaydev.BulkUpdateResultData BulkUserManage(Integer clientId,String apiPassword,MPPBusinessobjectsBulkupdate2.ArrayOfUserManageRequest userManageRequests,Boolean failOnFirstError) {
            MPPWcfServicesPublicBulkupdate.BulkUserManage_element request_x = new MPPWcfServicesPublicBulkupdate.BulkUserManage_element();
            MPPWcfServicesPublicBulkupdate.BulkUserManageResponse_element response_x;
            request_x.clientId = clientId;
            request_x.apiPassword = apiPassword;
            request_x.userManageRequests = userManageRequests;
            request_x.failOnFirstError = failOnFirstError;
            Map<String, MPPWcfServicesPublicBulkupdate.BulkUserManageResponse_element> response_map_x = new Map<String, MPPWcfServicesPublicBulkupdate.BulkUserManageResponse_element>();
            response_map_x.put('response_x', response_x);
            WebServiceCallout.invoke(
              this,
              request_x,
              response_map_x,
              new String[]{endpoint_x,
              'MppGlobal.WCFServices.Public.BulkUpdate.v7/BulkUpdate/BulkUserManage',
              'MppGlobal.WCFServices.Public.BulkUpdate.v7',
              'BulkUserManage',
              'MppGlobal.WCFServices.Public.BulkUpdate.v7',
              'BulkUserManageResponse',
              'MPPWcfServicesPublicBulkupdate.BulkUserManageResponse_element'}
            );
            response_x = response_map_x.get('response_x');
            return response_x.BulkUserManageResult;
        }
    }
    public class BulkAddDynamicPaymentSchedule_element {
        public Integer clientId;
        public String apiPassword;
        public MPPGlobalCoreDataContract.ArrayOfAddDynamicPaymentScheduleRequest addDynamicPaymentScheduleRequests;
        public Boolean failOnFirstError;
        private String[] clientId_type_info = new String[]{'clientId','http://www.w3.org/2001/XMLSchema','int','0','1','false'};
        private String[] apiPassword_type_info = new String[]{'apiPassword','http://www.w3.org/2001/XMLSchema','string','0','1','true'};
        private String[] addDynamicPaymentScheduleRequests_type_info = new String[]{'addDynamicPaymentScheduleRequests','MppGlobal.BusinessLogic.Core.DataContract.v7','ArrayOfAddDynamicPaymentScheduleRequest','0','1','true'};
        private String[] failOnFirstError_type_info = new String[]{'failOnFirstError','http://www.w3.org/2001/XMLSchema','boolean','0','1','false'};
        private String[] apex_schema_type_info = new String[]{'MppGlobal.WCFServices.Public.BulkUpdate.v7','true','false'};
        private String[] field_order_type_info = new String[]{'clientId','apiPassword','addDynamicPaymentScheduleRequests','failOnFirstError'};
    }
    public class BulkUserManage_element {
        public Integer clientId;
        public String apiPassword;
        public MPPBusinessobjectsBulkupdate2.ArrayOfUserManageRequest userManageRequests;
        public Boolean failOnFirstError;
        private String[] clientId_type_info = new String[]{'clientId','http://www.w3.org/2001/XMLSchema','int','0','1','false'};
        private String[] apiPassword_type_info = new String[]{'apiPassword','http://www.w3.org/2001/XMLSchema','string','0','1','true'};
        private String[] userManageRequests_type_info = new String[]{'userManageRequests','MppGlobal.iShop.BusinessObjects.BulkUpdate.DataContract.v4','ArrayOfUserManageRequest','0','1','true'};
        private String[] failOnFirstError_type_info = new String[]{'failOnFirstError','http://www.w3.org/2001/XMLSchema','boolean','0','1','false'};
        private String[] apex_schema_type_info = new String[]{'MppGlobal.WCFServices.Public.BulkUpdate.v7','true','false'};
        private String[] field_order_type_info = new String[]{'clientId','apiPassword','userManageRequests','failOnFirstError'};
    }
    public class BulkCancelPaymentScheduleResponse_element {
        public MPPBusinessObjectsIPaydev.BulkUpdateResultData BulkCancelPaymentScheduleResult;
        private String[] BulkCancelPaymentScheduleResult_type_info = new String[]{'BulkCancelPaymentScheduleResult','MppGlobal.iShop.BusinessObjects.iPayDeveloper.DataContract.v4','BulkUpdateResultData','0','1','true'};
        private String[] apex_schema_type_info = new String[]{'MppGlobal.WCFServices.Public.BulkUpdate.v7','true','false'};
        private String[] field_order_type_info = new String[]{'BulkCancelPaymentScheduleResult'};
    }
    public class BulkUserManageDirectDebit_element {
        public Integer clientId;
        public String apiPassword;
        public MPPGlobalCoreDataContract.ArrayOfUserManageDirectDebitRequest userManageDirectDebitRequests;
        public Boolean failOnFirstError;
        private String[] clientId_type_info = new String[]{'clientId','http://www.w3.org/2001/XMLSchema','int','0','1','false'};
        private String[] apiPassword_type_info = new String[]{'apiPassword','http://www.w3.org/2001/XMLSchema','string','0','1','true'};
        private String[] userManageDirectDebitRequests_type_info = new String[]{'userManageDirectDebitRequests','MppGlobal.BusinessLogic.Core.DataContract.v7','ArrayOfUserManageDirectDebitRequest','0','1','true'};
        private String[] failOnFirstError_type_info = new String[]{'failOnFirstError','http://www.w3.org/2001/XMLSchema','boolean','0','1','false'};
        private String[] apex_schema_type_info = new String[]{'MppGlobal.WCFServices.Public.BulkUpdate.v7','true','false'};
        private String[] field_order_type_info = new String[]{'clientId','apiPassword','userManageDirectDebitRequests','failOnFirstError'};
    }
    public class BulkUserManageResponse_element {
        public MPPBusinessObjectsIPaydev.BulkUpdateResultData BulkUserManageResult;
        private String[] BulkUserManageResult_type_info = new String[]{'BulkUserManageResult','MppGlobal.iShop.BusinessObjects.iPayDeveloper.DataContract.v4','BulkUpdateResultData','0','1','true'};
        private String[] apex_schema_type_info = new String[]{'MppGlobal.WCFServices.Public.BulkUpdate.v7','true','false'};
        private String[] field_order_type_info = new String[]{'BulkUserManageResult'};
    }
    public class BulkCancelPaymentSchedule_element {
        public Integer clientId;
        public String apiPassword;
        public MPPBusinessobjectsBulkupdate2.ArrayOfCancelPaymentScheduleRequest cancelPaymentScheduleRequests;
        public Boolean failOnFirstError;
        private String[] clientId_type_info = new String[]{'clientId','http://www.w3.org/2001/XMLSchema','int','0','1','false'};
        private String[] apiPassword_type_info = new String[]{'apiPassword','http://www.w3.org/2001/XMLSchema','string','0','1','true'};
        private String[] cancelPaymentScheduleRequests_type_info = new String[]{'cancelPaymentScheduleRequests','MppGlobal.iShop.BusinessObjects.BulkUpdate.DataContract.v4','ArrayOfCancelPaymentScheduleRequest','0','1','true'};
        private String[] failOnFirstError_type_info = new String[]{'failOnFirstError','http://www.w3.org/2001/XMLSchema','boolean','0','1','false'};
        private String[] apex_schema_type_info = new String[]{'MppGlobal.WCFServices.Public.BulkUpdate.v7','true','false'};
        private String[] field_order_type_info = new String[]{'clientId','apiPassword','cancelPaymentScheduleRequests','failOnFirstError'};
    }
}