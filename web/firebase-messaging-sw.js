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
  
  // 🛡️ 二重通知防止：通知ペイロード（notification）が最初から含まれている場合、
  // ブラウザがバックグラウンドで自動表示するため、ServiceWorker側での手動表示（showNotification）はスキップします。
  if (payload.notification) {
    return;
  }

  const notificationTitle = '大会本部からのお知らせ';
  const notificationOptions = {
    body: payload.data?.body || '',
    icon: '/favicon.png'
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});
