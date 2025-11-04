import { initializeApp } from 'firebase/app';
import { getAuth } from 'firebase/auth';
import { getFirestore } from 'firebase/firestore';
import { getFunctions } from 'firebase/functions';

const firebaseConfig = {
    apiKey: "AIzaSyBeSp-YLbbPnEUrEdzro-4PS2TCg4JBQxg",
    authDomain: "madhwa-hackathon.firebaseapp.com",
    projectId: "madhwa-hackathon",
    storageBucket: "madhwa-hackathon.firebasestorage.app",
    messagingSenderId: "136044007781",
    appId: "1:136044007781:web:e5ad8af1ae652ae31c518c",
    measurementId: "G-SBR5LXLPHL"
};

const app = initializeApp(firebaseConfig);
export const auth = getAuth(app);
export const db = getFirestore(app);
export const functions = getFunctions(app);
