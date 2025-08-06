import React from 'react';
import {
    Box,
    Button,
    Dialog,
    DialogTitle,
    DialogContent,
    DialogActions,
    TextField,
    Typography,
    FormControl,
    InputLabel,
    MenuItem,
    Select,
    IconButton,
    Divider,
    Card,
    Container,
    Stack,
} from '@mui/material';

import CloseIcon from '@mui/icons-material/Close';
import { deviceModels, type ClaimDevicePayload, type ModelDefinition } from 'xyte-api';
import { useAppSelector } from '../../store/hooks';
import { claimDevice } from '../../api/devices';
import SpacesContainer from '../Spaces/SpacesContainer';

interface DeviceClaimProps {
    handleCloseClaim: () => void;
    open: boolean;
}

export default function DeviceClaim({ handleCloseClaim, open }: DeviceClaimProps) {
    const spaces = useAppSelector((state) => state.spaces);
    const [claiming, setClaiming] = React.useState(false);
    const [claimError, setClaimError] = React.useState('');
    const [cloudId, setCloudId] = React.useState('');
    const [deviceType, setDeviceType] = React.useState('');
    const [spacesListOpen, setSpacesListOpen] = React.useState(false);
    const [name, setName] = React.useState('');
    const [space, setSpace] = React.useState(spaces?.selected || spaces.spaces.at(0));

    const handleClaimDevice = async () => {
        try {
            setClaiming(true);
            const payload: ClaimDevicePayload = {
                cloud_id: cloudId.trim(),
                name: name.trim(),
                space_id: space?.id
            };
            await claimDevice(payload);
            handleCloseClaim();
        } catch (err: any) {
            const data = err?.response?.data;
            setClaiming(false);
            setClaimError(data?.error || 'Failed to claim device');
            console.error('Failed to claim device', err);
        }
    };

    const handleSwitchSpace = () => {
        setSpacesListOpen(true);
    };

    return (
        <Dialog open={open} onClose={handleCloseClaim} maxWidth={'lg'}>
            <DialogTitle>Add device to space</DialogTitle>
            <Divider />
            <IconButton
                aria-label="close"
                onClick={handleCloseClaim}
                sx={(theme) => ({
                    position: 'absolute',
                    right: 8,
                    top: 8,
                    color: theme.palette.grey[500],
                })}
            >
                <CloseIcon />
            </IconButton>
            <DialogContent>
                <Dialog open={spacesListOpen} onClose={() => { setSpacesListOpen(false) }}>
                    <DialogTitle>Select Space</DialogTitle>
                    <Divider />
                    <IconButton
                        aria-label="close"
                        onClick={() => { setSpacesListOpen(false) }}
                        sx={(theme) => ({
                            position: 'absolute',
                            right: 8,
                            top: 8,
                            color: theme.palette.grey[500],
                        })}
                    >
                        <CloseIcon />
                    </IconButton>
                    <DialogContent>
                        <Box height={400}>
                            <SpacesContainer
                                onSpaceClick={(space) => {
                                    setSpace(space);
                                    setSpacesListOpen(false)
                                }}
                            />
                        </Box>
                    </DialogContent>
                </Dialog>
                <Card elevation={0} sx={{ backgroundColor: '#EFEFEFFF', pt: 2, pb: 2 }}>
                    <Container>
                        <Typography variant={'body1'} sx={{ fontWeight: 600 }}>Add device to</Typography>
                    </Container>
                    <Stack direction="row" alignItems={'center'}>
                        <Typography variant={'body1'} flex={1} flexGrow={1} sx={{ pl: 4 }}>{space?.name}</Typography>
                        <Button variant={'text'} sx={{ mr: 2 }} onClick={handleSwitchSpace}>Change space</Button>
                    </Stack>
                </Card>
                <TextField
                    fullWidth
                    margin="normal"
                    label="Cloud ID"
                    value={cloudId}
                    onChange={(e) => setCloudId(e.target.value)}
                />
                <FormControl fullWidth margin="normal">
                    <InputLabel>Device Type</InputLabel>
                    <Select
                        label="Device Type"
                        value={deviceType}
                        onChange={(e) => {
                            setDeviceType(e.target.value as string)
                        }}
                        renderValue={(selected: string) => {
                            const found = deviceModels.find((m: ModelDefinition) => m.id === selected);
                            return found ? (
                                <Box sx={{ display: 'flex', alignItems: 'center' }}>
                                    <img
                                        src={found.image_url}
                                        alt={found.model}
                                        style={{ width: 32, height: 32, marginRight: 8 }}
                                    />
                                    {found.model}
                                </Box>
                            ) : selected;
                        }}
                    >
                        {deviceModels.map((model: ModelDefinition) => (
                            <MenuItem key={model.id} value={model.id}>
                                <Box sx={{ display: 'flex', alignItems: 'center' }}>
                                    <img
                                        src={model.image_url}
                                        alt={model.model}
                                        style={{ width: 32, height: 32, marginRight: 8 }}
                                    />
                                    {model.model}
                                </Box>
                            </MenuItem>
                        ))}
                    </Select>
                </FormControl>
                <TextField
                    fullWidth
                    margin="normal"
                    label="Name"
                    value={name}
                    onChange={(e) => setName(e.target.value)}
                />
            </DialogContent>
            <Divider />
            <DialogActions sx={{ mt: 2, mb: 2 }}>
                {claimError && <Typography color="error">{claimError}</Typography>}
                <Button disabled={claiming} onClick={handleCloseClaim}>Cancel</Button>
                <Button disabled={claiming} onClick={handleClaimDevice} variant="contained">
                    Claim
                </Button>
            </DialogActions>
        </Dialog>
    );
}
