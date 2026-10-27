import { initializeApp } from 'https://www.gstatic.com/firebasejs/13.1.0/firebase-app.js';
import { getFirestore } from 'https://www.gstatic.com/firebasejs/13.1.0/firebase-firestore.js';

const firebaseConfig = {
  apiKey: 'AIzaSyC3qD3xTxGtyCY_CFeMA5gOSyMqyHFeCvE',
  authDomain: 'ids-service-docket.firebaseapp.com',
  projectId: 'ids-service-docket',
  storageBucket: 'ids-service-docket.firebasestorage.app',
  messagingSenderId: '373863538161',
  appId: '1:373863538161:web:f72f6f833799a59a1ef850',
  measurementId: 'G-WWQQ31KZ1H',
};

const app = initializeApp(firebaseConfig);
export const db = getFirestore(app);
