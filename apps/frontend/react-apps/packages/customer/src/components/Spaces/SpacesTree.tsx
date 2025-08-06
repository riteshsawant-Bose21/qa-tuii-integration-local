import React from 'react';
import {
  Box,
  Typography,
  IconButton,
  Menu,
  MenuItem
} from '@mui/material';
import ExpandMoreIcon from '@mui/icons-material/ExpandMore';
import ChevronRightIcon from '@mui/icons-material/ChevronRight';
import MoreHorizIcon from '@mui/icons-material/MoreHoriz';
import type { SpaceNode } from './buildSpacesTree';
import AddIcon from '@mui/icons-material/Add';

interface SpacesTreeProps {
  nodes: SpaceNode[];
  onSpaceClick?: (space: SpaceNode) => void;
  onAddSubSpace?: (parentSpace: SpaceNode) => void;
}

export const SpacesTree: React.FC<SpacesTreeProps> = ({
  nodes,
  onSpaceClick,
  onAddSubSpace,
}) => {
  return (
    <Box sx={{ ml: 1 }}>
      {nodes.map((node) => (
        <TreeNode
          key={node.id}
          node={node}
          onSpaceClick={onSpaceClick}
          onAddSubSpace={onAddSubSpace}
        />
      ))}
    </Box>
  );
};

interface TreeNodeProps {
  node: SpaceNode;
  onSpaceClick?: (space: SpaceNode) => void;
  onAddSubSpace?: (parentSpace: SpaceNode) => void;
}

const TreeNode: React.FC<TreeNodeProps> = ({
  node,
  onSpaceClick,
  onAddSubSpace,
}) => {
  const [expanded, setExpanded] = React.useState(true);
  const [anchorEl, setAnchorEl] = React.useState<null | HTMLElement>(null);
  const [hovered, setHovered] = React.useState(false);
  const openMenu = Boolean(anchorEl);

  const hasChildren = node.children && node.children.length > 0;

  const toggleExpand = () => setExpanded((prev) => !prev);

  const handleNodeClick = () => {
    if (onSpaceClick) onSpaceClick(node);
  };

  const handleMenuOpen = (event: React.MouseEvent<HTMLElement>) => {
    event.stopPropagation(); // prevents toggling expand
    setAnchorEl(event.currentTarget);
  };
  const handleMenuClose = () => setAnchorEl(null);

  const handleAddSubSpace = () => {
    handleMenuClose();
    if (onAddSubSpace) onAddSubSpace(node);
  };

  return (
    <Box
      sx={{ mt: 1 }}
      onMouseEnter={() => setHovered(true)}
      onMouseLeave={() => setHovered(false)}
    >
      <Box sx={{ display: 'flex', alignItems: 'center' }}>
        {hasChildren ? (
          <IconButton size="small" onClick={toggleExpand} sx={{ mr: 1 }}>
            {expanded ? <ExpandMoreIcon fontSize="small" /> : <ChevronRightIcon fontSize="small" />}
          </IconButton>
        ) : (
          <Box sx={{ width: 24, mr: 1 }} />
        )}

        <Box
          sx={{ display: 'flex', alignItems: 'center', cursor: 'pointer' }}
          onClick={handleNodeClick}
        >
          <Typography variant="body2">{node.name}</Typography>
        </Box>

        <IconButton
          size="small"
          onClick={handleMenuOpen}
          sx={{
            ml: 'auto',
            visibility: hovered || openMenu ? 'visible' : 'hidden',
          }}
        >
          <MoreHorizIcon fontSize="small" />
        </IconButton>

        <Menu
          anchorEl={anchorEl}
          open={openMenu}
          onClose={handleMenuClose}
          onClick={(e) => e.stopPropagation()}
        >
          <MenuItem onClick={handleAddSubSpace}><AddIcon />Add New Space</MenuItem>
        </Menu>
      </Box>

      {hasChildren && expanded && (
        <SpacesTree
          nodes={node.children!}
          onSpaceClick={onSpaceClick}
          onAddSubSpace={onAddSubSpace}
        />
      )}
    </Box>
  );
};
