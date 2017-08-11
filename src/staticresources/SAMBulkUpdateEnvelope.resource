<?xml version="1.0" encoding="UTF-8"?>
<env:Envelope xmlns:env="http://schemas.xmlsoap.org/soap/envelope/" >
   <env:Header/>
   <env:Body>
      <m:bulkUpdateRequest xmlns:m="http://ws.eb.evolok.com/">
         <!--1 to 5000 repetitions:-->
         {0}
         <uuid>{1}</uuid>
         <serviceKey>{2}</serviceKey>
      </m:bulkUpdateRequest>
   </env:Body>
</env:Envelope>