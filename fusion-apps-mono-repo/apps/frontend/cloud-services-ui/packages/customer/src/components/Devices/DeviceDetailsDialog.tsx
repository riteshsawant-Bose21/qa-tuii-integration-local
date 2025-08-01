import React from 'react';
import {
    Dialog,
    DialogContent,
    Button,
    Box,
    Tabs,
    Tab,
    Typography,
    Stack,
    IconButton,
    Menu,
    MenuItem,
    Divider,
} from '@mui/material';
import { type Device, getDeviceLogo } from 'xyte-api';
import CloseIcon from '@mui/icons-material/Close';
import MoreVertIcon from '@mui/icons-material/MoreVert';
import CheckCircleIcon from '@mui/icons-material/CheckCircle';
import CancelIcon from '@mui/icons-material/Cancel';
import DeviceOverview from './DeviceOverview';

interface DeviceDetailsDialogProps {
    open: boolean;
    onClose: () => void;
    device?: Device;
}

export default function DeviceDetailsDialog({
    open,
    onClose,
    device,
}: DeviceDetailsDialogProps) {
    // Manage which tab is active
    const [tabValue, setTabValue] = React.useState(0);

    const [anchorEl, setAnchorEl] = React.useState<null | HTMLElement>(null);
    const menuOpen = Boolean(anchorEl);

    const handleMenuOpen = (e: React.MouseEvent<HTMLElement>) => {
        setAnchorEl(e.currentTarget);
    };
    const handleMenuClose = () => {
        setAnchorEl(null);
    };

    const handleDelete = () => {
        handleMenuClose();
        alert('Delete device clicked');
    };
    if (!device) {
        return null;
    }

    const handleTabChange = (_event: React.SyntheticEvent, newValue: number) => {
        setTabValue(newValue);
    };

    return (
        <Dialog
            open={open}
            onClose={onClose}
            fullWidth
            maxWidth="lg"
        >
            <IconButton
                onClick={onClose}
                sx={{
                    position: 'absolute',
                    top: 8,
                    right: 8,
                    zIndex: 10,
                }}
            >
                <CloseIcon />
            </IconButton>
            <DialogContent dividers sx={{ display: 'flex', minHeight: '90vh' }}>
                <Box
                    sx={{
                        width: '33%',
                        borderRight: 1,
                        borderColor: 'divider',
                        p: 2,
                        display: 'flex',
                        flexDirection: 'column',
                    }}
                >
                    <Box
                        sx={{
                            display: 'flex',
                            mb: 2,
                        }}
                    >
                        <Box
                            sx={{
                                minWidth: 120,
                                maxWidth: 120,
                                mr: 2,
                                display: 'flex',
                                alignItems: 'center',
                            }}
                        >
                            <img
                                src={device.model?.name ? getDeviceLogo(device.model?.name) : ''}
                                alt={device.name}
                                style={{
                                    maxWidth: '100%',
                                    height: 'auto',
                                    objectFit: 'contain',
                                }}
                            />
                        </Box>
                        <Stack spacing={1} sx={{ flexGrow: 1 }}>
                            <Typography variant="subtitle1" fontWeight="bold">
                                {device.name}
                            </Typography>
                            <Typography variant="body2" color="text.secondary">
                                {'[device.path]'}
                            </Typography>
                            <Box sx={{ display: 'flex', alignItems: 'center' }}>
                                {device.status === 'online' ? (
                                    <CheckCircleIcon fontSize="small" color="success" sx={{ mr: 1 }} />
                                ) : (
                                    <CancelIcon fontSize="small" color="warning" sx={{ mr: 1 }} />
                                )}
                                <Typography variant="body2">
                                    {device.status === 'online' ? 'ONLINE' : 'N/A'}
                                </Typography>
                            </Box>
                        </Stack>
                    </Box>
                    <Box
                        sx={{
                            display: 'flex',
                            alignItems: 'center',
                            justifyContent: 'flex-start',
                            gap: 1,
                            mb: 2,
                        }}
                    >
                        <Button variant="outlined">Support</Button>
                        <Button variant="outlined">Refresh</Button>
                        <IconButton onClick={handleMenuOpen}>
                            <MoreVertIcon />
                        </IconButton>
                        <Menu
                            anchorEl={anchorEl}
                            open={menuOpen}
                            onClose={handleMenuClose}
                        >
                            <MenuItem onClick={handleDelete}>Delete Device</MenuItem>
                        </Menu>
                    </Box>

                    <Divider sx={{ mb: 2 }} />
                    <Stack spacing={2} sx={{ overflowY: 'auto' }}>
                        <Typography variant="subtitle1" fontWeight="bold">
                            Device Details
                        </Typography>
                        <Box>
                            <Typography variant="caption" color="text.secondary">
                                Vendor
                            </Typography>
                            <Typography variant="body2">
                                {'Get Vendor Info API'}
                            </Typography>
                        </Box>
                        <Box>
                            <Typography variant="caption" color="text.secondary">
                                Model
                            </Typography>
                            <Typography variant="body2">
                                {device.model?.name}
                            </Typography>
                        </Box>
                        <Box>
                            <Typography variant="caption" color="text.secondary">
                                Last Seen
                            </Typography>
                            <Typography variant="body2">
                                {device.last_seen_at}
                            </Typography>
                        </Box>
                        <Box>
                            <Typography variant="caption" color="text.secondary">
                                Firmware Version
                            </Typography>
                            <Typography variant="body2">
                                {device.firmware?.version}
                            </Typography>
                        </Box>
                        <Box>
                            <Typography variant="caption" color="text.secondary">
                                Serial Number
                            </Typography>
                            <Typography variant="body2">
                                {device.sn}
                            </Typography>
                        </Box>
                    </Stack>
                </Box>
                <Box sx={{ width: '67%', pl: 2 }}>
                    <Tabs value={tabValue} onChange={handleTabChange}>
                        <Tab label="Overview" />
                        <Tab label="Incidents" />
                        <Tab label="Commands" />
                        <Tab label="Files" />
                        <Tab label="State" />
                    </Tabs>

                    {/* Tab panels */}
                    {tabValue === 0 && (
                        <Box sx={{ mt: 2 }}>
                            <DeviceOverview />
                        </Box>
                    )}
                    {tabValue === 1 && (
                        <Box sx={{ mt: 2 }}>
                            <Typography variant="body1" gutterBottom>
                                Incidents content here
                            </Typography>
                        </Box>
                    )}
                    {tabValue === 2 && (
                        <Box sx={{ mt: 2 }}>
                            <Typography variant="body1" gutterBottom>
                                Commands content here
                            </Typography>
                        </Box>
                    )}
                    {tabValue === 3 && (
                        <Box sx={{ mt: 2 }}>
                            <Typography variant="body1" gutterBottom>
                                Files content here
                            </Typography>
                        </Box>
                    )}
                    {tabValue === 4 && (
                        <Box sx={{ mt: 2 }}>
                            <Typography variant="body1" gutterBottom>
                                State content here
                            </Typography>
                        </Box>
                    )}
                </Box>
            </DialogContent>
        </Dialog>
    );
}
