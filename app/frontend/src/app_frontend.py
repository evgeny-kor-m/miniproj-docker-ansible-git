#!/usr/bin/env python3
"""
Flask API Frontend Application
User Management Interface using Tkinter
"""

import tkinter as tk
from tkinter import ttk, messagebox, scrolledtext
import requests
import json
from typing import Optional, Dict, Any
import config


class UserManagementApp:
    """Main application class for user management interface"""
    
    def __init__(self, root: tk.Tk):
        self.root = root
        self.root.title("User Management System")
        self.root.geometry("900x700")
        self.root.resizable(True, True)
        
        # Configure style
        self.setup_styles()
        
        # Create UI
        self.create_widgets()
        
        # Test API connection on startup
        self.test_connection()
    
    def setup_styles(self):
        """Configure ttk styles"""
        style = ttk.Style()
        style.theme_use('clam')
        
        # Button styles
        style.configure('Action.TButton', 
                       padding=10, 
                       font=('Arial', 10, 'bold'))
        
        # Label styles
        style.configure('Header.TLabel', 
                       font=('Arial', 14, 'bold'),
                       foreground='#2c3e50')
        
        style.configure('Field.TLabel', 
                       font=('Arial', 10))
    
    def create_widgets(self):
        """Create all UI widgets"""
        
        # Main container
        main_frame = ttk.Frame(self.root, padding="10")
        main_frame.grid(row=0, column=0, sticky=(tk.W, tk.E, tk.N, tk.S))
        
        # Configure grid weights
        self.root.columnconfigure(0, weight=1)
        self.root.rowconfigure(0, weight=1)
        main_frame.columnconfigure(0, weight=1)
        
        # Create sections
        self.create_header(main_frame)
        self.create_get_users_section(main_frame)
        self.create_create_user_section(main_frame)
        self.create_results_section(main_frame)
        self.create_status_bar(main_frame)
    
    def create_header(self, parent: ttk.Frame):
        """Create header section"""
        header_frame = ttk.Frame(parent)
        header_frame.grid(row=0, column=0, sticky=(tk.W, tk.E), pady=(0, 20))
        
        title = ttk.Label(header_frame, 
                         text="User Management System",
                         style='Header.TLabel')
        title.pack()
        
        api_info = ttk.Label(header_frame,
                            text=f"API: {config.API_BASE_URL}",
                            font=('Arial', 9),
                            foreground='#7f8c8d')
        api_info.pack()
    
    def create_get_users_section(self, parent: ttk.Frame):
        """Create section for getting users"""
        # Section container
        section = ttk.LabelFrame(parent, text="1. Display Users", padding="10")
        section.grid(row=1, column=0, sticky=(tk.W, tk.E), pady=(0, 10))
        section.columnconfigure(1, weight=1)
        
        # Number of rows input
        ttk.Label(section, 
                 text="Number of users:",
                 style='Field.TLabel').grid(row=0, column=0, sticky=tk.W, padx=(0, 10))
        
        self.num_rows_var = tk.StringVar(value=str(config.DEFAULT_NUM_ROWS))
        num_rows_entry = ttk.Entry(section, 
                                   textvariable=self.num_rows_var,
                                   width=15)
        num_rows_entry.grid(row=0, column=1, sticky=tk.W)
        
        # Get All checkbox
        self.get_all_var = tk.BooleanVar(value=False)
        get_all_check = ttk.Checkbutton(section,
                                        text="Get ALL users",
                                        variable=self.get_all_var,
                                        command=self.toggle_num_rows)
        get_all_check.grid(row=0, column=2, padx=(20, 0))
        
        # Get Users button
        get_btn = ttk.Button(section,
                            text="Get Users",
                            command=self.get_users,
                            style='Action.TButton')
        get_btn.grid(row=0, column=3, padx=(20, 0))
        
        # Tooltip
        tooltip = ttk.Label(section,
                          text="Enter number of users to retrieve or check 'Get ALL'",
                          font=('Arial', 8),
                          foreground='#95a5a6')
        tooltip.grid(row=1, column=0, columnspan=4, sticky=tk.W, pady=(5, 0))
    
    def create_create_user_section(self, parent: ttk.Frame):
        """Create section for creating new user"""
        # Section container
        section = ttk.LabelFrame(parent, text="2. Create New User", padding="10")
        section.grid(row=2, column=0, sticky=(tk.W, tk.E), pady=(0, 10))
        section.columnconfigure(1, weight=1)
        
        # Username
        ttk.Label(section, text="Username*:", style='Field.TLabel').grid(
            row=0, column=0, sticky=tk.W, padx=(0, 10), pady=5)
        self.username_var = tk.StringVar()
        username_entry = ttk.Entry(section, textvariable=self.username_var, width=40)
        username_entry.grid(row=0, column=1, sticky=(tk.W, tk.E), pady=5)
        
        # Password
        ttk.Label(section, text="Password*:", style='Field.TLabel').grid(
            row=1, column=0, sticky=tk.W, padx=(0, 10), pady=5)
        self.password_var = tk.StringVar()
        password_entry = ttk.Entry(section, textvariable=self.password_var, 
                                   show="*", width=40)
        password_entry.grid(row=1, column=1, sticky=(tk.W, tk.E), pady=5)
        
        # Email
        ttk.Label(section, text="Email*:", style='Field.TLabel').grid(
            row=2, column=0, sticky=tk.W, padx=(0, 10), pady=5)
        self.email_var = tk.StringVar()
        email_entry = ttk.Entry(section, textvariable=self.email_var, width=40)
        email_entry.grid(row=2, column=1, sticky=(tk.W, tk.E), pady=5)
        
        # Remarks (optional)
        ttk.Label(section, text="Remarks:", style='Field.TLabel').grid(
            row=3, column=0, sticky=tk.W, padx=(0, 10), pady=5)
        self.remarks_var = tk.StringVar()
        remarks_entry = ttk.Entry(section, textvariable=self.remarks_var, width=40)
        remarks_entry.grid(row=3, column=1, sticky=(tk.W, tk.E), pady=5)
        
        # Buttons frame
        btn_frame = ttk.Frame(section)
        btn_frame.grid(row=4, column=0, columnspan=2, pady=(10, 0))
        
        # Create User button
        create_btn = ttk.Button(btn_frame,
                               text="Create User",
                               command=self.create_user,
                               style='Action.TButton')
        create_btn.pack(side=tk.LEFT, padx=(0, 10))
        
        # Clear button
        clear_btn = ttk.Button(btn_frame,
                              text="Clear Fields",
                              command=self.clear_user_fields)
        clear_btn.pack(side=tk.LEFT)
        
        # Note
        note = ttk.Label(section,
                        text="* Required fields",
                        font=('Arial', 8),
                        foreground='#e74c3c')
        note.grid(row=5, column=0, columnspan=2, sticky=tk.W, pady=(5, 0))
    
    def create_results_section(self, parent: ttk.Frame):
        """Create section for displaying results"""
        # Section container
        section = ttk.LabelFrame(parent, text="Results", padding="10")
        section.grid(row=3, column=0, sticky=(tk.W, tk.E, tk.N, tk.S), pady=(0, 10))
        section.columnconfigure(0, weight=1)
        section.rowconfigure(0, weight=1)
        parent.rowconfigure(3, weight=1)
        
        # Results text area with scrollbar
        self.results_text = scrolledtext.ScrolledText(
            section,
            wrap=tk.WORD,
            width=80,
            height=15,
            font=('Courier', 10)
        )
        self.results_text.grid(row=0, column=0, sticky=(tk.W, tk.E, tk.N, tk.S))
        
        # Clear results button
        clear_btn = ttk.Button(section,
                              text="Clear Results",
                              command=self.clear_results)
        clear_btn.grid(row=1, column=0, pady=(5, 0))
    
    def create_status_bar(self, parent: ttk.Frame):
        """Create status bar"""
        self.status_var = tk.StringVar(value="Ready")
        status_bar = ttk.Label(parent,
                              textvariable=self.status_var,
                              relief=tk.SUNKEN,
                              anchor=tk.W,
                              font=('Arial', 9))
        status_bar.grid(row=4, column=0, sticky=(tk.W, tk.E))
    
    def toggle_num_rows(self):
        """Toggle num_rows entry based on Get All checkbox"""
        if self.get_all_var.get():
            self.num_rows_var.set("ALL")
        else:
            self.num_rows_var.set(str(config.DEFAULT_NUM_ROWS))
    
    def set_status(self, message: str, error: bool = False):
        """Update status bar"""
        self.status_var.set(message)
        if error:
            self.root.update_idletasks()
    
    def append_result(self, text: str):
        """Append text to results area"""
        self.results_text.insert(tk.END, text + "\n")
        self.results_text.see(tk.END)
        self.root.update_idletasks()
    
    def clear_results(self):
        """Clear results text area"""
        self.results_text.delete(1.0, tk.END)
    
    def clear_user_fields(self):
        """Clear all user input fields"""
        self.username_var.set("")
        self.password_var.set("")
        self.email_var.set("")
        self.remarks_var.set("")
    
    def test_connection(self):
        """Test API connection on startup"""
        try:
            response = requests.get(
                f"{config.API_BASE_URL}/healthcheck",
                timeout=config.REQUEST_TIMEOUT
            )
            if response.status_code == 200:
                self.set_status("✅ Connected to API")
                self.append_result("=== API Connection Successful ===")
                self.append_result(json.dumps(response.json(), indent=2))
                self.append_result("")
            else:
                self.set_status("⚠️ API returned unexpected status", error=True)
        except requests.exceptions.ConnectionError:
            self.set_status("❌ Cannot connect to API", error=True)
            messagebox.showerror(
                "Connection Error",
                f"Cannot connect to Flask API at {config.API_BASE_URL}\n\n"
                "Please ensure:\n"
                "1. Flask server is running\n"
                "2. API is accessible at the configured address"
            )
        except Exception as e:
            self.set_status(f"❌ Error: {str(e)}", error=True)
    
    def get_users(self):
        """Get users from API"""
        try:
            # Get num_row value
            num_row = self.num_rows_var.get().strip()
            
            if not num_row:
                messagebox.showwarning("Input Error", "Please enter number of users")
                return
            
            # Validate num_row
            if num_row != "ALL" and not num_row.isdigit():
                messagebox.showwarning("Input Error", "Number of users must be a positive integer or 'ALL'")
                return
            
            # Prepare request
            self.set_status(f"Fetching {num_row} users...")
            self.append_result(f"\n=== GET USERS Request (num_row={num_row}) ===")
            
            # Send GET request with query parameter
            response = requests.get(
                f"{config.GET_USERS_URL}?num_row={num_row}",
                timeout=config.REQUEST_TIMEOUT
            )
            
            # Handle response
            if response.status_code == 200:
                data = response.json()
                
                if "ok" in data:
                    users = data["ok"]
                    self.append_result(f"✅ Retrieved {len(users)} users:")
                    self.append_result(json.dumps(users, indent=2))
                    self.set_status(f"✅ Retrieved {len(users)} users")
                else:
                    self.append_result(f"Response: {json.dumps(data, indent=2)}")
                    self.set_status("⚠️ Unexpected response format")
            else:
                error_data = response.json() if response.text else {"error": "Unknown error"}
                self.append_result(f"❌ Error {response.status_code}:")
                self.append_result(json.dumps(error_data, indent=2))
                self.set_status(f"❌ Error {response.status_code}", error=True)
                
        except requests.exceptions.RequestException as e:
            self.append_result(f"❌ Request failed: {str(e)}")
            self.set_status("❌ Request failed", error=True)
            messagebox.showerror("Request Error", f"Failed to get users:\n{str(e)}")
        except Exception as e:
            self.append_result(f"❌ Error: {str(e)}")
            self.set_status(f"❌ Error: {str(e)}", error=True)
    
    def create_user(self):
        """Create new user via API"""
        try:
            # Get input values
            username = self.username_var.get().strip()
            password = self.password_var.get().strip()
            email = self.email_var.get().strip()
            remarks = self.remarks_var.get().strip() or None
            
            # Validate required fields
            if not all([username, password, email]):
                messagebox.showwarning(
                    "Input Error",
                    "Please fill in all required fields:\n- Username\n- Password\n- Email"
                )
                return
            
            # Prepare request body
            user_data = {
                "username": username,
                "password": password,
                "email": email,
                "remarks": remarks
            }
            
            self.set_status("Creating user...")
            self.append_result(f"\n=== CREATE USER Request ===")
            self.append_result(f"Data: {json.dumps(user_data, indent=2)}")
            
            # Send POST request
            response = requests.post(
                config.SET_USERS_URL,
                json=user_data,
                headers={"Content-Type": "application/json"},
                timeout=config.REQUEST_TIMEOUT
            )
            
            # Handle response
            if response.status_code == 200:
                result = response.json()
                self.append_result(f"✅ Success:")
                self.append_result(json.dumps(result, indent=2))
                self.set_status(f"✅ User '{username}' created successfully")
                
                # Clear fields after successful creation
                self.clear_user_fields()
                
                messagebox.showinfo(
                    "Success",
                    f"User '{username}' created successfully!"
                )
            else:
                error_data = response.json() if response.text else {"error": "Unknown error"}
                self.append_result(f"❌ Error {response.status_code}:")
                self.append_result(json.dumps(error_data, indent=2))
                self.set_status(f"❌ Error {response.status_code}", error=True)
                
                error_msg = error_data.get("error", "Unknown error")
                messagebox.showerror("Error", f"Failed to create user:\n{error_msg}")
                
        except requests.exceptions.RequestException as e:
            self.append_result(f"❌ Request failed: {str(e)}")
            self.set_status("❌ Request failed", error=True)
            messagebox.showerror("Request Error", f"Failed to create user:\n{str(e)}")
        except Exception as e:
            self.append_result(f"❌ Error: {str(e)}")
            self.set_status(f"❌ Error: {str(e)}", error=True)


def main():
    """Main entry point"""
    root = tk.Tk()
    app = UserManagementApp(root)
    root.mainloop()


if __name__ == "__main__":
    main()