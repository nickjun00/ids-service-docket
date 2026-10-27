const email = sessionStorage.getItem('ids-demo-email');
if (!email) {
  window.location.replace('index.html');
} else {
  const accountEmail = document.querySelector('#account-email');
  if (accountEmail) accountEmail.textContent = email;
}

document.querySelector('#sign-out').addEventListener('click', () => {
  sessionStorage.removeItem('ids-demo-email');
  window.location.replace('index.html');
});
