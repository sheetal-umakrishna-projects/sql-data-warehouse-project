# Data Warehouse Project

Welcome to the **Data Warehouse and Analytics Project** repository! 🚀  
This project demonstrates a complete data warehousing solution, covering the process from designing to building a data warehouse. Developed as a portfolio project, it showcases industry best practices in data engineering.

---
## 🏗️ Data Architecture

The data architecture for this project is based on the Medallion approach, consisting of Bronze, Silver, and Gold layers.

1. **Bronze Layer**: Contains raw data ingested directly from source systems, loaded from CSV files into a SQL Server database without transformation.
2. **Silver Layer**: Applies data cleaning, standardization, and normalization to refine and prepare the data.
3. **Gold Layer**: Stores curated, business-ready data structured in a star schema for reporting purposes.

---
## 📖 Project Overview

This project involves the following Key Components:

### 🔹 ETL Pipelines  
- Extract data from CSV files  
- Load raw data into the Bronze layer  
- Transform and clean data in the Silver layer  
- Model structured data in the Gold layer  

---

### 🔹 Data Modeling  
- Design **fact and dimension tables**  
- Implement a **star schema**  
- Optimize schema for query performance  

---

### 🔹 Data Transformation  
- Clean and validate raw data  
- Standardize formats (dates, text, etc.)  
- Apply business rules for consistency 

---

## 🛠️ Tech Stack  

- **Database:** MySQL  
- **Language:** SQL  
- **Data Source:** CSV files  
- **Version Control:** Git & GitHub  

---

## 📂 Repository Structure
```
data-warehouse-project/
│
├── datasets/                           # Raw datasets used for the project (ERP and CRM data)
│
├── docs/                               # Project documentation and architecture details
│   ├── data_architecture.drawio        # Draw.io file shows the project's architecture
│   ├── data_catalog.md                 # Catalog of datasets, including field descriptions and metadata
│
├── scripts/                            # SQL scripts for ETL and transformations
│   ├── bronze/                         # Scripts for extracting and loading raw data
│   ├── silver/                         # Scripts for cleaning and transforming data
│   ├── gold/                           # Scripts for creating analytical models
│
├── tests/                              # Test scripts and quality files
│
├── README.md                           # Project overview and instructions
```
---

### 🎯 Skills Demonstrated
- **Data Warehousing**
- **SQL Development (MySQL)**
- **ETL Pipeline Design**
- **Data Cleaning & Transformation**
- **Dimensional Modeling (Star Schema)**
- **Medallion Architecture**

---

### 📈 What I Learned
- Designing layered data architectures (**Bronze → Silver → Gold**)
- Building ETL pipelines in **MySQL**
- Structuring **analytical data models**
- Improving data quality through **transformations**

---

### 🚧 Future Improvements
- Automate pipelines with **scheduling tools**
- Integrate **BI tools or dashboards** (Power BI / Tableau)
- Expand the solution with **larger datasets**

---

## 🌟 About Me

Hi there! I'm **Sheetal Umakrishna**, I'm passionate about working with data and turning it into actionable insights. I aspire to become a **Data Engineer** and am actively looking for opportunities in this field.  

I enjoy building **ETL pipelines**, designing **data warehouses**, and creating **structured analytical models** that help organizations make better decisions. I'm eager to continue learning and contributing to projects that involve **data architecture**, **cleaning & transformation**, and **scalable solutions**.  

When I'm not coding, I love exploring new technologies, solving challenging data problems, and improving my skills in **SQL, Python, and cloud-based data platforms**.

