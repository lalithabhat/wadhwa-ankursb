public class TaskManagementServices {
    public static String className = TaskManagementServices.class.getName();

    public static Map < Id, Task > createTaskforLeads(List < Lead > leadList, String taskType, String Status, String Subject, String callType, String callDisposition, String description, String tollfreeNumber) {
        List < Id > taskIds = new List < Id > ();
        List < Task > retTaskList = new List < Task > ();
        Map < Id, Task > taskWhoIdMap = new Map < Id, Task > ();
        List < Task > taskList = new List < Task > ();
        if (Status == null || string.isBlank(status)) {
            Status = 'Open';
        }
        if (taskType == null || string.isBlank(taskType)) {
            taskType = 'Follow-up';
        }
        if (subject == null || string.isBlank(subject)) {
            subject = 'SYSTEM GENERATED TASK';
        }
        if (callDisposition == null || string.isBlank(callDisposition)) {
            callDisposition = '';
        }
        if (callType == null || string.isBlank(callType)) {
            callType = '';
        }
        if (description == null || string.isBlank(description)) {
            description = 'SYSTEM GENERATED TASK';
        }
        if (!leadList.isEmpty()) {

            for (Lead l: leadList) {
                System.debug('In create task for leads: ' + l);
                Task t = new Task(Subject = Subject, Status = Status, Task_Type__C = taskType, whoId = l.id, OwnerId = l.OwnerId,
                Call_Disposition_custom__C = callDisposition, CallType = callType, description = description, tollfree_number__C = tollfreeNumber);
                taskList.add(t);
            }
            try {
                Database.SaveResult[] srList = Database.insert(taskList, true);
                // Iterate through each returned result

                for (Database.SaveResult sr: srList) {
                    if (sr.isSuccess()) {
                        // Operation was successful, so get the ID of the record that was processed
                        System.debug('Successfully inserted account. Task ID: ' + sr.getId());
                        taskIds.add(sr.getId());
                    } else {
                        // Operation failed, so get all errors  
                        List < String > customMsgList = new List < String > ();
                        for (Database.Error err: sr.getErrors()) {
                            String msg = 'Task Insert Failed :' + err.getMessage();
                            customMsgList.add(msg);
                        }
                        throw new GlobalException(customMsgList, '', className);
                    }
                }

                if (!taskIds.isEmpty()) {
                    retTaskList = [SELECT Id, Subject, Task_Type__c, WhoId, WhatId, OwnerId from Task where Id in : taskIds];
                }


                for (task t: retTaskList) {
                    taskWhoIdMap.put(t.whoId, t);
                }

            } catch (System.DmlException ex) {
                List < String > customMsgList = new List < String > ();
                for (Integer i = 0; i < ex.getNumDml(); i++) {
                    String msg = 'Task Insert Failed :' + ex.getMessage();
                    customMsgList.add(msg);
                }
                throw new GlobalException(customMsgList, '', className);
            }
        }
        return taskWhoIdMap;
    }
    public static Map < Id, Task > createTaskforAccounts(List < Account > accList, String taskType, String Status, String Subject, String callType, String callDisposition, String description, String tollfreeNumber) {
        List < Id > taskIds = new List < Id > ();
        List < Task > retTaskList = new List < Task > ();
        Map < Id, Task > taskWhoIdMap = new Map < Id, Task > ();

        List < Task > taskList = new List < Task > ();
        if (Status == null) {
            Status = 'Open';
        }
        if (taskType == null) {
            taskType = 'Follow-up';
        }
        if (subject == null || string.isBlank(subject)) {
            subject = 'SYSTEM GENERATED TASK';
        }
        if (callDisposition == null || string.isBlank(callDisposition)) {
            callDisposition = '';
        }
        if (callType == null || string.isBlank(callType)) {
            callType = '';
        }
        if (description == null || string.isBlank(description)) {
            description = 'SYSTEM GENERATED TASK';
        }
        if (!accList.isEmpty()) {

            for (account a: accList) {
                System.debug('In create task for accounts: ' + a);

                Task t = new Task(Subject = Subject, Status = Status, Task_Type__C = taskType, whoId = a.PersonContactId, OwnerId = a.OwnerId,
                Call_Disposition_custom__C = callDisposition, CallType = callType, description = description, tollfree_number__C = tollfreenumber);
                System.debug('Task: person details' + a.PersonContactId);
                taskList.add(t);
            }

            try {
                Database.SaveResult[] srList = Database.insert(taskList, false);
                // Iterate through each returned result
                List < String > customMsgList = new List < String > ();

                for (Database.SaveResult sr: srList) {
                    if (sr.isSuccess()) {
                        // Operation was successful, so get the ID of the record that was processed
                        System.debug('Successfully inserted account. Task ID: ' + sr.getId());
                        taskIds.add(sr.getId());
                    } else {
                        // Operation failed, so get all errors  
                        for (Database.Error err: sr.getErrors()) {
                            String msg = 'Task Insert Failed :' + err.getMessage();
                            customMsgList.add(msg);
                        }
                    }
                }
                if (customMsgList != null && !customMsgList.isEmpty()) {
                    throw new GlobalException(customMsgList, '', className);
                }
                if (!taskIds.isEmpty()) {
                    retTaskList = [SELECT Id, Subject, Task_Type__c, WhoId, WhatId, OwnerId from Task where Id in : taskIds];
                    System.debug('Tasks Created:' + retTaskList);
                }

                //cant create task with person accounts as whoid
                //personcontact gives the contactid of the person account which can be used as whoId
                //while mapping which task is for who, we need to check the personcontactId and populate the account id back as the key to the calling program
                for (task t: retTaskList) {
                    for (account a: accList) {
                        if (a.PersonContactId == t.whoId) taskWhoIdMap.put(a.Id, t);
                    }
                }

            } catch (System.DmlException ex) {
                List < String > customMsgList = new List < String > ();
                for (Integer i = 0; i < ex.getNumDml(); i++) {
                    String msg = 'Task Insert Failed :' + ex.getMessage();
                    customMsgList.add(msg);
                }
                throw new GlobalException(customMsgList, '', className);
            }
        }

        return taskWhoIdMap;
    }
    
    /**
    * Description: When a call comes on a toll free number to the CCU
    * the tollfree number, the campaign associated with the toll freenumber
    * needs to be identified and stored in the task level
    * This gives a context for the CCU agent while calling back the  customer
    * the after insert trigger of task calls this method for 
    * associating the campaign details to task
    **/
    public static List<Task> AddCampaignToTask(List<task> taskList){
            //Based on EnquiryMode for CALLS
        Map<String,List<String>> campaignDetails = new Map<String,List<String>>();
        
        //collect the campaign codes or toll free numbers into a list and put them into appropriate buckets [mapkeys]
        for(task t:taskList) {
                if(t.TollFree_Number__c != null)  {
                    if(campaignDetails.containsKey('TOLLFREENUMBER')) {
                        campaignDetails.get('TOLLFREENUMBER').add(t.TollFree_Number__C);
                    } else {
                        List<String> tollFreeList = new List<String>();
                        tollFreeList.add(t.TollFree_Number__C);
                        campaignDetails.put('TOLLFREENUMBER', tollFreeList);
                    }
                }
        }
        Map<String,Campaign> searchResults = new Map<String,Campaign>();
        
        System.debug('CampaignDetails:' + CampaignDetails);
        
        if(campaignDetails != null && !campaignDetails.isEmpty())   
            searchResults = CampaignManagementServices.searchCampaign(CampaignDetails);
            
        for(task t: taskList) {
            if(searchResults.containsKey(t.TollFree_Number__c)) {
                t.Campaign_Name__c = searchResults.get(t.TollFree_Number__c).Name;
                t.Campaign_Type__C = searchResults.get(t.TollFree_Number__C).Type;
            }
        }
        return taskList;
    }
     //clone task object to communication object
    public static void createCommunicationEntries(Task[] TaskList) 
    {        
         List<Id>  allWhatId = new List<Id>();
         List<Id> allWhoId = new List<Id>();
         for(Task t : TaskList)
         {
            if(t.WhatId != null)
            {
                allWhatId.add(t.WhatId);
            }
            if(t.WhoId != null)
            {
                allWhoId.add(t.WhoId);
            }
         }
        //Create maps
        Map<Id, Opportunity> WhatIdToOptyMap = new Map<Id, Opportunity>([SELECT Id,Name,ProjectName__c, ProjectName__r.GRE__c, ProjectName__r.GRE__r.Email FROM Opportunity WHERE Id IN :allWhatId]);
        Map<Id, Lead> WhoIdToLeadMap = new Map<Id, Lead>([SELECT Id,Name,Email,Phone FROM Lead WHERE Id IN :allWhoId]);
      
        //Create a list 
        List<Communication__c> cloneList = new List<Communication__c>();
        for(Task t : TaskList)
        {
            String objectWhatName = '';
            String objectWhoName = '';    
            String dt ='';
            //Create an object
            Communication__c cloneRecord = new Communication__c();
            cloneRecord.CallType__c = t.CallType__c;
            cloneRecord.Name = t.Subject;
            cloneRecord.Disposition__c = t.Call_Disposition_Custom__c;                              
            
            //The activity date is a Date field which needs to be converted into a datetime field. The time value will be picked-up from
            // t.DueTime__c field and its value will be concatenated with the value of activity date value.
            Datetime  OnlyDate = t.ActivityDate;                      

            
            // stripping the time value 00:00:00 from the t.activity date value
            String ODate = OnlyDate.Date().format();           
            
             // Here we are concatenating the date and time values to make create a datetime string                       
             dt = ODate+' '+t.DueTime__c; 
             System.Debug('Value of datetime parse function' +dt);
                  
             System.Debug('HardCoded Value of datetime parse function' +dt);               
             cloneRecord.Due_Date__c = DateTime.Parse(dt);
             
            //Populating the externalId field on communication record with the task Id.
             cloneRecord.TaskId__c=t.id;
            
            //Recipient_Email__c : Bring the emailid/mobile number of the sales manager /customer from project/lead/opty/account
            cloneRecord.Send_Site_Address__c= t.Send_Site_Address__c;
            cloneRecord.Task_Type__c= t.Task_Type__c;
            if(t.WhatId != null)
            { 
                 objectWhatName = t.WhatId.getSObjectType().getDescribe().getName();
            }
            if(t.WhoId != null)
            {
                 objectWhoName = t.WhoId.getSObjectType().getDescribe().getName();            
            }
            // If the parent record is an opportunity then query project object and get the sales managers name and email id.    
            if(objectWhatName == 'Opportunity')
            {
                      cloneRecord.Recipient_Email__c= WhatIdToOptyMap.get(t.WhatId).ProjectName__r.GRE__r.Email;
                      cloneRecord.sobjectName__c= objectWhatName; 
                      cloneRecord.OptyName__c = t.WhatId;
                      cloneList.add(cloneRecord);                  
            }
            else if(objectWhoName == 'Lead')        
            {
                      cloneRecord.Recipient_Email__c= WhoIdToLeadMap.get(t.WhoId).Email;
                      cloneRecord.Mobile__c= WhoIdToLeadMap.get(t.WhoId).Phone;
                      cloneRecord.sobjectName__c= objectWhoName; 
                      cloneRecord.LeadName__c=t.WhoId;
                      cloneList.add(cloneRecord);
            }                    
            else
            {
                   System.Debug('Do nothing');
                           
            }
        }
        if(cloneList.size()>0)
        {    
            upsert cloneList  TaskId__c ;
        }
    }   
    
    //update the number of consecutive unreachable call counter on leads and oppty
    // this will be used in the workflow to close unreachable leads or oppty after 5 consecutive attempts for
    // 5 days continously
     public static Void Incrementcounter(Task[] TaskList)
    {
            //Create a list to save all records to be updated
            List<Lead> updatedleadobj = new List<Lead>();
            List<Opportunity> updatedOppobj = new List<Opportunity>();
            
            //Create a list to hold all the parent Ids
            List<Id> allWhoId = new List<Id>();
            List<Id> allWhatId = new List<Id>();
            
            //String to store the name of objects (Lead or opty)
            String objectWhatName = '';
            String objectWhoName = '';
             
            // Date to be used for comparision against the last update date. 
            // In case of last update date being same as today, no action needs to be taken
            DateTime d = Date.Today();
            
            //Loop over the tasklist(passed as part of the method call) to extract all the whoids/whatids.
            for(Task t :TaskList){
                if(t.WhoId != null && t.Task_Type__C == 'Call')
                {
                    allWhoId.add(t.WhoId);
                }
                if(t.WhatId != null && t.Task_Type__C == 'Call')
                {
                    allWhatId.add(t.WhatId);
                }
            }
            
         //Create a map to store the whoid-Lead record combination   
         Map<Id, Lead> WhoIdToLeadMap = new Map<Id, Lead>([SELECT Id,Name,DateForCall__c,CounterForCall__c FROM Lead  WHERE Id IN :allWhoId]);

         //Create a map to store the whoid-Lead record combination
         Map<Id, Opportunity> WhatIdToOptyMap = new Map<Id, Opportunity>([SELECT Id,Name,DateForCall__c,CounterForCall__c FROM Opportunity  WHERE Id IN :allWhatId]);
             //Loop over the tasklist to execute business logic   
             for(Task t :TaskList)
             { 
                  if(t.WhatId != null)
                    { 
                         objectWhatName = t.WhatId.getSObjectType().getDescribe().getName();
                         //objectWhatName = t.What.Type; This can also be used.                  
                    }
                    if(t.WhoId != null)
                    {
                         objectWhoName = t.WhoId.getSObjectType().getDescribe().getName();   
                        //System.Debug('This Is Object Name' +objectWhoName);         
                    }
                    //If the parent record is an opty
                    if(objectWhatName == 'Opportunity')
                    {
                            //Check call disposition, if answered, flush the values of counter and last update date
                            if(t.Call_Disposition_Custom__c == 'Answered')
                            {
                                WhatIdToOptyMap.get(t.WhatId).DateForCall__c = null;
                                WhatIdToOptyMap.get(t.WhatId).CounterForCall__c = 0;
                                updatedOppobj.add(WhatIdToOptyMap.get(t.WhatId));     
                            }     
                            //Check call disposition, if unanswered for the first time today, increment values of counter and update last update date to today's date
                            else if(t.Call_Disposition_Custom__c == 'Unanswered')
                            { 
                                    
                                if (WhatIdToOptyMap.get(t.WhatId).DateForCall__c != d)
                                {
                                    WhatIdToOptyMap.get(t.WhatId).CounterForCall__c = WhatIdToOptyMap.get(t.WhatId).CounterForCall__c + 1;
                                    WhatIdToOptyMap.get(t.WhatId).DateForCall__c =  Date.Today() ;
                                    updatedOppobj.add(WhatIdToOptyMap.get(t.WhatId));     
                                        
                                }
                                else
                                {
                                
                                        System.debug('The counter has already been incremented for today');
                                }
            
                             }
                             else
                             {
                                 System.Debug('This Is neither Answered nor Unanswered');  
                             }
                            
                      }   
                     //If the parent record was a lead 
                     else if(objectWhoName == 'Lead')        
                     {
                            //Check call disposition, if answered, flush the values of counter and last update date
                            if(t.Call_Disposition_Custom__c == 'Answered')
                            {
                                WhoIdToLeadMap.get(t.WhoId).DateForCall__c = null;
                                WhoIdToLeadMap.get(t.WhoId).CounterForCall__c = 0;
                                updatedleadobj.add(WhoIdToLeadMap.get(t.WhoId));     
                            }
                            //Check call disposition, if unanswered for the first time today, increment values of counter and update last update date to today's date
                            else if(t.Call_Disposition_Custom__c == 'Unanswered')
                            {
                                //If the counter value is more than 4 then change stage to 'Closed Lost'
                                //This update stage code has to move to a different method. If condition true then add the record to a list and make a call to the update stage method with this list as parameter(after the for loop)                            
                                if (WhoIdToLeadMap.get(t.WhoId).DateForCall__c != d)
                                {
                                    WhoIdToLeadMap.get(t.WhoId).CounterForCall__c = WhoIdToLeadMap.get(t.WhoId).CounterForCall__c + 1;
                                    WhoIdToLeadMap.get(t.WhoId).DateForCall__c =  Date.Today() ;
                                    updatedleadobj.add(WhoIdToLeadMap.get(t.WhoId));                                     
                                }
                                else
                                {
                                        System.debug('The counter has already been incremented once today');
                                }
            
                             }
                             else
                             {
                                 System.Debug('This Is neither Answered nor Unanswered');  
                             }      
                             
                    
                     }
                     else
                     {
                         System.Debug('This is neither lead not opportunity');
                     }      
                
                 }
                if(updatedOppobj .size()>0)
                {
                    update updatedOppobj ;
                }  
                if(updatedleadobj.size()>0)
                 {
                     update updatedleadobj;
                 }
        }
        
    //Method to update opty stage based on the no of site visits added for that opty
    public static void updateOpptyStage(Task[] TaskList) {
        System.Debug('Inside the method');
        List < Opportunity > updatedOppobj = new List < Opportunity > ();
        Set < Id > opptyIds = new Set < Id > ();
        for (Task t: TaskList) {
            System.Debug('Inside the forloop2. VAlue of t.what.Type'+t.what.Type);
            if(t.WhatId!=null)
            {
                System.Debug('Inside the forloop2. VAlue of t.WhatId.getSObjectType().getDescribe().getName()'+t.WhatId.getSObjectType().getDescribe().getName());            
                //only add tasks who parent are opportunity and update oppty only when a new task of type site visit is created.
                if(t.WhatId.getSObjectType().getDescribe().getName() == 'Opportunity' && t.Task_Type__c =='Site Visit' ) {
                    opptyIds.add(t.WhatId);
                    System.Debug('Inside if opty and site visit condition. Value of opptyIds'+opptyIds);
                    }
            }
        }
        Map < Id, Opportunity > OptyMap = new Map < Id, Opportunity > ([SELECT Id, StageName, CounterForSiteVisit__c FROM Opportunity WHERE Id IN: opptyIds]);
        
        Map < Id, Task > TaskMap = new Map < Id, Task > ([SELECT Id, Task_Type__c, WhatId FROM Task WHERE WhatId IN: opptyIds and Task_Type__c = 'Site Visit']);
        
        Map<Id, List<Task>> opptyTaskListMap = new Map<Id,List<Task>>();
        
        if(!TaskMap.isEmpty()) {
            
            //group them into tasks for each Oppty
            //{Oppty1, [Task1, Task2],
            // Oppty2, [Task1],
            // Oppty3, [Task1] }
            
            for(Task t: TaskMap.values()) {
                if(opptyTaskListMap.containsKey(t.WhatId)) {
                    opptyTaskListMap.get(t.WhatId).add(t);
                } else {
                    List<Task> tList = new List<Task>();
                    tList.add(t);
                    opptyTaskListMap.put(t.WhatId, tList);
                }
            }
        }
        for(Id opptyId : opptyTaskListMap.keySet()) {
            System.debug('Value of Map'+opptyTaskListMap.get(opptyId).size());
            if(opptyTaskListMap.get(opptyId).size() == 0) {
                System.debug('No Site Visits Yet');
            } else if(opptyTaskListMap.get(opptyId).size() == 1){
                OptyMap.get(opptyId).StageName = 'Site Visit Scheduled';
                OptyMap.get(opptyId).CounterForSiteVisit__c = OptyMap.get(opptyId).CounterForSiteVisit__c + 1;
                updatedOppobj.add(OptyMap.get(opptyId));
            } else if(opptyTaskListMap.get(opptyId).size() == 2) {
                OptyMap.get(opptyId).StageName = 'Second Site Visit';
                OptyMap.get(opptyId).CounterForSiteVisit__c = OptyMap.get(opptyId).CounterForSiteVisit__c + 1;
                updatedOppobj.add(OptyMap.get(opptyId));
            } else {
                OptyMap.get(opptyId).StageName = 'Third Site Visit';
                OptyMap.get(opptyId).CounterForSiteVisit__c = OptyMap.get(opptyId).CounterForSiteVisit__c + 1;
                updatedOppobj.add(OptyMap.get(opptyId));
                
            }
        }
        System.Debug('After For Loop. VAlue of updatedOppobj'+updatedOppobj);
    
        if (updatedOppobj.size() > 0) {
            update updatedOppobj;
        }
    }
}