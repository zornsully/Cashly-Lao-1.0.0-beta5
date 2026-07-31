const fs = require('fs');
const path = require('path');
const {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} = require('@firebase/rules-unit-testing');

/**
 * Real Firestore Emulator rules-unit tests for ../firestore.rules —
 * previously absent from this repository entirely. Covers the
 * highest-risk categories named in the audit: unauthenticated/cross-user
 * denial, ownership enforcement, pinned/immutable fields, amount
 * validation, transfer currency validation, and default-deny for
 * anything not explicitly matched (including the server-only
 * `notificationState` collection).
 *
 * Not exhaustive of every field on every collection — see TODO.md for
 * what's intentionally left for a follow-up pass.
 */

let testEnv;

const ALICE = 'alice-uid';
const BOB = 'bob-uid';

beforeAll(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: 'cashly-lao-rules-test',
    firestore: {
      rules: fs.readFileSync(
        path.resolve(__dirname, '../firestore.rules'),
        'utf8',
      ),
      host: '127.0.0.1',
      port: 8080,
    },
  });
});

afterAll(async () => {
  await testEnv.cleanup();
});

afterEach(async () => {
  await testEnv.clearFirestore();
});

function aliceDb() {
  return testEnv.authenticatedContext(ALICE).firestore();
}
function bobDb() {
  return testEnv.authenticatedContext(BOB).firestore();
}
function anonDb() {
  return testEnv.unauthenticatedContext().firestore();
}

async function seedAliceProfile() {
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    await ctx
      .firestore()
      .collection('users')
      .doc(ALICE)
      .set({ uid: ALICE, email: 'alice@example.com' });
  });
}

async function seedAliceAccount(id, overrides = {}) {
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    await ctx
      .firestore()
      .doc(`users/${ALICE}/accounts/${id}`)
      .set({
        name: 'Cash',
        type: 'cash',
        balance: 100,
        currencyCode: 'LAK',
        icon: 'wallet',
        color: 'blue',
        isArchived: false,
        ...overrides,
      });
  });
}

describe('users/{userId}', () => {
  test('unauthenticated clients cannot read or write a profile doc', async () => {
    await seedAliceProfile();
    await assertFails(anonDb().collection('users').doc(ALICE).get());
    await assertFails(
      anonDb().collection('users').doc(ALICE).set({ uid: ALICE }),
    );
  });

  test("a signed-in user cannot read another user's profile doc", async () => {
    await seedAliceProfile();
    await assertFails(bobDb().collection('users').doc(ALICE).get());
  });

  test('a user can create their own profile doc only with a matching uid/email', async () => {
    await assertFails(
      bobDb()
        .collection('users')
        .doc(BOB)
        .set({ uid: ALICE, email: 'bob@example.com' }),
    );
  });
});

describe('accounts subcollection', () => {
  test("a user cannot read or write into another user's accounts", async () => {
    await seedAliceProfile();
    await seedAliceAccount('acc-1');

    await assertFails(
      bobDb().collection(`users/${ALICE}/accounts`).get(),
    );
    await assertFails(
      bobDb()
        .doc(`users/${ALICE}/accounts/acc-2`)
        .set({
          name: 'Hack',
          type: 'cash',
          balance: 0,
          currencyCode: 'LAK',
          icon: 'x',
          color: 'x',
          isArchived: false,
        }),
    );
  });

  test('an invalid account type is rejected on create', async () => {
    await seedAliceProfile();
    await assertFails(
      aliceDb()
        .doc(`users/${ALICE}/accounts/bad`)
        .set({
          name: 'Bad',
          type: 'not-a-real-type',
          balance: 0,
          currencyCode: 'LAK',
          icon: 'x',
          color: 'x',
          isArchived: false,
        }),
    );
  });

  test('currencyCode is pinned — an update cannot change it', async () => {
    await seedAliceProfile();
    await seedAliceAccount('acc-1');

    await assertFails(
      aliceDb()
        .doc(`users/${ALICE}/accounts/acc-1`)
        .set({
          name: 'Cash',
          type: 'cash',
          balance: 100,
          currencyCode: 'USD', // changed — must be rejected
          icon: 'wallet',
          color: 'blue',
          isArchived: false,
        }),
    );

    await assertSucceeds(
      aliceDb()
        .doc(`users/${ALICE}/accounts/acc-1`)
        .set({
          name: 'Cash renamed',
          type: 'cash',
          balance: 250,
          currencyCode: 'LAK', // unchanged — allowed
          icon: 'wallet',
          color: 'blue',
          isArchived: false,
        }),
    );
  });
});

