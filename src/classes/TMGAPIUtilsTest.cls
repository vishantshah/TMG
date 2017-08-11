/*
 * File Name   : TMGAPIUtilsTest
 * Description : Test class for TMGAPIUtils
 *
 * Modification Log
 * ======================================================== 
 * Ver Date       Author         Modification
 * --- ---------- -------------- --------------------------
 * 1.0 30/01/2014 IVAN ALMEIDA	 Initial Version 
 */
 @isTest
public class TMGAPIUtilsTest {
	
	//Test callout for GET with full endpoint
	static testmethod void testCallOutGet () {
		StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
		mock.setStaticResource('ChangeSubscriptionWithoutChargeSuccess');
		mock.setStatusCode(200);
		mock.setHeader('Content-Type', 'application/json');
		
		Test.setMock(HttpCalloutMock.class, mock);
		
		Test.startTest();
		
		Dom.Document responseDoc = TMGAPIUtils.callOutGet('test.endpoint');
		
		Test.stopTest();

		System.assertEquals(TMGAPIUtils.response.getStatusCode(), 200);
		System.assertEquals(responseDoc.toXmlString(), TMGAPIUtils.response.getBodyDocument().toXmlString());
	}
	
	//Test callout for GET with parameters to build
	static testmethod void testCallOutGetWithParams () {
		StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
		mock.setStaticResource('ChangeSubscriptionWithoutChargeSuccess');
		mock.setStatusCode(200);
		mock.setHeader('Content-Type', 'application/json');
		
		Test.setMock(HttpCalloutMock.class, mock);
		
		Map<String,String> parameters = new Map<String, String>();
		parameters.put('key1', 'value1');
		parameters.put('key2', 'value2');
		Test.startTest();
		
		Dom.Document responseDoc = TMGAPIUtils.callOutGet('test.endpoint', parameters);
		
		Test.stopTest();
		
		System.assertEquals(TMGAPIUtils.response.getStatusCode(), 200);
		System.assertEquals(responseDoc.toXmlString(), TMGAPIUtils.response.getBodyDocument().toXmlString());
	}
	
	//Test callout for GET for unsuccessful execution
	static testmethod void testCallOutGetWithParamsUnsuccessful () {
		StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
		mock.setStaticResource('ChangeSubscriptionWithoutChargeSuccess');
		mock.setStatusCode(404);
		mock.setStatus('TEST - Not found');
		mock.setHeader('Content-Type', 'application/json');
		
		Test.setMock(HttpCalloutMock.class, mock);
		
		Map<String,String> parameters = new Map<String, String>();
		parameters.put('key1', 'value1');
		parameters.put('key2', 'value2');
		Test.startTest();
		Boolean errorCaught = false;
		try {
			TMGAPIUtils.callOutGet('test.endpoint', parameters);
			System.assert(false, 'Error must be thrown before');
		}
		catch (TMGAPIUtils.UnsuccessfullResponseException USRex) {
			errorCaught = true;
			System.assertEquals(USRex.getErrorCode(), '404');
			System.assertEquals(USRex.getErrorMessage(),'TEST - Not found');
		}
		
		Test.stopTest();
		
		System.assert(errorCaught);
	}
	
	//Test callout for POST with a string template and a TEXT request
	static testmethod void testCallOutPostTextTemplate () {
		StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
		mock.setStaticResource('ChangeSubscriptionWithoutChargeSuccess');
		mock.setStatusCode(200);
		mock.setHeader('Content-Type', 'application/json');
		
		Test.setMock(HttpCalloutMock.class, mock);
		
		List<String> values = new List<String>{'value1','value2'};
		String template = 'key1={0}&key2={1}';
		
		Test.startTest();
		
		Dom.Document responseDoc = TMGAPIUtils.callOutPost('test.endpoint', values, template, TMGAPIUtils.BodyType.TEXT);
		
		Test.stopTest();
		
		System.assertEquals(TMGAPIUtils.response.getStatusCode(), 200);
		System.assertEquals(responseDoc.toXmlString(), TMGAPIUtils.response.getBodyDocument().toXmlString());
	}
	
	//Test callout for POST with a string template and an XML request
	static testmethod void testCallOutPostXMLTemplate () {
		StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
		mock.setStaticResource('ChangeSubscriptionWithoutChargeSuccess');
		mock.setStatusCode(200);
		mock.setHeader('Content-Type', 'application/json');
		
		Test.setMock(HttpCalloutMock.class, mock);
		
		List<String> values = new List<String>{'value1','value2'};
		String template = '<request><key1>{0}</key1><key2>{1}</key2></request>';
		
		Test.startTest();
		
		Dom.Document responseDoc = TMGAPIUtils.callOutPost('test.endpoint', values, template, TMGAPIUtils.BodyType.XML);
		
		Test.stopTest();
		
		System.assertEquals(TMGAPIUtils.response.getStatusCode(), 200);
		System.assertEquals(responseDoc.toXmlString(), TMGAPIUtils.response.getBodyDocument().toXmlString());
	}
	
