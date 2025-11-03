// src/components/Employee/MealSelection.js
import { useState, useEffect } from 'react';
import { db } from '../../firebase/config';
import { doc, getDoc, setDoc } from 'firebase/firestore';
import { useAuth } from '../../context/AuthContext';

const MealSelection = () => {
  const [menu, setMenu] = useState(null);
  const [selections, setSelections] = useState({
    breakfast: false,
    lunch: false,
    snacks: false
  });
  const [deadline, setDeadline] = useState(false);
  const { currentUser } = useAuth();

  useEffect(() => {
    fetchTomorrowMenu();
    checkDeadline();
    loadUserSelections();
  }, []);

  const fetchTomorrowMenu = async () => {
    const tomorrow = getTomorrowDate();
    const menuRef = doc(db, 'menus', tomorrow);
    const menuSnap = await getDoc(menuRef);
    if (menuSnap.exists()) {
      setMenu(menuSnap.data());
    }
  };

  const checkDeadline = () => {
    const now = new Date();
    const hour = now.getHours();
    setDeadline(hour >= 21); // After 9 PM
  };

  const handleSubmit = async () => {
    const tomorrow = getTomorrowDate();
    const selectionRef = doc(db, 'mealSelections', tomorrow, 'users', currentUser.uid);
    
    await setDoc(selectionRef, {
      ...selections,
      timestamp: new Date().toISOString(),
      userId: currentUser.uid
    });
    
    alert('Meal preferences saved!');
  };

  const getTomorrowDate = () => {
    const tomorrow = new Date();
    tomorrow.setDate(tomorrow.getDate() + 1);
    return tomorrow.toISOString().split('T')[0];
  };

  // ... render UI
};
