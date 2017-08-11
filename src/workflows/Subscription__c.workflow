<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>CancellationDatedelete</fullName>
        <field>Cancellation_Date__c</field>
        <name>Cancellation Date delete</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Null</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>CancellationMethoddelete</fullName>
        <field>Cancellation_Method__c</field>
        <name>Cancellation Method delete</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>CancellationReasondelete</fullName>
        <field>Cancellation_Reason__c</field>
        <name>Cancellation Reason delete</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>CurrentPackFinaldelete</fullName>
        <field>Current_Pack_Position_Final__c</field>
        <name>Current Pack Final delete</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Null</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>CurrentWeekPosistiondelete</fullName>
        <field>Current_Week_Position_Final__c</field>
        <name>Current Week Posistion delete</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Null</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Force_Entitlements_Update</fullName>
        <field>Force_Entitlement_Update__c</field>
        <literalValue>1</literalValue>
        <name>Force Entitlements Update</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <targetObject>Subscriber__c</targetObject>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>LastStatusChangedateupdate</fullName>
        <field>Last_Status_Change__c</field>
        <formula>today()</formula>
        <name>Last Status Change date update</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>NumberofVoucherResends</fullName>
        <field>Number_of_Voucher_Resends__c</field>
        <formula>NULLVALUE( Number_of_Voucher_Resends__c, 0)+1</formula>
        <name>Number of Voucher Resends</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Outstanding_Balance_Goodwill</fullName>
        <description>This Field Update Rule adds the calculated Goodwill to the Outstanding Balance Voucher Adjustment field when a new Goodwill Voucher Adjustment record is created.</description>
        <field>Outstanding_Balance_Voucher_Adjustment__c</field>
        <formula>Outstanding_Balance_Voucher_Adjustment__c + (Voucher_Resend_Number__c * ((Weekly_Price__c / 7) + ((Discount__c / Subscription_Duration_Number__c)/7)))</formula>
        <name>Outstanding_Balance_Goodwill</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Outstanding_Balance_Holiday_Return</fullName>
        <description>This Field Update Rule adds the calculated Holiday Return value to the Outstanding Balance Voucher Adjustment field when a new Holiday Return Adjustment record is created.</description>
        <field>Outstanding_Balance_Voucher_Adjustment__c</field>
        <formula>Outstanding_Balance_Voucher_Adjustment__c + (Voucher_Resend_Number__c * ((Weekly_Price__c / 7) + ((Discount__c / Subscription_Duration_Number__c)/7)))</formula>
        <name>Outstanding_Balance_Holiday_Return</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Outstanding_Balance_Voucher_Return</fullName>
        <description>This Field Update Rule adds the calculated Voucher Return value to the Outstanding Balance Voucher Adjustment field when a new Voucher Return Adjustment record is created.</description>
        <field>Outstanding_Balance_Voucher_Adjustment__c</field>
        <formula>Outstanding_Balance_Voucher_Adjustment__c + (Voucher_Resend_Number__c * ((Weekly_Price__c / 7) + ((Discount__c / Subscription_Duration_Number__c)/7)))</formula>
        <name>Outstanding_Balance_Voucher_Return</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Paid_Until_Calculated_Field_Update</fullName>
        <field>Paid_Until_Calculated__c</field>
        <formula>IF(
  OR(
    ISBLANK(Subscription_Duration_Number__c),
    Subscription_Duration_Number__c = 0,
    AND((Total_of_All_Payments__c + SumOfVoucherReceivedRefundDue__c + BLANKVALUE(Revenue_Write_off_Amount__c, 0) + Sum_of_Processed_Holiday_Return_Vouchers__c) - DD_Not_Completed_Payments_Sum__c = 0, Weekly_Price__c != 0),
    ISBLANK(Weekly_Price__c)
  ),
  Start_Date__c,
  IF(
    Weekly_Price__c = 0,
    End_Date__c,
    IF(
      AND(
        NOT(ISBLANK(Low_Start_Period__c)),
        NOT(ISBLANK(Low_Start_Weekly_Price__c)),
        Low_Start_Period__c != 0,
        Low_Start_Weekly_Price__c != 0
      ),
      IF(
        ((Total_of_All_Payments__c + SumOfVoucherReceivedRefundDue__c + BLANKVALUE(Revenue_Write_off_Amount__c, 0) + Sum_of_Processed_Holiday_Return_Vouchers__c) - DD_Not_Completed_Payments_Sum__c) &gt; LowStartTotalPrice__c,

        Start_Date__c +CEILING((Low_Start_Period__c * 7) + ((((Total_of_All_Payments__c + SumOfVoucherReceivedRefundDue__c + BLANKVALUE(Revenue_Write_off_Amount__c, 0) + Sum_of_Processed_Holiday_Return_Vouchers__c) - DD_Not_Completed_Payments_Sum__c) - LowStartTotalPrice__c) / (Total_Price__c - LowStartTotalPrice__c) * 7 * (Subscription_Duration_Number__c - Low_Start_Period__c))),
        
        Start_Date__c + CEILING(((((Total_of_All_Payments__c + SumOfVoucherReceivedRefundDue__c + BLANKVALUE(Revenue_Write_off_Amount__c, 0) + Sum_of_Processed_Holiday_Return_Vouchers__c) - DD_Not_Completed_Payments_Sum__c) / LowStartTotalPrice__c) * 7 * Low_Start_Period__c))
      ),
      Start_Date__c + CEILING(((((Total_of_All_Payments__c + SumOfVoucherReceivedRefundDue__c + BLANKVALUE(Revenue_Write_off_Amount__c, 0) + Sum_of_Processed_Holiday_Return_Vouchers__c) - DD_Not_Completed_Payments_Sum__c) / Total_Price__c )* 7 * Subscription_Duration_Number__c))
    )
  )
)</formula>
        <name>Paid Until Calculated Field Update</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>R1StatusUpdate</fullName>
        <field>Renewal_Status__c</field>
        <literalValue>R1 Sent</literalValue>
        <name>R1 Status Update</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>R2FieldUpdate</fullName>
        <field>Renewal_Status__c</field>
        <literalValue>R2 Sent</literalValue>
        <name>R2 Field Update</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>R3RenewalStatusUpdate</fullName>
        <field>Renewal_Status__c</field>
        <literalValue>R3 Sent</literalValue>
        <name>R3 Renewal Status Update</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_First_Class_Postage_value_to_TRUE</fullName>
        <field>Requires_First_Class_Postage_for_Renewal__c</field>
        <literalValue>1</literalValue>
        <name>Set First Class Postage value to TRUE</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_Send_Loyalty_to_No</fullName>
        <field>Send_Loyalty__c</field>
        <literalValue>No</literalValue>
        <name>Set Send Loyalty to No</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_Send_Loyalty_to_Yes</fullName>
        <field>Send_Loyalty__c</field>
        <literalValue>Yes</literalValue>
        <name>Set Send Loyalty to Yes</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Subscription_Status_Lock_All_Fields</fullName>
        <description>This Workflow Action sets the Lock All Fields field to checked.</description>
        <field>Lock_All_Fields__c</field>
        <literalValue>1</literalValue>
        <name>Subscription_Status_Lock_All_Fields</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>UpdateCurrentPackPositionFinal</fullName>
        <field>Current_Pack_Position_Final__c</field>
        <formula>if(Current_Pack_Position__c&lt;0,0,Current_Pack_Position__c)</formula>
        <name>Update Current Pack Position Final</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>UpdateCurrentWeekPositionFinal</fullName>
        <description>SB 27/11: Old:
