trigger AccountTrigger on Account(before Insert, after Insert, before update, after update) {
    if (Trigger.IsInsert) {
        if (Trigger.IsBefore) {
            List < Account > updateNRIList = new List < Account > ();
            List < Account > updateChannelList = new List < Account > ();

            // call the CampaignManagementServices.addchannel method
           for (Account a: trigger.new) {
                if (a.IsPersonAccount) 
                    updateChannelList.add(a);
            }
            updateNRIList = CampaignManagementServices.setNRIChannelOnAccount(updateChannelList);
        } else if (Trigger.isAfter) {
        	List<Account> updateCMList = new List<Account>();
        	for(Account a : trigger.new) {
        		if(a.isPersonAccount && (a.Campaign_Code__c != null || a.TollFree_Number__C !=null)) {
        			updateCMList.add(a);
        		}
        	}
        	if (updateCMList != null && updateCMList.size() > 0) {
				try {
					PersonAccountManagementServices.AddCampaignToAccount(updateCMList);
				} catch (GlobalException ex) {
					System.debug('Global Exception:' + ex.getErrorMsg() + ex.getClassDetails());
				}
			}
        }
    }
    If(Trigger.isUpdate) {
        if (Trigger.isBefore) {
            List < Account > updateChannelList = new List < Account > ();
            List < Account > updateNRIList = new List < Account > ();

            for (Account a: trigger.new) {
                if (Trigger.newMap.get(a.Id).channel_Code__C != Trigger.oldMap.get(a.Id).Channel_Code__c && 
                                                                    Trigger.newMap.get(a.Id).IsPersonAccount) 
                    updateChannelList.add(a);
            }
            if (updateChannelList != null && updateChannelList.size() > 0) 
                updateNRIList = CampaignManagementServices.setNRIChannelOnAccount(updateChannelList);
        } else if(Trigger.isUpdate) {
        	List < Account > updateCMList = new List < Account > ();
			for (account a: trigger.new) {
				if (Trigger.newMap.get(a.Id).Campaign_Code__C != Trigger.oldMap.get(a.Id).Campaign_Code__C || Trigger.newMap.get(a.Id).TollFree_Number__C != Trigger.oldMap.get(a.Id).TollFree_Number__C) 
				updateCMList.add(a);
			}
			if (updateCMList != null && updateCMList.size() > 0) {
				try {
					PersonAccountManagementServices.AddCampaignToAccount(updateCMList);
				} catch (GlobalException ex) {
					System.debug('Global Exception:' + ex.getErrorMsg() + ex.getClassDetails());
				}
			}
        }

    }

 }