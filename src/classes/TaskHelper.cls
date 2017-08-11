public with sharing class TaskHelper 
{
	public static Task createTask(String ownerId, Id whatId, String subject, String message, String status)
    {
        Task result = new Task();
        result.OwnerId = ownerId;
        result.WhatId = whatId;
        result.Subject = subject;
        result.Status = status;
        result.Description = message;
        return result;
    }
}