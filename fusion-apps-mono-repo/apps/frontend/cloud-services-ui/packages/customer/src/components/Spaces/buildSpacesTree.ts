import type { SpaceItem } from 'xyte-api';

export interface SpaceNode extends SpaceItem {
    children?: SpaceNode[];
}
export function buildSpacesTree(items: SpaceItem[]): SpaceNode[] {
    const map = new Map<number, SpaceNode>();

    items.forEach((item) => {
        map.set(item.id, { ...item, children: [] });
    });

    const roots: SpaceNode[] = [];

    map.forEach((node) => {
        if (node.parent_id) {
            const parentNode = map.get(node.parent_id);
            if (parentNode) {
                parentNode.children?.push(node);
            }
        } else {
            roots.push(node);
        }
    });

    return roots;
}
