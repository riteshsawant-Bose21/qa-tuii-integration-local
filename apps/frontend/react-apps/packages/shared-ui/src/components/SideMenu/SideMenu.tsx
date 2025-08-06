import React from 'react';
import Drawer from '@mui/material/Drawer';
import List from '@mui/material/List';
import ListItem from '@mui/material/ListItem';
import ListItemButton from '@mui/material/ListItemButton';
import ListItemIcon from '@mui/material/ListItemIcon';
import ListItemText from '@mui/material/ListItemText';
import Divider from '@mui/material/Divider';
import { styled } from '@mui/material/styles';
import { SideMenuProps } from './SideMenuModels';
import { Button, Typography } from '@mui/material';

const ThinDrawer = styled(Drawer)(({ theme }) => ({
    '& .MuiDrawer-paper': {
        paddingLeft: 8,
        paddingRight: 8,
        overflowX: 'hidden',
        boxSizing: 'border-box',
    },
}));

const SideMenu: React.FC<SideMenuProps> = ({
    sections,
    width = 72,
    title = '',
    logo,
    onLogoClick = () => { }
}) => {
    return (
        <ThinDrawer
            variant={'permanent'}
            sx={{ width: width }}
        >
            <Button onClick={onLogoClick} sx={{ mt: 1 }}>
                <img width={56} src={logo} />
            </Button>
            <Typography variant={'caption'} align={'center'} sx={{ height: '20px', maxWidth: '72px', mb: 1, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{title}</Typography>
            <Divider sx={{ mb: 1 }} />
            {sections && sections.map((section, sectionIndex) => (
                <React.Fragment key={sectionIndex}>

                    <List disablePadding
                        sx={{ pl: 1, pr: 1 }}
                    >
                        {section.items.map((item, itemIndex) => (
                            <ListItem
                                key={itemIndex}
                                disablePadding
                                sx={{ display: 'block', mb: 1 }}
                            >
                                <ListItemButton
                                    dense
                                    sx={{
                                        borderRadius: 2,
                                        flexDirection: 'column',
                                        width: 56
                                    }}
                                    onClick={item.onClick}
                                >
                                    <ListItemIcon
                                        sx={{
                                            minWidth: 0,
                                            justifyContent: 'center',
                                        }}
                                    >
                                        {item.icon}
                                    </ListItemIcon>
                                    <ListItemText
                                        primary={item.label}
                                        primaryTypographyProps={{
                                            variant: 'caption',
                                            textAlign: 'center',
                                            noWrap: true,
                                        }}
                                    />
                                </ListItemButton>
                            </ListItem>
                        ))}
                    </List>
                    {sectionIndex < sections.length - 1 && <Divider sx={{ mb: 1 }} />}
                </React.Fragment>
            ))}
        </ThinDrawer>
    );
};

export default SideMenu;
