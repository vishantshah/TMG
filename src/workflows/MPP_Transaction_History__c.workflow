<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Payment_Date_Today</fullName>
        <field>Payment_Date__c</field>
        <formula>NOW()</formula>
        <name>Payment Date Today</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Payment_Status_Success</fullName>
        <field>Payment_status__c</field>
        <literalValue>Success</literalValue>
        <name>Payment Status Success</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Transaction_History_Update_Product_Name</fullName>
        <description>If account related product is NOT print then digital, else print. Logic built this way because transaction histories are not always linked to subscription records, which prevents from checking if product is print.</description>
        <field>Product_name__c</field>
        <formula>IF( 
   OR(Subscriber__r.RecordType.Name = &apos;Individual Subscriber&apos;,
      Subscriber__r.RecordType.Name = &apos;School&apos;
   ),
   &quot;Print&quot;,
   &quot;Digital&quot;
)</formula>
        <name>Transaction History: Update Product Name</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Transaction History%3A Update DD Payment Status</fullName>
        <active>true</active>
        <criteriaItems>
            <field>MPP_Transaction_History__c.Payment_Type__c</field>
            <operation>equals</operation>
            <value>DirectDebit</value>
        </criteriaItems>
        <criteriaItems>
            <field>MPP_Transaction_History__c.Payment_status__c</field>
            <operation>equals</operation>
            <value>Pending</value>
        </criteriaItems>
        <criteriaItems>
            <field>MPP_Transaction_History__c.DD_Transaction_Type__c</field>
            <operation>equals</operation>
            <value>Payment</value>
        </criteriaItems>
        <triggerType>onCreateOnly</triggerType>
        <workflowTimeTriggers>
            <actions>
                <name>Payment_Date_Today</name>
                <type>FieldUpdate</type>
            </actions>
            <actions>
                <name>Payment_Status_Success</name>
                <type>FieldUpdate</type>
            </actions>
            <offsetFromField>MPP_Transaction_History__c.Payment_Submission_Date__c</offsetFromField>
            <timeLength>0</timeLength>
            <workflowTimeTriggerUnit>Days</workflowTimeTriggerUnit>
        </workflowTimeTriggers>
    </rules>
    <rules>
        <fullName>Transaction History%3A Update Product Name</fullName>
        <actions>
            <name>Transaction_History_Update_Product_Name</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <formula>OR(NOT(ISBLANK( Subscriber__c )), NOT(ISBLANK( Subscription__c )))</formula>
        <triggerType>onCreateOnly</triggerType>
    </rules>
</Workflow>
