import streamlit as st
import requests
import os
import pandas as pd
import time

# Page config
st.set_page_config(
    page_title="Student Management System",
    page_icon="🎓",
    layout="wide",
    initial_sidebar_state="collapsed"
)

# Hide default menu and footer
st.markdown("<style>#MainMenu {visibility: hidden;} footer {visibility: hidden;}</style>", unsafe_allow_html=True)

# Custom CSS for modern, premium design
st.markdown("""
    <style>
    @import url('https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap');
    
    * {
        font-family: 'Inter', sans-serif;
    }
    
    /* Premium gradient background */
    .stApp {
        background: linear-gradient(135deg, #667eea 0%, #764ba2 50%, #f093fb 100%);
        background-attachment: fixed;
    }
    
    /* Glassmorphism container */
    .glass-container {
        background: rgba(255, 255, 255, 0.15);
        backdrop-filter: blur(10px);
        -webkit-backdrop-filter: blur(10px);
        border-radius: 20px;
        border: 1px solid rgba(255, 255, 255, 0.2);
        padding: 30px;
        margin: 20px 0;
        box-shadow: 0 8px 32px 0 rgba(31, 38, 135, 0.37);
    }
    
    /* Header styling */
    .main-header {
        text-align: center;
        padding: 40px 20px;
        background: rgba(255, 255, 255, 0.1);
        backdrop-filter: blur(10px);
        border-radius: 25px;
        margin-bottom: 30px;
        border: 1px solid rgba(255, 255, 255, 0.2);
        animation: fadeInDown 0.8s ease-out;
    }
    
    .main-header h1 {
        color: #ffffff;
        font-size: 48px;
        font-weight: 700;
        margin: 0;
        text-shadow: 2px 2px 4px rgba(0,0,0,0.2);
        letter-spacing: -1px;
    }
    
    .main-header p {
        color: #f0f0f0;
        font-size: 18px;
        margin-top: 10px;
        font-weight: 300;
    }
    
    /* Tab styling */
    .stTabs [data-baseweb="tab-list"] {
        gap: 10px;
        background: rgba(255, 255, 255, 0.1);
        padding: 10px;
        border-radius: 15px;
        backdrop-filter: blur(10px);
    }
    
    .stTabs [data-baseweb="tab"] {
        background: rgba(255, 255, 255, 0.2);
        border-radius: 10px;
        color: white;
        font-weight: 500;
        padding: 12px 24px;
        transition: all 0.3s ease;
        border: 1px solid rgba(255, 255, 255, 0.3);
    }
    
    .stTabs [data-baseweb="tab"]:hover {
        background: rgba(255, 255, 255, 0.3);
        transform: translateY(-2px);
        box-shadow: 0 4px 12px rgba(0,0,0,0.2);
    }
    
    .stTabs [aria-selected="true"] {
        background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
        box-shadow: 0 4px 15px rgba(102, 126, 234, 0.4);
    }
    
    /* Button styling */
    .stButton > button {
        background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
        color: white;
        border: none;
        border-radius: 12px;
        padding: 12px 32px;
        font-size: 16px;
        font-weight: 600;
        transition: all 0.3s ease;
        box-shadow: 0 4px 15px rgba(102, 126, 234, 0.4);
        width: 100%;
    }
    
    .stButton > button:hover {
        transform: translateY(-2px);
        box-shadow: 0 6px 20px rgba(102, 126, 234, 0.6);
        background: linear-gradient(135deg, #764ba2 0%, #667eea 100%);
    }
    
    .stButton > button:active {
        transform: translateY(0);
    }
    
    /* Input field styling */
    .stTextInput > div > div > input,
    .stNumberInput > div > div > input,
    .stSelectbox > div > div > select {
        background: rgba(255, 255, 255, 0.9);
        border: 2px solid rgba(255, 255, 255, 0.3);
        border-radius: 10px;
        padding: 12px;
        font-size: 15px;
        transition: all 0.3s ease;
    }
    
    .stTextInput > div > div > input:focus,
    .stNumberInput > div > div > input:focus {
        border-color: #667eea;
        box-shadow: 0 0 0 3px rgba(102, 126, 234, 0.2);
        background: white;
    }
    
    /* Label styling */
    .stTextInput > label,
    .stNumberInput > label,
    .stSelectbox > label {
        color: white !important;
        font-weight: 600 !important;
        font-size: 14px !important;
        text-shadow: 1px 1px 2px rgba(0,0,0,0.2);
    }
    
    /* Card styling for student data */
    .student-card {
        background: rgba(255, 255, 255, 0.95);
        border-radius: 15px;
        padding: 20px;
        margin: 15px 0;
        box-shadow: 0 4px 15px rgba(0,0,0,0.1);
        transition: all 0.3s ease;
        border-left: 4px solid #667eea;
    }
    
    .student-card:hover {
        transform: translateX(5px);
        box-shadow: 0 6px 20px rgba(0,0,0,0.15);
    }
    
    /* Table styling */
    .dataframe {
        background: rgba(255, 255, 255, 0.95) !important;
        border-radius: 15px !important;
        overflow: hidden !important;
    }
    
    .dataframe tbody tr:hover {
        background-color: rgba(102, 126, 234, 0.1) !important;
        transition: all 0.2s ease;
    }
    
    .dataframe thead tr th {
        background: linear-gradient(135deg, #667eea 0%, #764ba2 100%) !important;
        color: white !important;
        font-weight: 600 !important;
        padding: 15px !important;
    }
    
    /* Success/Error message styling */
    .stSuccess, .stError, .stWarning, .stInfo {
        border-radius: 10px;
        padding: 15px;
        backdrop-filter: blur(10px);
    }
    
    /* Animations */
    @keyframes fadeInDown {
        from {
            opacity: 0;
            transform: translateY(-20px);
        }
        to {
            opacity: 1;
            transform: translateY(0);
        }
    }
    
    @keyframes fadeIn {
        from { opacity: 0; }
        to { opacity: 1; }
    }
    
    /* Section headers */
    h2, h3 {
        color: white !important;
        font-weight: 600 !important;
        text-shadow: 2px 2px 4px rgba(0,0,0,0.2);
    }
    
    /* Metric styling */
    [data-testid="stMetricValue"] {
        color: #667eea !important;
        font-size: 32px !important;
        font-weight: 700 !important;
    }
    
    [data-testid="stMetricLabel"] {
        color: white !important;
        font-weight: 500 !important;
    }
    </style>
""", unsafe_allow_html=True)

