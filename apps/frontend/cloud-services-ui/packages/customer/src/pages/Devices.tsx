import { useEffect, useState } from 'react';
import {
    Box,
    Button,
    Table,
    TableBody,
    TableCell,
    TableContainer,
    TableHead,
    TableRow,
    Paper,
    Typography,
} from '@mui/material';
import AddIcon from '@mui/icons-material/Add';
import DeviceClaim from '../components/Devices/DeviceClaim';
import { useDispatch } from 'react-redux';
import { useAppSelector } from '../store/hooks';
import { setDevices } from '../store/features/devices/devicesSlice';
import { getDevices } from '../api/devices';

export default function DevicesPage() {
    const dispatch = useDispatch();
    const devices = useAppSelector(state => state.devices)
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState('');
    const [claimOpen, setClaimOpen] = useState(false);

    async function loadDevices() {
        try {
            setLoading(true);
            const data = await getDevices();
            dispatch(setDevices(data.items));
        } catch (err: any) {
            setError('Failed to load devices');
            console.error(err);
        } finally {
            setLoading(false);
        }
    }
    useEffect(() => {
        loadDevices();
    }, []);

    const handleOpenClaim = () => {
        setClaimOpen(true);
    };

    const handleCloseClaim = () => {
        setClaimOpen(false);
    };

    return (
        <Box sx={{ p: 4 }}>
            <Box sx={{ display: 'flex', alignItems: 'center', mb: 4 }}>
                <Typography flexGrow={1} variant="h5" gutterBottom>
                    Devices
                </Typography>
                <Button variant="contained" onClick={handleOpenClaim}>
                    <AddIcon />
                    Claim Device
                </Button>
            </Box>
            {loading ? (
                <Typography>Loading devices...</Typography>
            ) : error ? (
                <Typography color="error">{error}</Typography>
            ) : (
                <TableContainer component={Paper}>
                    <Table>
                        <TableHead>
                            <TableRow>
                                <TableCell>Name</TableCell>
                                <TableCell>Vendor</TableCell>
                                <TableCell>Model</TableCell>
                                <TableCell>Sub Model</TableCell>
                                <TableCell>Customer</TableCell>
                                <TableCell>Parent</TableCell>
                                <TableCell>Status</TableCell>
                                <TableCell>Serial Number</TableCell>
                                <TableCell>Cloud Id</TableCell>
                                <TableCell>Created at</TableCell>
                            </TableRow>
                        </TableHead>
                        <TableBody>
                            {devices?.all?.map((dev) => (
                                <TableRow key={dev.id}>
                                    <TableCell>{dev.name}</TableCell>
                                    <TableCell>{'Vendor****'}</TableCell>
                                    <TableCell>
                                        {dev.model ? `${dev.model.name}` : ''}
                                    </TableCell>
                                    <TableCell>
                                        {dev.model ? `${dev.model.sub_model}` : ''}
                                    </TableCell>
                                    <TableCell>{'Customer****'}</TableCell>
                                    <TableCell>{'Parent****'}</TableCell>
                                    <TableCell>{'Status****'}</TableCell>
                                    <TableCell>{dev.sn}</TableCell>
                                    <TableCell>{dev.cloud_id}</TableCell>
                                    <TableCell>{dev.created_at}</TableCell>
                                </TableRow>
                            ))}
                            {devices?.all?.length === 0 &&
                                <Box
                                    sx={{
                                        p: 4,
                                        textAlign: 'center',
                                        color: 'text.secondary',
                                        width: '100%'
                                    }}
                                >
                                    <Typography variant="h6" gutterBottom>
                                        No Devices
                                    </Typography>
                                </Box>
                            }
                        </TableBody>
                    </Table>
                </TableContainer>
            )}

            <DeviceClaim open={claimOpen} handleCloseClaim={handleCloseClaim} />
        </Box>
    );
}
