# FitTrainer Platform

> **A trainer-first fitness management platform** engineered for independent personal trainers, with native architectural support for future gym-based organizations, head trainers, trainers, and clients.

---

## 📁 Repository Structure

```
├── docs/
│   ├── product-spec-v1.json       # Complete machine-readable product specification & schema
│   ├── business-rules.md          # Core platform policies, credit rules, and constraints
│   └── user-flows.md              # Detailed end-to-end user journeys and state diagrams
│
├── app/                           # Application source code (Frontend & Backend)
│
└── README.md                      # Project documentation and architectural overview
```

---

## 🚀 Tech Stack & Recommendations

| Layer | Recommended Technology | Purpose |
| :--- | :--- | :--- |
| **Mobile & Web Frontend** | [Flutter](https://flutter.dev/) | Cross-platform mobile-first app (iOS & Android) with responsive web support. |
| **Backend & Authentication** | [Supabase](https://supabase.com/) | Auth, Realtime updates, Row Level Security (RLS), and REST/GraphQL APIs. |
| **Database** | [PostgreSQL](https://www.postgresql.org/) | Relational database with fine-grained role-based policies. |
| **Storage** | [Supabase Storage](https://supabase.com/storage) | Secure media storage for progress photos, certification documents, and exercise demos. |
| **Web Deployment** | [Vercel](https://vercel.com/) | Web dashboard hosting and edge routing. |

---

## 🌟 Core System Highlights

- **Trainer-First Philosophy**: Independent trainers manage their clients, packages, availability, and workout programs without mandatory gym dependencies.
- **Gym & Head Trainer Governance**: Multi-tenant gym organizations allow Head Trainers to oversee trainers, reassign clients, and track gym-wide performance.
- **Flexible Package & Validity Engine**: Dynamic validity calculations (e.g., $4\times$ or $3\times$ session count) and custom expiration dates.
- **Fair Credit Consumption**: Completed sessions deduct 1 credit; client self-workouts ("Own Workouts") are strictly free of credit deduction.
- **Configurable Cancellation Policies**: Trainers configure grace periods (No penalty, 4-hour window, or custom rules).
- **Extensive Exercise & Workout Suite**: Global exercise library + custom trainer exercises with set, rep, RPE, and weight logging.
- **Role-Based Privacy**: Medical data, client body metrics, and progress photos are protected by database-level Row Level Security (RLS).

---

## 📚 Documentation Index

1. [**Product Specification (v1.0 JSON)**](docs/product-spec-v1.json) – The comprehensive 1,300+ line specification detailing database entities, API endpoints, feature flags, test accounts, and acceptance criteria.
2. [**Business Rules & Policies**](docs/business-rules.md) – The definitive guide to roles, credit deduction logic, booking preconditions, cancellation cutoff rules, and organization models.
3. [**User Flows & State Diagrams**](docs/user-flows.md) – Step-by-step visual flows covering Auth, Trainer & Client Onboarding, Package Purchase, Booking Lifecycles, and Gym Management.

---

## 👥 Platform Roles

- **Super Admin**: Global control, feature flags, platform analytics, system audits.
- **Gym Manager**: Gym business configuration, membership oversight, revenue reporting.
- **Head Trainer**: Trainer roster management, gym-wide package templates, client reassignment.
- **Trainer**: Client management, scheduling, custom packages, workout programming, progress reviews.
- **Client**: Trainer discovery, booking, workout execution & logging ("Own Workouts" vs "PT Sessions"), body metric tracking.

---

## 🛠️ Next Steps

1. Review the detailed specifications in the [`docs/`](docs/) folder.
2. Initialize the application frontend/backend inside the [`app/`](app/) directory.
