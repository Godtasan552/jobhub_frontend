# JobHub Frontend

**JobHub** คือแอปพลิเคชันหางาน/โพสต์งาน พัฒนาด้วย **Flutter** และจัดการ state ด้วย **GetX** โดยแอปนี้เชื่อมต่อกับ Backend ผ่าน REST API และ Socket เพื่อรองรับการแชทและการแจ้งเตือนแบบเรียลไทม์

---

## 📌 สถาปัตยกรรมโปรเจก

### 🗂️ โครงสร้างหลัก

```
lib/
├── main.dart                  # จุดเริ่มต้นของแอป
├── component/                 # Component UI ที่ใช้ซ้ำ
│   └── bottom_nav.dart        # Bottom Navigation Bar
├── controllers/               # GetX Controller จัดการ state
│   ├── auth_controller.dart   # การล็อกอิน/สมัครสมาชิก
│   ├── chat_controller.dart   # จัดการแชทและ socket connection
│   └── notification_controller.dart # จัดการการแจ้งเตือน
├── model/                     # Data Models
│   ├── application_model.dart # ข้อมูลการสมัครงาน
│   ├── job_model.dart         # ข้อมูลงาน
│   └── notification_model.dart# ข้อมูล Notification
├── routes/                    # การจัดการเส้นทาง (Routing)
│   ├── app_pages.dart
│   └── app_routes.dart
├── screens/                   # หน้าจอ UI หลักทั้งหมด
│   ├── chat.dart              # หน้าสนทนา (Chat)
│   ├── create_job.dart        # ฟอร์มโพสต์งานใหม่
│   ├── dashboard_Screen.dart  # Dashboard แสดงงานทั้งหมด
│   ├── edit_job_screen.dart   # แก้ไขโพสต์งาน
│   ├── forget_pass.dart       # ลืมรหัสผ่าน
│   ├── job_detail.dart        # ดูรายละเอียดงาน
│   ├── login.dart             # หน้าล็อกอิน
│   ├── my_posted_jobs_screen.dart # งานที่เราโพสต์ไว้
│   ├── my_posted_jobs_detail_screen.dart # รายละเอียดงานที่เราโพสต์
│   ├── notification_screen.dart        # รายการแจ้งเตือน
│   ├── notification_detail_screen.dart # รายละเอียดแจ้งเตือน
│   ├── profilePage.dart       # โปรไฟล์ผู้ใช้
│   ├── regis.dart             # หน้าสมัครสมาชิก
│   ├── splash_screen.dart     # Splash Screen
│   └── wallet.dart            # กระเป๋าเงินผู้ใช้
├── services/                  # จัดการ API และ Socket
│   ├── auth_service.dart      # Authentication API
│   ├── chat_service.dart      # จัดการข้อความ/ห้องแชท
│   ├── job_service.dart       # API สำหรับ Job CRUD
│   ├── notification_service.dart # API สำหรับ Notification
│   ├── socket_service.dart    # จัดการ Socket.IO
│   └── wallet_service.dart    # API กระเป๋าเงิน
├── utils/
│   └── navigation_helper.dart # Helper สำหรับการนำทาง
└── widgets/
    └── notification_badge.dart # Badge แสดงจำนวนแจ้งเตือน
```

---

## ✨ ฟีเจอร์หลักของแอป

1. **Authentication**

   * ลงทะเบียน, เข้าสู่ระบบ, ออกจากระบบ
   * จัดการ Token และ Session ด้วย `auth_service.dart` + `auth_controller.dart`

2. **งาน (Jobs)**

   * Dashboard แสดงงานทั้งหมด
   * ค้นหาและดูรายละเอียดงาน (`job_detail.dart`)
   * โพสต์งานใหม่ (`create_job.dart`)
   * แก้ไข/ลบงาน (`edit_job_screen.dart`)
   * จัดการงานที่เราโพสต์ (`my_posted_jobs_screen.dart`)

3. **การสมัครงาน**

   * มี `application_model.dart` จัดเก็บข้อมูลผู้สมัคร
   * เชื่อมต่อ API ผ่าน `job_service.dart`

4. **แชท (Real-time Chat)**

   * ใช้ `socket_service.dart` + `chat_controller.dart`
   * ส่งข้อความและรับข้อความทันที (`chat.dart`)

5. **การแจ้งเตือน (Notifications)**

   * ดึงข้อมูลแจ้งเตือนจาก API (`notification_service.dart`)
   * แสดง badge ที่ icon (`notification_badge.dart`)
   * เปิดอ่านรายละเอียดแจ้งเตือน (`notification_detail_screen.dart`)

6. **กระเป๋าเงิน (Wallet)**

   * จัดการธุรกรรมในแอป (`wallet_service.dart`, `wallet.dart`)

7. **โปรไฟล์ผู้ใช้**

   * ดู/แก้ไขข้อมูลส่วนตัว (`profilePage.dart`)

---

## 🔧 การติดตั้งและใช้งาน

1. ติดตั้ง dependencies

```bash
flutter pub get
```

2. รันโปรเจค

```bash
flutter run
```

3. เชื่อมต่อกับ Backend (API + Socket)

* กำหนดค่า endpoint ใน `services/` (auth_service, job_service, socket_service ฯลฯ)

---

## 🛠️ เทคโนโลยี

* Flutter (Dart)
* GetX (State Management)
* REST API (Job, Auth, Wallet, Notification)
* Socket.IO (Chat & Notification Real-time)
* intl (จัดรูปแบบวันที่/สกุลเงิน)

---

## 📌 Roadmap (สิ่งที่อาจทำเพิ่ม)

* การค้นหางานด้วย Filter ที่ละเอียดขึ้น
* ระบบรีวิว/เรตติ้งผู้ว่าจ้างและผู้สมัคร
* ระบบกระเป๋าเงินที่รองรับการจ่ายจริง
* Dark Mode

---

## 👨‍💻 ผู้พัฒนา

* **Frontend (Flutter + GetX)** : ทีม JobHub
* **Backend (REST API & Socket)** : ทีม JobHub

---
