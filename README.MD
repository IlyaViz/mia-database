# Administrative Service Center System (Driver's Licenses)

A relational database management system designed for an **Administrative Service Center (МВС)**. It automates the complete lifecycle of driver's license issuance: from client registration to theoretical/practical exams and document generation.

## 🚀 Features
- **Complex Business Processes:**
  - **Exam Management:** Logic for tracking attempts and results for both theoretical and practical driving exams.
  - **Document Workflow:** Issuance of passports, medical certificates, and driving licenses with validity checks.
  - **Penalty System:** Tracking of fines and license revocations/suspensions.
- **Advanced SQL:**
  - **Stored Procedures:** Automated ticket generation and status updates.
  - **Triggers:** Validation of exam prerequisites (e.g., cannot take practical exam without passing theory).
  - **Views:** Analytical reports on pass rates and service center load.
- **Data Seeding:** Python scripts using `Faker` to generate realistic test datasets (clients, inspectors, cars) for load testing.

## 🛠 Tech Stack
- **Database:** PostgreSQL
- **Scripting:** Python (Psycopg2, Faker)
- **Modeling:** ER Diagrams (Draw.io)

## 📂 Project Structure
- `creation/`: DDL scripts for database structure (tables, enums, roles).
- `main/`: Business logic implementation (triggers, functions).
- `data/`: ETL scripts for mock data generation.
- `docs/`: Domain documentation and ER diagrams.

## ⚡ How to Run
1. Create a PostgreSQL database.
2. Execute scripts in `creation/` to build the schema.
3. Execute scripts in `main/` to add business logic. Can be ndoe using `everything.bat` file.
4. (Optional) Run `python data/generate.py` to populate the database with test data.