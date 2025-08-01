import api from "./axios";
import type { AxiosResponse } from "./types";

export interface Project {
  id: string;
  name: string;
  metadata: Record<string, unknown>;
  createdAt: string;
  updatedAt: string;
}

export interface ProjectsResponse {
  items: Project[];
  next_page: number;
}

/* List (optionally paginated) */
export const getProjects = (page?: number) =>
  api
    .get<AxiosResponse<ProjectsResponse>>("/projects", {
      params: { page },
    })
    .then((r) => r.data.data);
export const getProjectById = (id: string) =>
  api.get<AxiosResponse<Project>>(`/projects/${id}`).then((r) => r.data.data);
