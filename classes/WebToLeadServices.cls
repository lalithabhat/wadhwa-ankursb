global class WebToLeadServices {

	global static final String INPUT_ERROR = 'MISSING REQUIRED PARAMETERS';

	global class result {
		webservice Integer returnCode;
		webservice String message;
		webservice Id recordId;
	}

//TODO add toll free number in the method signature and as part of lead and task creation
	global class WebLead {
		webservice String fullName;
		webservice String emailAddress;
		webservice String countryCode;
		webservice String dialingCode;
		webservice String mobileNumber;
		webservice String ProjectInterested;
		webservice String leadLocation;
		webservice String campaignCode;
		webservice String channelCode;
		webservice String description;
		webservice String serachKeyword;
		webservice String placement;
		webservice String capturePoint;
		webservice String pageURL;
		webservice String source; //click2call, microsite, corpsite etc.
		webservice String tollFreeNumber; 
	}

	global class WebTask {
		webservice Id recordId;
		webservice String taskType;
		webservice String Status;
		webservice String Subject;
		webservice String callDisposition;
		webservice String callType;
		webservice String description;
		webservice String countryCode;
		webservice String dialingCode;
		webservice String mobileNumber;
		webservice String source;
		webservice String tollfreeNumber;
	}

	webservice static result createLeadFromWeb(WebLead wl) {
		List < Lead > leadList = new List < Lead > ();
		Lead l = null;
		result r = new result();

		System.debug('WEB LEAD:' + wl);

		if (String.isBlank(wl.countryCode) || String.isBlank(wl.dialingCode) || String.isBlank(wl.mobileNumber)) {
			System.debug('Missing Required Parameters');
			r.returnCode = 1;
			r.message = INPUT_ERROR;
			r.recordId = null;
			return r;
		} else {
			l = new Lead(lastName = wl.fullName,
			mobilePhone = wl.mobileNumber,
			campaign_code__c = wl.campaignCode,
			channel_code__C = wl.channelcode,
			email = wl.emailAddress,
			tollfree_number__C = wl.tollfreeNumber);
		}
		leadList.add(l);
		try {
			List < DupResultsDTO > dupList = LeadManagementServices.leadPreprocessing(leadList, 'WEB');
			if (dupList.isEmpty()) {
				try {
					Database.saveResult[] srList = Database.insert(leadList, true);
					for (Database.SaveResult sr: srList) {
						if (sr.isSuccess()) {
							// Operation was successful, so get the ID of the record that was processed
							System.debug('Successfully inserted account. Task ID: ' + sr.getId());
							r.recordId = sr.getId();
							r.returnCode = 0;
							r.message = 'SUCCESS';
						} else {
							// Operation failed, so get all errors  
							String msg = null;
							for (Database.Error err: sr.getErrors()) {
								msg = 'Lead Insert Failed :' + err.getMessage();
							}
							r.returnCode = 1;
							r.message = msg;
							r.recordId = null;
							return r;
						}
					}
				} catch (System.DmlException ex) {
					String msg = null;
					for (Integer i = 0; i < ex.getNumDml(); i++) {
						msg = 'Lead Insert Failed :' + ex.getMessage();
					}
					r.returnCode = 1;
					r.message = msg;
					r.recordId = null;
					return r;
				}
			} else {
				r.recordId = dupList[0].duplicateMaster;
				r.returnCode = 0;
				r.message = 'SUCCESS';
			}
		} catch (GlobalException g) {
			r.returnCode = 1;
			r.message = g.getErrorMsg()[0];
			r.recordId = null;
			return r;
		}
		return r;
	}

	webservice static result createMissedCallLog(WebTask wt) {

		result r = new result();

		if (String.isBlank(wt.recordId) || String.isBlank(wt.mobileNumber) || String.isBlank(wt.countryCode) || String.isBlank(wt.dialingCode)) {
			System.debug('Missing Required Parameters');
			r.returnCode = 1;
			r.message = INPUT_ERROR;
			r.recordId = null;
			return r;
		} else {
			if (String.isBlank(wt.subject)) {
				wt.subject = 'Call';
			}
			if (String.isBlank(wt.Status)) {
				wt.status = 'Open';
			}
			if (String.isBlank(wt.callType)) {
				wt.callType = 'Inbound';
			}
			if (String.isBlank(wt.callDisposition)) {
				wt.callDisposition = 'Unanswered';
			}
			if (String.isBlank(wt.description)) {
				wt.description = 'Click2Call - Not Connected';
			}
			if(String.isBlank(wt.tasktype)) {
				wt.taskType = 'Call';
			}
			Map < Id, Task > taskMap = new Map < Id, Task > ();

			try {
				if (Id.valueOf(wt.recordId).getSobjectType() == Schema.Lead.SObjectType) {
					List < lead > ll = [select Id, Name, OwnerId from Lead where Id = :Id.valueOf(wt.recordId)];
					if(!ll.isEmpty())
						taskMap = TaskManagementServices.createTaskforLeads(ll, wt.taskType, wt.Status, wt.Subject, wt.callType, wt.callDisposition, wt.description , wt.tollfreeNumber);
				} else if (Id.valueOf(wt.recordId).getSobjectType() == Schema.Account.SObjectType) {
					List < Account > al = [Select Id, Name,OwnerId from Account where Id = :Id.valueOf(wt.recordId)];
					if(!al.isEmpty())
						taskMap = TaskManagementServices.createTaskforAccounts(al, wt.taskType, wt.Status, wt.Subject, wt.callType, wt.callDisposition, wt.description, wt.tollfreeNumber);
				} else {
					List < String > customMsgList = new List < String > ();
					String msg = 'Invalid record Id, Neither an Account nor a Lead';
					customMsgList.add(msg);
					throw new GlobalException(customMsgList, '', 'createMissedCallLog');
				}
				if (!taskMap.isEmpty() && taskMap.containsKey(Id.valueOf(wt.recordId))) {
					r.returnCode = 0;
					r.message = 'SUCCESS';
					r.recordId = taskMap.get(Id.valueOf(wt.recordId)).Id;
					return r;
				} else {
					List < String > customMsgList = new List < String > ();
					String msg = 'Task not created';
					customMsgList.add(msg);
					throw new GlobalException(customMsgList, '', 'createMissedCallLog');

				}

			} catch (GlobalException g) {
				r.returnCode = 1;
				r.message = g.getErrorMsg()[0];
				r.recordId = null;
				return r;
			} catch (Exception e) {
				r.returnCode = 1;
				r.message = e.getMessage();
				r.recordId = null;
				return r;
			}
		}

	}
}