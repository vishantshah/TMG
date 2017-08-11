<?xml version="1.0" encoding="utf-8"?> 
<authenticationRequest xmlns:user="http://www.evolok.com/api/users" 
xmlns:type="http://www.evolok.com/api/types" 
xmlns="http://www.evolok.com/api/sessions"> 
<serviceKey>{0}</serviceKey> 
<identifiers><type:key>EMAIL_ADDRESS</type:key> 
<type:value>{1}</type:value> 
</identifiers> 
<validators> 
<type:key>PASSWORD</type:key> 
<type:value>{2}</type:value> 
</validators> 
</authenticationRequest>