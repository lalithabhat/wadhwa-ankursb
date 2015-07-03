public with sharing class JQtest1Controller {
		public string firstName {get;set;}
		public string lastName {get;set;}
		
        public JQtest1Controller() {
                
        }
        
        @RemoteAction
        public  static String createContact(String f, String n) {
                System.debug('In create contact:');
                contact c = new Contact(firstName = f, lastName = n);
                insert c;
                return c.id;
        }
}