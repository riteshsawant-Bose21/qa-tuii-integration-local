import React from 'react';
import {
    Card,
    CardActionArea,
    CardContent,
    CardMedia,
    Typography,
    IconButton,
    Menu,
    MenuItem,
    Box
} from '@mui/material';
import MoreVertIcon from '@mui/icons-material/MoreVert';
import { type Device, getDeviceLogo } from 'xyte-api';

interface DeviceCardProps {
    device: Device;
    onClick?: (device: Device) => void;
}

export default function DeviceCard({ device, onClick }: DeviceCardProps) {
    const [anchorEl, setAnchorEl] = React.useState<null | HTMLElement>(null);
    const openMenu = Boolean(anchorEl);

    const handleMenuOpen = (e: React.MouseEvent<HTMLElement>) => {
        e.stopPropagation();
        setAnchorEl(e.currentTarget);
    };

    const handleMenuClose = () => {
        setAnchorEl(null);
    };

    const handleCardClick = () => {
        if (onClick) onClick(device);
    };

    return (
        <Card sx={{ display: 'flex', flexDirection: 'column', height: '100%', border: '1px solid #e0e0e0' }} elevation={0}>
            <CardActionArea
                onClick={handleCardClick}
                sx={{ flexGrow: 1, display: 'flex', flexDirection: 'column', alignItems: 'stretch' }}
            >
                <CardContent sx={{ flexGrow: 1, width: '100%', display: 'flex', flexDirection: 'column', alignItems: 'center', pl: 0, pr: 0 }}>
                    <Typography variant="subtitle1" gutterBottom>
                        {device.name}
                    </Typography>
                </CardContent>
                <CardMedia
                    component="img"
                    image={device.model?.name ? getDeviceLogo(device.model?.name) : ''}
                    alt={device.name}
                    sx={{ width: '100%', height: 140, objectFit: 'contain', display: 'flex', flexDirection: 'column', alignItems: 'center' }}
                />
                <CardContent sx={{ flexGrow: 1, width: '100%', display: 'flex', flexDirection: 'column', alignItems: 'center', pl: 0, pr: 0 }}>
                    <Typography variant="subtitle1" gutterBottom>
                        {device.name}
                    </Typography>
                </CardContent>
            </CardActionArea>
            <Box sx={{ position: 'absolute', top: 8, right: 8 }}>
                <IconButton size="small" onClick={handleMenuOpen}>
                    <MoreVertIcon />
                </IconButton>
                <Menu anchorEl={anchorEl} open={openMenu} onClose={handleMenuClose}>
                    <MenuItem onClick={() => { handleMenuClose(); alert('Device action 1'); }}>
                        Action 1
                    </MenuItem>
                    <MenuItem onClick={() => { handleMenuClose(); alert('Device action 2'); }}>
                        Action 2
                    </MenuItem>
                </Menu>
            </Box>
        </Card>
    );
}
