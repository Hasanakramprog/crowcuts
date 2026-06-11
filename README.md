# ✂️ Crown Cuts - Premium Barber Shop Management

![Crown Cuts Banner](https://img.shields.io/badge/Status-Active-brightgreen?style=for-the-badge)
![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)
![Firebase](https://img.shields.io/badge/firebase-%23039BE5.svg?style=for-the-badge&logo=firebase)

A fully-featured, premium Barber Shop Management and Booking application built with **Flutter** and powered by **Firebase**. Designed with a luxurious UI/UX aesthetic, Crown Cuts seamlessly supports Light and Dark modes while offering dedicated interfaces for Customers, Barbers, and Administrators.

---

## 🌟 Key Features

### 1. 🧔 Customer App
- **Real-Time Booking:** View barber availability, select time slots, and instantly confirm appointments.
- **Service Selection:** Browse a curated catalog of services and add them to your cart.
- **Dynamic Theming:** Enjoy a stunning UI that flawlessly adapts to both Light and Dark modes with premium gold accents.
- **Appointment Tracking:** Manage upcoming and past appointments effortlessly.

### 2. 💈 Barber Dashboard
- **Schedule Management:** Easily view your daily bookings, monitor your earnings, and check your reviews.
- **Appointment Statuses:** Track appointments via clear "Pending", "In Progress", and "Done" statuses.
- **Streamlined Workflow:** A dedicated tabbed interface ensures barbers can focus purely on their craft.

### 3. 👑 Admin Panel
- **Complete Control:** Full suite of tools to manage barbers, services, and shop hours.
- **Accounting & Analytics:** View detailed financial breakdowns by barber and by service over custom date ranges.
- **Working Hours configuration:** Manage days off and individual barber shift lengths securely.
- **Live Overviews:** Instantly see pending and completed bookings for the day.

---

## 🎨 Premium UI/UX Design System
The app utilizes a strictly typed, central theme extension system (`AppColorsExtension`) avoiding hardcoded UI elements. This allows the app to cleanly switch between high-contrast light mode and a deep, luxurious dark mode while keeping signature gold highlights consistent across the entire application.

---

## 🚀 Tech Stack

*   **Frontend:** Flutter & Dart
*   **State Management:** Riverpod
*   **Routing:** GoRouter
*   **Backend / Database:** Firebase (Auth, Firestore)
*   **Animations:** flutter_animate

---

## ⚙️ Getting Started

### Prerequisites
- Flutter SDK (latest stable version)
- Dart SDK
- Firebase CLI installed and configured
- An active Firebase Project

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/Hasanakramprog/crowcuts.git
   cd crowcuts
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase:**
   Ensure your `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) are correctly placed in the project based on your Firebase console setup.

4. **Run the App:**
   ```bash
   flutter run
   ```

---

## 🛡️ License
This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for more details.

---

*Crafted with precision for the modern Barber Shop.*
