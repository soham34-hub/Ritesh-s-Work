import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue, getRecordNotifyChange } from 'lightning/uiRecordApi';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import searchCis from '@salesforce/apex/CisService.searchCis';
import createCisProfile from '@salesforce/apex/CisService.createCisProfile';
import updateCpid from '@salesforce/apex/CisService.updateCpid';
import findAccountByName from '@salesforce/apex/AccountController.findAccountByName';
import getAccountRecordTypes from '@salesforce/apex/AccountController.getAccountRecordTypes';

import FIRST_NAME      from '@salesforce/schema/Account.First_Name__c';
import LAST_NAME       from '@salesforce/schema/Account.Last_Name__c';
import TAX_ID          from '@salesforce/schema/Account.Tax_ID__c';
import SSN             from '@salesforce/schema/Account.Social_Security_Number__c';
import ACCOUNT_NAME    from '@salesforce/schema/Account.Name';
import RECORD_TYPE_ID      from '@salesforce/schema/Account.RecordTypeId';
import RT_DEVELOPER_NAME   from '@salesforce/schema/Account.RecordType.DeveloperName';
import BILLING_STREET  from '@salesforce/schema/Account.BillingStreet';
import BILLING_CITY    from '@salesforce/schema/Account.BillingCity';
import BILLING_STATE   from '@salesforce/schema/Account.BillingState';
import BILLING_ZIP     from '@salesforce/schema/Account.BillingPostalCode';
import BILLING_COUNTRY from '@salesforce/schema/Account.BillingCountry';

const ACCOUNT_FIELDS = [
    FIRST_NAME, LAST_NAME, TAX_ID, SSN, ACCOUNT_NAME, RECORD_TYPE_ID, RT_DEVELOPER_NAME,
    BILLING_STREET, BILLING_CITY, BILLING_STATE, BILLING_ZIP, BILLING_COUNTRY
];

export default class ResolveCpIdLWC extends LightningElement {

    @api recordId;

    // ── Search field values ───────────────────────────────────────────────────
    ssn       = '';
    tin       = '';
    firstName = '';
    lastName  = '';
    street    = '';
    city      = '';
    state     = '';
    zip       = '';
    country   = '';

    // ── Current account fields (for comparison + form defaults) ───────────────
    _currentAccountName  = '';
    _currentRecordTypeId = '';
    _currentRtDevName    = '';   // 'Party' | 'Individual' | 'PersonAccount'
    _autoSearched        = false;

    // ── Search state ──────────────────────────────────────────────────────────
    isSearching            = false;
    hasSearched            = false;
    searchResults          = [];
    selectedCisId          = null;
    selectedResult         = null;
    errorMessage           = '';
    hasError               = false;

    // ── Warning state ─────────────────────────────────────────────────────────
    showDiffAccountWarning = false;
    showNotFoundWarning    = false;
    _resolveTargetId       = null;

    // ── Create form state ─────────────────────────────────────────────────────
    showCreateForm      = false;
    showCisCreatedMsg   = false;   // shown after CIS profile created, before link
    _cisCreatedId       = null;    // CPID returned from CIS create
    isCreating       = false;
    hasCreateError   = false;
    createErrorMessage = '';
    createStatusMsg  = 'Creating CIS profile...';

    // Record type options for create form
    recordTypeOptions = [];
    newRecordTypeId   = '';
    _newRtDevName     = '';   // developer name of selected RT in create form

    // Create form field values (prefilled from search fields)
    newFirstName = '';
    newLastName  = '';
    newSsn       = '';
    newTin       = '';
    newStreet    = '';
    newCity      = '';
    newState     = '';
    newZip       = '';
    newCountry   = '';

