importScripts('https://www.gstatic.com/firebasejs/10.12.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.12.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyA1CZKSmxAPEDTi1KiAY5bZLKPvje-jl0c',
  authDomain: 'smartrev-4291b.firebaseapp.com',
  projectId: 'smartrev-4291b',
  storageBucket: 'smartrev-4291b.firebasestorage.app',
  messagingSenderId: '856339034594',
  appId: '1:856339034594:web:8fcd6b4ec33af1299089bb',
  measurementId: 'G-GZ71CS4T98',
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage(function (payload) {
  const notificationTitle = payload.notification.title;
  const notificationOptions = {
    body: payload.notification.body,
    icon: '/icons/Icon-192.png',
  };
  self.registration.showNotification(notificationTitle, notificationOptions);
});
