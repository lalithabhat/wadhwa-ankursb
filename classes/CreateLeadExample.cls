global class CreateLeadExample implements Messaging.InboundEmailHandler {
  global Messaging.InboundEmailResult handleInboundEmail(Messaging.inboundEmail email, 
                                                       Messaging.InboundEnvelope env){
    // Create an InboundEmailResult object for returning the result of the  
    // Apex Email Service 
    Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();
    String myPlainText= '';
    // Add the email plain text into the local variable  
    myPlainText = email.plainTextBody;    
    //Create a list and insert                                                            
    //Check for existing leads with this email address   
    List<Lead> emailLeadList = new List<Lead>();
    Lead newLead = new Lead();
    newLead.LastName ='AnkurTesting';
    newLead.Email = email.fromAddress;
    emailLeadList.add(newLead);    
    System.debug('Value of the lead list created: ' +emailLeadList);   
    //Calling the Leadmanagementservice to preprocess leads                                                       
    List<DupResultsDTO> results = LeadManagementServices.leadPreProcessing(emailLeadList, 'WEB');
    System.debug('Result of LeadManagementServices Match Logic: ' +results);
    if(results==null)
    {
        insert newLead;
    }
    else
    {
     //Create a email task on the matching record.   
     Task emailActivity = new Task();
     emailActivity.Subject = 'Email'+email.subject;
     emailActivity.Description = email.plainTextBody;
     // Completed status will move the task from 'open activities' to 'activity history'   
     emailActivity.Status = 'Completed';
     emailActivity.WhoId = results[0].duplicateMaster;
     insert emailActivity;  
      //System.debug('Incoming email duplicates existing Lead record(s): ');
    }

    // Set the result to true. No need to send an email back to the user      
    // with an error message   
    result.success = true;

    // Return the result for the Apex Email Service 
    return result;
  }
}