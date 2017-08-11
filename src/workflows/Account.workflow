<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Account_Address_Updated_Action</fullName>
        <description>This Workflow Action sets the Address Updated checkbox field to checked.</description>
        <field>Address_Updated__c</field>
        <literalValue>1</literalValue>
        <name>Account_Address_Updated_Action</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>POC_Value_Creation_Action</fullName>
        <description>This Workflow Action creates the POC field value. E.g. NNN (Campaign Code) + AA (Week No) + NNN (Creative Code) + NNNNNN (SRN)</description>
        <field>POC__c</field>
        <formula>If ( POC__c = &quot;&quot;, Campaign_Code__c &amp; Weekly_Number__c &amp; Creative_Code__c &amp; SRN__c, POC__c)</formula>
        <name>POC_Value_Creation_Action</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Populate_Unique_Email_Check</fullName>
        <description>Populates Unique_Email_Check__c field with PersonEmail value on person accounts.</description>
        <field>Unique_Email_Check__c</field>
        <formula>PersonEmail</formula>
        <name>Populate Unique Email Check</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Subscriber_Number_Static_Update</fullName>
        <description>assigns the subscriber_number__c to subsriber_number_static__c</description>
        <field>Subscriber_Number_static__c</field>
        <formula>IF( LEN( SRN__c ) &gt;= 7,
&quot;TS&quot; &amp; SRN__c,
&quot;TS&quot; &amp; LPAD( SRN__c , 7 , &quot;0&quot;)
)</formula>
        <name>Subscriber Number Static Update</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>TDT_Value_Creation_Action</fullName>
        <description>This Workflow Action creates the TDT field value. E.g. “TDT&quot; + Wave ID (NNNL) + LLL (First 3 Last Name Letters) + NNNN (SRN)
SB 7/12: Change to logic as per SMS-244</description>
        <field>TDT__c</field>
        <formula>If( TDT__c = &quot;&quot;,
    IF(LEN(LastName)  &gt;= 3, 
         Wave_ID__c &amp; UPPER(LEFT(LastName, 3)) &amp; RIGHT(SRN__c, 7),  
         IF(LEN(LastName)  = 2,
               Wave_ID__c &amp; UPPER(LEFT(LastName, 2)) &amp; &quot;X&quot; &amp; RIGHT(SRN__c, 7),  
               Wave_ID__c &amp; UPPER(LEFT(LastName, 2)) &amp; &quot;XX&quot; &amp; RIGHT(SRN__c, 7)
          )
    )
,
TDT__c)</formula>
        <name>TDT_Value_Creation_Action</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Account_Address_Updated</fullName>
        <actions>
            <name>Account_Address_Updated_Action</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>This Workflow Rule is used to set the Account Address Updated field to checked whenever the Shop or Voucher Address fields are edited so management can verify the changes.</description>
        <formula>OR(ISCHANGED(BillingStreet), ISCHANGED(BillingCity), ISCHANGED(BillingState), ISCHANGED(BillingPostalCode), ISCHANGED(BillingCountry), ISCHANGED(ShippingStreet), ISCHANGED(ShippingCity), ISCHANGED(ShippingState), ISCHANGED(ShippingPostalCode), ISCHANGED(ShippingCountry))</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>POC_Value_Creation_Rule</fullName>
        <actions>
            <name>POC_Value_Creation_Action</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>This Workflow Rule is used to generate a unique Subscriber POC field value.</description>
        <formula>True</formula>
        <triggerType>onCreateOnly</triggerType>
    </rules>
    <rules>
        <fullName>Populate_Unique_Email</fullName>
        <actions>
            <name>Populate_Unique_Email_Check</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>Copies PersonEmail field to unique custom field.</description>
        <formula>AND(IsPersonAccount, OR(ISBLANK(Unique_Email_Check__c), ISCHANGED(PersonEmail)))</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Subscriber Number Field update</fullName>
        <actions>
            <name>Subscriber_Number_Static_Update</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>assign SRN number to Subscriber_Number_Static__c</description>
        <formula>Subscriber_Number_static__c   =  &apos;&apos;</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>TDT_Value_Creation_Rule</fullName>
        <actions>
            <name>TDT_Value_Creation_Action</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>This Workflow Rule is used to generate a unique Subscriber TDT field value.</description>
        <formula>True</formula>
        <triggerType>onCreateOnly</triggerType>
    </rules>
</Workflow>
