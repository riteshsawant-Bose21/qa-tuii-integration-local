import React from "react";
import { Breadcrumbs, Typography } from "@mui/material";
import NavigateNextIcon from "@mui/icons-material/NavigateNext";
import { Link } from "react-router-dom";

interface Breadcrumb {
  label: string;
  path?: string;
}
interface ProjectBreadCrumbProps {
  breadcrumbs: Breadcrumb[];
}

const ProjectBreadCrumb: React.FC<ProjectBreadCrumbProps> = ({
  breadcrumbs,
}) => {
  return (
    <Breadcrumbs
      separator={<NavigateNextIcon fontSize="small" />}
      aria-label="breadcrumb"
    >
      {breadcrumbs.map((breadcrumb, index) => {
        if (index === breadcrumbs.length - 1) {
          return (
            <Typography key={index} variant="h5" color="#000">
              {breadcrumb.label}
            </Typography>
          );
        }
        if (!breadcrumb.path) {
          return (
            <Typography key={index} variant="h5" color="#000">
              {breadcrumb.label}
            </Typography>
          );
        }
        return (
          <Link
            key={index}
            color="inherit"
            to={breadcrumb.path}
            style={{ color: "#000" }}
          >
            {breadcrumb.label}
          </Link>
        );
      })}
    </Breadcrumbs>
  );
};

export default ProjectBreadCrumb;
