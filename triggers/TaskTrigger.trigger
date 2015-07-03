trigger TaskTrigger on Task (before Insert, after Insert, before update, after update) {
    if(Trigger.isInsert) {
        if(Trigger.isBefore) {
           List<task> taskList = TaskManagementServices.AddCampaignToTask(Trigger.new);
           //TaskManagementServices.updateOpptyStage(Trigger.new);
        } else if(Trigger.isAfter) {
           TaskManagementServices.createCommunicationEntries(Trigger.new);
           TaskManagementServices.Incrementcounter(Trigger.new);
           TaskManagementServices.updateOpptyStage(Trigger.new);
        }
    } 
    if(Trigger.isUpdate) {        
         if(Trigger.isAfter) {
            TaskManagementServices.createCommunicationEntries(Trigger.new);
            TaskManagementServices.IncrementCounter(Trigger.new);
            TaskManagementServices.updateOpptyStage(Trigger.new);
        } 
    }
}