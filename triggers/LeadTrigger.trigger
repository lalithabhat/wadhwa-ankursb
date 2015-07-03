trigger LeadTrigger on Lead(before Insert, after Insert, before update, after update) {
	if (Trigger.IsInsert) {
		if (Trigger.IsBefore) {
			//check the user, if its batch user, only then call the preprocessing logic
			If(UserInfo.getUserName() == 'ankur.priyadarshan@stetig.in') {
				List < DupResultsDTO > dupResList = new List < DupResultsDTO > ();
				dupResList = LeadManagementServices.leadPreProcessing(Trigger.new, 'BULKLOAD');
				if (dupResList != null) {
					for (Lead l: Trigger.new) {
						System.debug('Trigger.new: ' + l);
						for (DupResultsDTO d: dupResList) {
							if (d.originalLead == l) {
								System.debug('Trigger.new: dup match' + l + d.originalLead);

								String errMsg = 'Duplicates exists for:' + l.lastName + '\n';
								for (String dupType: d.duplicatesMap.keySet()) {
									errMsg = errMsg + '\n' + dupType + 'duplicates are:' + d.duplicatesMap.get(dupType);
								}
								l.addError(errMsg);
							}
							break;
						}
					}
				}
			}

			List < lead > updateNRIList = new List < Lead > ();
			// call the CampaignManagementServices.addchannel method
			updateNRIList = CampaignManagementServices.setNRIChannelOnLead(Trigger.new);
		} else if (Trigger.isAfter) {
			try {
				LeadManagementServices.AddCampaignToLead(Trigger.new);
			} catch (GlobalException ex) {
				System.debug('Global Exception:' + ex.getErrorMsg() + ex.getClassDetails());
			}
		}
	}
	If(Trigger.isUpdate) {
		if (Trigger.isBefore) {
			List < Lead > updateChannelList = new List < Lead > ();
			List < Lead > updateNRIList = new List < Lead > ();

			for (lead l: trigger.new) {
				if (Trigger.newMap.get(l.Id).channel_Code__C != Trigger.oldMap.get(l.Id).Channel_Code__c) {
					updateChannelList.add(l);
				}
			}
			if (updateChannelList != null && updateChannelList.size() > 0) {
				updateNRIList = CampaignManagementServices.setNRIChannelOnLead(updateChannelList);
			}
		} else if (Trigger.isAfter) {
			List < Lead > updateCMList = new List < Lead > ();
			for (lead l: trigger.new) {
				if (Trigger.newMap.get(l.Id).Campaign_Code__C != Trigger.oldMap.get(l.Id).Campaign_Code__C || Trigger.newMap.get(l.Id).TollFree_Number__C != Trigger.oldMap.get(l.Id).TollFree_Number__C) {
					updateCMList.add(l);
				}
			}
			if (updateCMList != null && updateCMList.size() > 0) {
				try {
					LeadManagementServices.AddCampaignToLead(updateCMList);
				} catch (GlobalException ex) {
					System.debug('Global Exception:' + ex.getErrorMsg() + ex.getClassDetails());
				}
			}
		}

	}
}