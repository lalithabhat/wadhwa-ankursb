public class DedupeChecker {

	public static Map < Lead, List < Lead >> findLeadDupeforLeads(String Field, List < Lead > leadList) {
		Map < Lead, List < Lead >> leadDuplicateMap = new Map < Lead, List < Lead >> ();
		if (Field == 'EMAIL') {
			Map < Lead, List < Lead >> leadEmailDupMap = findLeadDupeforLeadsByEmail(leadList);
			leadDuplicateMap.putAll(leadEmailDupMap);
		} else if (Field == 'MOBILE') {
			Map < Lead, List < Lead >> leadMobileDupMap = findLeadDupeforLeadsByMobile(leadList);
			leadDuplicateMap.putAll(leadMobileDupMap);
		}
		return leadDuplicateMap;
	}

	public static Map < Lead, List < Account >> findPADupeforLeads(String Field, List < Lead > leadList) {
		Map < Lead, List < Account >> leadDuplicateMap = new Map < Lead, List < Account >> ();
		if (Field == 'EMAIL') {
			Map < Lead, List < Account >> personAccountEmailDup = findPADupeforLeadsByEmail(leadList);
			leadDuplicateMap.putAll(personAccountEmailDup);
		} else if (Field == 'MOBILE') {
			Map < Lead, List < Account >> PAMobileDupMap = findPADupeforLeadsByMObile(leadList);
			leadDuplicateMap.putAll(PAMobileDupMap);
		} else {
			System.debug('findPADupeforLeads not implement for key: ' + Field);
		}
		return leadDuplicateMap;
	}

	public static Map < Lead, List < Lead >> findLeadDupeforLeadsByEmail(List < Lead > leadList) {
		Map < String, List < Lead >> emailKeyMap = new Map < String, List < Lead >> ();
		// arrange the incoming list of leads in the below format
		// {email1, [IncomingLead1, IncomingLead2, IncomingLead3]
		//  email2, [IncomingLead4, IncomingLead5]
		//  email3, [IncomingLead6]}
		if (leadList == null || leadList.isEmpty()) {
			List < String > customMsgList = new List < String > ();
			customMsgList.add('Incoming lead list is empty');
			throw new GlobalException(customMsgList, '', 'findLeadDupeForLeadsByEmail');
		}
		for (Lead l: leadList) {
			System.debug('lead l: ' + l);
			if (l.Email != null) {
				if (emailKeyMap.containsKey(l.Email)) emailKeyMap.get(l.Email).add(l);
				else {
					List < Lead > newList = new List < Lead > ();
					newList.add(l);
					emailKeyMap.put(l.email, newList);
				}
			}
		}
		System.debug('Incoming emailKeyMap:' + emailKeyMap);

		// search for duplicates in existing leads 
		// arrange the existing lead list below format
		// {email1, [existingLead1, existingLead2, existingLead3]
		//  email2, [existingLead4, existingLead5]
		//  email3, [existingLead6]
		Map < String, List < Lead >> existingLeademailKeyMap = new Map < String, List < Lead >> ();

		for (Lead existingLead: [Select Id, Name, Email, MobilePhone from lead where email IN: emailKeyMap.keyset() and isConverted = false]) {
			if (existingLeademailKeyMap.containsKey(existingLead.Email)) existingLeademailKeyMap.get(existingLead.Email).add(existingLead);
			else {
				List < Lead > newList = new List < Lead > ();
				newList.add(existingLead);
				existingLeademailKeyMap.put(existingLead.email, newList);
			}
		}

		// loop through the incoming list map and check if there are duplicates in the existing lead map
		Map < Lead, List < Lead >> leadEmailDupMap = new Map < Lead, List < Lead >> ();
		for (String email: emailKeyMap.keyset()) {
			if (existingLeademailKeyMap.containsKey(email)) {
				for (Lead l: emailKeyMap.get(email)) {
					leadEmailDupMap.put(l, existingLeademailKeyMap.get(email));
					System.debug('Lead:' + l.lastName + 'lead duplicates are:' + existingLeademailKeyMap.get(email));
				}
			}
		}
		return leadEmailDupMap;
	}

	public static Map < Lead, List < Lead >> findLeadDupeforLeadsByMobile(List < Lead > leadList) {
		Map < String, List < Lead >> mobileKeyMap = new Map < String, List < Lead >> ();
		// arrange the incoming list of leads in the below format
		// {mobile1, [IncomingLead1, IncomingLead2, IncomingLead3]
		//  mobile2, [IncomingLead4, IncomingLead5]
		//  mobile3, [IncomingLead6]}
		if (leadList == null || leadList.isEmpty()) {
			List < String > customMsgList = new List < String > ();
			customMsgList.add('Incoming lead list is empty');
			throw new GlobalException(customMsgList, '', 'findLeadDupeForLeadsByMobile');
		}
		for (Lead l: leadList) {
			System.debug('lead l: ' + l);
			if (l.mobilePhone != null) {
				if (mobileKeyMap.containsKey(l.MobilePhone)) mobileKeyMap.get(l.MobilePhone).add(l);
				else {
					List < Lead > newList = new List < Lead > ();
					newList.add(l);
					mobileKeyMap.put(l.MobilePhone, newList);
				}
			}
		}
		System.debug('Incoming mobileKeyMap:' + mobileKeyMap);

		// arrange the existing lead list below format
		// {mobile1, [existingLead1, existingLead2, existingLead3]
		//  mobile2, [existingLead4, existingLead5]
		//  mobile3, [existingLead6]
		Map < String, List < Lead >> existingLeadMobileKeyMap = new Map < String, List < Lead >> ();

		for (Lead existingLead: [Select Id, Name, Email, MobilePhone from lead where MobilePhone IN: mobileKeyMap.keyset() and isConverted = false]) {
			if (existingLeadMobileKeyMap.containsKey(existingLead.MobilePhone)) existingLeadMobileKeyMap.get(existingLead.MobilePhone).add(existingLead);
			else {
				List < Lead > newList = new List < Lead > ();
				newList.add(existingLead);
				existingLeadMobileKeyMap.put(existingLead.MobilePhone, newList);
			}
		}

		// loop through the incoming list map and check if there are duplicates in the existing lead map
		Map < Lead, List < Lead >> leadMobileDupMap = new Map < Lead, List < Lead >> ();
		for (String mobile: mobileKeyMap.keyset()) {
			if (existingLeadMobileKeyMap.containsKey(mobile)) {
				for (Lead l: mobileKeyMap.get(mobile)) {
					leadMobileDupMap.put(l, existingLeadMobileKeyMap.get(mobile));
					System.debug('Lead:' + l.lastName + 'lead duplicates are:' + existingLeadMobileKeyMap.get(mobile));
				}
			}
		}
		return leadMobileDupMap;
	}

	public static Map < Lead, List < Account >> findPADupeforLeadsByEmail(List < Lead > leadList) {
		Map < String, List < Lead >> emailKeyMap = new Map < String, List < Lead >> ();
		// arrange the incoming list of leads in the below format
		// {email1, [IncomingLead1, IncomingLead2, IncomingLead3]
		//  email2, [IncomingLead4, IncomingLead5]
		//  email3, [IncomingLead6]}
		if (leadList == null || leadList.isEmpty()) {
			List < String > customMsgList = new List < String > ();
			customMsgList.add('Incoming lead list is empty');
			throw new GlobalException(customMsgList, '', 'findPADupeForLeadsByEmail');
		}
		for (Lead l: leadList) {
			System.debug('lead l: ' + l);
			if (l.email != null) {
				if (emailKeyMap.containsKey(l.Email)) emailKeyMap.get(l.Email).add(l);
				else {
					List < Lead > newList = new List < Lead > ();
					newList.add(l);
					emailKeyMap.put(l.email, newList);
				}
			}
		}
		System.debug('Incoming emailKeyMap:' + emailKeyMap);

		// search for duplicates in existing person accounts 
		// arrange the existing person account list below format
		// {email1, [existingPA1, existingPA2, existingPA3]
		//  email2, [existingPA4, existingPA5]
		//  email3, [existingPA6]

		Map < String, List < Account >> existingPAemailKeyMap = new Map < String, List < Account >> ();
		for (Account existingPA: [Select Id, Name, personEmail, personMobilePhone from Account where personemail IN: emailKeyMap.keyset() and isPersonAccount = true]) {
			if (existingPAemailKeyMap.containsKey(existingPA.personEmail)) existingPAemailKeyMap.get(existingPA.personEmail).add(existingPA);
			else {
				List < Account > newList = new List < Account > ();
				newList.add(existingPA);
				existingPAemailKeyMap.put(existingPA.personEmail, newList);
			}
		}

		// loop through the incoming lead map and check if there are duplicates in the existing person account map
		// the final duplicate Map will be of the below format
		// {lead1, [PADup1, PADup2]
		//  lead2, []
		//  lead3, [PADup3]}

		Map < Lead, List < Account >> personAccountEmailDup = new Map < Lead, List < Account >> ();
		for (String email: emailKeyMap.keyset()) {
			if (existingPAemailKeyMap.containsKey(email)) {
				for (Lead l: emailKeyMap.get(email)) {
					personAccountEmailDup.put(l, existingPAemailKeyMap.get(email));
					System.debug('Lead:' + l.lastName + 'person account duplicates are:' + existingPAemailKeyMap.get(email));
				}
			}
		}

		return personAccountEmailDup;

	}

	public static Map < Lead, List < Account >> findPADupeforLeadsByMobile(List < Lead > leadList) {
		Map < String, List < Lead >> mobileKeyMap = new Map < String, List < Lead >> ();
		// arrange the incoming list of leads in the below format
		// {mobile1, [IncomingLead1, IncomingLead2, IncomingLead3]
		//  mobile2, [IncomingLead4, IncomingLead5]
		//  mobile3, [IncomingLead6]}
		if (leadList == null || leadList.isEmpty()) {
			List < String > customMsgList = new List < String > ();
			customMsgList.add('Incoming lead list is empty');
			throw new GlobalException(customMsgList, '', 'findPADupeForLeadsByMobile');
		}
		for (Lead l: leadList) {
			System.debug('lead l: ' + l);
			if (l.MobilePhone != null) {
				if (mobileKeyMap.containsKey(l.MobilePhone)) mobileKeyMap.get(l.MobilePhone).add(l);
				else {
					List < Lead > newList = new List < Lead > ();
					newList.add(l);
					mobileKeyMap.put(l.MobilePhone, newList);
				}
			}
		}
		System.debug('Incoming mobileKeyMap:' + mobileKeyMap);

		// arrange the existing lead list below format
		// {mobile1, [existingLead1, existingLead2, existingLead3]
		//  mobile2, [existingLead4, existingLead5]
		//  mobile3, [existingLead6]
		Map < String, List < Account >> existingPAMobileKeyMap = new Map < String, List < Account >> ();

		for (Account existingPA: [Select Id, Name, personEmail, personMobilePhone from Account where personMobilePhone IN: mobileKeyMap.keyset() and isPersonAccount = true]) {
			if (existingPAMobileKeyMap.containsKey(existingPA.personMobilePhone)) existingPAMobileKeyMap.get(existingPA.personMobilePhone).add(existingPA);
			else {
				List < Account > newList = new List < Account > ();
				newList.add(existingPA);
				existingPAMobileKeyMap.put(existingPA.personMobilePhone, newList);
			}
		}

		// loop through the incoming list map and check if there are duplicates in the existing lead map
		Map < Lead, List < Account >> PAMobileDupMap = new Map < Lead, List < Account >> ();
		for (String mobile: mobileKeyMap.keyset()) {
			if (existingPAMobileKeyMap.containsKey(mobile)) {
				for (Lead l: mobileKeyMap.get(mobile)) {
					PAMobileDupMap.put(l, existingPAMobileKeyMap.get(mobile));
					System.debug('Lead:' + l.lastName + 'lead duplicates are:' + existingPAMobileKeyMap.get(mobile));
				}
			}
		}
		return PAMobileDupMap;
	}

	public static Map < Lead, Map < String, List < Id >>> aggregateLeadDuplicates(Map < Lead, List < Lead >> emailDupMap, Map < Lead, List < Lead >> MobileDupMap,
	Map < Lead, List < Account >> PAEmailDupMap, Map < Lead, List < Account >> PAMobileDupMap) {

		Map < Lead, Map < String, List < Id >>> leadDupAgg = new Map < Lead, Map < String, List < Id >>> ();
		if (!emailDupMap.isEmpty()) {
			for (Lead lead: emailDupMap.keyset()) {
				System.debug('231:' + emailDupMap.keyset());
				Map < String, List < Id >> leadMap = new Map < String, List < Id >> ();
				for (Lead dupLead: emailDupMap.get(lead)) {
					if (leadMap.containsKey('LEADEMAIL')) {
						leadMap.get('LEADEMAIL').add(duplead.Id);
					} else {
						List < Id > IdList = new List < Id > ();
						IdList.add(dupLead.Id);
						leadMap.put('LEADEMAIL', IdList);
					}
				}
				System.debug('leademail:' + leadMap);
				leadDupAgg.put(lead, leadMap);
				System.debug('Aggregate:244: ' + leadDupAgg);
			}
		}
		if (!MobileDupMap.isEmpty()) {
			for (Lead lead: MobileDupMap.keyset()) {
				Map < String, List < Id >> leadMap = new Map < String, List < Id >> ();
				for (Lead dupLead: MobileDupMap.get(lead)) {
					if (leadMap.containsKey('LEADMOBILE')) {
						leadMap.get('LEADMOBILE').add(duplead.Id);
					} else {
						List < Id > IdList = new List < Id > ();
						IdList.add(dupLead.Id);
						leadMap.put('LEADMOBILE', IdList);
					}
				}
				if (leadDupAgg.containsKey(lead)) {
					leadDupAgg.get(lead).putAll(leadMap);
				} else {
					leadDupAgg.put(lead, leadMap);
				}
				System.debug('Aggregate:265: ' + leadDupAgg);

			}
		}
		if (!PAEmailDupMap.isEmpty()) {
			for (Lead lead: PAEmailDupMap.keyset()) {
				System.debug('271:' + PAEmailDupMap.keyset());
				Map < String, List < Id >> accMap = new Map < String, List < Id >> ();
				for (Account dupAcc: PAEmailDupMap.get(lead)) {
					if (accMap.containsKey('PAEMAIL')) {
						accMap.get('PAEMAIL').add(dupAcc.Id);
					} else {
						List < Id > IdList = new List < Id > ();
						IdList.add(dupAcc.Id);
						accMap.put('PAEMAIL', IdList);
					}
				}
				System.debug('acc email:' + accMap);
				if (leadDupAgg.containsKey(lead)) {
					leadDupAgg.get(lead).putAll(accMap);
				} else {
					leadDupAgg.put(lead, accMap);
				}
				System.debug('Aggregate:285: ' + leadDupAgg);
			}
		}

		if (!PAMobileDupMap.isEmpty()) {
			for (Lead lead: PAMobileDupMap.keyset()) {
				System.debug('271:' + PAMobileDupMap.keyset());
				Map < String, List < Id >> accMap = new Map < String, List < Id >> ();
				for (Account dupAcc: PAMobileDupMap.get(lead)) {
					if (accMap.containsKey('PAMOBILE')) {
						accMap.get('PAMOBILE').add(dupAcc.Id);
					} else {
						List < Id > IdList = new List < Id > ();
						IdList.add(dupAcc.Id);
						accMap.put('PAMOBILE', IdList);
					}
				}
				System.debug('acc email:' + accMap);
				if (leadDupAgg.containsKey(lead)) {
					leadDupAgg.get(lead).putAll(accMap);
				} else {
					leadDupAgg.put(lead, accMap);
				}
				System.debug('Aggregate:304: ' + leadDupAgg);
			}
		}
		return leadDupAgg;
	}

	public static List < DupResultsDTO > dupHandler(Map < Lead, Map < String, List < Id >>> leadDupAgg, String context) {
		List < DupResultsDTO > dupResults;
		if (context == 'BULKLOAD') {
			dupResults = bulkLoadDupHandler(leadDupAgg, context);
		} else if (context == 'WEB' || context == 'EMAIL') {
			dupResults = WebDupHandler(leadDupAgg, context);
		} else {
			// not implementing for UI context as it will be handled by the DupeCatcher which has a better UI for handling duplicates
			// cant use the same for bulk as it doesnt handle bulk load
			// cant use the same for web forms as we need to take special actions not provided by dupe catcher
			System.debug('ERROR: duplicate logic invoked for context: ' + context + ' which hasnt been implemented');
			List < String > customMsgList = new List < String > ();

			customMsgList.add('ERROR: duplicate logic invoked for context: ' + context + ' which hasn\'t been implemented');
			throw new GlobalException(customMsgList, '', 'DupHandler');
		}

		return dupResults;
	}

	public static List < DupResultsDTO > bulkLoadDupHandler(Map < Lead, Map < String, List < Id >>> leadDupAgg, String context) {

		List < Account > updateAccList = new List < Account > ();
		List < Lead > updateLeadList = new List < Lead > ();
		List < DupResultsDTO > dupResultsList = new List < DupResultsDTO > ();

		for (Lead originalLead: leadDupAgg.keyset()) {
			DupResultsDTO dupResults = new DupResultsDTO();
			if (!leadDupAgg.get(originalLead).isEmpty()) {
				Map < String, List < Id >> dupMapPerLead = leadDupAgg.get(originalLead);

				if (!dupMapPerLead.isEmpty()) {
					// Aggregate and count the number of duplicates
					// goto no duplicates, one duplicate, or more than one duplicate scenario based on count

					Set < Id > leadDup = new Set < Id > ();
					if (dupMapPerLead.containsKey('LEADEMAIL')) leadDup.addAll(dupMapPerLead.get('LEADEMAIL'));
					if (dupMapPerLead.containsKey('LEADMOBILE')) leadDup.addAll(dupMapPerLead.get('LEADMOBILE'));

					Set < Id > accDup = new Set < Id > ();
					if (dupMapPerLead.containsKey('PAEMAIL')) accDup.addAll(dupMapPerLead.get('PAEMAIL'));
					if (dupMapPerLead.containsKey('PAMOBILE')) accDup.addAll(dupMapPerLead.get('PAMOBILE'));

					// bucket the duplicates into lead and account duplicates and populate in the DTO
					// mainly used in bulk upload for setting lead.addError with the list of all duplicate values
					Map < String, Set < Id >> dupMap = new Map < String, Set < Id >> ();
					if (!leadDup.isEmpty()) dupMap.put('LEAD', leadDup);
					if (!accDup.isEmpty()) dupMap.put('ACCOUNT', accDup);

					if (!dupMap.isEmpty()) {
						dupResults.duplicatesMap.putAll(dupMap);
					}

					dupResults.originalLead = originalLead;
					if (dupResults != null) {
						dupResultsList.add(dupResults);
					}
				}
			}
		}
		for (DupResultsDTO d: dupResultsList)
		System.debug('DupResults: ' + d.originalLead + ':' + d.dupEnquiryTaskId + ':' + d.duplicateMaster + ':' + d.duplicatesMap);
		return dupResultsList;
	}

	public static List < DupResultsDTO > WebDupHandler(Map < Lead, Map < String, List < Id >>> leadDupAgg, String context) {

		List < Account > updateAccList = new List < Account > ();
		List < Lead > updateLeadList = new List < Lead > ();
		List < DupResultsDTO > dupResultsList = new List < DupResultsDTO > ();

		for (Lead originalLead: leadDupAgg.keyset()) {
			DupResultsDTO dupResults = new DupResultsDTO();
			if (!leadDupAgg.get(originalLead).isEmpty()) {
				Map < String, List < Id >> dupMapPerLead = leadDupAgg.get(originalLead);

				if (!dupMapPerLead.isEmpty()) {
					// Aggregate and count the number of duplicates
					// goto no duplicates, one duplicate, or more than one duplicate scenario based on count

					Set < Id > leadDup = new Set < Id > ();
					if (dupMapPerLead.containsKey('LEADEMAIL')) leadDup.addAll(dupMapPerLead.get('LEADEMAIL'));
					if (dupMapPerLead.containsKey('LEADMOBILE')) leadDup.addAll(dupMapPerLead.get('LEADMOBILE'));

					Set < Id > accDup = new Set < Id > ();
					if (dupMapPerLead.containsKey('PAEMAIL')) accDup.addAll(dupMapPerLead.get('PAEMAIL'));
					if (dupMapPerLead.containsKey('PAMOBILE')) accDup.addAll(dupMapPerLead.get('PAMOBILE'));

					// bucket the duplicates into lead and account duplicates and populate in the DTO
					// mainly used in bulk upload for setting lead.addError with the list of all duplicate values
					Map < String, Set < Id >> dupMap = new Map < String, Set < Id >> ();
					if (!leadDup.isEmpty()) dupMap.put('LEAD', leadDup);
					if (!accDup.isEmpty()) dupMap.put('ACCOUNT', accDup);

					if (!dupMap.isEmpty()) {
						dupResults.duplicatesMap.putAll(dupMap);
					}

					if (leadDup.size() + accDup.size() == 0) {
						System.debug('No duplicates for lead:' + originalLead);
					} else if (leadDup.size() + accDup.size() == 1) {
						if (dupMapPerLead.containsKey('LEADEMAIL')) {
							Lead dupLead = [SELECT Email, MobilePhone, firstName, LastName, OwnerId, MasterRecord__c, DuplicatesIdentified__c, LatestDuplicates__c,
							Channel_Code__c, Campaign_Code__c, TollFree_Number__C
							from Lead where Id = : dupMapPerLead.get('LEADEMAIL')[0]];
							dupLead.Email = originalLead.Email;
							dupLead.MobilePhone = originalLead.mobilePhone;
							dupLead.firstName = originalLead.firstName;
							dupLead.lastName = originalLead.lastName;
							dupLead.MasterRecord__c = true;
							if (originalLead.Channel_Code__c != null) dupLead.Channel_Code__c = originalLead.Channel_Code__c;
							if (originalLead.TollFree_Number__c != null) dupLead.TollFree_Number__C = originallead.TollFree_Number__c;
							if (originalLead.Campaign_Code__C != null) dupLead.Campaign_Code__C = originalLead.Campaign_Code__c;
							if (dupLead.DuplicatesIdentified__C != null) dupLead.DuplicatesIdentified__C = dupLead.DuplicatesIdentified__c + dupLead.Id + '\n';
							else dupLead.DuplicatesIdentified__C = dupLead.Id + '\n';
							dupLead.LatestDuplicates__C = dupLead.Id;
							updateLeadList.add(dupLead);
							dupResults.originalLead = originalLead;
							dupResults.duplicateMaster = dupLead.Id;

						} else if (dupMapPerLead.containsKey('LEADMOBILE')) {
							Lead dupLead = [SELECT Email, MobilePhone, firstName, LastName, OwnerId, MasterRecord__c, DuplicatesIdentified__c, LatestDuplicates__c,
							Channel_Code__c, Campaign_Code__c, TollFree_Number__C
							from Lead where Id = : dupMapPerLead.get('LEADMOBILE')[0]];
							dupLead.Email = originalLead.Email;
							dupLead.MobilePhone = originalLead.mobilePhone;
							dupLead.firstName = originalLead.firstName;
							dupLead.lastName = originalLead.lastName;
							dupLead.MasterRecord__c = true;
							if (originalLead.Channel_Code__c != null) dupLead.Channel_Code__c = originalLead.Channel_Code__c;
							if (originalLead.TollFree_Number__c != null) dupLead.TollFree_Number__C = originallead.TollFree_Number__c;
							if (originalLead.Campaign_Code__C != null) dupLead.Campaign_Code__C = originalLead.Campaign_Code__c;
							if (dupLead.DuplicatesIdentified__C != null) dupLead.DuplicatesIdentified__C = dupLead.DuplicatesIdentified__c + dupLead.Id + '\n';
							else dupLead.DuplicatesIdentified__C = dupLead.Id + '\n';
							dupLead.LatestDuplicates__C = dupLead.Id;
							updateLeadList.add(dupLead);
							dupResults.originalLead = originalLead;
							dupResults.duplicateMaster = dupLead.Id;

						} else if (dupMapPerLead.containsKey('PAEMAIL')) {
							Account dupAcc = [SELECT PersonEmail, PersonMobilePhone, PersonContactId, firstName, LastName, OwnerId, MasterRecord__c, DuplicatesIdentified__c, LatestDuplicates__c,
							Channel_Code__c, Campaign_Code__c, TollFree_Number__C
							from Account where Id = : dupMapPerLead.get('PAEMAIL')[0]];
							dupAcc.PersonEmail = originalLead.Email;
							dupAcc.PersonMobilePhone = originalLead.mobilePhone;
							dupAcc.firstName = originalLead.firstName;
							dupAcc.lastName = originalLead.lastName;
							dupAcc.MasterRecord__c = true;
							if (originalLead.Channel_Code__c != null) dupAcc.Channel_Code__c = originalLead.Channel_Code__c;
							if (originalLead.TollFree_Number__c != null) dupAcc.TollFree_Number__C = originallead.TollFree_Number__c;
							if (originalLead.Campaign_Code__C != null) dupAcc.Campaign_Code__C = originalLead.Campaign_Code__c;
							dupAcc.Campaign_Code__C = originalLead.Campaign_Code__c;
							if (dupAcc.DuplicatesIdentified__C != null) dupAcc.DuplicatesIdentified__C = dupAcc.DuplicatesIdentified__c + dupAcc.Id + '\n';
							else dupAcc.DuplicatesIdentified__C = dupAcc.Id + '\n';
							dupAcc.LatestDuplicates__C = dupAcc.Id;
							updateAccList.add(dupAcc);
							dupResults.originalLead = originalLead;
							dupResults.duplicateMaster = dupAcc.Id;
						} else if (dupMapPerLead.containsKey('PAMOBILE')) {
							Account dupAcc = [SELECT PersonEmail, PersonMobilePhone, PersonContactId, firstName, LastName, OwnerId, MasterRecord__c, DuplicatesIdentified__c, LatestDuplicates__c,
							Channel_Code__c, Campaign_Code__c, TollFree_Number__C
							from Account where Id = : dupMapPerLead.get('PAMOBILE')[0]];
							dupAcc.PersonEmail = originalLead.Email;
							dupAcc.PersonMobilePhone = originalLead.mobilePhone;
							dupAcc.firstName = originalLead.firstName;
							dupAcc.lastName = originalLead.lastName;
							dupAcc.MasterRecord__c = true;
							if (originalLead.Channel_Code__c != null) dupAcc.Channel_Code__c = originalLead.Channel_Code__c;
							if (originalLead.TollFree_Number__c != null) dupAcc.TollFree_Number__C = originallead.TollFree_Number__c;
							if (originalLead.Campaign_Code__C != null) dupAcc.Campaign_Code__C = originalLead.Campaign_Code__c;
							if (dupAcc.DuplicatesIdentified__C != null) dupAcc.DuplicatesIdentified__C = dupAcc.DuplicatesIdentified__c + dupAcc.Id + '\n';
							else dupAcc.DuplicatesIdentified__C = dupAcc.Id + '\n';
							dupAcc.LatestDuplicates__C = dupAcc.Id;
							updateAccList.add(dupAcc);
							dupResults.originalLead = originalLead;
							dupResults.duplicateMaster = dupAcc.Id;
						} else {
							System.debug('Some error: duplicate map contains an unknown key: \n');
							List < String > customMsgList = new List < String > ();
							customMsgList.add('Duplicate Map Contains an unknown Key:');
							throw new GlobalException(customMsgList, '', 'WebDupHandler');
						}
					} else {
						//If more than one duplicate exists?
						// check if a master record exists, use that else
						//query the first duplicate record, add incoming fields to that
						//create a task of repeat enquiry against it and return the id
						System.debug('More than one duplicates exists for lead Id: ' + originalLead + ' and they are ' + dupMapPerLead);

						List < Lead > leadDupRecs = new List < Lead > ();
						List < Account > AccDupRecs = new List < Account > ();
						if (!leadDup.isEmpty()) {

							leadDupRecs = [SELECT Email, MobilePhone, firstName, LastName, OwnerId, MasterRecord__c, DuplicatesIdentified__c, LatestDuplicates__c,
							Channel_Code__c, Campaign_Code__c, TollFree_Number__C
							from Lead where Id in : leadDup];
						}
						if (!accDup.isEmpty()) {
							accDupRecs = [SELECT PersonEmail, PersonMobilePhone, PersonContactId, firstName, LastName, OwnerId, MasterRecord__c, DuplicatesIdentified__c, LatestDuplicates__c,
							Channel_Code__c, Campaign_Code__c, TollFree_Number__C
							from Account where Id in : AccDup];
						}
						// if a master record which has been used for merge is identified, use that as the master and upsert the values
						// else use the first record from lead or account as master and upsert that record

						//Duplicate list is a comma separated list of all account + lead duplicates of a lead record.
						//writing this back to the database in the duplicateList field. this field has a running list of all duplicates identified in multiple updates of the lead
						//latest duplicate field contains the duplicates identified in the last update/insert of the lead record
						List < String > DuplicateList = new List < String > ();
						if (!leadDupRecs.isEmpty()) {
							for (lead l: leadDupRecs) {
								String dup = l.Id;
								DuplicateList.add(dup);
							}
						}
						if (!AccDupRecs.isEmpty()) {
							for (Account a: AccDupRecs) {
								String dup = a.Id;
								DuplicateList.add(dup);
							}
						}
						Boolean masterFound = false;
						for (lead l: leadDupRecs) {
							if (l.MasterRecord__C) {
								l.Email = originalLead.Email;
								l.MobilePhone = originalLead.mobilePhone;
								l.firstName = originalLead.firstName;
								l.lastName = originalLead.lastName;
								System.debug('channel code information:' + originalLead.Channel_Code__c);
								if (originalLead.Channel_Code__c != null) l.Channel_Code__c = originalLead.Channel_Code__c;
								if (originalLead.TollFree_Number__c != null) l.TollFree_Number__C = originallead.TollFree_Number__c;
								if (originalLead.Campaign_Code__C != null) l.Campaign_Code__C = originalLead.Campaign_Code__c;
								if (l.DuplicatesIdentified__C != null) l.DuplicatesIdentified__C = l.DuplicatesIdentified__c + String.valueOf(DuplicateList) + '\n';
								else l.DuplicatesIdentified__C = String.valueOf(DuplicateList) + '\n';
								l.LatestDuplicates__C = String.valueOf(DuplicateList);
								updateLeadList.add(l);
								dupResults.originalLead = originalLead;
								dupResults.duplicateMaster = l.Id;
								masterFound = true;
								break;
							}
						}
						if (!masterFound) {
							for (Account a: accDupRecs) {
								if (a.MasterRecord__c) {
									a.PersonEmail = originalLead.Email;
									a.PersonMobilePhone = originalLead.mobilePhone;
									a.firstName = originalLead.firstName;
									a.lastName = originalLead.lastName;
									if (originalLead.Channel_Code__c != null) a.Channel_Code__c = originalLead.Channel_Code__c;
									if (originalLead.TollFree_Number__c != null) a.TollFree_Number__C = originallead.TollFree_Number__c;
									if (originalLead.Campaign_Code__C != null) a.Campaign_Code__C = originalLead.Campaign_Code__c;
									if (a.DuplicatesIdentified__C != null) a.DuplicatesIdentified__C = a.DuplicatesIdentified__c + String.valueOf(DuplicateList) + '\n';
									else a.DuplicatesIdentified__C = String.valueOf(DuplicateList) + '\n';
									a.LatestDuplicates__C = String.valueOf(DuplicateList);
									updateAccList.add(a);
									dupResults.originalLead = originalLead;
									dupResults.duplicateMaster = a.Id;
									masterFound = true;
									break;
								}
							}
						}
						if (!masterFound && !leadDupRecs.isEmpty()) {
							leadDupRecs[0].Email = originalLead.Email;
							leadDupRecs[0].MobilePhone = originalLead.mobilePhone;
							leadDupRecs[0].firstName = originalLead.firstName;
							leadDupRecs[0].lastName = originalLead.lastName;
							leadDupRecs[0].MasterRecord__c = true;
							if (originalLead.Channel_Code__c != null) leadDupRecs[0].Channel_Code__c = originalLead.Channel_Code__c;
							if (originalLead.TollFree_Number__c != null) leadDupRecs[0].TollFree_Number__C = originallead.TollFree_Number__c;
							if (originalLead.Campaign_Code__C != null) leadDupRecs[0].Campaign_Code__C = originalLead.Campaign_Code__c;
							leadDupRecs[0].DuplicatesIdentified__C = leadDupRecs[0].DuplicatesIdentified__c + String.valueOf(DuplicateList);
							leadDupRecs[0].LatestDuplicates__C = String.valueOf(DuplicateList);
							updateLeadList.add(leadDupRecs[0]);
							dupResults.originalLead = originalLead;
							dupResults.duplicateMaster = leadDupRecs[0].Id;
							masterFound = true;
						}
						if (!masterFound && !AccDupRecs.isEmpty()) {
							AccDupRecs[0].PersonEmail = originalLead.Email;
							AccDupRecs[0].PersonMobilePhone = originalLead.mobilePhone;
							AccDupRecs[0].firstName = originalLead.firstName;
							AccDupRecs[0].lastName = originalLead.lastName;
							AccDupRecs[0].MasterRecord__C = true;
							if (originalLead.Channel_Code__c != null) AccDupRecs[0].Channel_Code__c = originalLead.Channel_Code__c;
							if (originalLead.TollFree_Number__c != null) AccDupRecs[0].TollFree_Number__C = originallead.TollFree_Number__c;
							if (originalLead.Campaign_Code__C != null) AccDupRecs[0].Campaign_Code__C = originalLead.Campaign_Code__c;
							AccDupRecs[0].DuplicatesIdentified__C = AccDupRecs[0].DuplicatesIdentified__c + String.valueOf(DuplicateList);
							AccDupRecs[0].LatestDuplicates__C = String.valueOf(DuplicateList);
							updateAccList.add(AccDupRecs[0]);
							dupResults.originalLead = originalLead;
							dupResults.duplicateMaster = leadDupRecs[0].Id;
							masterFound = true;
						}
					}

				}
				if (dupResults != null) {
					dupResultsList.add(dupResults);
				}
			}
		}
		String description = 'Repeat Enquiry Received From: ' + context;
		Map < Id, Task > completeTaskMap = new Map < Id, Task > ();

		if (!updateLeadList.isEmpty()) {
			try {
				Database.SaveResult[] srList = Database.update(updateLeadList, true);
				for (Database.SaveResult sr: srList) {
					if (sr.isSuccess()) {
						// Operation was successful, so get the ID of the record that was processed
						System.debug('Successfully updated lead. Lead ID: ' + sr.getId());
					} else {
						// Operation failed, so get all errors  
						List < String > customMsgList = new List < String > ();
						for (Database.Error err: sr.getErrors()) {
							String msg = 'Lead Update Failed :' + err.getMessage();
							customMsgList.add(msg);
						}
						throw new GlobalException(customMsgList, '', 'WebDedupeHandler');
					}
				}
			} catch (System.DmlException ex) {
				List < String > customMsgList = new List < String > ();
				for (Integer i = 0; i < ex.getNumDml(); i++) {
					String msg = 'Lead Update Failed :' + ex.getMessage();
					customMsgList.add(msg);
				}
				throw new GlobalException(customMsgList, '', 'WebDedupeHandler');
			}
			Map < Id, Task > leadWhoIdMap = TaskManagementServices.createTaskForLeads(updateLeadList, 'Repeat Enquiry', 'Open', 'SYSTEM GENERATED TASK', '', '', description,'');
			if (!leadWhoIdMap.isEmpty()) {
				completeTaskMap.putAll(leadWhoIdMap);
			}
		}

		if (!updateAccList.isEmpty()) {
			try {
				Database.SaveResult[] srList = Database.update(updateAccList, true);
				for (Database.SaveResult sr: srList) {
					if (sr.isSuccess()) {
						// Operation was successful, so get the ID of the record that was processed
						System.debug('Successfully updated Account. Account ID: ' + sr.getId());
					} else {
						// Operation failed, so get all errors  
						List < String > customMsgList = new List < String > ();
						for (Database.Error err: sr.getErrors()) {
							String msg = 'Account Update Failed :' + err.getMessage();
							customMsgList.add(msg);
						}
						throw new GlobalException(customMsgList, '', 'WebDedupeHandler');
					}
				}
			} catch (System.DmlException ex) {
				List < String > customMsgList = new List < String > ();
				for (Integer i = 0; i < ex.getNumDml(); i++) {
					String msg = 'Account Update Failed :' + ex.getMessage();
					customMsgList.add(msg);
				}
				throw new GlobalException(customMsgList, '', 'WebDedupeHandler');
			}
			Map < Id, Task > AccWhoIdMap = TaskManagementServices.createTaskForAccounts(updateAccList, 'Repeat Enquiry', 'Open', 'SYSTEM GENERATED TASK', '', '', description,'');
			if (!AccWhoIdMap.isEmpty()) {
				completeTaskMap.putAll(AccWhoIdMap);
			}
		}
		if (!dupResultsList.isEmpty()) {
			for (DupResultsDTO d: dupResultsList) {
				if (completeTaskMap.containsKey(d.duplicateMaster)) {
					d.dupEnquiryTaskId = completeTaskMap.get(d.duplicateMaster).Id;
				}
			}
		}
		for (DupResultsDTO d: dupResultsList)
		System.debug('DupResults: ' + d.originalLead + ':' + d.dupEnquiryTaskId + ':' + d.duplicateMaster + ':' + d.duplicatesMap);
		return dupResultsList;
	}
}