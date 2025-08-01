import { createSlice, type PayloadAction } from '@reduxjs/toolkit';
import type { SpaceItem } from 'xyte-api';

interface SpacesState {
    selected?: SpaceItem;
    spaces: SpaceItem[]
}

const initialState: SpacesState = {
    spaces: [],
};

const spacesSlice = createSlice({
    name: 'spaces',
    initialState,
    reducers: {
        selectSpace(state, action: PayloadAction<SpaceItem>) {
            state.selected = action.payload;
        },
        setSpaces(state, action: PayloadAction<SpaceItem[]>) {
            state.spaces = action.payload;
        },
    },
});

export const { selectSpace, setSpaces } = spacesSlice.actions;

export default spacesSlice.reducer;
