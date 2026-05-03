import type { StoreAdminFuelProductTreeNodeDto } from './models/store-admin-fuel-product.models';

/** Flat rows for parent `<select>` (indented labels). */
export function flattenFuelProductTreeForSelect(
  nodes: StoreAdminFuelProductTreeNodeDto[],
  depth = 0,
): { id: number; label: string }[] {
  const rows: { id: number; label: string }[] = [];
  const indent = depth === 0 ? '' : `${'  '.repeat(depth - 1)}└ `;
  for (const n of nodes) {
    rows.push({ id: n.id, label: `${indent}${n.code} — ${n.name}` });
    if (n.children?.length) {
      rows.push(...flattenFuelProductTreeForSelect(n.children, depth + 1));
    }
  }
  return rows;
}

/** `productId` → `parentId` for cycle checks (matches backend walk map). */
export function parentMapFromTree(
  nodes: StoreAdminFuelProductTreeNodeDto[],
  map = new Map<number, number | null>(),
): Map<number, number | null> {
  for (const n of nodes) {
    map.set(n.id, n.parentId ?? null);
    if (n.children?.length) {
      parentMapFromTree(n.children, map);
    }
  }
  return map;
}

export function findTreeNode(
  nodes: StoreAdminFuelProductTreeNodeDto[],
  id: number,
): StoreAdminFuelProductTreeNodeDto | null {
  for (const n of nodes) {
    if (n.id === id) {
      return n;
    }
    if (n.children?.length) {
      const f = findTreeNode(n.children, id);
      if (f) {
        return f;
      }
    }
  }
  return null;
}

/** All ids in the subtree rooted at `node` (including `node.id`). */
export function collectSubtreeIds(node: StoreAdminFuelProductTreeNodeDto): Set<number> {
  const ids = new Set<number>([node.id]);
  for (const c of node.children ?? []) {
    for (const id of collectSubtreeIds(c)) {
      ids.add(id);
    }
  }
  return ids;
}

/** Mirrors backend `ParentWouldCreateCycle` for UX before save. */
export function parentWouldCreateCycle(
  nodeId: number,
  newParentId: number,
  parentByProductId: Map<number, number | null>,
): boolean {
  if (newParentId === nodeId) {
    return true;
  }
  let walk = newParentId;
  for (let i = 0; i < 10_000; i++) {
    if (walk === nodeId) {
      return true;
    }
    const p = parentByProductId.get(walk);
    if (p === undefined || p === null) {
      return false;
    }
    walk = p;
  }
  return true;
}
