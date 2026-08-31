# Screen Inventory & UI Component Catalog

**Project:** FitTrainer (Fitness Trainer Platform)  
**Version:** 1.0  
**Status:** MVP Specification & Stage 1 Screen Index  

---

## 1. Authentication & Onboarding Module

| Screen ID | Screen Name | Role Access | Primary Purpose | Key Widgets & Components |
| :--- | :--- | :--- | :--- | :--- |
| `AUTH-01` | **Splash Screen** | Public | Brand presentation & auth state router | Animated Logo, Tagline, Theme Loader, Auth Check |
| `AUTH-02` | **Login Screen** | Public | Phone / Social login entry | Mobile Number Input, Google Sign-In Button, Test Accounts Quick-Select |
| `AUTH-03` | **OTP Verification** | Public | 6-Digit code verification | PinCodeTextField, Countdown Timer, Resend Button, Auto-Fill Simulator |
| `AUTH-04` | **Role Selection** | New Users | Role onboarding gateway | Role Cards (`TRAINER`, `CLIENT`, `GYM_MANAGER`), Scope Descriptions |
| `AUTH-05` | **Trainer Onboarding Wizard**| Trainer | Multi-step profile setup | Bio Input, Specialization Chips, Certificate Uploader, Trial Banner |
| `AUTH-06` | **Client Onboarding Wizard** | Client | Health & fitness goal intake | Goal Selector, Fitness Level Slider, Medical Disclaimer, Sharing Toggle |

---

## 2. Trainer Module Screens

| Screen ID | Screen Name | Primary Purpose | Key Widgets & Components | Actions & Triggers |
| :--- | :--- | :--- | :--- | :--- |
| `TRN-01` | **Trainer Dashboard** | Command center & daily briefing | Today's Sessions Card, Active Client Counter, Pending Requests Banner, Revenue Card, Low-Credit Alerts | Tap session to start, view pending requests, quick action (+Workout) |
| `TRN-02` | **Trainer Profile** | View & edit professional profile | Avatar Uploader, Bio, Certifications List, QR Code Display, Trainer Code Share | Copy code, download QR, edit hourly rates |
| `TRN-03` | **Clients Roster** | List of all assigned clients | Search Bar, Filter Chips (Active, Expiring, Inactive), Client Summary Cards | Tap client $\to$ `TRN-04` |
| `TRN-04` | **Client Detail** | Single client 360 overview | Package Balance Badge, Next Scheduled Session, Quick Assign Workout, Action Tabs | View progress, view medical info, log session |
| `TRN-05` | **Client Progress View** | Review weight & body measurements | Interactive Line Charts (Weight/BMI), Measurement History Table, Photo Carousel | Add new measurement entry |
| `TRN-06` | **Client Personal Info** | Protected medical & intake data | Medical History, Injury Badges, Emergency Contact (Shielded if not opted-in) | Read-only with privacy lock indicator |
| `TRN-07` | **Calendar & Schedule** | Day/Week/Month schedule view | Interactive Timetable Grid, Booked Slot Blocks, Availability Overlay | Tap slot to view session, block off time |
| `TRN-08` | **Session Detail** | Manage specific booking | Client Card, Package Credit Tag, Status Pill, Session Notes Input | Start Session, Mark Completed, Cancel, Reschedule |
| `TRN-09` | **Workout Library** | Directory of workouts & programs | Workout Category Tabs, Assigned Workouts, Filter by Goal | Create Workout, Duplicate Template |
| `TRN-10` | **Exercise Library** | Global + Custom exercise catalog | Category Grid (Chest, Legs, Core), Muscle Filter, Search, Exercise Card | Tap to view instructions/media, Add Custom Exercise |
| `TRN-11` | **Workout Template Manager**| Pre-built reusable routines | Template Cards, Exercise Sequences, Target Sets/Reps Summary | Edit Template, Assign to Client |
| `TRN-12` | **Workout Builder** | Create/Edit workout routine | Reorderable Exercise List, Set/Rep/Weight Fields, Rest Timer Config | Add Exercise, Save Template, Assign Directly |
| `TRN-13` | **Package Management** | Create and manage offerings | Package Cards (Price, Sessions, Validity), Validity Multiplier Switch | Create New Package, Archive Package |
| `TRN-14` | **Payment Verification** | Review offline client payments | Pending Payment Queue, UPI Reference Card, Client Info | Approve Payment (Activates Package), Reject Payment |
| `TRN-15` | **Availability Settings**| Configure working hours & limits | Day-of-Week Schedule, Slot Capacity Stepper, Break Blocks | Save Schedule, Set Cancellation Policy Mode |
| `TRN-16` | **Trainer Requests** | Inbound consultation/connect leads| Request Cards, Client Goals, Intake Snippet | Accept Request, Decline Request |
| `TRN-17` | **Financial Dashboard** | Revenue metrics & payout history | Monthly Revenue Chart, Total Sessions Conducted, Pending Receivables | Filter by month/year, export statement |
| `TRN-18` | **Notifications Center** | In-app alerts & reminders | Notification Feed, Unread Badges, Filter by Event Type | Tap to navigate to related booking/payment |
| `TRN-19` | **Trainer Settings** | Preferences & theme control | Theme Toggle (Dark/Light), Notification Preferences, Trial Info | Change Theme, Reset Demo Data |

