# 🧩 Flutter Puzzle Game

A number-matching puzzle game built with **Flutter**, inspired by *Number Master* by KiwiFun, but with a **custom matching mechanic**.  
Developed as part of a fresher assignment challenge.  

---

## 🚀 Features

- 🎮 **Core Gameplay**
  - Match two numbers if they are **equal** or **sum to 10**  
  - Matched cells remain visible but turn **faded (dull)**  
  - Invalid match → **red flash**  
  - Add new rows dynamically with the **➕ Add Row button**

- 🏆 **Levels**
  - **Level 1:** Easy – basic grid with limited rows You add one row to slove
  - **Level 2:** Medium – increased difficulty and time pressure  You add one row to slove
  - **Level 3:** Hard – advanced constraints and full row matching  You add two row to slove
  - ⏳ Each level must be completed within **2 minutes**

- 🎨 **UI / UX**
  - Clean & minimal design (focus on gameplay)  
  - Tap → Highlight → Second Tap → Validate match  
  - Responsive across devices

- ⚙️ **Tech Stack & Architecture**
  - **Flutter (Stable Channel)**  
  - **State Management:** Bloc  
  - **Modular Code:** Separate layers for UI, models, and controllers  
---

## 📂 Project Structure

```bash
lib/
│── main.dart              # App entry point
│── models/                # Data models (Cell, Level, Game State)
│── blocs/                 # State management logic
│── services/              # Game services & controllers
│── screens/               # Ui
│── widgets                #  Reusable widgets (GridCell)

