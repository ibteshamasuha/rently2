# Rently (CSE 2100 Project)

Rently is a comprehensive Flutter-based apartment rental management application designed to streamline the rental experience for both landlords and tenants. Powered by Firebase (Authentication, Firestore, and Storage), Rently offers a secure, scalable, and user-friendly platform for managing properties, maintenance requests, lease agreements, and communications.

## 🌟 Key Features

### For Tenants
* **Apartment Discovery**: Browse available apartment listings with detailed descriptions, amenities, and photo galleries.
* **Rental Requests**: Apply for apartments directly through the app and track the status of your rental requests.
* **Maintenance Ticketing**: Submit maintenance requests (Plumbing, Electrical, HVAC, etc.) with attached photos from your device gallery.
* **In-App Notifications**: Receive instant pop-up alerts for important notices, lease approvals, and maintenance updates.
* **Rent Tracking**: Keep track of your rent payment records for your active tenancy.

### For Landlords
* **Property Management**: Create, edit, and manage apartment listings. Upload multiple high-resolution photos securely via Firebase Storage.
* **Applicant Screening**: Review rental applications and approve or reject prospective tenants.
* **Maintenance Dashboard**: Oversee tenant maintenance tickets, view attached photo evidence, and update task statuses (Pending, In Progress, Completed).
* **Targeted Notices**: Publish announcements and notices to all tenants, specific individuals, or entire apartment complexes.
* **Rent Management**: Log and track rent payments for all managed properties.

## 🛠️ Technology Stack
* **Frontend**: [Flutter](https://flutter.dev/) (Dart)
* **Backend Platform**: [Firebase](https://firebase.google.com/)
  * **Authentication**: Secure user login and role-based access control (Tenant, Landlord, Admin).
  * **Cloud Firestore**: Real-time NoSQL database for structured app data (Apartments, Requests, Notices, Users).
  * **Firebase Storage**: Cloud storage for high-resolution images and attachments.

## 🚀 Getting Started

### Prerequisites
* Flutter SDK (latest stable version)
* Dart SDK
* A connected Firebase Project (Authentication, Firestore, Storage enabled)

### Installation
1. Clone the repository:
   ```bash
   git clone https://github.com/ibteshamasuha/rently2.git
   ```
2. Navigate to the project directory:
   ```bash
   cd rently2
   ```
3. Install dependencies:
   ```bash
   flutter pub get
   ```
4. Run the app:
   ```bash
   flutter run
   ```

## 🔐 Firebase Security Rules
The application relies on robust Firestore security rules to ensure that:
* Tenants can only access their own rental records, notices, and maintenance requests.
* Landlords have exclusive access to manage their properties and applicants.
* Unauthorized data manipulation is strictly blocked.

---
*Developed as part of the CSE 2100 curriculum.*