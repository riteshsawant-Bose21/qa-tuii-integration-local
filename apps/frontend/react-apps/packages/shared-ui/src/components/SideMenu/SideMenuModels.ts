export interface MenuItem {
    label: string;
    icon?: React.ReactNode;
    onClick?: () => void;
}

export interface MenuSection {
    items: MenuItem[];
}

export interface SideMenuProps {
    sections?: MenuSection[];
    width?: number;
    logo?: string;
    title?: string;
    onLogoClick?: () => void;
}
