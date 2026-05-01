# SQL Cohort Analysis

## 📊 Project Overview
This project performs cohort analysis using SQL to understand user retention over time.

## 🎯 Objective
The goal is to:
- Clean and standardize inconsistent date formats
- Track user activity over time
- Analyze retention by cohort
- Compare users acquired via promo vs non-promo channels

## 🛠️ Tools
- SQL (PostgreSQL)

## 🔍 What was done

### 1. Data Cleaning
- Cleaned inconsistent date formats in signup and event data
- Converted text dates into proper date format
- Handled multiple date formats using CASE and regex

### 2. Data Preparation
- Joined user and event tables
- Created:
  - cohort_month (signup month)
  - activity_month (event month)
  - month_offset (months since signup)

### 3. Filtering
- Removed:
  - missing dates
  - test events
  - invalid records

### 4. Cohort Analysis
- Grouped users by:
  - signup cohort
  - acquisition channel (promo flag)
  - activity month offset
- Calculated number of active users per cohort

## 📈 Key Insights
- Allows tracking user retention over time
- Helps compare effectiveness of promo vs organic users
- Provides structured cohort table for further analysis

## 📁 Project Structure
- `cohort_analysis.sql` — main SQL query

## 🚀 How to Use
Run the SQL query in a PostgreSQL environment with the required tables:
- cohort_users_raw
- cohort_events_raw