if(Current_Week_Position__c&lt;0,0,Current_Week_Position__c)</description>
        <field>Current_Week_Position_Final__c</field>
        <formula>IF(
	OR(ISPICKVAL(Subscription_Status__c, &quot;Pending Cancellation&quot;),ISPICKVAL(Subscription_Status__c, &quot;Cancelled&quot;)),
CEILING((Cancellation_Date__c - Start_Date__c) / 7),
	IF(Current_Week_Position__c&lt;=0,
		0,
		IF(NOT(ISBLANK(Current_Week_Position_Final__c)),
			Current_Week_Position_Final__c,
			CEILING((TODAY() - Start_Date__c - 1)/7)
		)
	)
)</formula>
        <name>Update Current Week Position Final</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>UpdateKey</fullName>
        <field>Synthesis_Key__c</field>
        <formula>TDT__c + IF(LEN(text( DAY(Start_Date__c)))=1,&quot;0&quot;+text( DAY(Start_Date__c)),text(DAY(Start_Date__c)))+&quot;/&quot;+ IF(LEN(text( MONTH(Start_Date__c)))=1,&quot;0&quot;+text( MONTH(Start_Date__c)),text(MONTH(Start_Date__c)))+&quot;/&quot;+text(year(Start_Date__c))</formula>
        <name>Update Key</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_Week_Pos_Final_to_Duration</fullName>
        <description>Updates current week pos final to duration</description>
        <field>Current_Week_Position_Final__c</field>
        <formula>Subscription_Duration_Number__c</formula>
        <name>Update Week Pos Final to Duration</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>VoucherExtractionDatecalc</fullName>
        <field>Voucher_Resend_Extraction_Date__c</field>
        <formula>Voucher_Resend_Extraction_Date_Calc__c</formula>
        <name>Voucher Extraction Date calc</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Voucher_Adjustment_Halt_Workflow</fullName>
        <description>This Field Update Action will reset the Voucher Adjustment Reason field back to its previous value after a Goodwill, Voucher Return or Holiday Return Voucher Adjustment record has been created.</description>
        <field>Voucher_Adjustment_Reason__c</field>
        <formula>Voucher_Adjustment_Reason__c &amp; &quot;.&quot;</formula>
        <name>Voucher_Adjustment_Halt_Workflow</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Zero_Final_Week_Pos</fullName>
        <field>Cur_Week_Pos_Final_Text_Hidden__c</field>
        <formula>&quot;0&quot;</formula>
        <name>Zero Final Week Pos</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Zero_Value_Final_Week_Pos</fullName>
        <description>Sets final week position to 0</description>
        <field>Current_Week_Position_Final__c</field>
        <formula>0</formula>
        <name>Zero Value Final Week Pos</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Clear Canx Reason%2C Method%2C Date</fullName>
        <actions>
            <name>CancellationDatedelete</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>CancellationMethoddelete</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>CancellationReasondelete</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>Clears the cancellation reason, method and date when status is changed from pending canx to anything but Cancelled</description>
        <formula>AND( ISCHANGED(Subscription_Status__c) ,ispickval( PRIORVALUE( Subscription_Status__c ) ,&apos;Pending Cancellation&apos;), NOT(ISPICKVAL(Subscription_Status__c, &apos;Cancelled&apos;)) )</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Clear Pack Final%2C Week Pos Final</fullName>
        <actions>
            <name>CurrentPackFinaldelete</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>CurrentWeekPosistiondelete</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>Clears Current Pack pos Final and Current Week pos final when status is changed from pending canx to anything but Cancelled or Lapsed.</description>
        <formula>AND(Ispickval (PRIORVALUE( Subscription_Status__c ), &apos;Pending Cancellation&apos;), IF(Ispickval(Subscription_Status__c, &apos;Cancelled&apos;), FALSE, IF(Ispickval(Subscription_Status__c, &apos;Lapsed&apos;), FALSE, IF(Ispickval(Subscription_Status__c, &apos;Pending Cancellation&apos;), FALSE,  TRUE))))</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Final Week Pos Update</fullName>
        <actions>
            <name>Force_Entitlements_Update</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>UpdateCurrentWeekPositionFinal</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>Updates the final week position if the cancellation date is changed.</description>
        <formula>AND(OR(ISPICKVAL(Subscription_Status__c, &quot;Pending Cancellation&quot;), ISPICKVAL(Subscription_Status__c, &quot;Cancelled&quot;)) , Cancellation_Date__c &lt;= Today())</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>If renewal is taken out -23 days before start date then set First Class Postage flag</fullName>
        <actions>
            <name>Set_First_Class_Postage_value_to_TRUE</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>DM 28/03/14 - If a renewal subscription is set to pending, then check if vouchers need to be sent via First Class post. If so, then tick the First Class flag so that voucher extracts can retrieve the data correctly.</description>
        <formula>ISCHANGED( Subscription_Status__c ) &amp;&amp;  ISPICKVAL(Subscription_Status__c, &apos;Pending&apos;) &amp;&amp; (if_Is_Renewal_Binary__c == 1) &amp;&amp; (DATEVALUE(NOW()) &gt;= First_Class_Postage_required_from__c)</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Lapsed Week Pos Final update</fullName>
        <actions>
            <name>Update_Week_Pos_Final_to_Duration</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>Updates Current Week Pos Final to the duration if sub goes from Pending Canx to Lapsed.</description>
        <formula>AND(ISPICKVAL(PRIORVALUE(Subscription_Status__c), &quot;Pending Cancellation&quot; ),ISPICKVAL(Subscription_Status__c, &quot;Lapsed&quot;))</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Last Status change date</fullName>
        <actions>
            <name>LastStatusChangedateupdate</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>The workflow updates the &apos;Last Status Change&apos; field whenever the Subscription status is updated</description>
        <formula>OR(ISCHANGED( Subscription_Status__c ), ISNEW())</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Paid Until Date Calculation</fullName>
        <actions>
            <name>Paid_Until_Calculated_Field_Update</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>Workflow to calculate Paid Until date</description>
        <formula>true</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>R1_R2_R3_Renewal_Status</fullName>
        <active>true</active>
        <description>This Workflow Rule updates the renewal status on a Subscription</description>
        <formula>AND(ISPICKVAL(Subscription_Status__c, &quot;Pending&quot;), NOT(ISNULL(Previous_Subscription_Expiry__c)), NOT(ISPICKVAL( Payment_Type__c , &quot;Direct Debit&quot;)), End_Date__c &gt; Today())</formula>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
        <workflowTimeTriggers>
            <actions>
                <name>R2FieldUpdate</name>
                <type>FieldUpdate</type>
            </actions>
            <offsetFromField>Subscription__c.End_Date__c</offsetFromField>
            <timeLength>-50</timeLength>
            <workflowTimeTriggerUnit>Days</workflowTimeTriggerUnit>
        </workflowTimeTriggers>
        <workflowTimeTriggers>
            <actions>
                <name>R1StatusUpdate</name>
                <type>FieldUpdate</type>
            </actions>
            <offsetFromField>Subscription__c.End_Date__c</offsetFromField>
            <timeLength>-78</timeLength>
            <workflowTimeTriggerUnit>Days</workflowTimeTriggerUnit>
        </workflowTimeTriggers>
        <workflowTimeTriggers>
            <actions>
                <name>R3RenewalStatusUpdate</name>
                <type>FieldUpdate</type>
            </actions>
            <offsetFromField>Subscription__c.End_Date__c</offsetFromField>
            <timeLength>-15</timeLength>
            <workflowTimeTriggerUnit>Days</workflowTimeTriggerUnit>
        </workflowTimeTriggers>
    </rules>
    <rules>
        <fullName>Set Send Loyalty to No</fullName>
        <actions>
            <name>Set_Send_Loyalty_to_No</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>Sets the &quot;Send Loyalty&quot; field on Subscription object to NO so that Customer is not qualified to receive the Loyalty Rewards Card.</description>
        <formula>IF ( ISPICKVAL(Previous_Subscription__r.Subscription_Duration_Picklist__c,&apos;26&apos;) &amp;&amp; ISPICKVAL(Subscription_Duration_Picklist__c,&apos;26&apos;) &amp;&amp; (ISPICKVAL(Previous_Subscription__r.Send_Loyalty__c, &apos;Yes&apos;) || ISPICKVAL(Previous_Subscription__r.Send_Loyalty__c, &apos;&apos;)), true, false)</formula>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>Set Send Loyalty to Yes</fullName>
        <actions>
            <name>Set_Send_Loyalty_to_Yes</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>Sets the &quot;Send Loyalty&quot; field on Subscription object to YES so that Customer is qualified to receive the Loyalty Rewards Card.</description>
        <formula>IF ( (ISPICKVAL(Subscription_Duration_Picklist__c,&apos;13&apos;) || ISPICKVAL(Subscription_Duration_Picklist__c,&apos;52&apos;)), true, false)</formula>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>Subscription_Status_Lock_All_Fields</fullName>
        <actions>
            <name>Subscription_Status_Lock_All_Fields</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>This workflow rule is used with a Validation Rule with the same name to lock all fields when the Subscription Status is Withdrawn, Declined, Cancelled and Lapsed.</description>
        <formula>OR(ISPICKVAL(Subscription_Status__c, &quot;Withdrawn&quot;), ISPICKVAL(Subscription_Status__c, &quot;Declined&quot;), ISPICKVAL(Subscription_Status__c, &quot;Cancelled&quot;), ISPICKVAL(Subscription_Status__c, &quot;Lapsed&quot;))</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Synthesis Key Update</fullName>
        <actions>
            <name>UpdateKey</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Subscription__c.Synthesis_Key__c</field>
            <operation>equals</operation>
        </criteriaItems>
        <description>Populates the synthesis key field with a combination of TDT and start date of subscripotion where key is not already populated.</description>
        <triggerType>onCreateOnly</triggerType>
    </rules>
    <rules>
        <fullName>Update Cur Pack for Cancellation</fullName>
        <active>true</active>
        <description>Updates current pack and week at the cancellation date</description>
        <formula>OR(ISPICKVAL(Subscription_Status__c, &quot;Pending Cancellation&quot;), ISPICKVAL(Subscription_Status__c, &quot;Cancelled&quot;) )</formula>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
        <workflowTimeTriggers>
            <actions>
                <name>Force_Entitlements_Update</name>
                <type>FieldUpdate</type>
            </actions>
            <actions>
                <name>UpdateCurrentPackPositionFinal</name>
                <type>FieldUpdate</type>
            </actions>
            <actions>
                <name>UpdateCurrentWeekPositionFinal</name>
                <type>FieldUpdate</type>
            </actions>
            <offsetFromField>Subscription__c.Cancellation_Date__c</offsetFromField>
            <timeLength>0</timeLength>
            <workflowTimeTriggerUnit>Days</workflowTimeTriggerUnit>
        </workflowTimeTriggers>
    </rules>
    <rules>
        <fullName>Update Cur Pack for Cancellation - 1 time</fullName>
        <active>true</active>
        <description>Updates current pack and week at the cancellation date (1 time for existing data)</description>
        <formula>Cancellation_Date_Workflow_trigger__c = true</formula>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
        <workflowTimeTriggers>
            <actions>
                <name>Force_Entitlements_Update</name>
                <type>FieldUpdate</type>
            </actions>
            <actions>
                <name>UpdateCurrentPackPositionFinal</name>
                <type>FieldUpdate</type>
            </actions>
            <actions>
                <name>UpdateCurrentWeekPositionFinal</name>
                <type>FieldUpdate</type>
            </actions>
            <offsetFromField>Subscription__c.Cancellation_Date__c</offsetFromField>
            <timeLength>0</timeLength>
            <workflowTimeTriggerUnit>Days</workflowTimeTriggerUnit>
        </workflowTimeTriggers>
    </rules>
    <rules>
        <fullName>Update_Current_Pack_Position_Final</fullName>
        <actions>
            <name>UpdateCurrentPackPositionFinal</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>This Workflow Rule updates the Current Pack Position Final field whenever the Current Pack Position field is changed. This is used to lock the current pack position &amp; financials once the Subscription Status is Pending Cancellation or Cancelled.</description>
        <formula>OR(ISPICKVAL(Subscription_Status__c, &quot;Lapsed&quot;))</formula>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>Update_Current_Week_Position_Final</fullName>
        <actions>
            <name>UpdateCurrentWeekPositionFinal</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>This Workflow Rule updates the Current Week Position Final field whenever the Current Week Position field is changed. This is used to lock the subscription position &amp; financials indirectly once the Subscription Status is Pending Cancellation or Cancelled.</description>
        <formula>OR(ISPICKVAL(Subscription_Status__c, &quot;Lapsed&quot;))</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Voucher Resend Extraction Date Population</fullName>
        <actions>
            <name>VoucherExtractionDatecalc</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Subscription__c.Voucher_Resend_Date__c</field>
            <operation>equals</operation>
            <value>TODAY</value>
        </criteriaItems>
        <description>This workflow copies the voucher extraction date calc field to the voucher extraction date field whenever a voucher extraction is requested</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>Voucher Resend Number</fullName>
        <actions>
            <name>NumberofVoucherResends</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>Maintains the number of voucher resends requested for this Subscription</description>
        <formula>ISCHANGED( Voucher_Resend_Date__c)</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Voucher_Adjustment_Goodwill</fullName>
        <actions>
            <name>Outstanding_Balance_Goodwill</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>Voucher_Adjustment_Halt_Workflow</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>GoodwillApplied</name>
            <type>Task</type>
        </actions>
        <active>true</active>
        <description>This Workflow Rule applies goodwill when a Subscriber has outstanding vouchers that have not been paid for, but as a goodwill gesture TMG agree to let the Subscriber keep the vouchers.</description>
        <formula>Voucher_Adjustment_Reason__c = &quot;Goodwill&quot;</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Voucher_Adjustment_Holiday_Return</fullName>
        <actions>
            <name>Outstanding_Balance_Holiday_Return</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>Voucher_Adjustment_Halt_Workflow</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>This Workflow Rule applies a Holiday Return value when a Subscriber returns vouchers under the holiday process, in order to qualify for a refund.  Whole weeks must be returned.</description>
        <formula>Voucher_Adjustment_Reason__c = &quot;Holiday Return&quot;</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Voucher_Adjustment_Voucher_Return</fullName>
        <actions>
            <name>Outstanding_Balance_Voucher_Return</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>Voucher_Adjustment_Halt_Workflow</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>This Workflow Rule applies a Voucher Return value when a Subscriber returns vouchers that have not been paid for, such as when a Subscription has been cancelled. Any number of vouchers can be returned, no refund amount is calculated.</description>
        <formula>Voucher_Adjustment_Reason__c = &quot;Voucher Return&quot;</formula>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>Voucher_Replacement_Full_Pack</fullName>
        <actions>
            <name>Voucher_Adjustment_Halt_Workflow</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>FullVoucherReplacementPackSent</name>
            <type>Task</type>
        </actions>
        <active>true</active>
        <description>This Workflow Rule creates a completed Task to signify that a Replacement Voucher Pack has been sent.</description>
        <formula>Voucher_Adjustment_Reason__c = &quot;Voucher Resend - Full Pack&quot;</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Voucher_Replacement_Part_Pack</fullName>
        <actions>
            <name>Voucher_Adjustment_Halt_Workflow</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>ReplacementVoucherstobeSent</name>
            <type>Task</type>
        </actions>
        <active>true</active>
        <description>This Workflow Rule creates a completed Task to signify that Replacement Vouchers (part pack) have been sent.</description>
        <formula>Voucher_Adjustment_Reason__c =  &quot;Voucher Resend - Part Pack&quot;</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Zero Week Pos</fullName>
        <actions>
            <name>Zero_Final_Week_Pos</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>Zero_Value_Final_Week_Pos</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>Sets the current + Final week pos to be 0, if Canc Date = Start Date and Start Date &lt; Today.</description>
        <formula>AND(OR(ISPICKVAL(Subscription_Status__c, &quot;Pending Cancellation&quot;), ISPICKVAL(Subscription_Status__c, &quot;Cancelled&quot;) ) , Cancellation_Date__c = Start_Date__c, Today()&lt;Start_Date__c )</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <tasks>
        <fullName>FullVoucherReplacementPackSent</fullName>
        <assignedTo>system@telegraph.co.uk</assignedTo>
        <assignedToType>user</assignedToType>
        <description>A Full Replacement Pack has been sent.</description>
        <dueDateOffset>0</dueDateOffset>
        <notifyAssignee>false</notifyAssignee>
        <priority>Normal</priority>
        <protected>false</protected>
        <status>Completed</status>
        <subject>Full Voucher Replacement Pack Sent</subject>
    </tasks>
    <tasks>
        <fullName>GoodwillApplied</fullName>
        <assignedTo>system@telegraph.co.uk</assignedTo>
        <assignedToType>user</assignedToType>
        <dueDateOffset>0</dueDateOffset>
        <notifyAssignee>false</notifyAssignee>
        <priority>Normal</priority>
        <protected>false</protected>
        <status>In Progress</status>
        <subject>Goodwill Applied</subject>
    </tasks>
    <tasks>
        <fullName>ReplacementVoucherstobeSent</fullName>
        <assignedTo>system@telegraph.co.uk</assignedTo>
        <assignedToType>user</assignedToType>
        <description>Replacement Vouchers (undated) need to be sent.</description>
        <dueDateOffset>0</dueDateOffset>
        <notifyAssignee>false</notifyAssignee>
        <priority>Normal</priority>
        <protected>false</protected>
        <status>Not Started</status>
        <subject>Replacement Vouchers to be Sent</subject>
    </tasks>
</Workflow>
