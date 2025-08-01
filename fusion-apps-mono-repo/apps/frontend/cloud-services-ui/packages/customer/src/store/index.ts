import { configureStore } from '@reduxjs/toolkit';
import userReducer from './features/user/userSlice';
import devicesReducer from './features/devices/devicesSlice';
import organizationReducer from './features/organization/organizationSlice';
import spacesReducer from './features/spaces/spacesSlice';
import globalReducer from './features/global/globalSlice';
import projectsReducer from './features/projects/projectsSlice';

export const store = configureStore({
    reducer: {
        user: userReducer,
        devices: devicesReducer,
        organization: organizationReducer,
        spaces: spacesReducer,
        global: globalReducer,
        projects: projectsReducer,
    },
});

export type RootState = ReturnType<typeof store.getState>;
export type AppDispatch = typeof store.dispatch;
