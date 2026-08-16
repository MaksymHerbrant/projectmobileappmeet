importScripts('https://www.gstatic.com/firebasejs/10.7.1/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.7.1/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: "AIzaSyBl6lOa94--Lyqb8sbcVJPJYAdAdeAZaXU",
  authDomain: "mateme-e68a6.firebaseapp.com",
  projectId: "mateme-e68a6",
  storageBucket: "mateme-e68a6.firebasestorage.app",
  messagingSenderId: "1081382433038",
  appId: "1:1081382433038:web:627c997362df4a73a5675f",
});

const messaging = firebase.messaging();

// Фонова обробка сповіщень
messaging.onBackgroundMessage((payload) => {
  console.log('Прийнято фонове повідомлення:', payload);
  const notificationTitle = payload.notification.title;
  const notificationOptions = {
    body: payload.notification.body,
    icon: '/firebase-logo.png'
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});