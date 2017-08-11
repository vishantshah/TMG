public class TMGUnitTestUtil {
	private static List<SObject> objects;
	private static List<List<SObject>> objectTree;
	public static final String INS = 'insert';
	public static final String UPD = 'update';	
	
	/*
	* Part of the fix in avoiding the MIXED_DML_OPERATION involves
	* running the Setup Object DML in a separate context. This method returns
	* a user making this possible.
	*/	
	public static List<SObject> doAsyncDml(List<SObject> s, String op){
		objects = s;
		
		// Test.start/stopTest forces the async @future to run synchronously.
		Test.startTest();
		
		asyncDml(op);
		
		Test.stopTest();		
		
		return objects;
	}
	
	// deal with situations where we have different types of setup objects
	public static void doAsyncDml(List<List<SObject>> objs, String op){
		objectTree = objs;
		
		Test.startTest();
		
		asyncDmlObjTree(op);
		
		Test.stopTest();
		
	}
	
	public static List<SObject> doAsyncInsert(List<SObject> s){
		return doAsyncDml(s, INS);
	}
	
	public static List<SObject> doAsyncUpdate(List<SObject> s){
		return doAsyncDml(s, UPD);
	}
	
	public static SObject doAsyncDml(SObject s, String op){
		return doAsyncDml(new List<SObject>{s}, op)[0];
	}
	
	public static SObject doAsyncInsert(SObject s){
		return doAsyncDml(new List<SObject>{s}, INS)[0];
	}
	
	public static SObject doAsyncUpdate(SObject s){
		return doAsyncDml(new List<SObject>{s}, UPD)[0];
	}
	
	// Future method that makes the DML occur in separate context.
	// Returns SObject so that we can track ID if DML is an insert
	@future
	private static void asyncDml(String op){
		// Grab a user to perform the async DML as
		User u = [SELECT id FROM User WHERE id=:UserInfo.getUserId()];
		
		System.debug('objects: '+objects);
		
		System.runAs(u){
			if(op==INS){
				insert objects;
			}else if(op==UPD){
				update objects;
			}
		}
	}
	
	// Specific method is required since the previous method doesn't handle multiple
	// lists that are statically referred to by the same variable. It "loses" some
	// along the way. Hence the bad DML (insert/update inside a loop).
	@future
	private static void asyncDmlObjTree(String op){
		// Grab a user to perform the async DML as
		User u = [SELECT id FROM User WHERE id=:UserInfo.getUserId()];
				
		System.runAs(u){
			if(op==INS){
				for(List<SObject> objs: objectTree){
					insert objs;
				}				
			}else if(op==UPD){
				for(List<SObject> objs: objectTree){
					update objs;
				}
			}
		}
	}	

}