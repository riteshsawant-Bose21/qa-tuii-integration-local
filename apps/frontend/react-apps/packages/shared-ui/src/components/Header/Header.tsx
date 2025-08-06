import React from 'react';
import AppBar from '@mui/material/AppBar';
import Toolbar from '@mui/material/Toolbar';
import IconButton from '@mui/material/IconButton';
import AccountCircle from '@mui/icons-material/AccountCircle';
import Menu from '@mui/material/Menu';
import MenuItem from '@mui/material/MenuItem';
import { Divider } from '@mui/material';

export interface User {
    name: String;
    email: String;
};

export interface HeaderProps {
    user?: User;
    onLogout?: () => void;
    sideMenuWidth?: number
}

const Header: React.FC<HeaderProps> = ({
    user = { name: '', email: '' },
    onLogout,
    sideMenuWidth = 0,
}) => {
    const [anchorEl, setAnchorEl] = React.useState<null | HTMLElement>(null);
    const open = Boolean(anchorEl);

    const handleMenu = (event: React.MouseEvent<HTMLElement>) => {
        setAnchorEl(event.currentTarget);
    };

    const handleClose = () => {
        setAnchorEl(null);
    };

    const handleLogout = () => {
        handleClose();
        onLogout?.();
    };

    return (
        <AppBar position="fixed" elevation={0} sx={{ pl: sideMenuWidth + 'px', background: 'white', borderWidth: '0px 0px 1px 0px', borderStyle: 'solid', borderColor: '#e0e0e0' }}>
            <Toolbar>
                <div style={{ flexGrow: 1 }} />
                <div>
                    <IconButton
                        size="large"
                        aria-label="account of current user"
                        aria-controls="menu-appbar"
                        aria-haspopup="true"
                        onClick={handleMenu}
                        color="inherit"
                    >
                        <AccountCircle color="primary" />
                    </IconButton>
                    <Menu
                        id="menu-appbar"
                        anchorEl={anchorEl}
                        open={open}
                        onClose={handleClose}
                        anchorOrigin={{
                            vertical: 'top',
                            horizontal: 'right',
                        }}
                        transformOrigin={{
                            vertical: 'top',
                            horizontal: 'right',
                        }}
                    >
                        {user.name && <MenuItem disabled>{user.name}</MenuItem>}
                        <MenuItem onClick={handleLogout}>Logout</MenuItem>
                    </Menu>
                </div>
            </Toolbar>
        </AppBar>
    );
};

export default Header;