---

## 3. Client Module Screens

| Screen ID | Screen Name | Primary Purpose | Key Widgets & Components | Actions & Triggers |
| :--- | :--- | :--- | :--- | :--- |
| `CLI-01` | **Client Dashboard** | Daily fitness hub & active trainer | Next Session Countdown Card, Remaining Credits Gauge, Today's Workout Card | Start Workout, Book Session, View Trainer |
| `CLI-02` | **Trainer Discovery** | Browse verified fitness trainers | Search Bar, Filter Chips (Fat Loss, Strength), Trainer Cards with Ratings | Tap trainer $\to$ `CLI-04` |
| `CLI-03` | **Trainer Search / QR** | Search by unique code / QR scan | QR Scanner Viewfinder, 6-Character Trainer Code Input Box | Scan QR, Connect Directly |
| `CLI-04` | **Trainer Public Profile**| Trainer credentials & pricing | Bio, Certifications, Reviews Carousel, Packages List, Availability Preview | Click "Request Consultation" / "Connect" |
| `CLI-05` | **Consultation Request** | Initial interest & goal note | Goal Selection, Preferred Training Times, Notes to Trainer | Submit Request $\to$ Status PENDING |
| `CLI-06` | **Package Selection** | Select package after approval | Package Cards, Validity Mode Details, Session Price Breakdown | Select Package $\to$ `CLI-07` |
| `CLI-07` | **Payment Screen** | Trainer offline payment details | Trainer UPI ID Card, Copy Button, QR Code, Bank Details, Amount | Copy UPI, Click "I Have Paid" $\to$ `CLI-08` |
| `CLI-08` | **Payment Confirmation**| Enter payment transaction ID | UTR / Transaction Reference Input, Screenshot Upload (Optional) | Submit for Verification |
| `CLI-09` | **My Package & Credits** | Active packages & usage history | Credits Circular Progress Bar, Expiration Date Tag, Usage History List | View Past Packages, Renew Package |
| `CLI-10` | **Booking Calendar** | Book PT sessions with trainer | Date Picker Strip, Available Slot Chips, Capacity Indicator | Select Slot $\to$ Submit Booking Request |
| `CLI-11` | **Upcoming Workout View** | Review trainer assigned routine | Exercise List, Muscle Targets, Trainer Form Notes | Start Workout Session $\to$ `CLI-12` |
| `CLI-12` | **Active Workout Session**| Live interactive workout tracker | Set Checkboxes, Weight & Rep Input, Built-in Rest Stopwatch Timer | Complete Set, Finish Workout |
| `CLI-13` | **Own Workout Builder** | Client-created independent workout| Exercise Picker, Custom Set/Rep Config, "Own Workout" Zero-Credit Badge | Save & Log Workout |
| `CLI-14` | **Workout History** | Historical log of all workouts | Calendar Heatmap, Workout Summary Cards, Filter (PT vs Own) | Tap log to review detailed sets/reps |
| `CLI-15` | **Progress Overview** | Transformation dashboard | Weight Trend Chart, BMI Indicator, Body Metric Highlights | Log New Measurement $\to$ `CLI-16` |
| `CLI-16` | **Measurements Logger** | Record body circumference | Sliders/Inputs for Chest, Waist, Hips, Biceps, Thighs, Weight | Save Record |
| `CLI-17` | **Progress Photos** | Private photo gallery | Front / Side / Back Comparison Slider, Private Security Badge | Upload Photo (Mock) |
| `CLI-18` | **Trainer Review Modal** | Rate completed training | 5-Star Interactive Rating Bar, Written Feedback TextArea | Submit Review |
| `CLI-19` | **Client Notifications**| Reminders & status changes | Booking Confirmations, Workout Assignments, Credit Warnings | Tap notification to open screen |
| `CLI-20` | **Client Settings** | Personal profile & sharing privacy| Privacy Toggle ("Share info with trainer"), Theme Switcher | Update Profile, Switch Theme |