    // ── Wire ──────────────────────────────────────────────────────────────────
    connectedCallback() {
        // Notify cisStatusBanner to pause toast polling while this modal is open
        window.dispatchEvent(new CustomEvent('resolvecpid_modal_open'));

        getAccountRecordTypes()
            .then(function(types) {
                var cpidTypes = ['Party', 'Individual', 'PersonAccount'];
                this.recordTypeOptions = (types || [])
                    .filter(function(rt) { return cpidTypes.indexOf(rt.developerName) !== -1; })
                    .map(function(rt) { return { label: rt.name, value: rt.id, developerName: rt.developerName }; });
                // Default to the current account's RT if it's a CPID type, else first option
                if (this.recordTypeOptions.length > 0 && !this.newRecordTypeId) {
                    var matchingRt = this.recordTypeOptions.find(function(o) {
                        return o.developerName === this._currentRtDevName;
                    }.bind(this));
                    var defaultRt = matchingRt || this.recordTypeOptions[0];
                    this.newRecordTypeId = defaultRt.value;
                    this._newRtDevName   = defaultRt.developerName || '';
                }
            }.bind(this))
            .catch(function(error) {
                console.error('resolveCpIdLWC getAccountRecordTypes error:', error);
            }.bind(this));
    }

    @wire(getRecord, { recordId: '$recordId', fields: ACCOUNT_FIELDS })
    wiredAccount({ data, error }) {
        if (data) {
            this._currentAccountName  = getFieldValue(data, ACCOUNT_NAME) || '';
            this._currentRecordTypeId = getFieldValue(data, RECORD_TYPE_ID) || '';
            this._currentRtDevName    = getFieldValue(data, RT_DEVELOPER_NAME) || '';
            this.firstName = getFieldValue(data, FIRST_NAME)      || '';
            this.lastName  = getFieldValue(data, LAST_NAME)       || '';
            this.tin       = getFieldValue(data, TAX_ID)          || '';
            this.ssn       = getFieldValue(data, SSN)             || '';
            this.street    = getFieldValue(data, BILLING_STREET)  || '';
            this.city      = getFieldValue(data, BILLING_CITY)    || '';
            this.state     = getFieldValue(data, BILLING_STATE)   || '';
            this.zip       = getFieldValue(data, BILLING_ZIP)     || '';
            this.country   = getFieldValue(data, BILLING_COUNTRY) || '';

            if (!this._autoSearched) {
                this._autoSearched = true;
                // Only auto-search if the relevant field for this RT is populated
                var rt = this._currentRtDevName;
                var isPersonAccount = rt === 'Individual' || rt === 'PersonAccount';
                var isParty         = rt === 'Party';
                var hasRelevantData = (isPersonAccount && this.ssn)
                    || (isParty && this.tin);
                if (hasRelevantData) {
                    this.handleSearch();
                }
            }
        }
        if (error) {
            console.error('resolveCpIdLWC wiredAccount error:', error);
        }
    }

    // ── Getters ───────────────────────────────────────────────────────────────
    get hasResults() {
        return this.hasSearched && !this.isSearching && this.searchResults.length > 0;
    }

    get noResults() {
        return this.hasSearched && !this.isSearching &&
               this.searchResults.length === 0 && !this.hasError;
    }

    get isLinkDisabled() {
        return !this.selectedCisId || this.showDiffAccountWarning || this.showNotFoundWarning;
    }

    // Create New Account is only enabled when search returned 0 results
    get isCreateDisabled() {
        return !this.hasSearched || this.searchResults.length > 0;
    }

    // SSN/TIN visibility in CREATE FORM based on selected record type
    get newShowSsnField() {
        return this._newRtDevName === 'Individual' || this._newRtDevName === 'PersonAccount';
    }

    get newShowTinField() {
        return this._newRtDevName === 'Party';
    }

    // SSN field shown only for Individual / PersonAccount
    get showSsnField() {
        var rt = this._currentRtDevName;
        return rt === 'Individual' || rt === 'PersonAccount';
    }

    // TIN field shown only for Party
    get showTinField() {
        return this._currentRtDevName === 'Party';
    }

    // ── Search field handlers ─────────────────────────────────────────────────
    handleSsnChange(event)       { this.ssn       = event.detail.value; }
    handleTinChange(event)       { this.tin       = event.detail.value; }
    handleFirstNameChange(event) { this.firstName = event.detail.value; }
    handleLastNameChange(event)  { this.lastName  = event.detail.value; }
    handleStreetChange(event)    { this.street    = event.detail.value; }
    handleCityChange(event)      { this.city      = event.detail.value; }
    handleStateChange(event)     { this.state     = event.detail.value; }
    handleZipChange(event)       { this.zip       = event.detail.value; }
    handleCountryChange(event)   { this.country   = event.detail.value; }

