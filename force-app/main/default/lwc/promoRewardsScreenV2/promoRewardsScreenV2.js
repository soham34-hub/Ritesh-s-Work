import { LightningElement, api, track, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import CreateRewardStructure from '@salesforce/apex/PromoXRewardsController.CreateRewardStructure';
import { subscribe, unsubscribe } from 'lightning/empApi';

export default class PromoRewardsScreenV2 extends LightningElement {
    @api recordId;

    channelName = '/event/Enrollment_Activity_Refresh__e';
    subscription = null;
    wiredRewardResult;


    @track rewardOptions = [];
    @track selectedRewardKey = '';
    @track selectedReward = null;

    _rewardById = new Map();



     connectedCallback() {
        this.subscribeToEvent();
    }

    disconnectedCallback() {
        this.unsubscribeFromEvent();
    }


   
subscribeToEvent() {
    subscribe(this.channelName, -1, message => {
        const payload = message?.data?.payload;

        console.log('Platform Event received:', payload);

        // ✅ Only refresh if this Case is affected
        if (payload?.CaseId__c === this.recordId) {
            refreshApex(this.wiredRewardResult);
        }
    }).then(response => {
        this.subscription = response;
    });
}



    unsubscribeFromEvent() {
        if (this.subscription) {
            unsubscribe(this.subscription);
            this.subscription = null;
        }
    }


    get hasOptions() {
        return this.rewardOptions.length > 0;
    }

   
@wire(CreateRewardStructure, { caseId: '$recordId' })
wiredRewardData(result) {
    this.wiredRewardResult = result;
    const { data, error } = result;

    if (data) {
        console.log('REAL_APEX_DATA:', JSON.parse(JSON.stringify(data)));
        const cloned = JSON.parse(JSON.stringify(data.rewardList || []));
        this._buildFromRagList(cloned);

        if (this.selectedRewardKey && !this._rewardById.has(this.selectedRewardKey)) {
            this.selectedRewardKey = '';
            this.selectedReward = null;
        }

        if (!this.selectedRewardKey && this.rewardOptions.length > 0) {
            this.selectedRewardKey = this.rewardOptions[0].value;
            this.selectedReward = this._rewardById.get(this.selectedRewardKey);
        }
    } else if (error) {
        console.error('APEX ERROR:', error);
    }
}

    handleRewardChange(event) {
        const value = event.detail.value;
        this.selectedRewardKey = value;
        this.selectedReward = this._rewardById.get(value) || null;
    }

    _buildFromRagList(ragList) {
        const opts = [];
        const map = new Map();

        ragList.forEach(rawRag => {
            const r = rawRag?.reward;
            if (!r || !r.Id) return;

            opts.push({ label: r.Reward_Name__c || r.Name, value: r.Id });

            const normalized = this._normalizeReward(rawRag);
            map.set(r.Id, normalized);
        });

        this.rewardOptions = opts;
        this._rewardById = map;
    }

    _normalizeReward(rag) {
        const r = rag.reward;
        const id = r.Id;

        function ensureArray(v) {
            return Array.isArray(v) ? v : (v ? [v] : []);
        }

        const safeAccountGroups = ensureArray(rag.accountList).map(g => ({
            accountList: ensureArray(g.accountList),
            conditionList: ensureArray(g.conditionList)
        }));

        const groupings = [];

        safeAccountGroups.forEach((acctGrp, gIdx) => {
            const accounts = acctGrp.accountList.map((a, ai) => ({
                _key: `${id}-acc-${ai}`,
                id: a.Id,
                last4: a.Last_4__c,
                type: a.Account_Type__c
            }));

            const allRawAccounts = safeAccountGroups.flatMap(g => g.accountList);

            const conditions = acctGrp.conditionList.map((condWrap, ci) => {
                const cond = condWrap.condition;

                const condAccountId =
                    cond.Promotion_Account__c ||
                    cond.Promotion_account__c ||
                    null;

                const rawAcc = allRawAccounts.find(a => a.Id === condAccountId);
                const accountLast4 = rawAcc ? rawAcc.Last_4__c : null;

                const ruleSets = ensureArray(condWrap.ruleSetList).map((rsWrap, ri) => {
                    const rs = rsWrap.ruleSet;

                    const rules = ensureArray(rsWrap.rulesList).map((ruleWrap, rwi) => {
                        const rl = ruleWrap.rule;

                        const progressList = ensureArray(ruleWrap.progressList).map((pgWrap, pi) => {
                            const pg = pgWrap.progress;
                            const pass = !!pg.Rule_Pass_Flag__c;

                            return {
                                _key: `${id}-prog-${pi}`,
                                progressId: pg.Id,
                                progressRecordName: pg.Name,
                                actual: pg.Actual_Value__c,
                                details: pg.Rule_Details__c,
                                passFlag: pg.Rule_Pass_Flag__c,
                                passBadgeClass: `slds-badge ${pass ? 'slds-theme_success' : 'slds-theme_error'}`,
                                start: pg.Evaluation_Start_Date__c,
                                end: pg.Evaluation_End_Date__c,
                                passedDate: pg.Rule_Passed_Date__c
                            };
                        });

                        return {
                            _key: `${id}-rule-${rwi}`,

                            // ⭐ FINAL CORRECT VALUES ⭐
                            recordId: rl.Id,
                            recordName: rl.Name,  // PR00004

                            // additional rule info
                            code: rl.Rule_Code__c,
                            target: rl.Target_Value__c,
                            type: rl.Progress_Type__c,
                            name: rl.Rule_Name__c,
                            description: rl.Rule_Description__c,

                            progressList,
                            firstProgressId: progressList.length ? progressList[0].progressId : null,
                            firstProgressRecordName: progressList.length ? progressList[0].progressRecordName : null
                        };
                    });

                    return {
                        _key: `${id}-rs-${ri}`,
                        name: rs.Name,
                        ruleSetId: rs.Id,
                        code: rs.Rule_Set_Code__c,
                        rules
                    };
                });

                return {
                    _key: `${id}-cond-${ci}`,
                    id: cond.Id,
                    name: cond.Condition_Name__c,
                    recordName: cond.Name,
                    code: cond.Condition_Code__c,
                    description: cond.Condition_Description__c,
                    isMet: cond.Condition_Met__c,
                    metBadgeClass: `slds-badge ${cond.Condition_Met__c ? 'slds-theme_success' : 'slds-theme_error'}`,
                    accountLast4,
                    ruleSets
                };
            });

            groupings.push({
                _key: `${id}-grp-${gIdx}`,
                accounts,
                conditions
            });
        });

        return {
            id,
            recordName: r.Name,
            recName: r.Reward_Name__c,
            rewardCode: r.Reward_Code__c,
            rewardStatus: r.Reward_Status__c,
            rewardPaymentAmount: r.Reward_Payment_Amount__c,
            rewardPaymentDate: r.Reward_Payment_Date__c,
            rewardType: r.Reward_Type__c,
            rewardAccountNumber: r.Reward_Account__c,
            rewardFlag: r.Force_Payout_Flag__c === 'Y'? 'Force Payout' : '—',
            name: r.Reward_Name__c,
            description: r.Reward_Description__c,
            rewardTotalAmountPaid: r.Reward_Total_Amount_Paid__c,
            rewardMailingDate: r.Reward_Mailing_Date__c,
            rewardValueType: r.Reward_Value_Type__c,
            rewardReverseFlag: r.Reward_Reversal_Flag__c,
            rewardNotes: r.Reverse_Notes__c,
            groupings
        };
    }

    handleOpenConditionRecord(event) {
        const id = event.target.dataset.id;
        if (id) window.open(`/lightning/r/Promotion_Condition__c/${id}/view`, "_self");
    }

    handleOpenRuleSetRecord(event) {
        const id = event.target.dataset.id;
        if (id) window.open(`/lightning/r/Promotion_Rule_Set__c/${id}/view`, "_self");
    }

    handleOpenRuleRecord(event) {
        const id = event.target.dataset.id;
        if (id) window.open(`/lightning/r/Promotion_Rule__c/${id}/view`, "_self");
    }

    handleOpenProgressRecord(event) {
        const id = event.target.dataset.id;
        if (id) window.open(`/lightning/r/Promotion_Rule_Progress__c/${id}/view`, "_self");
    }

    handleOpenRewardRecord() {
        const id = this.selectedReward?.id;
        if (id) window.open(`/lightning/r/Promotion_Rewards__c/${id}/view`, "_self");
    }
}