---

## 4. Gym Manager & Head Trainer Module Screens

| Screen ID | Screen Name | Role Access | Primary Purpose | Key Widgets & Components |
| :--- | :--- | :--- | :--- | :--- |
| `GYM-01` | **Gym Dashboard** | `GYM_MANAGER`, `HEAD_TRAINER` | Overview of gym metrics | Total Trainers, Active Clients, Sessions Today, Monthly Revenue |
| `GYM-02` | **Trainers Directory** | `GYM_MANAGER`, `HEAD_TRAINER` | Manage staff & roster | Trainer Cards, Active Clients per Trainer, Utilization Rate |
| `GYM-03` | **Head Trainer Console**| `HEAD_TRAINER` | Staff workout supervision | Trainer Workout Audits, Client Reassignment Button |
| `GYM-04` | **Gym Clients Roster** | `GYM_MANAGER`, `HEAD_TRAINER` | All gym-affiliated clients | Client Table, Assigned Trainer Chip, Reassign Action |
| `GYM-05` | **Client Reassignment**| `GYM_MANAGER`, `HEAD_TRAINER` | Transfer client between trainers | Source Trainer, Destination Trainer Dropdown, Reason Note |
| `GYM-06` | **Gym Master Calendar** | `GYM_MANAGER`, `HEAD_TRAINER` | Facility-wide session schedule | Multi-Trainer Schedule Grid, Room/Capacity Allocation |
| `GYM-07` | **Gym Packages** | `GYM_MANAGER`, `HEAD_TRAINER` | Standardized gym packages | Gym-wide Package Templates, Revenue Split Config |
| `GYM-08` | **Gym Financial Reports**| `GYM_MANAGER` | Financial breakdown | Revenue by Trainer, Package Sales Volume, Payout Ledger |
| `GYM-09` | **Gym Settings** | `GYM_MANAGER` | Gym business profile | Gym Name, Address, Operating Hours, Branding |

---

## 5. Super Admin Module Screens

| Screen ID | Screen Name | Role Access | Primary Purpose | Key Widgets & Components |
| :--- | :--- | :--- | :--- | :--- |
| `ADM-01` | **Admin Dashboard** | `SUPER_ADMIN` | Global platform health | Total Users, Active Trainers, Verified vs Unverified, Server Status |
| `ADM-02` | **User Management** | `SUPER_ADMIN` | Global user directory | Role Filter, Status Toggle (Active/Suspended), Search by Email |
| `ADM-03` | **Trainer Verification**| `SUPER_ADMIN` | Review & verify trainers | Certification Document Viewer, Approve / Reject Action Buttons |
| `ADM-04` | **Gym Organizations** | `SUPER_ADMIN` | Manage registered gyms | Gym List, Owner Details, Membership Counts |
| `ADM-05` | **Global Exercise Lib** | `SUPER_ADMIN` | Manage global exercises | Global Exercise Editor, Category Categorizer, Media Attachments |
| `ADM-06` | **Review Moderation** | `SUPER_ADMIN` | Moderate client reviews | Reported Reviews, Rating Breakdown, Delete / Publish Toggle |
| `ADM-07` | **Feature Flags Console**| `SUPER_ADMIN` | Runtime platform feature flags| Toggle Switches for 7 System Flags (Online Payments, Search, etc.) |
| `ADM-08` | **Trial Settings** | `SUPER_ADMIN` | Global trial configuration | Default Trial Duration (365 Days), Payment Requirement Toggle |
| `ADM-09` | **Test Account HUD** | `SUPER_ADMIN` / Dev | Instant role switcher bar | Floating Pill with 5 Role Buttons, Reset Seed Data Button |
