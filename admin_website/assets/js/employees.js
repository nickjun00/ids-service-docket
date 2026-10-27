import { db } from './firebase.js';
import {
  addDoc,
  collection,
  deleteDoc,
  doc,
  getDocs,
  onSnapshot,
  query,
  where,
} from 'https://www.gstatic.com/firebasejs/13.1.0/firebase-firestore.js';

const accountsCollection = collection(db, 'accounts');
const employeeDialog = document.querySelector('#employee-dialog');
const deleteConfirmDialog = document.querySelector('#delete-confirm-dialog');
const deleteConfirmMessage = document.querySelector('#delete-confirm-message');
const employeeForm = document.querySelector('#employee-form');
const employeeName = document.querySelector('#employee-name');
const employeeEmail = document.querySelector('#employee-email');
const employeeFeedback = document.querySelector('#employee-feedback');
const employeeStatus = document.querySelector('#employee-status');
const employeePanel = employeeStatus.closest('.home-panel');
const employeeCount = document.querySelector('#employee-count');
const employeeEmpty = document.querySelector('#employee-empty');
const employeeTable = document.querySelector('#employee-table-wrap');
const employeeList = document.querySelector('#employee-list');
const addEmployeeButton = document.querySelector('#add-employee');
const snackbar = document.querySelector('#account-snackbar');
let employees = [];
let loaded = false;
let saving = false;
let snackbarTimeout;

function showSnackbar(message) {
  window.clearTimeout(snackbarTimeout);
  snackbar.textContent = message;
  snackbar.classList.add('is-visible');
  snackbarTimeout = window.setTimeout(() => {
    snackbar.classList.remove('is-visible');
  }, 3500);
}

function errorMessage(error, action) {
  console.error(`Firebase ${action} failed:`, error);
  const code = error?.code || 'unknown-error';
  const detail = error?.message || 'Firebase did not provide more details.';
  if (error?.code === 'permission-denied' || error?.code === 'unauthenticated') {
    return `Firebase rejected ${action} (${code}). Check that the published Firestore rules allow access to the accounts collection.`;
  }
  if (error?.code === 'unavailable' || error?.code === 'failed-precondition') {
    return `Firebase ${action} failed (${code}): ${detail}`;
  }
  return `Firebase ${action} failed (${code}): ${detail}`;
}

function renderEmployees() {
  employeeCount.textContent = `${employees.length} ${employees.length === 1 ? 'account' : 'accounts'}`;
  employeeEmpty.hidden = !loaded || employees.length > 0;
  employeeTable.hidden = employees.length === 0;
  employeeList.replaceChildren();

  for (const employee of employees) {
    const row = document.createElement('tr');
    for (const value of [employee.name, employee.email]) {
      const cell = document.createElement('td');
      cell.textContent = value;
      row.append(cell);
    }

    const actions = document.createElement('td');
    const deleteButton = document.createElement('button');
    deleteButton.type = 'button';
    deleteButton.className = 'compact-button delete-button';
    deleteButton.textContent = 'Delete';
    deleteButton.setAttribute('aria-label', `Delete account for ${employee.name} (${employee.email})`);
    deleteButton.addEventListener('click', () => deleteAccount(employee));
    actions.append(deleteButton);
    row.append(actions);
    employeeList.append(row);
  }
}

function showError(error, action) {
  employeeStatus.textContent = errorMessage(error, action);
}

