<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Check_FLAGS_Enable_Case_Flags</fullName>
        <field>FLAGS__Enable_Case_Flags__c</field>
        <literalValue>1</literalValue>
        <name>Check FLAGS Enable Case Flags</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>true</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Complete_OC_Case</fullName>
        <description>Updated Case Status to Completed</description>
        <field>Status</field>
        <literalValue>Completed</literalValue>
        <name>Complete OC Case</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Complete_OC_Case_DDCX</fullName>
        <description>Updated Case Status to Completed</description>
        <field>Status</field>
        <literalValue>Completed</literalValue>
        <name>Complete OC Case DDCX</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>IncrementNoOfTimesRescheduledby1</fullName>
        <description>Increment No Of Times Rescheduled by 1</description>
        <field>Number_Of_Times_Rescheduled__c</field>
        <formula>IF(ISNULL(Number_Of_Times_Rescheduled__c), 1, Number_Of_Times_Rescheduled__c + 1)</formula>
        <name>Increment No Of Times Rescheduled by 1</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Retention_CC_assignment</fullName>
        <description>Change owner of the case to retention CC queue</description>
        <field>OwnerId</field>
        <lookupValue>Retention_Card</lookupValue>
        <lookupValueType>Queue</lookupValueType>
        <name>Retention CC assignment</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>LookupValue</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_FLAGS_Flag_to_Now</fullName>
        <field>FLAGS__ViewedFlag__c</field>
        <formula>NOW()</formula>
        <name>Set FLAGS Flag to Now</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <reevaluateOnChange>true</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_Spam_Email_Record_Type</fullName>
        <description>Update the spam email record type to &quot;Spam Email&quot;</description>
        <field>RecordTypeId</field>
        <lookupValue>Spam_Email</lookupValue>
        <lookupValueType>RecordType</lookupValueType>
        <name>Update Spam Email Record Type</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>LookupValue</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Case Move to Retention Card Queue</fullName>
        <actions>
            <name>Retention_CC_assignment</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Case.Status</field>
            <operation>equals</operation>
            <value>New</value>
        </criteriaItems>
        <criteriaItems>
            <field>Case.Type_Of_Issue__c</field>
            <operation>equals</operation>
            <value>Failed Card Recurring Payment</value>
        </criteriaItems>
        <description>Case Move to Retention Card Queue after 2nd fail</description>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Close DD Cancellation Case</fullName>
        <actions>
            <name>Complete_OC_Case_DDCX</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Case.DD_Cancellation_Outcome__c</field>
            <operation>equals</operation>
            <value>Sale,Wrong Number,Deceased,No Sale,Cheque Sales,NATC</value>
        </criteriaItems>
        <description>Automatically set case status to Closed when outcome is: Wrong number, Deceased etc.</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>Close DD Winback Case</fullName>
        <actions>
            <name>Complete_OC_Case</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Case.DD_Winback_Outcome__c</field>
            <operation>equals</operation>
            <value>Sale,Wrong Number,Deceased,No Sale,Cheque Sales,NATC</value>
        </criteriaItems>
        <description>Automatically set case status to Closed when outcome is: Wrong number, Deceased etc.</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>Close Outbound Calling Case</fullName>
        <actions>
            <name>Complete_OC_Case</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Case.OC_Outcome__c</field>
            <operation>equals</operation>
            <value>Sale,Wrong Number,Deceased,No Sale,Cheque Sales,Call Completed</value>
        </criteriaItems>
        <description>Automatically set OC case status to Closed when outcome is: Wrong number, Deceased etc.</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>FLAGS managed package activation</fullName>
        <actions>
            <name>Check_FLAGS_Enable_Case_Flags</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>Set_FLAGS_Flag_to_Now</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Case.RecordTypeId</field>
            <operation>notEqual</operation>
            <value>Outbound Calling (Retention),Outbound Calling (DD Cancellation),Outbound Calling (DD Winback),Outbound Calling (Direct Debit),Outbound Calling (Balance Review),Outbound Calling (Credit Card Expiry),Outbound Calling (Sales)</value>
        </criteriaItems>
        <description>Workflow that limits the case records that should be processed by CASE FLAGS managed package.</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>Increment No Times Rescheduled by 1</fullName>
        <actions>
            <name>IncrementNoOfTimesRescheduledby1</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>When a &apos;Future Action Date&apos; is re-scheduled for the future, increment the &apos;No of Times Rescheduled&apos; field by 1.</description>
        <formula>ISCHANGED( Future_Action_Date__c)</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Reactivate Case Flag</fullName>
        <actions>
            <name>Check_FLAGS_Enable_Case_Flags</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>Set_FLAGS_Flag_to_Now</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Case.FLAGS__ViewedFlag__c</field>
            <operation>equals</operation>
        </criteriaItems>
        <criteriaItems>
            <field>Case.Status</field>
            <operation>equals</operation>
            <value>In Progress,Awaiting Response,Escalated</value>
        </criteriaItems>
        <criteriaItems>
            <field>Case.RecordTypeId</field>
            <operation>notEqual</operation>
            <value>Outbound Calling (Retention),Outbound Calling (DD Cancellation),Outbound Calling (DD Winback),Outbound Calling (Direct Debit),Outbound Calling (Balance Review),Outbound Calling (Credit Card Expiry),Outbound Calling (Sales)</value>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>Update Spam Email Record Type</fullName>
        <actions>
            <name>Update_Spam_Email_Record_Type</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Case.OwnerId</field>
            <operation>equals</operation>
            <value>Spam Email</value>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
</Workflow>
