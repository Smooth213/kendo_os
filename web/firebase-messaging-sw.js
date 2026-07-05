importScripts('https://www.gstatic.com/firebasejs/10.8.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.8.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: "AIzaSyCAL6MtoCV6s5RAD6cOAr4QO4bVEZd7OnQ",
  appId: "1:779304236953:web:a46a5e18d8a2913f404508",
  messagingSenderId: "779304236953",
  projectId: "kendo-os",
  authDomain: "kendo-os.firebaseapp.com",
  storageBucket: "kendo-os.firebasestorage.app"
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