function startAccountsListener() {
  employeePanel.classList.add('accounts-loading');
  employeeStatus.setAttribute('aria-busy', 'true');
  const spinner = document.createElement('span');
  spinner.className = 'employee-spinner';
  spinner.setAttribute('aria-hidden', 'true');
  const loadingLabel = document.createElement('span');
  loadingLabel.className = 'visually-hidden';
  loadingLabel.textContent = 'Loading accounts';
  employeeStatus.replaceChildren(spinner, loadingLabel);
  onSnapshot(accountsCollection, snapshot => {
    employees = snapshot.docs
      .map(account => ({ id: account.id, ...account.data() }))
      .filter(account => typeof account.name === 'string' && typeof account.email === 'string')
      .sort((a, b) => a.name.localeCompare(b.name));
    loaded = true;
    renderEmployees();
    employeePanel.classList.remove('accounts-loading');
    employeeStatus.setAttribute('aria-busy', 'false');
    employeeStatus.textContent = '';
  }, error => {
    loaded = false;
    employeePanel.classList.remove('accounts-loading');
    employeeStatus.setAttribute('aria-busy', 'false');
    employeeStatus.textContent = errorMessage(error, 'load accounts');
  });
}

async function deleteAccount(account) {
  if (!sessionStorage.getItem('ids-demo-email')) {
    window.location.replace('index.html');
    return;
  }
  deleteConfirmMessage.textContent = `Delete the account for ${account.name} (${account.email})?`;
  const confirmation = new Promise(resolve => {
    deleteConfirmDialog.addEventListener('close', () => {
      resolve(deleteConfirmDialog.returnValue === 'delete');
    }, { once: true });
  });
  deleteConfirmDialog.showModal();
  if (!await confirmation) return;

  try {
    await deleteDoc(doc(db, 'accounts', account.id));
    showSnackbar(`Account for ${account.name} has been deleted.`);
    addEmployeeButton.focus();
  } catch (error) {
    showError(error, 'delete account');
  }
}

addEmployeeButton.addEventListener('click', () => {
  employeeForm.reset();
  employeeFeedback.textContent = '';
  employeeName.setCustomValidity('');
  employeeDialog.showModal();
  employeeName.focus();
});

document.querySelector('#cancel-employee').addEventListener('click', () => employeeDialog.close());
employeeForm.addEventListener('input', () => {
  employeeName.setCustomValidity('');
  employeeFeedback.textContent = '';
});

employeeForm.addEventListener('submit', async event => {
  event.preventDefault();
  if (!sessionStorage.getItem('ids-demo-email')) {
    window.location.replace('index.html');
    return;
  }
  if (saving) return;

  const name = employeeName.value.trim();
  const email = employeeEmail.value.trim().toLowerCase();
  if (!name) {
    employeeName.setCustomValidity('Enter the account holder’s name.');
    employeeName.reportValidity();
    return;
  }
  if (!employeeForm.reportValidity()) return;

  saving = true;
  const submitButton = employeeForm.querySelector('[type="submit"]');
  const submitButtonLabel = submitButton.textContent;
  const submitButtonWidth = submitButton.getBoundingClientRect().width;
  submitButton.style.width = `${submitButtonWidth}px`;
  submitButton.disabled = true;
  const spinner = document.createElement('span');
  spinner.className = 'employee-spinner';
  spinner.setAttribute('aria-hidden', 'true');
  const savingLabel = document.createElement('span');
  savingLabel.className = 'visually-hidden';
  savingLabel.textContent = 'Saving account';
  submitButton.replaceChildren(spinner, savingLabel);
  employeeFeedback.textContent = '';

  try {
    const duplicateQuery = query(accountsCollection, where('email', '==', email));
    const duplicateSnapshot = await getDocs(duplicateQuery);
    if (!duplicateSnapshot.empty) {
      employeeFeedback.textContent = 'An account with this email address already exists.';
      employeeEmail.focus();
      return;
    }

    await addDoc(accountsCollection, {
      name,
      email,
      createdAt: new Date().toISOString(),
    });
    employeeDialog.close();
    showSnackbar(`${name} has been added.`);
  } catch (error) {
    employeeFeedback.textContent = errorMessage(error, 'save account');
  } finally {
    saving = false;
    submitButton.disabled = false;
    submitButton.textContent = submitButtonLabel;
    submitButton.style.width = '';
  }
});

renderEmployees();
startAccountsListener();
