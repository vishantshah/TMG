/************************************************************************************
Class Name   : MyNewsletterWrapper
Author       : Vishant Shah
Created Date : 02/12/2016
Function     : Wrapper class to hold what newletters a Account (Subscriber) holds
Change Log:
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
* Developer             Date         Description
* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
*************************************************************************************/
public class MyNewsletterWrapper{
    
    public String tsNumber { get; set; }
    public List<Newsletters> newsletters { get; set; } 
    
    public class Newsletters  implements Comparable {
        public String id { get; set; }
        public String category { get; set; }
        public String name { get; set; }
        public String frequency { get; set; }
        public String imageUrl { get; set; }
        public String sampleUrl { get; set; }
        public String description { get; set; }
        public String customerStatus { get; set; }
        public Boolean hideSample { get; set; }
        public Boolean retired { get; set; }
        public Boolean defaultAccess { get; set; }
        public Integer counter { get; set; }
        public String categoryName { get { return category + name; } }

        
        public Integer compareTo(Object compareTo) {
            MyNewsletterWrapper.Newsletters compareToNewsletter = (MyNewsletterWrapper.Newsletters)compareTo;
            
            if(categoryName == compareToNewsletter.categoryName)
                return 0;
            else if(categoryName > compareToNewsletter.categoryName)
                return 1;
            else
                return 0;
        }
    }
}