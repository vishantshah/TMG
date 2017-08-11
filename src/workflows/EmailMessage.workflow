<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Close_Case</fullName>
        <field>Status</field>
        <literalValue>Closed</literalValue>
        <name>Close Case</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <targetObject>ParentId</targetObject>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_Case_Flag</fullName>
        <field>FLAGS__ViewedFlag__c</field>
        <formula>NOW()</formula>
        <name>Set Case Flag</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <targetObject>ParentId</targetObject>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_Case_Status_Email_Received</fullName>
        <description>Sets case status to Email Received</description>
        <field>Status</field>
        <literalValue>Email Received</literalValue>
        <name>Set Case Status Email Received</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <targetObject>ParentId</targetObject>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_Case_Status_To_In_Progress</fullName>
        <field>Status</field>
        <literalValue>In Progress</literalValue>
        <name>Set Case Status To In Progress</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <targetObject>ParentId</targetObject>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_Enable_Case_Flag</fullName>
        <field>FLAGS__Enable_Case_Flags__c</field>
        <literalValue>1</literalValue>
        <name>Set Enable Case Flag</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <targetObject>ParentId</targetObject>
    </fieldUpdates>
    <rules>
        <fullName>Close Case After Email Sent</fullName>
        <actions>
            <name>Close_Case</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <booleanFilter>1 AND 2 AND 3 AND 4 AND 5 AND 6 AND 7</booleanFilter>
        <criteriaItems>
            <field>EmailMessage.Status</field>
            <operation>equals</operation>
            <value>Sent</value>
        </criteriaItems>
        <criteriaItems>
            <field>EmailMessage.Subject</field>
            <operation>notContain</operation>
            <value>Case#:</value>
        </criteriaItems>
        <criteriaItems>
            <field>EmailMessage.FromAddress</field>
            <operation>notEqual</operation>
            <value>customerservice+support@telegraph.co.uk</value>
        </criteriaItems>
        <criteriaItems>
            <field>EmailMessage.FromAddress</field>
            <operation>notEqual</operation>
            <value>digitalservices+support@telegraph.co.uk</value>
        </criteriaItems>
        <criteriaItems>
            <field>EmailMessage.FromAddress</field>
            <operation>notEqual</operation>
            <value>appfeedback+support@telegraph.co.uk</value>
        </criteriaItems>
        <criteriaItems>
            <field>Case.Reason</field>
            <operation>notContain</operation>
            <value>Voucher Enquiry</value>
        </criteriaItems>
        <criteriaItems>
            <field>Case.Subject</field>
            <operation>notEqual</operation>
            <value>Delayed Refund</value>
        </criteriaItems>
        <description>Close the case after an email is sent from the case. The second condition relates is to stop the auto response rule from firing and auto closing the case</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>Reopen Closed Case After New Email Received</fullName>
        <actions>
            <name>Set_Case_Flag</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>Set_Case_Status_Email_Received</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>Set_Enable_Case_Flag</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>EmailMessage.Status</field>
            <operation>equals</operation>
            <value>New</value>
        </criteriaItems>
        <criteriaItems>
            <field>Case.Status</field>
            <operation>equals</operation>
            <value>Closed</value>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
</Workflow>
