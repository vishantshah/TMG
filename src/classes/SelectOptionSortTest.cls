@isTest
private class SelectOptionSortTest {

    static testMethod void testSorting() {
    	set<string> items = new set<string>();
		items.add('DIGITAL_SUBSCRIBER_ACTIVE');
		items.add('7DAY_SUBSCRIBER_ACTIVE');
		items.add('IPHONE_SUBSCRIBER_INACTIVE');
		items.add('DIGITAL_SUBSCRIBER_INACTIVE');
		items.add('7DAY_SUBSCRIBER_LAPSED');
		items.add('WEBPACK_SUBSCRIBER_ACTIVE');
		items.add('ANDROIDTABLET_SUBSCRIBER_ACTIVE');
		items.add('SALESFORCE');
		items.add('7DAY_SUBSCRIBER_IN_RENEWAL');
		items.add('ANDROIDTABLET_SUBSCRIBER_INACTIVE');
		items.add('KINDLEFIRE_SUBSCRIBER_INACTIVE');
		items.add('IPHONE_SUBSCRIBER_ACTIVE');
		items.add('IPAD_SUBSCRIBER_INACTIVE');
		items.add('KINDLEFIRE_SUBSCRIBER_ACTIVE');
		items.add('7DAY_SUBSCRIBER_RECENTLY_LAPSED');
		items.add('IPAD_SUBSCRIBER_ACTIVE');
		items.add('7DAY_SUBSCRIBER_PENDING');
		items.add('CUSTOMER_PORTAL_OFFERS');
		items.add('WEBPACK_SUBSCRIBER_INACTIVE');
		system.debug('***items: ' + items);
		
        list<SelectOption> so = new list<SelectOption>();
        for(string item : items){
        	so.add(new SelectOption(item, item));
        }
		
		//This orders the list alphabetically (if you look at the debug of so it's ordered,  so,  why it's not displaying
		//properly on the diagnostics console I don't know
		so = SelectOptionSort.SortOptionList(so);

		system.assertEquals('7DAY_SUBSCRIBER_ACTIVE', so[0].getValue());
		system.assertEquals('WEBPACK_SUBSCRIBER_INACTIVE', so[so.size()-1].getValue());
    }
}