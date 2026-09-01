import { LightningElement, api, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import USER_ID from '@salesforce/user/Id';
import { getRecord } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';
import USER_NAME_FIELD from '@salesforce/schema/User.Name';
import USER_TRUIST_ID_FIELD from '@salesforce/schema/User.truist__Truist_User_ID__c';

import getCaseInfo from '@salesforce/apex/PromoEnrollmentActionController.getCaseInfo';
import getEnrollmentActivitiesByCase from '@salesforce/apex/PromoEnrollmentActionController.getEnrollmentActivitiesByCase';
import getofferRewardsStructure from '@salesforce/apex/PromoEnrollmentActionController.getofferRewardsStructure';
import getPromotionEnrollmentsByCase from '@salesforce/apex/PromoEnrollmentActionController.getPromotionEnrollmentsByCase2';
import basicEARUpdates from '@salesforce/apex/PromoEnrollmentActionController.basicEARUpdates';


import runingUserProfileAndPermissionSets from '@salesforce/apex/PromoEnrollmentActionController.runingUserProfileAndPermissionSets';
import sendPromoActionFromLwc from '@salesforce/apex/PromoEnrollmentActionController.sendPromoActionFromLwc';
import markZafinSuccess from '@salesforce/apex/PromoEnrollmentActionController.markZafinSuccess';

const SAVE_REWARD_CODE_TO_FIELD = 'Req_Reward_Code__c';
const BASE_LEFT_WITH_TXN = [{ api: 'Transaction_Type__c', label: 'Transaction Type', disabled: true }];

const ENROLL_LEFT = [
    { api: 'Transaction_Type__c', label: 'Transaction Type', disabled: true },
];
const PAY_LEFT = [...BASE_LEFT_WITH_TXN];
const REVERSE_LEFT = [...BASE_LEFT_WITH_TXN, { api: 'stopReq_Comments__c', label: '', disabled: false }];

const ENROLL_RIGHT = [{ api: 'Req_stopReason_Code__c', label: '', disabled: false }];


const PAY_RIGHT = [
    { api: 'Req_Effective_Date__c', label: 'Effective date', disabled: true }
];

const REVERSE_RIGHT = [
    {
        api: 'stopReq_Reward_Code__c', label: '', disabled: true

    }
];


export default class PromoEnrollmentAction extends LightningElement {
    @api recordId;
    selectedComment = null;
    today = new Date().toISOString().slice(0, 10);
    showForm = false;
    activeAction = null;
    isBusy = false;
    renderUi = false;
    activitiesLoaded = false;
    noActivitiesMessage = false;
    nameDisplay;
    caseNumber;
    accountNumber;
    servicesChallengingCategory;
    initiativeTracking;
    reliefProvided;
    reliefType;
    remediation;
    ownerName;
    ownerDisplay;
    promoCode;
    zafinStatusDisplay = '';
    zafinTs = null;
    transactionTypeValue = null;
    editingRecordId = null;
    promoNeedsDefault = false;
    promoApplied = false;
    promoCodeResolved = null;
    promoInputValue = '';
    promoNeedsSync = false;
    promoDefaultPending = false;
    @track casePromoCode = null; // holds Case.Cat_Level_5__c
    enrollmentActivities = [];
    enrollmentError;
    wiredEnrollmentResult;
    enrollmentRecordSet = [];
    workingRecord;
    @track selectedComments;
    offerOptions = [];
    @track selectedOfferCode = null;
    pendingOfferCode = null;
    offerRewards = [];
    wiredOfferRewardsResult;
    rewardOptions = [];
    @track selectedRewardCode = null;
    rewardHelp;
    rewardPlaceholder = 'Select a reward';

    pendingRewardCode = null;

    canSave = false;
    canSubmit = false;
    canForceEnroll = false;
    canForcePay = false;
    canRewardReversal = false;
    @track promoCodeValue = '';
    selectedEnrollmentId = null;     // Promotion_Enrollment__c.Id (reward key)
    selectedOfferCodeToSave = null; // Offer_Code__c (what we save)

    offerRenderKey = 0;
    offerError;
    isEditMode = false;
    @track selectedReasonCode = null;

    isSaved = false;
    isDirty = false;

    formRenderKey = 0;
    offerRenderKey = 0;
    selectedActivity;
    usercode;
    ReqAccountDisplay;
    fieldAccess;
    effectiveDate;


    enrollmentActivityColumns = [
        { label: 'Record', fieldName: 'Name', type: 'button', typeAttributes: { label: { fieldName: 'Name' }, name: 'editActivity', variant: 'base' } },
        { label: 'Transaction Type', fieldName: 'Transaction_Type__c', type: 'text' },
        { label: 'Send Status', fieldName: 'Zafin_Request__c', type: 'text' },
        { label: 'Send Timestamp', fieldName: 'Zafin_Request_DateTime__c', type: 'date', typeAttributes: { year: 'numeric', month: '2-digit', day: '2-digit', hour: '2-digit', minute: '2-digit' } },
        { label: 'User', fieldName: 'Req_Initiator_2__c', type: 'text' },
        { label: 'Offer Code', fieldName: 'Req_Offer_Code__c', type: 'text' },
        { label: 'Reward Code', fieldName: 'Req_Reward_Code__c', type: 'text' },
        { label: 'Account #', fieldName: 'ReqAccountDisplay', type: 'text' },
        { label: 'Reason Code', fieldName: 'Req_Reason_Code__c', type: 'text' }
    ];

    connectedCallback() {
        this.fetchActivities();
    }



    @wire(getRecord, {
        recordId: USER_ID,
        fields: [USER_NAME_FIELD, USER_TRUIST_ID_FIELD]
    })
    wiredUser({ data, error }) {
        if (data) {
            const name = data.fields.Name?.value || '';
            const truistId = data.fields.truist__Truist_User_ID__c?.value || '';

            this.usercode = truistId;
            this.ownerDisplay = truistId
                ? `${name} (${truistId})`
                : name;

            console.log('ownerDisplay:', this.ownerDisplay);
        } else if (error) {
            console.error('Failed to load user record', error);
            this.ownerDisplay = '';
        }
    }

    @wire(runingUserProfileAndPermissionSets, {})
    wiredRuningUserProfileAndPermissionSets({ data, error }) {
        console.log('todays date ', this.today);
        if (data) {
            console.log('User permissions resolved:', data);
            this.canSave = data.saveButton;
            this.canSubmit = data.submitButton;
            this.canForceEnroll = data.forceEnrollButton;
            this.canForcePay = data.forcePayButton;
            this.canRewardReversal = data.rewardReversalButton;
            this.fieldAccess = data.fieldAccess;

        } else if (error) {
            console.error('Permission load failed', error);
            this.canSave = false;
            this.canSubmit = false;
            this.canForceEnroll = false;
            this.canForcePay = false;
            this.canRewardReversal = false;
            this.fieldAccess = false;
        }
    }


    @wire(getPromotionEnrollmentsByCase, { caseId: '$recordId' })
    wiredPromotionEnrollments({ data, error }) {
        if (error) {
            console.error('getPromotionEnrollmentsByCase error', error);
            return;
        }

        if (!data) {
            return;
        }

        this.offerMap = {};
        this.offerOptions = data.map(rec => {
            this.offerMap[rec.Offer_Code__c] = {
                enrollmentId: rec.Id
            };
            return {
                label: rec.Offer_Code__c,
                value: rec.Offer_Code__c
            };
        });

        // safe to call every time
        this._applyPendingOffer();
    }


    fetchActivities() {
        this.activitiesLoaded = false;
        console.log('RecordID', this.recordId);
        getEnrollmentActivitiesByCase({ caseId: this.recordId })
            .then((data) => {
                if (data) {
                    console.log('show enrollment data ', data);
                    this.enrollmentActivities = data.map(row => {
                        const user = row?.Req_Initiator__r?.Name || '';
                        const code = row?.Req_Initiator__r?.truist__Truist_User_ID__c || '';
                        return {
                            ...row,
                            Initiator_Display__c: code ? `${user} (${code})` : user,
                            ReqAccountDisplay: this.removeLeadingZeros(row.Req_Account__c)
                        };
                    });


                    this.noActivitiesMessage = this.enrollmentActivities.length === 0;
                    this.enrollmentError = null;
                    this.enrollmentRecordSet = [...data];
                    console.log('enrollmentRecordSet ', this.enrollmentRecordSet);
                    if (this.editingRecordId) {
                        this.enrollmentActivities.find(row => row.Id === this.editingRecordId);
                        this.selectedActivity?.Req_Offer_Code__c || null;
                        this.selectedActivity?.Req_Reward_Code__c || null;


                    }
                }
            })
            .catch((error) => {
                this.enrollmentActivities = [];
                this.enrollmentError = error;
                this.noActivitiesMessage = true;
                console.log('Errormessage', error);
            })
            .finally(() => {
                this.activitiesLoaded = true;
                this.renderUi = true;
            });
    }
    //     @wire(getEnrollmentActivitiesByCase, })
    //         wiredActivities(result) {this.wiredEnrollmentResult = result;
    //         const { data, error } = result;
    //                     console.log('fire enrollment data' );

    //         if (data) {
    //             console.log('show enrollment data ' , data);
    //             this.enrollmentActivities = data.map(row => {
    //                 const user = row?.Req_Initiator__r?.Name || '';
    //                 const code = row?.Req_Initiator__r?.truist__Truist_User_ID__c || '';
    //                 return { ...row, Initiator_Display__c: code ? `${user} (${code})` : user };
    //             });
    //             this.noActivitiesMessage = data.length === 0;
    //             this.enrollmentError = null;

    // //fix loading of activities 

    //     this.enrollmentRecordSet = [...data];
    //     console.log('this.enrollmentRecordSet ' , this.enrollmentRecordSet);
    //  console.log('show id of editing record ' , this.editingRecordId);
    //             this.enrollmentActivities.find(row => row.Id === this.editingRecordId);
    //             this.selectedActivity?.Req_Offer_Code__c || null;
    //             this.selectedActivity?.Req_Reward_Code__c || null;

    //             console.log('enrollmentActivities ' , this.enrollmentActivities);
    //             console.log('selectedActivity ' , this.selectedActivity?.Req_Offer_Code__c);
    //            // console.log('show enrollment data ' , data);

    // if (this.selectedOfferCode) {
    //     // do something with offer code
    // }

    //         } else {
    //             this.enrollmentActivities = [];
    //             this.enrollmentError = error;
    //             this.noActivitiesMessage = true;
    //         }
    //         this.activitiesLoaded = true;
    //         this.renderUi = true;
    //     }

    get hasActivities() {
        return this.activitiesLoaded && this.enrollmentActivities.length > 0;
    }

    get hasZafinTs() {
        return !!this.zafinTs && this.zafinTs !== 'Unprocessed';
    }

    get errorMessage() {
        return this.enrollmentError ? this.enrollmentError.body?.message : '';
    }

    get offerErrorMessage() {
        return this.offerError ? this.offerError.body?.message : '';
    }

    get recordCountLabel() {
        return this.hasActivities ? `${this.enrollmentActivities.length} record(s)` : '';
    }

    get enrollVariant() {
        return this.activeAction === 'ENROLL' ? 'brand' : 'neutral';
    }

    get payVariant() {
        return this.activeAction === 'PAY' ? 'brand' : 'neutral';
    }

    get reverseVariant() {
        return this.activeAction === 'REVERSE' ? 'destructive' : 'neutral';
    }

    get disableEnrollButton() {
        return (
            this.isBusy ||
            this.editingRecordId ||
            !this.canForceEnroll
        );
    }

    get disablePayButton() {

        return (
            this.isBusy ||
            this.editingRecordId ||
            !this.canForcePay
        );
    }

    get disableReverseButton() {

        return (
            this.isBusy ||
            this.editingRecordId ||
            !this.canRewardReversal
        );
    }

    get showPromoInput() {
        return this.activeAction === 'ENROLL';
    }


    get isSubmitDisabled() {
        console.log('is Suvbmit ',)
        if (this.isPromoLocked) return true;
        if (!this.canSubmit) return true;
        if (this.isSaveDisabled) return true;
        if (!this.isSaved) return true;
        if (this.isDirty) return true;
        if (!this.areRequiredFieldsFilled) { return true; }
        return false;

    }

    get isSaveDisabled() {


        console.log('areRequiredFieldsFilled ', this.areRequiredFieldsFilled);
        console.log('canSave ', this.canSave);
        console.log('isPromoLocked ', this.isPromoLocked);



        if (this.isPromoLocked) {
            return true;
        }

        if (!this.canSave) {
            return true;
        }

        // transaction-based required fields
        // if(this.isEditMode == true){
        if (!this.areRequiredFieldsFilled) {
            return true;
        }
        //}
        return false;
    }


    get areRequiredFieldsFilled() {
        const required = this.requiredFieldsByAction[this.activeAction] || [];
        console.log('this.selectedOfferCode ', this.selectedOfferCode);
        console.log('this.selectedRewardCode ', this.selectedRewardCode);
        console.log('this.selectedReasonCode ', this.selectedReasonCode);

        return required.every(api => {
            console.log('api ', api);

            if (api === 'Req_Offer_Code__c') {
                return !!this.selectedOfferCode;
            }

            if (api === 'Req_Reward_Code__c') {
                return !!this.selectedRewardCode;
            }
            if (api === 'Req_Reason_Code__c') {
                return !!this.selectedReasonCode;
            }

            if (api === 'Req_Promo_Code__c') {
                return !!this.promoCodeValue;
            }

            return true;
            // const el = this.template.querySelector(
            //   `lightning-input-field[data-field="${api}"]`
            // );
            //return el && el.value !== null && el.value !== '';
        });
    }



    get requiredFieldsByAction() {
        return {
            ENROLL: [
                'Req_Promo_Code__c',
                'Req_Reason_Code__c'
            ],
            PAY: [
                'Req_Reason_Code__c',
                'Req_Offer_Code__c',
                'Req_Reward_Code__c'
            ],
            REVERSE: [
                'Req_Reason_Code__c',
                'Req_Offer_Code__c',
                'Req_Reward_Code__c'
            ]
        };
    }


    get isKeyFieldsDisabled() {
        if (this.isPromoLocked) return true;
        if (this.isBusy) return true;
        if (!this.fieldAccess) return true;
        return false;
    }



    handlePromoCodeChange(event) {
        this.isDirty = true;
        this.promoCodeValue = event.target.value;
    }

    get showPromoCode() {
        return this.activeAction === 'ENROLL';
    }

    handleRefreshActivities() {
        // refreshApex(this.wiredEnrollmentResult);
        this.fetchActivities();
    }

    get highlightEnroll() {
        return this.editingRecordId && this.activeAction === 'ENROLL' ? 'highlighted' : '';
    }

    get highlightPay() {
        return this.editingRecordId && this.activeAction === 'PAY' ? 'highlighted' : '';
    }

    get highlightReverse() {
        return this.editingRecordId && this.activeAction === 'REVERSE' ? 'highlighted' : '';
    }

    get leftDynamicFields() {
        switch (this.activeAction) {
            case 'ENROLL': return ENROLL_LEFT;
            case 'PAY': return PAY_LEFT;
            case 'REVERSE': return REVERSE_LEFT;
            default: return [];
        }
    }


    get rightDynamicFieldsForRender() {
        let base;

        console.log('RENDER CHECK activeAction =', this.activeAction);

        switch (this.activeAction) {
            case 'ENROLL':
                base = ENROLL_RIGHT;
                break;
            case 'PAY':
                base = PAY_RIGHT;
                break;
            case 'REVERSE':
                base = REVERSE_RIGHT;
                break;
            default:
                return [];
        }

        const pick = this.activeAction === 'PAY' || this.activeAction === 'REVERSE';

        return base.map(f => {
            const isOffer = pick && f.api === 'Req_Offer_Code__c';
            const isReward = pick && f.api === 'Req_Reward_Code__c';

            return {
                ...f,
                label: '',
                isOfferAndPicklist: isOffer,
                isRewardAndPicklist: isReward,
                renderNative: !(isOffer || isReward),
                useLightningLabel: isOffer || isReward
            };
        });
    }

    /*
        
    openActivityForEdit(row) {
        // ---- basic form state ----
        this.showForm = true;
        this.isEditMode = true;
        this.editingRecordId = row.Id;
    
        this.zafinStatusDisplay = row.Zafin_Request__c || 'Not Sent';
        this.zafinTs = row.Zafin_Request_DateTime__c || 'Unprocessed';
    
        // ---- resolve action ----
        const txnType = (row.Transaction_Type__c || '').trim();
        if (txnType === 'Force Enroll') {
            this.activeAction = 'ENROLL';
        } else if (txnType === 'Force Pay') {
            this.activeAction = 'PAY';
        } else if (txnType === 'Reward Reversal') {
            this.activeAction = 'REVERSE';
        } else {
            this.activeAction = null;
        }
        this.transactionTypeValue = txnType;
    
        // ---- promo code ----
        this.promoCodeValue = row.Req_Promo_Code__c || '';
        this.promoInputValue = this.promoCodeValue;
    
        // ---- capture record values (PENDING state) ----
        this.pendingOfferCode = row.Req_Offer_Code__c || null;
        this.pendingRewardCode = row.Req_Reward_Code__c || null;
    
        // ---- clear UI selections ----
        this.selectedOfferCode = null;
        this.selectedEnrollmentId = null;
        this.selectedRewardCode = null;
        this.rewardOptions = [];
        this.rewardHelp = null;
    
        // ---- attempt apply (safe even if options not loaded yet) ----
        this._applyPendingOffer();
    }
    
    */



    _applyPendingOffer() {
        // guards
        if (!this.pendingOfferCode || !this.offerMap) {
            return;
        }

        const entry = this.offerMap[this.pendingOfferCode];
        if (!entry || !entry.enrollmentId) {
            return;
        }

        // apply offer → enrollment
        this.selectedOfferCode = this.pendingOfferCode;
        this.selectedEnrollmentId = entry.enrollmentId;

        // clear pending so it runs once
        this.pendingOfferCode = null;

        // load rewards only after enrollment id exists
        this.loadRewardsImperatively();
    }

    _syncRewards() {
        if (
            Array.isArray(this.offerRewards) &&
            this.offerRewards.length > 0 &&
            this.selectedOfferCode
        ) {
            console.log('✅ SYNC: rebuilding rewards for', this.selectedOfferCode);
            this._rebuildRewardOptions();
        }
    }




    async openActivityForEdit(row) {
        // this.isSaved = false;
        // this.isDirty = false;
        await this.fetchHeaderData();
        console.log('fire off open activity');
        console.log('process ', row);
        console.log('isSaved', this.isSaved);
        console.log('isSaveDisabled ', this.isSaveDisabled);

        console.log('isDirty ', this.isDirty);
        console.log('fire off open activity');

        this.showForm = true;
        this.isEditMode = true;
        this.editingRecordId = row.Id;

        this.zafinStatusDisplay = row.Zafin_Request__c || 'Not Sent';
        this.zafinTs = row.Zafin_Request_DateTime__c ? new Date(row.Zafin_Request_DateTime__c).toLocaleString("en-US", { timeZone: "America/New_york" }) : 'Unprocessed';

        const txnType = (row.Transaction_Type__c || '').trim();

        switch (txnType) {
            case 'Force Enroll':
                this.activeAction = 'ENROLL';
                break;
            case 'Force Pay':
                this.activeAction = 'PAY';
                break;
            case 'Reward Reversal':
                this.activeAction = 'REVERSE';
                break;
            default:
                this.activeAction = null;
                console.warn('Unknown Transaction_Type__c:', txnType);
        }

        this.transactionTypeValue = txnType;
        this.promoCodeValue = row.Req_Promo_Code__c || '';
        this.pendingOfferCode = row.Req_Offer_Code__c || null;
        this.pendingRewardCode = row.Req_Reward_Code__c || null;
        this.selectedOfferCode = null;
        this.selectedEnrollmentId = null;
        this.selectedRewardCode = null;
        this.rewardOptions = [];
        this.rewardHelp = null;
        this.selectedOfferCode = row.Req_Offer_Code__c || null;
        this.selectedRewardCode = row.Req_Reward_Code__c || null;
        this.pendingOfferCode = row.Req_Offer_Code__c || null;
        this.pendingRewardCode = row.Req_Reward_Code__c || null;

        console.log('show record id ', this.editingRecordId);
        this.workingRecord = this.enrollmentRecordSet.find(
            rec => rec.Id === this.editingRecordId
        ) || null;
        this.selectedOfferCode = this.workingRecord.Req_Offer_Code__c;
        this.selectedRewardCode = this.workingRecord.Req_Reward_Code__c;
        this.selectedReasonCode = this.workingRecord.Req_Reason_Code__c;

        this.zafinMessage = this.workingRecord.Resp_Message__c;
        this.zafinError = this.workingRecord.Resp_Error__c;
        this.enrommentRecordName = this.workingRecord.Name;
        console.log('show workingRecord record  ', this.workingRecord);
        console.log('show selectedOfferCode', this.selectedOfferCode);
        console.log('show selectedRewardCode', this.selectedRewardCode);
        if (this.workingRecord?.Zafin_Request__c == 'Sent') {
            console.log('this.workingRecord?.Zafin_Request__c---->'+this.workingRecord?.Zafin_Request__c);
             this.effectiveDate = this.workingRecord?.Req_Effective_Date__c;
        } else {
            this.effectiveDate = this.today;
        }

        this._applyPendingOffer();
    }
    @track enrommentRecordName
    @track zafinMessage = null;
    @track zafinError = null;
    handleForceEnroll() {
        console.log('fire off Force Enroll!!!!!');

        this.isEditMode = true;
        console.log('start new Enroll');
        this._startNew('ENROLL');
    }

    handleForcePay() {
        console.log('fire off force pay!!!!!');
        this.effectiveDate = this.today;
        this.isEditMode = true;
        this._startNew('PAY');
    }

    handleRewardReversal() {
        console.log('fire off RewardReversal!!!!!');

        this.isEditMode = true;

        this._startNew('REVERSE');
    }


    removeLeadingZeros(value) {
        if (!value) {
            return value;
        }
        return value.replace(/^0+/, '') || '0';
    }

    async fetchHeaderData() {
        if (!this.accountNumber || !this.caseNumber) {
            try {
                const data = await getCaseInfo({ caseId: this.recordId });
                // console.log('show case Remediation', data.Remediation);
                this.caseNumber = data.caseNumber;
                this.accountNumber = this.removeLeadingZeros(data.accountNumber);
                this.servicesChallengingCategory = data.servicesChallengingCategory;
                this.initiativeTracking = data.initiativeTracking;
                this.reliefProvided = data.reliefProvided;
                this.reliefType = data.reliefType;
                this.remediation = data.remediation;
                this.casePromoCode = data.promoCode;
                this.nameDisplay = `Enrollment Activity Case ${data.caseNumber}`;

            } catch (error) {
                console.error('Header Load error:', error);
            }
        }
    }

    async _startNew(action) {
        console.log('Strat new fired!!')
        // ------------------------------------------------------------
        // BASIC FORM STATE
        // ------------------------------------------------------------
        this.showForm = true;
        this.activeAction = action;

        this.isSaved = false;
        this.isDirty = false;

        // ------------------------------------------------------------
        // NEW RECORD CONTEXT
        // ------------------------------------------------------------
        this.isEditMode = false;
        this.editingRecordId = null;

        // ------------------------------------------------------------
        // RESET FIELD STATE
        // ------------------------------------------------------------
        this.selectedOfferCode = null;
        this.selectedEnrollmentId = null;
        this.selectedRewardCode = null;

        this.rewardOptions = [];
        this.rewardHelp = null;

        this.pendingOfferCode = null;
        this.pendingRewardCode = null;

        this.zafinStatusDisplay = null;
        this.zafinTs = null;
        this.enrommentRecordName = null;
        this.selectedReasonCode = null;
        this.zafinError = null;
        this.zafinMessage = null;

        // ------------------------------------------------------------
        // PROMO CODE (MANUAL FIELD – CLEAN)
        // ------------------------------------------------------------
        // Reset first
        this.promoCodeValue = '';
        await this.fetchHeaderData();


        // ------------------------------------------------------------
        // TRANSACTION TYPE LABEL
        // ------------------------------------------------------------
        this.transactionTypeValue =
            action === 'ENROLL' ? 'Force Enroll'
                : action === 'PAY' ? 'Force Pay'
                    : 'Reward Reversal';


        ///////
        //LOAD ENROLMENT RECORDS
        ///////////
        // ------------------------------------------------------------
        // LOAD CASE DATA (HEADER ONLY — PROMO ALREADY SET ABOVE)
        // ------------------------------------------------------------
        try {
            console.log('loading case');
            const data = await getCaseInfo({ caseId: this.recordId });
            console.log('show case data ', data);

            console.log('show case data promo code', data.promoCode);
            console.log('show case accountNumber', data.accountNumber);
            // console.log('show case Remediation', data.Remediation);

            this.caseNumber = data.caseNumber;
            this.accountNumber = this.removeLeadingZeros(data.accountNumber);
            this.servicesChallengingCategory = data.servicesChallengingCategory;
                this.initiativeTracking = data.initiativeTracking;
                this.reliefProvided = data.reliefProvided;
                this.reliefType = data.reliefType;
                this.remediation = data.remediation;
            this.nameDisplay = `Enrollment Activity - Case ${data.caseNumber}`;

            // Save case promo for future ENROLL actions
            this.casePromoCode = data.promoCode;
            console.log('Case this.data.catLevel5:', data.catLevel5);

            console.log('Case casePromoCode:', this.casePromoCode);

        } catch (error) {
            console.error('Failed to load case data', error);
            this._toast('Failed to load case data', 'error');
        }

        console.log('show action ', action);
        console.log('show casePromoCode ', this.casePromoCode);
        // Force Enroll only → default from Case
        if (action === 'ENROLL' && this.casePromoCode) {
            this.promoCodeValue = this.casePromoCode;
        }
        console.log('STATE AFTER _startNew:', {
            action: this.activeAction,
            promoCodeValue: this.promoCodeValue,
            isEditMode: this.isEditMode,
            editingRecordId: this.editingRecordId
        });


    }


    handleError(event) {
        console.log('error found? ');
    }


    async submitForm(event) {
        event.preventDefault();
        try {
            form.submit();
        } catch (error) {
            console.error(
                ' basicEARUpdates error:',
                error?.body?.message || error
            );
        }
    }


    handleActivityRowAction(event) {

        try {
            const action = event.detail.action;
            const row = event.detail.row;

            console.log('Action:', action);
            console.log('Row:', row);

            if (action?.name === 'editActivity') {
                this.openActivityForEdit(row);
            }
        } catch (e) {
            console.error('❌ handleRowAction failed', e);
            throw e; // force Salesforce to show it
        }
    }

    handleLoad(event) {
        // 🔹 Set system fields for new Force Enroll records
        if (!this.editingRecordId && this.transactionTypeValue) {
            this._setFieldValue('Transaction_Type__c', this.transactionTypeValue);
            this._setFieldValue('Case_Number__c', this.recordId);
        }

        if (!this.editingRecordId) {
            this._setFieldValue('Req_Initiator__c', USER_ID);
            this._setFieldValue('Req_Initiator2__c', USER_ID);
        }

    }





    handleOfferChange(event) {
        console.log('fire off offerChange');
        const offerCode = event.detail.value;
        console.log('foffer code', offerCode);

        this.isDirty = true;

        this.selectedOfferCode = offerCode;

        const entry = this.offerMap?.[offerCode];
        console.log('entry', entry);

        this.selectedEnrollmentId = entry ? entry.enrollmentId : null;
        console.log('selectedEnrollmentId', this.selectedEnrollmentId);

        this.rewardOptions = [];

        if (this.selectedEnrollmentId) {
            this.loadRewardsImperatively();
        }
        console.log('loadRewardsImperatively passed');


        if (this.activeAction !== 'ENROLL') {
            return;
        }

        /* const currentValue = promoField.value;
         console.log('show promo currentValue' ,currentValue);
         if (currentValue) {
             return;
         }
         console.log('case value ' , this.casePromoCode)
         if (this.casePromoCode) {
             promoField.value = this.casePromoCode;
         } /*/
        console.log('Offer Code:', this.selectedOfferCode);
        console.log('Enrollment Id:', this.selectedEnrollmentId);
    }


    handleRewardChange(event) {
        this.isDirty = true;
        this.selectedRewardCode = event.detail.value;
        this._setFieldValue('Req_Reward_Code__c', this.selectedRewardCode);
    }


    async handleSubmit(event) {
        console.log('Save button Clicked');
        event.preventDefault();
        const fields = event.detail.fields;
        try {
            const result = await basicEARUpdates({
                enrollmentActionRecordId: this.editingRecordId,
                caseId: this.recordId,
                offerCode: this.selectedOfferCode,
                casePromo: this.promoCodeValue,
                selectedReasonCode: fields.Req_Reason_Code__c,
                selectedRewardCode: this.selectedRewardCode,
                TransactionType: this.transactionTypeValue, //fields.Transaction_Type__c,
                Comments: fields.Req_Comments__c,
                employeId: this.usercode

            });

            this.isSaved = true;
            this.isDirty = false;

            this.editingRecordId = result;
            this._toast(`Enrollment Record Saved Successfully!`, 'success');
            this.fetchActivities();
            console.log(' show editingRecordIdafter update ', this.editingRecordId);
            console.log('show save result ', result)
            //some how populate this.editingRecordId

        } catch (error) {
            console.error(
                'basicEARUpdates error:',
                error?.body?.message || error
            );
        }
    }




    handleError(event) {
        this.isBusy = false;

        console.error('Save error FULL OBJECT:', JSON.stringify(event.detail, null, 2));

        // Common useful locations
        if (event.detail?.output) {
            console.error('OUTPUT ERRORS:', JSON.stringify(event.detail.output, null, 2));
        }

        if (event.detail?.detail) {
            console.error('DETAIL MESSAGE:', event.detail.detail);
        }
    }


    async handleExternalSubmit() {
        console.log(' fire external submit');
        if (!this.editingRecordId) {
            this._toast('No Enrollment Activity selected.', 'error');
            return;
        }
        this.isBusy = true;
        try {
            console.log(' fire external submit save method');
            console.log(' finish save');
            console.log('starat zafin call out');

            const response = await sendPromoActionFromLwc({
                enrollmentActivityId: this.editingRecordId
            });

            console.log('############################checkResponse', response);
            console.log('Record id is editRecId : ', this.editingRecordId);
            console.log('Record id is enrollment: ', this.enrollmentActivityId);
            console.log('Show response', response);
            const statusCode = response?.zafinPackage.statusCode || 0;
            const isSuccess = statusCode >= 200 && statusCode < 300;
            console.log(' fire external submit status code ', statusCode);
            this._toast(
                isSuccess
                    ? 'Zafin request sent successfully.'
                    : `Zafin error (${statusCode})`,
                isSuccess ? 'success' : 'error'
            );
            //await refreshApex(this.wiredEnrollmentResult);
            this.fetchActivities();
            this.zafinError = response.zafinError || '';
            this.zafinMessage = response.zafinMessage || '';
            this.zafinStatusDisplay = isSuccess ? 'Sent' : 'Error';
            this.zafinTs = isSuccess ? new Date().toLocaleString("en-US", { timeZone: "America/New_york" }) : 'Unprocessed';
            this.enrommentRecordName = response.recordName;
        } catch (err) {
            this._toast(
                err?.body?.message || 'Callout failed.',
                'error'
            );
            //await refreshApex(this.wiredEnrollmentResult);
            this.fetchActivities();

        }

        this.isBusy = false;
    }

    /*
        handleSuccess(event) {
            this.isBusy = false;
            refreshApex(this.wiredEnrollmentResult);
            refreshApex(this.wiredOfferRewardsResult);
            this._toast(`Record saved (${event.detail.id})`, 'success');
            //this.showForm = false;
            this.editingRecordId = null;
        }
      */





    get isPromoLocked() {
        return this.zafinStatusDisplay?.toLowerCase() === 'sent' || this.isBusy === true

    }

    handleError(event) {
        this.isBusy = false;
        this._toast(event.detail.message, 'error');
    }

    handleClose() {

        this.isEditMode = false;
        //this.activeAction = null;
        this.showForm = false;
        this.editingRecordId = null;
        this.isBusy = false;
    }

    _setFieldValue(api, value) {
        const el = this.template.querySelector(
            `lightning-input-field[data-field="${api}"]`
        );
        if (el) el.value = value;
    }

    _toast(message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Notice',
                message,
                variant
            })
        );
    }

    _resolveAndSetPromo({ casePromo, activityPromo, zafinStatus }) {
        let resolved = '';

        if (zafinStatus === 'Sent' && activityPromo) {
            resolved = activityPromo;
        } else if (activityPromo) {
            resolved = activityPromo;
        } else if (casePromo) {
            resolved = casePromo.split(' (')[0].trim();
        }

        this.promoInputValue = resolved;
    }


    _rebuildRewardOptions() {
        if (!this.selectedEnrollmentId || !Array.isArray(this.offerRewards)) {
            this.rewardOptions = [];
            return;
        }

        const wrapper = this.offerRewards.find(
            w => w.enrollmentRecord && w.enrollmentRecord.Id === this.selectedEnrollmentId
        );

        if (!wrapper || !Array.isArray(wrapper.rewardList)) {
            this.rewardOptions = [];
            this.rewardHelp = 'This enrollment has no associated rewards.';
            return;
        }

        this.rewardOptions = wrapper.rewardList.map(rw => ({
            label:
                (rw.reward.Reward_Name__c || '') +
                (rw.reward.Reward_Code__c ? ` (${rw.reward.Reward_Code__c})` : ''),
            value: rw.reward.Reward_Code__c
        }));
        console.log('show rewards options : ', this.rewardOptions);

        // apply saved reward ONCE
        if (this.pendingRewardCode) {
            const match = this.rewardOptions.find(
                r => r.value === this.pendingRewardCode
            );
            this.selectedRewardCode = match ? match.value : null;
            this.pendingRewardCode = null;
        }

        this.rewardHelp = null;
    }

    get enrollReversalOnly() {
        if (this.activeAction == 'ENROLL' || this.activeAction == 'REVERSE') {
            return true;
        }
        return false;
    }





    get payOnly() {
        console.log('fire pay only', this.activeAction);
        if (this.activeAction == 'PAY') {
            return true;
        }
        return false;
    }
    get payReversalOnly() {
        if (this.activeAction == 'PAY' || this.activeAction == 'REVERSE') {
            return true;
        }
        return false;
    }

    async loadRewardsImperatively() {
        if (!this.recordId || !this.selectedEnrollmentId) {
            return;
        }
        try {
            const data = await getofferRewardsStructure({
                caseId: this.recordId
            });

            this.offerRewards = Array.isArray(data) ? data : [];
            console.log('offerRewards', this.offerRewards);
            this._rebuildRewardOptions();
        } catch (error) {
            console.error('loadRewardsImperatively failed', error);
            this.offerRewards = [];
            this.rewardOptions = [];
            this.rewardHelp = 'Failed to load rewards.';
        }
    }












    _setFieldValue(apiName, value) {
        const el = this.template.querySelector(
            `lightning-input-field[data-field="${apiName}"]`
        );
        if (el) {
            el.value = value;
        }
    }


    handleReasonCodeChange(event) {
        this.selectedReasonCode = event.detail.value;
        console.log('Reason code change fired?');
        this.isDirty = true;
        this.isSaved = false;
    }


    handleCommentChange(event) {
        this.selectedComment = event.detail.value;
        console.log('Reason code change fired?');
        this.isDirty = true;
        this.isSaved = false;
    }

    handleCommentsChange(event) {
        this.selectedComments = event.detail.value;
        console.log('Comments change fired?');
        this.isDirty = true;
    }

    _applyPendingOffer() {
        // Guard: must have pending offer and offerMap ready
        if (!this.pendingOfferCode || !this.offerMap) {
            return;
        }

        const entry = this.offerMap[this.pendingOfferCode];
        if (!entry || !entry.enrollmentId) {
            return;
        }

        // Apply Offer
        this.selectedOfferCode = this.pendingOfferCode;
        this.selectedEnrollmentId = entry.enrollmentId;

        // Prevent re-run
        this.pendingOfferCode = null;

        // Load rewards only now
        this.loadRewardsImperatively();
    }





}