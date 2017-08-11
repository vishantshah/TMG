/**
* @author Unknown
* @date Unknown
* @description This class contains a list of utility methods which can be re-used( and/or abused) by other classes
* #############Change Log#############
* Modified by           Version    Change Date
* Wiktor Czykin         1.1        02/06/2015  //added limitString(),logIndividualResponsesForIndividualRequests(), logIndividualLogsForParent(), logWebServiceRequestSerialized()
* Wiktor Czykin         1.2        20/07/2015  //moved here nested WebserviceLog class, added generateLogRecordsFromWebserviceLog(),
*                                              modified relateWebserviceLogToObject(), added newLogWebServiceRequestSerialized() and modified methods to call it
* Wiktor Czykin         1.3        03/09/2015  //modified EmailUtil class
* Wiktor Czykin         1.4        27/10/2015  //removed PropertiesUtil inner class
* Wiktor Czykin         1.5        15/12/2015  //added upsertRecordWithJson();
* Wiktor Czykin         1.6        12/2015     //moved here cheque related methods common to all flows
* Wiktor Czykin         1.7        16/12/2015  //added common logging buffer map
* Wiktor Czykin         1.8        22/02/2016  //modified logWebServiceRequestSerialized(), added populateExtraDetailsOnWebServiceRequestSerialized()
* Michal Szewczyk       1.9        14/03/2016  //added multiPickListSelectionCheck()
* Gavin Palmer          2.0        01/06/2016  // added method validateAgainstProductPrice() and class FieldValidationWrapper
* Gavin Palmer          2.1        09/06/2016  // added a getFieldLabel() method and getDMLErrors() method
* Mantas Grigaliunas    2.2        20/06/2016  //added method converDateToString()
* Mantas Grigaliunas    2.3        08/08/2016  //added method getCurrentPageName()
* Wiktor Czykin         2.4        29/09/2016  //modified validateAgainstProductPrice()
* Mantas Grigaliunas    2.5        05/10/2016  //added method displayServerErorr()
* Mantas Grigaliunas    2.6        12/10/2016  //added new methods newZuoraLogWebServiceRequestSerialized(),  logZuoraServerResponse()
*                                             and ZuoraServerResponseWrapper for Zuora web service logs
* Mantas Grigaliunas    2.7         01/12/2016  //added logWebServiceResponse method override to be able to pass tsNumber
* Pawel Chrzanowski     2.9     18/01/2017  //added createRestrictedOfferUsage()
* Pawel Chrzanowski     3.0     17/02/2017  //modified createRestrictedOfferUsage()
* Wiktor Czykin         3.1     15/03/2017  //modified populateResponseOnWebServiceRequestSerialized()
* Mantas Grigaliunas    3.2     08/05/2017  //modified Zuora Web Service logging functionality
**/
public class TMGUtil {

    public static Map<String, List<Webservice_Log__c>> mapCommonLogBuffer = new Map<String, List<Webservice_Log__c>>();
    public static Map<String, zqu__ZProduct__c> mapProdNameToProdRec = new Map<String,zqu__ZProduct__c>();
    /*
    * The EmailUtil class is used to create an email utility which
    * can be used by others. Taking a cue from the Java API best practices
    * from the revered book 'Effective Java' by Joshua Bloch, I am going to use the
    * Builder pattern[Chapter 2, Item 2] instead of creating one method with a
    * long list of (mostly optional) parameters. This pattern also simulates named optional
    * parameters as found in Ada and Python.
    * As a implementer, it gives us the flexibility to add new parameters without breaking
    * the existing use of it's methods.
    * Another advantage of the Builder pattern is that the developer using this util class/method
    * doesn't need to remember the order of the parameters.
    * If you aren't sure how to use this method or class, see the TestTMGUtil class.
    *
    * Finally, if you are updating this class please try to keep it as generic as possible,
    * avoid all TMG specific references since I'd like to post this class on the
    * Apex Code Share when it is more feature complete.
    * @author: Anup
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         03/06/2015  //removed var with soql that could be called when not necessary -> moved to replyTo getter
    */
    public class EmailUtil {

        private Messaging.SingleEmailMessage singleEmailMessage;
        private final List<String> toAddresses;
        //optional parameters set to default
        private String subject = '';
        private String htmlBody = '';
        private Boolean useSignature = false;
        private List<Messaging.EmailFileAttachment> fileAttachments = null;
        //defaults to current user's first name + last name
        private String senderDisplayName = UserInfo.getFirstName()+' '+UserInfo.getLastName();
        //get the current user in context
        //replyTo is set to current user's email
        private String replyTo {
            get{
                if(String.isBlank(this.replyTo)){
                    List<User> lstCurrentUser = [Select Email from User where Username = :UserInfo.getUserName() limit 1];
                    if(!lstCurrentUser.isEmpty()){
                        this.replyTo = lstCurrentUser[0].Email;
                    }
                }
                return this.replyTo;
            }
            set;
        }
        private String plainTextBody = '';
        private List<Id> documentAttach = new List<Id>();

        public EmailUtil(List<String> addresses) {
            this.toAddresses = addresses;
        }

        public EmailUtil senderDisplayName(String val) {
            senderDisplayName = val;
            return this;
        }

        public EmailUtil subject(String val) {
            subject = val;
            return this;
        }

        public EmailUtil htmlBody(String val) {
            htmlBody = val;
            return this;
        }

        public EmailUtil useSignature(Boolean bool) {
            useSignature = bool;
            return this;
        }

        public EmailUtil replyTo(String val) {
            replyTo = val;
            return this;
        }

        public EmailUtil plainTextBody(String val) {
            plainTextBody = val;
            return this;
        }

        public EmailUtil fileAttachments(List<Messaging.Emailfileattachment> val) {
            fileAttachments = val;
            return this;
        }

        public EmailUtil documentAttach(Id document) {
            //allows file attachments
            documentAttach.add(document);
            return this;
        }

        //where it all comes together
        public EmailUtil build() {
            singleEmailMessage = new Messaging.SingleEmailMessage();
            singleEmailMessage.setToAddresses(this.toAddresses);
            singleEmailMessage.setSenderDisplayName(this.senderDisplayName);
            singleEmailMessage.setSubject(this.subject);
            singleEmailMessage.setHtmlBody(this.htmlBody);
            singleEmailMessage.setUseSignature(this.useSignature);
            singleEmailMessage.setReplyTo(this.replyTo);
            singleEmailMessage.setPlainTextBody(this.plainTextBody);
            singleEmailMessage.setFileAttachments(this.fileAttachments);
            if (documentAttach.size() > 0)
                singleEmailMessage.setDocumentAttachments(this.documentAttach);
            return this;
        }

        public EmailUtil buildEmailFromTemplate(Id templateId, Id targetId, Id whatId, Boolean saveAsActivity, Id orgWideEmailAddressId){
            singleEmailMessage = new Messaging.SingleEmailMessage();
            singleEmailMessage.setTargetObjectId(targetId);
            singleEmailMessage.setWhatId(whatId);
            singleEmailMessage.setTemplateId(templateId); 
            singleEmailMessage.setSaveAsActivity(saveAsActivity);
            singleEmailMessage.setOrgWideEmailAddressId(orgWideEmailAddressId);

            return this;
        }


