import { createSlice, type PayloadAction } from '@reduxjs/toolkit';
import type { Device } from 'xyte-api';

interface DevicesState {
    all: Device[];
}

const initialState: DevicesState = {
    all: [],
};

const devicesSlice = createSlice({
    name: 'devices',
    initialState,
    reducers: {
        setDevices(state, action: PayloadAction<Device[]>) {
            state.all = action.payload;
        },
    },
});

export const { setDevices } = devicesSlice.actions;

export default devicesSlice.reducer;
