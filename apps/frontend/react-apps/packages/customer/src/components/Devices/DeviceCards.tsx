import { useState, useMemo } from 'react';
import { Grid, Typography } from '@mui/material';
import DeviceCard from './DeviceCard';
import DeviceDetailsDialog from './DeviceDetailsDialog';
import type { Device } from 'xyte-api';
import { useAppSelector } from '../../store/hooks';

export default function DevicesPage() {
    const [selectedDevice, setSelectedDevice] = useState<Device | null>(null);
    const [openDetails, setOpenDetails] = useState(false);
    const selectedSpace = useAppSelector(state => state.spaces.selected);
    const allDevices = useAppSelector(state => state.devices.all);

    const devices = useMemo(() => {
        return allDevices.filter(d =>
            d.space?.id === selectedSpace?.id ||
            !selectedSpace?.id ||
            !selectedSpace?.parent_id
        );
    }, [allDevices, selectedSpace?.id, selectedSpace?.parent_id]);

    const handleCardClick = (device: Device) => {
        setSelectedDevice(device);
        setOpenDetails(true);
    };

    const handleCloseDetails = () => {
        setOpenDetails(false);
        setSelectedDevice(null);
    };

    return (
        <div>
            <Typography variant="h5" gutterBottom>
                Devices
            </Typography>

            <Grid container spacing={2}>
                {devices.map((device) => (
                    <Grid size={12} key={device.id}>
                        <DeviceCard device={device} onClick={handleCardClick} />
                    </Grid>
                ))}
            </Grid>

            <DeviceDetailsDialog
                open={openDetails}
                onClose={handleCloseDetails}
                device={selectedDevice ?? undefined}
            />
        </div>
    );
}
