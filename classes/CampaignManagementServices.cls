public with sharing class CampaignManagementServices {
	/* send a map bucketed by fieldName and the list of campaign codes 
	 to search from the campaign object. For example:
	 TollFreeNumber, [18002525,1800555]
	 CampaignCode,[1234,2222,8888] */

	public static Map < String, Campaign > searchCampaign(Map < String, List < String >> campaignDetails) {
		List < Campaign > searchRes1 = new List < Campaign > ();
		List < Campaign > searchRes2 = new List < Campaign > ();
		
		if(!campaignDetails.isEmpty() && (!campaignDetails.containsKey('TOLLFREENUMBER') && !campaignDetails.containsKey('TOLLFREENUMBER'))) {

			List < String > customMsgList = new List < String > ();
			customMsgList.add('ERROR: logic invoked for campaing key: ' + campaignDetails.keySet() + ' which hasn\'t been implemented');
			System.debug(customMsgList);
			throw new GlobalException(customMsgList, '', 'CampaignManagementServices.searchCampaign()');
		}
		if (!campaignDetails.isEmpty() && campaignDetails.containsKey('TOLLFREENUMBER')) {
			for (Integer i = 0; i < campaignDetails.get('TOLLFREENUMBER').size(); i++) {
				if (campaignDetails.get('TOLLFREENUMBER').get(i) == null) {
					campaignDetails.get('TOLLFREENUMBER').remove(i);
				}
			}

			searchRes1 = [select Name, Type, Description, CreatedDate, isActive, StartDate, EndDate, TollFree_Number__c, Campaign_Code__C from
			Campaign where Tollfree_Number__c in : campaignDetails.get('TOLLFREENUMBER')];
		}
		if (!campaignDetails.isEmpty() && campaignDetails.containsKey('CAMPAIGNCODE')) {
			for (Integer i = 0; i < campaignDetails.get('CAMPAIGNCODE').size(); i++) {
				if (campaignDetails.get('CAMPAIGNCODE').get(i) == null) {
					campaignDetails.get('CAMPAIGNCODE').remove(i);
				}
			}
			searchRes2 = [select Name, CreatedDate, isActive, StartDate, EndDate, TollFree_Number__c, Campaign_Code__C from
			Campaign where Campaign_Code__C in : campaignDetails.get('CAMPAIGNCODE')];
		} 

		Map < String, Campaign > searchResponse = new Map < String, Campaign > ();

		for (campaign c: searchRes1) {
			if (!searchResponse.containsKey(c.Tollfree_Number__c)) searchResponse.put(c.TollFree_Number__c, c);
		}

		for (campaign c: searchRes2) {
			if (!searchResponse.containsKey(c.Campaign_Code__c)) searchResponse.put(c.Campaign_Code__c, c);
		}
		return searchResponse;
	}

	public static void AddCampaignToLead(Map < Campaign, List < Lead >> campaignMap) {
		List < CampaignMember > cmList = new List < campaignMember > ();

		if (campaignMap != null && !campaignMap.isEmpty()) {
			for (Campaign c: campaignMap.keyset()) {
				for (lead eachLead: campaignMap.get(c)) {
					CampaignMember cm = new CampaignMember(CampaignId = c.Id, LeadId = eachLead.Id, Status = 'Responded');
					cmList.add(cm);
				}
			}
		}
		try {
			Database.saveResult[] srList = Database.insert(cmList, false);
			List < String > customMsgList = new List < String > ();
			
			for (Database.SaveResult sr: srList) {
				if (sr.isSuccess()) {
					// Operation was successful, so get the ID of the record that was processed
					System.debug('Successfully inserted members. member ID: ' + sr.getId());
				} else {
					// Operation failed, so get all errors  
					for (Database.Error err: sr.getErrors()) {
						if (err.getMessage().equals('This entity is already a member of this campaign') ||  err.getMessage().contains('more than once')) {
							System.debug('Ignore error: Lead already a member error');
						} else {
							customMsgList.add(err.getMessage());
						}
					}
				}
			}
			if(customMsgList!= null && !customMsgList.isEmpty()) {
				System.debug('Campaign Member Insert Error:' + customMsgList);
				throw new GlobalException(customMsgList, '', 'CampaignManagmentServices.AddCampaignToLead()');
			}
		} catch (System.DmlException ex) {
			List < String > customMsgList = new List < String > ();
			for (Integer i = 0; i < ex.getNumDml(); i++) {
				String msg = 'Campaign Member Insert Failed :' + ex.getMessage();
				customMsgList.add(msg);
			}
			throw new GlobalException(customMsgList, '', 'CampaignManagmentServices.AddCampaignToLead()');
		}
	}

	public static void AddCampaignToAccount(Map < Campaign, List < Account >> campaignMap) {
		List < CampaignMember > cmList = new List < campaignMember > ();

		if (campaignMap != null && !campaignMap.isEmpty()) {
			for (Campaign c: campaignMap.keyset()) {
				for (account eachAcc: campaignMap.get(c)) {
					CampaignMember cm = new CampaignMember(CampaignId = c.Id, contactId = eachAcc.PersonContactId, Status = 'Responded');
					cmList.add(cm);
				}
			}
		}
		try {
			Database.saveResult[] srList = Database.insert(cmList, false);
			List < String > customMsgList = new List < String > ();
			
			for (Database.SaveResult sr: srList) {
				if (sr.isSuccess()) {
					// Operation was successful, so get the ID of the record that was processed
					System.debug('Successfully inserted members. member ID: ' + sr.getId());
				} else {
					// Operation failed, so get all errors  
					for (Database.Error err: sr.getErrors()) {
						if (err.getMessage().equals('This entity is already a member of this campaign') ||  err.getMessage().contains('more than once')) {
							System.debug('Ignore error: Lead already a member error');
						} else {
							customMsgList.add(err.getMessage());
						}
					}
				}
			}
			if(customMsgList!= null && !customMsgList.isEmpty()) {
				System.debug('Campaign Member Insert Error:' + customMsgList);
				throw new GlobalException(customMsgList, '', 'CampaignManagmentServices.AddCampaignToLead()');
			}
		} catch (System.DmlException ex) {
			List < String > customMsgList = new List < String > ();
			for (Integer i = 0; i < ex.getNumDml(); i++) {
				String msg = 'Campaign Member Insert Failed :' + ex.getMessage();
				customMsgList.add(msg);
			}
			throw new GlobalException(customMsgList, '', 'CampaignManagmentServices.AddCampaignToLead()');
		}
	}
	
	public static Map < String, Channel__c > searchChannelByCode(List < String > channelId) {

		Map < String, Channel__c > resultsMap = new Map < String, Channel__c > ();

		if (channelId != null && channelId.size() > 0) {
			for (Integer i = 0; i < channelId.size(); i++) {
				if (channelId[i] == null) channelId.remove(i);
			}
			List < Channel__C > cList = [select Name, Channel_Code__c from
			Channel__c where Channel_Code__c in : ChannelId];
			if (cList != null && cList.size() > 0) {
				for (Channel__C c: cList) {
					if (!resultsMap.containsKey(c.Channel_Code__c)) resultsMap.put(c.Channel_Code__c, c);
				}
			}
		}
		return resultsMap;
	}

	public static List < Lead > setNRIChannelOnLead(List < Lead > recordList) {

		List < String > channelCodeList = new List < String > ();
		if (recordList != null && recordList.size() > 0) {

			for (lead l: recordList) {
				if (l.Channel_Code__C != null) {
					channelCodeList.add(l.Channel_Code__C);
				}
			}
		}

		Map < String, Channel__C > channelDetailsMap = searchChannelByCode(channelCodeList);
		System.debug('Channel Details Updated:' + channelDetailsMap);
		List < Lead > updateList = new List < Lead > ();
		for (lead l: recordList) {
			if (channelDetailsMap != null && channelDetailsMap.containsKey(l.Channel_Code__c)) {
				if (channelDetailsMap.get(l.Channel_Code__C).Name.endsWithIgnoreCase('_Local')) {
					l.Residential_Status__C = 'Indian';
					l.Channel_Name__c = channelDetailsMap.get(l.Channel_Code__C).Id;
				} else {
					l.Residential_Status__C = 'NRI';
					l.Channel_Name__c = channelDetailsMap.get(l.Channel_Code__C).Id;
				}
				updateList.add(l);
			}
		}
		return updateList;
	}

	public static List < Account > setNRIChannelOnAccount(List < Account > recordList) {
		List < String > channelCodeList = new List < String > ();
		if (recordList != null && recordList.size() > 0) {

			for (Account a: recordList) {
				if (a.Channel_Code__C != null) {
					channelCodeList.add(a.Channel_Code__C);
				}
			}
		}
		Map < String, Channel__C > channelDetailsMap = searchChannelByCode(channelCodeList);
		System.debug('Channel Details Updated:' + channelDetailsMap);
		List < Account > updateList = new List < Account > ();
		for (Account a: recordList) {
			if (channelDetailsMap != null && channelDetailsMap.containsKey(a.Channel_Code__c)) {
				if (channelDetailsMap.get(a.Channel_Code__C).Name.endsWithIgnoreCase('_Local')) {
					a.Residential_Status__C = 'Indian';
					a.Channel_Name__c = channelDetailsMap.get(a.Channel_Code__C).Id;
				} else {
					a.Residential_Status__C = 'NRI';
					a.Channel_Name__c = channelDetailsMap.get(a.Channel_Code__C).Id;
				}
				updateList.add(a);
			}
		}
		return updateList;
	}

}