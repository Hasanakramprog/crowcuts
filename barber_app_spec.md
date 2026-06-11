# Crown Cuts — Barber Shop App
## Complete Developer Specification

> **Purpose:** This document is the single source of truth for building the Crown Cuts Flutter application. It covers architecture, user roles, screens, flows, data models, animations, and accounting. Read it fully before writing any code.

---

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [Tech Stack](#2-tech-stack)
3. [User Roles](#3-user-roles)
4. [App Architecture](#4-app-architecture)
5. [Data Models](#5-data-models)
6. [Feature Modules](#6-feature-modules)
   - 6.1 Authentication
   - 6.2 Customer — Booking Flow
   - 6.3 Time Slot Engine
   - 6.4 Barber Screen
   - 6.5 Admin Panel
   - 6.6 Accounting System
   - 6.7 Ratings & Reviews
   - 6.8 Notifications
7. [Screen Inventory](#7-screen-inventory)
8. [Animations](#8-animations)
9. [Design System](#9-design-system)
10. [CRUD Operations Reference](#10-crud-operations-reference)
11. [Business Rules](#11-business-rules)
12. [Future Considerations](#12-future-considerations)

---

## 1. Project Overview

Crown Cuts is a multi-barber barbershop management and booking app built in Flutter. It serves three user types — customers, barbers, and admin — each with a dedicated experience.

**Core capabilities:**
- Customers browse barbers, select services, pick time slots, and confirm bookings
- Each barber has their own profile, service list with individual pricing and durations, working schedule, and rating
- Admin creates and manages barbers, services, pricing, schedules, and views full accounting
- Accounting tracks income by day, month, year, and custom date range — broken down by barber and service type
- Animated barber chair carousel for barber selection (signature UI moment)

---

## 2. Tech Stack

| Layer | Choice | Reason |
|---|---|---|
| Framework | Flutter (latest stable) | Cross-platform iOS + Android |
| State management | Riverpod | Scalable, testable, compile-safe |
| Backend | Firebase (Firestore + Auth + FCM) | Real-time slots, push notifications |
| Local storage | Hive | Offline caching of barber/service data |
| Navigation | GoRouter | Deep linking, role-based routing |
| Animations | flutter_animate + Rive | Page transitions + chair animation |
| Notifications | firebase_messaging + flutter_local_notifications | Booking confirmations + reminders |
| Charts | fl_chart | Accounting bar/line charts |
| PDF export | pdf + printing | Income report export |

> **Phase 1 (demo/prototype):** Run entirely with mock data using Riverpod providers. No Firebase calls. All data lives in a local `mock_data.dart` file. Firebase integration is Phase 2.

---

## 3. User Roles

### 3.1 Customer
A person who books appointments at the shop.

**Can:**
- Register and log in with email/phone
- Browse all barbers with their ratings and availability
- Select a barber and see their specific services, prices, and durations
- Pick one or more services in a single booking
- Choose a date and available time slot
- View and cancel upcoming bookings
- See their booking history
- Rate a barber after a completed appointment (once per visit)
- Receive push notifications for booking confirmation and reminders

**Cannot:**
- See other customers' data
- Access accounting
- Modify barber or service data

---

### 3.2 Barber
An employee of the shop with their own login.

**Can:**
- See their personal daily/weekly schedule
- View each upcoming appointment (customer name, services, time)
- Mark appointments as: In Progress → Completed
- View their own ratings and reviews
- See their personal earnings summary

**Cannot:**
- See other barbers' schedules or earnings
- Edit their own services or pricing (admin only)
- Access full shop accounting

---

### 3.3 Admin (Shop Owner)
Full control over the shop.

**Can:**
- Create, edit, delete barbers
- Create global service catalog (e.g. Haircut, Beard Trim, Hair Wash)
- Assign services to barbers with per-barber pricing and duration overrides
- Set working hours and days off per barber
- View all bookings across all barbers
- Access full accounting: income by day/month/year/custom range
- View income broken down by barber and by service type
- Export income reports as PDF or CSV
- Cancel any booking
- Manage customer accounts if needed

---

## 4. App Architecture

```
lib/
├── main.dart
├── app.dart                  # GoRouter setup, theme, providers
│
├── core/
│   ├── theme/                # Colors, text styles, spacing constants
│   ├── router/               # Route definitions, role-based guards
│   ├── utils/                # Date helpers, formatters, validators
│   └── widgets/              # Shared widgets (buttons, cards, loaders)
│
├── data/
│   ├── models/               # All data model classes (see Section 5)
│   ├── repositories/         # Abstract repos + Firebase implementations
│   ├── mock/                 # mock_data.dart for Phase 1
│   └── providers/            # Riverpod providers for all data
│
├── features/
│   ├── auth/                 # Login, register, role routing
│   ├── home/                 # Customer home screen
│   ├── booking/              # Full booking flow (5 steps)
│   ├── barber_dashboard/     # Barber's own schedule view
│   ├── admin/                # Admin panel screens
│   ├── accounting/           # Income charts and reports
│   ├── profile/              # Customer profile + history
│   └── ratings/              # Rating submission + display
│
└── gen/                      # Generated assets (fonts, images, Rive)
```

**State management pattern:** Each feature has its own Notifier class. Screens consume providers via `ConsumerWidget`. No business logic lives in UI files.

---

## 5. Data Models

### 5.1 User
```dart
class UserModel {
  final String id;
  final String name;
  final String phone;
  final String email;
  final UserRole role;         // customer | barber | admin
  final String? barberId;      // set if role == barber
  final DateTime createdAt;
}

enum UserRole { customer, barber, admin }
```

---

### 5.2 Barber
```dart
class BarberModel {
  final String id;
  final String name;
  final String avatarUrl;
  final double rating;          // computed average, updated on each review
  final int reviewCount;
  final int experienceYears;
  final bool isActive;          // admin can deactivate without deleting
  final List<BarberService> services;
  final WorkSchedule schedule;
}
```

---

### 5.3 BarberService
Each barber has their own version of a service with their own price and duration.

```dart
class BarberService {
  final String serviceId;       // references global Service catalog
  final String name;            // copied from catalog, can be overridden
  final double price;           // this barber's price for this service
  final int durationMinutes;    // this barber's duration for this service
  final bool isAvailable;       // barber can pause a service
}
```

---

### 5.4 Service (Global Catalog)
```dart
class ServiceModel {
  final String id;
  final String name;            // e.g. "Haircut", "Beard Trim", "Hair Wash"
  final String? iconName;       // icon reference for UI
  final bool isActive;
}
```

---

### 5.5 WorkSchedule
```dart
class WorkSchedule {
  final List<DaySchedule> weeklySchedule;  // one entry per day of week
  final List<DateTime> daysOff;            // specific blocked dates
}

class DaySchedule {
  final int weekday;            // 1=Monday ... 7=Sunday
  final bool isWorking;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final int slotIntervalMinutes; // e.g. 30 (generates slots automatically)
}
```

---

### 5.6 Booking
```dart
class BookingModel {
  final String id;
  final String customerId;
  final String barberId;
  final List<String> serviceIds;
  final DateTime date;
  final TimeOfDay startTime;
  final int totalDurationMinutes;   // sum of selected service durations
  final double totalPrice;          // sum of selected service prices
  final BookingStatus status;
  final DateTime createdAt;
  final String? cancellationReason;
  final bool isRated;               // prevents double rating
}

enum BookingStatus {
  pending,        // created, awaiting confirmation (auto or manual)
  confirmed,      // confirmed
  inProgress,     // barber started, marked by barber
  completed,      // done, triggers rating prompt
  cancelled,      // by customer or admin
  noShow          // customer did not arrive
}
```

---

### 5.7 Rating
```dart
class RatingModel {
  final String id;
  final String bookingId;       // one rating per booking
  final String customerId;
  final String barberId;
  final double stars;           // 1.0 to 5.0, increments of 0.5
  final String? comment;
  final DateTime createdAt;
}
```

---

### 5.8 IncomeRecord
Auto-created when a booking is marked `completed`.

```dart
class IncomeRecord {
  final String id;
  final String bookingId;
  final String barberId;
  final List<String> serviceIds;
  final double amount;
  final DateTime date;
}
```

---

## 6. Feature Modules

### 6.1 Authentication

**Screens:** Splash → Login → Register → Role Router

**Flow:**
1. App opens → check persisted auth token
2. If token valid → route to correct home based on `UserRole`
3. If no token → show Login screen
4. Login with email + password (Firebase Auth in Phase 2, mock in Phase 1)
5. On first register, role defaults to `customer`
6. Admin and barber accounts created by admin only (no self-registration for staff)

**Role routing after login:**
- `customer` → Customer Home
- `barber` → Barber Dashboard
- `admin` → Admin Panel

---

### 6.2 Customer — Booking Flow

The booking flow is a 5-step process. A progress bar at the top always shows which step the customer is on. Going back at any step preserves the previously selected state.

---

#### Step 1 — Customer Home Screen

**Layout:**
- Top: greeting with customer name + notification bell (badge if unread)
- Stats strip: today's shop bookings count + next appointment time
- "Our barbers" section with horizontal scrollable chair cards
- "Upcoming booking" card if one exists: barber name, time, services, status badge
- Bottom navigation: Home | Book | History | Profile

**Barber chair cards (horizontal scroll):**
- Each card shows an animated SVG barber chair with a stylised barber figure sitting in it
- Barber name, star rating, and availability badge (green = available, red = busy, grey = off today)
- Tapping a card goes directly to Step 3 (barber pre-selected)
- Tapping "Book now" goes to Step 2

---

#### Step 2 — Barber Selection (Animated Chair Carousel)

This is the signature screen. See Section 8 for full animation spec.

**Layout:**
- Dark background with a subtle radial gold glow in the center
- Three barber chairs rendered side by side in the center of the screen
- The selected chair is: scaled up (1.12×), fully opaque, gold drop shadow glow
- Non-selected chairs are: scaled down (0.9×), 35% opacity
- Busy barbers: 25% opacity, "BUSY" overlay badge, not tappable
- Below each chair: barber name, small status indicator dot

**Interaction:**
- Tap a free chair → it animates to selected state, others animate to non-selected state
- A barber detail card slides up from below showing: name, avatar, rating, experience, and their service list
- Swipe left/right also cycles through barbers

**Barber detail card (appears after selection):**
- Barber avatar (initials circle with color per barber) + name + rating + years of experience
- Service grid (2 columns): each card shows service name, price, duration
- Customer can tap one or more services to select them — selected cards get a gold border highlight
- Combined duration and price updates live at the bottom as services are toggled

---

#### Step 3 — Service Selection

Embedded inside Step 2 (appears in the same screen after barber is selected). Customer taps services. At least one service must be selected to continue.

**Each service card shows:**
- Service name (e.g. "Haircut")
- This barber's price (e.g. $35)
- This barber's duration (e.g. 30 min)
- A checkmark when selected

**Bottom summary bar:** "2 services · $55 · ~50 min" with a "Choose time →" button that activates once at least one service is selected.

---

#### Step 4 — Time Slot Selection

**Layout:**
- Progress bar (step 4 of 5 active)
- Barber summary strip at top (name, selected services, total duration) — always visible
- Date carousel: scrollable row of the next 7 days. Tapping a date loads that day's slots
- Legend: Free · Last slot · Taken · Selected
- Slots grouped by time of day: Morning (before 12), Afternoon (12–5), Evening (after 5)
- Each slot: time label + duration label inside a rounded tile

**Slot states:**
- **Free:** default dark surface tile, gold border on hover/tap
- **Almost full (last 1 slot):** amber border, amber time text
- **Taken:** faded, strikethrough line across the tile, not tappable
- **Selected:** filled gold, dark text, slightly scaled up (1.06×)

**Slot generation logic:**
- Slots are generated from the barber's `WorkSchedule` for the selected date
- A slot is marked taken if an existing booking overlaps it (start time + total duration of that booking)
- Slots that are too close to end-of-day to fit the selected services' total duration are hidden

**After selecting a slot:**
- A confirmation strip animates in below the slot grid showing: time, date, barber, services, total price
- "Continue to confirm" button activates

---

#### Step 5 — Booking Confirmation

**Layout:**
- Full summary card:
  - Barber name + avatar
  - Date and time
  - Each service with individual price
  - Total duration
  - Total price (bold, gold)
- "Confirm booking" button (gold, full width)

**On confirm:**
1. Booking record created with status `confirmed`
2. Success animation plays (see Section 8)
3. Customer routed back to Home
4. Home screen upcoming booking card updates
5. Push notification sent to customer (confirmation)
6. Push notification sent to barber (new appointment)

---

### 6.3 Time Slot Engine

The slot engine is a pure Dart utility class with no UI dependencies. It must be unit-tested.

```
SlotEngine.generateSlots({
  required WorkSchedule schedule,
  required DateTime date,
  required List<Booking> existingBookings,
  required int requiredDurationMinutes,
}) → List<TimeSlot>
```

**Logic:**
1. Check if `date` is a working day in `schedule.weeklySchedule`
2. Check if `date` is in `schedule.daysOff` → return empty list
3. Get `startTime` and `endTime` for that weekday
4. Generate candidate slots at every `slotIntervalMinutes` interval
5. For each candidate slot, check if `[slotStart, slotStart + requiredDuration]` overlaps any existing booking for this barber on this date
6. Remove overlapping slots → mark as `taken`
7. Remove slots where `slotStart + requiredDuration > endTime` → hidden
8. The last free slot before a taken block is marked `almostFull` if only one remains in a group

---

### 6.4 Barber Dashboard

Entry point for barbers after login.

**Screens:**
- **Today's schedule:** List of appointments sorted by time. Each card shows customer name, services, time, duration, status badge. Tap to expand and see customer phone.
- **Appointment actions:** Barber can tap "Start" (pending → inProgress), "Complete" (inProgress → completed). Cannot cancel.
- **My earnings:** Simple summary of today's earnings and this month's total. Breakdown by service.
- **My reviews:** List of customer ratings with stars and comments.

---

### 6.5 Admin Panel

**Sections accessible from admin home:**

#### Barber Management
- List of all barbers with edit/deactivate/delete controls
- "Add barber" → form: name, phone, email (creates auth account), profile photo
- Edit barber → full form including their service list, prices, durations, and working schedule
- Deactivate barber → sets `isActive: false`, hides from booking flow, preserves history
- Delete barber → soft delete only (data retained for accounting history)

#### Service Catalog
- Global list of service types (Haircut, Beard Trim, Hair Wash, etc.)
- Add / edit / delete service entries
- Services deleted from catalog are marked inactive but stay on historical bookings

#### Working Hours
- Per-barber weekly schedule editor
- Toggle working/off per day
- Set start and end time per day
- Add specific days off (calendar picker)
- Slot interval setting per barber (e.g. every 30 minutes)

#### All Bookings
- Full list of all bookings across all barbers
- Filter by: date range, barber, status
- Admin can cancel any booking with a reason

---

### 6.6 Accounting System

**Entry point:** Admin bottom nav → "Income" tab

#### Period Selector
Tabs: Today · This Week · This Month · This Year · Custom Range
Custom range: date range picker (start date → end date)

#### Main Income Card
- Large display of total income for selected period
- Appointment count
- Comparison vs previous period: "+12% vs last week" (green if up, red if down)

#### Service Breakdown
Mini stat cards (2-column grid):
- Total from Haircuts
- Total from Beard Trims
- Total from Hair Washes
- Total appointments count

#### Income Chart
- Bar chart for selected period:
  - Today → bars by hour of day
  - This Week → bars by day
  - This Month → bars by week
  - This Year → bars by month
  - Custom → bars auto-grouped by day or week depending on range length
- Tap a bar → tooltip with exact amount and appointment count

#### Barber Breakdown
List of all barbers with:
- Avatar + name
- Number of appointments in period
- Total income generated
- Most performed service

#### Export
- "Export PDF" → generates a formatted PDF report with all the above data for the selected period
- "Export CSV" → raw data rows: date, barber, service, amount

---

### 6.7 Ratings & Reviews

**Trigger:** When a booking is marked `completed`, the customer receives a push notification: "How was your visit with Karim? Leave a rating."

**Rating screen:**
- Barber name and avatar
- 5-star selector (half-star increments)
- Optional text comment (max 200 chars)
- "Submit" button
- "Skip" link (can skip, but only prompted once per booking)

**Rules:**
- One rating per booking (enforced by `booking.isRated` flag)
- Rating cannot be edited after submission
- Rating feeds into `barber.rating` (recomputed average on each new rating)
- Reviews visible on the barber's profile card and in barber's own dashboard

---

### 6.8 Notifications

| Trigger | Recipient | Message |
|---|---|---|
| Booking confirmed | Customer | "Your booking with [Barber] on [Date] at [Time] is confirmed." |
| Booking reminder | Customer | 1 hour before appointment: "Your appointment is in 1 hour." |
| New booking | Barber | "New appointment: [Customer] at [Time] — [Services]." |
| Booking cancelled | Barber | "[Customer] cancelled their [Time] appointment." |
| Booking cancelled | Customer | "Your booking has been cancelled." |
| Rating prompt | Customer | After completion: "Rate your visit with [Barber]." |

In Phase 1 (no Firebase): simulate notifications with `flutter_local_notifications` triggered by timer or button press.

---

## 7. Screen Inventory

| # | Screen | Role | Notes |
|---|---|---|---|
| 1 | Splash | All | Logo animation, auth check |
| 2 | Login | All | Email + password |
| 3 | Register | Customer | Name, phone, email, password |
| 4 | Customer Home | Customer | Barber cards, upcoming booking |
| 5 | Barber Selection | Customer | Animated chair carousel |
| 6 | Service Selection | Customer | Embedded in step 5 screen |
| 7 | Time Slot Picker | Customer | Date carousel + slot grid |
| 8 | Booking Confirmation | Customer | Summary + confirm button |
| 9 | Booking Success | Customer | Animated success modal |
| 10 | Booking History | Customer | List of past + upcoming bookings |
| 11 | Booking Detail | Customer | Single booking detail + cancel |
| 12 | Rating Screen | Customer | Post-completion star rating |
| 13 | Customer Profile | Customer | Name, phone, edit info, logout |
| 14 | Barber Dashboard | Barber | Today's schedule list |
| 15 | Appointment Detail | Barber | Customer info + service list + actions |
| 16 | Barber Earnings | Barber | Personal income summary |
| 17 | Barber Reviews | Barber | Own ratings and comments |
| 18 | Admin Home | Admin | Navigation hub |
| 19 | Barber List | Admin | All barbers with CRUD |
| 20 | Add / Edit Barber | Admin | Full barber form |
| 21 | Service Catalog | Admin | Global services CRUD |
| 22 | Working Hours Editor | Admin | Per-barber schedule config |
| 23 | All Bookings | Admin | Full booking list + filters |
| 24 | Accounting Overview | Admin | Income dashboard |
| 25 | Accounting Export | Admin | PDF/CSV generation |

---

## 8. Animations

### 8.1 Barber Chair Carousel (Signature Animation)

This is the most important animation in the app. It must feel premium and tactile.

**Assets needed:** One Rive file (`barber_chair.riv`) with:
- An idle state: barber sitting still, subtle breathing motion (shoulder rise/fall loop, ~3s cycle)
- An "active" state: barber looks forward, a golden spotlight expands from below the chair
- A "busy" state: barber leaning back, a red "BUSY" sash visible on the chair

**Flutter implementation:**
```dart
// Three RiveAnimation.asset() widgets in a Row
// Scale and opacity driven by AnimationController
// Tapping a chair:
//   1. selectedBarber changes
//   2. AnimatedScale on each chair reacts
//   3. AnimatedOpacity dims non-selected
//   4. Rive state machine on selected chair transitions to 'active'
//   5. DraggableScrollableSheet slides up with barber detail
```

**Fallback (Phase 1 / no Rive file yet):** Use SVG-rendered chairs (as in the demo) with Flutter's `AnimatedScale`, `AnimatedOpacity`, and a `BoxDecoration` with a gold-colored `BoxShadow` animating in on the selected chair. Use `TweenAnimationBuilder` for the glow radius.

---

### 8.2 Booking Success Modal

When customer confirms a booking:
1. Screen dims with a fade-in dark overlay (200ms)
2. Modal card scales in from 0.5× to 1.0× with an overshoot spring curve (`Curves.elasticOut`, 600ms)
3. Scissors icon inside modal does a single snip animation (rotate –15° → +15° → 0°, 400ms)
4. Confetti falls from top for 1.5 seconds (`confetti` package)
5. Modal auto-dismisses after 4 seconds or on button tap

---

### 8.3 Slot Selection Pulse

When a time slot is tapped:
- The slot scales to 1.06× with `Curves.easeOutBack` (200ms)
- The confirmation strip below slides up with `SlideTransition` (300ms, `Curves.easeOutCubic`)
- Previously selected slot scales back to 1.0× simultaneously

---

### 8.4 Page Transitions

- Between booking steps: slide left (forward), slide right (back)
- Modal screens (rating, confirmation): bottom sheet slide up
- Admin CRUD forms: shared axis horizontal transition (Material motion)

---

### 8.5 Status Badge Transitions

When a barber's availability changes (e.g. barber finishes a booking and becomes free):
- Badge background color transitions via `AnimatedContainer` (300ms)
- "Busy" red → "Available" green with a short pulse scale (1.0 → 1.15 → 1.0)

---

## 9. Design System

### 9.1 Color Palette

| Name | Hex | Usage |
|---|---|---|
| Gold primary | `#C9A84C` | CTAs, selected states, accents |
| Gold light | `#E8D5A0` | Hover states, icon fills |
| Dark background | `#111111` | App background |
| Surface | `#242424` | Cards, bottom sheets |
| Surface 2 | `#2E2E2E` | Input fields, unselected slots |
| Text primary | `#F5F0E8` | All main text |
| Text muted | `#7A7672` | Labels, subtitles, placeholders |
| Success green | `#4CAF7D` | Available status, positive values |
| Error red | `#E05555` | Busy status, errors, cancellations |
| Warning amber | `#E89040` | "Last slot" indicator |

### 9.2 Typography

| Style | Font | Size | Weight | Usage |
|---|---|---|---|---|
| Display | Playfair Display | 28px | 700 | Shop name, screen titles |
| Heading 1 | DM Sans | 22px | 600 | Section headers |
| Heading 2 | DM Sans | 17px | 600 | Card titles, barber names |
| Body | DM Sans | 15px | 400 | Main content text |
| Caption | DM Sans | 13px | 400 | Subtitles, secondary info |
| Label | DM Sans | 11px | 600 | Badges, section labels (uppercase) |

### 9.3 Spacing

Use multiples of 4dp. Common values: 4, 8, 12, 16, 20, 24, 32.

### 9.4 Border Radius

| Element | Radius |
|---|---|
| Cards | 20dp |
| Buttons | 16dp |
| Input fields | 12dp |
| Slots / chips | 12dp |
| Badges / pills | 20dp (fully rounded) |
| Avatar circles | 50% |

### 9.5 Elevation / Depth

No hard shadows. Depth is communicated through layered background colors (surface on dark, surface2 on surface) and subtle border lines (0.5px, `#333333`). Gold-tinted borders (`rgba(201,168,76,0.3)`) indicate active or highlighted cards.

---

## 10. CRUD Operations Reference

### Barbers
| Operation | Who | Notes |
|---|---|---|
| Create | Admin | Form with all fields including services and schedule |
| Read | All | Customers see name/rating/services; barbers see own data only |
| Update | Admin | All fields editable; service prices and durations per barber |
| Delete | Admin | Soft delete only — set `isActive: false` |

### Services (Global Catalog)
| Operation | Who | Notes |
|---|---|---|
| Create | Admin | Name + icon only |
| Read | All | Used to populate service lists |
| Update | Admin | Name can change; affects all barbers using it |
| Delete | Admin | Soft delete; historical records unaffected |

### Bookings
| Operation | Who | Notes |
|---|---|---|
| Create | Customer | Via 5-step booking flow |
| Read | Customer (own), Barber (own), Admin (all) | |
| Update | Barber (status only), Admin (any field) | |
| Delete | Admin only | Soft delete with reason required |
| Cancel | Customer (before appointment), Admin | Sets status to `cancelled` |

### Ratings
| Operation | Who | Notes |
|---|---|---|
| Create | Customer | Once per completed booking only |
| Read | All | Visible on barber profile |
| Update | Nobody | Ratings are final |
| Delete | Admin only | For abuse/spam cases |

### Income Records
| Operation | Who | Notes |
|---|---|---|
| Create | System | Auto-created when booking → `completed` |
| Read | Admin (all), Barber (own only) | |
| Update | Nobody | Records are immutable |
| Delete | Nobody | Financial records must not be deleted |

---

## 11. Business Rules

1. **A booking cannot overlap** another booking for the same barber on the same date. The slot engine enforces this before presenting slots to the customer.

2. **Service duration stacking:** When a customer selects multiple services, the total duration is the sum of all selected service durations. The slot engine uses this total to check availability.

3. **Barber must be active** (`isActive: true`) to appear in the booking flow.

4. **Barber must be scheduled** on the selected date's day-of-week and the date must not be in their `daysOff` list.

5. **Customers can only cancel** bookings with status `pending` or `confirmed` and only if the appointment is more than 2 hours away. After that, only admin can cancel.

6. **Ratings are gated** behind a completed booking. The `isRated` flag prevents a second rating for the same visit.

7. **Barber rating** is recomputed as a running average every time a new rating is submitted. Store both `rating` (average) and `reviewCount` on the barber document to compute without fetching all reviews.

8. **Income records are created by the system** (Cloud Function in Phase 2, local trigger in Phase 1) the moment a booking transitions to `completed`. They cannot be manually created or edited.

9. **Admin-created staff accounts**: Admin fills a form with the new barber's details and the system creates the Firebase Auth account + Firestore user document + barber document atomically. The barber receives a "set your password" email (Phase 2).

10. **Walk-in support (Phase 2):** Admin can create a booking on behalf of a walk-in customer without a customer account. Booking is attributed to a "Walk-in" placeholder customer.

---

## 12. Future Considerations

These are out of scope for the initial build but should be architected to allow them:

- **Online payment** (Stripe): booking confirmation triggers a payment intent. Full amount charged on completion.
- **Waiting list:** if all slots for a day are taken, customer can join a waiting list and is notified if a slot opens.
- **Multi-branch support:** a `shopId` field on all documents allows the app to serve multiple barbershop locations under one admin account.
- **Loyalty points:** customers earn points per appointment, redeemable for discounts.
- **Barber app (separate):** a dedicated lighter app for barbers only, optimised for the chair-side experience.
- **Web admin panel:** a Flutter Web build of just the admin + accounting screens for desktop use.
- **SMS notifications:** fallback when push notifications are disabled.

---

*Document version 1.0 — Crown Cuts Barber App*
*Generated for Flutter development handoff*
