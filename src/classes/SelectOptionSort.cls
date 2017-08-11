global class SelectOptionSort {
	/*
		Ripped directly from http://improveit360.blogspot.co.uk/2010/09/implementing-quicksort-to-sort-list-of.html
		
		The entitlements tab on the diagnostics console was not ordering the results alphabetically,  this does...
	*/
	
    global static List<SelectOption> SortOptionList(List<SelectOption> ListToSort)
    {
        if(ListToSort == null || ListToSort.size() <= 1)
            return ListToSort;
            
        List<SelectOption> Less = new List<SelectOption>();
        List<SelectOption> Greater = new List<SelectOption>();
        integer pivot = ListToSort.size() / 2;
          
        // save the pivot and remove it from the list
        SelectOption pivotValue = ListToSort[pivot];
        ListToSort.remove(pivot);
        
        for(SelectOption x : ListToSort)
        {
            if(x.getLabel() <= pivotValue.getLabel())
                Less.add(x);
            else if(x.getLabel() > pivotValue.getLabel()) Greater.add(x);   
        }
        List<SelectOption> returnList = new List<SelectOption> ();
        returnList.addAll(SortOptionList(Less));
        returnList.add(pivotValue);
        returnList.addAll(SortOptionList(Greater));
        return returnList; 
    }  
    
}