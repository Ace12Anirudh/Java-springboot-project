import streamlit as st
import requests
import os
import pandas as pd

# Page config
st.set_page_config(page_title="Students DataStore", page_icon="📚", layout="wide")

# Hide default menu and footer
st.markdown("<style>#MainMenu {visibility: hidden;} footer {visibility: hidden;}</style>", unsafe_allow_html=True)

# Custom CSS for background, buttons, and headers
st.markdown("""
    <style>
    /* Gradient background */
    .stApp {
        background: linear-gradient(135deg, #74ebd5, #ACB6E5);
        color: #333333;
    }
    
    /* Header style */
    .welcome {
        background-color: rgba(255,255,255,0.2);
        padding: 25px;
        border-radius: 15px;
        text-align: center;
        font-family: 'Arial';
    }
    .welcome h1 {
        color: #fff;
        font-size: 40px;
    }
    .welcome p {
        color: #f0f0f0;
        font-size: 20px;
    }

    /* Buttons style */
    .stButton>button {
        background-color: #ff7f50;
        color:white;
        height:3em;
        width:12em;
        border-radius:10px;
        border:none;
        font-size:16px;
    }

    /* Table style */
    .dataframe tbody tr:hover {
        background-color: #ffe4b5;
    }
    </style>
""", unsafe_allow_html=True)

# Welcome banner
st.markdown("""
<div class="welcome">
    <h1>Welcome to MultiCloudDevOps by Veera NareshIT -Springboot project📚</h1>
    <p>Manage your student data effortlessly!</p>
</div>
""", unsafe_allow_html=True)

# API URL
API_URL = os.environ.get("API_URL", "http://localhost:8081")

# Tabs
tab1, tab2, tab3 = st.tabs(["Add Student", "Search Student", "List Students"])

# --- Tab 1: Add Student ---
with tab1:
    st.markdown('<h2 style="color:#ff7f50;">Add a new student</h2>', unsafe_allow_html=True)
    with st.form("add_student_form"):
        name = st.text_input("Name")
        age = st.number_input("Age", min_value=1, max_value=100, value=18)
        submit_button = st.form_submit_button("Add Student")
        if submit_button:
            if name:
                try:
                    response = requests.post(f"{API_URL}/student/post", json={"name": name, "age": age})
                    if response.status_code == 200:
                        st.success(f"Student {name} added successfully!")
                    else:
                        st.error(f"Error adding student: {response.text}")
                except requests.exceptions.RequestException as e:
                    st.error(f"Connection error: {e}")
            else:
                st.warning("Please fill in all required fields.")

# --- Tab 2: Search Student ---
with tab2:
    st.markdown('<h2 style="color:#ff7f50;">Search for a student</h2>', unsafe_allow_html=True)
    search_name = st.text_input("Enter student name to search")
    if st.button("Search") and search_name:
        try:
            response = requests.get(f"{API_URL}/student/get/{search_name}")
            if response.status_code == 200:
                student = response.json()
                st.subheader("Student Information")
                st.write(f"**Name:** {student.get('name', 'N/A')}")
                st.write(f"**Age:** {student.get('age', 'N/A')}")
            else:
                st.warning(f"Student with name '{search_name}' not found.")
        except requests.exceptions.RequestException as e:
            st.error(f"Connection error: {e}")

# --- Tab 3: List Students ---
with tab3:
    st.markdown('<h2 style="color:#ff7f50;">List of all students</h2>', unsafe_allow_html=True)
    if st.button("Refresh List"):
        pass  # refresh handled automatically
    try:
        response = requests.get(f"{API_URL}/student/all")
        if response.status_code == 200:
            students = response.json()
            if students:
                student_data = [{"Name": s.get("name", "N/A"), "Age": s.get("age", "N/A")} for s in students]
                df = pd.DataFrame(student_data)
                st.dataframe(df.style.set_properties(**{'background-color': '#f0f8ff', 'color': 'black'}))
            else:
                st.info("No students found in the database.")
        else:
            st.error("Failed to retrieve student list.")
    except requests.exceptions.RequestException as e:
        st.error(f"Connection error: {e}")