export interface Organization {
    id: string;
    name: string;
    created_at: string;
    lab: boolean;
    partner: string;
    domain: string;
    mobile_domain: string;
    pricing_plan: string;
    contacts: {
        admin_email: string;
        admin_name: string;
        finance_email: string;
        finance_name: string;
    };
    statistics: {
        devices: number;
        users: number;
        groups: number;
        spaces: number;
        open_tickets: number;
        open_incidents: number;
        pending_invoices: number;
    };
}