        //Amir Hafeez - we need to able to send emails in bulk rather than one at a time, so I have added a getter for the singleEmailMessage object.
        public Messaging.SingleEmailMessage getEmailMessage(){
            return this.singleEmailMessage;
        }

        //send the email message
        public void sendEmail() {
            if(singleEmailMessage != null) {
                try {
                    Messaging.sendEmail(new Messaging.SingleEmailMessage[] { singleEmailMessage });
                } catch (Exception ex) {
                    if(!Test.isRunningTest()){
                        throw new GenericException('There was a problem while calling Messaging.sendEmail()');
                    }
                }
            } else {
                //build was not called to create an instance of singleEmailMessage
                throw new GenericException('Build the EmailMessageInstance using the build() method');
            }
        }
    }

    /*
    * This method will convert 15 character IDs to 18 character IDs
    * This technique was first described by Scott Hemmeter (http://sfdc.arrowpointe.com/2010/08/23/convert-15-char-to-18-char-ids-in-apex/)
    *
    * @param 15CharacterID string representing the 15 character ID that you would like to convert
    * @return 18 character ID
    * @throws GenericException
    */
    public static ID generate18CharacterID(String fifteenCharId) {
        ID eighteenCharID;
        try {
            //if it's not a valid id or is null, this assignment will have a spazz and throw an exception
            eighteenCharID = fifteenCharId;
        } catch(Exception ex) {
            throw new GenericException('There was a problem while converting your 15 char id to 18 char id.');
        }
        //no exception means we have a winner, return the 18 char ID
        return eighteenCharID;
    }

    public String RetrieveSalesforceServerName(){
        //gets the salesforce servername part only eg: tapp0, emea etc
        String Ref = ApexPages.currentPage().getHeaders().get('Referer');
        String ServerName = ref.substring(8,ref.indexof('.salesforce',0));
        system.debug('ServerName ' + ServerName);

        return ServerName;
    }

    /*
    * This method will validate your postcode using the rules
    * described in British Standard (BS 7666)
    * more details can be found here - http://en.wikipedia.org/wiki/Postcodes_in_the_United_Kingdom#Validation
    * I'll attempt to achieve this feat using regular expression with a dash of Pan Galactic Gargle Blaster(http://en.wikipedia.org/wiki/Zaphod_Beeblebrox#Pan-Galactic_Gargle_Blaster).
    *
    */
    public static Boolean isValidPostCode(String postCode) {
        //create a pattern obj
        Pattern postCodePattern = Pattern.compile('(GIR 0AA)|(((A[BL]|B[ABDHLNRSTX]?|C[ABFHMORTVW]|D[ADEGHLNTY]|E[HNX]?|F[KY]|G[LUY]?|H[ADGPRSUX]|I[GMPV]|JE|K[ATWY]|L[ADELNSU]?|M[EKL]?|N[EGNPRW]?|O[LX]|P[AEHLOR]|R[GHM]|S[AEGKLMNOPRSTY]?|T[ADFNQRSW]|UB|W[ADFNRSV]|YO|ZE)[1-9]?[0-9]|((E|N|NW|SE|SW|W)1|EC[1-4]|WC[12])[A-HJKMNPR-Y]|(SW|W)([2-9]|[1-9][0-9])|EC[1-9][0-9]) [0-9][ABD-HJLNP-UW-Z]{2})');
        //then create a matcher
        Matcher postCodeMatcher = postCodePattern.matcher(postCode);

        if(postCodeMatcher != null) {
            return postCodeMatcher.matches();
        }

        return false;
    }

    /** Log the details of the an incoming webservice call
        Direction = Inbound / Outbound
        Endpoint = Endpoint called when Outbound
        Expects a map of the received parameters

        Will return the Id of the log record created, which can be used to log the return
        of the webservice call in the same record

        Will swallow any exceptions that it creates as we don't want this to block any webservice call
    */
    public static ID logWebServiceRequest(String direction, String Endpoint, String methodName, Map<String, Object> parameters){

        WebService_Log__c log;

        try{
            String input = '';

            for(String k: parameters.keySet()){
                input += k + '=' + string.valueOf(parameters.get(k)) + '\r\n';
            }

            log = getRequestLog(null);
            log.Request_Time__c = DateTime.now();
            log.Method_Name__c = methodName;
            log.Parameters__c = input;
            log.direction__c = direction;
            if(Endpoint != null && Endpoint.length() > 254){
                log.Endpoint__c = Endpoint.substring(0, 254);
            }
            else{
                log.Endpoint__c = Endpoint;
            }
            insert log;

        } catch(Exception e){System.debug(' exception while logging webservicelogs: '+e.getMessage());}

        if( log != null ){
            System.debug('log id: '+log.Id);
            return log.Id;
        } else {
            return null;
        }
    }

    /*
        Amir Hafeez - Added method to insert attachments on logs as we get 5mb of data to store on each attachment.
        Used on logs where larger data cannot be stored on the long text area fields.
    */
    public static Id logWebServiceAttachment(Id logId, String direction, String endpoint, String description, String fileName, String contentType, Blob theData)
    {
        WebService_Log__c log;
        if(logId == null){
            log = new WebService_Log__c();
            log.direction__c = direction;
            log.Endpoint__c = endpoint;
            log.Extra_Details__c = description;
            log.User__c = UserInfo.getUserId();
            log.SessionId__c = UserInfo.getSessionId();
            log.ProfileId__c = UserInfo.getProfileId();
            log.Request_Time__c = DateTime.now();
            insert log;
        }

        Attachment attachment = new Attachment();
        attachment.Name = fileName;
        attachment.ContentType = contentType;
        attachment.Body = theData;
        attachment.ParentId = (logId == null ? log.Id : logId);
        insert attachment;
        return attachment.ParentId;
    }

    /*
        Amir Hafeez - Add new log and attachment.
    */
    public static Id logWebServiceAttachment(String direction, String endpoint, String description, String fileName, String contentType, Blob theData)
    {
        return logWebServiceAttachment(null, direction, endpoint, null, fileName, contentType, theData);
    }

    /*
        Amir Hafeez - Add new attachment to existing log.
    */
    public static void attachToExistingLog(Id logId, String fileName, String contentType, Blob theData){
        if(logId == null)return;
        logWebServiceAttachment(logId, null, null, null, fileName, contentType, theData);
    }

    /**    Log the details of the returned values for an incoming webservice call
        The requestId is the Id of the record created when the incoming parameters were logged.
        Use this to match the return values with the incoming parameter values.  This can be null,
        in which case a record with only return data will be created.

        Will swallow any exceptions that it creates as we don't want this to block any webservice call
    */
    public static Id logWebServiceResponse(ID requestId, Object returnValue, String tsNumber){
        WebService_Log__c log;
        try{
            log = getRequestLog(requestId);

            log.Response_Time__c = DateTime.now();
            log.Response_Content__c = string.valueOf(returnValue);
            log.TS_Number__c = tsNumber;

            upsert log;

        } catch(Exception e){}

        if( log != null ){
            return log.Id;
        } else {
            return null;
        }
    }

