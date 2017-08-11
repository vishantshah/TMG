/************************************************************************************
Class Name   : OutboundCallingBean
Author       : Mantas Grigaliunas
Created Date : 18/07/2016
Function     : The class to hold nested classes that are used to deserialize JSON Parameters described in Outbound Call Setting records
Change Log:
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
* Developer    Date         Description
* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
*************************************************************************************/

public class OutboundCallingBean {
	
	public static final String OUTBOUND_CALL_SETTINGS_CALL_STAGE_PARAMETER_NAME = 'callStageParameters';

	public List<CallStageMapping> callStageParameters;

	public class CallStageMapping{
		public String stagename;
		public String outcome;
		public String calldatetime;
		public String nosalereason;
		public Integer offset;
		public String tcode;

		public CallStageMapping(String stage, String outcome, String calldatetime, String nosalereason, Integer offset, String tcode){
			this.stagename = stage;
			this.outcome = outcome;
			this.calldatetime = calldatetime;
			this.nosalereason = nosalereason;
			this.offset = offset;
			this.tcode = tcode;
		}

		public CallStageMapping(String stage, String outcome, String calldatetime, Integer offset){
			this.stagename = stage;
			this.outcome = outcome;
			this.calldatetime = calldatetime;
			this.nosalereason = null;
			this.offset = offset;
			this.tcode = null;
		}
	}
}