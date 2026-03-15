# 🏗 BuildTrack – Construction Management App

BuildTrack is a modern **Construction Management Application** built with Flutter.  
It helps contractors and site managers efficiently manage **workers, attendance, materials, payments, and reports** from a single dashboard.

The app simplifies daily construction operations by providing **real-time tracking, cost monitoring, and powerful insights** for better decision-making.

---

# ✨ Features

## 👷 Worker Management
- Add, edit, and manage workers
- Store labour details and contact information
- Track labour types (daily / hourly)

## 📅 Attendance Management
- Day-wise attendance tracking
- Mark **Present / Absent**
- Support for:
  - Full Day
  - Half Day
  - Overtime
- Smart pending worker list
- Daily, weekly, monthly filters

## 💰 Worker Payment System
- Attendance-based payment calculation
- Support for:
  - Hourly labour
  - Daily labour
- Overtime payment support
- Realtime payment tracking
- Pending payment calculation
- Payment history

## 🧱 Material Management
- Add and track construction materials
- Unit-based pricing support:
  - kg
  - litre
  - ton
  - piece
  - bag
- Automatic cost calculation
- Material usage tracking

## 📊 Reports & Analytics
- Construction analytics dashboard
- Labour cost reports
- Payment reports
- Material usage insights
- Daily / Weekly / Monthly filters

## 📈 Realtime Dashboard
- Worker statistics
- Attendance summary
- Labour cost tracking
- Material expense tracking
- Payment summaries

## 🔍 Search & Filters
Smart search across modules:

- Worker name  
- Material name  
- Amount  
- Phone number  

Filters supported:

- Daily
- Weekly
- Monthly

---

# 🚀 Tech Stack

| Technology | Purpose |
|------------|--------|
| Flutter | Cross-platform UI framework |
| Dart | Programming language |
| GetX | State management & navigation |
| Firebase Firestore | Realtime database |
| Material 3 | UI design system |

---

# 📱 Application Architecture

The project follows **clean architecture principles** for scalability and maintainability.


lib/
│
├── core
│ ├── constants
│ ├── helpers
│ └── utils
│
├── modules
│ ├── dashboard
│ ├── workers
│ ├── attendance
│ ├── materials
│ ├── payments
│ └── reports
│
├── services
├── repositories
├── models
└── widgets


Benefits:

- Scalable architecture  
- Easy maintenance  
- Clean separation of logic  
- Reusable components  

---

# 📊 Firestore Structure

Collections used:


workers
attendance
materials
payments


Example Attendance Record:


attendance
workerId
date
attendanceStatus
hoursWorked
overtimeAmount


---

# ⚡ Realtime Data Flow

The app uses **Firestore streams** to keep data updated instantly.


Attendance → Dashboard
Payments → Worker Summary
Materials → Cost Reports


All UI updates automatically without manual refresh.

---

# 🎨 UI Design

The application follows **Material 3 design principles** with:

- Clean card layouts
- Light theme UI
- Smooth animations
- Responsive layouts
- Professional dashboard design

---

# 📦 Installation

Clone the repository:


git clone https://github.com/your-repo/buildtrack.git


Install dependencies:


flutter pub get


Run the app:


flutter run


---

# 🧪 Testing

Run unit tests:


flutter test


Test coverage includes:

- Payment calculations  
- Attendance logic  
- Material cost calculations  
- Dashboard aggregations  

---

# 📌 Future Improvements

Planned upgrades:

- AI cost prediction
- Expense forecasting
- Export reports (PDF / Excel)
- Multi-project management
- Role-based access

---

# 👨‍💻 Author

**Satwinder Singh**  
Flutter Developer

---

# 📄 License

This project is created for **demonstration and client usage purposes**.