describe('transactions subcollection', () => {
  test('a transfer between mismatched-currency accounts is rejected', async () => {
    await seedAliceProfile();
    await seedAliceAccount('lak-acc', { currencyCode: 'LAK' });
    await seedAliceAccount('usd-acc', { currencyCode: 'USD' });

    await assertFails(
      aliceDb()
        .collection(`users/${ALICE}/transactions`)
        .add({
          accountId: 'lak-acc',
          toAccountId: 'usd-acc',
          categoryId: '',
          type: 'transfer',
          amount: 10,
          date: new Date(),
          note: '',
        }),
    );
  });

  test('a transfer between same-currency accounts succeeds', async () => {
    await seedAliceProfile();
    await seedAliceAccount('lak-acc-1', { currencyCode: 'LAK' });
    await seedAliceAccount('lak-acc-2', { currencyCode: 'LAK' });

    await assertSucceeds(
      aliceDb()
        .collection(`users/${ALICE}/transactions`)
        .add({
          accountId: 'lak-acc-1',
          toAccountId: 'lak-acc-2',
          categoryId: '',
          type: 'transfer',
          amount: 10,
          date: new Date(),
          note: '',
        }),
    );
  });

  test('a non-positive amount is rejected', async () => {
    await seedAliceProfile();
    await seedAliceAccount('acc-1');

    await assertFails(
      aliceDb()
        .collection(`users/${ALICE}/transactions`)
        .add({
          accountId: 'acc-1',
          toAccountId: '',
          categoryId: 'cat-1',
          type: 'expense',
          amount: 0,
          date: new Date(),
          note: '',
        }),
    );
  });
});

describe('budgets subcollection', () => {
  test('categoryId and month are pinned — an update cannot change either', async () => {
    await seedAliceProfile();
    const monthA = new Date('2026-01-01');
    const monthB = new Date('2026-02-01');
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx
        .firestore()
        .doc(`users/${ALICE}/budgets/cat-1_2026-01`)
        .set({
          categoryId: 'cat-1',
          month: monthA,
          limitAmount: 100000,
          currencyCode: 'LAK',
        });
    });

    await assertFails(
      aliceDb()
        .doc(`users/${ALICE}/budgets/cat-1_2026-01`)
        .set({
          categoryId: 'cat-2', // changed — rejected
          month: monthA,
          limitAmount: 100000,
          currencyCode: 'LAK',
        }),
    );
    await assertFails(
      aliceDb()
        .doc(`users/${ALICE}/budgets/cat-1_2026-01`)
        .set({
          categoryId: 'cat-1',
          month: monthB, // changed — rejected
          limitAmount: 100000,
          currencyCode: 'LAK',
        }),
    );
    await assertSucceeds(
      aliceDb()
        .doc(`users/${ALICE}/budgets/cat-1_2026-01`)
        .set({
          categoryId: 'cat-1',
          month: monthA,
          limitAmount: 150000, // changed — allowed
          currencyCode: 'LAK',
        }),
    );
  });
});

