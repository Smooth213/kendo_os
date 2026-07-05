importScripts('https://www.gstatic.com/firebasejs/10.8.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.8.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: "AIzaSyAkV9sojMHGhFtwBTDAzUgx7qRxEWkWnRM",
  appId: "1:164010781926:web:55ac5f475727d7dc0d5f27",
  messagingSenderId: "164010781926",
  projectId: "kendo-os-beta",
  authDomain: "kendo-os-beta.firebaseapp.com",
  storageBucket: "kendo-os-beta.firebasestorage.app"
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Received background message ', payload);
  const notificationTitle = payload.notification?.title || '大会本部からのお知らせ';
  const notificationOptions = {
    body: payload.notification?.body || '',
    icon: '/favicon.png'
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});
