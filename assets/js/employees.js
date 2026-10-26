const employeeStorageKey = 'ids-demo-employees';
const employeeDialog = document.querySelector('#employee-dialog');
const employeeForm = document.querySelector('#employee-form');
const employeeName = document.querySelector('#employee-name');
const employeeEmail = document.querySelector('#employee-email');
const employeeFeedback = document.querySelector('#employee-feedback');
const employeeStatus = document.querySelector('#employee-status');
let employees = [];
let employeeStorageReady = true;

try {
  const stored = JSON.parse(localStorage.getItem(employeeStorageKey) || '[]');
  if (!Array.isArray(stored) || !stored.every(employee => employee && typeof employee.name === 'string' && typeof employee.email === 'string')) {
    throw new Error('Invalid account data');
  }
  employees = stored;
} catch {
  employeeStorageReady = false;
  employeeStatus.textContent = 'Unable to load accounts. Please check browser storage and reload.';
}

function renderEmployees() {
  document.querySelector('#employee-count').textContent = `${employees.length} ${employees.length === 1 ? 'account' : 'accounts'}`;
  document.querySelector('#employee-empty').hidden = employees.length > 0 || !employeeStorageReady;
  document.querySelector('#employee-table-wrap').hidden = employees.length === 0;
  const list = document.querySelector('#employee-list');
  list.replaceChildren();
  employees.forEach(employee => {
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
    list.append(row);
  });
}

function deleteAccount(account) {
  if (!sessionStorage.getItem('ids-demo-email')) {
    window.location.replace('index.html');
    return;
  }
  if (!window.confirm(`Delete the account for ${account.name} (${account.email})?`)) return;
  const updatedEmployees = employees.filter(employee => employee !== account);
  try {
    localStorage.setItem(employeeStorageKey, JSON.stringify(updatedEmployees));
  } catch {
    employeeStatus.textContent = 'Unable to delete. Please allow browser storage and try again.';
    return;
  }
  employees = updatedEmployees;
  renderEmployees();
  employeeStatus.textContent = `Account for ${account.name} has been deleted.`;
  document.querySelector('#add-employee').focus();
}

document.querySelector('#add-employee').addEventListener('click', () => {
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

employeeForm.addEventListener('submit', event => {
  event.preventDefault();
  if (!sessionStorage.getItem('ids-demo-email')) {
    window.location.replace('index.html');
    return;
  }
  const name = employeeName.value.trim();
  const email = employeeEmail.value.trim().toLowerCase();
  if (!name) {
    employeeName.setCustomValidity('Enter the account holder’s name.');
    employeeName.reportValidity();
    return;
  }
  if (!employeeForm.reportValidity()) return;
  if (!employeeStorageReady) {
    employeeFeedback.textContent = 'Unable to save until account storage is available. Please reload and try again.';
    return;
  }
  if (employees.some(employee => employee.email.toLowerCase() === email)) {
    employeeFeedback.textContent = 'An account with this email address already exists.';
    employeeEmail.focus();
    return;
  }
  const updatedEmployees = [...employees, { name, email }];
  try {
    localStorage.setItem(employeeStorageKey, JSON.stringify(updatedEmployees));
  } catch {
    employeeFeedback.textContent = 'Unable to save. Please allow browser storage and try again.';
    return;
  }
  employees = updatedEmployees;
  renderEmployees();
  employeeDialog.close();
  employeeStatus.textContent = `${name} has been added.`;
});

renderEmployees();
