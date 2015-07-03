trigger OpportunityTrigger on Opportunity (before insert, after insert, before update, after update ) {
    if(Trigger.isInsert) {
        if(Trigger.isBefore) {
           OpportunityManagementServices.copySiteSource(Trigger.new);
            OpportunityManagementServices.calculateOpportunityRating(Trigger.new);
        } else if (Trigger.isAfter) {
            ForecastManagementServices.createOpportunitySnapshots(Trigger.new);
        }
    }
    if(Trigger.isUpdate) {
        if(Trigger.isBefore) {
            OpportunityManagementServices.copySiteSource(Trigger.oldMap, Trigger.newMap);
            OpportunityManagementServices.calculateOpportunityRating(Trigger.new);
        } else if(Trigger.isAfter) {
            ForecastManagementServices.createOpportunitySnapshots(Trigger.new);
        }
    }     
}