    // ── Create form field handlers ────────────────────────────────────────────
    handleNewFirstNameChange(event) { this.newFirstName = event.detail.value; }
    handleNewLastNameChange(event)  { this.newLastName  = event.detail.value; }
    handleNewSsnChange(event)       { this.newSsn       = event.detail.value; }
    handleNewTinChange(event)       { this.newTin       = event.detail.value; }
    handleNewStreetChange(event)    { this.newStreet    = event.detail.value; }
    handleNewCityChange(event)      { this.newCity      = event.detail.value; }
    handleNewStateChange(event)     { this.newState     = event.detail.value; }
    handleNewZipChange(event)       { this.newZip       = event.detail.value; }
    handleNewCountryChange(event)   { this.newCountry   = event.detail.value; }

    handleNewRecordTypeChange(event) {
        this.newRecordTypeId = event.detail.value;
        var selected = this.recordTypeOptions.find(function(o) { return o.value === event.detail.value; });
        this._newRtDevName = selected ? (selected.developerName || '') : '';
    }

    // ── Enter key triggers search ─────────────────────────────────────────────
    handleKeyDown(event) {
        if ((event.key === 'Enter' || event.key === 'Return') && !this.isSearching) {
            this.handleSearch();
        }
    }

    // ── Search CIS ────────────────────────────────────────────────────────────
    handleSearch() {
        this.isSearching           = true;
        this.hasSearched           = false;
        this.searchResults         = [];
        this.selectedCisId         = null;
        this.selectedResult        = null;
        this.hasError              = false;
        this.errorMessage          = '';
        this.showDiffAccountWarning = false;
        this.showNotFoundWarning   = false;

        // Enforce RT-based search: PersonAccount/Individual → SSN only, Party → TIN only
        var rt = this._currentRtDevName;
        var isPersonAccount = rt === 'Individual' || rt === 'PersonAccount';
        var isParty         = rt === 'Party';
        var searchSsn = isPersonAccount ? this.ssn : '';
        var searchTin = isParty         ? this.tin : '';

        searchCis({
            ssn: searchSsn, tin: searchTin,
            firstName: this.firstName, lastName: this.lastName,
            street: this.street, city: this.city,
            state: this.state, zip: this.zip, country: this.country
        })
            .then(function(results) {
                this.hasSearched   = true;
                this.isSearching   = false;
                this.searchResults = (results || []).map(function(r) {
                    return Object.assign({}, r, { isSelected: false, rowClass: '' });
                });
            }.bind(this))
            .catch(function(error) {
                this.isSearching  = false;
                this.hasSearched  = true;
                this.hasError     = true;
                this.errorMessage = (error.body && error.body.message)
                    || 'Search failed. Please try again.';
            }.bind(this));
    }

    // ── Row selection ─────────────────────────────────────────────────────────
    handleRowSelect(event) {
        var selectedId = event.currentTarget.dataset.id;
        this.selectedCisId  = selectedId;
        this.selectedResult = this.searchResults.find(function(r) {
            return r.cisId === selectedId;
        }) || null;
        this.searchResults = this.searchResults.map(function(r) {
            return Object.assign({}, r, {
                isSelected: r.cisId === selectedId,
                rowClass: r.cisId === selectedId ? 'selected-row' : ''
            });
        });
        this.showDiffAccountWarning = false;
        this.showNotFoundWarning    = false;
    }