    public static Id logWebServiceResponse(ID requestId, Object returnValue){
        return logWebServiceResponse(requestId, returnValue, null);
    }

    /**    Log some extra details around this request.
        Return the Id of the request log for future use.

        Will swallow any exceptions that it creates as we don't want this to block any webservice call
    */
    public static Id logWebServiceDetail(ID requestId, String Detail) {

        WebService_Log__c log;
        try{

            log = getRequestLog(requestId);
            log.Extra_Details__c = log.Extra_Details__c + '\r\n' + DateTime.now() + ' - ' + Detail;

            upsert log;

        } catch(Exception e){}

        if( log != null ){
            return log.Id;
        } else {
            return null;
        }

    }
    /**    Log some extra details around this request.
        Return the Id of the request log for future use.

        Will swallow any exceptions that it creates as we don't want this to block any webservice call
    */
    public static Id updateWebServiceLog(ID requestId, Map<String, Object> parameters, String Detail) {

        WebService_Log__c log;
        try{
            String input = '';
            log = getRequestLog(requestId);
            if(log!=null && parameters!=null)
            {
                for(String k: parameters.keySet()){
                    input += k + '=' + string.valueOf(parameters.get(k)) + '\r\n';
                }
                log.Parameters__c = input;
            }

            log.Extra_Details__c = log.Extra_Details__c + '\r\n' + DateTime.now() + ' - ' + Detail;

            upsert log;

        } catch(Exception e){}

        if( log != null ){
            return log.Id;
        } else {
            return null;
        }

    }
    /***************************************************************************************
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Function -  Get a log record for the given Id
                There may not be a record associated with the id as it may have failed in an earlier call or
                be the first call.  In this case just create the object and add the default fields.
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin    1.1            03/06/2015    //added extra fields to the soql so that the method can be used in more scenarios
    ****************************************************************************************/
    private static WebService_Log__c getRequestLog(ID requestId){

        WebService_Log__c log = new WebService_Log__c();

        if(requestId != null){
            List<WebService_Log__c> logs = [Select     Id,
                                                    Direction__c,
                                                    Request_Time__c,
                                                    Method_Name__c,
                                                    Event_Name__c,
                                                    Response_Time__c,
                                                    Response_Content__c,
                                                    Extra_Details__c,
                                                    Endpoint__c
                                                From WebService_Log__c
                                                Where Id = :requestId];
            if(logs != null && logs.size() > 0){
                log = logs[0];
            }
        }else{
            log = new WebService_Log__c(
                User__c = UserInfo.getUserId(),
                SessionId__c = UserInfo.getSessionId(),
                ProfileId__c = UserInfo.getProfileId() );
        }

        return log;
    }

    public static String getStringVal( Map<String, String> parameters){
        String input = '';
        for(String k: parameters.keySet()){
            input += k + '=' + parameters.get(k) + '\r\n';
        }
        return input;
    }

    /*
        Amir Hafeez - creates a quoted comma separated list in parentheses
        for use with the in clause in dynamic SOQL.
    */
    public static String parenthesizeList(List<Object> aList) {
        String result = '(\'\')';

        if(!aList.isEmpty()){
            result = '(\'' + String.valueOf(aList[0]).trim() + '\'';
            for(Integer i = 1; i < aList.size(); i++){
                result += ', \'' + String.valueOf(aList[i]).trim() + '\'';
            }
            result += ')';
        }
        return result ;
    }

    public static Boolean isDataValid(Object theData){
        if(theData == null || String.valueOf(theData).length() == 0){
            return false;
        }else{
            return true;
        }
    }

    //custom exception
    public class GenericException extends Exception{}

    public static Boolean checkSearchEntry(Integer qty){
        if (qty==0){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Search entry not found. Please try again.'));
            return false;
        }else
            return true;
    }

    public static List<SelectOption> recordDisplayValues(Integer numberRecordsToDisplay) {
        //Produces a SelectOption to control the number of records to display per page
        integer numberRecordsToDisplayTemp;
        String strRecordsToDisplayTemp;

        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption(String.valueof(numberRecordsToDisplay),String.valueof(numberRecordsToDisplay)));

