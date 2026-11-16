import { LightningElement, api, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { subscribe, unsubscribe } from 'lightning/empApi';
import getRewardTransactions from '@salesforce/apex/PromoXAccountTransactionsController.getRewardTransactions';

// DR-4350-9: Transaction Code replaces Transaction Channel; new Account Number column.
// Align labels/order with the approved Account Transactions Tab wireframe.
const COLUMNS = [
    { label: 'Transaction', fieldName: 'recordUrl', type: 'url', typeAttributes: { label: { fieldName: 'name' }, target: '_self' } },
    { label: 'Transaction Amount', fieldName: 'amount', type: 'number', typeAttributes: { minimumFractionDigits: 2, maximumFractionDigits: 2 } },
    { label: 'Transaction Date', fieldName: 'transactionDate', type: 'date', typeAttributes: { timeZone: 'UTC', year: 'numeric', month: '2-digit', day: '2-digit' } },
    { label: 'Debit/Credit Code', fieldName: 'debitCredit' },
    { label: 'Transaction Code', fieldName: 'transactionCode' },
    { label: 'Account Number', fieldName: 'accountNumber' }
];

export default class PromoAccountTransactions extends LightningElement {
    @api recordId;

    columns = COLUMNS;
    channelName = '/event/Enrollment_Activity_Refresh__e';
    subscription = null;
    wiredResult;

    rewardOptions = [];
    selectedRewardKey = '';
    _rowsByReward = new Map();

    connectedCallback() {
        subscribe(this.channelName, -1, message => {
            const payload = message?.data?.payload;
            if (payload?.CaseId__c === this.recordId) {
                refreshApex(this.wiredResult);
            }
        }).then(response => {
            this.subscription = response;
        });
    }

    disconnectedCallback() {
        if (this.subscription) {
            unsubscribe(this.subscription);
            this.subscription = null;
        }
    }

    @wire(getRewardTransactions, { caseId: '$recordId' })
    wiredTransactions(result) {
        this.wiredResult = result;
        const { data, error } = result;
        if (data) {
            const opts = [];
            const map = new Map();
            data.forEach(rt => {
                // DR-4350-8: label from Apex (Reward Name, else PRW record number); value = PRW Id
                opts.push({ label: rt.label, value: rt.rewardId });
                map.set(rt.rewardId, (rt.rows || []).map(row => {
                    const t = row.record || {};
                    return {
                        id: t.Id,
                        name: t.Name,
                        recordUrl: `/lightning/r/Promotion_Account_Transactions__c/${t.Id}/view`,
                        referenceId: t.Transaction_Reference_Id__c,
                        transactionDate: t.Transaction_Date__c,
                        amount: t.Transaction_Amount__c,
                        debitCredit: t.Transaction_Debit_Credit_Code__c,
                        transactionCode: t.Transaction_Code__c,
                        accountNumber: row.accountNumber
                    };
                }));
            });
            this.rewardOptions = opts;
            this._rowsByReward = map;

            // DR-4350-8: keep the selected reward if still available, else select the first returned reward
            if (!map.has(this.selectedRewardKey)) {
                this.selectedRewardKey = opts.length ? opts[0].value : '';
            }
        } else if (error) {
            console.error('APEX ERROR:', error);
        }
    }

    get hasOptions() {
        return this.rewardOptions.length > 0;
    }

    get rows() {
        return this._rowsByReward.get(this.selectedRewardKey) || [];
    }

    get hasRows() {
        return this.rows.length > 0;
    }

    handleRewardChange(event) {
        this.selectedRewardKey = event.detail.value;
    }
}