# Welcome header
st.markdown("""
<div class="main-header">
    <h1>🎓 Student Management System</h1>
    <p>Modern, efficient, and beautiful student data management</p>
</div>
""", unsafe_allow_html=True)

# API URL configuration
API_URL = os.environ.get("API_URL", "http://localhost:8080")

# Helper function for API calls with error handling
def api_call(method, endpoint, data=None, show_error=True):
    try:
        url = f"{API_URL}{endpoint}"
        if method == "GET":
            response = requests.get(url, timeout=5)
        elif method == "POST":
            response = requests.post(url, json=data, timeout=5)
        elif method == "PUT":
            response = requests.put(url, json=data, timeout=5)
        elif method == "DELETE":
            response = requests.delete(url, timeout=5)
        
        if response.status_code in [200, 201]:
            return response.json(), None
        else:
            error_msg = response.json().get('error', response.text) if response.text else f"Error {response.status_code}"
            return None, error_msg
    except requests.exceptions.ConnectionError:
        return None, "Cannot connect to backend server. Please ensure the backend is running."
    except requests.exceptions.Timeout:
        return None, "Request timed out. Please try again."
    except Exception as e:
        return None, f"Unexpected error: {str(e)}"

# Tabs
tab1, tab2, tab3, tab4, tab5 = st.tabs(["➕ Add Student", "🔍 Search Student", "✏️ Update Student", "🗑️ Delete Student", "📋 All Students"])

# --- Tab 1: Add Student ---
with tab1:
    st.markdown("### Add a New Student")
    
    with st.form("add_student_form", clear_on_submit=True):
        col1, col2 = st.columns(2)
        
        with col1:
            name = st.text_input("Full Name *", placeholder="Enter student name")
            age = st.number_input("Age *", min_value=1, max_value=150, value=18)
        
        with col2:
            email = st.text_input("Email", placeholder="student@example.com")
            course = st.text_input("Course", placeholder="e.g., Computer Science")
        
        submit_button = st.form_submit_button("➕ Add Student")
        
        if submit_button:
            if not name:
                st.warning("⚠️ Please enter a student name.")
            else:
                with st.spinner("Adding student..."):
                    student_data = {
                        "name": name,
                        "age": age,
                        "email": email if email else None,
                        "course": course if course else None
                    }
                    
                    result, error = api_call("POST", "/student/post", student_data)
                    
                    if error:
                        st.error(f"❌ {error}")
                    else:
                        st.success(f"✅ Student '{name}' added successfully! (ID: {result.get('id')})")
                        time.sleep(0.5)
                        st.rerun()

# --- Tab 2: Search Student ---
with tab2:
    st.markdown("### Search for a Student")
    
    search_name = st.text_input("Enter student name", placeholder="Type name to search...", key="search_name")
    
    col1, col2 = st.columns([1, 4])
    with col1:
        search_button = st.button("🔍 Search", use_container_width=True)
    
    if search_button and search_name:
        with st.spinner("Searching..."):
            result, error = api_call("GET", f"/student/get/{search_name}")
            
            if error:
                st.warning(f"⚠️ {error}")
            else:
                st.markdown(f"""
                <div class="student-card">
                    <h3 style="color: #667eea; margin-top: 0;">👤 {result.get('name', 'N/A')}</h3>
                    <p><strong>ID:</strong> {result.get('id', 'N/A')}</p>
                    <p><strong>Age:</strong> {result.get('age', 'N/A')} years</p>
                    <p><strong>Email:</strong> {result.get('email', 'Not provided')}</p>
                    <p><strong>Course:</strong> {result.get('course', 'Not specified')}</p>
                </div>
                """, unsafe_allow_html=True)

