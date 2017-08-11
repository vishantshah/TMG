@isTest
private class TaskHelperTest
{
    static testMethod void testHelper() 
    {
    	Task task;
        Test.startTest();
        	task = TaskHelper.createTask(null, null, 'Test', 'Test', 'Test');
        Test.stopTest();
        System.assertNotEquals(task, null);
    }
}