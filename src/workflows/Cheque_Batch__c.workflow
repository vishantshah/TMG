<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>Notify_manager_about_cheque_batch_closure</fullName>
        <description>Notify manager about cheque batch closure</description>
        <protected>false</protected>
        <recipients>
            <type>creator</type>
        </recipients>
        <recipients>
            <recipient>russell.gruber@telegraph.co.uk</recipient>
            <type>user</type>
        </recipients>
        <senderType>DefaultWorkflowUser</senderType>
        <template>Voucher_Activity_Email_Templates/Holiday_Voucher_Refund_Cheque_Batch_Closure_Notification</template>
    </alerts>
    <fieldUpdates>
        <fullName>Update_Cheque_Batch_Index</fullName>
        <description>Update Cheque Batch Index Field with Batch Closing date and Payslip Ref Number if Voucher refund, otherwise update with Record Id to make sure the value is unique</description>
        <field>Index__c</field>
        <formula>IF(Payment_Slip_Ref_Number__c = &quot;Holiday Voucher Refund&quot;, Payment_Slip_Ref_Number__c +  TEXT(Batch_Closed_Date__c),  Id )</formula>
        <name>Update Cheque Batch Index</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Holiday Voucher Refund Cheque Batch Update</fullName>
        <actions>
            <name>Update_Cheque_Batch_Index</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>Update values on Holiday Vouche refund Cheque Batch</description>
        <formula>true</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Holiday Voucher Refund Closure</fullName>
        <actions>
            <name>Notify_manager_about_cheque_batch_closure</name>
            <type>Alert</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Cheque_Batch__c.Batch_Closed_Date__c</field>
            <operation>notEqual</operation>
        </criteriaItems>
        <criteriaItems>
            <field>Cheque_Batch__c.RecordTypeId</field>
            <operation>equals</operation>
            <value>Voucher Refund Cheque Batch</value>
        </criteriaItems>
        <description>Workflow which is triggered once Closed Date is populated for Holiday Voucher Refund  Cheque Batch records</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
</Workflow>
