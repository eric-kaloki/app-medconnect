// filepath: /home/eric/Desktop/Flutter/MedConnect/web/firebase-messaging-sw.js
importScripts('https://www.gstatic.com/firebasejs/9.0.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.0.0/firebase-messaging-compat.js');

// Initialize Firebase in the service worker
firebase.initializeApp({
  apiKey: "AIzaSyB83LBRPQuMabzHsn2Mtucs9Y9xTeqzEJ0",
  authDomain: "mastermind-1a14c.firebaseapp.com",
  projectId: "mastermind-1a14c",
  storageBucket: "mastermind-1a14c.firebasestorage.app",
  messagingSenderId: "700062154047",
  appId: "1:700062154047:web:e538dfb97ceeeb190b678a",
  measurementId: "G-B7PQC9LYJJ",
});

const messaging = firebase.messaging();

// Handle background messages
messaging.onBackgroundMessage(function (payload) {
  console.log('[firebase-messaging-sw.js] Received background message ', payload);
  const notificationTitle = payload.notification.title;
  const notificationOptions = {
    body: payload.notification.body,
    icon: '/firebase-logo.png',
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});