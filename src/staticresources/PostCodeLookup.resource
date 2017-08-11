    var account_code='CAPGE11124';
    var license_code='TR95-HE67-AT67-FJ98';
    var machine_id='';

function Populate(){
	
    document.getElementById(Field1).value = '' + pca_line1[0] + '\r\n' + pca_line2[0] + '\r\n' + pca_line3[0] + '\r\n' + pca_line4[0] + '\r\n' + pca_line5[0];
    document.getElementById(Field2).value = '' + pca_post_town[0];
    //code Jayant
    if(document.getElementById(Field3).tagName != 'SELECT')
    {
     document.getElementById(Field3).value = '' + pca_county[0];
    }else if(document.getElementById(Field3).tagName == 'SELECT')
    {
            //remove all states and insert county in state dropdown
            for(i=0;i<document.getElementById(Field3).length;i++)
            {
             document.getElementById(Field3).options.length=0;
            } 
            if(pca_county[0]=='')
            {
                
                document.getElementById(Field3).disabled=true;
                var optCounty = document.createElement("option");
                optCounty.text = '--Not Applicable--';
                optCounty.value = '' + pca_county[0];
                document.getElementById(Field3).add(optCounty,document.getElementById(Field3)[0]);

            }else
            {
            document.getElementById(Field3).disabled=false;
            var optCounty = document.createElement("option");
            optCounty.text = '' + pca_county[0];
            optCounty.value = '' + pca_county[0];
            document.getElementById(Field3).add(optCounty,document.getElementById(Field3)[0]);
            }
    }

    if(document.getElementById(Field4) != null)
    {
       document.getElementById(Field4).options[0].selected =true;

       for(i=0;i<document.getElementById(Field4).length;i++)
       {
          if(document.getElementById(Field4).options[i].text=='United Kingdom')
          {
            document.getElementById(Field4).options[i].selected=true;
               
          }
       }
    }
    //end code Jayant
}

function BeginPostCodeLookup(){
	var postcode = document.getElementById(PostCode).value;
    var scriptTag = document.getElementById("pcaScriptTag");
    var headTag = document.getElementsByTagName("head").item(0);
    var strUrl = "";
    
    //document.getElementById("divLoading").style.display = '';
//alert(postcode);
    //Build the url
    strUrl = "https://services.postcodeanywhere.co.uk/inline.aspx?";
    strUrl += "action=lookup";
    strUrl += "&type=by_postcode";
    strUrl += "&postcode=" + escape(postcode);
    strUrl += "&account_code=" + escape(account_code);
    strUrl += "&license_code=" + escape(license_code);
    strUrl += "&machine_id=" + escape(machine_id);
    strUrl += "&callback=EndPostCodeLookup";

    //Make the request
    if (scriptTag)
    {
    //The following 2 lines perform the same function and should be interchangeable
    //headTag.removeChild(scriptTag); PP-1429 - commented this line and uncommented the below to get it work in IE8
    scriptTag.parentNode.removeChild(scriptTag);
    }
    
    scriptTag = document.createElement("script");
    scriptTag.src = strUrl;
    scriptTag.type = "text/javascript";
    scriptTag.id = "pcaScriptTag";
    headTag.appendChild(scriptTag);
    //alert(strUrl);
    
    document.getElementById(selectaddressblock).style.display = '';
    document.getElementById(SelectAddressLabel).style.display = '';
	
}

    function EndPostCodeLookup()
    {
    //document.getElementById("divLoading").style.display = 'none';

    //Test for an error
    if (pcaIsError)
    {    
    //Show the error message
    document.getElementById("selectaddress").style.display = 'none';
	document.getElementById(SelectAddressLabel).style.display = 'none';
    document.getElementById(btnFetch).style.display = 'none';
    alert(pcaErrorMessage);
    }
    else
    {
    //Check if there were any items found
    if (pcaRecordCount==0)
    {
    document.getElementById("selectaddress").style.display = 'none';
		document.getElementById(SelectAddressLabel).style.display = 'none';
    document.getElementById(btnFetch).style.display = 'none';
    alert("Sorry, no matching items found. Please try another postcode.");
    }
    else
    {
    document.getElementById("selectaddress").style.display = '';
		document.getElementById(SelectAddressLabel).style.display = '';
    document.getElementById(btnFetch).style.display = '';
    
    for (var i=document.getElementById("selectaddress").options.length-1; i >= 0; i--){
    document.getElementById("selectaddress").options[i] = null;
    }
    for (i=0; i < pca_id.length; i++){
                        document.getElementById("selectaddress").options[document.getElementById("selectaddress").length] = new Option(pca_description[i], pca_id[i]);
                      }
                   }
             }
             
       }

    function PostCodeLookupFetchBegin()
       {
          var address_id = document.getElementById("selectaddress").value;
          var scriptTag = document.getElementById("pcaScriptTag");
          var headTag = document.getElementsByTagName("head").item(0);
          var strUrl = "";

          //Build the url
          strUrl = "https://services.postcodeanywhere.co.uk/inline.aspx?";
          strUrl += "&action=fetch";
    strUrl += "&id=" + escape(address_id);
    strUrl += "&account_code=" + escape(account_code);
    strUrl += "&license_code=" + escape(license_code);
    strUrl += "&machine_id=" + escape(machine_id);
    strUrl += "&callback=PostCodeLookupFetchEnd";

    //Make the request
    if (scriptTag)
    {
    //The following 2 lines perform the same function and should be interchangeable
    //headTag.removeChild(scriptTag); PP-1429 - commented this line and uncommented the below to get it work in IE8
    scriptTag.parentNode.removeChild(scriptTag);
    }
    scriptTag = document.createElement("script");
    scriptTag.src = strUrl
    scriptTag.type = "text/javascript";
    scriptTag.id = "pcaScriptTag";
    headTag.appendChild(scriptTag);

    document.getElementById("selectaddress").style.display = 'none';
		document.getElementById(SelectAddressLabel).style.display = 'none';
    document.getElementById(btnFetch).style.display = 'none';
    }


    function PostCodeLookupFetchEnd()
    {
		//document.getElementById(SelectAddressLabel).style.display = 'none';
    //Test for an error
    if (pcaIsError)
    {
    //Show the error message
    alert(pcaErrorMessage);
    }
    else
    {
    //Check if there were any items found
    if (pcaRecordCount==0)
    {
    alert("Sorry, no matching items found");
    }
    else
    { 
    Populate();   
    /*document.getElementById(Field1).value = '' + pca_line1[0] + ', ' + pca_line2[0] + ', ' + pca_line3[0] + '' + pca_line4[0] + '' + pca_line5[0];
    document.getElementById(Field2).value = '' + pca_post_town[0];
    document.getElementById(Field3).value = '' + pca_county[0];*/
    //document.getElementById(PostCode).value = '' + pca_postcode[0];
    }
    }
    }