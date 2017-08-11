/**
* Author:       Michal Szewczyk
* Date:         26/07/2016
* Description:  Controller for OutboundCallMenu component
*
* ******************* Change Log *******************
* Modified by           Change Date
**/
public with sharing class OutboundCallMenuController {
	
	public List<Outbound_Call_Setting__c> menuParams{get;set;}

    /************************************************************************************
    Developer - Michal Szewczyk
    Date - 26/07/2016
    Version - 1.0
    Function - class constructor
    #############Change Log#############
    Modified by         Version     Change Date
    *************************************************************************************/
	public OutboundCallMenuController() {
		menuParams = [SELECT Id, Menu_Name__c, Visualforce_Page__c, Icon_Image_Resource_Name__c FROM Outbound_Call_Setting__c WHERE Active__c = true ORDER BY Order__c];
	}

}