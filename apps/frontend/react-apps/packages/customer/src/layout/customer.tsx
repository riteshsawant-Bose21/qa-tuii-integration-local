import { Outlet, useNavigate } from 'react-router-dom';

import { MainLayout } from 'shared-ui';
import DevicesIcon from '@mui/icons-material/Devices';
import SettingsIcon from '@mui/icons-material/Settings';
import type { MenuSection, SideMenuProps } from 'shared-ui/dist/components/SideMenu/SideMenuModels';
import logo from '../assets/logo.png';
import { useAppSelector } from '../store/hooks';
import ViewCarouselIcon from '@mui/icons-material/ViewCarousel';
import FolderIcon from '@mui/icons-material/Folder';
import ReportGmailerrorredIcon from '@mui/icons-material/ReportGmailerrorred';
import WorkOutline from '@mui/icons-material/WorkOutline';
import { clearOrganization } from '../store/features/organization/organizationSlice';
import { useAuth } from '../contexts/AuthContext';

export default function CustomerLayout() {
    const organization = useAppSelector((state) => state.organization);
    const global = useAppSelector((state) => state.global);
    const navigate = useNavigate();
    const { logout } = useAuth();

    const sections: MenuSection[] = [
        {
            items: [
                {
                    label: 'Projects',
                    icon: <WorkOutline fontSize="medium" />,
                    onClick: () => navigate('projects'),
                },
            ],
        },
        {
            items: [
                {
                    label: 'Overview',
                    icon: <ViewCarouselIcon fontSize="medium" />,
                    onClick: () => navigate('dashboard'),
                },
                {
                    label: 'Incidents',
                    icon: <ReportGmailerrorredIcon fontSize="medium" />,
                    onClick: () => navigate('incidents'),
                },
            ],
        },
        {
            items: [
                {
                    label: 'Devices',
                    icon: <DevicesIcon fontSize="medium" />,
                    onClick: () => navigate('devices'),
                },
                {
                    label: 'Files',
                    icon: <FolderIcon fontSize="medium" />,
                    onClick: () => navigate('files'),
                },
            ],
        },
        {
            items: [
                {
                    label: 'Settings',
                    icon: <SettingsIcon fontSize="medium" />,
                    onClick: () => navigate('settings'),
                },
            ],
        },
    ];

    const headerProps = {
        user: {
            name: organization.name,
            email: organization.contacts.admin_email
        },
        onLogout: () => {
            clearOrganization();
            logout();
        },
    };

    const sideMenuProps: SideMenuProps = {
        sections,
        title: organization.name,
        logo: logo,
        onLogoClick: () => { navigate('dashboard') }
    };
    return (
        <MainLayout headerProps={headerProps} loading={global.loading} sideMenuProps={sideMenuProps}><Outlet /></MainLayout>
    );
}
