import { createSlice, type PayloadAction } from "@reduxjs/toolkit";

interface Project {
  id: string;
  name: string;
  metadata: Record<string, unknown>;
  createdAt: string;
  updatedAt: string;
}

interface ProjectsState {
  all: Project[];
}

const initialState: ProjectsState = {
  all: [],
};

const projectsSlice = createSlice({
  name: "projects",
  initialState,
  reducers: {
    setProjects(state, action: PayloadAction<Project[]>) {
      state.all = action.payload;
    },
  },
});
export const { setProjects } = projectsSlice.actions;
export default projectsSlice.reducer;
export const selectProjects = (state: { projects: ProjectsState }) =>
  state.projects.all;
export const selectProjectById =
  (state: { projects: ProjectsState }, id: string) =>
  state.projects.all.find((project) => project.id === id);

