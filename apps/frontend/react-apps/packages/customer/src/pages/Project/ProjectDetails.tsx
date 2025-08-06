import React, { useEffect, useState } from "react";
import { Box, Typography } from "@mui/material";
import { useParams } from "react-router-dom";
import ProjectBreadCrumb from "../../components/Projects/ProjectBreadCrumb";
import { getProjectById } from "../../api/projects";

const ProjectDetails: React.FC = () => {
  const { projectId } = useParams<{ projectId: string }>(null);

  const [loading, setLoading] = useState(false);
  const [project, setProject] = useState<any>(null);

  const [breadcrumbs, setBreadcrumbs] = useState([
    { label: "Projects", path: "/projects" },
  ]);

  useEffect(() => {
    fetchProjectDetails();
  }, [projectId]);

  useEffect(() => {
    if (project) {
      setBreadcrumbs((prev) => [
        breadcrumbs[0],
        { label: project.name, path: `/projects/${projectId}` },
      ]);
    }
  }, [project]);

  const fetchProjectDetails = async () => {
    try {
      setLoading(true);
      const data = await getProjectById(projectId);
      setProject(data);
    } catch (err: any) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  return (
    <Box sx={{ p: 4 }}>
      <ProjectBreadCrumb breadcrumbs={breadcrumbs} />

      {loading ? (
        <Typography>Loading project details...</Typography>
      ) : project ? (
        <Box
          sx={{ p: 2, border: "1px solid #ccc", borderRadius: 2, marginTop: 2 }}
        >
          <Typography variant="h4">{project.name}</Typography>
          {/* Add more project details here */}
          
        </Box>
      ) : (
        <Typography>No project found</Typography>
      )}
    </Box>
  );
};

export default ProjectDetails;
