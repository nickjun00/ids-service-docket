// Change this value when the authorized administrator email changes.
const ALLOWED_EMAIL = 'admin@megascreen.com.my';
// Temporary development code; no email is sent.
const DEMO_OTP = '888888';

const form = document.querySelector('#login-form');
const emailInput = document.querySelector('#email');
const feedback = document.querySelector('#email-feedback');
const brand = document.querySelector('.brand');

emailInput.addEventListener('input', () => {
  emailInput.removeAttribute('aria-invalid');
  feedback.textContent = '';
  feedback.classList.remove('success');
});

form.addEventListener('submit', (event) => {
  event.preventDefault();
  const email = emailInput.value.trim().toLowerCase();

  if (email !== ALLOWED_EMAIL) {
    emailInput.setAttribute('aria-invalid', 'true');
    feedback.classList.remove('success');
    feedback.textContent = `Use ${ALLOWED_EMAIL} to sign in to this demo.`;
    emailInput.focus();
    return;
  }

  emailInput.value = email;
  emailInput.removeAttribute('aria-invalid');
  document.querySelector('#otp-email').textContent = email;
  form.hidden = true;
  brand.hidden = true;
  otpForm.hidden = false;
  otpFeedback.textContent = '';
  otpFeedback.classList.add('success');
  digits[0].focus();
});

const otpForm = document.querySelector('#otp-form');
const otpFeedback = document.querySelector('#otp-feedback');
const digits = [...document.querySelectorAll('.otp-digit')];
const verifyButton = document.querySelector('#verify-button');

function updateVerification() {
  const complete = digits.every((digit) => /^[0-9]$/.test(digit.value));
  verifyButton.hidden = !complete;
  if (complete) otpForm.requestSubmit();
}

function fillDigits(value, index) {
  otpFeedback.textContent = '';
  digits.forEach((digit) => digit.removeAttribute('aria-invalid'));
  const numbers = value.replace(/\D/g, '').slice(0, digits.length - index);
  for (let offset = 0; offset < numbers.length; offset += 1) {
    digits[index + offset].value = numbers[offset];
  }
  if (numbers.length) digits[Math.min(index + numbers.length, digits.length - 1)].focus();
  updateVerification();
}

digits.forEach((input, index) => {
  input.addEventListener('input', () => {
    const value = input.value;
    input.value = '';
    fillDigits(value, index);
  });
  input.addEventListener('paste', (event) => {
    event.preventDefault();
    fillDigits(event.clipboardData.getData('text'), index);
  });
  input.addEventListener('focus', () => input.select());
  input.addEventListener('keydown', (event) => {
    if (event.key === 'Backspace' && !input.value && index > 0) {
      event.preventDefault();
      digits[index - 1].value = '';
      digits[index - 1].focus();
      updateVerification();
    } else if (event.key === 'ArrowLeft' && index > 0) {
      event.preventDefault();
      digits[index - 1].focus();
    } else if (event.key === 'ArrowRight' && index < digits.length - 1) {
      event.preventDefault();
      digits[index + 1].focus();
    }
  });
});

otpForm.addEventListener('submit', (event) => {
  event.preventDefault();
  if (!digits.every((digit) => /^[0-9]$/.test(digit.value))) return;
  const code = digits.map((digit) => digit.value).join('');
  if (code !== DEMO_OTP) {
    otpFeedback.classList.remove('success');
    otpFeedback.textContent = 'Incorrect code. Please try again.';
    digits.forEach((digit) => digit.setAttribute('aria-invalid', 'true'));
    digits[0].focus();
    return;
  }

  sessionStorage.setItem('ids-demo-email', emailInput.value.trim().toLowerCase());
  window.location.assign('home.html');
});

document.querySelector('#resend-otp').addEventListener('click', () => {
  otpFeedback.classList.add('success');
  otpFeedback.textContent = `Use ${DEMO_OTP} to continue. No email is sent in demo mode.`;
});

document.querySelector('#change-email').addEventListener('click', () => {
  otpForm.hidden = true;
  form.hidden = false;
  brand.hidden = false;
  otpForm.reset();
  verifyButton.hidden = true;
  emailInput.focus();
});
