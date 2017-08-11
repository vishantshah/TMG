
 //Added Change as a part of PP-1611

 function makeOptionReadonly(currentSelObj,node) {
 
  if(currentSelObj.selectedIndex>0)
  {
   document.getElementById(node).disabled=true;
   //document.getElementById('{!$Component.form.SubDetailsEdit.pbsectionId.batchcheckId}').disabled=true;
   }
  else
   {
  document.getElementById(node).disabled=false;
  //document.getElementById('{!$Component.form.SubDetailsEdit.pbsectionId.batchcheckId}').disabled=false;
   }
  }
 function makeReadonly(currentSelObj,node) {
      if (currentSelObj.checked) {
      	 document.getElementById(node).disabled=true;
        //document.getElementById('{!$Component.form.SubDetailsEdit.pbsectionId.dropdownId}').disabled=true;
        //document.getElementById('{!$Component.form.SubDetailsEdit.pbsectionId.selectoptionPanelId}').style.visibility="hidden";
       
      } else {
         document.getElementById(node).disabled=false;
      	//document.getElementById('{!$Component.form.SubDetailsEdit.pbsectionId.dropdownId}').disabled=false;
      	//document.getElementById('{!$Component.form.SubDetailsEdit.pbsectionId.selectoptionPanelId}').style.visibility="visible";
      }
     
    }
 //End Change PP-1611 
 