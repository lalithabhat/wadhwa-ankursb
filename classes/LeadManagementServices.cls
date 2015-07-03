public class LeadManagementServices{

    public static List<DupResultsDTO> leadPreProcessing(List<Lead> LeadList, String context){
       
        Map<Lead,List<Lead>> leadEmailDupMap = DedupeChecker.findLeadDupeforLeads('EMAIL', leadList);
        System.debug('lead email dup: ' + leadEmailDupMap);
        
        Map<Lead,List<Account>> personAccountEmailDup = DedupeChecker.findPADupeforLeads('EMAIL',leadList);
        System.debug('PA Email Dup: ' + personAccountEmailDup);
        
        Map<Lead, List<Lead>> leadMobileDupMap  = DedupeChecker.findLeadDupeforLeads('MOBILE', leadList);
        System.debug('Lead Mobile Dup: ' + leadMobileDupMap);
        
        Map<Lead,List<Account>>  PAMobileDupMap = DedupeChecker.findPADupeforLeads('MOBILE',leadList);
        System.debug('PA Mobile Duplicates: ' + PAMobileDupMap);
        
        Map<Lead, Map<String, List<Id>>> leadDupAgg = DedupeChecker.aggregateLeadDuplicates(leadEmailDupMap, leadMobileDupMap, personAccountEmailDup, PAMobileDupMap);
        System.debug('AggregatedDuplicates: ' + leadDupAgg);
        List<DupResultsDTO> dupResults = new List<DupResultsDTO>();
        if(leadDupAgg!=null & !leadDupAgg.isEmpty()) {
            // duplicates exists, based on the context of the method call, like batch loading, webservice call 
            // take context specific remedial action for duplicates
            dupResults = DedupeChecker.dupHandler(leadDupAgg, context);
        }
  
   		return dupResults;
    }  
    
    public static void AddCampaignToLead(List<Lead> leadList) {
    	//Based on EnquiryMode for CALLS
		Map<String,List<String>> campaignDetails = new Map<String,List<String>>();
		
		//collect the campaign codes or toll free numbers into a list and put them into appropriate buckets [mapkeys]
    	for(lead l:leadList) {
				if(l.TollFree_Number__c != null)  {
					if(campaignDetails.containsKey('TOLLFREENUMBER')) {
						campaignDetails.get('TOLLFREENUMBER').add(l.TollFree_Number__C);
					} else {
						List<String> tollFreeList = new List<String>();
						tollFreeList.add(l.TollFree_Number__C);
						campaignDetails.put('TOLLFREENUMBER', tollFreeList);
					}
				}
				if(l.Campaign_Code__C != null)  {
					if(campaignDetails.containsKey('CAMPAIGNCODE')) {
						campaignDetails.get('CAMPAIGNCODE').add(l.Campaign_Code__C);
					} else {
						List<String> codeList = new List<String>();
						codeList.add(l.Campaign_Code__C);
						campaignDetails.put('CAMPAIGNCODE', codeList);
					}
				}
    	}
    	Map<String,Campaign> searchResults = new Map<String,Campaign>();
    	
    	System.debug('CampaignDetails:' + CampaignDetails);
		if(campaignDetails != null && !campaignDetails.isEmpty())	
		searchResults = CampaignManagementServices.searchCampaign(CampaignDetails);
		
		// create a Map like below
		// { campaingnA, [List of Lead to add to that campaign]
		// 	 campaignB, [List of leads to add to that campaign]
		Map<Campaign,List<lead>> campaignMap = new Map<Campaign,List<Lead>>();
		
		for(lead l: leadList) {
			if(searchResults.containsKey(l.TollFree_Number__c)) {
				Campaign c= searchResults.get(l.TollFree_Number__c);
				if(campaignMap.containsKey(c)){
					campaignMap.get(c).add(l);
				} else {
					List<lead> ll = new List<Lead>();
					ll.add(l);
					campaignMap.put(c,ll);
				}
			}
			
			if(searchResults.containsKey(l.Campaign_Code__c)) {
				Campaign c= searchResults.get(l.Campaign_Code__c);
				if(campaignMap.containsKey(c)){
					campaignMap.get(c).add(l);
				} else {
					List<lead> ll = new List<Lead>();
					ll.add(l);
					campaignMap.put(c,ll);
				}
			}			
		}
		CampaignManagementServices.addCampaignToLead(campaignMap);
    } 
}