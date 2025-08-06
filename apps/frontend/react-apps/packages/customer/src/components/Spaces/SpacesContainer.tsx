import { useEffect, useState } from 'react';
import {
    Box,
    TextField,
    Typography,
    InputAdornment,
    IconButton,
    Button,
    Dialog,
    DialogActions,
    DialogContent,
    DialogTitle
} from '@mui/material';
import SearchIcon from '@mui/icons-material/Search';
import AddIcon from '@mui/icons-material/Add';
import { buildSpacesTree, type SpaceNode } from './buildSpacesTree';
import { SpacesTree } from './SpacesTree';
import type { SpaceItem, SpacesResponse } from 'xyte-api';
import { useAppDispatch, useAppSelector } from '../../store/hooks';
import { selectSpace } from '../../store/features/spaces/spacesSlice';
import { createSpace, getSpaces } from '../../api/spaces';

type SpacesContainerProps = {
    onSpaceClick?: (space: SpaceNode) => void;
};

export default function SpacesContainer({ onSpaceClick }: SpacesContainerProps) {
    const dispatch = useAppDispatch();
    const spaces = useAppSelector((state) => state.spaces);
    const [allSpaces, setAllSpaces] = useState<SpaceNode[]>([]);
    const [filteredSpaces, setFilteredSpaces] = useState<SpaceNode[]>([]);
    const [parentId, setParentId] = useState<number>();
    const [search, setSearch] = useState('');
    const [error, setError] = useState('');
    const [loading, setLoading] = useState(false);
    const [open, setOpen] = useState(false);
    const [spaceName, setSpaceName] = useState('');

    async function loadData() {
        try {
            setLoading(true);
            setError('');

            const response: SpacesResponse = await getSpaces();
            const tree = buildSpacesTree(response?.items);
            setAllSpaces(tree);
            if (!spaces.selected) {
                dispatch(selectSpace({
                    id: tree[0]?.id,
                    name: tree[0]?.name,
                    parent_id: tree[0]?.parent_id,
                    config: tree[0]?.config,
                    path: tree[0]?.path
                } as SpaceItem))
            }
            setFilteredSpaces(tree);
        } catch (err) {
            console.error('Failed to load spaces', err);
            setError('Failed to load spaces');
        } finally {
            setLoading(false);
        }
    };
    useEffect(() => {
        loadData();
    }, []);

    useEffect(() => {
        if (!search.trim()) {
            setFilteredSpaces(allSpaces);
            return;
        }
        const lower = search.toLowerCase();

        const flattenNodes = (nodes: SpaceNode[]): SpaceNode[] => {
            let arr: SpaceNode[] = [];
            for (const node of nodes) {
                arr.push(node);
                if (node.children) {
                    arr = arr.concat(flattenNodes(node.children));
                }
            }
            return arr;
        };
        const allFlat = flattenNodes(allSpaces);

        const matchedIds = new Set<number>(
            allFlat
                .filter((n) => n.name.toLowerCase().includes(lower))
                .map((n) => n.id)
        );

        const filterTree = (nodes: SpaceNode[]): SpaceNode[] => {
            const res: SpaceNode[] = [];
            for (const node of nodes) {
                let children: SpaceNode[] = [];
                if (node.children) {
                    children = filterTree(node.children);
                }
                if (matchedIds.has(node.id) || children.length > 0) {
                    res.push({ ...node, children });
                }
            }
            return res;
        };

        setFilteredSpaces(filterTree(allSpaces));
    }, [search, allSpaces]);

    const handleClickNewSpace = () => {
        setParentId(undefined);
        setSpaceName('');
        setOpen(true);
    };

    const handleCreateSpace = async () => {
        if (!spaceName.trim()) return; // avoid empty names
        try {
            await createSpace({ name: spaceName.trim(), parent_id: parentId });
            setOpen(false);
            setParentId(undefined);
            loadData();
        } catch (err) {
            console.error('Failed to create space:', err);
            alert('Failed to create space');
        }
    };
    const handleSpaceClick = (space: SpaceNode) => {
        if (onSpaceClick) {
            // If a custom click handler was provided, call it
            onSpaceClick(space);
        } else {
            // Otherwise, do the default behavior (selectSpace dispatch)
            dispatch(selectSpace({
                id: space.id,
                name: space.name,
                parent_id: space.parent_id,
                path: space.path
            } as SpaceItem));
        }
    };

    const handleClose = () => {
        setOpen(false);
        setParentId
    };

    const handleAddSubSpace = (parentSpace: SpaceNode) => {
        setParentId(parentSpace.id);
        setSpaceName('');
        setOpen(true);
    };

    return (
        <Box sx={{ pt: 2, pl: 2, pr: 1 }} minWidth={'260px'}>
            <Box sx={{ display: 'flex', mb: 2, alignItems: 'center' }}>
                <TextField
                    label="Find space"
                    variant="outlined"
                    size="small"
                    fullWidth
                    value={search}
                    onChange={(e) => setSearch(e.target.value)}
                    slotProps={{
                        input: {
                            endAdornment: <InputAdornment position="end"><SearchIcon /></InputAdornment>,
                        },
                    }}
                />

                <IconButton
                    onClick={handleClickNewSpace}
                    sx={{ ml: 1 }}
                >
                    <AddIcon />
                </IconButton>
            </Box>

            {loading && <Typography>Loading spaces...</Typography>}
            {error && <Typography color="error">{error}</Typography>}
            {!loading && !error ? filteredSpaces.length > 0 ? (
                <SpacesTree
                    nodes={filteredSpaces}
                    onSpaceClick={handleSpaceClick}
                    onAddSubSpace={handleAddSubSpace}
                />
            ) : (
                <Typography>No matching spaces</Typography>
            ) : <></>}

            <Dialog open={open} onClose={handleClose}>
                <DialogTitle>Create New Space</DialogTitle>
                <DialogContent>
                    <TextField
                        autoFocus
                        margin="dense"
                        label="Space Name"
                        fullWidth
                        value={spaceName}
                        onChange={(e) => setSpaceName(e.target.value)}
                    />
                </DialogContent>
                <DialogActions>
                    <Button onClick={handleClose}>Cancel</Button>
                    <Button onClick={handleCreateSpace} variant="contained">
                        Create
                    </Button>
                </DialogActions>
            </Dialog>
        </Box>
    );
}
