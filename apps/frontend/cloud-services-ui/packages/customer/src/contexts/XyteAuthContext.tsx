import React, { createContext, useState, useContext } from 'react';
import { clearOrganization, setOrganization as setOrg } from '../store/features/organization/organizationSlice';
import { useDispatch } from 'react-redux';
import type { Organization } from 'xyte-api';

interface XyteAuthContextValue {
    apiKey: string | null;
    organization: Organization | null;
    setApiKey: (key: string | null) => void;
    setOrganization: (org: Organization | null) => void;
}

const XyteAuthContext = createContext<XyteAuthContextValue | undefined>(undefined);

export const XyteAuthProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
    const dispatch = useDispatch();
    const [apiKey, setApiKeyState] = useState<string | null>('');
    const [organization, setOrganizationInfo] = useState<Organization | null>(null);

    const setApiKey = (key: string | null) => {
        setApiKeyState(key);
    };

    const setOrganization = (org: Organization | null) => {
        setOrganizationInfo(org);
        if (org) {
            dispatch(setOrg(org));
        } else {
            dispatch(clearOrganization());
        }
    };

    return (
        <XyteAuthContext.Provider value={{ apiKey, organization, setApiKey, setOrganization }}>
            {children}
        </XyteAuthContext.Provider>
    );
};

export function useXyteAuth() {
    const context = useContext(XyteAuthContext);
    if (!context) {
        throw new Error('useXyteAuth must be used within a XyteAuthProvider');
    }
    return context;
}