	//Test callout for POST with parameters to build
	static testmethod void testCallOutPostWithParams () {
		StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
		mock.setStaticResource('ChangeSubscriptionWithoutChargeSuccess');
		mock.setStatusCode(200);
		mock.setHeader('Content-Type', 'application/json');
		
		Test.setMock(HttpCalloutMock.class, mock);
		
		Map<String,String> parameters = new Map<String, String>();
		parameters.put('key1', 'value1');
		parameters.put('key2', 'value2');
		Test.startTest();
		
		Dom.Document responseDoc = TMGAPIUtils.callOutPost('test.endpoint', parameters);
		
		Test.stopTest();
		System.assertEquals(TMGAPIUtils.response.getStatusCode(), 200);
		System.assertEquals(responseDoc.toXmlString(), TMGAPIUtils.response.getBodyDocument().toXmlString());
	}
	
	//Test callout for POST with a full XML body
	static testmethod void testCallOutPostFullXML() {
		StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
		mock.setStaticResource('ChangeSubscriptionWithoutChargeSuccess');
		mock.setStatusCode(200);
		mock.setHeader('Content-Type', 'application/json');
		
		Test.setMock(HttpCalloutMock.class, mock);
		String bodyDoc = '<request><key1>value1</key1><key2>value2</key2></request>';
		
		Test.startTest();
		
		Dom.Document responseDoc = TMGAPIUtils.callOutPost('test.endpoint', bodyDoc, TMGAPIUtils.BodyType.XML);
		
		Test.stopTest();
		
		System.assertEquals(TMGAPIUtils.response.getStatusCode(), 200);
		System.assertEquals(responseDoc.toXmlString(), TMGAPIUtils.response.getBodyDocument().toXmlString());
	}
	
	//Test callout for POST with a full TEXT body
	static testmethod void testCallOutPostFullTEXT() {
		StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
		mock.setStaticResource('ChangeSubscriptionWithoutChargeSuccess');
		mock.setStatusCode(200);
		mock.setHeader('Content-Type', 'application/json');
		
		Test.setMock(HttpCalloutMock.class, mock);
		String bodyDoc = 'key1=value1&key2=value2';
		
		Test.startTest();
		
		Dom.Document responseDoc = TMGAPIUtils.callOutPost('test.endpoint', bodyDoc, TMGAPIUtils.BodyType.TEXT);
		
		Test.stopTest();
		
		System.assertEquals(TMGAPIUtils.response.getStatusCode(), 200);
		System.assertEquals(responseDoc.toXmlString(), TMGAPIUtils.response.getBodyDocument().toXmlString());
	}
	
	//Test callout for POST with a full XML body in a Dom.Document format
	static testmethod void testCallOutPostFullXMLDocument() {
		StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
		mock.setStaticResource('ChangeSubscriptionWithoutChargeSuccess');
		mock.setStatusCode(200);
		mock.setHeader('Content-Type', 'application/json');
		
		Test.setMock(HttpCalloutMock.class, mock);
		Dom.Document requestDoc = new Dom.Document();
		
		Test.startTest();
		
		Dom.Document responseDoc = TMGAPIUtils.callOutPost('test.endpoint', requestDoc, TMGAPIUtils.BodyType.ETXML);
		
		Test.stopTest();
		
		System.assertEquals(TMGAPIUtils.response.getStatusCode(), 200);
		System.assertEquals(responseDoc.toXmlString(), TMGAPIUtils.response.getBodyDocument().toXmlString());
	}
	
	//Test callout for POST with a full XML body in a String format
	static testmethod void testCallOutPostFullTextString() {
		StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
		mock.setStaticResource('ChangeSubscriptionWithoutChargeSuccess');
		mock.setStatusCode(200);
		mock.setHeader('Content-Type', 'application/json');
		
		Test.setMock(HttpCalloutMock.class, mock);
		String bodyDoc = 'key1=value1&key2=value2';
		
		Test.startTest();
		
		Dom.Document responseDoc = TMGAPIUtils.callOutPost('test.endpoint', bodyDoc);
		
		Test.stopTest();
		
		System.assertEquals(TMGAPIUtils.response.getStatusCode(), 200);
		System.assertEquals(responseDoc.toXmlString(), TMGAPIUtils.response.getBodyDocument().toXmlString());
	}
}