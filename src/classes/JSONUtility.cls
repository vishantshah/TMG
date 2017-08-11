/************************************************************************************
Class Name   : JSONUtility
Author       : Vishant Shah
Created Date : 02/12/2016
Function     : Utility Class to generate JSON string
Change Log:
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
* Developer             Date         Description
* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
*************************************************************************************/
public class JSONUtility {

    /************************************************************************************
    Method Name  : getJSONString
    Author       : Vishant Shah
    Created Date : 02/12/2016
    Function     : Method to generate JSON String from a map of String and Object. Object can be :Boolean, Id, String,
                   Blob, Datetime, Integer, Long, Double.
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    public static String getJSONString(Map<String, Object> fieldValues){
        
        System.JSONGenerator jsonGen = System.JSON.createGenerator(true);
        
        jsonGen.writeStartObject();
        
        for (String field : fieldValues.keySet()){
            
            Object o = fieldValues.get(field);

            if (o != null){
                if(o instanceof Boolean)                 jsonGen.writeBooleanField(field, (Boolean)o);
                else if(o instanceof Id)                 jsonGen.writeIdField(field, (Id)o);
                else if(o instanceof String)             jsonGen.writeStringField(field, (String)o);
                else if(o instanceof Blob)               jsonGen.writeBlobField(field, (Blob)o);
                else if(o instanceof Datetime)           jsonGen.writeDateTimeField(field, (DateTime)o);
                else if(o instanceof Integer)            jsonGen.writeNumberField(field, (Integer)o);
                else if(o instanceof Long)               jsonGen.writeNumberField(field, (Long)o);
                else if(o instanceof Double)             jsonGen.writeNumberField(field, (Double)o); 
            }
        }

        jsonGen.writeEndObject();

		return jsonGen.getAsString();        
    }

}