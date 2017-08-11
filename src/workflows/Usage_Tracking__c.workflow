<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>MaintainTalendUpsertKey</fullName>
        <description>Maintain the TalendUpsertKey</description>
        <field>TalendUpsertKey__c</field>
        <formula>Device_Unique_ID__c + Device_Operating_System__c + Device_Name__c + App_Name__c + App_Version__c + Account__c</formula>
        <name>MaintainTalendUpsertKey</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_First_Accessed_to_Last_Accessed</fullName>
        <description>Set the first accessed date to the last accessed date if the value is null.  When a record is newly created,  only the L.A.D. is supplied ,  so,  the F.A.D. will be null.  In this instance,  the 2 values should be the same</description>
        <field>First_Accessed_Date__c</field>
        <formula>Last_Accessed_Date__c</formula>
        <name>Set First Accessed to Last Accessed</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>First Access Data Is Null</fullName>
        <actions>
            <name>Set_First_Accessed_to_Last_Accessed</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Usage_Tracking__c.First_Accessed_Date__c</field>
            <operation>equals</operation>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>TalendUpsertKeyGeneration</fullName>
        <actions>
            <name>MaintainTalendUpsertKey</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>Maintain the TalendUpsertKey</description>
        <formula>ISNEW() || ISCHANGED( Device_Unique_ID__c ) || ISCHANGED( Device_Operating_System__c ) || ISCHANGED( Device_Name__c ) || ISCHANGED( App_Name__c ) || ISCHANGED( App_Version__c ) || ISCHANGED( Account__c )</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
