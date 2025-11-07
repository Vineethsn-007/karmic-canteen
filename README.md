# 🍽️ Karmic Canteen – Smart Meal Management System

> 🥈 **2nd Prize Winner at Madhwa Hackathon**  
> An intelligent, multilingual, and socially impactful canteen management system powered by AI, RFID, and real-time analytics.

---

## ✨ Overview

**Karmic Canteen** is a modern meal management system designed to reduce food waste, simplify meal operations, and empower NGOs through surplus food distribution.  
Built with **React, Firebase, and Python ML models**, it integrates **RFID-based meal collection**, **multilingual interfaces**, and **AI-driven predictions** for smarter food management.

---

## 🌍 Key Features

### 🗣️ Multilingual Support
- Supports **English**, **Hindi**, and **Kannada**
- Instant language switching across the app
- Auto-detection of browser language preference
- Professionally translated UI content

### 🔐 Role-Based Access Control
| Role | Capabilities |
|------|---------------|
| **Employee** | Browse menu, select meals, view preferences |
| **Admin** | Manage menus, deadlines, and analytics |
| **NGO** | Track and collect surplus meals |
| **All Users** | Secure login via Firebase Authentication |

### 🤖 AI-Powered Intelligence
- Predicts next-day popular meals  
- Tracks eating patterns and preferences  
- Detects surplus food for donation  
- Generates weekly demand forecasts  

### 📱 RFID Meal Collection
- RFID card-based meal verification  
- Real-time meal tracking and updates  
- Prevents duplicate collection  
- Auto-syncs with inventory counts  

### 🌱 NGO Food Distribution
- Access real-time surplus inventory  
- Schedule food collection  
- Track social impact via reports  
- Secure and transparent management  

### 📊 Admin Dashboard
- **Menu Management:** Create, update, and publish menus  
- **Analytics & Reports:** Visualize meal data and patterns  
- **User Management:** Handle employee & NGO accounts  
- **Prediction Insights:** AI-based meal forecasts  
- **Deadline Control:** Set and manage meal selection cutoffs  

### 🎨 Modern UI/UX
- Professional **blue theme (#0066cc)**  
- Glassmorphism design with smooth animations  
- Fully responsive for desktop, tablet, and mobile  
- Accessible and user-friendly interface  

---

## 🛠️ Tech Stack

### Frontend
- **React 19.1.1** – UI framework  
- **Vite 7.1.12** – Lightning-fast build tool  
- **React Router 7.9.5** – Navigation  
- **i18next 25.6.0** – Internationalization  
- **Vanilla CSS + Variables** – Dynamic theming  

### Backend & Services
- **Firebase Authentication** – Secure login  
- **Firestore** – Real-time database  
- **Cloud Functions** – Serverless logic  
- **Python ML Models** – Predictive engine  
- **RFID Integration** – Hardware-based meal validation  

---

## 👥 User Workflows

### 👤 Employee
1. Login via Firebase  
2. View daily menu (auto in preferred language)  
3. Select meals before the deadline  
4. Scan RFID to collect meals  
5. View meal history and analytics  

### 👨‍💼 Admin
1. Manage menus and meal deadlines  
2. Monitor real-time analytics  
3. Generate reports and forecasts  
4. Track surplus food  
5. Manage employee & NGO accounts  

### 🤝 NGO Partner
1. View available surplus food  
2. Schedule collection  
3. Track distributed meals  
4. Generate impact reports  

---

## 🧩 Smart Features

- **Deadline Countdown:** Prevents late selections  
- **Duplicate Prevention:** RFID-based meal validation  
- **Real-time Updates:** Firestore-powered live sync  
- **AI Insights:** Predictive analytics for menu planning  

---

## 🔒 Security

- **Firebase Authentication:** Secure login  
- **Role-Based Access:** Controlled data access  
- **RFID Verification:** Hardware-level validation  
- **Firestore Rules:** Enforced database security  
- **Encrypted Data Transmission:** Safe communication  

---

## 📈 Performance & Accessibility

- ⚡ **Fast Load Times:** Vite-optimized build  
- 🔄 **Real-Time Updates:** Firestore sync  
- 📱 **Responsive:** Works seamlessly on all screens  
- ♿ **Accessible:** WCAG AA compliant  

---

## 🌐 Supported Languages

| Language | Code | Status |
|-----------|------|--------|
| English | en | ✅ Complete |
| Kannada | ka | ✅ Complete |
| Hindi | hi | ✅ Complete |

---

## 🚀 Getting Started

### Prerequisites
- Node.js **v16+**
- Firebase project setup  
- Python **3.8+** (for ML models)

### Installation

```bash
# Navigate to frontend directory
cd madhwa-hackathon/frontend

# Install dependencies
npm install

# Start the development server
npm run dev

# Build for production
npm run build
