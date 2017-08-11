/**
* @author Pawel Chrzanowski
* @date 14/09/2016
* @description Controller extension to generate custom report url
#############Change Log#############
Modified by        Version    Change Date
Pawel Chrzanowski  1.1        07/10/2016  Added second report
Pawel Chrzanowski  1.2        08/11/2016  Added Outstanding Cases report
Vishant Shah       1.3        06/06/2017  Refactored class to be dynamic, instead of using hardcoded reports.
**/
public class CasesByCallStageReport {

    public Component.Apex.OutputPanel outputPanel { get; set; }

    /*************************************************************************************** 
    Developer - Pawel Chrzanowski
    Date - 14/09/2016
    Function - Constructor
    #############Change Log#############
    Modified by        Version    Change Date
    Pawel Chrzanowski  1.1        07/10/2016  Added second report
	Pawel Chrzanowski  1.2        08/11/2016  Added Outstanding Cases report
    Vishant Shah       1.3        06/06/2017  refactored class to be dynamic, instead of using hardcoded reports. 
    ****************************************************************************************/
    public CasesByCallStageReport(ApexPages.StandardController controller){
        Id recordId = controller.getId();
        List<Outbound_Call_Setting__c> lstOCSettings = [SELECT Case_Record_Type__c, Reports__c FROM Outbound_Call_Setting__c WHERE Id = :recordId];
        if(lstOCSettings.isEmpty()) return;
   

        List<String> reports = (List<String>)JSON.deserialize(lstOCSettings[0].Reports__c, List<String>.class);
        Map<Id, String> reportIdList = new Map<Id, String>();

        Id rtId = RecordTypeUtility.getRecordTypeId(Case.SObjectType, lstOCSettings[0].Case_Record_Type__c, Case.class.getName());

        outputPanel = new Component.Apex.OutputPanel();
        
        for (Report report : [SELECT Id, Description FROM Report WHERE DeveloperName IN :reports ]){

            Id reportId = report.Id;

            String reportUrl = '/' + reportId + '?pv0=' + String.valueOf(rtId).substring(0,15);
            
            Component.Apex.OutputPanel innerPanel  = new Component.Apex.OutputPanel();
            Component.Apex.OutputPanel innerPanel0 = new Component.Apex.OutputPanel();
            Component.Apex.OutputPanel innerPanel1 = new Component.Apex.OutputPanel();
            Component.Apex.OutputText html1        = new Component.Apex.OutputText(); 
            Component.Apex.OutputText html2Start   = new Component.Apex.OutputText(); 
            Component.Apex.OutputText html2End     = new Component.Apex.OutputText();
            Component.Apex.OutputText description  = new Component.Apex.OutputText();

            if (report.Description != null){
                description.value = '<b>' + report.Description + '</b>';
            } else {
                description.value = '<b> &nbsp; </b>';
            }
            
            description.escape = false;
            innerPanel1.childComponents.add(description);

            html1.value = '<a href="'+ reportUrl + '" target="_blank"><div style="width:500px;height:390px;z-index:100;top:20px;left:0;position:absolute;"></div></a>';               
            html1.escape = false;
            innerPanel1.childComponents.add(html1);

            html2Start.value = '<div style="z-index:1;position:absolute;top:20px;left:0;">';               
            html2Start.escape = false;

            html2End.value = '</div>';               
            html2End.escape = false;

            innerPanel0.childComponents.add(html2Start);
            innerPanel0.childComponents.add(new Component.Analytics.ReportChart(reportId=reportId,size='medium',cacheResults=false,hideOnError=false,rendered=true,showRefreshButton=true));
            innerPanel0.childComponents.add(html2End);
            
            innerPanel.styleClass = 'blockOutputPanel';
            innerPanel.childComponents.add(innerPanel1);
            innerPanel.childComponents.add(innerPanel0);

            outputPanel.childComponents.add(innerPanel);
        }
    }

}