describe('savingsGoals subcollection (audit fix: previously untested entirely)', () => {
  test("a user cannot read another user's savings goals", async () => {
    await seedAliceProfile();
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx
        .firestore()
        .doc(`users/${ALICE}/savingsGoals/goal-1`)
        .set({
          name: 'New phone',
          targetAmount: 500,
          accountId: 'acc-1',
          icon: 'x',
          color: 'x',
          isArchived: false,
          autoContributionAmount: 0,
          autoContributionFrequency: '',
          lastContributionAt: new Date(),
        });
    });

    await assertFails(
      bobDb().collection(`users/${ALICE}/savingsGoals`).get(),
    );
  });

  test('accountId is pinned — an update cannot repoint the goal', async () => {
    await seedAliceProfile();
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx
        .firestore()
        .doc(`users/${ALICE}/savingsGoals/goal-1`)
        .set({
          name: 'New phone',
          targetAmount: 500,
          accountId: 'acc-1',
          icon: 'x',
          color: 'x',
          isArchived: false,
          autoContributionAmount: 0,
          autoContributionFrequency: '',
          lastContributionAt: new Date(),
        });
    });

    await assertFails(
      aliceDb()
        .doc(`users/${ALICE}/savingsGoals/goal-1`)
        .set({
          name: 'New phone',
          targetAmount: 500,
          accountId: 'acc-2', // changed — rejected
          icon: 'x',
          color: 'x',
          isArchived: false,
          autoContributionAmount: 0,
          autoContributionFrequency: '',
          lastContributionAt: new Date(),
        }),
    );
  });

  test('a non-positive target amount is rejected on create', async () => {
    await seedAliceProfile();
    await assertFails(
      aliceDb()
        .doc(`users/${ALICE}/savingsGoals/goal-bad`)
        .set({
          name: 'Bad goal',
          targetAmount: 0,
          accountId: 'acc-1',
          icon: 'x',
          color: 'x',
          isArchived: false,
          autoContributionAmount: 0,
          autoContributionFrequency: '',
          lastContributionAt: new Date(),
        }),
    );
  });
});

describe('smartMoneyScores subcollection (audit fix: previously untested entirely)', () => {
  const scoreId = '2026-01_LAK';

  async function seedScore() {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx
        .firestore()
        .doc(`users/${ALICE}/smartMoneyScores/${scoreId}`)
        .set({
          monthStart: new Date('2026-01-01'),
          monthKey: '2026-01',
          currencyCode: 'LAK',
          openingBalance: 1000,
          baselineState: 'reliable',
          baselineNote: 'ok',
          createdAt: new Date(),
          updatedAt: new Date(),
          latestCalculation: { totalScore: 80 },
        });
    });
  }

  test('deletion is always denied, even to the owner', async () => {
    await seedAliceProfile();
    await seedScore();
    await assertFails(
      aliceDb().doc(`users/${ALICE}/smartMoneyScores/${scoreId}`).delete(),
    );
  });

  test('opening fields are pinned — only updatedAt/latestCalculation may change', async () => {
    await seedAliceProfile();
    await seedScore();

    await assertFails(
      aliceDb()
        .doc(`users/${ALICE}/smartMoneyScores/${scoreId}`)
        .set({
          monthStart: new Date('2026-01-01'),
          monthKey: '2026-01',
          currencyCode: 'LAK',
          openingBalance: 999999, // changed — rejected
          baselineState: 'reliable',
          baselineNote: 'ok',
          createdAt: new Date(0),
          updatedAt: new Date(),
          latestCalculation: { totalScore: 10 },
        }),
    );
  });

  test("a user cannot read another user's Smart Money Scores", async () => {
    await seedAliceProfile();
    await seedScore();
    await assertFails(
      bobDb().doc(`users/${ALICE}/smartMoneyScores/${scoreId}`).get(),
    );
  });
});

describe('fcmTokens subcollection', () => {
  test('createdAt is pinned on update', async () => {
    await seedAliceProfile();
    const originalCreatedAt = new Date('2026-01-01');
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx
        .firestore()
        .doc(`users/${ALICE}/fcmTokens/token-abc`)
        .set({
          token: 'token-abc',
          platform: 'android',
          createdAt: originalCreatedAt,
          updatedAt: originalCreatedAt,
        });
    });

    await assertFails(
      aliceDb()
        .doc(`users/${ALICE}/fcmTokens/token-abc`)
        .set({
          token: 'token-abc',
          platform: 'android',
          createdAt: new Date(), // changed — rejected
          updatedAt: new Date(),
        }),
    );
  });
});

describe('notificationState subcollection (server-only)', () => {
  test('even the owner is denied read and write — Cloud Functions only', async () => {
    await seedAliceProfile();
    await assertFails(
      aliceDb().doc(`users/${ALICE}/notificationState/budget-alerts`).get(),
    );
    await assertFails(
      aliceDb()
        .doc(`users/${ALICE}/notificationState/budget-alerts`)
        .set({ anything: true }),
    );
  });
});

describe('default-deny catch-all', () => {
  test('an unlisted top-level collection is denied entirely', async () => {
    await assertFails(
      aliceDb().collection('somethingNotInTheSchema').add({ x: 1 }),
    );
  });
});