    // ── Link Account ──────────────────────────────────────────────────────────
    handleLinkAccount() {
        if (!this.selectedCisId || !this.selectedResult) return;

        findAccountByName({ name: this.selectedResult.name })
            .then(function(result) {
                if (result && result.id) {
                    if (result.id === this.recordId) {
                        this.doUpdateCpid(this.recordId);
                    } else {
                        this._resolveTargetId = result.id;
                        this.showDiffAccountWarning = true;
                    }
                } else {
                    this.showNotFoundWarning = true;
                }
            }.bind(this))
            .catch(function(error) {
                var msg = (error.body && error.body.message) || 'Error looking up account.';
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Error', message: msg, variant: 'error'
                }));
            }.bind(this));
    }

    handleWarningConfirm() {
        this.showDiffAccountWarning = false;
        this.doUpdateCpid(this._resolveTargetId);
    }

    handleCreateAccountFromCis() {
        // Account not found in SF — resolve the CIS CPID to the currently opened account
        this.showNotFoundWarning = false;
        this.selectedCisId = this.selectedResult.cisId;
        this.doUpdateCpid(this.recordId);
    }

    handleWarningCancel() {
        this.showDiffAccountWarning = false;
        this.showNotFoundWarning    = false;
        this._resolveTargetId       = null;
    }

    doUpdateCpid(accountId) {
        updateCpid({ accountId: accountId, cisId: this.selectedCisId })
            .then(function() {
                this.dispatchEvent(new ShowToastEvent({
                    title:   'CPID Resolved',
                    message: 'CIS Customer ID ' + this.selectedCisId + ' has been linked successfully.',
                    variant: 'success'
                }));
                // Notify the record page to refresh so CPID and Sync Status update immediately
                getRecordNotifyChange([{ recordId: accountId }]);
                this.dispatchEvent(new CloseActionScreenEvent());
            }.bind(this))
            .catch(function(error) {
                var msg = (error.body && error.body.message) || 'Failed to update CPID.';
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Error', message: msg, variant: 'error'
                }));
            }.bind(this));
    }

    // ── Show Create Form ──────────────────────────────────────────────────────
    handleShowCreateForm() {
        // Pre-fill create form with whatever was in the search fields
        this.newFirstName = this.firstName;
        this.newLastName  = this.lastName;
        this.newSsn       = this.ssn;
        this.newTin       = this.tin;
        this.newStreet    = this.street;
        this.newCity      = this.city;
        this.newState     = this.state;
        this.newZip       = this.zip;
        this.newCountry   = this.country;
        this.hasCreateError = false;
        this.createErrorMessage = '';
        // Keep whatever RT is currently selected (already defaulted in connectedCallback)
        this.showCreateForm = true;
    }

    handleBackToSearch() {
        this.showCreateForm    = false;
        this.hasCreateError    = false;
        this.showCisCreatedMsg = false;
        this._cisCreatedId     = null;
    }

    // ── Submit New Account ────────────────────────────────────────────────────
    // Step 1: Create CIS profile → get CPID
    // Step 2: Create SF Account with that CPID already set
    handleSubmitNewAccount() {
        if (!this.newFirstName || !this.newLastName) {
            this.hasCreateError = true;
            this.createErrorMessage = 'First Name and Last Name are required.';
            return;
        }

        this.isCreating       = true;
        this.hasCreateError   = false;
        this.createErrorMessage = '';
        this.createStatusMsg  = 'Creating CIS profile...';

        createCisProfile({
            firstName: this.newFirstName,
            lastName:  this.newLastName,
            ssn:       this.newSsn,
            tin:       this.newTin,
            street:    this.newStreet,
            city:      this.newCity,
            state:     this.newState,
            zip:       this.newZip,
            country:   this.newCountry
        })
            .then(function(cisResult) {
                if (!cisResult || !cisResult.success) {
                    this.isCreating = false;
                    this.hasCreateError = true;
                    this.createErrorMessage = (cisResult && cisResult.errorMessage)
                        || 'CIS profile creation failed.';
                    return;
                }

                // CIS profile created. Keep create form visible to show success panel.
                // Do NOT create SF account. Do NOT hide the form yet.
                this.isCreating       = false;
                this._cisCreatedId    = cisResult.cisId;
                this.showCisCreatedMsg = true;
                // showCreateForm stays true so the success panel renders inside the form view
            }.bind(this))
            .catch(function(error) {
                this.isCreating = false;
                var msg = (error.body && error.body.message) || 'Account creation failed.';
                this.hasCreateError = true;
                this.createErrorMessage = msg;
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Error', message: msg, variant: 'error'
                }));
            }.bind(this));
    }

    // ── Link newly created CIS profile to current account ───────────────────
    handleLinkCisToCurrentAccount() {
        this.selectedCisId = this._cisCreatedId;
        this.doUpdateCpid(this.recordId);
    }

    handleDismissCisCreated() {
        this.showCisCreatedMsg = false;
        this._cisCreatedId = null;
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    // ── Cancel ────────────────────────────────────────────────────────────────
    disconnectedCallback() {
        // Notify cisStatusBanner to resume toast polling
        window.dispatchEvent(new CustomEvent('resolvecpid_modal_close'));
    }

    handleCancel() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}
