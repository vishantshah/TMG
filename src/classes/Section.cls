/**
* Author:       Vishant Shah
* Date:         28/06/2017
* Description:  Wrapper class to hold sections and section fields from Case_Layout_Definition__mdt
* ******************* Change Log *******************
* Modified by 	Change Date
**/
public class Section{
    public String name                       { get; set; }
    public Boolean showHeader                { get; set; }
    public Integer columns                   { get; set; }
    public List<SectionFields> sectionFields { get; set; }

    public class SectionFields{
	    public String fieldName { get; set; }
	    public String style     { get; set; }
	    public Boolean required { get; set; }
	    public Boolean empty    { get; set; }
	    
	    public SectionFields (){}
	    
	    public SectionFields (String fieldName, String style, Boolean required, Boolean empty){
	        this.fieldName = fieldName;
	        this.required  = required;
	        this.style     = style;
	        this.empty     = empty;
	    }
	}
}