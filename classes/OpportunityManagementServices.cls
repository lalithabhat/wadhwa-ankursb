public with sharing class OpportunityManagementServices {
	//method to set Opportunity Rating based on field value
	public static Void calculateOpportunityRating(Opportunity[] opptyList) {
		//Integer variable to store points given to opty based on certain conditions
		Integer point = 0;
		//Create List of Id type to store all opty ids
		List < string > projnames = new List < String > ();
		for (Opportunity opp: OpptyList) {
			projnames.add(opp.ProjectName__c);

		}
		System.Debug('id of projects:' + projnames);
		Map < Id, Project__c > ProjectMap = new Map < Id, Project__c > ([SELECT Id, Area_Rating__c, BudgetInLacs_RatingField__c, StageOfConstruction_Rating__c, Configuration_Rating__c
		from Project__c where Id = : projnames]);
		for (Opportunity opp: OpptyList) {
			//Check if the map is empty. Calculate rating if not null
			if (!ProjectMap.isEmpty()) {
				//Increment if oppty area is same as projects
				if (opp.Area_Range_in_Sq_ft__c != null) {
					if (ProjectMap.get(opp.ProjectName__c).Area_Rating__c.contains(opp.Area_Range_in_Sq_ft__c)) {
						point = point + 1;
						System.Debug('Same Area as project. So Point is incremented to POINT : ' + point);
					}

				} else {
					System.Debug('Area has value' + opp.Area_Range_in_Sq_ft__c);
				}
				//Increment if opty Budget is same as projects
				if (opp.Budget_in_lacs__c != null) {
					if (ProjectMap.get(opp.ProjectName__c).BudgetInLacs_RatingField__c.contains(opp.Budget_in_lacs__c)) {
						point = point + 1;
						System.Debug('Same Budget as project. So Point is incremented to POINT : ' + point);
					}
				} else {
					System.Debug('Budget is :' + opp.Budget_in_lacs__c);
				}
				//Increment if opty Bedroom preferrences is same as projects
				if (opp.Bedroom_Preference__c != null) {
					if (ProjectMap.get(opp.ProjectName__c).Configuration_Rating__c.contains(opp.Bedroom_Preference__c)) {
						point = point + 1;
						System.Debug('Same Bedroom preferrences as project. So Point is incremented to POINT : ' + point);
					}
				} else {
					System.Debug('Bedroom preferrences is :' + opp.Bedroom_Preference__c);
				}
				//Increment if opty Completion State is same as projects
				if (opp.Completion_Stage__c != null) {
					if (ProjectMap.get(opp.ProjectName__c).StageOfConstruction_Rating__c.contains(opp.Completion_Stage__c)) {
						point = point + 1;
						System.Debug('Same Completion State as project. So Point is incremented to POINT : ' + point);
					}
				} else {
					System.Debug('Completion State is :' + opp.Completion_Stage__c);
				}
				//Increment if opty Prefered Location is same as projects
				if (opp.Preferred_Location__c == 'Same as Project') {
					point = point + 1;
					System.Debug('Prefered Location Same as Project. So Point is incremented to POINT : ' + point);
				} else {
					System.Debug('Prefered Location is not Same as Project. It is :' + opp.Preferred_Location__c);
				}
				//Increment  point if no of site visit for opty is more than one
				if (opp.CounterForSiteVisit__c > 1) {
					point = point + 1;
					System.Debug('More than one Site Visit : Point :' + point);
				}
			}
			//Set Rating  based on point value
			if (point > 4) {
				opp.Rating_System__c = 'Hot';
				System.Debug('Value of the Rating ' + opp.Rating_System__c);
			} else if (point == 3 || point == 4) {
				opp.Rating_System__c = 'Warm';
				System.Debug('Value of the Rating Warm' + opp.Rating_System__c);
			} else {
				opp.Rating_System__c = 'Cold';
				System.Debug('Value of the Rating Cold ' + opp.Rating_System__c);
			}
		}
	}
	//method to auto update site visit field values based on CCU field values
	// assumption: this method will be called from an before update trigger only, hence the old and new old values will be present in the 
	// respective maps
	public static Void copySiteSource(Map < Id, Opportunity > opptyOldMap, Map < Id, Opportunity > opptyNewMap) {

		for (Id oId: opptyNewMap.keyset()) {

			if ((opptyOldMap.get(oId).Site_Visit_Source__c == null || opptyNewMap.get(oId).Site_Visit_Source__c == null)  && opptyNewMap.get(oId).CCU_Source__c != null) {
				OpptyNewMap.get(oId).Site_Visit_Source__c = OpptyNewMap.get(oId).CCU_Source__c;
			}
			//if site visit campaign details is null set its value to CCU_Campaign_Details
			if ((opptyOldMap.get(oId).Site_Visit_Campaign_Details__c == null || opptyNewMap.get(oId).Site_Visit_Campaign_Details__c == null) && opptyNewMap.get(oId).CCU_Campaign_Details__c != null) {
				OpptyNewMap.get(oId).Site_Visit_Campaign_Details__c = opptyNewMap.get(oId).CCU_Campaign_Details__c;
			}
			//if Site_Visit_Employee_Name is null set its value to CCU_Employee_Name
			if ((opptyOldMap.get(oId).Site_Visit_Employee_Name__c == null ||opptyNewMap.get(oId).Site_Visit_Employee_Name__c == null)  && OpptyNewMap.get(oId).CCU_Employee_Name__c != null) {
				OpptyNewMap.get(oId).Site_Visit_Employee_Name__c = OpptyNewMap.get(oId).CCU_Employee_Name__c;
			}
			//if Site_Visit_Broker_Firm is null set its value to Broker_Firm
			if ((opptyOldMap.get(oId).Site_Visit_Broker_Firm__c == null ||opptyNewMap.get(oId).Site_Visit_Broker_Firm__c == null) && opptyNewMap.get(oId).Broker_Firm__c != null) {
				OpptyNewMap.get(oId).Site_Visit_Broker_Firm__c = OpptyNewMap.get(oId).Broker_Firm__c;
			}
			//if Site_Visit_referee_Customer_Code is null set its value to CCU_referee_Customer_Code
			if ((opptyOldMap.get(oId).Site_Visit_referee_Customer_Code__c == null || opptyNewMap.get(oId).Site_Visit_referee_Customer_Code__c == null) && OpptyNewMap.get(oId).CCU_referee_Customer_Code__c != null) {
				opptyNewMap.get(oId).Site_Visit_referee_Customer_Code__c = OpptyNewMap.get(oId).CCU_referee_Customer_Code__c;
			}

		}

	}

	//method to auto update site visit field values based on CCU field values
	//this is an overridden method for accommodating before insert scenario
	public static Void copySiteSource(List < Opportunity > opptyList) {

		for (Opportunity o: opptyList) {
			// in before insert scenario, check if the user is entering values for both CCU and site source at the time of creating the record
			// if not copy the CCU data over to site source data
			System.debug('Oppty Info:' + o);
			if (o.Site_Visit_Source__c == null) o.Site_Visit_Source__c = o.CCU_Source__c;
			if (o.Site_Visit_Campaign_Details__c == null) o.Site_Visit_Campaign_Details__c = o.CCU_Campaign_Details__c;
			if (o.Site_Visit_Employee_Name__c == null) o.Site_Visit_Employee_Name__c = o.CCU_Employee_Name__c;
			if (o.Site_Visit_Broker_Firm__c == null) o.Site_Visit_Broker_Firm__c = o.Broker_Firm__c;
			if (o.Site_Visit_referee_Customer_Code__c == null) o.Site_Visit_referee_Customer_Code__c = o.CCU_referee_Customer_Code__c;
		}

	}

}