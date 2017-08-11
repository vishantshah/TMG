/*
 * File Name   : TMGAPIUtils
 * Description : Generic class for HTTP callouts
 *
 * Modification Log
 * ======================================================== 
 * Ver Date       Author         Modification
 * --- ---------- -------------- --------------------------
 * 1.0 30/01/2014 IVAN ALMEIDA	 Initial Version
 * 1.1 24/07/2014 Wiktor Czykin	 Modified callOutGet() -> added parameters encoding
 * 1.2 28/11/2016 Michal Szewczyk Changed in generic callOut
 */ 
public with sharing class TMGAPIUtils {
	//Properties
	public static HttpResponse response {get;set;}
	
	//GET Method with full endpoint (including parameters) and no body
	public static Dom.Document callOutGet(string url) {
		return callOut(url, 'GET', null, null, null);
	}
	
	/*************************************************************************************** 
    Developer - Ivan Almeida
    Date - 30/01/2014
    Version - 1.1
    Function - GET Method with parameters to build and no body
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         23/07/2015  //added parameters encoding
    ****************************************************************************************/
	public static Dom.Document callOutGet(string url, Map<String,String> parameters) {
		String parameterString = '';
		for (String key : parameters.keySet()) {
			if (parameterString == '')
				parameterString += '?' + key + '=' + (String.isNotBlank(parameters.get(key))?EncodingUtil.urlEncode(parameters.get(key), 'UTF-8'):parameters.get(key));
			else
				parameterString += '&' + key + '=' + (String.isNotBlank(parameters.get(key))?EncodingUtil.urlEncode(parameters.get(key), 'UTF-8'):parameters.get(key));
		}
		url += parameterString;
		return callOut(url, 'GET', null, null, null);
	}
	
	//POST Method for XML or TEXT Request with template
	public static Dom.Document callOutPost(string url, List<String> parameters, String bodyTemplate, BodyType bType) {
		String body = String.format(bodyTemplate, parameters);
		Dom.Document doc = new Dom.Document();
		if (bType == BodyType.XML) {
			doc.load(body);
		}
		return callOut(url, 'POST', body, doc, bType);
	}
	
	//POST Method for XML or TEXT with full body, getting a string body (XML or TEXT)
	public static Dom.Document callOutPost(string url, String bodyString, BodyType bType) {
		Dom.Document doc = new Dom.Document();
		if (bType == BodyType.XML) {
			doc.load(bodyString);
		}
		return callOut(url, 'POST', bodyString, doc, bType);
	}
	
	//POST Method for TEXT with full String body
	public static Dom.Document callOutPost(string url, String bodyString) {
		return callOut(url, 'POST', bodyString, null, BodyType.TEXT);
	}
	
	//POST Method for XML with full XML body. BodyType included to support ETXML (ExactTarget)
	public static Dom.Document callOutPost(string url, Dom.Document body, BodyType bType) {
		return callOut(url, 'POST', null, body, bType);
	}
	
	//POST Method for Text body Request in a form style
	public static Dom.Document callOutPost(string url, Map<String, String> parameters) {
		String body = '';
		for (String key : parameters.keySet()) {
			if (body == '')
				body += key + '=' + parameters.get(key);
			else
				body += '&' + key + '=' + parameters.get(key);
		}
		return callOut(url, 'POST', body, null, BodyType.TEXT);
	}
	
	//Do generic callout
	private static Dom.Document callOut(string url, String method, String StringBody, Dom.Document docBody, BodyType bType){
        //HTTP objects
        HttpRequest req;
        HttpResponse res;
		System.debug('Request endpoint -> ' + url);
		Http h = new Http();
		
		//Set request
		req = new HttpRequest();
		req.setEndpoint(url);
		req.setMethod(method);
		req.setTimeout(60000);
		
		//Set xml body
		if (bType == BodyType.XML) {
		   req.setHeader('Content-Type', 'application/xml');
		   req.setBody(stringBody);
		}
		if (bType == BodyType.TEXT) {
			req.setBody(stringBody);
		}
		if (bType == BodyType.ETXML) {
			String requestString = docBody.toXmlString();
			String requestEncoded = EncodingUtil.urlEncode(requestString, 'UTF-8');
            req.setHeader('Content-Length', ''+requestEncoded.length());
            req.setBody('qf=xml&xml='+requestEncoded);
            req.setTimeout(60000);
		}
		
		//Send request and return response or error
		res = h.send(req);
		if(res.getStatusCode() != 200){
			throw new UnsuccessfullResponseException(string.valueOf(res.getStatusCode()), res.getStatus());
		}
		
		response = res;
		return res.getBodyDocument();
	}
	
	//Body types available
	public enum BodyType {XML,TEXT, ETXML}
	
	/**
	* @author Unknown
	* @date Unknown
	* @description Custom exception for callouts
	#############Change Log#############
	Modified by     Version     Change Date
	Wiktor Czykin   1.1         14/07/2015  //made sure getMessage() returns what it should
	**/
	public class UnsuccessfullResponseException extends Exception{
		private string errorCode;
		private string errorMessage;
		
		public UnsuccessfullResponseException(string errorCode, string errorMessage){
			this(errorMessage);
			this.errorCode = errorCode;
			this.errorMessage = errorMessage;
		}
		
		public string getErrorCode(){
			return errorCode;
		}
		
		public string getErrorMessage(){
			return errorMessage;
		}
	}

}