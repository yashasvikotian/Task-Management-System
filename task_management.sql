# Task-Management-System
import tkinter as tk
from tkinter import ttk, messagebox, simpledialog
import mysql.connector
from mysql.connector import Error

class TaskManagementApp:
    def _init_(self, root):
        self.root = root
        self.root.title("Task Management System")
        self.root.geometry("300x200")

        self.connection = self.create_db_connection()
        self.logged_in_user_id = None

        # Create tables if they don't exist
        self.create_tables()

        # Open the login window
        self.open_login_window()

    def create_db_connection(self):
        """Creates and returns a connection to the database."""
        try:
            connection = mysql.connector.connect(
                host='localhost',
                database='task_management',
                user='root',
                password='ismira*1806'  # Update with your password
            )
            if connection.is_connected():
                print("Connected to the database")
                return connection
        except Error as e:
            print(f"Error: {e}")
            return None

    def open_login_window(self):
        """Creates and opens the login window."""
        login_window = tk.Toplevel(self.root)
        login_window.title("Login")
        login_window.geometry("300x200")

        ttk.Label(login_window, text="Email:").pack(pady=5)
        email_entry = ttk.Entry(login_window)
        email_entry.pack(pady=5)

        ttk.Label(login_window, text="Password:").pack(pady=5)
        password_entry = ttk.Entry(login_window, show="*")
        password_entry.pack(pady=5)

        def handle_login():
            email = email_entry.get()
            password = password_entry.get()

            if self.authenticate_user(email, password):
                login_window.destroy()
                self.open_main_window()
            else:
                messagebox.showerror("Login Failed", "Invalid email or password")

        ttk.Button(login_window, text="Login", command=handle_login).pack(pady=20)

    def authenticate_user(self, email, password):
        """Authenticates user credentials."""
        cursor = self.connection.cursor()
        query = "SELECT user_id FROM users WHERE email = %s AND password = %s"
        cursor.execute(query, (email, password))
        result = cursor.fetchone()
        if result:
            self.logged_in_user_id = result[0]
            return True
        return False

    def open_main_window(self):
        """Creates and opens the main application window."""
        self.main_window = tk.Toplevel(self.root)
        self.main_window.title("Main Application")
        self.main_window.geometry("800x600")

        # Create menu
        self.create_menu()

    def create_menu(self):
        """Creates the menu for the main application window."""
        menu = tk.Menu(self.main_window)
        self.main_window.config(menu=menu)

        user_menu = tk.Menu(menu, tearoff=0)
        menu.add_cascade(label="Users", menu=user_menu)
        user_menu.add_command(label="Create User", command=self.create_user_ui)
        user_menu.add_command(label="Read Users", command=self.read_users_ui)
        user_menu.add_command(label="Update User Email", command=self.update_user_email_ui)
        user_menu.add_command(label="Delete User", command=self.delete_user_ui)

        task_menu = tk.Menu(menu, tearoff=0)
        menu.add_cascade(label="Tasks", menu=task_menu)
        task_menu.add_command(label="Create Task", command=self.create_task_ui)
        task_menu.add_command(label="Read Tasks", command=self.read_tasks_ui)
        task_menu.add_command(label="Update Task", command=self.update_task_ui)
        task_menu.add_command(label="Delete Task", command=self.delete_task_ui)

        comment_menu = tk.Menu(menu, tearoff=0)
        menu.add_cascade(label="Comments", menu=comment_menu)
        comment_menu.add_command(label="Create Comment", command=self.create_comment_ui)
        comment_menu.add_command(label="Read Comments", command=self.read_comments_ui)
        comment_menu.add_command(label="Update Comment Status", command=self.update_comment_status_ui)
        comment_menu.add_command(label="Delete Comment", command=self.delete_comment_ui)

        role_menu = tk.Menu(menu, tearoff=0)
        menu.add_cascade(label="Roles", menu=role_menu)
        role_menu.add_command(label="Create Role", command=self.create_role_ui)
        role_menu.add_command(label="Read Roles", command=self.read_roles_ui)
        role_menu.add_command(label="Update Role", command=self.update_role_ui)
        role_menu.add_command(label="Delete Role", command=self.delete_role_ui)

    def create_tables(self):
        """Creates tables in the database."""
        create_users_table = """
        CREATE TABLE IF NOT EXISTS users (
            user_id INT AUTO_INCREMENT PRIMARY KEY,
            name VARCHAR(255) NOT NULL,
            email VARCHAR(255) NOT NULL UNIQUE,
            password VARCHAR(255) NOT NULL
        );
        """

        create_tasks_table = """
        CREATE TABLE IF NOT EXISTS tasks (
            task_id INT AUTO_INCREMENT PRIMARY KEY,
            name VARCHAR(255) NOT NULL,
            description TEXT,
            due_date DATE,
            user_id INT,
            FOREIGN KEY (user_id) REFERENCES users (user_id) ON DELETE CASCADE
        );
        """

        create_comments_table = """
        CREATE TABLE IF NOT EXISTS comments (
            comment_id INT AUTO_INCREMENT PRIMARY KEY,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            status ENUM('Pending', 'Resolved') DEFAULT 'Pending',
            task_id INT,
            user_id INT,
            FOREIGN KEY (task_id) REFERENCES tasks (task_id) ON DELETE CASCADE,
            FOREIGN KEY (user_id) REFERENCES users (user_id) ON DELETE CASCADE
        );
        """

        create_roles_table = """
        CREATE TABLE IF NOT EXISTS roles (
            role_id INT AUTO_INCREMENT PRIMARY KEY,
            role_name VARCHAR(255) NOT NULL,
            user_id INT,
            FOREIGN KEY (user_id) REFERENCES users (user_id) ON DELETE CASCADE
        );
        """

        table_queries = [create_users_table, create_tasks_table, create_comments_table, create_roles_table]

        for query in table_queries:
            self.execute_query(query)

    def execute_query(self, query, data=None):
        """Executes a query on the database."""
        cursor = self.connection.cursor()
        try:
            if data:
                cursor.execute(query, data)
            else:
                cursor.execute(query)
            self.connection.commit()
        except Error as e:
            messagebox.showerror("Query Error", f"The error '{e}' occurred")
            print(f"The error '{e}' occurred")

    def get_role_id(self, role_name):
        """Retrieves the role ID based on the role name."""
        cursor = self.connection.cursor()
        query = "SELECT role_id FROM roles WHERE role_name = %s"
        cursor.execute(query, (role_name,))
        result = cursor.fetchone()
        return result[0] if result else None

    # CRUD operations for users
    def create_user(self, name, email, password):
        """Creates a new user."""
        if self.user_exists(email):
            messagebox.showwarning("User Exists", f"User with email {email} already exists.")
            return

        query = "INSERT INTO users (name, email, password) VALUES (%s, %s, %s)"
        self.execute_query(query, (name, email, password))
        messagebox.showinfo("Success", "User created successfully")

    def read_users(self):
        """Reads all users."""
        cursor = self.connection.cursor()
        cursor.execute("SELECT * FROM users")
        return cursor.fetchall()

    def update_user_email(self, user_id, email):
        """Updates the email of an existing user."""
        query = "UPDATE users SET email = %s WHERE user_id = %s"
        self.execute_query(query, (email, user_id))
        messagebox.showinfo("Success", "User email updated successfully")

    def delete_user(self, user_id):
        """Deletes a user by ID."""
        query = "DELETE FROM users WHERE user_id = %s"
        self.execute_query(query, (user_id,))
        messagebox.showinfo("Success", "User deleted successfully")

    def user_exists(self, email):
        """Checks if a user exists by email."""
        cursor = self.connection.cursor()
        query = "SELECT * FROM users WHERE email = %s"
        cursor.execute(query, (email,))
        return cursor.fetchone() is not None

    # CRUD operations for tasks
    def create_task(self, name, description, due_date, user_id):
        """Creates a new task."""
        query = "INSERT INTO tasks (name, description, due_date, user_id) VALUES (%s, %s, %s, %s)"
        self.execute_query(query, (name, description, due_date, user_id))
        messagebox.showinfo("Success", "Task created successfully")

    def read_tasks(self):
        """Reads all tasks."""
        cursor = self.connection.cursor()
        cursor.execute("SELECT * FROM tasks")
        return cursor.fetchall()

    def update_task(self, task_id, name, description, due_date):
        """Updates a task."""
        query = "UPDATE tasks SET name = %s, description = %s, due_date = %s WHERE task_id = %s"
        self.execute_query(query, (name, description, due_date, task_id))
        messagebox.showinfo("Success", "Task updated successfully")

    def delete_task(self, task_id):
        """Deletes a task by ID."""
        query = "DELETE FROM tasks WHERE task_id = %s"
        self.execute_query(query, (task_id,))
        messagebox.showinfo("Success", "Task deleted successfully")

    # CRUD operations for comments
    def create_comment(self, status, task_id, user_id):
        """Creates a new comment."""
        query = "INSERT INTO comments (status, task_id, user_id) VALUES (%s, %s, %s)"
        self.execute_query(query, (status, task_id, user_id))
        messagebox.showinfo("Success", "Comment created successfully")

    def read_comments(self):
        """Reads all comments."""
        cursor = self.connection.cursor()
        cursor.execute("SELECT * FROM comments")
        return cursor.fetchall()

    def update_comment_status(self, comment_id, status):
        """Updates the status of a comment."""
        query = "UPDATE comments SET status = %s WHERE comment_id = %s"
        self.execute_query(query, (status, comment_id))
        messagebox.showinfo("Success", "Comment status updated successfully")

    def delete_comment(self, comment_id):
        """Deletes a comment by ID."""
        query = "DELETE FROM comments WHERE comment_id = %s"
        self.execute_query(query, (comment_id,))
        messagebox.showinfo("Success", "Comment deleted successfully")

    # CRUD operations for roles
    def create_role(self, role_name, user_id):
        """Creates a new role."""
        query = "INSERT INTO roles (role_name, user_id) VALUES (%s, %s)"
        self.execute_query(query, (role_name, user_id))
        messagebox.showinfo("Success", "Role created successfully")

    def read_roles(self):
        """Reads all roles."""
        cursor = self.connection.cursor()
        cursor.execute("SELECT * FROM roles")
        return cursor.fetchall()

    def update_role(self, role_id, role_name):
        """Updates a role."""
        query = "UPDATE roles SET role_name = %s WHERE role_id = %s"
        self.execute_query(query, (role_name, role_id))
        messagebox.showinfo("Success", "Role updated successfully")

    def delete_role(self, role_id):
        """Deletes a role by ID."""
        query = "DELETE FROM roles WHERE role_id = %s"
        self.execute_query(query, (role_id,))
        messagebox.showinfo("Success", "Role deleted successfully")

    # UI methods
    def create_user_ui(self):
        """UI for creating a new user."""
        name = simpledialog.askstring("Input", "Enter name:")
        email = simpledialog.askstring("Input", "Enter email:")
        password = simpledialog.askstring("Input", "Enter password:", show="*")
        if name and email and password:
            self.create_user(name, email, password)

    def read_users_ui(self):
        """UI for reading all users."""
        users = self.read_users()
        users_str = "\n".join([f"ID: {user[0]}, Name: {user[1]}, Email: {user[2]}" for user in users])
        messagebox.showinfo("Users", users_str)

    def update_user_email_ui(self):
        """UI for updating a user's email."""
        user_id = simpledialog.askinteger("Input", "Enter user ID:")
        new_email = simpledialog.askstring("Input", "Enter new email:")
        if user_id and new_email:
            self.update_user_email(user_id, new_email)

    def delete_user_ui(self):
        """UI for deleting a user."""
        user_id = simpledialog.askinteger("Input", "Enter user ID:")
        if user_id:
            self.delete_user(user_id)

    def create_task_ui(self):
        """UI for creating a new task."""
        name = simpledialog.askstring("Input", "Enter task name:")
        description = simpledialog.askstring("Input", "Enter task description:")
        due_date = simpledialog.askstring("Input", "Enter due date (YYYY-MM-DD):")
        user_id = simpledialog.askinteger("Input", "Enter user ID:")
        if name and description and due_date and user_id:
            self.create_task(name, description, due_date, user_id)

    def read_tasks_ui(self):
        """UI for reading all tasks."""
        tasks = self.read_tasks()
        tasks_str = "\n".join([f"ID: {task[0]}, Name: {task[1]}, Description: {task[2]}, Due Date: {task[3]}, User ID: {task[4]}" for task in tasks])
        messagebox.showinfo("Tasks", tasks_str)

    def update_task_ui(self):
        """UI for updating a task."""
        task_id = simpledialog.askinteger("Input", "Enter task ID:")
        name = simpledialog.askstring("Input", "Enter new task name:")
        description = simpledialog.askstring("Input", "Enter new task description:")
        due_date = simpledialog.askstring("Input", "Enter new due date (YYYY-MM-DD):")
        if task_id and name and description and due_date:
            self.update_task(task_id, name, description, due_date)

    def delete_task_ui(self):
        """UI for deleting a task."""
        task_id = simpledialog.askinteger("Input", "Enter task ID:")
        if task_id:
            self.delete_task(task_id)

    def create_comment_ui(self):
        """UI for creating a new comment."""
        status = simpledialog.askstring("Input", "Enter comment status (Pending/Resolved):")
        task_id = simpledialog.askinteger("Input", "Enter task ID:")
        user_id = simpledialog.askinteger("Input", "Enter user ID:")
        if status and task_id and user_id:
            self.create_comment(status, task_id, user_id)

    def read_comments_ui(self):
        """UI for reading all comments."""
        comments = self.read_comments()
        comments_str = "\n".join([f"ID: {comment[0]}, Status: {comment[1]}, Task ID: {comment[2]}, User ID: {comment[3]}" for comment in comments])
        messagebox.showinfo("Comments", comments_str)

    def update_comment_status_ui(self):
        """UI for updating a comment's status."""
        comment_id = simpledialog.askinteger("Input", "Enter comment ID:")
        status = simpledialog.askstring("Input", "Enter new comment status (Pending/Resolved):")
        if comment_id and status:
            self.update_comment_status(comment_id, status)

    def delete_comment_ui(self):
        """UI for deleting a comment."""
        comment_id = simpledialog.askinteger("Input", "Enter comment ID:")
        if comment_id:
            self.delete_comment(comment_id)

    def create_role_ui(self):
        """UI for creating a new role."""
        role_name = simpledialog.askstring("Input", "Enter role name:")
        user_id = simpledialog.askinteger("Input", "Enter user ID:")
        if role_name and user_id:
            self.create_role(role_name, user_id)

    def read_roles_ui(self):
        """UI for reading all roles."""
        roles = self.read_roles()
        roles_str = "\n".join([f"ID: {role[0]}, Role Name: {role[1]}, User ID: {role[2]}" for role in roles])
        messagebox.showinfo("Roles", roles_str)

    def update_role_ui(self):
        """UI for updating a role."""
        role_id = simpledialog.askinteger("Input", "Enter role ID:")
        new_role_name = simpledialog.askstring("Input", "Enter new role name:")
        if role_id and new_role_name:
            self.update_role(role_id, new_role_name)

    def delete_role_ui(self):
        """UI for deleting a role."""
        role_id = simpledialog.askinteger("Input", "Enter role ID:")
        if role_id:
            self.delete_role(role_id)

if _name_ == "_main_":
    root = tk.Tk()
    root.withdraw()  # Hide the root window
    app = TaskManagementApp(root)
    root.mainloop()
