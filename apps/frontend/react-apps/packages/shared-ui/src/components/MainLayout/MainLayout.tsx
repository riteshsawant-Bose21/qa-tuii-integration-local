import React from 'react';
import { styled } from '@mui/material/styles';
import Header, { HeaderProps } from '../Header/Header';
import SideMenu from '../SideMenu/SideMenu';
import { SideMenuProps } from '../SideMenu/SideMenuModels';
import { Container } from '@mui/material';

export interface MainLayoutProps {
    headerProps?: HeaderProps;
    sideMenuProps?: SideMenuProps;
    children?: React.ReactNode;
    loading?: boolean;
}

const Root = styled('div')(({ theme }) => ({
    display: 'flex',
    height: '100vh',
}));


const MainLayout: React.FC<MainLayoutProps> = ({
    headerProps,
    sideMenuProps,
    children,
    loading = false,
}) => {
    const sideMenuWidth = sideMenuProps?.width || 88;

    const mergedHeaderProps: HeaderProps = {
        ...headerProps,
        sideMenuWidth: sideMenuWidth
    };

    const mergedSideMenuProps: SideMenuProps = {
        ...sideMenuProps,
        width: sideMenuWidth
    };

    return (
        <Root>
            <Header {...mergedHeaderProps} />
            <SideMenu {...mergedSideMenuProps} />
            <Container sx={{ mt: '64px', ml: 0, mr: 0, pl: '0px !important', pr: '0px !important' }}>
                {loading ? '' : children}
            </Container>
        </Root>
    );
};

export default MainLayout;
