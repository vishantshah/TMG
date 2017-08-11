/**
* Author:       Michal Szewczyk
* Date:         26/07/2016
* Description:  Interface that need to be implemented by all pages that use OutboundCallMenu component
*
* ******************* Change Log *******************
* Modified by           Change Date
**/
public interface OutboundCallMenuSwitcher {

 void validateContext();
 boolean saveContext();
 void getSelf();

}