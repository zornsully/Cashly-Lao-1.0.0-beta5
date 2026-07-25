/**
 * A minimal in-memory stand-in for `firebase-admin`'s `Firestore`, scoped
 * to exactly the operations this project's Cloud Functions use: direct
 * doc get/set, whole-collection get, a handful of `where()` comparisons
 * (`==`, `>=`, `<`, `in`), `collectionGroup`, and batched deletes. Not a
 * general-purpose Firestore emulator — the equivalent, for this TS
 * package, of this repo's Dart tests using `fake_cloud_firestore` rather
 * than mocking `cloud_firestore` call-by-call.
 */

type WhereOp = '==' | '>=' | '<' | 'in';

interface WhereClause {
  field: string;
  op: WhereOp;
  value: unknown;
}

export class FakeDocumentSnapshot {
  constructor(
    public readonly id: string,
    public readonly ref: FakeDocumentReference,
    private readonly _data: Record<string, unknown> | undefined,
  ) {}

  get exists(): boolean {
    return this._data !== undefined;
  }

  data(): Record<string, unknown> | undefined {
    return this._data;
  }
}

export class FakeQuerySnapshot {
  constructor(public readonly docs: FakeDocumentSnapshot[]) {}

  get empty(): boolean {
    return this.docs.length === 0;
  }
}

export class FakeDocumentReference {
  constructor(
    private readonly store: FakeFirestore,
    public readonly path: string,
    public readonly id: string,
  ) {}

  get parent(): { parent: { id: string } | null } {
    const segments = this.path.split('/');
    // .../{collection}/{docId} -> parent collection -> its own parent doc.
    if (segments.length < 4) return { parent: null };
    const parentDocId = segments[segments.length - 3];
    return { parent: { id: parentDocId } };
  }

  collection(name: string): FakeCollectionReference {
    return new FakeCollectionReference(this.store, `${this.path}/${name}`);
  }

  async get(): Promise<FakeDocumentSnapshot> {
    return new FakeDocumentSnapshot(this.id, this, this.store.read(this.path));
  }

  async set(data: Record<string, unknown>): Promise<void> {
    this.store.write(this.path, { ...data });
  }

  async delete(): Promise<void> {
    this.store.delete(this.path);
  }
}

export class FakeCollectionReference {
  private readonly whereClauses: WhereClause[] = [];

  constructor(
    private readonly store: FakeFirestore,
    public readonly path: string,
  ) {}

  doc(id: string): FakeDocumentReference {
    return new FakeDocumentReference(this.store, `${this.path}/${id}`, id);
  }

  where(field: string, op: WhereOp, value: unknown): FakeCollectionReference {
    const next = new FakeCollectionReference(this.store, this.path);
    next.whereClauses.push(...this.whereClauses, { field, op, value });
    return next;
  }

  async get(): Promise<FakeQuerySnapshot> {
    const docs = this.store
      .docsUnder(this.path)
      .filter(({ data }) => this.whereClauses.every((clause) => matches(data, clause)))
      .map(({ id, path, data }) => new FakeDocumentSnapshot(id, new FakeDocumentReference(this.store, path, id), data));
    return new FakeQuerySnapshot(docs);
  }
}

class FakeCollectionGroup {
  private readonly whereClauses: WhereClause[] = [];

  constructor(
    private readonly store: FakeFirestore,
    private readonly collectionName: string,
  ) {}

  where(field: string, op: WhereOp, value: unknown): FakeCollectionGroup {
    const next = new FakeCollectionGroup(this.store, this.collectionName);
    next.whereClauses.push(...this.whereClauses, { field, op, value });
    return next;
  }

  async get(): Promise<FakeQuerySnapshot> {
    const docs = this.store
      .docsInCollectionGroup(this.collectionName)
      .filter(({ data }) => this.whereClauses.every((clause) => matches(data, clause)))
      .map(({ id, path, data }) => new FakeDocumentSnapshot(id, new FakeDocumentReference(this.store, path, id), data));
    return new FakeQuerySnapshot(docs);
  }
}

function matches(data: Record<string, unknown>, clause: WhereClause): boolean {
  const actual = data[clause.field];
  switch (clause.op) {
    case '==':
      return actual === clause.value;
    case '>=':
      return compareOrdered(actual, clause.value) >= 0;
    case '<':
      return compareOrdered(actual, clause.value) < 0;
    case 'in':
      return Array.isArray(clause.value) && clause.value.includes(actual);
  }
}

function compareOrdered(a: unknown, b: unknown): number {
  const aVal = toComparable(a);
  const bVal = toComparable(b);
  if (aVal < bVal) return -1;
  if (aVal > bVal) return 1;
  return 0;
}

// Duck-typed rather than `instanceof Timestamp` so tests can seed fixtures
// using the *real* `firebase-admin/firestore` Timestamp (which is a pure
// value type — no live Firestore connection needed to construct one) —
// this fake only ever needs to compare/store it, never construct one.
function toComparable(value: unknown): number {
  if (typeof value === 'number') return value;
  if (
    value !== null &&
    typeof value === 'object' &&
    'toMillis' in value &&
    typeof (value as { toMillis: unknown }).toMillis === 'function'
  ) {
    return (value as { toMillis: () => number }).toMillis();
  }
  throw new Error(`Unsupported comparable value in fake Firestore query: ${String(value)}`);
}

class FakeWriteBatch {
  private readonly deletes: FakeDocumentReference[] = [];

  delete(ref: FakeDocumentReference): void {
    this.deletes.push(ref);
  }

  async commit(): Promise<void> {
    for (const ref of this.deletes) await ref.delete();
  }
}

export class FakeFirestore {
  private readonly docs = new Map<string, Record<string, unknown>>();

  seed(path: string, data: Record<string, unknown>): void {
    this.docs.set(path, { ...data });
  }

  read(path: string): Record<string, unknown> | undefined {
    return this.docs.get(path);
  }

  write(path: string, data: Record<string, unknown>): void {
    this.docs.set(path, data);
  }

  delete(path: string): void {
    this.docs.delete(path);
  }

  docsUnder(collectionPath: string): { id: string; path: string; data: Record<string, unknown> }[] {
    const prefix = `${collectionPath}/`;
    const results: { id: string; path: string; data: Record<string, unknown> }[] = [];
    for (const [path, data] of this.docs.entries()) {
      if (!path.startsWith(prefix)) continue;
      const rest = path.slice(prefix.length);
      if (rest.includes('/')) continue; // a doc directly under this collection only
      results.push({ id: rest, path, data });
    }
    return results;
  }

  docsInCollectionGroup(
    collectionName: string,
  ): { id: string; path: string; data: Record<string, unknown> }[] {
    const results: { id: string; path: string; data: Record<string, unknown> }[] = [];
    for (const [path, data] of this.docs.entries()) {
      const segments = path.split('/');
      const collectionIndex = segments.length - 2;
      if (segments[collectionIndex] !== collectionName) continue;
      results.push({ id: segments[segments.length - 1], path, data });
    }
    return results;
  }

  collection(name: string): FakeCollectionReference {
    return new FakeCollectionReference(this, name);
  }

  collectionGroup(name: string): FakeCollectionGroup {
    return new FakeCollectionGroup(this, name);
  }

  batch(): FakeWriteBatch {
    return new FakeWriteBatch();
  }
}
