<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>BTX_Channel_to_Contact_Centre</fullName>
        <field>Channel__c</field>
        <literalValue>Contact Centre</literalValue>
        <name>BTX Channel to Contact Centre</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>BTX_Channel_to_TCUK</fullName>
        <field>Channel__c</field>
        <literalValue>TCUK</literalValue>
        <name>BTX Channel to TCUK</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>BTX_Origin_to_Auto_Renewal</fullName>
        <field>Origin__c</field>
        <literalValue>Auto-Renewal</literalValue>
        <name>BTX Origin to Auto Renewal</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>true</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>BTX_Origin_to_Inbound</fullName>
        <field>Origin__c</field>
        <literalValue>Inbound</literalValue>
        <name>BTX Origin to Inbound</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>true</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>BTX_Origin_to_Online</fullName>
        <field>Origin__c</field>
        <literalValue>Online</literalValue>
        <name>BTX Origin to Online</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>true</reevaluateOnChange>
    </fieldUpdates>
    <rules>
        <fullName>Business Transaction Channel to Contact Centre</fullName>
        <actions>
            <name>BTX_Channel_to_Contact_Centre</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Business_Transaction__c.Origin__c</field>
            <operation>equals</operation>
            <value>Inbound</value>
        </criteriaItems>
        <description>Workflow that updates Business Transaction Channel field when Origin is Inbound.</description>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Business Transaction Channel to TCUK</fullName>
        <actions>
            <name>BTX_Channel_to_TCUK</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Business_Transaction__c.Origin__c</field>
            <operation>equals</operation>
            <value>Online</value>
        </criteriaItems>
        <description>Workflow that updates Business Transaction Channel field when Origin is Online.</description>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Business Transaction Origin to Auto Renewal</fullName>
        <actions>
            <name>BTX_Origin_to_Auto_Renewal</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>Workflow that updates Business Transaction Origin field when Status is Complete.</description>
        <formula>AND(OR(ISNEW(),ISCHANGED(Status__c)), ISPICKVAL(Status__c, &apos;Complete&apos;))</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Business Transaction Origin to Inbound</fullName>
        <actions>
            <name>BTX_Origin_to_Inbound</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>Workflow that updates Business Transaction Origin field when Status is Alternative and Agent Name is not blank or when Status is Discretionary.</description>
        <formula>AND(OR(
AND(ISPICKVAL(Status__c, &apos;Alternative&apos;), NOT(ISBLANK(Agent_Name__c))),
ISPICKVAL(Status__c, &apos;Discretionary&apos;)
)
)</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Business Transaction Origin to Online</fullName>
        <actions>
            <name>BTX_Origin_to_Online</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>Workflow that updates Business Transaction Origin field when Status is Alternative and Agent Name is blank..</description>
        <formula>AND(ISPICKVAL(Status__c, &apos;Alternative&apos;),  ISBLANK(Agent_Name__c))</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
