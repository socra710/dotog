// Firebase Cloud Messaging Service Worker

importScripts(
  'https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js',
);
importScripts(
  'https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js',
);

// Firebase 설정 (firebase_options.dart의 웹 설정과 동일해야 함)
firebase.initializeApp({
  apiKey: 'AIzaSyCMrH9JC0VjqqOvqcCJ_6xfFNcdcLPPZOI',
  authDomain: 'dotog-26f44.firebaseapp.com',
  projectId: 'dotog-26f44',
  storageBucket: 'dotog-26f44.firebasestorage.app',
  messagingSenderId: '469497701352',
  appId: '1:469497701352:web:90e6c61fc5e30a89cf7481',
  measurementId: 'G-TZN5B5HDCX',
});

const messaging = firebase.messaging();

// 백그라운드 메시지 처리
messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] 백그라운드 메시지 수신:', payload);

  const notificationTitle = payload.notification?.title || 'DOTOG 알림';
  const notificationOptions = {
    body: payload.notification?.body || '',
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
  };

  return self.registration.showNotification(
    notificationTitle,
    notificationOptions,
  );
});
