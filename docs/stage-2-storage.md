# FitTrainer (myPT) — Stage 2 Storage & Media Architecture

**Project:** FitTrainer (Fitness Trainer Platform)  
**Storage Engine:** Supabase Storage (Private S3 Buckets)  
**Date:** August 31, 2026  

---

## 1. Storage Bucket Configuration

FitTrainer uses private storage buckets with strict RLS storage policies:

| Bucket Name | Privacy Level | Purpose | Max Size | Allowed MIME Types |
| :--- | :--- | :--- | :--- | :--- |
| `progress-photos` | **PRIVATE** | Client body check-in photos (Front, Side, Back) | 10 MB | `image/jpeg`, `image/png`, `image/webp` |
| `trainer-certificates`| **PUBLIC / AUTH** | Trainer certification verification documents | 15 MB | `application/pdf`, `image/*` |
| `payment-receipts` | **PRIVATE** | Offline UPI payment screenshots | 5 MB | `image/*` |

---

## 2. Storage RLS Policies & Signed URLs

- **HIPAA / Privacy Rule:** `progress-photos` objects are stored at `user_id/measurement_id/pose.jpg`.
- **Signed URL Access:** Client photos are retrieved using **Expiring Signed URLs** (valid for 15 minutes), ensuring zero public image URL leakage.
- **Coach Access:** A coach can generate signed URLs for a client's progress photos **only if** `share_personal_info_with_trainer = TRUE` and an active relationship exists.
