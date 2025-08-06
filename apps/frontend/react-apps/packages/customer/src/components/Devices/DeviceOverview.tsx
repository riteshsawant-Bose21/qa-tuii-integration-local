import React from 'react';
import {
    Grid,
    Card,
    CardContent,
    Typography,
    Box,
    IconButton,
    Menu,
    MenuItem,
    Divider
} from '@mui/material';
import MoreVertIcon from '@mui/icons-material/MoreVert';
import CircularProgress from '@mui/material/CircularProgress';

export default function DeviceOverview() {
    const [anchorEl, setAnchorEl] = React.useState<null | HTMLElement>(null);
    const [timeRange, setTimeRange] = React.useState('30d');

    const openMenu = Boolean(anchorEl);
    const handleMenuOpen = (event: React.MouseEvent<HTMLElement>) => {
        setAnchorEl(event.currentTarget);
    };
    const handleMenuClose = () => {
        setAnchorEl(null);
    };
    const handleTimeRangeSelect = (range: string) => {
        setTimeRange(range);
        handleMenuClose();
    };

    return (
        <Grid container spacing={2}>
            <Grid size={4}>
                <Card sx={{ height: '100%' }}>
                    <CardContent>
                        <Typography variant="subtitle1" gutterBottom>
                            Status
                        </Typography>
                        <Typography variant="body2">
                            Device status details go here
                        </Typography>
                    </CardContent>
                </Card>
            </Grid>
            <Grid size={4}>
                <Card sx={{ height: '100%' }}>
                    <CardContent>
                        <Typography variant="subtitle1" gutterBottom>
                            Active Incidents
                        </Typography>
                        <Typography variant="body2">
                            Incident details or counts go here
                        </Typography>
                    </CardContent>
                </Card>
            </Grid>
            <Grid size={4}>
                <Card sx={{ height: '100%' }}>
                    <CardContent>
                        <Typography variant="subtitle1" gutterBottom>
                            Pending Commands
                        </Typography>
                        <Typography variant="body2">
                            Info about commands in queue
                        </Typography>
                    </CardContent>
                </Card>
            </Grid>

            <Grid size={6}>
                <Card sx={{ height: '100%' }}>
                    <CardContent>
                        <Typography variant="subtitle1" gutterBottom>
                            System Load
                        </Typography>
                        <Box
                            sx={{
                                display: 'flex',
                                alignItems: 'center',
                                justifyContent: 'center',
                                mt: 4,
                                mb: 2,
                            }}
                        >
                            <Box sx={{ position: 'relative', display: 'inline-flex' }}>
                                <CircularProgress variant="determinate" value={65} size={80} />
                                <Box
                                    sx={{
                                        top: 0,
                                        left: 0,
                                        bottom: 0,
                                        right: 0,
                                        position: 'absolute',
                                        display: 'flex',
                                        alignItems: 'center',
                                        justifyContent: 'center',
                                    }}
                                >
                                    <Typography variant="caption" component="div">
                                        65%
                                    </Typography>
                                </Box>
                            </Box>
                        </Box>
                    </CardContent>
                </Card>
            </Grid>
            <Grid size={6}>
                <Card sx={{ height: '100%' }}>
                    <CardContent>
                        <Typography variant="subtitle1" gutterBottom>
                            Memory Usage
                        </Typography>
                        <Box
                            sx={{
                                display: 'flex',
                                alignItems: 'center',
                                justifyContent: 'center',
                                mt: 4,
                                mb: 2,
                            }}
                        >
                            <Box sx={{ position: 'relative', display: 'inline-flex' }}>
                                <CircularProgress variant="determinate" value={40} size={80} />
                                <Box
                                    sx={{
                                        top: 0,
                                        left: 0,
                                        bottom: 0,
                                        right: 0,
                                        position: 'absolute',
                                        display: 'flex',
                                        alignItems: 'center',
                                        justifyContent: 'center',
                                    }}
                                >
                                    <Typography variant="caption" component="div">
                                        40%
                                    </Typography>
                                </Box>
                            </Box>
                        </Box>
                    </CardContent>
                </Card>
            </Grid>

            <Grid size={12}>
                <Card>
                    <CardContent>
                        <Box sx={{ display: 'flex', alignItems: 'center', mb: 1 }}>
                            <Typography variant="subtitle1" sx={{ flexGrow: 1 }}>
                                Network Bandwidth Usage ({timeRange})
                            </Typography>

                            <Box>
                                <IconButton onClick={handleMenuOpen}>
                                    <MoreVertIcon />
                                </IconButton>
                                <Menu
                                    anchorEl={anchorEl}
                                    open={openMenu}
                                    onClose={handleMenuClose}
                                >
                                    <MenuItem
                                        onClick={() => handleTimeRangeSelect('30d')}
                                        selected={timeRange === '30d'}
                                    >
                                        Last 30 Days
                                    </MenuItem>
                                    <MenuItem
                                        onClick={() => handleTimeRangeSelect('7d')}
                                        selected={timeRange === '7d'}
                                    >
                                        Last 7 Days
                                    </MenuItem>
                                    <MenuItem
                                        onClick={() => handleTimeRangeSelect('24h')}
                                        selected={timeRange === '24h'}
                                    >
                                        Last 24 Hours
                                    </MenuItem>
                                </Menu>
                            </Box>
                        </Box>
                        <Divider sx={{ mb: 2 }} />
                        <Box
                            sx={{
                                mt: 2,
                                height: 200,
                                backgroundColor: 'rgba(0,0,0,0.04)',
                                display: 'flex',
                                alignItems: 'center',
                                justifyContent: 'center',
                            }}
                        >
                            <Typography variant="body2" color="text.secondary">
                                Chart JS?
                            </Typography>
                        </Box>
                    </CardContent>
                </Card>
            </Grid>
        </Grid>
    );
}
