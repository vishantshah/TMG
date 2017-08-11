public with sharing class CustomValidator {

	static Map<String, String> customValidationFieldMap = new Map<String, String>();
	static Map<String, Map<String, Map<String, Map<String, Map<String, Set<String>>>>>> megaMap = new Map<String, Map<String, Map<String, Map<String, Map<String, Set<String>>>>>>();
	static String allowedMessage = 'Allowed values for {0} are : {1}';

	public static void validate(String objectName, List<sObject> recordsToValidate){

		getObjectFieldsToValidate(objectName);
		System.debug('Start ' + Datetime.now());
		getCustomValidationRules(objectName);
		System.debug(megaMap);

		for (sObject thisRecord : recordsToValidate){

			String recordTypeId = getFieldValue(thisRecord,'RecordTypeId');
			String level1Key    = getFieldValue(thisRecord,'Reason');
			String level2Key    = getFieldValue(thisRecord,'Type_Of_Issue__c');
			String level3Key    = getFieldValue(thisRecord,'Digital_Details__c');
			String level4Key    = getFieldValue(thisRecord,'Digital_Details_2__c');
			String level5Key    = getFieldValue(thisRecord,'Digital_Details_3__c');

			if (megaMap != null && megaMap.containsKey(recordTypeId)){

				Map<String, Map<String, Map<String, Map<String, Set<String>>>>> reasons = megaMap.get(recordTypeId);

				if (reasons != null && reasons.containsKey(level1Key)){
					
					Map<String, Map<String, Map<String, Set<String>>>> level2 = reasons.get(level1Key);
					
					if (level2 != null && level2.containsKey(level2Key)){

						Map<String, Map<String, Set<String>>> level3 = level2.get(level2Key);
						
						if (level3 != null && level3.containsKey(level3Key)){

							Map<String,Set<String>> level4 = level3.get(level3Key);
							
							if (level4 != null && level4.containsKey(level4Key)){

								Set<String> level5 = level4.get(level4Key);
								
								if (level5Key != null && !level5.contains(level5Key)){
									addError(thisRecord, level5, 'Case Detail 4');
								}

							} else if (level4Key != null) {
								addError(thisRecord, level4.keySet(), 'Case Detail 3');
							}

						} else if (level3Key != null) {
							addError(thisRecord, level3.keySet(), 'Case Detail 2');
						}

					} else if (level2Key != null) {
						addError(thisRecord, level2.keySet(), 'Case Detail 1');
					}

				} else if (level1Key != null){
					addError(thisRecord, reasons.keySet(), 'Case Reason');
				}
			}
		}

		System.debug('end ' + Datetime.now());
	}

	private static String getFieldValue(sObject thisRecord, String fieldName){
		if (thisRecord.get(fieldName) == null )
			return null;
		else 
			return String.valueOf(thisRecord.get(fieldName));
	}

	private static void addError(sObject thisRecord, Set<String> levelValues, String field){
		if (levelValues.size() == 0)
			thisRecord.addError(String.format(allowedMessage, new List<String>{field, 'None'}));
		else
			thisRecord.addError(String.format(allowedMessage, new List<String>{field, String.valueOf(levelValues)}));
	}

	private static void getObjectFieldsToValidate(String objectName){
        for (Custom_Validation_Fields__c validationField : Custom_Validation_Fields__c.getAll().values()){
            if (validationField.Object__c == objectName){
                customValidationFieldMap.put(validationField.Field__c, validationField.Mapped_To__c);
            }
        }
    }

    private static void getCustomValidationRules(String objectName){
        for (Custom_Validation__c validation : Custom_Validation__c.getAll().values()){
            if (validation.Object__c == objectName){
            	populateMegaMap(validation);
            }
        }
    }

    public static Map<String, Map<String, Map<String, Map<String, Map<String, Set<String>>>>>> getCustomValidationRules(String objectName, String recordTypeName){
        for (Custom_Validation__c validation : Custom_Validation__c.getAll().values()){
            if (validation.Object__c == objectName && recordTypeName == validation.Record_Type_Name__c){
            	populateMegaMap(validation);
            }
        }

        return megaMap;
    }

    private static void populateMegaMap(Custom_Validation__c rule){
    	
    	Id caseRecordTypeId = RecordTypeUtility.getRecordTypeId(Case.SObjectType, rule.Record_Type_Name__c, Case.class.getName());

    	if (caseRecordTypeId != null && !megaMap.containsKey(caseRecordTypeId)){
    		megaMap.put(caseRecordTypeId, new Map<String, Map<String, Map<String, Map<String, Set<String>>>>>());
    	}

	    if (caseRecordTypeId != null){	
	    	Map<String, Map<String, Map<String, Map<String, Set<String>>>>> reason = megaMap.get(caseRecordTypeId);

	    	if (rule.F1__c != null && !reason.containsKey(rule.F1__c)){
	    		reason.put(rule.F1__c, new Map<String, Map<String, Map<String, Set<String>>>>());
	    	}

	    	if (rule.F1__c != null){
		    	Map<String, Map<String, Map<String, Set<String>>>> level2 = reason.get(rule.F1__c);
		    	if (rule.F2__c != null && !level2.containsKey(rule.F2__c)){
		    		level2.put(rule.F2__c, new Map<String, Map<String, Set<String>>>());
		    	}

		    	if (rule.F2__c != null){
			    	Map<String, Map<String, Set<String>>> level3 = level2.get(rule.F2__c);
			    	if (rule.F3__c != null && !level3.containsKey(rule.F3__c) ){
			    		level3.put(rule.F3__c, new Map<String, Set<String>>());
			    	}

			    	if (rule.F3__c != null){
				    	Map<String, Set<String>> level4 = level3.get(rule.F3__c);
				    	if (rule.F4__c != null && !level4.containsKey(rule.F4__c)){
				    		level4.put(rule.F4__c, new Set<String>());
				    	}
				    
				    	if (rule.F4__c != null){
				    		if (rule.F5__c != null){
						    	Set<String> level5 = level4.get(rule.F4__c);
						    	level5.add(rule.F5__c);
				    		}
				    	}
				    	
			    	}
			    }
			}
		}
    }
}