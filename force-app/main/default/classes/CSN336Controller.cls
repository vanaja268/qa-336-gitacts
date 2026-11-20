/**
 * CSN-336 TC-06: Apex controller - control language. Not analysed by the ESLint engine,
 * so its results must be identical before/after the fix.
 * Also holds a FAKE hard-coded credential for the Gitleaks regression check (TC-10).
 */
public with sharing class CSN336Controller {
    public String userInput { get; set; }

    // FAKE secret for Gitleaks regression (not a real credential)
    private static final String API_PASSWORD = 'Csn336-Fake-P4ssw0rd-9f8e7d6c';

    public CSN336Controller() {
        userInput = ApexPages.currentPage().getParameters().get('q');
    }

    public void updateContacts(List<Account> accounts) {
        for (Account a : accounts) {
            // SOQL + DML inside loop
            List<Contact> cs = [SELECT Id FROM Contact WHERE AccountId = :a.Id];
            update cs;
        }
    }

    public void emptyCatch() {
        try {
            Integer i = 1 / 0;
        } catch (Exception e) {
        }
    }
}
