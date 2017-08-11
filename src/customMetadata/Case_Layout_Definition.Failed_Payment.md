<?xml version="1.0" encoding="UTF-8"?>
<CustomMetadata xmlns="http://soap.sforce.com/2006/04/metadata" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
    <label>Failed Payment</label>
    <protected>false</protected>
    <values>
        <field>Record_Type_Name__c</field>
        <value xsi:type="xsd:string">Failed Payment</value>
    </values>
    <values>
        <field>Section_Properties__c</field>
        <value xsi:type="xsd:string">[  
   {  
      &quot;showHeader&quot;:true,
      &quot;sectionFields&quot;:[  
         { &quot;empty&quot;:false, &quot;required&quot;:false, &quot;fieldName&quot;:&quot;AccountID&quot;},
         { &quot;empty&quot;:false, &quot;required&quot;:false, &quot;fieldName&quot;:&quot;Subject&quot;}
      ],
      &quot;name&quot;:&quot;Case Information&quot;,
      &quot;columns&quot;:2
   },
   {  
      &quot;showHeader&quot;:true,
      &quot;sectionFields&quot;:[  
         { &quot;empty&quot;:true, &quot;required&quot;:false, &quot;fieldName&quot;:&quot;&quot;},
         { &quot;empty&quot;:false, &quot;required&quot;:false, &quot;fieldName&quot;:&quot;Case_Closed_Reason__c&quot;}
      ],
      &quot;name&quot;:&quot;Case Detail&quot;,
      &quot;columns&quot;:2
   },
   {  
      &quot;showHeader&quot;:true,
      &quot;sectionFields&quot;:[  
         { &quot;empty&quot;:false, &quot;required&quot;:false, &quot;fieldName&quot;:&quot;Payment__c&quot;},
         { &quot;empty&quot;:false, &quot;required&quot;:false, &quot;fieldName&quot;:&quot;Payment_Gateway_Name__c&quot;},
         { &quot;empty&quot;:false, &quot;required&quot;:false, &quot;fieldName&quot;:&quot;Payment_Status__c&quot;},
         { &quot;empty&quot;:false, &quot;required&quot;:false, &quot;fieldName&quot;:&quot;Gateway_Reason_code_source__c&quot;},
         { &quot;empty&quot;:false, &quot;required&quot;:false, &quot;fieldName&quot;:&quot;Gateway_Reason_code__c&quot;},
         { &quot;empty&quot;:false, &quot;required&quot;:false, &quot;fieldName&quot;:&quot;BACS_Report_Date__c&quot;},
         { &quot;empty&quot;:false, &quot;required&quot;:false, &quot;fieldName&quot;:&quot;Gateway_Reason_Code_detail__c&quot;},
         { &quot;empty&quot;:false, &quot;required&quot;:false, &quot;fieldName&quot;:&quot;Payer_Reference__c&quot;},    
         { &quot;empty&quot;:false, &quot;required&quot;:false, &quot;fieldName&quot;:&quot;Bank_Reference_Number__c&quot;},
         { &quot;empty&quot;:false, &quot;required&quot;:false, &quot;fieldName&quot;:&quot;Mandate_ID__c&quot;}
      ],
      &quot;name&quot;:&quot;Failed Payment Detail&quot;,
      &quot;columns&quot;:2
   },
   {  
      &quot;showHeader&quot;:true,
      &quot;sectionFields&quot;:[  
         { &quot;empty&quot;:false, &quot;required&quot;:false, &quot;fieldName&quot;:&quot;Subscription__c&quot;}
      ],
      &quot;name&quot;:&quot;Subscription Details&quot;,
      &quot;columns&quot;:2
   },
   {  
      &quot;showHeader&quot;:true,
      &quot;sectionFields&quot;:[  
         { &quot;empty&quot;:false, &quot;required&quot;:false, &quot;fieldName&quot;:&quot;Description&quot;}
      ],
      &quot;name&quot;:&quot;Description Information&quot;,
      &quot;columns&quot;:2
   }
]</value>
    </values>
</CustomMetadata>
