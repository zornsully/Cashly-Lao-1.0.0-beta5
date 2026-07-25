import { initializeApp } from 'firebase-admin/app';
import { setGlobalOptions } from 'firebase-functions/v2';

initializeApp();
setGlobalOptions({ maxInstances: 10 });

export { onTransactionWrite } from './budget/onTransactionWrite';
export { onBudgetWrite } from './budget/onBudgetWrite';
export { onAccountWrite } from './account/onAccountWrite';
export { checkGoalReminders } from './goals/checkGoalReminders';
export { onUserDeleted } from './cleanup/onUserDeleted';
