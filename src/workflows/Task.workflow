<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Change_Scheduled_Time_on_busy</fullName>
        <field>Scheduled_Callback__c</field>
        <formula>Now() + 30/1440</formula>
        <name>Change Scheduled Time on busy</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Change_Scheduled_Time_on_not_or_answered</fullName>
        <field>Scheduled_Callback__c</field>
        <formula>Now() + 240/1440</formula>
        <name>Change Scheduled Time on not or answered</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Close_the_Task</fullName>
        <field>Status</field>
        <literalValue>Completed</literalValue>
        <name>Close the Task</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>NON DMC Call Busy</fullName>
        <actions>
            <name>Change_Scheduled_Time_on_busy</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Task.Outcome__c</field>
            <operation>equals</operation>
            <value>Busy</value>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>NON DMC Call Not%2FAnswered</fullName>
        <actions>
            <name>Change_Scheduled_Time_on_not_or_answered</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Task.Outcome__c</field>
            <operation>equals</operation>
            <value>No Answer,Answerphone</value>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>NON DMC Call Remove</fullName>
        <actions>
            <name>Close_the_Task</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Task.Outcome__c</field>
            <operation>equals</operation>
            <value>Sale,Wrong Number,Deceased,No Sale,Cheque Sales,Renewal Details Sent</value>
        </criteriaItems>
        <description>Remove record from call list when outcome is: 
wrong number, deceased, etc.</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
</Workflow>