# --- Tab 3: Update Student ---
with tab3:
    st.markdown("### Update Student Information")
    
    # First, get student by ID or name
    search_col1, search_col2 = st.columns([3, 1])
    with search_col1:
        search_id = st.number_input("Enter Student ID", min_value=1, step=1, key="update_search_id")
    with search_col2:
        st.write("")
        st.write("")
        load_button = st.button("📥 Load", use_container_width=True)
    
    if load_button and search_id:
        result, error = api_call("GET", f"/student/{search_id}")
        
        if error:
            st.warning(f"⚠️ {error}")
        else:
            st.session_state['update_student'] = result
    
    if 'update_student' in st.session_state:
        student = st.session_state['update_student']
        
        with st.form("update_student_form"):
            st.info(f"Updating: {student.get('name')} (ID: {student.get('id')})")
            
            col1, col2 = st.columns(2)
            
            with col1:
                new_name = st.text_input("Full Name *", value=student.get('name', ''))
                new_age = st.number_input("Age *", min_value=1, max_value=150, value=student.get('age', 18))
            
            with col2:
                new_email = st.text_input("Email", value=student.get('email', '') or '')
                new_course = st.text_input("Course", value=student.get('course', '') or '')
            
            update_button = st.form_submit_button("💾 Update Student")
            
            if update_button:
                if not new_name:
                    st.warning("⚠️ Name cannot be empty.")
                else:
                    with st.spinner("Updating..."):
                        update_data = {
                            "name": new_name,
                            "age": new_age,
                            "email": new_email if new_email else None,
                            "course": new_course if new_course else None
                        }
                        
                        result, error = api_call("PUT", f"/student/update/{student.get('id')}", update_data)
                        
                        if error:
                            st.error(f"❌ {error}")
                        else:
                            st.success(f"✅ Student updated successfully!")
                            del st.session_state['update_student']
                            time.sleep(0.5)
                            st.rerun()

# --- Tab 4: Delete Student ---
with tab4:
    st.markdown("### Delete a Student")
    st.warning("⚠️ This action cannot be undone!")
    
    delete_id = st.number_input("Enter Student ID to Delete", min_value=1, step=1, key="delete_id")
    
    # Show student details before deletion
    if delete_id:
        result, error = api_call("GET", f"/student/{delete_id}", show_error=False)
        
        if result:
            st.markdown(f"""
            <div class="student-card">
                <h4 style="color: #dc3545; margin-top: 0;">Student to be deleted:</h4>
                <p><strong>Name:</strong> {result.get('name', 'N/A')}</p>
                <p><strong>Age:</strong> {result.get('age', 'N/A')}</p>
                <p><strong>Email:</strong> {result.get('email', 'Not provided')}</p>
                <p><strong>Course:</strong> {result.get('course', 'Not specified')}</p>
            </div>
            """, unsafe_allow_html=True)
            
            col1, col2, col3 = st.columns([1, 1, 2])
            with col1:
                if st.button("🗑️ Confirm Delete", type="primary", use_container_width=True):
                    with st.spinner("Deleting..."):
                        _, error = api_call("DELETE", f"/student/delete/{delete_id}")
                        
                        if error:
                            st.error(f"❌ {error}")
                        else:
                            st.success("✅ Student deleted successfully!")
                            time.sleep(0.5)
                            st.rerun()

# --- Tab 5: List All Students ---
with tab5:
    st.markdown("### All Students")
    
    col1, col2, col3 = st.columns([1, 1, 3])
    with col1:
        refresh_button = st.button("🔄 Refresh", use_container_width=True)
    
    # Fetch all students
    with st.spinner("Loading students..."):
        students, error = api_call("GET", "/student/all")
        
        if error:
            st.error(f"❌ {error}")
        elif students:
            # Display metrics
            metric_col1, metric_col2, metric_col3 = st.columns(3)
            with metric_col1:
                st.metric("Total Students", len(students))
            with metric_col2:
                avg_age = sum(s.get('age', 0) for s in students) / len(students) if students else 0
                st.metric("Average Age", f"{avg_age:.1f}")
            with metric_col3:
                with_email = sum(1 for s in students if s.get('email'))
                st.metric("With Email", with_email)
            
            # Display table
            st.markdown("---")
            student_data = [{
                "ID": s.get("id", "N/A"),
                "Name": s.get("name", "N/A"),
                "Age": s.get("age", "N/A"),
                "Email": s.get("email", "Not provided"),
                "Course": s.get("course", "Not specified")
            } for s in students]
            
            df = pd.DataFrame(student_data)
            st.dataframe(
                df,
                use_container_width=True,
                hide_index=True,
                height=400
            )
        else:
            st.info("📭 No students found in the database. Add some students to get started!")

# Footer
st.markdown("---")
st.markdown("""
<div style="text-align: center; color: white; padding: 20px; opacity: 0.8;">
    <p>🎓 Student Management System | Built with Spring Boot & Streamlit</p>
</div>
""", unsafe_allow_html=True)
