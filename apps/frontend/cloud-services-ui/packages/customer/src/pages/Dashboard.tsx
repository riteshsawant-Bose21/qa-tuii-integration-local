import React, { useEffect, useMemo, useState } from 'react';
import { Box, Divider, Grid, Stack, Toolbar, Typography, Card, CardContent, CardActions, Button } from '@mui/material';
import SpacesContainer from '../components/Spaces/SpacesContainer';
import { useAppSelector } from '../store/hooks';
import Devices from './Devices';
import Splash from '../assets/splash.png';
import { useNavigate } from 'react-router-dom';
import Incidents from './Incidents';
import DeviceCards from '../components/Devices/DeviceCards';
import { useDispatch } from 'react-redux';
import { setDevices } from '../store/features/devices/devicesSlice';
import DeviceClaim from '../components/Devices/DeviceClaim';
import AddIcon from '@mui/icons-material/Add';
import { getDevices } from '../api/devices';

const DashboardView: React.FC = () => {
    const dispatch = useDispatch();
    const navigate = useNavigate();

    const selectedSpace = useAppSelector(state => state.spaces.selected);
    const spaces = useAppSelector((state) => state.spaces);
    const allDevices = useAppSelector(state => state.devices.all);
    const [claimOpen, setClaimOpen] = useState(false);

    const devices = useMemo(() => {
        return allDevices.filter(d =>
            d.space?.id === selectedSpace?.id ||
            !selectedSpace?.id ||
            !selectedSpace?.parent_id
        );
    }, [allDevices, selectedSpace?.id, selectedSpace?.parent_id]);

    const onlineDevices = useMemo(() => {
        return devices.filter((d) => d.status === 'online');
    }, [devices]);

    const handleOpenClaim = () => {
        setClaimOpen(true);
    };

    const handleCloseClaim = () => {
        setClaimOpen(false);
    };
    async function loadDevices() {
        try {
            const data = await getDevices();
            dispatch(setDevices(data.items));
        } catch (err: any) {
        } finally {
        }
    }

    useEffect(() => {
        loadDevices();
    }, []);

    return (
        <Box sx={{ width: '100%', height: 'calc(100vh - 65px)', overflow: 'hidden' }}>
            <Stack
                direction="row"
                divider={<Divider orientation="vertical" flexItem />}
                spacing={0}
                sx={{ width: '100%', height: 'calc(100vh - 65px)', maxHeight: 'calc(100vh - 65px)' }}
            >
                <SpacesContainer />
                <Stack width={'100%'} sx={{ overflowY: 'auto', backgroundColor: '#fafafa' }}>
                    <Box sx={{ minHeight: '200px', backgroundImage: `url(${Splash})`, width: '100%', backgroundSize: 'cover' }}></Box>
                    <Toolbar sx={{ backgroundColor: 'white' }}>
                        <Typography variant='h5' flexGrow={1}>{spaces.selected?.path}</Typography>
                        <Button variant="contained" onClick={handleOpenClaim}>
                            <AddIcon />
                            Claim Device
                        </Button>
                    </Toolbar>
                    <Divider orientation="horizontal" flexItem />
                    <Box sx={{ p: 2, }} height={'100%'}>
                        <Grid container spacing={2}>
                            <Grid size={4}>
                                <Card elevation={0} sx={{ width: '100%' }}>
                                    <CardContent>
                                        <Typography variant="h5" gutterBottom sx={{ color: 'text.secondary', fontSize: 14 }}>
                                            Claimed Devices
                                        </Typography>
                                        <Typography variant="h5" component="div">
                                            {devices?.length}
                                        </Typography>
                                    </CardContent>
                                    <CardActions>
                                        <Button size="small" onClick={() => { navigate('/devices') }}>View Details</Button>
                                    </CardActions>
                                </Card>
                            </Grid>
                            <Grid size={4}>
                                <Card elevation={0}>
                                    <CardContent>
                                        <Typography variant="h5" gutterBottom sx={{ color: 'text.secondary', fontSize: 14 }}>
                                            Online Devices
                                        </Typography>
                                        <Typography variant="h5" component="div">
                                            {onlineDevices?.length}
                                        </Typography>
                                    </CardContent>
                                    <CardActions>
                                        <Button size="small" onClick={() => { navigate('/devices') }}>View Details</Button>
                                    </CardActions>
                                </Card>
                            </Grid>
                            <Grid size={4}>
                                <Card elevation={0}>
                                    <CardContent>
                                        <Typography variant="h5" gutterBottom sx={{ color: 'text.secondary', fontSize: 14 }}>
                                            Active Incidents
                                        </Typography>
                                        <Typography variant="h5" component="div">
                                            {Devices.length}
                                        </Typography>
                                    </CardContent>
                                    <CardActions>
                                        <Button size="small" onClick={() => { navigate('/incidents') }}>View Details</Button>
                                    </CardActions>
                                </Card>
                            </Grid>
                            <Grid size={8} maxHeight={'sm'}>
                                <Card elevation={0} sx={{ boxSizing: 'border-box' }}>
                                    <CardContent>
                                        <DeviceCards />
                                    </CardContent>
                                </Card>
                            </Grid>
                            <Grid size={4}>
                                <Card elevation={0} sx={{ boxSizing: 'border-box' }}>
                                    <CardContent>
                                        <Incidents />
                                    </CardContent>
                                </Card>
                            </Grid>
                        </Grid>
                    </Box>
                </Stack>
            </Stack>
            <DeviceClaim open={claimOpen} handleCloseClaim={handleCloseClaim} />
        </Box>
    );
};

export default DashboardView;
