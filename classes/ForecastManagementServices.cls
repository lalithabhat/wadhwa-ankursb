public with sharing class ForecastManagementServices {
	
	/** Everytime an opportunity moves to negotiation stage or booked, sold or cancelled stage
		create a snapshot of that record [opportunity project record]
		and link to the salesforecast record for that specific project and quarter
		Also, check for any stage changes of the records existing in opportunity clone table,
		say oppty A goes from negotiation back to site visit, then we need to remove this 
		opportunity from opportunity project table so that it doesnt get included in the forecasting rollups */
		
		public static void createOpportunitySnapShots(List<Opportunity> opptyList) {
			// select the current quarter number from the period object
			// this gives the fiscal quarter not the calendar quarter
			// for ex: if the company's financial yr starts on Apr , Apr - June is Q1
			// the same quarter values should be defined in the custom table created for Quarters
			
			List<Period> fiscalQtr = [Select Number, StartDate, EndDate from Period where startDate = THIS_FISCAL_QUARTER and Type = 'Quarter'];
			
			// select only the salesforecast reports that are relevant for this quarter
			// dont mess with the records from other quarters 
			List<SalesForecast__C> sfList = [Select Id, Name, ProjectName__r.Name,QuarterName__r.Name 
										FROM SalesForecast__c where 
										QuarterName__r.QuarterNumber__c = :fiscalQtr[0].Number and
										QuarterName__r.Start_Date__c = :fiscalQtr[0].StartDate and
										QuarterName__r.End_Date__c = :fiscalQtr[0].EndDate];
			System.debug('Salesforecast Info:' + sfList);
			
			Map<Id,Id> sfProjectMap = new Map<Id,Id>();
			
			for(SalesForecast__C sf: sfList) {
				sfProjectMap.put(sf.ProjectName__c,sf.Id);
			}
			
			List<Opportunity_Project__c> upsertList = new List<Opportunity_Project__c>();
			List<Id> removeList = new List<Id>();
			
			// prepare for checking if any of the existing opportunities in the opportunities project table have moved back in status
			// for ex: from booked -> site visit, UF and negotiation -> site visit # 2 and remove those oppty from the table
			
			List<Opportunity_Project__c> existingOpList = [select Id, Opportunity__c, Opportunity__r.Id, SalesForecast__c, Ext_Id__c from Opportunity_Project__c where createdDate = THIS_FISCAL_QUARTER];
			
			Map<Id,Opportunity_Project__c> opProjMap = new Map<Id,Opportunity_Project__c>();
			
			for(Opportunity_Project__c op: existingOpList) {
				opProjMap.put(op.Opportunity__r.Id, op);
			}
			
			// if the incoming oppty record's stage anything that we forecast on then go ahead and clone that record in the opportunity sales object
			// if the incoming oppty stage is anything else, check if its already in the oppty project object and remove that record
			for(opportunity o: opptyList) {
				if(o.StageName == 'Booked' || o.StageName ==  'Sold' || o.StageName == 'Cancelled' || o.StageName == 'Unit Finalization and Negotiation') {
					Id sfId = sfProjectMap.get(o.ProjectName__c);
					String extId = String.valueOf(o.Id) + string.valueOf(sfId);
					Opportunity_Project__c op = new Opportunity_Project__c (Opportunity__c = o.Id, SalesForecast__c = sfId, Stage__c = o.StageName, 
																						Expected_Revenue__c = o.ExpectedRevenue, Amount__c=o.Amount, Ext_Id__c= extId);
					upsertList.add(op);																	
				} else {
					if(!opProjMap.isEmpty() && opProjMap.containsKey(o.Id)) {
						// some stage reversal has happened on existing records, remove the record from the table
						removeList.add(opProjMap.get(o.Id).Id);
					}
				}
			}
			try {
				Schema.SObjectField f = Opportunity_Project__c.Fields.Ext_Id__C;
				Database.UpsertResult[] srList = Database.upsert(upsertList, f, false);
				
				List < String > customMsgList = new List < String > ();
			
				for (Database.UpsertResult sr: srList) {
					if (sr.isSuccess()) {
						// Operation was successful, so get the ID of the record that was processed
						System.debug('Successfully inserted oppty projects.  ID: ' + sr.getId());
					} else {
						// Operation failed, so get all errors  
						for (Database.Error err: sr.getErrors()) {
								customMsgList.add(err.getMessage());
						}
					}
				}
				if(customMsgList!= null && !customMsgList.isEmpty()) {
					System.debug('Opportunity Project Upsert Error:' + customMsgList);
					throw new GlobalException(customMsgList, '', 'ForecastManagementServices.createOpportunitySnapShots()');
				}
			} catch(System.DmlException ex) {
				List < String > customMsgList = new List < String > ();
				for (Integer i = 0; i < ex.getNumDml(); i++) {
					String msg = 'Opportunity Project Upsert Error:' + ex.getMessage();
					customMsgList.add(msg);
				}
				throw new GlobalException(customMsgList, '', 'CampaignManagmentServices.AddCampaignToLead()');
			}
			
			try {
				Database.DeleteResult[] srList = Database.delete(removeList, false);
				
				List < String > customMsgList = new List < String > ();
			
				for (Database.DeleteResult sr: srList) {
					if (sr.isSuccess()) {
						// Operation was successful, so get the ID of the record that was processed
						System.debug('Successfully deleted oppty projects.  ID: ' + sr.getId());
					} else {
						// Operation failed, so get all errors  
						for (Database.Error err: sr.getErrors()) {
								customMsgList.add(err.getMessage());
						}
					}
				}
				if(customMsgList!= null && !customMsgList.isEmpty()) {
					System.debug('Opportunity Project Delete Error:' + customMsgList);
					throw new GlobalException(customMsgList, '', 'ForecastManagementServices.createOpportunitySnapShots()');
				}
			} catch(System.DmlException ex) {
				List < String > customMsgList = new List < String > ();
				for (Integer i = 0; i < ex.getNumDml(); i++) {
					String msg = 'Opportunity Project Delete Error:' + ex.getMessage();
					customMsgList.add(msg);
				}
				throw new GlobalException(customMsgList, '', 'ForecastManagementServices.createOpportunitySnapShots()');
			}
		}	
		
		public static void createForecastRollUps() {
			
			AggregateResult[] arList = [SELECT Salesforecast__c sf, count(Id) opptyCount, Stage__C opptyStage, sum(Expected_Revenue__C) opptyRevenue
																					 from Opportunity_Project__c 
																					 where createdDate = THIS_FISCAL_QUARTER
																					 group by SalesForecast__c , Stage__c ];
																					 
			List<Period> fiscalQtr = [Select Number, StartDate, EndDate from Period where startDate = THIS_FISCAL_QUARTER and Type = 'Quarter'];
			
			// select only the salesforecast reports that are relevant for this quarter
			// dont mess with the records from other quarters 
			Map<Id,SalesForecast__C> sfMap = new Map<Id,Salesforecast__c>([Select Id, Name, ProjectName__r.Name,QuarterName__r.Name 
										FROM SalesForecast__c where 
										QuarterName__r.QuarterNumber__c = :fiscalQtr[0].Number and
										QuarterName__r.Start_Date__c = :fiscalQtr[0].StartDate and
										QuarterName__r.End_Date__c = :fiscalQtr[0].EndDate]);
			System.debug('Salesforecast Info:' + sfMap);
			
			List<SalesForecast__C> sfupdateList = new List<SalesForecast__C>();
			
			for(Id i : sfMap.keySet()) {
				
				Boolean isUpdated = false;
				
				sfMap.get(i).Actual_Commit_Revenue__c =0;
				sfMap.get(i).Actual_Closed_Revenue__c =0;
				sfMap.get(i).Unit_Sold__c =0;
				sfMap.get(i).Unit_Negotiation__c =0;
				
				for(AggregateResult ar : arList) {
					if(string.valueOf(ar.get('sf')) == String.valueOf(sfMap.get(i).Id) && String.ValueOf(ar.get('opptyStage')) == 'Unit Finalization and Negotiation' ) {
						sfMap.get(i).Actual_Commit_Revenue__c = Integer.valueOf(ar.get('opptyRevenue'));
						sfMap.get(i).Unit_Negotiation__c = Integer.valueOf(ar.get('opptyCount'));
						isUpdated = true;
					} else if (String.valueOf(ar.get('sf')) == String.valueOf(sfMap.get(i).Id) && ( String.valueOf(ar.get('opptyStage')) == 'Booked' || String.valueOf(ar.get('opptyStage')) == 'Sold' ) )  {
						sfMap.get(i).Actual_Closed_Revenue__c = sfMap.get(i).Actual_Closed_Revenue__c + Integer.valueOf(ar.get('opptyRevenue'));
						sfMap.get(i).Unit_Sold__c = sfMap.get(i).Unit_Sold__c + Integer.valueOf(ar.get('opptyCount'));
						isUpdated = true;
					} else {
						System.debug('ar details from else:' + ar);
					}
				}
				if(isUpdated) {
					sfUpdateList.add(sfMap.get(i));
				}
			}
			if(sfUpdateList!=null && !sfUpdateList.isEmpty()) {
				try {
					
					Database.saveResult[] srList = Database.update(sfUpdateList, true);
					
					List < String > customMsgList = new List < String > ();
				
					for (Database.saveResult sr: srList) {
						if (sr.isSuccess()) {
							// Operation was successful, so get the ID of the record that was processed
							System.debug('Successfully update salesforecast.  ID: ' + sr.getId());
						} else {
							// Operation failed, so get all errors  
							for (Database.Error err: sr.getErrors()) {
									customMsgList.add(err.getMessage());
							}
						}
					}
					if(customMsgList!= null && !customMsgList.isEmpty()) {
						System.debug('Salesforeast update error:' + customMsgList);
						throw new GlobalException(customMsgList, '', 'ForecastManagementServices.createForecastRollups()');
					}
				} catch(System.DmlException ex) {
					List < String > customMsgList = new List < String > ();
					for (Integer i = 0; i < ex.getNumDml(); i++) {
						String msg = 'Salesforeast update error:' + ex.getMessage();
						customMsgList.add(msg);
					}
					throw new GlobalException(customMsgList, '', 'ForecastManagementServices.createForecastRollups()');
				}
			}
		}		
}