        numberRecordsToDisplayTemp=numberRecordsToDisplay;
        for (integer i=1;i<=9;i++){
            numberRecordsToDisplayTemp += 10;
            strRecordsToDisplayTemp = String.valueof(numberRecordsToDisplayTemp);
            options.add(new SelectOption(strRecordsToDisplayTemp,strRecordsToDisplayTemp));
        }
        return options;
    }

    public static Boolean checkHeapSize(String errorMsg){
        if (limits.getHeapSize() > limits.getLimitHeapSize()){
            apexpages.addMessage(new Apexpages.Message(Apexpages.Severity.FATAL, errorMsg));
            return false;
        }
        return true;
    }

    /*    Round a decimal to a given number of decimal places
        not particularly exciting but I can't seem tp see
        this elsewhere
    */
    public static decimal decimalRound(decimal value, integer places){
        if(value == 0)
            return 0;

        decimal factor = Math.pow(10, places);
        return Math.round((value*factor)+0.1)/factor;
    }

    public static Boolean checkSOQLLimit(String errorMsg, integer marginBuffer){
        if (limits.getQueries() > (limits.getLimitQueries() - marginBuffer)){
            apexpages.addMessage(new Apexpages.Message(Apexpages.Severity.FATAL, errorMsg));
            return true;
        }
        return false;
    }

    public static Integer getNumberOfWeekdays(Date sdate, Date edate){
        //Get the number of days between date range
        Integer totalnumberDays = sdate.daysBetween(edate);

        Datetime sdatetime = Datetime.newInstance(sdate.year(),sdate.month(),sdate.day());
        Datetime edatetime = Datetime.newInstance(edate.year(),edate.month(),edate.day());

        //Get number working days
        Integer workingdays = (totalnumberDays - daysOff(sdatetime, edatetime));

        return workingdays;
    }

    public static Integer daysOff(Datetime sdate, Datetime edate){
         //get the number of Saturdays and Sundays
         Integer i = 0;

         while (sdate < edate) {
           if (sdate.format('E') == 'Sat' | sdate.format('E') == 'Sun'){
            i = i + 1;
           }
         sdate = sdate.addDays(1);
         }

         return i;
    }

    public static Map<String, RecordType> recordTypeMap{
        get{
            if(recordTypeMap == null){
                recordTypeMap = new Map<String, RecordType>();
                for(RecordType a : [SELECT Id, Name, SObjectType FROM RecordType]){
                    recordTypeMap.put(a.SObjectType + '.' + a.Name, a);
                }
            }
            return recordTypeMap;
        }
        private set;
    }

    public static ID logWebServiceRequest(String direction, String Endpoint, String methodName, Map<String, Object> parameters, String Detail){

        WebService_Log__c log;

        try{
            String input = '';
            if(parameters!=null){
                for(String k: parameters.keySet()){
                    input += k + '=' + string.valueOf(parameters.get(k)) + '\r\n';
                }
            }

            log = getRequestLog(null);
            log.Request_Time__c = DateTime.now();
            log.Method_Name__c = methodName;
            log.Parameters__c = input;
            log.direction__c = direction;
            if(Detail!=null)
                log.Extra_Details__c =  DateTime.now() + ' - ' + Detail;
            if(Endpoint != null && Endpoint.length() > 254){
                log.Endpoint__c = Endpoint.substring(0, 254);
            }
            else{
                log.Endpoint__c = Endpoint;
            }
            insert log;

        } catch(Exception e){System.debug(' exception while logging webservicelogs: '+e.getMessage());}

        if( log != null ){
            System.debug('log id: '+log.Id);
            return log.Id;
        } else {
            return null;
        }
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 15/06/2015
    Version - 1.1
    Function - Another overload for the method that accepts populated instance
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin    1.1            22/02/2016    //returning null if log is null
    ****************************************************************************************/
     public static Id logWebServiceRequestSerialized(WebService_Log__c log){
         if(log == null) return null;
         try{
            insert log;
        } catch(Exception e){
            System.debug(' exception while logging webservicelogs: '+e.getMessage());
        }
        return log.Id;
     }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 03/06/2015
    Version - 1.0
    Function - Proxy method with less params
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
     public static WebService_Log__c logWebServiceRequestSerialized(    String sDirection,
                                                                    String sEndpoint,
                                                                    String sMethodName,
                                                                    Object parameters){
         return logWebServiceRequestSerialized(sDirection, sEndpoint, sMethodName, parameters, null, null, null);
     }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 29/05/2015
    Version - 1.0
    Function -     Almost a copy of logWebServiceRequest, this version accepts parameters with whatever is there and just puts into a field in a serialized format.
                As an extra it stores Related_Record_Id__c.
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
     public static WebService_Log__c logWebServiceRequestSerialized(    String sDirection,
                                                                    String sEndpoint,
                                                                    String sMethodName,
                                                                    Object parameters,
                                                                    String sDetails,
                                                                    String sRelatedRecordId,
                                                                    String sParentLog
                                                                    ){
        WebService_Log__c log;
        try{
            log = newLogWebServiceRequestSerialized(sDirection, sEndpoint, sMethodName, parameters, sDetails, sRelatedRecordId, sParentLog);
            insert log;
        } catch(Exception e){
            System.debug(' exception while logging webservicelogs: '+e.getMessage());
        }

        if(log.Id == null){
            return null;
        }
        return log;
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 29/07/2015
    Version - 1.0
    Function -     moved the record initialization contents of logWebServiceRequestSerialized() to here so that no-insert version could be done as well
                just make sure the method calling this has exception handling
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
     public static WebService_Log__c newLogWebServiceRequestSerialized(    String sDirection,
                                                                        String sEndpoint,
                                                                        String sMethodName,
                                                                        Object parameters,
                                                                        String sDetails,
                                                                        String sRelatedRecordId,
                                                                        String sParentLog
                                                                        ){
        WebService_Log__c log = getRequestLog(null);
        if(parameters!=null){
            log.Parameters__c = JSON.serialize(parameters);
        }
        log.Request_Time__c = DateTime.now();
        log.Method_Name__c = sMethodName;
        log.Event_Name__c = TMGUtil.limitString(sMethodName, 255);
        log.Direction__c = sDirection;
        if(String.isNotBlank(sDetails)){
            log.Extra_Details__c = sDetails;
        }
        log.Endpoint__c = TMGUtil.limitString(sEndpoint, 255);

        if(String.isNotBlank(sRelatedRecordId)){
            log.Related_Record_Id__c = sRelatedRecordId;
        }
        if(String.isNotBlank(sParentLog)){
            log.Parent_Log__c = sParentLog;
        }
        return log;
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 16/12/2015
    Version - 1.1
    Function -     adds response details to instance
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         15/03/2017  //added string length limit
    ****************************************************************************************/
    public static WebService_Log__c populateResponseOnWebServiceRequestSerialized(WebService_Log__c log, Object response){
        log.Response_Time__c = Datetime.now();
        log.Response_Content__c = JSON.serialize(response).left(60000);
        return log;
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 22/02/2016
    Version - 1.0
    Function -     adds extra details to instance
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public static WebService_Log__c populateExtraDetailsOnWebServiceRequestSerialized(WebService_Log__c log, String sExtraDetails){
        log.Extra_Details__c = sExtraDetails;
        return log;
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 15/12/2015
    Version - 1.0
    Function - replaces Parameters__c value with serialized parameters value
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public static WebService_Log__c upsertRecordWithJson(WebService_Log__c wl, Object parameters){
        if(parameters != null && wl != null){
            wl.Parameters__c = JSON.serialize(parameters);
        }
        upsert wl;
        return wl;
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 02/06/2015
    Version - 1.0
    Function - just proxy method that retrieves original webservice log before executing logIndividualLogsForParent()
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public static void logIndividualLogsForParent(Id logId, Map<Id, Object> mapRelatedObjects, Map<Id, String> mapRecordIdToTSNumber){
        if(logId == null) return;

        WebService_Log__c log = getRequestLog(logId);
        if(log != null && log.Id != null){
            logIndividualLogsForParent(log, mapRelatedObjects, mapRecordIdToTSNumber);
        }
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 02/06/2015
    Version - 1.0
    Function - tries to insert webservice log records for master log record based on individual payloads (members of bulk request payload)
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public static void logIndividualLogsForParent(WebService_Log__c parentLog, Map<Id, Object> mapRelatedObjects, Map<Id, String> mapRecordIdToTSNumber){
        List<WebService_Log__c> lstLogs = new List<WebService_Log__c>();
        if(parentLog == null || mapRelatedObjects == null) return;

        try{
            for(Id idk : mapRelatedObjects.keySet()){
                if(idk == null) continue;

                WebService_Log__c wl = getRequestLog(null);
                wl.Direction__c = parentLog.Direction__c;
                wl.Request_Time__c = parentLog.Request_Time__c;
                wl.Method_Name__c = parentLog.Method_Name__c+Constants.LOG_CHILD_RECORD_SUFFIX;
                wl.Event_Name__c = TMGUtil.limitString(parentLog.Event_Name__c+Constants.LOG_CHILD_RECORD_SUFFIX, 255);
                wl.Endpoint__c = parentLog.Endpoint__c;

                if(mapRelatedObjects.get(idk) != null){
                    wl.Parameters__c = JSON.serialize(mapRelatedObjects.get(idk));
                }
                wl.Parent_Log__c = parentLog.Id;
                wl.Related_Record_Id__c = idk;
                if(mapRecordIdToTSNumber != null && mapRecordIdToTSNumber.containsKey(idk) && String.isNotBlank(mapRecordIdToTSNumber.get(idk))){
                    wl.TS_Number__c = mapRecordIdToTSNumber.get(idk);
                }
                lstLogs.add(wl);
            }
            insert lstLogs;
        }catch(Exception e){
            System.debug('TMGLOG::TMGUtil:logIndividualLogsForParent:'+e.getMessage());
        }//failing silently
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 02/06/2015
    Version - 1.0
    Function -     method that tries to match response callback logs with requests made in a different transaction.
                If it cannot find a match it links it to fallbackParentLogId
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public static Boolean logIndividualResponsesForIndividualRequests(    Map<Id, Object> mapRelatedObjects,
                                                                        Map<Id, String> mapRecordIdToTSNumber,
                                                                        String sEventName,
                                                                        Id fallbackParentLogId){


        if(mapRelatedObjects == null || mapRecordIdToTSNumber == null || String.isBlank(sEventName)) return false;
        try{
            List<WebService_Log__c> lstToInsert = new List<WebService_Log__c>();
            List<WebService_Log__c> lstWebserviceLogs = [select     Id,
                                                                    TS_Number__c,
                                                                    Related_Record_Id__c
                                                                from WebService_Log__c
                                                                where TS_Number__c in :mapRecordIdToTSNumber.values()
                                                                and Related_Record_Id__c in :mapRecordIdToTSNumber.keySet()
                                                                and TS_Number__c != null
                                                                and Parent_Log__c != null
                                                                and Related_Record_Id__c != null
                                                                order by CreatedDate desc
                                                        ];
            Set<String> setUsedValues = new Set<String>();
            sEventName = TMGUtil.limitString(sEventName, 255);
            Datetime dtNow = Datetime.now();
            if(!lstWebserviceLogs.isEmpty()){
                Map<Id, WebService_Log__c> mapToCheck = new Map<Id, WebService_Log__c>([select Id from WebService_Log__c where Parent_Log__c in :lstWebserviceLogs]);

                for(WebService_Log__c wl : lstWebserviceLogs){

                    if(    mapRelatedObjects.containsKey(wl.Related_Record_Id__c) &&
                        mapRecordIdToTSNumber.containsKey(wl.Related_Record_Id__c) &&
                        wl.TS_Number__c == mapRecordIdToTSNumber.get(wl.Related_Record_Id__c) &&
                        !mapToCheck.containsKey(wl.Id) &&
                        !setUsedValues.contains(wl.Related_Record_Id__c)
                        ){
                            setUsedValues.add(wl.Related_Record_Id__c);
                            WebService_Log__c newWl = getRequestLog(null);
                            newWl.Direction__c = Constants.DIRECTION_INBOUND;
                            newWl.Request_Time__c = dtNow;
                            newWl.Event_Name__c = sEventName;
                            newWl.Method_Name__c = sEventName;
                            newWl.Parent_Log__c = wl.Id;
                            newWl.TS_Number__c = wl.TS_Number__c;
                            newWl.Related_Record_Id__c = wl.Related_Record_Id__c;
                            newWl.Parameters__c = JSON.serialize(mapRelatedObjects.get(wl.Related_Record_Id__c));
                            lstToInsert.add(newWl);
                    }
                }
            }
            for(Id idk : mapRelatedObjects.keySet()){
                if(!setUsedValues.contains(idk)){
                    WebService_Log__c newWl = getRequestLog(null);
                    newWl.Direction__c = Constants.DIRECTION_INBOUND;
                    newWl.Request_Time__c = dtNow;
                    newWl.Event_Name__c = sEventName;
                    newWl.Method_Name__c = sEventName;
                    newWl.Related_Record_Id__c = idk;
                    newWl.Parameters__c = JSON.serialize(mapRelatedObjects.get(idk));
                    if(mapRecordIdToTSNumber.containsKey(idk)){
                        newWl.TS_Number__c = mapRecordIdToTSNumber.get(idk);
                    }
                    if(fallbackParentLogId != null){
                        newWl.Parent_Log__c =  fallbackParentLogId;
                    }
                    lstToInsert.add(newWl);
                }
            }
            insert lstToInsert;
        }catch(Exception e){//failing silently
            return false;
            System.debug(e.getMessage());
        }
        return true;
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 29/05/2015
    Version - 1.0
    Function - simple method to substring with check
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public static String limitString(String sValue, Integer iMaxLength){
        if(String.isNotBlank(sValue) && sValue.length() > iMaxLength){
            return sValue.substring(0, iMaxLength);
        }
        return sValue;
    }


    /***************************************************************************************
    Developer - Ivan Almeida
    Date - Unknown
    Version - 1.1
    Function - //e.g relate the webservice log to Pricing history by passing in the name of the field and the object id
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin    1.1            29/07/2015 //change the method so that it no longer does dmls, only updates passed in list
    ****************************************************************************************/
    public static void relateWebserviceLogToObject(String apiFieldName, List<WebService_Log__c> logs, Id relatedObjectId){
        for(WebService_Log__c log : logs){
            log.put(apiFieldName, relatedObjectId);
        }
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 29/07/2015
    Version - 1.0
    Function -
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public static List<WebService_Log__c> generateLogRecordsFromWebserviceLog(List<WebserviceLog> lstWrappers){
        if(lstWrappers == null) return null;

        List<WebService_Log__c> lstWebserviceLogs = new List<WebService_Log__c>();
        for(WebServiceLog wl : lstWrappers){
            try{
                WebService_Log__c logObject = newLogWebServiceRequestSerialized(Constants.DIRECTION_OUTBOUND, null, wl.methodName, wl.params, null, null, null);
                if(wl.response != null){
                    logObject.Response_Content__c = JSON.serialize(wl.response);
                }
                lstWebserviceLogs.add(logObject);
            }catch(Exception e){
                System.debug('TMGLOG::TMGUtil:generateLogRecordsFromWebserviceLog:failsSilently');
            }
        }
        return lstWebserviceLogs;
    }

    /*************************************************************************************** 
    Developer - Mantas Grigaliunas   
    Date - 12/10/2016
    Version - 1.0
    Function - method override with predefined variables used for Zuora Api web service logging
    #############Change Log#############
    Modified by         Change Date
    Mantas Grigaliunas  08/05/2017  //refactored
    ****************************************************************************************/
    public static String newZuoraWebServiceLog(String zMethodName, String eventName, Map<String, Object> zParameters){
        return String.valueOf(JSON.serialize(new WebService_Log__c(
            Parameters__c        = JSON.serialize(zParameters), 
            Method_Name__c       = zMethodName,
            Event_Name__c        = eventName,
            Request_Time__c      = DateTime.now()))
        );
    }

    /*************************************************************************************** 
    Developer - Mantas Grigaliunas   
    Date - 12/10/2016
    Version - 1.0
    Function - logs Zuora API server call response from returned zuora save results list
    #############Change Log#############
    Modified by         Change Date
    Mantas Grigaliunas  08/05/2017  //refactored, added future call annotation
    ****************************************************************************************/
    public static void insertZuoraWebServiceLog(String log, String results, String extraDetails){
        WebService_Log__c webServiceLog   = (WebService_Log__c)JSON.deserialize(log, WebService_Log__c.class);
        webServiceLog.Response_Content__c = results;
        webServiceLog.Extra_Details__c    = (extraDetails != null ? JSON.serialize(extraDetails) : null);
        webServiceLog.Response_Time__c    = DateTime.now();
        insert webServiceLog;
    }

    public static void insertZuoraWebServiceLog(String log, List<String> results){
        String resultsString = null; 
        if(results != null) resultsString += results;
        insertZuoraWebServiceLog(log, resultsString, null);
    }

    public static void insertZuoraWebServiceLog(String log, String results){
        insertZuoraWebServiceLog(log, results, null);
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 23/12/2015
    Version - 1.0
    Function - Moved here as was same across all flows: acquisition, offline renewal, outbound calling
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public static String validateCheque(String sAccountNumber, String sSortCode){
        String sError = '';
        if (sAccountNumber != null && sSortCode != null ){
            if (sAccountNumber.length() != 8){
                sError += ', a valid Account Number';
            }
            if (sSortCode.length() != 6){
                sError += ', a valid Sort Code';
            }
        }else{
             sError = ', a valid Account Number and a valid Sort Code';
        }
        if (sError != '' ){
            if (sError.length() > 0 && sError.substring(0,1) == ',')
              sError = sError.substring(1); //removes the first ,

          sError = 'Please enter ' + sError ;
        }
        return sError;
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 23/12/2015
    Version - 1.0
    Function - Moved here as was same across all flows: acquisition, offline renewal, outbound calling
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public static Id createChequeBatch(){
        Cheque_Batch__c batch = new Cheque_Batch__c();
        insert batch;
        return batch.Id;
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 29/12/2015
    Version - 1.0
    Function - Moved here as was same across 2 flows: offline renewal, outbound calling
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public static void processChequePayment(Id subId, String chequeBatchSelected, Boolean createNewBatch, Integer duration, Cheque__c cheque, Decimal weeklyPrice){
        try{
            //if no new cheque batch is selected, then we must assign a valid existing batch to attach cheques to.
            if((createNewBatch == null || createNewBatch == false) && String.isBlank(chequeBatchSelected)){
                throw new TelegraphApplicationException(Label.Offline_Acquisition_Cheque_batch_selection_error);
            }

            String errorCheque = TMGUtil.validateCheque(cheque.Account_Number__c, cheque.Sort_Code__c);
            if(String.isNotBlank(errorCheque)){
                throw new TelegraphApplicationException(errorCheque);
            }

            if ((String.isBlank(chequeBatchSelected)) && !createNewBatch){
                throw new TelegraphApplicationException('An error occurred. Please ensure you have selected an existing batch or have selected to create a new batch.');
            }

            Decimal chequeAmount = duration * weeklyPrice;
            //get the batch name
            if (createNewBatch){
                Id batchId = TMGUtil.createChequeBatch();
                upsertCheque(subID, batchId, chequeBatchSelected, cheque, chequeAmount);
            }else{
                   upsertCheque(subID, null, chequeBatchSelected, cheque, chequeAmount);
            }
        }catch(Exception e){
            throw new TelegraphApplicationException('An error occurred processing the cheque. '+e.getMessage());
        }
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 29/12/2015
    Version - 1.0
    Function - Moved here as was same across 2 flows: offline renewal, outbound calling
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private static void upsertCheque(    Id subscriptionId,
                                        Id chequeBatchId,
                                        String chequeBatchName,
                                        Cheque__c cheque,
                                        Decimal amount){

        try{
            if(chequeBatchId == null && String.isNotBlank(chequeBatchName)){
                List<Cheque_Batch__c> lstRec = [select Id, Batch_Closed_Date__c from Cheque_Batch__c where Name = :chequeBatchName];
                if(!lstRec.isEmpty() && lstRec[0].Batch_Closed_Date__c == null){
                    chequeBatchId = lstRec[0].Id;
                }
            }else if(chequeBatchId != null){
                List<Cheque_Batch__c> lstRec = [select Id, Batch_Closed_Date__c from Cheque_Batch__c where Id = :chequeBatchId];
                if(lstRec.isEmpty() || lstRec[0].Batch_Closed_Date__c != null){
                    chequeBatchId = null;
                }
            }
            if(chequeBatchId == null){
                throw new TelegraphApplicationException('Cannot identify open Cheque Batch. Selected one might have been closed before use.');
            }

            //  If cheque is editing or Batch is changed. Having Master detail, we should delete existing and clone as new.
            if(cheque.Cheque_Batch__c != null && cheque.Cheque_Batch__c != chequeBatchId ){
                Cheque__c newCheque = new Cheque__c(Name_on_Cheque__c = cheque.Name_on_Cheque__c,
                                                    Account_Number__c = cheque.Account_Number__c,
                                                    Sort_Code__c = cheque.Sort_Code__c,
                                                    Ref_Number_on_Cheque__c = cheque.Ref_Number_on_Cheque__c
                                                    );
                if(cheque.Id != null){
                    try{
                        delete new Cheque__c(Id = cheque.Id);
                    }catch(Exception ex){}
                }
                cheque = newCheque;
            }
            cheque.Cheque_Batch__c = chequeBatchId;
            cheque.Type__c = Constants.CHEQUE_TYPE_SUBPAYMENT;
            cheque.Cheque_Amount__c = amount;
            cheque.Cheque_Banking_Status__c = Constants.CHEQUE_BANKINGSTATUS_BANKED;
            cheque.Subscription__c = subscriptionId;
            upsert cheque;
        }catch (Exception e){
            throw new TelegraphApplicationException('An error occurred processing the cheque' +e.getMessage());
        }
    }

    /**
    * @author Ivan Almeida
    * @date Unknown
    * @description Holds the logs for successive callouts so that they can be applied AFTER all those callouts have been made
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         29/07/2015  //moved here so that it could be re-used if necessary
    **/
    public class WebserviceLog{
        public String methodName {get; set;}
        public Map<string, object> params {get; set;}
        public Object response {get; set;}
        public Boolean error {
            get{
                return (!String.isEmpty(this.errorMessage)?true:false);
            }
        }
        public String ErrorMessage {get; set;}

        public WebserviceLog(String methodName, Map<String, Object> params){
            this.methodName = methodName;
            this.params = params;
        }
    }
    /***************************************************************************************
    Developer - Michal Szewczyk
    Date - 14/03/2016
    Version - 1.0
    Function - pass picklist selected value to check if value was selected
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public static Boolean multiPickListSelectionCheck(String selectedValues,String lookforValue){
        if(selectedValues != null && selectedValues != '' && lookforValue != null && lookforValue != '') {
            return selectedValues.contains(lookforValue);
        } else {
            return false;
        }
    }

    /***************************************************************************************
    Developer - Michal Szewczyk
    Date - 16/03/2016
    Version - 1.0
    Function - utils method that populates static map name -> Zuora Product
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private static void populateProdNameToProdRecMap(){

        for(zqu__ZProduct__c tmp : [SELECT Id,Name,zqu__Active__c,zqu__Category__c,ProductCountry__c,Print_Product__c FROM  zqu__ZProduct__c]){
            mapProdNameToProdRec.put(tmp.Name,tmp);
        }
    }

    /***************************************************************************************
    Developer - Michal Szewczyk
    Date - 16/03/2016
    Version - 1.0
    Function - fetch ProductId from Product Catalogue based on prod name
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public static String getProductIdFromCatalog(String prodName){
        String retId = '';
        zqu__ZProduct__c tempRec;

        if(mapProdNameToProdRec ==null || mapProdNameToProdRec.size() <= 0 ) {
            populateProdNameToProdRecMap();
        }

        tempRec = mapProdNameToProdRec.get(prodName);
        if(tempRec != null) {
            retId = tempRec.Id;
        }
        return retId;
    }

    /***************************************************************************************
    Developer - Michal Szewczyk
    Date - 16/03/2016
    Version - 1.0
    Function - check if product is Print Product
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public static Boolean productIsPrint(String prodId){

        if(mapProdNameToProdRec ==null || mapProdNameToProdRec.size() <= 0 ) {
            populateProdNameToProdRecMap();
        }

        for(zqu__ZProduct__c tmp : mapProdNameToProdRec.values()){

            if(tmp.Id == prodId) {
                return tmp.Print_Product__c;
            }
        }
        return null;
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 28/09/2016
    Version - 1.0
    Function - overloaded version of the method, if called full validation will be run always
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public static void validateAgainstProductPrice(List<SObject> lstNewRecords, List<FieldValidationWrapper> fieldValidationList, String parentZProductFieldName){
        validateAgainstProductPrice(lstNewRecords,fieldValidationList, parentZProductFieldName);
    }

    /***************************************************************************************
    Developer - Gavin Palmer
    Date - 27/05/2016
    Version - 1.1
    Function - validate the given sObject and field against the product price table
                for the map enter a string of the field name with a corresponding error message
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         28/09/2016  //modified so that validation is only triggered if value is changed
    ****************************************************************************************/
    public static void validateAgainstProductPrice(List<SObject> lstNewRecords, List<SObject> lstOldRecords, List<FieldValidationWrapper> fieldValidationList, String parentZProductFieldName){

        General__c generalSetting = General__c.getInstance(Constants.ENABLE_PRODUCT_PRICE_VALIDATION);
        if( generalSetting == null || !generalSetting.Value_Boolean__c ) return;

        if(lstNewRecords == null || fieldValidationList.isEmpty() || String.isBlank(parentZProductFieldName)){
            throw new TelegraphApplicationException('Invalid parameters passed into validateAgainstProductPrice()');
        }
        if(lstNewRecords.isEmpty()){
            return; //nothing to validate41
        }
        Set<Id> productIds = new Set<Id>();
        for(SObject objectToValidate : lstNewRecords){
            productIds.add((Id) objectToValidate.get(parentZProductFieldName));
        }

        Map<Id, zqu__ZProduct__c> zProductMap = new Map<Id, zqu__ZProduct__c>([
            SELECT Id,
                ( SELECT Price__c, Pricing_Type__c FROM Product_Prices__r WHERE Valid__c = TRUE )
                FROM zqu__ZProduct__c
                WHERE Id IN :productIds
        ]);
        Map<Id, SObject> mapOldRecords;
        Boolean bCheckChange = false;
        if(lstOldRecords != null){
            bCheckChange = true;
            mapOldRecords = new Map<Id, SObject>(lstOldRecords);
        }

        for(SObject objectToValidate : lstNewRecords){
            for(FieldValidationWrapper fieldValidation : fieldValidationList){
                if(fieldValidation.hasConditions){
                    Boolean condition = objectToValidate.get(fieldValidation.conditionalField) == fieldValidation.fieldValue;
                    fieldValidation.pricingType = fieldValidation.pricingTypeConditions.get(condition);
                }
                if(bCheckChange){
                    SObject oldRecord = mapOldRecords.get(objectToValidate.Id);
                    if(oldRecord != null && objectToValidate.get(fieldValidation.fieldToValidate) == oldRecord.get(fieldValidation.fieldToValidate)){
                        continue;
                    }
                }
                // if we havent succeeded in getting the product prices lets give the user an error
                if( objectToValidate.get(fieldValidation.fieldToValidate) != null
                    && (objectToValidate.get(parentZProductFieldName) == null
                        || zProductMap.get((Id) objectToValidate.get(parentZProductFieldName)) == null
                        || zProductMap.get((Id) objectToValidate.get(parentZProductFieldName)).Product_Prices__r.isEmpty() ))
                {
                    objectToValidate.addError(Label.Product_Price_Validation_Error);
                    break;
                }

                Boolean isValid = false;
                for(Product_Price__c validPrice : zProductMap.get((Id) objectToValidate.get(parentZProductFieldName)).Product_Prices__r){
                    if(objectToValidate.get(fieldValidation.fieldToValidate) == null
                        || (validPrice.Price__c == objectToValidate.get(fieldValidation.fieldToValidate)
                            && fieldValidation.pricingType == validPrice.Pricing_Type__c)){

                        isValid = true;
                        break;
                    }
                }

                if(!isValid){
                    objectToValidate.addError(fieldValidation.errorMessage);
                }
            }
        }
    }

    /***************************************************************************************
    Developer - Gavin Palmer
    Date - 27/05/2016
    Version - 1.1
    Function - a wrapper class to hold the field that needs to be validated against with an error message
                and the pricing type it should be validating against
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         28/09/2016
    ****************************************************************************************/
    public class FieldValidationWrapper {

        public String fieldToValidate;
        public String errorMessage;
        public String pricingType;
        public Map<Boolean, String> pricingTypeConditions;
        public String conditionalField;
        public String fieldValue;
        public Boolean hasConditions {
            get{
                return pricingTypeConditions != null && conditionalField != null && fieldValue != null;
            }
        }
        public List<SObject> lstRecordsToVerify;

        /***************************************************************************************
        Developer - Gavin Palmer
        Date - 27/05/2016
        Function - Standard constructor used in most cases
        #############Change Log#############
        Modified by     Version     Change Date
        ****************************************************************************************/
        public FieldValidationWrapper(String fieldToValidate, String errorMessage, String pricingType){
            this.fieldToValidate = fieldToValidate;
            this.errorMessage = errorMessage;
            this.pricingType = pricingType;
        }

        /***************************************************************************************
        Developer -  Gavin Palmer
        Date - 31/05/2016
        Function - constructor that allows conditions to be attached to the pricing type from a field on the object
        #############Change Log#############
        Modified by     Version     Change Date
        ****************************************************************************************/
        public FieldValidationWrapper(String fieldToValidate, String errorMessage, Map<Boolean, String> pricingTypeConditions, String conditionalField, String fieldValue){
            this.fieldToValidate = fieldToValidate;
            this.errorMessage = errorMessage;
            this.pricingTypeConditions = pricingTypeConditions;
            this.conditionalField = conditionalField;
            this.fieldValue = fieldValue;
        }

    }

    /**
    * @author Gavin Palmer
    * @date 08/06/2016
    * @description Utility method to get field label from SObject Type
    *#############Change Log#############
    *Modified by     Version     Change Date
    **/
    public static String getFieldLabel(Schema.SObjectType objectType, String fieldName){
        return objectType.getDescribe().fields.getMap().get(fieldName).getDescribe().getLabel();
    }

    /***************************************************************************************
    Developer - Mantas Grigaliunas
    Date - 21/06/2016
    Version - 1.0
    Function - converts Date to string with format dd/mm/yyyy
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public static String convertDateToString(Date d){
        if(d != null){
            String[] dl = String.valueOf(d).split('-', 0);
            return dl[2] + '/' + dl[1] + '/' + dl[0];
        } else {
            return null;
        }
    }

    /***************************************************************************************
    Developer - Mantas Grigaliunas
    Date - 08/08/2016
    Version - 1.0
    Function - returns current visuaforce page name from url
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public static String getCurrentPageName(){
        String currentPageUrl = ApexPages.currentPage().getUrl();
        if(currentPageUrl.contains('?'))
            return ApexPages.currentPage().getUrl().substringBetween('apex/', '?');
        else
            return ApexPages.currentPage().getUrl().substringAfter('apex/');
    }

    /***************************************************************************************
    Developer - Mantas Grigaliunas
    Date - 05/10/2016
    Version - 1.0
    Function - returns current visuaforce page name from url
    #############Change Log#############
    Modified by  Version     Change Date
    ****************************************************************************************/
    public static void displayServerError(HttpResponse response){
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL,
              'Code: ' + response.getStatusCode()   + ' | ' 
            + 'Status: ' + response.getStatus()     + ' | ' 
            + 'Error Message: ' + response.getBody()
        ));
    }
	
    /***************************************************************************************
    Developer - Pawel Chrzanowski
    Date - 18/01/2017
    Function to create new Restricted Offer Usage records
    #############Change Log#############
    Modified by        Version     Change Date
	Pawel Chrzanowski  1.1         17/02/2017  modified to use Quote instead of Account
    ****************************************************************************************/
    @future(callout=true)
    public static void createRestrictedOfferUsage(Set<Id> subIds){
        System.debug('@future createRestrictedOfferUsage');
        if(subIds.isEmpty()) return;

        List<Zuora__Subscription__c> lstSubs = [SELECT Zuora__Account__c, PromoCode__c, Master_Quote__c, Zuora__External_Id__c FROM Zuora__Subscription__c WHERE Zuora__Account__c != NULL AND PromoCode__c != NULL AND Master_Quote__c != NULL AND Id IN :subIds];
        System.debug('@future lstSubs.size: ' + lstSubs.size());
        if(lstSubs.isEmpty()) return;

        Set<Id> quoteIds = new Set<Id>();
        for(Zuora__Subscription__c sub : lstSubs){
            quoteIds.add(sub.Master_Quote__c);
        }

        Map<String, String> quoteQRPMap = new Map<String, String>();
        String discountRatePlanName = '%' + Constants.DISCOUNT_RATE_PLAN_NAME.tolowerCase() + '%';
        List<zqu__QuoteRatePlan__c> lstQRP = [SELECT zqu__Quote__c, zqu__QuoteProductName__c FROM zqu__QuoteRatePlan__c WHERE zqu__Quote__c IN :quoteIds AND (NOT zqu__ProductRatePlan__r.Name LIKE :discountRatePlanName)];
        for(zqu__QuoteRatePlan__c qRP : lstQRP){
            quoteQRPMap.put(qRP.zqu__Quote__c, qRP.zqu__QuoteProductName__c);
        }

        Map<String, List<String>> productNameIdMap = new Map<String, List<String>>();
        List<zqu__ZProduct__c> lstProduct = [SELECT Name, zqu__ZuoraId__c FROM zqu__ZProduct__c WHERE Name IN :quoteQRPMap.values()];
        for(zqu__ZProduct__c prod : lstProduct){
            productNameIdMap.put(prod.Name, new List<String>{prod.Id, prod.zqu__ZuoraId__c});
        }

        //each promo code can be used by many subs
        Map<String, List<List<String>>> promoCodeAccountProductSubMap = new Map<String, List<List<String>>>();
        for(Zuora__Subscription__c sub : lstSubs){
            if(promoCodeAccountProductSubMap.containsKey(sub.PromoCode__c)){
                promoCodeAccountProductSubMap.get(sub.PromoCode__c).add(new List<String>{sub.Zuora__Account__c, productNameIdMap.get(quoteQRPMap.get(sub.Master_Quote__c))[0], productNameIdMap.get(quoteQRPMap.get(sub.Master_Quote__c))[1], sub.Id, sub.Zuora__External_Id__c});
            }else{
                promoCodeAccountProductSubMap.put(sub.PromoCode__c, new List<List<String>>{new List<String>{sub.Zuora__Account__c, productNameIdMap.get(quoteQRPMap.get(sub.Master_Quote__c))[0], productNameIdMap.get(quoteQRPMap.get(sub.Master_Quote__c))[1], sub.Id, sub.Zuora__External_Id__c}});
            }
        }

        List<Restricted_Offer_Usage__c> lstROU = new List<Restricted_Offer_Usage__c>();
        CoreApiResources.CoreApiOffers allOffers = CoreAPICalloutUtility.GetAllOfferCodes();
        if(allOffers != null && allOffers.offers != null && allOffers.offers.size() > 0){
            for(CoreApiResources.CoreApiOfferDetails offer : allOffers.offers){
                if(String.isNotBlank(offer.tmgId) && offer.isRestricted != null && offer.isRestricted && offer.containsFreeTrial != null && promoCodeAccountProductSubMap.containsKey(offer.tmgId)){
                    String typeOfOffer = offer.containsFreeTrial ? Constants.OFFER_TYPE_FREE_TRIAL : Constants.OFFER_TYPE_INTRODUCTORY;
                    for(List<String> lstAccountProductSub : promoCodeAccountProductSubMap.get(offer.tmgId)){
                        lstROU.add(new Restricted_Offer_Usage__c(Account__c = lstAccountProductSub[0], Product__c = lstAccountProductSub[1], Zuora_Product_Id__c = lstAccountProductSub[2], Subscription__c = lstAccountProductSub[3], Zuora_Subscription_Id__c = lstAccountProductSub[4], Type_Of_Offer__c = typeOfOffer, Ignore_Lock_in_Period__c = false));
                    }
                }
            }
        }
        System.debug('@future lstROU size: ' + lstROU.size());
        if(lstROU.isEmpty()) return;

        Database.SaveResult[] lstResults = Database.insert(lstROU, false);
        for(Integer i=0; i<lstResults.size(); i++){
            if(!lstResults[i].isSuccess()){
                for(Database.Error er : lstResults[i].getErrors()){
                    System.debug('Error inserting Restricted Offer Usage record: '+ er.getMessage());
                }
            }
        }
    }

}