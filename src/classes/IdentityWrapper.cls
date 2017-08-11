/************************************************************************************
Class Name   : IdentityWrapper
Author       : Vishant Shah
Created Date : 02/12/2016
Function     : Wrapper class to hold response from IdentityUtility.
Change Log:
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
* Developer             Date         Description
* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
*************************************************************************************/

public class IdentityWrapper {
    
    public String access_token {get; set;}
    public String refresh_token {get; set;}
    public String id_token {get; set;}
    public String livefyre_token {get; set;}
    public String token_type { get; set; }
    public Integer expires_in {get; set; }
    
}