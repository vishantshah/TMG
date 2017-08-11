/**
* Author:       Pawel Chrzanowski
* Date:         09/03/2017
* Description:  Controller Extension for NewCaseRedirect page
* ******************* Change Log *******************
* Modified by           Change Date
* Pawel Chrzanowski     04/04/2017  modified redirectUser()
* Vishant Shah          28/06/2017  refactored to make code more readable 
                                    and added support to go to customcase page if not OC recordtype.
**/
public class NewCaseRedirectExtension {
 
    private static final String PARAM_RECORDTYPE = 'RecordType';
    private static final String PARAM_RETURL = 'retURL';
    private static final String PARAM_SAVENEWURL = 'save_new_url';
    private static final String PARAM_NOOVERRIDE = 'nooverride';
    private static final String PARAM_SAVENEW = 'save_new';
    private static final String PARAM_ENT = 'ent';
    private static final String PARAM_CACHING = 'scontrolCaching';
    private static final String PARAM_OVERRIDE = 'sfdc.override';
    private static final String PAGE_RECORDTYPESELECT = '/setup/ui/recordtypeselect.jsp';
    private static final String CUSTOM_CASE = '/apex/CustomCase';

    /***************************************************************************************
    Developer   Pawel Chrzanowski
    Date        09/03/2017
    Constructor
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    public NewCaseRedirectExtension(ApexPages.StandardController stdController){}
    
    /***************************************************************************************
    Developer   Pawel Chrzanowski
    Date        09/03/2017
    Page Action
    ******************* Change Log *******************
    Modified by         Change Date
    Pawel Chrzanowski   04/04/2017  added support for extra parameters
    Vishant Shah        28/06/2017  refactored and added support to go to customcase page if not OC recordtype.
    ****************************************************************************************/
    public PageReference redirectUser(){
        Map<String, String> mapAllParams = ApexPages.currentPage().getParameters();
        String casePrefix                = '/' + Case.sObjectType.getDescribe().getKeyPrefix() + '/e';
        String returnURL                 = '%2F' + Case.sObjectType.getDescribe().getKeyPrefix() + '%2Fo';
        PageReference pr;
        
        //redirect User arriving from Record Type selection page
        if(mapAllParams.containsKey(PARAM_RECORDTYPE) && String.isNotBlank(mapAllParams.get(PARAM_RECORDTYPE))){
            Id recTypeId  = Id.valueOf(mapAllParams.get(PARAM_RECORDTYPE));


            String recordtypeName =  RecordTypeUtility.getRecordTypeName(Case.SObjectType, recTypeId, 'Case');

            List<Case_Layout_Definition__mdt> layoutsDefinitions = [SELECT Record_Type_Name__c FROM Case_Layout_Definition__mdt WHERE Record_Type_Name__c = :recordtypeName];

            if( layoutsDefinitions.size() == 0)
                pr = new PageReference(casePrefix);
            else
                pr = new PageReference(CUSTOM_CASE);
            
            Custom_Validation_Bypass__c cvb = Custom_Validation_Bypass__c.getInstance(UserInfo.getUserId() );

            if (cvb.Bypass_Custom_Validation_Rule__c){
                pr = new PageReference(casePrefix );
            }

            pr.getParameters().put(PARAM_ENT, Case.class.getName());
            pr.getParameters().put(PARAM_RETURL, returnURL);
            pr.getParameters().put(PARAM_RECORDTYPE, mapAllParams.get(PARAM_RECORDTYPE));
            pr.getParameters().put(PARAM_NOOVERRIDE, '1');

            for(String key : mapAllParams.keySet()){
                if(key != PARAM_CACHING && key != PARAM_OVERRIDE && key != PARAM_SAVENEW && key != PARAM_RECORDTYPE && String.isNotBlank(mapAllParams.get(key))){
                    pr.getParameters().put(key, mapAllParams.get(key));
                }
            }

            return pr;
        }
        
        //redirect User based on Department
        User u = [SELECT Department FROM User WHERE Id = :UserInfo.getUserId()];
        if(String.isNotBlank(u.Department)){
            Boolean hasDepartment = false;
            String recordTypeId;

            if(u.Department == Constants.USER_DEPARTMENT_DIGITALSERVICES){
                recordTypeId = RecordTypeUtility.getRecordTypeId(Case.SObjectType, Constants.CASE_RECORDTYPE_DIGITALSERVICES, Case.class.getName());
                hasDepartment = true;
            }
            if(u.Department == Constants.USER_DEPARTMENT_SALESANDCUSTOMEREXPERIENCE){
                recordTypeId = RecordTypeUtility.getRecordTypeId(Case.SObjectType, Constants.CASE_RECORDTYPE_GENERALENQUIRY, Case.class.getName());
                hasDepartment = true;
            }
            
            if(hasDepartment){
                Custom_Validation_Bypass__c cvb = Custom_Validation_Bypass__c.getInstance(UserInfo.getUserId() );

                if (cvb.Bypass_Custom_Validation_Rule__c){
                    pr = new PageReference(casePrefix);
                } else {
                    pr = new PageReference(CUSTOM_CASE);
                }

                pr.getParameters().put(PARAM_ENT, Case.class.getName());
                pr.getParameters().put(PARAM_RETURL, returnURL);
                pr.getParameters().put(PARAM_RECORDTYPE, recordTypeId);
                pr.getParameters().put(PARAM_NOOVERRIDE, '1');

                for(String key : mapAllParams.keySet()){
                    if(key != PARAM_CACHING && key != PARAM_OVERRIDE && key != PARAM_SAVENEW && String.isNotBlank(mapAllParams.get(key))){
                        pr.getParameters().put(key, mapAllParams.get(key));
                    }
                }
                return pr;
            }
        }
        
        //redirect User to Record Type selection page
        pr = new PageReference(PAGE_RECORDTYPESELECT);
        pr.getParameters().put(PARAM_ENT, Case.class.getName());
        if(mapAllParams.containsKey(PARAM_RETURL) && String.isNotBlank(mapAllParams.get(PARAM_RETURL))){
            pr.getParameters().put(PARAM_RETURL, mapAllParams.get(PARAM_RETURL));
        }
        
        PageReference prSaveNew = Page.NewCaseRedirect;
        for(String key : mapAllParams.keySet()){
            if(String.isNotBlank(mapAllParams.get(key))){
                prSaveNew.getParameters().put(key, mapAllParams.get(key));
            }
        }
        pr.getParameters().put(PARAM_SAVENEWURL, prSaveNew.getUrl());
        return pr;
    }
}