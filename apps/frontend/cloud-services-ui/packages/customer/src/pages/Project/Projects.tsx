import React, { useEffect, useState } from "react";
import {
  Box,
  Button,
  Card,
  CardActions,
  CardContent,
  CardMedia,
  Skeleton,
  Typography,
} from "@mui/material";
import { getProjects } from "../../api/projects";
import { useDispatch } from "react-redux";
import { useAppSelector } from "../../store/hooks";
import { setProjects } from "../../store/features/projects/projectsSlice";

import cardImg from "../../assets/splash.png";
import { useNavigate } from "react-router-dom";
import ProjectBreadCrumb from "../../components/Projects/ProjectBreadCrumb";

const Projects: React.FC = () => {
  const dispatch = useDispatch();
  const navigate = useNavigate();
  const projects = useAppSelector((state) => state.projects);

  /** STATE */
  const [loading, setLoading] = useState(false);
  const [breadcrumbs, setBreadcrumbs] = useState([
    { label: "Projects", path: "/projects" },
  ]);
  /** HOOKS */

  useEffect(() => {
    fetchProjects();
  }, []);

  /** METHODS */

  const fetchProjects = async () => {
    try {
      setLoading(true);
      const data = await getProjects();
      dispatch(setProjects(data.items));
    } catch (err: any) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  const handleProjectClick = (projectId: string) => {
    // Handle project click logic here
    console.log("Project clicked");
    navigate(`/projects/${projectId}`);
  };

  /** VIEWS */
  const ProjectCardSkeleton = () => {
    return (
      <Card sx={{ width: 300, padding: 2 }}>
        <Skeleton variant="rectangular" height={60} />
        <Skeleton variant="rounded" height={60} />
        <CardContent sx={{ padding: 0 }}>
          <Skeleton variant="text" width={"100%"} height={60} />
        </CardContent>
        <CardActions sx={{ padding: 0 }}>
          <Skeleton variant="text" width={"100%"} height={60} />
        </CardActions>
      </Card>
    );
  };

  return (
    <Box sx={{ p: 4 }}>
      <ProjectBreadCrumb breadcrumbs={breadcrumbs} />
      {loading ? (
        <Box sx={{ display: "flex", flexWrap: "wrap", gap: 2, marginTop: 2 }}>
          {Array.from({ length: 3 }).map((_, index) => (
            <ProjectCardSkeleton key={index} />
          ))}
        </Box>
      ) : projects.all.length === 0 ? (
        <Typography variant="h5" sx={{ marginTop: 2 }}>
          No projects found
        </Typography>
      ) : (
        <Box sx={{ display: "flex", flexWrap: "wrap", gap: 2, marginTop: 2 }}>
          {projects.all.map((project) => (
            <Card sx={{ maxWidth: 345 }}>
              <CardMedia
                sx={{ height: 140 }}
                image={cardImg}
                title="green iguana"
              />
              <CardContent>
                <Typography gutterBottom variant="h5" component="div">
                  {project.name}
                </Typography>
                <Typography variant="body2" sx={{ color: "text.secondary" }}>
                  Lorem ipsum dolor sit amet, consectetur adipiscing elit.
                  Quisque
                </Typography>
              </CardContent>
              <CardActions
                sx={{ float: "right" }}
                onClick={() => handleProjectClick(project.id)}
              >
                <Button variant="contained">View</Button>
              </CardActions>
            </Card>
          ))}
        </Box>
      )}
    </Box>
  );
};

export default Projects;
