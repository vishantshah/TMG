/************************************************************************************
Class Name   : JSONUtilityTest
Author       : Vishant Shah
Created Date : 02/12/2016
Function     : Test Class for JSONUtility
Change Log:
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
* Developer             Date         Description
* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
*************************************************************************************/
@isTest
private class JSONUtilityTest {
    
    /************************************************************************************
    Method Name  : testJSONUtility
    Author       : Vishant Shah
    Created Date : 02/12/2016
    Function     : Test class to make sure the JSONUtility class returns back the right response for various object types
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    private static testMethod void testJSONUtility() {
        Map<String, Object> jsonMap = new Map<String, Object>();
        jsonMap.put('oBoolean', true);
        jsonMap.put('oId', Id.valueOf('001xa000003DIlo'));
        jsonMap.put('oString', 'testString');
        jsonMap.put('oBlob', Blob.valueOf('BlobString'));        
        jsonMap.put('oDateTime', DateTime.now());
        jsonMap.put('oInteger', 1) ;
        jsonMap.put('oLong', 2147483648L);
        jsonMap.put('oDouble', 3.14159);
        
        String jsonString                       = JSONUtility.getJSONString(jsonMap);
        JSONUtilityTest.JSONTestWrapper wrapper = (JSONUtilityTest.JSONTestWrapper)System.JSON.deserialize(jsonString, JSONUtilityTest.JSONTestWrapper.Class);
        
        System.assertEquals(jsonMap.get('oBoolean'), wrapper.oBoolean);
        System.assertEquals(jsonMap.get('oId'), wrapper.oId);
        System.assertEquals(jsonMap.get('oString'), wrapper.oString);
        System.assertEquals(jsonMap.get('oBlob'), wrapper.oBlob);
        System.assertEquals(jsonMap.get('oDateTime'), wrapper.oDateTime);
        System.assertEquals(jsonMap.get('oInteger'), wrapper.oInteger);
        System.assertEquals(jsonMap.get('oLong'), wrapper.oLong);
        System.assertEquals(jsonMap.get('oDouble'), wrapper.oDouble);
    }

    /************************************************************************************
    Class Name   : JSONTestWrapper
    Author       : Vishant Shah
    Created Date : 02/12/2016
    Function     : Wrapper class to hold response back from JSONUtility and Assert values.
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer             Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    
    @testVisible
    private class JSONTestWrapper{
        public Boolean oBoolean {get; set;}
        public Id oId {get; set;}
        public String oString {get; set;}
        public Blob oBlob {get; set;}
        public DateTime oDateTime {get; set;}
        public Integer oInteger {get; set;}
        public Long oLong {get; set;}
        public Double oDouble {get; set;}
    }
    
}