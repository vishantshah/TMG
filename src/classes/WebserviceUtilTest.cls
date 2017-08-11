/** PP-2: Tests for WebserviceUtil
	
	Dependencies: WebserviceUtil
*/

@isTest
private class WebserviceUtilTest {
	
	private static testMethod void testWSError(){
		WebserviceUtil.WSError err = new WebserviceUtil.WSError('1', 'fail');
		System.assertEquals(err.errorCode, '1');
		System.assertEquals(err.errorMessage, 'fail');
	}

	private static testMethod void testWSException(){
		
		Exception ex;
		
		try{
			throw new WebserviceUtil.WSException();
		} catch (WebserviceUtil.WSException wse){
			System.assertEquals(wse.getError().errorCode, '1');
			ex = wse;
		}
		System.assertNotEquals(null, ex);
		System.assert(ex instanceof WebserviceUtil.WSException);
	}
	
	private static testMethod void testGuidInUseException(){	

		Exception ex;
		
		try{
			throw new WebserviceUtil.GuidInUseException();
		} catch (WebserviceUtil.WSException wse){
			System.assertEquals(wse.getError().errorCode, '2');
			ex = wse;
		}
		System.assertNotEquals(null, ex);
		System.assert(ex instanceof WebserviceUtil.GuidInUseException);
	}
		
	private static testMethod void testUnknownTSNumberException(){	

		Exception ex;
		
		try{
			throw new WebserviceUtil.UnknownTSNumberException();
		} catch (WebserviceUtil.WSException wse){
			System.assertEquals(wse.getError().errorCode, '3');
			ex = wse;
		}
		System.assertNotEquals(null, ex);
		System.assert(ex instanceof WebserviceUtil.UnknownTSNumberException);
	}
		
	private static testMethod void testInvalidFieldException(){	

		Exception ex;
		
		try{
			throw new WebserviceUtil.InvalidFieldException('name', 'value', 'correct');
		} catch (WebserviceUtil.WSException wse){
			System.assertEquals(wse.getError().errorCode, '4');
			System.assert(wse.getError().errorMessage.contains('name'));
			System.assert(wse.getError().errorMessage.contains('value'));
			System.assert(wse.getError().errorMessage.contains('correct'));
			ex = wse;
		}
		System.assertNotEquals(null, ex);
		System.assert(ex instanceof WebserviceUtil.InvalidFieldException);
	}	
		
	private static testMethod void testNullParameterException(){	

		Exception ex;
		
		try{
			throw new WebserviceUtil.NullParameterException('testParam', '');
		} catch (WebserviceUtil.WSException wse){
			System.assertEquals(wse.getError().errorCode, '5');
			System.assert(wse.getError().errorMessage.contains('testParam'));
			ex = wse;
		}
		System.assertNotEquals(null, ex);
		System.assert(ex instanceof WebserviceUtil.NullParameterException);
	}
	
	private static testMethod void testTooManyRecordsException(){	

		Exception ex;
		
		try{
			throw new WebserviceUtil.TooManyRecordsException();
		} catch (WebserviceUtil.WSException wse){
			System.assertEquals(wse.getError().errorCode, '7');
			ex = wse;
		}
		System.assertNotEquals(null, ex);
		System.assert(ex instanceof WebserviceUtil.TooManyRecordsException);
	}	
		
	private static testMethod void testUnknownOrderIdException(){	

		Exception ex;
		
		try{
			throw new WebserviceUtil.UnknownOrderIdException('testParam', '');
		} catch (WebserviceUtil.WSException wse){
			System.assertEquals(wse.getError().errorCode, '8');
			System.assert(wse.getError().errorMessage.contains('testParam'));
			ex = wse;
		}
		System.assertNotEquals(null, ex);
		System.assert(ex instanceof WebserviceUtil.UnknownOrderIdException);
	}
	
	private static testMethod void testGenericWSException(){
		
		Exception ex;
		
		try{
			throw new WebserviceUtil.GenericWSException('100', 'TEST');
		} catch (WebserviceUtil.WSException wse){
			System.assertEquals(wse.getError().errorCode, '100');
			ex = wse;
		}
		System.assertNotEquals(null, ex);
		System.assert(ex instanceof WebserviceUtil.GenericWSException);
	}	
		
	private static testMethod void testDatabaseValidationException(){	

		Exception ex;
		
		try{
			throw new WebserviceUtil.DatabaseValidationException('testParam', '');
		} catch (WebserviceUtil.WSException wse){
			System.assertEquals(wse.getError().errorCode, '9');
			System.assert(wse.getError().errorMessage.contains('testParam'));
			ex = wse;
		}
		System.assertNotEquals(null, ex);
		System.assert(ex instanceof WebserviceUtil.DatabaseValidationException);
	}
	
}