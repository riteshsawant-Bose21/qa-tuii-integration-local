import { createSlice, type PayloadAction } from '@reduxjs/toolkit';
import type { Organization } from 'xyte-api';

const initialState: Organization = {
    id: '',
    name: '',
    created_at: '',
    lab: false,
    partner: '',
    domain: '',
    mobile_domain: '',
    pricing_plan: '',
    contacts: {
        admin_email: '',
        admin_name: '',
        finance_email: '',
        finance_name: ''
    },
    statistics: {
        devices: 0,
        users: 0,
        groups: 0,
        spaces: 0,
        open_tickets: 0,
        open_incidents: 0,
        pending_invoices: 0
    }
};

const orgSlice = createSlice({
    name: 'organization',
    initialState,
    reducers: {
        setOrganization(_state, action: PayloadAction<Organization>) {
            return action.payload;
        },
        clearOrganization() {
            return initialState;
        },
    },
});

export const { setOrganization, clearOrganization } = orgSlice.actions;
export default orgSlice.reducer;
